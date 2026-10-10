# AlmaLinux 10 の初期設定の手順（インストール直後の更新・sudo・SSH・導入元・日本語入力・GNOME・シェルのツール・Git・Firefox・WezTerm・Neovim・AI エージェント）の参考資料

[手順書](../almalinux-setup.md)・[ロールバックと注意点](../extra/almalinux-setup.md)

## 補足

### 実施手順 / ログインと sudo / 手順 1: 補足: 日本語の名前のフォルダー

- このログインで、ホームに日本語の名前のフォルダー（`ダウンロード`・`ドキュメント` など）ができる。「GNOME の表示と入力」の手順 1 で英語の名前にする

### 実施手順 / ログインと sudo / 手順 3: 補足: 貼り直し

- 貼り直しても同じ内容で置き直すだけ（何度貼ってもよい）

### 実施手順 / OS とファームウェアの更新 / 手順 2: 補足: fwupd の起動待ち

- `デーモンへの接続に失敗しました: … タイムアウトしました` が出るのは、起動の直後に fwupd の起動が間に合わないことがあるため

### 実施手順 / システムの設定 / 手順 1: 補足: 変数の意味

- `HOST_NAME` は、SSH・RDP・Samba・Syncthing などで、この PC を見分ける名前
- `DASH_FAVORITES` は、「GNOME の表示と入力」の手順 13 で左の Dash に並べるアプリ（`/usr/share/applications` の `.desktop` のファイル名）
- 変数はその端末の中だけで有効なので、新しい端末を開いたら貼り直す

### 実施手順 / システムの設定 / 手順 3: 補足: SSH の既定とログイン

- `enabled`・`active`・`yes`・`yes` は、Workstation の既定
- 別の PC からは `ssh <USER>@<IP>` でログインできる（初めてつなぐときは、ホストの鍵の fingerprint を聞かれる）

### 実施手順 / システムの設定 / 手順 5: 補足: journal の置き場所

- AlmaLinux 10 の既定では `/var/log/journal` が無く、journal は `/run/log/journal`（メモリー）にだけ書かれて、再起動で消える
- journald が作った `/var/log/journal` に付かない ACL は、`wheel`・`adm` のグループが読めるもの（付け直す仕組みは[選択した方針](#選択した方針)）
- 前の起動のログが読めることは、「再起動と確認」の手順 1 の再起動の後に、同じ項の手順 3 で確かめる

### 実施手順 / システムの設定 / 手順 6: 補足: 予約しているメモリー

- `/sys/kernel/kexec_crash_size` の数は、予約しているメモリーのバイト数（`268435456` で 256 MiB）

### 実施手順 / システムの設定 / 手順 7: 補足: 効く時期

- メモリーが空くのは、「再起動と確認」の手順 1 の再起動の後

### 実施手順 / システムの設定 / 手順 8: 補足: 外した後

- 外すと、無いコマンドを打ったときは `bash: <コマンド>: コマンドが見つかりません...` とだけ出て、パッケージを探して待たされない

### 実施手順 / EPEL と RPM Fusion / 手順 1: 補足: EPEL の入手元と使う手順書

- `epel-release` は AlmaLinux の `extras` リポジトリにあるので、追加のリポジトリの設定は要らない
- 最後に出る「CRB を有効にすることを推奨」を気にしなくてよいのは、AlmaLinux 10 では CRB が既定で有効なため（[導入元一覧](../tool-catalog.md#導入経路と-el10-での注意)）
- EPEL を使う手順書（[btop](../btop.md)・[distrobox](../distrobox.md)・[podman-compose](../podman-compose.md)・[podman-tui](../podman-tui.md)・[VirtualBox](../virtualbox.md)）と、[導入元一覧](../tool-catalog.md)の EPEL の行が使えるようになる

### 実施手順 / EPEL と RPM Fusion / 手順 4: 補足: localpkg_gpgcheck と free

- `--setopt=localpkg_gpgcheck=1` を外さない理由は、[検証記録](../verification/almalinux-setup.md#rpm-fusion-実施手順--手順-3-補足-署名の確認とepel-を前提にした理由)と[RPM Fusion の選択した方針](#rpm-fusion-選択した方針)
- 有効にするのは free だけ。nonfree は扱わない

### 実施手順 / EPEL と RPM Fusion / 手順 5: 補足: 使えるようになるもの

- [Firefox の AAC・H.264](../almalinux-setup.md#firefox)（firefox.md の手順 8 から。RPM Fusion の `ffmpeg-libs` を入れる）が使えるようになる

### 実施手順 / Flatpak と Flathub / 手順 1: 補足: flatpak と Flathub の登録

- Workstation には flatpak が最初から入っている
- `flathub` の行が既にあれば、「Flatpak と Flathub」の手順 3 は何もしない（`--if-not-exists` のため）

### 実施手順 / Flatpak と Flathub / 手順 3: 補足: 使えるようになるもの

- [導入元一覧](../tool-catalog.md#gui)の「Flathub」の行にある GUI アプリが入れられるようになる。[Firefox](../almalinux-setup.md#firefox) と [VS Code](../vscode.md) は Flathub を使わず RPM で入れる

### 実施手順 / Flatpak と Flathub / 手順 4: 補足: 確認用のアプリ

- 確認用のアプリは、小さい [Flatseal](https://flathub.org/apps/com.github.tchx84.Flatseal)（Flatpak アプリの権限を GUI で変えるツール）にしてある

### 実施手順 / 日本語入力 / 手順 1: 補足: 入っているときと入れたとき

- Workstation で入れた PC には、3 つとも最初から入っている
- 入れたときに「再起動と確認」の手順 1 の再起動を待つのは、動いている IBus が、ログインし直すまで Anthy を使えないため

### 実施手順 / 日本語入力 / 手順 2: 補足: 入力ソースを切り替えるキー

- 最後の `get` の `['<Super>space', 'XF86Keyboard']` が、入力ソースを切り替えるキー（Super+Space）

### 実施手順 / GNOME の表示と入力 / 手順 1: 補足: 中身とログインの窓

- 中身は、フォルダーごと移る
- 次のログインで「標準フォルダーの名前を現在の言語に合わせて更新しますか?」の窓は出ない（`~/.config/user-dirs.locale` は今の言語のまま）

### 実施手順 / GNOME の表示と入力 / 手順 2: 補足: 設定アプリとの対応

- 設定の「外観」の「スタイル」の「ダーク」と同じで、すぐに効く

### 実施手順 / GNOME の表示と入力 / 手順 3: 補足: 効く範囲

- 自分のセッションだけの設定。ログイン画面と、ほかのユーザーには効かない

### 実施手順 / GNOME の表示と入力 / 手順 4: 補足: 既定値

- `button-layout` の既定は `'appmenu:close'`

### 実施手順 / GNOME の表示と入力 / 手順 6: 補足: 2 つのスキーマ

- Files と GTK4 のアプリは `org.gtk.gtk4`、GTK3 のアプリは `org.gtk` を読む
- Files では Ctrl+H で、隠しファイルを出す・隠すを切り替えられる

### 実施手順 / GNOME の表示と入力 / 手順 7: 補足: アプリごとの切り替え

- アプリごとの切り替えは Super+Tab に残る

### 実施手順 / GNOME の表示と入力 / 手順 8: 補足: アクティビティの画面

- ホットコーナーを切った後も、アクティビティの画面は Super キーで開く

### 実施手順 / GNOME の表示と入力 / 手順 9: 補足: 拡大率を選ぶ時期

- 拡大率を選ぶのは、「再起動と確認」の手順 1 の再起動の後に、同じ項の手順 4 で行う

### 実施手順 / GNOME の表示と入力 / 手順 10: 補足: 版

- 入る `gnome-shell-extension-appindicator` は、AlmaLinux 10.2 では 61

### 実施手順 / GNOME の表示と入力 / 手順 11: 補足: 効く時期

- 動いている GNOME Shell は、ログインし直すまで、入れたばかりの拡張を読まない。「再起動と確認」の手順 1 の再起動の後に、同じ項の手順 3 で確かめる

### 実施手順 / GNOME の表示と入力 / 手順 12: 補足: 設定アプリでの表示

- 足したショートカットは、設定の「キーボード」→「キーボードショートカット」→「カスタムショートカット」にも出る

### 実施手順 / 共通の bash 設定 / 手順 1: 補足: 共通の bash 設定

- [README の共通の bash 設定を先に入れる](../../README.md#共通の-bash-設定を先に入れる)と同じ（Workstation には git が最初から入っている）
- 元の `~/.bashrc` は `~/.bashrc.before-bash` に残る
- `~/.bashrc` の末尾に、`~/.config/bash/bashrc` を読む 1 行が足される。ツールごとの設定（Homebrew・starship・zoxide・fzf・eza・bat の `MANPAGER`・履歴と `shopt` など）は、この設定がまとめて読む。この文書では `~/.bashrc` に追記しない

### 実施手順 / 共通の bash 設定 / 手順 3: 補足: 入っているときと入れたとき

- Workstation で入れた PC は、bash-completion が最初から入っている
- BaseOS から入れるときは、依存の `pkgconf` 系 4 つも入る

### 実施手順 / Homebrew / 手順 2: 補足: Next steps を行わない理由

- `Next steps` の `~/.bashrc` への追記を行わないのは、共通の bash 設定が `brew shellenv` を読むため

### 実施手順 / Homebrew / 手順 3: 補足: 日々の操作

- 日々の操作は[Homebrew の使い方の基本](../almalinux-setup.md#homebrew-の使い方の基本)

### 実施手順 / シェルのツール / 手順 1: 補足: 確認とボトル

- 依存も入れる計画なので、`[y/n]` と聞かれる
- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
- 要らないツールの名前を外してよいのは、共通の bash 設定が、入っているものだけを読むため

### 実施手順 / シェルのツール / 手順 2: 補足: 開き直した端末で効く理由

- 開き直した端末で starship・zoxide・fzf・eza・bat が効くのは、共通の bash 設定が、入っているツールを読むため

### 実施手順 / シェルのツール / 手順 3: 補足: 補完の順

- `-F _brew brew` が出るのは、共通の bash 設定が Homebrew の補完を fzf より前に読むため

### 実施手順 / シェルのツール / 手順 4: 補足: 初期化の順と starship explain

- starship → WezTerm → zoxide の順は、共通の bash 設定が初期化の順番を持つ。`~/.bashrc` の編集は不要
- `starship explain` は、今のプロンプトに出ている各部分の意味を 1 行ずつ説明する
- 見た目を変えるなら[starship のプリセットを当てる（任意）](../almalinux-setup.md#starship-のプリセットを当てる任意)、細かい調整は[starship の設定ファイル](../almalinux-setup.md#starship-の設定ファイル)

### 実施手順 / シェルのツール / 手順 6: 補足: 出力の意味

- `[+git]` は git の連携込みのビルド
- `Git` の列が出るのは、`~/.config/bash` が git のリポジトリだから
- `ll`・`la`・`lt` は共通の bash 設定が足す。`ls` は置き換えない

### 実施手順 / シェルのツール / 手順 7: 補足: bat の出力と MANPAGER

- `--color=always` を外してパイプに繋ぐと、装飾の無い `cat` と同じ出力になる
- `MANPAGER` の `bat -plman` は共通の bash 設定が持つ。`man bash` が bat の色で開く（`q` で閉じる）

### 実施手順 / シェルのツール / 手順 8: 補足: BaseOS の tmux

- BaseOS の tmux で始めたセッションに Homebrew の tmux からはつなげない（[検証記録](../verification/almalinux-setup.md#tmux-実施手順--手順-2-補足-baseos-の-tmux-と並べたとき)）

### 実施手順 / シェルのツール / 手順 10: 補足: z と zi の使い方

- 以後は `z share` のように末尾の一部を書けば `/usr/share` に飛ぶ。`zi` で候補を fzf で選べる

### 実施手順 / キー操作を試す / 手順 3: 補足: プレビューと複数の選択

- 右側のプレビューは、共通の bash 設定が、bat があるときに入れる
- Tab で複数を選べる（選んだ行に印が付き、Enter で全部入る）

### 実施手順 / キー操作を試す / 手順 4: 補足: ** の補完

- `**` を付けなければ、今までどおりの補完
- `ssh **<Tab>` は `~/.ssh/config` と `known_hosts` のホスト名、`export **<Tab>` は変数名の一覧になる

### 実施手順 / tmux を試す / 手順 1: 補足: デタッチ

- デタッチしても、セッションの中のシェルと、そこで動かしているコマンドは動き続ける

### 実施手順 / tmux を試す / 手順 2: 補足: tmux の使い方

- キーとコマンドは[tmux の使い方の基本](../almalinux-setup.md#tmux-の使い方の基本)

### 実施手順 / tmux を試す / 手順 3: 補足: tmux のサーバー

- セッションが 1 つも無くなると、tmux のサーバーも終わる

### 実施手順 / 再起動と確認 / 手順 1: 補足: 再起動で効くもの

- 「システムの設定」の手順 7 の kdump のメモリー（外したとき）、「日本語入力」の手順 1 で入れた ibus-anthy（入れたとき）、「GNOME の表示と入力」の手順 9 の拡大率、同じ項の手順 11 のトレイアイコン、「Flatpak と Flathub」の手順 4 の Flatseal のメニュー

### SSH を公開鍵だけにする（任意） / 手順 1: 補足: restorecon

- `restorecon` は、`~/.ssh` の SELinux のラベルを、sshd が読めるものに合わせる

### SSH を公開鍵だけにする（任意） / 手順 5: 補足: 既定値

- `passwordauthentication yes` と `kbdinteractiveauthentication no` は、AlmaLinux 10 の既定

### dnf-automatic で自動で更新する（任意） / 手順 2: 補足: 入れる更新の設定

- 何を入れるか（`upgrade_type`）などは `/etc/dnf/automatic.conf` にある。このタイマーは、その設定の `apply_updates` に関わらず、更新を入れる

### dnf-automatic で自動で更新する（任意） / 手順 3: 補足: GNOME Software の設定

- `download-updates` を `false` にすると、GNOME Software の「設定」の「自動更新」がオフになる
- 更新があることの通知と、手で入れる更新は、そのまま使える

### 画面オフ・画面ロック・自動サスペンドを止める（任意） / 手順 1: 補足: 変数の有効な範囲

- 変数はそのシェルの中だけで有効なので、新しいシェルを開いたら貼り直す

### 画面オフ・画面ロック・自動サスペンドを止める（任意） / 手順 2: 補足: 読み戻し

- 最後の 3 つのコマンドで読み戻す

### 画面オフ・画面ロック・自動サスペンドを止める（任意） / 手順 3: 補足: ログイン画面の設定ファイル

- ファイルには、自動サスペンドと電源ボタンの設定を書く
- 文字列の値は引用符（`'`）で囲む。囲まないと、`dconf update` が失敗する

### 画面オフ・画面ロック・自動サスペンドを止める（任意） / 手順 4: 補足: mask の効き目

- GNOME のメニュー・蓋・電源ボタンなど、どこから頼まれてもサスペンドが始まらなくなる

### 画面オフ・画面ロック・自動サスペンドを止める（任意） / 手順 5: 補足: 蓋の既定値

- `HandleLidSwitch` の既定は `s "suspend"`
- 蓋の無い PC では何も変わらない（置いても害は無い）

### 画面オフ・画面ロック・自動サスペンドを止める（任意） / 手順 9: 補足: 残るディレクトリ

- 空の `/etc/systemd/logind.conf.d` は残る

### Wake on LAN を使う（任意） / 手順 2: 補足: Wake-on の値

- `Wake-on:` の `g` がマジック パケット
- VirtualBox の VM の e1000 は、`Supports Wake-on: umbg` でも `d` のままだった

### 実施手順 / WezTerm と HackGen Console NF をデスクトップで使う / 手順 1: 補足: 等幅のフォント

- 等幅のフォントは、端末の Ptyxis などが使う
- 最初の `get` は変える前の値（AlmaLinux 10 の既定は `'Red Hat Mono Regular 10'`）
- Ptyxis は既定でこのフォントを使うので、開いている端末もすぐに変わる

### Homebrew を root のシェルでも使う（任意） / 手順 2: 補足: Homebrew を消したとき

- Homebrew 自体を削除した場合は、共通設定が自動で読み込みを省略する

### Homebrew を sudo でも使う（任意） / 手順 1: 補足: 使い方

- Homebrew で入れたコマンドを、`sudo jq --version` のように打てる
- `sudo` でどれが使われるかは、`sudo bash -c 'type -a <コマンド>'` で見る（先頭の行が使われる）

### Homebrew を sudo でも使う（任意） / 手順 2: 補足: root のシェルの PATH

- [Homebrew を root のシェルでも使う（任意）](../almalinux-setup.md#homebrew-を-root-のシェルでも使う任意)の節も通していれば、root のシェル（`sudo -i` も）では、root の共通の bash 設定が Homebrew を PATH に入れたまま

### starship のプリセットを当てる（任意） / 手順 2: 補足: --force と再初期化

- starship は設定ファイルをプロンプトのたびに読む
- `--force` は既存のファイルを置き換える。付けないと既存設定がある場合に拒否されるので、節の先頭のとおり先に退避する
- 共通設定は初期化済みの starship を再初期化しない。手で `eval "$(starship init bash)"` を重ねると `PS0` が重複するため、追加で実行しない

### starship の設定ファイル / 手順 1: 補足: 編集と置き場所

- `starship config` で `$EDITOR` が開く
- 設定の場所を変えたいときは、starship 自身が読む環境変数 `STARSHIP_CONFIG` を `~/.bashrc` で `export` する

### starship でユーザー名とホスト名を常に表示する（任意） / 手順 1: 補足: starship config

- 既存の設定を保ち、常時表示に必要な 2 項目だけを更新する。設定ファイルが無ければ作られる

### fzf で fd と bat を候補とプレビューに使う（任意） / 手順 1: 補足: fd-find と二重に入れない理由

- EPEL の `fd-find` も Homebrew の fd も `fd` で、PATH の先頭の Homebrew 版が使われる

### fzf で fd と bat を候補とプレビューに使う（任意） / 手順 2: 補足: 変数を入れる時期

- 共通の bash 設定は、端末を開くときに fd と bat を見つけて変数を入れる

### fzf で fd と bat を候補とプレビューに使う（任意） / 手順 4: 補足: コマンドの中のプレビュー

- コマンドの中で同じプレビューを使うなら、`fzf --preview 'bat --color=always --style=numbers {}'`

### fzf で fd と bat を候補とプレビューに使う（任意） / 手順 5: 補足: 消した後

- 開き直した端末から、共通の bash 設定は候補の 3 つの変数を入れず、候補は fzf の既定の一覧に戻る
- yazi.md の `YAZI_EXTRAS` で入れた fd を消さないのは、yazi の検索が使うため

### bat の設定ファイル / 手順 1: 補足: テーマと言語とキャッシュ

- テーマの一覧は `bat --list-themes`、認識する言語の一覧は `bat --list-languages`
- 自前のシンタックス定義やテーマを足したときだけ `bat cache --build` が要る（キャッシュの場所は `bat --cache-dir`）

### tmux の設定ファイル（任意） / 手順 2: 補足: 読み込みとホイール

- 既存・新規のどちらの設定ファイルも、起動時と同じ順で読み込む。既存セッションのマウス設定にも反映する
- tmux の中でホイールを上へ回すと、さかのぼって読める（右上に `[5/258]` のような位置が出る）。下まで回すか `q` で戻る

### Claude Code を tmux の中で動かす（任意） / 手順 2: 補足: ディレクトリ

- ホームを選ばないのは、Claude Code がホームの信頼を保存しないため（[Windows の手順書](../windows-claude-remote-control.md#実施手順)の手順 2）
- 同じ節の手順 4 は、tmux の中で見た作業ディレクトリの名前を Remote Control のセッション名にする

### Claude Code を tmux の中で動かす（任意） / 手順 6: 補足: 切った後

- tmux のセッションと、その中の Claude Code は、このホストで動き続ける

### 更新 / 手順 2: 補足: 自動更新

- `brew install` / `brew upgrade` は既定で自動更新が走るので、普段は `brew update` を明示しなくてよい（抑えるには `HOMEBREW_NO_AUTO_UPDATE=1`）

### 更新 / 手順 3: 補足: 確認と、上げた後の tmux・fzf・zoxide

- `[y/n]` を聞く条件は[注意点](../extra/almalinux-setup.md#注意点)
- 動いている tmux のサーバーは、前の版のまま動き続ける。新しい版を使うのは、セッションを全部閉じて `tmux ls` が `no server running on …` になってから
- fzf は、開いているシェルには前の版の `fzf --bash` が読まれたまま。新しい端末から新しい版になる。zoxide のデータベース（`~/.local/share/zoxide/db.zo`）は更新で消えない

### 選択した方針

- **1 本の手順書にまとめた**: インストールした直後に行う作業を、上から順に貼れば終わる形にした（利用者の依頼。Windows 11 の [windows-setup.md](../windows-setup.md) と同じ形）
  - もとは、更新・sudo・SSH などの OS の作業はどの手順書にも無く、導入元（EPEL・RPM Fusion・Flathub・Homebrew）・日本語入力・電源・シェルのツールは、13 本の手順書に分かれていた
  - 13 本（epel・rpmfusion・bash-settings・homebrew・flatpak・japanese-input・gnome-power・starship・zoxide・fzf・eza・bat・tmux）は、この文書に入れて消した。もとの参考資料は、この文書の[統合前の参考資料](#統合前の参考資料-epelもとは-epelmd)以下に、中身を変えずに移した
  - ほかの手順書が前提にしていたもの（EPEL・RPM Fusion・Homebrew・Flathub・画面オフの設定）は、使う側の手順書がこの文書の手順番号か節を名指しする
  - AlmaLinux 10 と Windows 11 の両方を対象にする手順書（git・firefox・hackgen・wezterm-nightly・claude-code・codex・grok-build）は、OS ごとの節があるので残し、リードから順に案内する
- **sudo をパスワード無しにする（「ログインと sudo」の手順 3）**: このリポジトリの手順書は、`sudo` の後ろに続く行がパスワードの入力に食われないように、NOPASSWD を前提に書いてある（README の記法）。それを設定する手順が無かったので、最初に置いた
  - `/etc/sudoers.d/nopasswd` に、このユーザーだけの 2 行を置く。`/etc/sudoers` の `%wheel ALL=(ALL) ALL` は残す（ロールバックで、ファイルを消せば元に戻る）
  - `Defaults:<USER> verifypw=any` も置く。`sudo -v`（`-v` は資格を更新するだけ）は、`verifypw` の既定の `all` では、そのユーザーに当たるすべての行が NOPASSWD のときだけパスワードを聞かない。`%wheel` の行が残るので、`verifypw=any` が無いと Homebrew のインストーラの `sudo -v` がパスワードを聞いた（sudoers(5) の `verifypw`）
  - 書く前に `visudo -cf -` で確かめ、`install -m 0440` で置き、最後に `visudo -c` で全体を確かめる（書式の誤りがあると `sudo` そのものが使えなくなるため）
- **ファームウェアは fwupd（「OS とファームウェアの更新」の手順 2・3）**: Workstation に入っている `fwupdmgr` で、LVFS から入れる。AlmaLinux 10 の既定では LVFS のリモートが無効で、`refresh` が有効にするかを聞く
  - `--assume-yes` を付けても、この問いは出た。問いに答える手順として、`refresh` と `update` を分けた
- **journal を永続にする（「システムの設定」の手順 5）**: `/etc/systemd/journald.conf.d/` のドロップインで `Storage=persistent` にする（`/etc/systemd/journald.conf` は書き換えない）
  - journald が作った `/var/log/journal` には、`systemd-journal` のグループと ACL が付かなかった。`systemd-tmpfiles --create --prefix /var/log/journal` で、パッケージの tmpfiles の定義どおりに付け直す
  - tmpfiles の定義（`/usr/lib/tmpfiles.d/systemd.conf` の `z`・`a+`）は、すでにあるものだけを直す。`/var/log/journal` は `journalctl --flush` のときに作られるので、tmpfiles はその後に行う（前に行うと、何も直らなかった）
  - 元に戻すときは、`journalctl --relinquish-var` で journald に `/var/log/journal` を手放させてから消す。手放させずに消すと、動いている journald がすぐに作り直し、`Storage=auto` のまま書き続けた
- **kdump を止める（「システムの設定」の手順 6・7）**: カーネルが落ちたときの記録が要らない PC では、予約されるメモリー（`crashkernel=`）を空ける
  - `/etc/kdump.conf` の `auto_reset_crashkernel` を `no` にする。`yes` のままだと、カーネルを入れたときに kernel-install の `92-crashkernel.install` が `crashkernel=` を付け直す
  - `crashkernel=` は `grubby --update-kernel=ALL --remove-args=crashkernel` で、入っているすべてのカーネルの起動の項目から外す
- **PackageKit-command-not-found を外す（「システムの設定」の手順 8）**: 無いコマンドを打つたびにリポジトリを探して待たされるため。パッケージは `dnf provides` で探す
- **ホームのフォルダーの名前を英語にする（「GNOME の表示と入力」の手順 1）**: 端末で打ちやすく、Homebrew・WezTerm などの既定の場所と合わせるため
  - `xdg-user-dirs-update --force` は空のフォルダーを作り直すだけで、中身を移さない。中身を残すために、フォルダーを `mv` してから `xdg-user-dirs-update --set` で場所を書き換える
  - Files のサイドバーのブックマーク（`~/.config/gtk-3.0/bookmarks`）も、日本語の名前の URI のままになるので書き換える
  - `~/.config/user-dirs.locale` を今のロケールに合わせる。xdg-user-dirs-gtk は、このファイルのロケールが今のロケールと違うときに、ログインで「標準フォルダーの名前を現在の言語に合わせて更新しますか?」の窓を出す（xdg-user-dirs-gtk のソース）
- **GNOME の設定は `gsettings` の読み戻しで確かめる**: `gsettings` は書けなかったときも終了コード 0 で終わる。`/usr/bin/gsettings` で呼ぶ（Homebrew の glib の `gsettings` は dconf に書かない。統合前の[画面オフ・ロック・サスペンドの記録](../verification/almalinux-setup.md#画面オフロックサスペンド-実施手順--手順-2-補足-変える前の値0-にしても暗くなる理由設定アプリの項目)）
  - 一覧の値（`xkb-options`・`experimental-features`・`custom-keybindings`）は、まるごと置き換えず、無ければ足す。ほかの設定で入っている値を消さないため
- **Caps Lock を Ctrl に（「GNOME の表示と入力」の手順 3）**: XKB の `ctrl:nocaps`（xkeyboard-config の説明は「Caps Lock as Ctrl」）を `xkb-options` に足す。Caps Lock の働きは無くなる。自分のセッションの設定なので、ログイン画面と仮想コンソールは変わらない
- **拡大率（「GNOME の表示と入力」の手順 9）**: GNOME の設定に 125%・150% などの拡大率を出すのは、mutter の実験的な機能 `scale-monitor-framebuffer`。`xwayland-native-scaling` は、X11 のアプリをぼやけさせずに拡大する（mutter 49 の gschema の説明）。AlmaLinux 10.2 の mutter 49.4 の既定は `[]`
- **トレイアイコン（「GNOME の表示と入力」の手順 10・11）**: EPEL の `gnome-shell-extension-appindicator`（AppIndicator と KStatusNotifierItem を扱う）。AppStream の `gnome-shell-extension-status-icons` は、旧来の XEmbed のトレイアイコンだけを扱い、今のアプリが使う AppIndicator / KStatusNotifierItem を出さない
- **Ctrl+Alt+T（「GNOME の表示と入力」の手順 12）**: GNOME 49 の media-keys には端末を開くキーが無いので、カスタムのショートカットにする。コマンドは、新しい窓を開く `ptyxis --new-window`
- **シェルのツールは 1 回の `brew install` にまとめた（「シェルのツール」の手順 1）**: 依存の確認（`[y/n]`）が 1 回で済む。初期化は共通の bash 設定が持つので、入れた後は端末を開き直すだけ
- **SSH を公開鍵だけにする（任意節）**: ドロップインのファイル名を `40-pubkey-only.conf` にする。sshd は最初に読んだ値を使い、Workstation の `50-redhat.conf` より前に読ませるため
- **dnf-automatic（任意節）**: `dnf-automatic-install.timer` で、毎日更新を入れる（再起動はしない）。GNOME Software の自動の更新（`download-updates`）は切る。2 つの仕組みが同じ更新を落とし合わないようにするため
- **Wake on LAN（任意節）**: NetworkManager の接続の `802-3-ethernet.wake-on-lan` に `magic` を入れる。`ethtool -s` で変えた値は再起動で消えるが、接続の設定は接続を上げるたびに入る

### 参照

- [sudoers(5)](https://www.sudo.ws/docs/man/sudoers.man/) — `verifypw`（`sudo -v` のときの認証の条件）と `NOPASSWD`、`/etc/sudoers.d` の読み込み
- [AlmaLinux の Security のページ](https://almalinux.org/security/) — AlmaLinux 10 の署名鍵の fingerprint
- `man fwupdmgr`（`refresh`・`update`）と [LVFS](https://fwupd.org/) — ファームウェアを配るサービス
- `man journald.conf`（`Storage=`）と `man systemd-tmpfiles`
- `man kdump.conf`（`auto_reset_crashkernel`）と `/usr/lib/kernel/install.d/92-crashkernel.install` — カーネルを入れたときに `crashkernel=` を付け直す仕組み
- [xdg-user-dirs](https://www.freedesktop.org/wiki/Software/xdg-user-dirs/) と [xdg-user-dirs-gtk](https://gitlab.gnome.org/GNOME/xdg-user-dirs-gtk) — `user-dirs.dirs`・`user-dirs.locale` と、名前を更新するかを聞く窓
- mutter 49.4 の `/usr/share/glib-2.0/schemas/org.gnome.mutter.gschema.xml` — `experimental-features` の `scale-monitor-framebuffer` と `xwayland-native-scaling` の説明
- [gnome-shell-extension-appindicator](https://github.com/ubuntu/gnome-shell-extension-appindicator) — AppIndicator / KStatusNotifierItem のトレイアイコン（EPEL のパッケージの上流）
- [dnf-automatic](https://dnf.readthedocs.io/en/latest/automatic.html) — `dnf-automatic-install.timer` と `/etc/dnf/automatic.conf`
- `man sshd_config`（最初に読んだ値が使われる）と `man nm-settings-nmcli`（`802-3-ethernet.wake-on-lan`）
- [README の共通の bash 設定を先に入れる](../../README.md#共通の-bash-設定を先に入れる) と [ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash) — 「共通の bash 設定」の手順 1〜4
- [Windows 11 の初期設定](../windows-setup.md) — Windows 11 側の同じ形の手順書

---

## 統合前の参考資料: EPEL（もとは epel.md）

もとの `epel.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜3 | 「EPEL と RPM Fusion」の手順 1 |
| 更新 1 | 更新のリード（OS は「OS とファームウェアの更新」の手順 1） |
| ロールバック 1・2 | ロールバックの「Flatpak・RPM Fusion・EPEL を消す」の手順 7・8 |

### EPEL: 補足

#### EPEL: 実施手順 / 手順 3: 補足: 出力例と、EPEL の鍵

`epel-release` は、repo ファイル（`/etc/yum.repos.d/epel.repo` と、無効の `epel-testing.repo`）と、鍵のファイル `/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-10` を置く。

取り込んだ鍵は、`rpm -q gpg-pubkey` に `gpg-pubkey-e37ed158-65785fa9` として出る（[ロールバック](../extra/almalinux-setup.md#flatpakrpm-fusionepel-を消す)の手順 2 で使う）。

#### EPEL: 参照

- [EPEL — Fedora Docs](https://docs.fedoraproject.org/en-US/epel/) — EPEL とは何か。入れ方は同じ文書の [Getting Started](https://docs.fedoraproject.org/en-US/epel/getting-started/)（CRB と `epel-release`）
- `man dnf`（`remove` の `--noautoremove`）
- [導入元一覧の導入経路と EL10 での注意](../tool-catalog.md#導入経路と-el10-での注意) — EPEL とほかの導入元の比較

---

## 統合前の参考資料: RPM Fusion（もとは rpmfusion.md）

もとの `rpmfusion.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜4 | 「EPEL と RPM Fusion」の手順 2〜5 |
| ロールバック 1・2 | ロールバックの「Flatpak・RPM Fusion・EPEL を消す」の手順 5・6 |

### RPM Fusion: 補足

#### RPM Fusion: 選択した方針

- **署名を確かめて入れる**: Configuration の `--nogpgcheck` の例は使わず、keys ページの方法（鍵を先に取り込み、`localpkg_gpgcheck=1`）にした（手順 3 の補足）
- **free だけ**: 本書を使う [Firefox の AAC・H.264](../almalinux-setup.md#firefox) は、free の `ffmpeg-libs` で足りる。nonfree は有効にしない
- **EPEL を前提にする**: `rpmfusion-free-release` が `epel-release` を要求し、RPM Fusion の Configuration も EPEL を先に有効にする順で書いている（手順 3 の補足）
- **独立した手順書にした**: リポジトリの有効化と、Firefox のために FFmpeg を入れることを分けた。EPEL の [epel.md](../almalinux-setup.md) と同じ扱い

#### RPM Fusion: 参照

- [Configuration — RPM Fusion](https://rpmfusion.org/Configuration) — free / nonfree の区別と、EL 向けの有効化（EPEL を先に有効にすること、`--nogpgcheck` の例、Alma・Rocky の `crb enable`）
- [Trusting Package Integrity — RPM Fusion](https://rpmfusion.org/keys) — 鍵の fingerprint と、鍵を先に取り込んで `localpkg_gpgcheck=1` で入れる方法
- `man dnf.conf`（`localpkg_gpgcheck`）
- [EPEL](../almalinux-setup.md) — 前提の手順書

---

## 統合前の参考資料: bash の設定（もとは bash-settings.md）

もとの `bash-settings.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 「共通の bash 設定」の手順 3 |
| 実施手順 2 | 「シェルのツール」の手順 3（今のシェルへの読み込みはやめた） |
| 実施手順 3 | 「共通の bash 設定」の手順 2 と「シェルのツール」の手順 3 |
| 実施手順 4 | 「シェルのツール」の手順 3 |
| 実施手順 5 | 「共通の bash 設定」の手順 4 |
| 実施手順 6 | 「シェルのツール」の手順 2 |
| 実施手順 7 | 「シェルのツール」の手順 3 |
| 実施手順 8 | 「キー操作を試す」の手順 1 |
| ロールバック 1 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 2 |
| ロールバック 2 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 7 |
| ロールバック 3 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 6 |
| ロールバック 4 | ロールバックの「Homebrew と bash-completion を消す」の手順 4 |
| ロールバック 5 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 8 |

### bash の設定: 補足

#### bash の設定: 選択した方針

- **bash-completion はシステムの RPM にした**: BaseOS の 2.11 で足りる。Homebrew にも `bash-completion@2`（2.16 系）があるが、RPM の各パッケージが置く `/usr/share/bash-completion/completions/` を読むのはシステムのものの方が素直で、`sudo` のシェルでも同じものが効く
- **Homebrew の補完は bash リポジトリから全部読む**: 遅延読み込みの対象のディレクトリに無いため（手順 4 の補足）。`~/.local/share/bash-completion/completions/` にシンボリックリンクを置けば遅延読み込みにできるが、入れるたびに足す手間があるので採らない
- **`~/.inputrc` を使い、`~/.bashrc` の `bind` にはしない**（手順 5 の補足）
- **採らなかった設定**
  - `HISTTIMEFORMAT`（`history` に時刻を出す）: 履歴ファイルに `#<epoch>` の行が増える。本書は履歴の見え方を変えない範囲にとどめる。欲しければ `HISTTIMEFORMAT='%F %T '` を手順 3 の行に足せばよい
  - `HISTCONTROL=…:erasedups`（同じ行を全部消して 1 つにする）: 覚えている一覧の中だけを直し、ファイルの古い重複は残る。効き目が分かりにくいので入れない
  - `PROMPT_COMMAND` に `history -a`（コマンドごとにファイルへ書き、別の端末ですぐ使う）: AlmaLinux 10 の `PROMPT_COMMAND` は配列で、starship・WezTerm のシェル統合・zoxide が順番に意味を持って触っている（[starship.md 手順 3](../almalinux-setup.md#シェルのツール) の補足）。そこへ足す形は本書では扱わない
  - `set bell-style none`（ベルを消す）、`menu-complete`（Tab で候補を順に入れる）: 好みの幅が大きいので入れない
  - `shopt -s histappend`: `/etc/bashrc` が対話のシェルで入れている（手順 3 の補足）
- **atuin（履歴を SQLite に持ち、同期もする）は使わない**: 履歴の検索は [fzf](../almalinux-setup.md) の Ctrl+R で足りる。[導入元一覧](../tool-catalog.md#cli-定番の置き換え)の行のまま

#### bash の設定: 参照

- [Bash Reference Manual — Bash Variables](https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html)（`HISTSIZE`・`HISTFILESIZE`・`HISTCONTROL`・`HISTTIMEFORMAT`）
- [Bash Reference Manual — The Shopt Builtin](https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html)（`autocd`・`cdspell`・`dirspell`・`globstar`・`histappend`）
- [Bash Reference Manual — Readline Init File](https://www.gnu.org/software/bash/manual/html_node/Readline-Init-File.html)（`$include`、`completion-ignore-case`、`show-all-if-ambiguous`、`colored-stats`、`colored-completion-prefix`、`history-search-backward`）
- [bash-completion](https://github.com/scop/bash-completion)（`_completion_loader`、`BASH_COMPLETION_USER_DIR`、`XDG_DATA_DIRS`）
- [Homebrew — Shell Completion](https://docs.brew.sh/Shell-Completion)（`etc/bash_completion.d` を読む形）
- [fzf](../almalinux-setup.md) — Ctrl+R の履歴の検索と `**<Tab>`。Homebrew の補完の行との並び
- [Homebrew](../almalinux-setup.md) — `brew shellenv` の行（手順 3）

---

## 統合前の参考資料: Homebrew（もとは homebrew.md）

もとの `homebrew.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 「Homebrew」の手順 1 |
| 実施手順 2 | 「Homebrew」の手順 2 |
| 実施手順 3・4 | 「Homebrew」の手順 3 |
| 使い方の基本 | Homebrew の使い方の基本 |
| root のシェルでも使う（任意）の 1・2 | Homebrew を root のシェルでも使う（任意）の 1・2 |
| sudo でも使う（任意）の 1・2 | Homebrew を sudo でも使う（任意）の 1・2 |
| 更新 1・2 | 更新 2・3 |
| ロールバック 1〜3 | ロールバックの「Homebrew と bash-completion を消す」の手順 1〜3 |

### Homebrew: 補足

#### Homebrew: 選択した方針

**Homebrew に揃える判断の実質は「更新の一元化」**。`brew upgrade` 1 本で、17 本の手順書（統合前の数。今はこの文書の「シェルのツール」の手順 1 と、11 本の手順書）で Homebrew から入れたものがまとめて上がる。

#### Homebrew: root のシェルで使うときの補足

| 入口 | 読むファイル | Homebrew のコマンド |
|---|---|---|
| `su -`、ssh での root のログイン | `/etc/profile` → `/root/.bash_profile` → `/root/.bashrc` | 使える（PATH の末尾） |
| `sudo -i` | 同上。PATH の始まりは sudo の `secure_path` | 使える（PATH の末尾） |
| `sudo -s`、`su`（`-` 無し） | `/root/.bashrc`（`sudo -s` でも `HOME` は `/root`） | 使える（PATH の末尾） |
| `sudo <コマンド>` | 読まない。PATH は `secure_path` の `/sbin:/bin:/usr/sbin:/usr/bin` | 使えない（`sudo: jq: command not found`）。[sudo でも使う](../almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節で使える |

- **`su`（`-` 無し）も、Homebrew のユーザーの PATH を引き継がない**: PATH は root のものに置き換わり、その末尾に足される
- **cron や systemd の unit では見えない**: `~/.bashrc` を読まないため（[注意点](../extra/almalinux-setup.md#注意点)の「`~/.bashrc` を読まない文脈」と同じ）。フルパスで書く
- **RPM と同じ名前のコマンドは、root では RPM が先**: AppStream の `jq` も入れると、`type -a jq` の並びが root と Homebrew のユーザーで逆になる

  ```
  # root のシェル
  jq is /bin/jq
  jq is /usr/bin/jq
  jq is /home/linuxbrew/.linuxbrew/bin/jq
  # Homebrew のユーザーのシェル
  jq is /home/linuxbrew/.linuxbrew/bin/jq
  jq is /usr/bin/jq
  jq is /bin/jq
  ```

#### Homebrew: sudo で使うときの補足

| 入口 | PATH | Homebrew のコマンド |
|---|---|---|
| `sudo <コマンド>`、`sudo -u <ユーザー> <コマンド>`、`sudo bash <スクリプト>` | `secure_path`（`/sbin:/bin:/usr/sbin:/usr/bin` の後ろに 2 つ） | 使える（`sudo jq --version` は `jq-1.8.2`） |
| `sudo -E <コマンド>` | 同上（`-E` でも、自分の PATH は渡らない） | 使える |
| `sudo -s` | `/root/.local/bin:/root/bin` の後ろに `secure_path` | 使える（PATH の末尾） |
| `sudo -i` | `/root/.local/bin:/root/bin:/usr/local/sbin` の後ろに `secure_path` | 使える（PATH の末尾） |
| `sudoedit`（`EDITOR=nvim`） | エディタを `secure_path` で探し、自分のユーザーと自分の環境で動かす | Homebrew の `nvim`。設定は自分の `~/.config/nvim` |
| `sudo EDITOR=nvim visudo` | エディタを `secure_path` で探し、root で動かす | Homebrew の `nvim`。設定は `/root/.config/nvim` |
| `su -`、`sudo su -`、ssh での root のログイン | sudo の `secure_path` を通らない | 使えない（[root のシェルでも使う](../almalinux-setup.md#homebrew-を-root-のシェルでも使う任意)の節で使える） |

#### Homebrew: 参照

---

## 統合前の参考資料: Flatpak（もとは flatpak.md）

もとの `flatpak.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜3 | 「Flatpak と Flathub」の手順 1 |
| 実施手順 4〜7 | 「Flatpak と Flathub」の手順 2〜5 |
| 使い方の基本 | Flatpak の使い方の基本 |
| 更新 1 | 更新 4 |
| ロールバック 1〜4 | ロールバックの「Flatpak・RPM Fusion・EPEL を消す」の手順 1〜4 |

### Flatpak: 補足

#### Flatpak: 実施手順 / 手順 4: 補足: 鍵は登録ファイルの中にある

`flathub.flatpakrepo` は鍵を**本文に base64 で埋め込んで**いて、`flatpak remote-add` はこの鍵をリモートの設定に取り込む。以後の取得はすべてこの鍵で署名を検証する。したがって、確かめるべきは「登録ファイルの中の鍵が Flathub のものか」の 1 点になる（[VS Code](../vscode.md) の手順で rpm の鍵を確かめているのと同じ考え方）。

`gpg --show-keys` は鍵を**鍵束に取り込まずに表示するだけ**。ただし `~/.gnupg` が無ければ最初の実行で作られる（`gpg: directory '/home/<USER>/.gnupg' created`）。

#### Flatpak: 参照

---

## 統合前の参考資料: 日本語入力（もとは japanese-input.md）

もとの `japanese-input.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1（変数） | 「システムの設定」の手順 1 |
| 実施手順 2・3 | 「日本語入力」の手順 1 |
| 実施手順 4 | 「日本語入力」の手順 2 |
| 実施手順 5（ログインし直す） | 「再起動と確認」の手順 1（再起動） |
| 実施手順 6 | 「再起動と確認」の手順 3 |
| 実施手順 7 | 「再起動と確認」の手順 6 |
| ロールバック 1・2 | ロールバックの「表示と入力を戻す」の手順 13・14 |

### 日本語入力: 補足

#### 日本語入力: 参照

- [Enabling Chinese, Japanese, or Korean text input — Using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/using_the_gnome_desktop_environment/customizing-the-desktop-environment) — 8.2 節。日本語は `ibus-anthy`、切り替えは Super+Space
- [ibus/ibus-anthy](https://github.com/ibus/ibus-anthy) — Anthy のエンジン
- [CentOS Stream 10 の ibus-anthy](https://gitlab.com/redhat/centos-stream/rpms/ibus-anthy) — RHEL のビルドの設定（配列 `default`、切り替えのキー）と、ひらがなで始めるパッチ

---

## 統合前の参考資料: 画面オフ・ロック・サスペンド（もとは gnome-power.md）

もとの `gnome-power.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜5 | 画面オフ・画面ロック・自動サスペンドを止める（任意）の 1〜5 |
| ロールバック 1〜4 | 同じ節の 6〜9 |

### 画面オフ・ロック・サスペンド: 補足

#### 画面オフ・ロック・サスペンド: 実施手順 / 手順 1: 補足: 変数について

- 画面を消したいなら、`IDLE_DELAY` に秒数を入れる（`300` で 5 分）。消えたときにロックもするなら `LOCK_ENABLED=true`
- 放置したときにサスペンドするかどうかは変数にしていない。手順 2・3 で `nothing`（何もしない）を直接書く
  - 手順 4 でサスペンドとハイバネートを OS ごと止めるので、ほかに選べる値が無いため
- `POWER_BUTTON` も同じ理由で、`suspend` / `hibernate` は選ばない
  - `interactive` は、設定アプリの「電源ボタンの挙動」の「電源オフ」にあたる
  - 押すと何をするかを聞く画面が出て、何も選ばなければ 60 秒で電源が切れる（RHEL 10 の文書の 13.1.2 節）

#### 画面オフ・ロック・サスペンド: 参照

- [Changing system power settings — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/changing-system-power-settings) — 電源ボタン（dconf と logind）と蓋（logind）の設定
- [gnome-settings-daemon 47.2 の電源のスキーマ](https://gitlab.gnome.org/GNOME/gnome-settings-daemon/-/blob/47.2/data/org.gnome.settings-daemon.plugins.power.gschema.xml.in) — `sleep-inactive-*`・`idle-dim`・`power-button-action` の既定値と説明
- [GDM 47.0 のログイン画面の既定の設定](https://gitlab.gnome.org/GNOME/gdm/-/blob/47.0/data/dconf/defaults/00-upstream-settings) — 電源のキーが無いこと
- `man dconf`（`dconf update` とプロファイル）/ `man 5 logind.conf`（`HandleLidSwitch`）/ `man systemctl`（`mask`）

---

## 統合前の参考資料: starship（もとは starship.md）

もとの `starship.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1（変数） | starship のプリセットを当てる（任意）の 2 |
| 実施手順 2 | 「シェルのツール」の手順 1 |
| 実施手順 3・5 | 「シェルのツール」の手順 4 |
| 実施手順 4 | 「シェルのツール」の手順 2 |
| プリセットを当てる（任意）の 1・2 | starship のプリセットを当てる（任意）の 1・2 |
| 設定ファイルの 1 | starship の設定ファイルの 1 |
| ユーザー名とホスト名を常に表示するの 1 | starship でユーザー名とホスト名を常に表示する（任意）の 1 |
| 更新 1 | 更新 3 |
| ロールバック 1 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 3 |
| ロールバック 2・3 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 5 |

### starship: 補足

#### starship: 実施手順 / 手順 1: 補足: 変数について

- `${STARSHIP_PRESET}` は[プリセットを当てる（任意）](../almalinux-setup.md#starship-のプリセットを当てる任意)でしか使わない
- 既定を `plain-text-symbols` にしてあるのは、Nerd Font が無い環境でも文字化けしないため

#### starship: 実施手順 / 手順 2: 補足: 降ってくるボトル

[検証記録](../verification/almalinux-setup.md#starship-参考資料から分離した記録)

#### starship: 設定ファイル / 手順 1: 補足: 調べるときに使うサブコマンド

| コマンド | 用途 |
|---|---|
| `starship explain` | 今のプロンプトの各部分が何を表しているか |
| `starship timings` | モジュールごとの所要時間。プロンプトが遅いときの犯人探し |
| `starship module <名前>` | 1 モジュールだけ描画して確かめる |
| `starship print-config` | 実効設定を表示 |

#### starship: 選択した方針

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `arm64_linux` ボトルを使える | **採用** |
| 公式 install.sh（`sh -c "$(curl -sS https://starship.rs/install.sh)"`） | `/usr/local/bin` にバイナリを 1 つ置く。`sudo` が要り、更新は自分で再実行する | 不採用（Homebrew に揃える） |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-musl` のビルドがある。更新は手作業 | 不採用 |
| `cargo install starship` | Rust toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

#### starship: 参照

- [starship.rs](https://starship.rs/) — 公式サイト。インストールと各シェルでの `init` の書き方
- [starship — Configuration](https://starship.rs/config/) — `starship.toml` の全モジュールと項目
- [starship — Presets](https://starship.rs/presets/) — プリセット一覧とスクリーンショット、Nerd Font が要るかどうか
- `starship --help` / `starship init bash --print-full-init` — サブコマンドと、シェルに入る初期化の中身
- [Homebrew](../almalinux-setup.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

---

## 統合前の参考資料: zoxide（もとは zoxide.md）

もとの `zoxide.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 「共通の bash 設定」の手順 2 |
| 実施手順 2 | 「シェルのツール」の手順 1 |
| 実施手順 3・4 | 「シェルのツール」の手順 9 |
| 実施手順 5 | 「シェルのツール」の手順 10 |
| 更新 1 | 更新 3 |
| ロールバック 1 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 3 |
| ロールバック 2 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 8 |
| ロールバック 3 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 5 |

### zoxide: 補足

#### zoxide: 参照

- [ajeetdsouza/zoxide — README](https://github.com/ajeetdsouza/zoxide) — 各 OS のインストール方法、シェルごとの `zoxide init` の書き方、`--cmd` の説明
- [zoxide — Installation](https://github.com/ajeetdsouza/zoxide#installation) — 公式 install.sh と各ディストリビューションの状況
- `zoxide --help` / `zoxide query --help` — `query --list` / `--score`、`remove`
- [Homebrew](../almalinux-setup.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作
- [kray74/cli-tools — Copr](https://copr.fedorainfracloud.org/coprs/kray74/cli-tools/) — chroot（`epel-10-x86_64` と `fedora-44-x86_64`）とビルドの履歴
- [kray74/cli-tools — GitHub](https://github.com/kray74/cli-tools) — COPR の spec（`zoxide/zoxide.spec`）

---

## 統合前の参考資料: fzf（もとは fzf.md）

もとの `fzf.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 「シェルのツール」の手順 1 |
| 実施手順 2・3 | 「シェルのツール」の手順 5 |
| 実施手順 4〜7 | 「キー操作を試す」の手順 2〜5 |
| 使い方の基本 | fzf の使い方の基本 |
| fd と bat を候補とプレビューに使う（任意）の 1・2 | fzf で fd と bat を候補とプレビューに使う（任意）の 3・4（fd を入れる 1 と、開き直す 2 を足した） |
| 更新 1 | 更新 3 |
| ロールバック 1 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 4 |
| ロールバック 2 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 8 |

### fzf: 補足

#### fzf: 実施手順 / 手順 1: 補足: 依存と、入れてあるホストで貼る意味

[この節の検証記録](../verification/almalinux-setup.md#fzf-実施手順--手順-1-補足-依存と入れてあるホストで貼る意味)

- fzf の依存は `ncurses` だけ（`brew deps fzf`）
- yazi.md や zoxide.md で入れた fzf は、`brew install zoxide fzf` のように名前を挙げて入れているので、Homebrew の「頼まれて入れた」印（`installed_on_request`）が付いている。`brew install fzf` を貼り直しても害は無く、印が無かったホストでは付く（印が無いと、zoxide や yazi を `brew uninstall` した際の自動削除や、明示的な `brew autoremove` で fzf も消えうる）

#### fzf: 参照

- [fzf — README](https://github.com/junegunn/fzf#readme)（Key bindings for command-line、Fuzzy completion for bash、Search syntax、Environment variables）
- [fzf — ADVANCED.md](https://github.com/junegunn/fzf/blob/master/ADVANCED.md)（プレビューの例）
- `man fzf`（`--preview`・`--line-range` は bat 側）
- [Homebrew の fzf の formula](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/f/fzf.rb)（caveat の `fzf --bash`）
- [bash の履歴・補完・キー操作](../almalinux-setup.md) — bash-completion と Homebrew の補完、`~/.inputrc`。fzf の行との並び
- [zoxide](../almalinux-setup.md) — `zi` が fzf を使う。[yazi](../almalinux-setup.md#yazi) — `z` / `Z` キーが fzf を使う
- [bat](../almalinux-setup.md) — プレビューに使う。[Homebrew](../almalinux-setup.md) — Homebrew 本体の導入と、Homebrew 系に共通の注意

---

## 統合前の参考資料: eza（もとは eza.md）

もとの `eza.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 「共通の bash 設定」の手順 2 |
| 実施手順 2 | 「シェルのツール」の手順 1 |
| 実施手順 3 | 「シェルのツール」の手順 6 |
| エイリアスを足す（任意）の 1 | 「シェルのツール」の手順 6 |
| 表示を調整する | eza の表示を調整する |
| 更新 1 | 更新 3 |
| ロールバック 1 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 3 |
| ロールバック 2 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 8 |

### eza: 補足

#### eza: 実施手順 / 手順 2: 補足: 降ってくるボトル

aarch64 で降ってくるボトルは `eza--0.23.5.arm64_linux.bottle.tar.gz`。

#### eza: 選択した方針

[この節の検証記録](../verification/almalinux-setup.md#eza-選択した方針)

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `eza 0.23.5` の `arm64_linux` ボトルがある。upstream の最新と一致 | **採用** |
| EPEL / AppStream / CRB | **`eza` も、前身の `exa` も無い**（`dnf list --available eza exa` → `Error: No matching Packages to list`） | 使えない |
| 公式の deb リポジトリ | eza は Debian/Ubuntu 向けの apt リポジトリを配っているが、**RPM 版の配布は無い** | 使えない |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-gnu` / `musl` のビルドがある。展開して PATH に置くだけだが、更新は手作業 | 不採用（Homebrew に揃える） |
| `cargo install eza` | Rust toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

#### eza: 参照

- [eza-community/eza — README](https://github.com/eza-community/eza) — 使い方、各ディストリビューションでの入手方法、`ls` との違い
- [eza.rocks](https://eza.rocks) — 公式サイト。スクリーンショットと機能一覧
- `eza --help` / `man eza` — 全オプション（`--help` は 86 行）
- [Homebrew](../almalinux-setup.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

---

## 統合前の参考資料: bat（もとは bat.md）

もとの `bat.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1（変数） | bat の設定ファイルの 1 |
| 実施手順 2 | 「シェルのツール」の手順 1 |
| 実施手順 3 | 「シェルのツール」の手順 7 |
| ページャに使う（任意）の 1 | 「シェルのツール」の手順 7 |
| ページャに使う（任意）の 2 | fzf で fd と bat を候補とプレビューに使う（任意）の 4 の箇条書き |
| 設定ファイルの 1 | bat の設定ファイルの 1 |
| 更新 1 | 更新 3 |
| ロールバック 1 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 3 |
| ロールバック 2 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 5 |
| ロールバック 3 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 8 |

### bat: 補足

#### bat: 実施手順 / 手順 1: 補足: 変数について

- `ansi` は「端末が設定している 16 色をそのまま使う」テーマで、端末の配色を変えたときに追従する。固定の配色にしたいなら `bat --list-themes` から選ぶ

#### bat: 参照

- [sharkdp/bat — README](https://github.com/sharkdp/bat) — 使い方、テーマ、`MANPAGER` や `fzf` との組み合わせ、他ツールとの連携例
- [bat — Customization](https://github.com/sharkdp/bat#customization) — 設定ファイルの書式、テーマとシンタックスの追加手順
- `bat --help` / `bat --list-themes` / `bat --list-languages` — フラグとテーマ・言語の一覧
- [Homebrew](../almalinux-setup.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

---

## 統合前の参考資料: tmux（もとは tmux.md）

もとの `tmux.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 「シェルのツール」の手順 1 |
| 実施手順 2 | 「シェルのツール」の手順 8 |
| 実施手順 3〜5 | 「tmux を試す」の手順 1〜3 |
| 使い方の基本 | tmux の使い方の基本 |
| 設定ファイル（任意）の 1・2 | tmux の設定ファイル（任意）の 1・2 |
| Claude Code を tmux の中で動かす（任意）の 1〜8 | 同じ節の 1〜8 |
| 更新 1 | 更新 3 |
| ロールバック 1 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 1 |
| ロールバック 2 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 3 |
| ロールバック 3 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 5 |

### tmux: 補足

#### tmux: 設定ファイル（任意） / 手順 1: 補足: 読み込む場所と、足さなかった行

- Homebrew の tmux のシステムの設定ファイルは `/home/linuxbrew/.linuxbrew/etc/tmux.conf`（`man tmux`）。`/etc/tmux.conf` は読まない
- `escape-time`（Esc の後に待つ時間）は、3.7c の既定ですでに 10 ミリ秒なので足さない。Neovim などのために 0〜10 にする例は、古い版の既定の 500 ミリ秒を縮めるためのもの
- Claude Code の公式ドキュメントには、tmux の設定の推奨は無かった（Shift+Enter のための `extended-keys` なども）。本書では足していない

#### tmux: Claude Code を tmux の中で動かす（任意） / 手順 1: 補足: claude auth status を最後に置く理由

- ブラケットペースト無しで貼ると、`claude auth status --text` は、端末に残っていた後ろの行を読んで捨てた（後ろの `tmux -V` や `echo` が実行されなかった）
#### tmux: 参照

- [tmux — Getting Started](https://github.com/tmux/tmux/wiki/Getting-Started) — セッション・ウィンドウ・ペインとキーの説明
- `man tmux`（`new-session` の `-A` と `-d`、`attach-session` の `-d`、`history-limit`、`mouse`、設定ファイルを読む場所）
- [Homebrew の tmux の formula](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/t/tmux.rb)
- [Continue local sessions from any device with Remote Control](https://code.claude.com/docs/en/remote-control) — `claude remote-control`、`--spawn`、Limitations（SSH の切断後も残すには tmux か screen、10 分の終了）、4 時間以内の再開
- [Interactive mode](https://code.claude.com/docs/en/interactive-mode) — `Ctrl+B`（tmux では 2 回）
- [Claude Code](../almalinux-setup.md#claude-code) — 導入とログイン、`claude` のコマンドラインの使い方
- [Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md) — 同じことを Windows で行う手順書
- [Homebrew](../almalinux-setup.md) — Homebrew 本体の導入と、Homebrew 系に共通の注意

---

## 統合前の参考資料: Git（もとは git.md）

もとの `git.md` の参考資料を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の参考資料](windows-setup.md#統合前の参考資料-git-の-windows-11もとは-gitmd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 「Git」の手順 1 |
| 実施手順 2（`dnf install git`） | （外した。git は「Homebrew」の手順 1 で入る） |
| 実施手順 3〜11 | 「Git」の手順 2〜10 |
| 改行を変換して clone したリポジトリを直すの 1〜4 | 改行を変換して clone したリポジトリを直すの 1〜4 |
| 更新 1 | 更新のリード（OS の更新で上がる） |
| ロールバック 1〜5 | ロールバックの「Git の道具を消す」の手順 9〜13 |

[検証記録](../verification/almalinux-setup.md#git-参考資料から分離した記録)

### Git: 補足

#### Git: 実施手順 / 手順 1: 補足: 変数について

- GitHub に push するなら、メールアドレスに GitHub の noreply のアドレス（`<ID>+<GITHUB_USER>@users.noreply.github.com`）を使うと、私用のアドレスをコミットに載せずに済む。アドレスは GitHub の Settings の Emails で確かめる
- 名前に空白を入れるときは、引用符の中に書く（引用符が無いと、空白の後ろがコマンドとして実行される）
- 使うのは手順 4 だけ。後から変えるときは、手順 1 と手順 4 を貼り直す（`git config --global` は同じキーを上書きする）
- 変数はそのシェルの中だけで有効

#### Git: 実施手順 / 手順 5: 補足: 設定の意味

- `pull.rebase true`: `git pull` が、取ってきた履歴の上に自分のコミットを載せ直す（マージコミットを作らない）
- `rebase.autoStash true`: 未コミットの変更があっても pull できる（pull の前に stash し、後で戻す）
- `core.autocrlf false`: チェックアウトでもコミットでも、改行を変換しない

#### Git: 実施手順 / 手順 6: 補足: 推奨の設定と、入れなかった設定

| キー | 値 | 変わること |
|---|---|---|
| `init.defaultBranch` | `main` | `git init` の最初のブランチを `main` にする |
| `core.quotepath` | `false` | 日本語のファイル名を、`"\346\227\245…"` と書かずにそのまま出す |
| `fetch.prune` | `true` | fetch・pull のたびに、リモートで消えたブランチの追跡ブランチ（`origin/…`）を消す。ローカルのブランチは消さない |
| `push.autoSetupRemote` | `true` | 新しいブランチの最初の `git push` で、`-u origin <ブランチ>` を付けなくても追跡を設定する |
| `rerere.enabled` | `true` | 一度解いた衝突の解き方を覚え、同じ衝突に当たったら自動で当てる。rebase で同じ衝突を何度も解かずに済む |
| `merge.conflictStyle` | `zdiff3` | 衝突の表示に、共通の祖先の内容も出す（git 2.35 以降） |
| `diff.algorithm` | `histogram` | 差分の取り方。既定の `myers` より、関数を動かしたときなどに読みやすい差分になりやすい |
| `branch.sort` | `-committerdate` | `git branch` を、最近コミットしたブランチから並べる |
| `tag.sort` | `version:refname` | `git tag` を版の順（`v1.9` の後に `v1.10`）に並べる |

- 要らないものは、[ロールバック](../extra/almalinux-setup.md#git-の道具を消す)の手順 1・4 に従い、そのキーだけ元の設定に戻せる
- `merge.conflictStyle zdiff3` は [git-delta.md 手順 3](../almalinux-setup.md#git-delta) と同じ設定で、どちらを先に通してもよい

入れなかったもの:

- `core.editor`: 好みで決める。未設定なら、環境変数 `VISUAL`・`EDITOR` のエディタ、どちらも無ければ `vi` が開く。Windows では、インストーラで選んだエディタが `system` に入る
- `rerere.autoUpdate`: 覚えた解き方を当てた後に、`git add` までする。当てた結果を `git diff` で見てから add したいので入れない
- `fetch.pruneTags`: リモートに無いタグを、ローカルからも消す
- `pull.ff only`: 分岐したときの pull が、rebase せずに止まる（手順 8）
- `push.default`: 既定の `simple`（今のブランチを、同じ名前の追跡ブランチにだけ push する）のままでよい

#### Git: 実施手順 / 手順 7: 補足: pull.ff

- 最後の `pull.ff` が何も出さないのは、設定が無いこと

#### Git: 実施手順 / 手順 9: 補足: 確かめている設定

- `?? 日本語.txt` がそのまま出るのは `core.quotepath`
- `i/crlf  w/crlf` は、CRLF のまま入ったこと（`core.autocrlf`）
- ブランチの `main` は `init.defaultBranch`
- `branch 'main' set up to track 'origin/main'.` は `push.autoSetupRemote`

#### Git: 実施手順 / 手順 10: 補足: 残る変更

- `M crlf.txt` は、pull の前の、未コミットの変更

#### Git: 改行を変換して clone したリポジトリを直す / 手順 2: 補足: 保存しなかったとき

- `No local changes to save` は、今回は保存していないこと

#### Git: 改行を変換して clone したリポジトリを直す / 手順 4: 補足: 別の stash を作らない理由

- `pop` は先頭の stash を戻すため

#### Git: 更新 / 手順 1: 補足: dnf upgrade

- 通常の `sudo dnf upgrade` にも含まれる

#### Git: ロールバック / 手順 1: 補足: 残るもの

- `rerere.enabled` で覚えた解き方は、各リポジトリの `.git/rr-cache` に残る。要らなければ手で消す
- `git init` 済みのリポジトリのブランチ名（`main`）は変わらない

#### Git: 選択した方針

| 経路 | 状況 | 採否 |
|---|---|---|
| **winget の `Git.Git` を `--scope machine` で** | 上流のインストーラを、winget が sha256 を確かめてから黙って動かす。`C:\Program Files\Git` に入り、`winget upgrade` で上がる。管理者の権限が要る | **採用** |
| winget の `--scope user` | 同じインストーラで、winget はスコープのスイッチを渡さない。入る先はインストーラが権限で決める | 不採用（PC 全体に入れるので、winget にも `machine` を指定する） |
| 上流のインストーラを落として、画面で入れる | 選択を画面で選べる。版の確認と更新は手作業 | 不採用 |
| scoop の `main/git` | Git for Windows の持ち運び版（PortableGit）を `~\scoop\apps\git` に入れ、`git` などを `~\scoop\shims` に置く。`C:\Program Files\Git\bin\bash.exe` が無い | 不採用（[Windows の OpenSSH サーバー](../windows-setup.md#ssh-の既定のシェルを-git-bash-にする任意)が `C:\Program Files\Git` を前提にしている。[Windows 11 の初期設定](../windows-setup.md)も、scoop の git を入れなくなった） |

- **インストーラの選択は既定のまま**（winget の `--custom` や `--override` で `/o:` を渡さない）
  - 本書は `system` を変えず `global` で上書きするので、`system` の `core.autocrlf=true`・`pull.rebase=false`・`init.defaultBranch=master` は既定のままでよい（[実施手順](../almalinux-setup.md#git)の手順 7 で確かめる）
  - 既定の PATH の選択（`cmd` だけを足す）で、PowerShell・scoop・Claude Code から `git` が見つかる。Unix の道具まで足す選択は、Windows の `find`・`sort` を隠す（インストーラの画面の警告）
  - `--override` は、winget が渡す黙って動かすスイッチ（`/SP- /SILENT …`）ごと置き換える（winget のソース）
- **Git for Windows は、scoop の `scoop update` が使う git も兼ねる**
  - scoop は、scoop の git が入っていなければ `PATH` の `git` を使う（[Windows 11 で Git for Windows を入れる](../windows-setup.md#git-for-windows)の手順 5 の補足）

#### Git: 参照

- `git help config` — 各キーの意味と既定値、設定の場所の順（`system` / `global` / `local`）
- `git help pull` — `--rebase`、`--autostash`、`pull.ff`
- `git help gitattributes` — `text`・`eol` と `core.autocrlf` の関係
- `git help rerere` — 解き方の記録と `forget`
- [Git for Windows](https://gitforwindows.org/) — 公式のサイト
- [winget-pkgs の `Git.Git`](https://github.com/microsoft/winget-pkgs/tree/master/manifests/g/Git/Git) — winget の定義（スコープ・インストーラの種類・スイッチ・sha256）
- [Silent or Unattended Installation](https://gitforwindows.org/silent-or-unattended-installation) — Git for Windows のインストーラを黙って動かすときのスイッチと、`/o:` で渡せる選択の一覧
- [git-for-windows/build-extra の `installer/install.iss`](https://github.com/git-for-windows/build-extra/blob/main/installer/install.iss) — インストーラの既定の選択、入れる先、`system` に書く値
- [Git for Windows のリリースノート](https://github.com/git-for-windows/build-extra/blob/main/ReleaseNotes.md) — 2.56.0 の `mingw64` から `ucrt64` への変更
- [microsoft/winget-cli](https://github.com/microsoft/winget-cli) — `ShellExecuteInstallerHandler.cpp`（インストーラに渡すスイッチ）、`ManifestCommon.cpp`（Inno Setup の既定のスイッチ）、`UninstallFlow.cpp`（削除のコマンド）、`doc/Settings.md`（スコープの既定）
- [Inno Setup の Uninstaller Command-Line Parameters](https://jrsoftware.org/ishelp/topic_uninstcmdline.htm) — 削除のプログラムの `/SILENT`
- [Claude Code の Set up Claude Code](https://code.claude.com/docs/en/setup) — Windows で Git for Windows があれば Bash のツールに Git Bash を使うこと、`CLAUDE_CODE_GIT_BASH_PATH`
- [Pro Git 8.1 Git の設定](https://git-scm.com/book/ja/v2/Git-%E3%81%AE%E3%82%AB%E3%82%B9%E3%82%BF%E3%83%9E%E3%82%A4%E3%82%BA-Git-%E3%81%AE%E8%A8%AD%E5%AE%9A) — `core.autocrlf` の説明

---

## 統合前の参考資料: Firefox（もとは firefox.md）

もとの `firefox.md` の参考資料を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の参考資料](windows-setup.md#統合前の参考資料-firefox-の-windows-11もとは-firefoxmd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜11 | 「Firefox」の手順 1〜11 |
| 更新 1 | 更新のリード（OS の更新で上がる） |
| ロールバック 1〜5 | ロールバックの「Firefox を戻す」の手順 1〜5 |

### Firefox: 補足

#### Firefox: 実施手順 / 手順 1: 補足: 扱う範囲

- ESR / Beta の導入・確認・ロールバックは本書では扱わない
- 手順 1 のブロックは、最後の行で値を読み戻す

#### Firefox: 実施手順 / 手順 3: 補足: 期限切れの副鍵の warning

- `rpm --import` が出す期限切れの副鍵についての warning は、署名に使う副鍵が別にあるので問題ない

#### Firefox: 実施手順 / 手順 4: 補足: priority は保険

[この節の検証記録](../verification/almalinux-setup.md#firefox-実施手順--手順-4-補足-priority-は保険)

Mozilla の案内する repo ファイルには `priority` が無い。`priority=10`（数字が小さいほど優先）は、将来のリポジトリ間の優先順位に備えて足している。

将来 AppStream 側の ESR が Mozilla 側の版を追い越す状況（Mozilla 側でリリースが巻き戻る、ESR が別番号体系になる、など）に備えた保険として残している。

`repo_gpgcheck=0` は Mozilla の案内どおりで、**パッケージの署名は検証する（`gpgcheck=1`）がリポジトリメタデータには署名が無い**、という意味。

このリポジトリは `baseurl` に `$basearch` を含まない**全アーキテクチャ共通**の作りなので、`dnf list` には `firefox.x86_64` の行も出る。インストールされるのは実行中のアーキテクチャのものだけ。

#### Firefox: 実施手順 / 手順 11: 補足: 起動し直す理由

- 起動中の Firefox は FFmpeg を読み直さない

#### Firefox: 更新 / 手順 1: 補足: RPM 版の更新

- Firefox 内蔵の自動更新機能は RPM 版では無効で（`/usr/lib/firefox` に一般ユーザーの書き込み権が無い）、更新は dnf 側で行う
- 本体だけ上げて言語パックを取り残すと UI が英語に戻るので、両方まとめて上げる

#### Firefox: 選択した方針

[この節の検証記録](../verification/almalinux-setup.md#firefox-選択した方針)

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Mozilla 公式 RPM リポジトリ** | `packages.mozilla.org/rpm/firefox` に `firefox` 156.0.1 / `firefox-esr` 153.3.0esr / `firefox-beta` 157.0b4 と各言語パックがあり、**aarch64 と x86_64 の両方**が揃っている。dnf 管理で更新できる | **採用** |
| AppStream の `firefox` | 140.15.0（ESR 140 系）。AlmaLinux がセキュリティ更新を出すが、最新版の機能は入らない | 不採用（最新版ではない） |
| Flathub の `org.mozilla.firefox` | Mozilla 公式ビルド。flathub と runtime の導入が必要で、RPM と二重管理になる | 不採用（RPM で足りる） |
| 公式 tarball を `/opt` に展開 | `linux-aarch64` のビルドが公式にある（Firefox 136 以降）。更新は Firefox 内蔵のアップデータ任せで、`.desktop` を自作する必要がある | 不採用（dnf で管理できない） |
| ソースビルド | 実用的でない | 不採用 |

**AAC と H.264 を OS の FFmpeg で補う理由**:

| 経路 | AAC | H.264 | 採否 |
|---|---|---|---|
| 何も足さない | 再生できない | OpenH264 が落ちるまでは再生できない。落ちた後は再生できる | —（元の状態） |
| **RPM Fusion（free）の `ffmpeg-libs` 7.1.5** | 再生できる | 再生できる（FFmpeg で復号） | **採用** |
| EPEL の `libavcodec-free` 7.1.2 | 再生できる | **再生できない**。H.264 を OpenH264 に任せる作りで、EL10 には中身の無い `noopenh264` しか無い。about:support には「対応」と出るのに `Couldn't open avcodec` で止まり、落ちてきた OpenH264 にも切り替わらない | 不採用 |
| RPM Fusion の `libavcodec-freeworld` | — | — | 不採用（EPEL の `ffmpeg-free` を使い続けるときに足すもの。RPM Fusion の Howto/Multimedia の案内による） |

- RPM Fusion の EL 10 向けには、`ffmpeg-libs` 7.1.5 が aarch64 と x86_64 の両方にある
- RPM Fusion は EPEL を前提にしている（`rpmfusion-free-release` が `epel-release` を要求する）

| 経路 | 状況 | 採否 |
|---|---|---|
| **winget の `Mozilla.Firefox.ja` を PC 全体に** | 157.0。Mozilla の CDN の日本語版の NSIS インストーラ（x64・x86・arm64）を、winget が sha256 を確かめて画面を出さずに入れる。`Scope` は `machine` だけ。Maintenance Service が入り、以後は Firefox が自分で更新する | **採用** |
| winget の `Mozilla.Firefox` に `--locale ja` | 137.0.1 までは言語ごとのインストーラ（`InstallerLocale`）が 51 あったが、137.0.2 から英語（en-US）だけになり、言語ごとに `Mozilla.Firefox.<言語>` に分かれた。言語の無いインストーラは、`--locale` を付けると候補から外れるので、入らないはず | 不採用 |
| `Mozilla.Firefox`（英語版）に日本語の言語パック | 言語パックがあると、閉じている間の更新（Background Update）が動かない（Mozilla の文書）。本体と版を揃える必要もある（AlmaLinux 10 の[注意点](../extra/almalinux-setup.md#注意点)と同じ） | 不採用 |
| winget の `Mozilla.Firefox.MSIX`・Microsoft Store 版 | MSIX（言語は multi）で、パッケージのアプリ（`Mozilla.MozillaFirefox`）として入る | 不採用（Mozilla の通常のインストーラと、Firefox 自身の更新にそろえた） |
| scoop の `extras/firefox` | 157.0。英語版のインストーラを 7z で展開するだけのポータブル版で、プロファイルは scoop の `persist` に作る | 不採用（日本語版でなく、PC 全体にも入らない） |
| Mozilla のサイトからインストーラを落として実行 | 同じものが入るが、ダウンロードと実行が画面の操作になる | 不採用（winget で同じインストーラが入る） |

- **PC 全体（`machine`）に入れた**: winget の定義が `machine` しか持たない。AlmaLinux 10 の dnf と同じく、PC の全ユーザーで 1 つの Firefox を使い、更新は Maintenance Service で管理者の確認なしに行える
  - Mozilla のインストーラは、管理者の権限が無いまま入れると `%LOCALAPPDATA%\Mozilla Firefox` に入れ、Maintenance Service は入れない（Firefox のソースの `installer.nsi`・`postupdate_helper.nsh`）。winget の定義では、この形は選べない
- **日本語版（`.ja`）にした**: 言語パックが要らないので、AlmaLinux 10 の「言語パックは本体と同時に上げる」（[注意点](../extra/almalinux-setup.md#注意点)）に当たる注意が無く、閉じている間の更新も動く
- **既定のブラウザーは、Windows の設定の画面で変える**: 今の Windows 11 では、`http`・`https` の既定をコマンドで書き換えられない（[Windows 11 で使う](../windows-setup.md#firefox)の手順 5 の補足）
- **Windows 11 の手順もこの文書に置いた**: 同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、OS ごとにファイルを分けない。手順が OS で違うので、[syncthing.md](../syncthing.md) と同じく後ろの節に分けた

#### Firefox: 参照

---

## 統合前の参考資料: HackGen Console NF（もとは hackgen.md）

もとの `hackgen.md` の参考資料を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の参考資料](windows-setup.md#統合前の参考資料-hackgen-console-nf-の-windows-11もとは-hackgenmd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜5 | 「HackGen Console NF」の手順 1〜5 |
| WezTerm で使う（任意）の 1・2 | （外した。自分用の WezTerm の設定がこのフォントを使う） |
| 更新 1 | 更新の手順 2・3 |
| ロールバック 1 | ロールバックの「端末とエディタを消す」の手順 10 |
| ロールバック 2 | （外した。WezTerm で使う（任意）の戻し方） |

[検証記録](../verification/almalinux-setup.md#hackgen-console-nf-参考資料から分離した記録)

### HackGen Console NF: 補足

#### HackGen Console NF: 実施手順 / 手順 1: 補足: HackGen35 Console NF

- 文字幅が半角 3:全角 5 の版 `HackGen35 Console NF` も、同じ手順で一緒に入る（[検証記録](../verification/almalinux-setup.md#統合前の記録-hackgen-console-nfもとは-hackgenmd)）

#### HackGen Console NF: 実施手順 / 手順 2: 補足: unzip が要る理由

- Homebrew は cask の zip を展開するのに `unzip` を使う

#### HackGen Console NF: 実施手順 / 手順 5: 補足: fc-match と文字の確かめ方

- `fc-match` は、名前が合わないときに別のフォントを黙って返すので、ファイル名が HackGen であることを確かめる
- 最後の `for` で、かな・漢字・Powerline 記号・Nerd Fonts のアイコンが、このフォントに入っていることを確かめる

#### HackGen Console NF: WezTerm で使う（任意） / 手順 2: 補足: 反映

- 起動中の WezTerm には、保存した時点で反映される（[wezterm-nightly.md の設定ファイル](../almalinux-setup.md#wezterm-の設定ファイル)の節）

#### HackGen Console NF: 選択した方針

| 経路 | 状況 | 採否 |
|---|---|---|
| **Homebrew の cask `font-hackgen-nerd`** | `brew upgrade` で上がり、`brew uninstall` で消せる。自分のユーザーにだけ入る | **採用**（Homebrew 系の手順書と揃える） |
| GitHub のリリースの zip を手で展開 | `~/.local/share/fonts` に置く。Homebrew が要らないが、**更新は手作業** | 不採用（Homebrew がある環境では cask で足りる） |
| 全ユーザー向け（`/usr/local/share/fonts` に置く） | root で置けば全ユーザーから見えるが、cask は自分のホームに置く。複数ユーザーで使う機会が無いので要らない | 不採用 |

- upstream の README は、Linux 向けの導入手順を書いていない（GitHub のリリースの ttf と、Mac の Homebrew、Windows の Chocolatey を案内している）
- Homebrew の cask は upstream の README では Mac 向けとして紹介されている

| 経路 | 状況 | 採否 |
|---|---|---|
| **上流の zip を版と sha256 を固定して、自分のユーザーに入れる** | 管理者の権限も scoop も要らず、Windows PowerShell 5.1 で動く。更新は手作業 | **採用** |
| scoop の個人のバケット mo-san の `font-hackgen-console-nf` | リリースの zip を使い、scoop と UniGet UI で上げられる。ただし、インストールのスクリプトが `Join-Path` に 3 つ以上の引数を渡していて、Windows PowerShell 5.1 の `Join-Path`（`-Path` と `-ChildPath` だけ）では失敗するはず。scoop はそのスクリプトを、`scoop` を打った PowerShell の中で動かす | 不採用（PowerShell 7 が要り、個人の保守） |
| scoop の nerd-fonts のバケット | HackGen は無い | — |
| winget | 既定のソース（winget-pkgs）に HackGen は無い。winget の一覧のサイトには `yuru7.HackGen`（第三者の `dfirr/winget-hackgen` が作り直したインストーラで、PC 全体に入れる）が載っている | 不採用 |
| Chocolatey | 上流の README が Windows 向けに案内している | 不採用（別のパッケージ マネージャーを足し、管理者が要る） |
| PC 全体（`C:\Windows\Fonts`）に入れる | 管理者が要る | 不採用（AlmaLinux 10 と同じく自分のユーザーだけ） |

- **Windows 11 の手順もこの文書に置いた**: 同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、OS ごとにファイルを分けない。手順が OS で違うので、[syncthing.md](../syncthing.md) と同じく後ろの節に分けた

#### HackGen Console NF: 参照

- [yuru7/HackGen](https://github.com/yuru7/HackGen) — フォントの特徴、ファミリーの種類、ライセンス、リリース
- [Homebrew Formulae — font-hackgen-nerd](https://formulae.brew.sh/cask/font-hackgen-nerd) — cask の版と中身
- [Nerd Fonts](https://www.nerdfonts.com/) — 追加されているアイコンの一覧（コードポイントの確認に使える）
- `man fc-list` / `man fc-match` / `man fc-cache` — fontconfig の照会と、キャッシュの作り直し
- [wezterm-nightly.md](../almalinux-setup.md#wezterm) — WezTerm の導入と設定ファイルの置き場所
- [AlmaLinux 10 の初期設定](../almalinux-setup.md) — 「Homebrew」の手順 1〜3 が Homebrew 本体の導入手順。`brew` の基本操作は同書の「Homebrew の使い方の基本」
- [HackGen v2.10.0](https://github.com/yuru7/HackGen/releases/tag/v2.10.0) — Windows 11 の節で取る `HackGen_NF_v2.10.0.zip`
- [Join-Path（5.1）— Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/join-path?view=powershell-5.1) — `-Path` と `-ChildPath` だけ（scoop の個人のバケットを採らなかった理由）
- [matthewjberger/scoop-nerd-fonts](https://github.com/matthewjberger/scoop-nerd-fonts) — Windows で自分のユーザーにフォントを入れる定義（issue #198 のアクセス権）
- [mo-san/scoop-bucket](https://github.com/mo-san/scoop-bucket) — 採らなかった scoop の個人のバケット
- [Windows 11 の初期設定](../windows-setup.md) — Windows のインストール直後にまとめて行う設定（scoop・UniGet UI・Caps Lock・表示・電源・リモート デスクトップなど）。この節は、そのリードから案内される

---

## 統合前の参考資料: WezTerm（もとは wezterm-nightly.md）

もとの `wezterm-nightly.md` の参考資料を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の参考資料](windows-setup.md#統合前の参考資料-wezterm-の-windows-11もとは-wezterm-nightlymd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜4 | 「WezTerm」の手順 1〜4 |
| 実施手順 5（SSH のセッションから確かめる） | （外した。この文書はデスクトップで行う） |
| 設定ファイルの 1（最小の例） | （外した。「WezTerm」の手順 5 で自分用の設定を入れる。箇条書きは「WezTerm の設定ファイル」） |
| 更新 1 | 更新のリード（OS の更新で上がる） |
| ロールバック 1・2 | ロールバックの「端末とエディタを消す」の手順 8・9 |

### WezTerm: 補足

#### WezTerm: 実施手順 / 手順 1: 補足: chroot を明示する理由

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

#### WezTerm: 実施手順 / 手順 3: 補足: wezterm はメタパッケージ / 取り込まれる鍵

[この節の検証記録](../verification/almalinux-setup.md#wezterm-実施手順--手順-3-補足-wezterm-はメタパッケージ--取り込まれる鍵)

- `wezterm` 本体（6.4 KB、`rpm -ql wezterm` は空）は、`wezterm-common`（CLI の `wezterm`、シェル統合、補完）/ `wezterm-gui`（`wezterm-gui`、desktop ファイル、アイコン）/ `wezterm-mux-server` を Requires で束ねているだけ
- `dnf repoquery --requires wezterm` に `gcc` / `*-devel` / `make` が並んで見えるのは、同名の **SRPM の BuildRequires** が一緒に表示されているため。x86_64 パッケージには入っていない

GPG 鍵はインストール時に COPR の `pubkey.gpg` から取り込まれる:

```
Importing GPG key 0xCEA2757D:
 Userid     : "wezfurlong_wezterm-nightly (None) <wezfurlong#wezterm-nightly@copr.fedorahosted.org>"
 Fingerprint: FD90 9B62 88A8 4250 AD58 020F A698 91C5 CEA2 757D
 From       : https://download.copr.fedorainfracloud.org/results/wezfurlong/wezterm-nightly/pubkey.gpg
```

#### WezTerm: 実施手順 / 手順 4: 補足: wezterm ls-fonts と wezterm-gui --version

- **`wezterm ls-fonts`** は GUI 無しでフォント解決を確認できる
  - 既定のフォントは組み込みの `JetBrains Mono` で、フォールバックに `Noto Color Emoji`（fontconfig 経由）と組み込みの `Symbols Nerd Font Mono` が並ぶ
  - `| head` で切ると `rc=101`（Rust の panic 終了コード）になるが、パイプが閉じたためで異常ではない。単体で実行すると `rc=0`
- **`wezterm-gui --version` は `wezterm-gui someone forgot to call assign_version_info` と出る**（rc=0）
  - COPR ビルドでは GUI バイナリにバージョン情報が埋め込まれていない。バージョンは `wezterm --version` で見る

#### WezTerm: 実施手順 / 手順 4: 補足: アプリ一覧の項目

- アプリ一覧の「WezTerm」は、`/usr/share/applications/org.wezfurlong.wezterm.desktop` から出る

#### WezTerm: 実施手順 / 手順 5: 補足: Wayland セッションでの起動試験

- **Wayland セッションでの起動試験**: この検証は Claude Code のシェル（TTY もディスプレイも無い）から行ったので、`env -i` で環境を空にしてから、ログイン中の GNOME セッションの `WAYLAND_DISPLAY=wayland-0` と `XDG_RUNTIME_DIR` を渡した
  - 値は `/proc/$(pgrep -u "$USER" -x gnome-shell)/environ` から取れる
  - `wezterm start -- sh -c 'exit 0'` はウィンドウを開いて `sh` を走らせ、終了と同時にウィンドウを閉じる。結果 `rc=0`
  - `timeout 30` は、描画に失敗してウィンドウが残った場合の保険
- 手順 5 のブロックは、ログイン中の Wayland セッションを指定して、ウィンドウを開く
- `rc=0` でウィンドウが閉じているのは、`exit_behavior` の既定が `Close` なので、子プロセスが終わるとウィンドウも閉じるため

#### WezTerm: 設定ファイル / 手順 1: 補足: 再読み込みと起動のオプション

- 保存すると起動中の WezTerm に自動で反映されるのは、`automatically_reload_config` の既定が true のため
- Lua の文法エラーで組み込みの既定値で起動するとき、別の候補ファイルには進まない
- `wezterm -n`（`--skip-config`）で、設定を読まずに起動できる
- `wezterm --config 'font_size=14'` のように、1 項目だけ上書きもできる

#### WezTerm: 選択した方針

`wezterm-gui` が要求するのは次のもの（`dnf repoquery --requires wezterm-gui`）:

- `libc.so.6(GLIBC_2.34)`
- `libssl.so.3(OPENSSL_3.0.0)` / `libcrypto.so.3`
- `libwayland-client.so.0` / `libwayland-egl.so.1`
- `libxkbcommon.so.0(V_0.6.0)` / `libxkbcommon-x11.so.0`
- `libxcb.so.1` / `libxcb-image.so.0` / `libxcb-util.so.1`
- `libX11.so.6` / `libX11-xcb.so.1`
- `libfontconfig.so.1`、`mesa-libEGL`、`dbus`

EL10 は glibc 2.39 / OpenSSL 3.5（`libssl.so.3` の soname と `OPENSSL_3.0.0` シンボルバージョンを両方提供）なので、EL9 向けバイナリがそのまま動く。

##### WezTerm: Homebrew の tap を採らない理由

##### WezTerm: Windows 11 で入れる経路

- **Windows 11 では、インストーラを直接取って、`.sha256` と比べてから黙って動かす方式を採用した**
  - [Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md)が前提にしている `C:\Program Files\WezTerm` に、公式の形のまま入る
  - `.sha256` は同じリリースに置かれたものなので、分かるのは壊れていないことまで。署名が無いので、ほかに本物かを確かめる手立ては無い（winget の定義の sha256 も、同じファイルから bot が取ったもの）
  - winget の `wez.wezterm.nightly` は、入れられる日なら 1 行で済み `VCRUNTIME140.dll` の依存も入るが、入るかどうかが日によるので採らなかった。依存の再頒布可能パッケージだけは winget で入れる（[Windows 11 で使う](../windows-setup.md#wezterm)の手順 3）
- **Windows 11 の手順もこの文書に置いた**: 同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、OS ごとにファイルを分けない。手順が OS で違うので、[syncthing.md](../syncthing.md) と同じく後ろの節に分けた

#### WezTerm: 参照

---

## 統合前の参考資料: git-delta（もとは git-delta.md）

もとの `git-delta.md` の参考資料を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の参考資料](windows-setup.md#統合前の参考資料-git-delta-の-windows-11もとは-git-deltamd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜4 | 「git-delta」の手順 1〜4 |
| lazygit と組み合わせる（任意）の 1 | （外した。自分用の lazygit の設定が delta を使う） |
| 設定ファイル | git-delta の設定ファイル |
| 更新 1 | 更新の手順 2・3 |
| ロールバック 1・3 | ロールバックの「Git の道具を消す」の手順 2・3 |
| ロールバック 2 | ロールバックの「Git の道具を消す」の手順 10 |

### git-delta: 補足

#### git-delta: 実施手順 / 手順 1: 補足: 変数について

- 3 つとも表示の好みなので、既定のままで進められる
- 3 つとも `~/.gitconfig` の `[delta]` に書かれる値で、後から `git config --global delta.side-by-side true` で変えられる
- `navigate` を `true` にすると、ページャ（`less`）の中で `n` が「次の変更へ」になる。delta が `less` に渡すオプションで実現しているので、`core.pager` 経由で起動したときだけ効く

#### git-delta: 実施手順 / 手順 2: 補足: 降ってくるボトル

aarch64 で降ってくるボトルは `git-delta--0.19.2.arm64_linux.bottle.tar.gz`。

- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない

#### git-delta: 実施手順 / 手順 2: 補足: formula 名とコマンド名

- formula 名は `git-delta` だが、入るコマンドは `delta`（`brew install delta` でも同じ formula に解決される）

#### git-delta: 実施手順 / 手順 3: 補足: git の設定の書き方

- `~/.gitconfig` を直接編集せず、`git config --global` で書く（既にある `[user]` や `[core]` を壊さない）
- ブロックの最後の行で、書けたか読み戻す
- `interactive.difffilter` と小文字で表示されるのは、git がキー名を正規化するため。`~/.gitconfig` の中では `diffFilter` のまま
- `merge.conflictstyle zdiff3` は delta とは独立した設定だが、コンフリクト表示が読みやすくなるので一緒に入れている
- `zdiff3` は git 2.35 以降で使える（AlmaLinux 10 の RPM は 2.52.0）
- [git.md 手順 6](../almalinux-setup.md#git) でも同じ値を入れる。先に通していても、同じキーが書き直されるだけ

#### git-delta: 実施手順 / 手順 4: 補足: 差分の出し方

- ブロックの最後の行で、変更のあるリポジトリの差分を出す

#### git-delta: 選択した方針

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `git-delta 0.19.2` の `arm64_linux` ボトルがある。upstream の最新と一致。formula に `delta` という別名が付いているので `brew install delta` でも入る | **採用** |
| EPEL / AppStream / CRB | **`delta` も `git-delta` も無い**（`dnf list --available delta git-delta` → `Error: No matching Packages to list`）。※ `delta` という名前の無関係なパッケージも無い | 使えない |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-gnu` の tar と `.rpm` が置いてある。rpm を直接入れると dnf のリポジトリ管理外になり更新が手作業になる | 不採用（Homebrew に揃える） |
| `cargo install git-delta` | Rust toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |
| diff-so-fancy / difftastic | 別物（difftastic は EPEL に `0.67.0` がある）。構文木で比較する difftastic とは用途が違うので、置き換えではなく併用できる | 対象外 |

#### git-delta: 参照

- [dandavison/delta — README](https://github.com/dandavison/delta) — 使い方、`~/.gitconfig` の書き方、side-by-side と navigate の説明
- [delta manual](https://dandavison.github.io/delta/) — 全設定項目、`features` による設定のまとめ方、他ツールとの連携
- [lazygit 0.65.1 の差分表示設定](https://github.com/jesseduffield/lazygit/blob/v0.65.1/docs/Custom_DiffRenderers.md) — `git.diffRenderers` の `stdinFilter` と delta の指定
- `delta --help` / `delta --show-config` / `delta --list-syntax-themes` — オプションと実効値、配色の一覧
- `git help config` の `core.pager` / `interactive.diffFilter` — git 側の仕様
- [AlmaLinux 10 の初期設定](../almalinux-setup.md) — 「Homebrew」の手順 1〜3 が Homebrew 本体の導入手順。`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件は参考資料、`brew` の基本操作は同書の「Homebrew の使い方の基本」
- [ScoopInstaller/Main — delta.json](https://github.com/ScoopInstaller/Main/blob/master/bucket/delta.json) — scoop の版、x64 の zip と hash、`delta.exe` の shim
- [winget-pkgs — dandavison.delta 0.20.1](https://github.com/microsoft/winget-pkgs/blob/master/manifests/d/dandavison/delta/0.20.1/dandavison.delta.installer.yaml) — 同じ zip の sha256 と、VC++ ランタイムの依存（採らなかった経路）
- [delta manual — Using Delta on Windows](https://dandavison.github.io/delta/tips-and-tricks/using-delta-on-windows.html) — Windows では新しい less が要るという案内
- [src/utils/bat/output.rs（0.20.1）](https://github.com/dandavison/delta/blob/0.20.1/src/utils/bat/output.rs)・[src/features/navigate.rs](https://github.com/dandavison/delta/blob/0.20.1/src/features/navigate.rs) — ページャの探し方と、Windows の less の検索履歴の写しの場所
- [git-for-windows/MINGW-packages — git-wrapper.c](https://github.com/git-for-windows/MINGW-packages/blob/main/mingw-w64-git/git-wrapper.c)・[mingw-w64-git.mak](https://github.com/git-for-windows/MINGW-packages/blob/main/mingw-w64-git/mingw-w64-git.mak) — `cmd\git.exe` が PATH の先頭に `usr\bin` を足すこと
- [ScoopInstaller/Scoop](https://github.com/ScoopInstaller/Scoop) — `install`・`update`・`uninstall` の表示と、arm64 の Windows 11 で x64 の定義を使うこと（`lib/manifest.ps1` の `Get-SupportedArchitecture`）
- [ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit) — 自分用の lazygit の設定。README の「前提ツール」と「Windows で使う場合」
- [Windows 11 の初期設定](../windows-setup.md) — 貼り付けの設定（「貼り付けの設定」の手順 1〜4）、scoop（「アプリを入れる」の手順 1・2）、PowerShell 7 のプロファイルの任意節
- [WezTerm の Windows 11 で使う](../windows-setup.md#wezterm) — VC++ ランタイム（手順 3）と、Git Bash で開く自分用の設定

---

## 統合前の参考資料: Neovim（もとは neovim.md）

もとの `neovim.md` の参考資料を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の参考資料](windows-setup.md#統合前の参考資料-neovim-の-windows-11もとは-neovimmd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 「Neovim」の手順 1 |
| 実施手順 2 | 「Neovim」の手順 2（`checkhealth` の起動は外した） |
| 既定のエディタにする（任意）の 1 | 「Neovim」の手順 4 |
| 設定ファイルの 1（最小の例） | （外した。「Neovim」の手順 3 で自分用の設定を入れる。箇条書きは「Neovim の設定ファイル」） |
| 更新 1 | 更新の手順 2・3 |
| ロールバック 1・2 | ロールバックの「端末とエディタを消す」の手順 3・4 |

### Neovim: 補足

#### Neovim: 実施手順 / 手順 1: 補足: ボトルと依存

- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
- 依存（`libuv` / `lpeg` / `luajit` / `luv` / `tree-sitter` / `unibilium` / `utf8proc`）も一緒に入る

#### Neovim: 実施手順 / 手順 2: 補足: :checkhealth の読み方

[この節の検証記録](../verification/almalinux-setup.md#neovim-実施手順--手順-2-補足-checkhealth-の読み方)

`:checkhealth` は「使っていない機能の WARNING」を大量に出す。素の状態で出るのは主に次の 3 種類:

- `vim.provider`: node / perl / python3 / ruby のプロバイダが無い。それぞれの言語で書かれたプラグインを使わないなら無視してよい（`vim.g.loaded_node_provider = 0` などで黙らせられる）
- `vim.deprecated`: プラグインが古い API を使っている
- ツールの不足: `rg`（ripgrep）、`fd`、`git`、`tree-sitter` など。必要なものを各手順書で導入する（[yazi.md](../almalinux-setup.md#yazi) の依存ツール、および RPM の git）

`ERROR` が出ていなければ、日常の編集には支障がない。

- 手順 2 のブロックは、最後の行で起動して、`:checkhealth` で健全性を確認する

#### Neovim: 既定のエディタにする（任意） / 手順 2: 補足: git commit のエディタ

- git の `core.editor` が無ければ、PowerShell から動かす `git commit` も Neovim で開く（Git for Windows の既定の Vim から変わる。`git config --get core.editor` で確かめられる）

#### Neovim: 既定のエディタにする（任意） / 手順 3: 補足: Git Bash の共通設定

- Git Bash の共通設定の `EDITOR`・`VISUAL` は、この手順では変わらない

#### Neovim: 設定ファイル / 手順 1: 補足: 探索先とディストリビューション

- 設定の探索先は `nvim -c ':echo stdpath("config")' -c 'q'` で確認できる
- LazyVim / NvChad などのディストリビューションを入れる場合も、同じ場所に置く

#### Neovim: 参照

- [Install Neovim](https://neovim.io/doc/install/) — 公式が案内する各経路（tarball / AppImage / パッケージマネージャ）
- [neovim/neovim — INSTALL.md](https://github.com/neovim/neovim/blob/master/INSTALL.md) — tarball の展開先と PATH の通し方、glibc の要件
- `:help nvim-defaults` / `:help checkhealth` — 既定値と健全性チェックの読み方
- [AlmaLinux 10 の初期設定](../almalinux-setup.md) — 「Homebrew」の手順 1〜3 が Homebrew 本体の導入手順。`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件は参考資料、`brew` の基本操作は同書の「Homebrew の使い方の基本」
- [ryo-aoki-pc/LazyVimStarter](https://github.com/ryo-aoki-pc/LazyVimStarter) — 自分用の設定（LazyVim ベース）。導入の手順は [docs/setup.md](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md)
- [ScoopInstaller/Main — neovim.json](https://github.com/ScoopInstaller/Main/blob/master/bucket/neovim.json) — Windows 11 の scoop の定義（版・`bin`・`suggest`）
- [neovim/neovim — runtime/doc/starting.txt（v0.12.5）](https://github.com/neovim/neovim/blob/v0.12.5/runtime/doc/starting.txt) — `base-directories`（Windows の設定・データ・キャッシュの場所）
- [lazygit — Config.md の Configuring File Editing](https://github.com/jesseduffield/lazygit/blob/v0.66.0/docs/Config.md#configuring-file-editing) — `e` キーのエディタの決まり方（`EDITOR` とプリセット）
- [ryo-aoki-pc/LazyVimStarter — docs/setup.md の Windows 11 に導入する](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#windows-11-に導入する-1-度だけ) — 自分用の設定の Windows の導入（scoop の Neovim と外部コマンドも入れる）

---

## 統合前の参考資料: lazygit（もとは lazygit.md）

もとの `lazygit.md` の参考資料を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の参考資料](windows-setup.md#統合前の参考資料-lazygit-の-windows-11もとは-lazygitmd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1（`LG_EDITOR`） | （外した。`e` キーのエディタは `EDITOR` で決まる） |
| 実施手順 2 | 「lazygit」の手順 1 |
| 実施手順 3 | 「lazygit」の手順 3・4 |
| 設定ファイルの 1（最小の例） | （外した。「lazygit」の手順 2 で自分用の設定を入れる。箇条書きは「lazygit の設定ファイル」） |
| 更新 1 | 更新の手順 2・3 |
| ロールバック 1 | ロールバックの「Git の道具を消す」の手順 1 |

### lazygit: 補足

#### lazygit: 実施手順 / 手順 1: 補足: 変数について

- `LG_EDITOR` を使うのは[設定ファイル](../almalinux-setup.md#lazygit-の設定ファイル)の節だけ
- lazygit は設定が無ければ `EDITOR` 環境変数を見るので、`~/.bashrc` に `export EDITOR=nvim` があれば設定ファイルは要らない

#### lazygit: 実施手順 / 手順 2: 補足: ボトル

- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない

#### lazygit: 実施手順 / 手順 3: 補足: 起動時の注意

[この節の検証記録](../verification/almalinux-setup.md#lazygit-実施手順--手順-3-補足-起動時の注意)

`lazygit --version` の `git version` 欄には、lazygit が呼ぶ git のバージョンが出る。

**git が入っていないと lazygit は起動しない。**

- Homebrew 版は git を依存に持たないので、RPM の git か `brew install git` のどちらかが要る

git 管理下でないディレクトリで起動すると `Would you like to create a new repository?` と聞かれる。意図せず `.git` を作らないよう、リポジトリのルートで起動する。

#### lazygit: 設定ファイル / 手順 1: 補足: 既定値とキーバインド

- 既定値の全体は `lazygit --config` で表示できる
- アプリ内では `x` でキーバインド一覧が出る

#### lazygit: 選択した方針

- `atim/lazygit` でも同じ 403
- dnf を介さず `curl -L` で `repomd.xml` を取っても同じ。COPR の配信元（`download.copr.fedorainfracloud.org`）が S3 の署名付き URL にリダイレクトし、その署名が期限切れになっている
- 一方で COPR 全体が落ちているわけではない。同じ日に `lihaohong/yazi` の `epel-10-aarch64` はメタデータを取得できている（[yazi.md](../almalinux-setup.md#yazi)）
- **プロジェクトごとの問題で、いずれ直る可能性がある**

#### lazygit: 参照

- [jesseduffield/lazygit — README](https://github.com/jesseduffield/lazygit) — 各 OS のインストール方法と機能一覧
- [lazygit Config Docs](https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md) — `config.yml` の項目（`os.edit` など）
- [AlmaLinux 10 の初期設定](../almalinux-setup.md) — 「Homebrew」の手順 1〜3 が Homebrew 本体の導入手順。`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件は参考資料、`brew` の基本操作は同書の「Homebrew の使い方の基本」
- [atim/lazygit — Copr](https://copr.fedorainfracloud.org/coprs/atim/lazygit/) / [dejan/lazygit — Copr](https://copr.fedorainfracloud.org/coprs/dejan/lazygit/) — chroot の一覧（`epel-10-aarch64` はある）
- [ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit) — 自分用の設定（`config.yml`）。導入方法と変えた項目は README にある
- [ScoopInstaller/Extras — lazygit.json](https://github.com/ScoopInstaller/Extras/blob/master/bucket/lazygit.json) — Windows 11 の scoop の定義
- [lazygit Config Docs（v0.66.0）](https://github.com/jesseduffield/lazygit/blob/v0.66.0/docs/Config.md) — Windows の設定の場所（`%LOCALAPPDATA%\lazygit\config.yml`）と `LG_CONFIG_FILE`
- [ryo-aoki-pc/lazygit — README の導入方法](https://github.com/ryo-aoki-pc/lazygit#導入方法) — 自分用の設定の Windows の clone の例と元に戻し方

---

## 統合前の参考資料: GitHub CLI（もとは gh.md）

もとの `gh.md` の参考資料を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の参考資料](windows-setup.md#統合前の参考資料-github-cli-の-windows-11もとは-ghmd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜5 | 「GitHub CLI」の手順 1〜5 |
| 更新 1 | 更新のリード（OS の更新で上がる） |
| ロールバック 1〜5 | ロールバックの「Git の道具を消す」の手順 4〜8 |

### GitHub CLI: 補足

#### GitHub CLI: 実施手順 / 手順 1: 補足: 生成される repo ファイルと、dnf4 と dnf5 の構文の違い

追加するのは公式が配っている repo ファイルで、生成される `/etc/yum.repos.d/gh-cli.repo` は次のとおり:

```
[gh-cli]
name=packages for the GitHub CLI
baseurl=https://cli.github.com/packages/rpm
enabled=1
gpgcheck=1
gpgkey=https://cli.github.com/packages/githubcli-archive-keyring.asc
```

AlmaLinux 10.2 の dnf は **4.20.0**（`dnf5` パッケージは未導入）なので `--add-repo` を使う。Fedora 41 以降の dnf5 では構文が変わり、`sudo dnf install dnf5-plugins` のうえで:

```
sudo dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo
```

になる。公式ドキュメントは両方を併記している。EL10 でも将来 dnf5 に移れば後者になる。

#### GitHub CLI: 実施手順 / 手順 2: 補足: 署名鍵

- 鍵が 2 本あるので、初回は取り込みを 2 回聞かれる

#### GitHub CLI: 実施手順 / 手順 4: 補足: 認証

トークンは OS の資格情報ストアに保存される。ストアを使えない場合は `~/.config/gh/hosts.yml` の平文保存に切り替わる。保存先は `gh auth status` で確認する。`gh auth token` の出力は**記録しない**。

#### GitHub CLI: 選択した方針

- 両方が有効なら、dnf はバージョンの高い `gh-cli` 側を選ぶ
- `armv6hl` や `i386` の行が見えるのは、このリポジトリが `baseurl` にアーキテクチャを含まない**全アーキテクチャ共通**の作りだから（Mozilla のリポジトリと同じ）

#### GitHub CLI: 参照

- [ScoopInstaller/Main — gh.json](https://github.com/ScoopInstaller/Main/blob/master/bucket/gh.json) — Windows 11 の scoop の定義（版・zip と sha256・`bin\gh.exe`）
- [winget-pkgs — GitHub.cli 2.102.0](https://github.com/microsoft/winget-pkgs/blob/master/manifests/g/GitHub/cli/2.102.0/GitHub.cli.installer.yaml) — MSI（machine）と portable（採らなかった経路）
- [gh 2.102.0 の login_flow.go](https://github.com/cli/cli/blob/v2.102.0/pkg/cmd/auth/shared/login_flow.go)・[git_credential.go](https://github.com/cli/cli/blob/v2.102.0/pkg/cmd/auth/shared/git_credential.go)・[gitcredentials](https://github.com/cli/cli/tree/v2.102.0/pkg/cmd/auth/shared/gitcredentials) — ログインの問いと、Git の認証に Yes と答えたときの動き
- [gh 2.102.0 の internal/config/config.go](https://github.com/cli/cli/blob/v2.102.0/internal/config/config.go)・[status.go](https://github.com/cli/cli/blob/v2.102.0/pkg/cmd/auth/status/status.go)・[logout.go（v2.102.0）](https://github.com/cli/cli/blob/v2.102.0/pkg/cmd/auth/logout/logout.go) — トークンの置き場所、状態の表示、ログアウト
- [gh 2.102.0 の internal/ghcmd/cmd.go](https://github.com/cli/cli/blob/v2.102.0/internal/ghcmd/cmd.go) — `GH_PATH` と自分の場所、新しい版の知らせ
- [cli/go-gh v2.16.1 — pkg/config/config.go](https://github.com/cli/go-gh/blob/v2.16.1/pkg/config/config.go) — 設定・状態・データ・キャッシュの場所
- [zalando/go-keyring v0.2.8 — keyring_windows.go](https://github.com/zalando/go-keyring/blob/v0.2.8/keyring_windows.go) — 資格情報マネージャーの項目の名前
- [GitHub CLI manual — gh help environment](https://cli.github.com/manual/gh_help_environment) — `GH_CONFIG_DIR`・`GH_PATH` など
- [Windows 11 の初期設定](../windows-setup.md) — 貼り付けの設定（「貼り付けの設定」の手順 1〜4）、scoop（「アプリを入れる」の手順 1・2）、PowerShell 7 のプロファイルの任意節。[Git](../almalinux-setup.md#git) — Git for Windows と、その Git Credential Manager

---

## 統合前の参考資料: yazi（もとは yazi.md）

もとの `yazi.md` の参考資料を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の参考資料](windows-setup.md#統合前の参考資料-yazi-の-windows-11もとは-yazimd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1・2 | 「yazi」の手順 1・2 |
| 実施手順 3 | 「yazi」の手順 4（`. ~/.bashrc` で読み直さず、新しいタブで確かめる） |
| 実施手順 4 | 「yazi」の手順 5 |
| 設定ファイルの 1（`mkdir`） | （外した。「yazi」の手順 3 で自分用の設定を入れる。箇条書きは「yazi の設定ファイル」） |
| 更新 1 | 更新の手順 2・3 |
| ロールバック 1 | ロールバックの「端末とエディタを消す」の手順 1 |

### yazi: 補足

#### yazi: 実施手順 / 手順 1: 補足: 変数について

- `YAZI_EXTRAS` に並べているのは、yazi が外部コマンドとして呼ぶツール。役割は手順 2 の補足にまとめた
- `ffmpeg-full` と `imagemagick-full` は、Homebrew の `ffmpeg` / `imagemagick` に対してコーデック・フォーマットを広く有効にしたビルド（どちらも `homebrew/core` の formula）
- 既定は、プレビュー・検索用のツールを一緒に入れる想定になっている

#### yazi: 実施手順 / 手順 2: 補足: ボトルと、依存ツールの役割

[この節の検証記録](../verification/almalinux-setup.md#yazi-実施手順--手順-2-補足-ボトルと依存ツールの役割)

- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない

#### yazi: 実施手順 / 手順 3: 補足: y 関数

- `y` は yazi を閉じたディレクトリへ移る。空白や日本語を含むパスも扱い、同じ場所なら移動し直さない

#### yazi: 実施手順 / 手順 4: 補足: ya と y

- `ya` は付属のプラグイン管理コマンド
- ブロックの最後の `y` で起動して確認する
- `y` で起動したときは、終了時にそのディレクトリへ移動する

#### yazi: 設定ファイル / 手順 1: 補足: プラグインとテーマ

- プラグインとテーマは `ya pkg add`（引数はリポジトリ名）で入れる。`~/.config/yazi/package.toml` に記録される
- 本書ではプラグインは扱っていない

#### yazi: 更新 / 手順 1: 補足: 先に確認する

- `brew outdated` で先に確認できる

#### yazi: 参照

- [Installation — Yazi](https://yazi-rs.github.io/docs/installation/) — 経路一覧と依存ツール（ffmpeg / 7-Zip / jq / poppler / fd / ripgrep / fzf / zoxide / ImageMagick）
- [Quick Start — Yazi](https://yazi-rs.github.io/docs/quick-start/) — `y` シェル関数（`--cwd-file`）の原典
- [Configuration — Yazi](https://yazi-rs.github.io/docs/configuration/overview/) — `yazi.toml` / `keymap.toml` / `theme.toml`
- [ryo-aoki-pc/yazi](https://github.com/ryo-aoki-pc/yazi) — 自分用の設定。入れ方・独自のキー・上流との差分の管理は README にある
- [AlmaLinux 10 の初期設定](../almalinux-setup.md) — 「Homebrew」の手順 1〜3 が Homebrew 本体の導入手順。`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件は参考資料、`brew` の基本操作は同書の「Homebrew の使い方の基本」
- [Installation — Yazi の Windows](https://yazi-rs.github.io/docs/installation/#windows) — scoop の経路と依存、`YAZI_FILE_ONE`（Git for Windows の `file.exe`）
- [Image Preview — Yazi](https://yazi-rs.github.io/docs/image-preview/) — Windows で画像を出せる端末（WezTerm の nightly、Windows Terminal 1.22.10352.0 以降）と ConPTY の制約
- [ScoopInstaller/Main — yazi.json](https://github.com/ScoopInstaller/Main/blob/master/bucket/yazi.json) — Windows 11 の scoop の定義
- [sxyazi/yazi — yazi-fs/src/xdg.rs（v26.9.1）](https://github.com/sxyazi/yazi/blob/v26.9.1/yazi-fs/src/xdg.rs) — Windows の設定・状態・キャッシュの場所
- [sxyazi/yazi — yazi-cli/src/env/env.rs（v26.9.1）](https://github.com/sxyazi/yazi/blob/v26.9.1/yazi-cli/src/env/env.rs) — `ya env` の出力
- [sxyazi/yazi — yazi-config/preset/yazi-default.toml（v26.9.1）](https://github.com/sxyazi/yazi/blob/v26.9.1/yazi-config/preset/yazi-default.toml) — 上流の既定の `[opener]`（Windows の `edit` は `code`）
- [sxyazi/yazi — yazi-plugin/preset/plugins/mime-local.lua（v26.9.1）](https://github.com/sxyazi/yazi/blob/v26.9.1/yazi-plugin/preset/plugins/mime-local.lua)・[yazi-binding/src/process/command.rs（v26.9.1）](https://github.com/sxyazi/yazi/blob/v26.9.1/yazi-binding/src/process/command.rs) — `YAZI_FILE_ONE` の起動（シェルを挟まない）

---

## 統合前の参考資料: Claude Code（もとは claude-code.md）

もとの `claude-code.md` の参考資料を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の参考資料](windows-setup.md#統合前の参考資料-claude-code-の-windows-11もとは-claude-codemd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜5 | 「Claude Code」の手順 1〜5 |
| 使い方の基本 | Claude Code の使い方の基本 |
| 更新 1 | 更新のリード（OS の更新で上がる） |
| stable チャンネルに切り替える（任意）の 1〜4 | Claude Code を stable チャンネルに切り替える（任意）の 1〜4 |
| ロールバック 1〜3 | ロールバックの「AI エージェントとプラグインを消す」の手順 2〜4 |

### Claude Code: 補足

#### Claude Code: 実施手順 / 手順 1: 補足: 変数について

- `CC_CHANNEL` は `baseurl` の末尾に埋まるだけ。入れた後でチャンネルを変えるときは、[stable チャンネルに切り替える（任意）](../almalinux-setup.md#claude-code-を-stable-チャンネルに切り替える任意)の手順で repo ファイルを書き換える（`stable` へ移るときは版が下がるので、`upgrade` ではなく `distro-sync` を使う）
- ネイティブインストーラ版にある `autoUpdatesChannel` / `minimumVersion` の設定は dnf 版では効かない（更新を行うのが dnf のため）

#### Claude Code: 更新 / 手順 1: 補足: dnf 版が自分で更新できない理由

- dnf 版の更新には root 権限が要るため、起動中の Claude Code は自分で更新できない

#### Claude Code: stable チャンネルに切り替える（任意） / 手順 3: 補足: 以後の更新

- 以後の `sudo dnf upgrade claude-code`（[更新](../almalinux-setup.md#更新)）は `stable` の版を追う

#### Claude Code: 選択した方針

[この節の検証記録](../verification/almalinux-setup.md#claude-code-選択した方針)

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **公式 dnf リポジトリ** | `downloads.claude.ai/claude-code/rpm/{stable,latest}`。aarch64 の RPM があり、署名鍵で検証される。更新は `dnf upgrade`（**自動更新はしない**） | **採用**（他のツールと同じ dnf 管理に揃う） |
| ネイティブインストーラ（`curl -fsSL https://claude.ai/install.sh \| bash`） | `~/.local/bin/claude` に入り、**バックグラウンドで自動更新する**。root 不要。ただし更新経路が dnf の外になり、`~/.local/share/claude/versions/` に版が積まれる | 不採用（自動更新が要るなら有力） |
| npm（`npm install -g @anthropic-ai/claude-code`） | Node.js 22 以上が要る。中身は同じネイティブバイナリ | 不採用 |

- どれを選んでも入るのは同じネイティブバイナリで、Node.js は実行時に使わない
- `ripgrep` は同梱されている（Alpine など musl 系以外では別途入れなくてよい）

**`stable` と `latest` の違い**:

- `stable` は 1 週間ほど遅れて、大きな不具合のある版を飛ばす
- `latest` は出た版をすぐ配る
- リポジトリが別 URL になっているだけで、切り替えは `baseurl` の書き換え（[stable チャンネルに切り替える（任意）](../almalinux-setup.md#claude-code-を-stable-チャンネルに切り替える任意)）

**既定を `latest` にした理由**:

- 本書の目的が最新版を入れることだから。`stable` のままだと 1 週間ほど遅れる
- ネイティブインストーラ（`install.sh` が取ってくる `bootstrap.sh`）も、まず `claude-code-releases/latest` が指す版を取ってくる
- 不具合に当たったときの逃げ道として、`stable` へ下げる節を用意した

- **Windows 11 の手順もこの文書に置いた**: 同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、OS ごとにファイルを分けない。手順が OS で違うので、[syncthing.md](../syncthing.md) と同じく後ろの節に分けた
- **インストーラは `& ([scriptblock]::Create(...)) <チャンネル>` の形で動かす**: 公式の文書がチャンネルを選ぶときに使う形。既定の `irm … | iex` は、インストーラの設定（`Set-StrictMode` など）を、入れた後の PowerShell に残す（[Windows 11 で使う](../windows-setup.md#claude-code)の手順 4 の補足）
- **`PATH` は本書で足す**: インストーラも `claude install` も足さず、足し方を出すだけなので、公式の文書の Verify your PATH と同じ書き方で、自分のユーザーの PATH に足す（同じ節の手順 5）
- **署名は入れた後に確かめる**: インストーラは sha256 しか照らさないので、公式の文書の `Get-AuthenticodeSignature` で `claude.exe` の署名を見る（同じ節の手順 7）。インストーラの中で動く前の確かめにはならない
- **Git for Windows を前提にした**: 公式の文書では任意だが、Claude Code の Bash のツール（と Monitor のツール）が Git Bash を使う。[Windows 11 の初期設定](../windows-setup.md)のリードの順で、先に入れる

#### Claude Code: 参照

- [Advanced setup — Claude Code Docs](https://code.claude.com/docs/en/setup) — dnf / apt / apk リポジトリの設定、チャンネル、アンインストール、署名の検証。Windows 11 の節は、Set up on Windows・Install a specific version（チャンネルを選ぶ形）・Update manually・Binary integrity and code signing・Uninstall の Windows PowerShell
- [Troubleshoot installation and login — Claude Code Docs](https://code.claude.com/docs/en/troubleshoot-install) — インストールが失敗したときの切り分け。Windows 11 の節は、Verify your PATH・Check for conflicting installations・`claude.exe` missing after an update on Windows・Claude Code does not support 32-bit Windows・Git Bash を探す順
- [CLI reference — Claude Code Docs](https://code.claude.com/docs/en/cli-reference) — `claude` のオプションとサブコマンド（[使い方の基本](../almalinux-setup.md#claude-code-の使い方の基本)）
- [Interactive mode](https://code.claude.com/docs/en/interactive-mode) / [Commands](https://code.claude.com/docs/en/commands) — セッションの中のキーとスラッシュコマンド
- [Run Claude Code programmatically](https://code.claude.com/docs/en/headless) — `-p` と `--output-format`
- [Connect Claude Code to tools via MCP](https://code.claude.com/docs/en/mcp) — `claude mcp` とスコープ
- [Continue local sessions from any device with Remote Control](https://code.claude.com/docs/en/remote-control) — `claude remote-control`
- `man dnf.conf`（`gpgcheck`、`baseurl`）
- [Authentication — Claude Code Docs](https://code.claude.com/docs/en/authentication) — 最初の起動のログインの流れと、Windows のログインの情報の置き場所（`.credentials.json`）
- [winget-pkgs の Anthropic.ClaudeCode](https://github.com/microsoft/winget-pkgs/tree/master/manifests/a/Anthropic/ClaudeCode) / [scoop の main/claude-code](https://github.com/ScoopInstaller/Main/blob/master/bucket/claude-code.json) — Windows 11 で採らなかった経路の定義
- [about_Preference_Variables（`$OutputEncoding`）— Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-5.1) — Windows PowerShell 5.1 が native のコマンドへパイプで渡す文字コード
- [Windows 11 の初期設定](../windows-setup.md) — 同じ PC で先に行う設定（貼り付けの設定と、この文書を通す順）
- [windows-claude-remote-control.md](../windows-claude-remote-control.md) — Windows 11 の節で入れた Claude Code を、SSH の切断後も Remote Control で使う

---

## 統合前の参考資料: Codex CLI（もとは codex.md）

もとの `codex.md` の参考資料を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の参考資料](windows-setup.md#統合前の参考資料-codex-cli-の-windows-11もとは-codexmd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜8 | 「Codex CLI」の手順 1〜8 |
| 更新 1〜3 | 更新の手順 5〜7 |
| ブラウザの無いホストでログインするの 1〜4 | Codex CLI をブラウザの無いホストでログインするの 1〜4 |
| 設定ファイル | Codex CLI の設定ファイル |
| ロールバック 1〜3 | ロールバックの「AI エージェントとプラグインを消す」の手順 5〜7 |

### Codex CLI: 補足

#### Codex CLI: 実施手順 / 手順 3: 補足: インストーラーが置くもの

- Node.js・npm・Homebrew は不要。CPU に合う公式の配布物を取り、SHA-256 と導入後の版を確認する
- `~/.local/bin/codex` と `~/.local/bin/codex-code-mode-host` にリンクを置き、配布物は `~/.codex/packages/standalone/` に保存する
- `~/.local/bin` が PATH に無い場合、bash では `~/.bashrc` に `# >>> Codex installer >>>` から `# <<< Codex installer <<<` までのブロックを足す
- 自分用の [bash の設定](https://github.com/ryo-aoki-pc/bash)を入れたホストでも、追加の設定を手書きする必要は無い

#### Codex CLI: 実施手順 / 手順 3: 補足: パッケージマネージャーで入れない理由

- 配布はある: Homebrew の cask `codex`（Linux でも入る）、scoop の main の `codex`、WinGet の `OpenAI.Codex`
- どれも、そのパッケージマネージャーのコマンド（`brew upgrade --cask codex`・`scoop update codex`・`winget upgrade`）を打たないと上がらない
- Homebrew の cask で入れた Codex（AlmaLinux 10）では、`codex update` が `Could not detect the Codex installation method.` で止まった（[検証記録](../verification/almalinux-setup.md#codex-cli-付録-起動したときの更新とパッケージマネージャー2026-10-09)）
- standalone のインストーラーで入れたものは、起動したときの知らせから Enter 1 回で上がる（[更新: 補足](#codex-cli-更新-補足-起動したときの知らせ)）。利用者の希望（自動で最新になるなら公式の方法でよい）に近いので、こちらを採る

#### Codex CLI: 実施手順 / 手順 3: 補足: Start Codex now? に n と答える理由

- `Start Codex now?` に `n` と答えるのは、同じ節の手順 8 で起動するため

#### Codex CLI: 実施手順 / 手順 4: 補足: 版

- 検証時の版は `0.160.0`

#### Codex CLI: 更新: 補足: 起動したときの知らせ

- 端末の Codex は、起動したときに、最新の版を GitHub（`api.github.com/repos/openai/codex/releases/latest`）に問い合わせ、`~/.codex/version.json` に控える。控えが無いか古いときだけ問い合わせる
- 控えた版が今の版より新しいと、起動の画面に `Update available!` を出す。`1. Update now` は、入れ方に合う更新のコマンドを動かす
- standalone のインストーラーで入れたものでは、`sh -c 'curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh'` を動かす
- Windows 用の `install.ps1` を使う同じ形のコマンドも、配布物の中にある
- `codex update` も、同じインストーラーを動かす

#### Codex CLI: 更新 / 手順 2: 補足: もう一度実行したとき

- 公式インストーラーをもう一度実行すると、新しい配布物を導入する

#### Codex CLI: 参照

- [OpenAI: Codex CLI](https://learn.chatgpt.com/docs/codex/cli) — 導入・起動・更新
- [公式 Linux/macOS インストーラー](https://chatgpt.com/codex/install.sh)
- [公式 Windows インストーラー](https://chatgpt.com/codex/install.ps1)
- [OpenAI: Authentication](https://learn.chatgpt.com/docs/auth) — ChatGPT・API キー・デバイスコード・資格情報の保存
- [OpenAI: Windows sandbox](https://learn.chatgpt.com/docs/windows/windows-sandbox) — Windows 11、初回の管理者承認
- [OpenAI: Config basics](https://developers.openai.com/codex/config-basic) — ユーザー設定
- [Homebrew: codex](https://formulae.brew.sh/cask/codex) — Homebrew の cask（使わなかった経路）

---

## 統合前の参考資料: Grok Build（もとは grok-build.md）

もとの `grok-build.md` の参考資料を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の参考資料](windows-setup.md#統合前の参考資料-grok-build-の-windows-11もとは-grok-buildmd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜7 | 「Grok Build」の手順 1〜7 |
| 更新 1・2 | 更新の手順 5・8 |
| ブラウザの無いホストでログインするの 1〜3 | Grok Build をブラウザの無いホストでログインするの 1〜3 |
| 設定ファイル | Grok Build の設定ファイル |
| ロールバック 1〜4 | ロールバックの「AI エージェントとプラグインを消す」の手順 8〜11 |

### Grok Build: 補足

#### Grok Build: 実施手順 / 手順 3: 補足: 版と PATH

- 検証時の版は `1.0.50`
- 新しく開いた端末で `grok` が通るのは、`~/.bashrc` のブロックが PATH を通すため

#### Grok Build: 実施手順 / 手順 6: 補足: 検証時のモデルの一覧

- ログインしていなくても出るモデルの一覧は、検証時は `grok-4.6` と `grok-4.5`

#### Grok Build: 更新 / 手順 2: 補足: 古い版の配布物

- 古い版の配布物は `~/.grok/downloads` に残ることがある。使っている量は `grok du` で見る

### Grok Build: 選択した方針

- xAI の公式のインストーラー（`https://x.ai/cli/install.sh`・`install.ps1`）を使う
  - 公式のインストーラーで入れた Grok は、対話の画面の起動のときに、自分で新しい版に上がる（[更新: 自動の更新の仕組み](#grok-build-更新-自動の更新の仕組み)）。利用者の希望（自動で最新になるなら公式の方法でよい）に合う
  - Node.js を増やさず、両 OS で同じ配布元・同じ `grok update` で上げられる
- パッケージマネージャーでは入れない
  - 配布はある: Homebrew の cask `grok-build`（Linux でも入る）、WinGet の `xAI.GrokBuild`（portable）、npm の `@xai-official/grok`。scoop の main と extras には無い（2026-10-09）
  - Homebrew と WinGet の版は、`brew upgrade --cask grok-build`・`winget upgrade` を打たないと上がらない
  - npm の版は Node.js が要る
  - Homebrew の cask で入れた Grok でも、`grok update` は Homebrew を使わずに Grok 自身で入れる
  - `grok update --force-reinstall` を打つと、Homebrew の外（`~/.grok/bin`・`~/.grok/downloads`）に別の Grok が入り、Homebrew の版はそのままだった（[検証記録](../verification/almalinux-setup.md#grok-build-homebrew-の-cask)）
  - Homebrew で使うなら、自動の更新を止め（`[cli] auto_update = false`）、`brew upgrade --cask grok-build` で上げる形になる
  - WinGet で入れた Grok では、`grok update` は WinGet のコマンドを出すだけで何も変えない
  - Homebrew の formula の `grok`（`brew install grok`）は Grok Build ではない（正規表現でログを読む別のツール）
- ログインは grok.com のアカウント（ブラウザ）で行う
  - API キー（`XAI_API_KEY`）は、ログインが無いときだけ使われ、API の従量課金になる
  - 利用者の契約がサブスクリプション（SuperGrok / X Premium）なので、API キーの手順は置かない
- 非公式の grok-cli（superagent-ai の `grok-dev`）は採らない。同じ `grok` の名前と `~/.grok` を使い、2026-05 から更新が止まっている（調査時）
- 確認用のディレクトリでの起動は [codex.md](../almalinux-setup.md#codex-cli) と同じ形にした（`~/grok-sandbox`）

#### Grok Build: 実施手順 / 手順 1: 名前がぶつかるもの

- インストーラーは `~/.grok/bin` に `grok` と `agent` の 2 つのリンクを置く（中身は同じ）
- `~/.local/bin` が PATH にあって `~/.grok/bin` が無いときは、`~/.local/bin/grok`・`~/.local/bin/agent` にもリンクを置く。`ln -sf` なので、同じ名前のファイルがあっても置き換える
- Cursor の CLI も `agent` の名前を使う。両方を使うなら、PATH の順でどちらが動くかを確かめる

#### Grok Build: 実施手順 / 手順 2: インストーラーが置くものと `~/.bashrc`

- 置くもの（AlmaLinux 10、1.0.50）
  - 配布物: `~/.grok/downloads/grok-linux-x86_64`（約 175 MB の実行ファイル 1 つ）
  - リンク: `~/.grok/bin/grok`・`~/.grok/bin/agent`（どちらも `../downloads/…` を指す）
  - 補完: `~/.grok/completions/bash/grok.bash`・`zsh/_grok`
  - 文書: `~/.grok/docs/user-guide/*.md`（利用者向けの文書 27 本。Web の文書と同じ内容の手元の写し）
  - 設定: `~/.grok/config.toml`（`[cli]` と `installer = "internal"` の 2 行）
- `~/.bashrc` の末尾に足すブロック（`SHELL` が bash のとき。zsh は `~/.zshrc`、fish は `config.fish`）

  ```bash
  # >>> grok installer >>>
  export PATH="$HOME/.grok/bin:$PATH"
  [[ -r "$HOME/.grok/completions/bash/grok.bash" ]] && source "$HOME/.grok/completions/bash/grok.bash"
  # <<< grok installer <<<
  ```

  - 初回は元の `~/.bashrc` を `~/.bashrc.bak.<UNIX 時刻>` に控える。2 回目からは、前のブロックを消して末尾に足し直す（ブロックの前の空行が 1 つずつ増える）
  - 書かせない設定（環境変数など）はインストーラーに無い。`SHELL` が bash・zsh・fish 以外のときだけ書かない
  - `~/.bashrc` がリンクなら、リンク先のファイルを書き換える
- setup-notes では `~/.bashrc` への追記を [ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash) に集めているが、このブロックはインストーラーが毎回書くので、手順書では消さずに残し、[ロールバック](../extra/almalinux-setup.md#ai-エージェントとプラグインを消す)の手順 3 で消す（codex.md のインストーラーが足すブロックと同じ扱い）
  - 共通の bash 設定より後ろで読まれるので、`~/.grok/bin` が PATH の先頭に来る
- インストーラー（`install.sh`）は、配布物のハッシュや署名を確かめない（Windows の `install.ps1` が同梱の Git の zip の SHA-256 を確かめるだけ）

#### Grok Build: 実施手順 / 手順 4〜6: ログインの流れ

- `grok login` は SpaceXAI の OAuth（`auth.x.ai`）でログインする。ブラウザが開けないときは、`https://accounts.x.ai/oauth2/device?user_code=…` の URL と確認用のコードを出して待つ（`--device-auth` と同じ画面）
- ログインの情報は `~/.grok/auth.json`（Unix では `0600`）に入り、自動で更新される。更新できなくなると、もう一度ログインを求められる（公式の文書 02-authentication）
- `grok models` は、ログインしていなくても終了コード 0 で、`You are not authenticated.` と既定のモデルの一覧を出す（1.0.50）。Claude Code のプラグインの `/grok-build:check` も、この終了コードだけで「ログイン済み」と判定する（[coding-agents.md の注意点](../extra/coding-agents.md#注意点)）

#### Grok Build: 実施手順 / 手順 7: フォルダーの信頼

- Grok は、信頼したフォルダーでだけ、起動のときにプロジェクトの指示書（AGENTS.md・CLAUDE.md など）・skills・MCP サーバー・hooks を読む
- 信頼は `~/.grok/trusted_folders.toml` に残る。対話の画面で答えるか、`--trust` を付けて起動すると記録される
- 信頼はそのリポジトリの下のディレクトリにも効く。入れ子の別の git のチェックアウトや、別の場所の worktree は、別に信頼する

#### Grok Build: 更新: 自動の更新の仕組み

- 設定の `[cli] auto_update`（既定は有効）で、対話の画面の起動のときに新しい版を確かめる。環境変数 `GROK_DISABLE_AUTOUPDATER` でも止められる（同梱の文書 05-configuration・26-config-reference）
- 確かめた時刻は `~/.grok/version.json` の `checked_at` に残り、間もないうちは確かめない
- 新しい版は `~/.grok/downloads/grok-<版>-<OS>-<CPU>` に入り、`~/.grok/bin` の `grok`・`agent` のリンクが付け替わる。前の配布物は残る
- 更新の入れ方は、設定の `[cli] installer`（公式のインストーラーは `internal` を書く）で選ばれる（同梱の文書 26-config-reference）
- 確かめた範囲は[検証記録](../verification/almalinux-setup.md#grok-build-付録-自動の更新とパッケージマネージャー2026-10-09)

#### Grok Build: 注意点: Linux の sandbox を起動できないとき

- Linux のファイルアクセス制限には Landlock が要る。カーネルの版が 5.13 以降でも、`CONFIG_SECURITY_LANDLOCK=y` で組み込まれ、起動中のカーネルで有効になっている必要がある。`/sys/kernel/security/lsm` に `landlock` があることを確かめる
- bubblewrap は、拒否するパスの遮蔽などに使う。bubblewrap があることだけでは `read-only` の書き込み制限が効くと判断しない
- `runtime-socket deny path /run/podman/podman.sock` の `Permission denied (os error 13)` は、ソケット本体に限らず、親ディレクトリを検索できないときも出る。Podman が停止し、ソケットが存在しなくても、親の検索権限が無ければ失敗する。親ディレクトリの検索権限を確かめ、ソケット本体の権限は緩めない
- `read-only` は起動時に `/run/docker.sock` と `/run/podman/podman.sock` を調べるが、`workspace` は調べない。`workspace` が `could not apply the 'workspace' sandbox profile` で止まるときは、ソケットの親ではなく Landlock の側を確かめる（Grok 1.0.50 の起動時のシステムコールを実機で追った。[検証記録](../verification/almalinux-setup.md#grok-build-sandbox-の再起動なしの追加検証)）
- 親の検索権限を直した後も、カーネルの保護を適用できず起動を拒否する場合がある。Landlock が有効なカーネルで OS を起動してから、同じ sandbox を再試行する。Grok 1.0.50 の実機で確認した 2 つの原因と、対処の準備結果は[追加の調査記録](../verification/almalinux-setup.md#grok-build-sandbox-の追加原因調査と対処の準備)に分けた。今回の実機ではユーザーの指示により対処を適用せず、調査と準備までで終了した

#### Grok Build: 注意点: 会話のデータの扱い

- `/privacy` は、設定の Coding data, retention, and training を開き、Opt in / Opt out を選ぶ（公式の文書 04-slash-commands）
- 2026-07 に、ベータ版の `grok` がディレクトリの中身を xAI のクラウドのストレージに送ることがあったと報告された（Simon Willison のブログ、2026-07-15。二次情報）
  - 同じ記事が引く xAI の発表は「2026-07-12 から、すべての Grok Build の利用者で既定の保存を止めた」「それまでに送られたデータは削除する」としている
  - その後、ソースコードが Apache-2.0 で公開された（github.com/xai-org/grok-build）
- 秘密情報のあるディレクトリで `grok` を起動しない。sandbox（`--sandbox read-only` など。Linux と macOS だけ。Linux では有効な Landlock と bubblewrap が要る）で書き込める場所を絞れる

### Grok Build: 参照

- [xAI: Grok Build CLI の発表](https://x.ai/news/grok-build-cli)（2026-05-25。対象は SuperGrok と X Premium+）
- [xAI: Grok Build の文書](https://docs.x.ai/build/overview) — 導入・ログイン・使い方
- 手元の文書 `~/.grok/docs/user-guide/`（1.0.50 に同梱）: 01-getting-started・02-authentication・05-configuration・12-project-rules・14-headless-mode・18-sandbox・22-permissions-and-safety・26-config-reference
- [公式の Linux / macOS のインストーラー](https://x.ai/cli/install.sh)・[公式の Windows のインストーラー](https://x.ai/cli/install.ps1)
- [xai-org/grok-build](https://github.com/xai-org/grok-build) — ソース（Apache-2.0）
- [Homebrew: grok-build](https://formulae.brew.sh/cask/grok-build) — Homebrew の cask（使わなかった経路）
- [xAI: Models](https://docs.x.ai/developers/models) — モデルと料金（API キーで使うとき）
- [Simon Willison: xai-org/grok-build, now open source](https://simonwillison.net/2026/Jul/15/grok-build/)（二次情報）
