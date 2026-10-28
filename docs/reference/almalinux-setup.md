# AlmaLinux 10 のセットアップの参考資料

[AlmaLinux 10 のセットアップ](../almalinux-setup.md)・[注意点](../extra/almalinux-setup.md)

## 補足

### ログインと sudo / 手順 1: 補足: 日本語の名前のフォルダー

- このログインで、ホームに日本語の名前のフォルダー（`ダウンロード`・`ドキュメント` など）ができる。「GNOME の表示と入力」の手順 2 で英語の名前にする

### ログインと sudo / 手順 3: 補足: 貼り直し

- 貼り直しても同じ内容で置き直すだけ（何度貼ってもよい）

### OS とファームウェアの更新 / 手順 2: 補足: fwupd の起動待ち

- `デーモンへの接続に失敗しました: … タイムアウトしました` が出るのは、起動の直後に fwupd の起動が間に合わないことがあるため

### システムの設定 / 手順 1: 補足: 変数の意味

- `HOST_NAME` は、SSH・RDP・Samba・Syncthing などで、この PC を見分ける名前
- 変数はその端末の中だけで有効なので、新しい端末を開いたら貼り直す

### システムの設定 / 手順 3: 補足: SSH の既定とログイン

- `enabled`・`active`・`yes`・`yes` は、Workstation の既定
- 別の PC からは `ssh <USER>@<IP>` でログインできる（初めてつなぐときは、ホストの鍵の fingerprint を聞かれる）

### システムの設定 / 手順 5: 補足: journal の置き場所

- AlmaLinux 10 の既定では `/var/log/journal` が無く、journal は `/run/log/journal`（メモリー）にだけ書かれて、再起動で消える
- journald が作った `/var/log/journal` に付かない ACL は、`wheel`・`adm` のグループが読めるもの（付け直す仕組みは[選択した方針](#選択した方針)）
- 前の起動のログが読めることは、「再起動と確認」の手順 1 の再起動の後に、同じ項の手順 3 で確かめる

### システムの設定 / 手順 6: 補足: 予約しているメモリー

- `/sys/kernel/kexec_crash_size` の数は、予約しているメモリーのバイト数（`268435456` で 256 MiB）

### システムの設定 / 手順 7: 補足: 効く時期

- メモリーが空くのは、「再起動と確認」の手順 1 の再起動の後

### システムの設定 / 手順 8: 補足: 外した後

- 外すと、無いコマンドを打ったときは `bash: <コマンド>: コマンドが見つかりません...` とだけ出て、パッケージを探して待たされない

### EPEL と RPM Fusion / 手順 1: 補足: EPEL の入手元と使う手順書

- `epel-release` は AlmaLinux の `extras` リポジトリにあるので、追加のリポジトリの設定は要らない
- 最後に出る「CRB を有効にすることを推奨」を気にしなくてよいのは、AlmaLinux 10 では CRB が既定で有効なため（[導入元一覧](../tool-catalog.md#導入経路と-el10-での注意)）
- EPEL を使う手順書（[btop](../almalinux-setup.md#btop)・[distrobox](../containers.md#distrobox)・[podman-compose](../containers.md#podman-compose)・[podman-tui](../containers.md#podman-tui)・[VirtualBox](../virtual-machines.md#virtualbox)）と、[導入元一覧](../tool-catalog.md)の EPEL の行が使えるようになる

### EPEL と RPM Fusion / 手順 1: 補足: 出力例と、EPEL の鍵

`epel-release` は、repo ファイル（`/etc/yum.repos.d/epel.repo` と、無効の `epel-testing.repo`）と、鍵のファイル `/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-10` を置く。

取り込んだ鍵は、`rpm -q gpg-pubkey` に `gpg-pubkey-e37ed158-65785fa9` として出る。

### EPEL と RPM Fusion / 手順 4: 補足: localpkg_gpgcheck と free

- `--setopt=localpkg_gpgcheck=1` を外さない理由は、[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#rpm-fusion-実施手順--手順-3-補足-署名の確認とepel-を前提にした理由)と[RPM Fusion の選択した方針](#epel-と-rpm-fusion)
- 有効にするのは free だけ。nonfree は扱わない

### EPEL と RPM Fusion / 手順 5: 補足: 使えるようになるもの

- [Firefox の AAC・H.264](../almalinux-setup.md#firefox)（RPM Fusion の `ffmpeg-libs` を入れる）が使えるようになる

### Flatpak と Flathub / 手順 1: 補足: flatpak と Flathub の登録

検証記録は[Flatpakの記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#flatpak-の記録)を参照する。

- Workstation には flatpak が最初から入っている
- `flathub` の行が既にあれば、「Flatpak と Flathub」の手順 3 は何もしない（`--if-not-exists` のため）

### Flatpak と Flathub / 手順 2: 補足: 鍵は登録ファイルの中にある

`flathub.flatpakrepo` は鍵を**本文に base64 で埋め込んで**いて、`flatpak remote-add` はこの鍵をリモートの設定に取り込む。以後の取得はすべてこの鍵で署名を検証する。したがって、確かめるべきは「登録ファイルの中の鍵が Flathub のものか」の 1 点になる（[VS Code](../almalinux-setup.md#vs-code) の手順で rpm の鍵を確かめているのと同じ考え方）。

`gpg --show-keys` は鍵を**鍵束に取り込まずに表示するだけ**。ただし `~/.gnupg` が無ければ最初の実行で作られる（`gpg: directory '/home/<USER>/.gnupg' created`）。

### Flatpak と Flathub / 手順 3: 補足: 使えるようになるもの

- [導入元一覧](../tool-catalog.md#gui)の「Flathub」の行にある GUI アプリが入れられるようになる。[Firefox](../almalinux-setup.md#firefox) と [VS Code](../almalinux-setup.md#vs-code) は Flathub を使わず RPM で入れる

### Flatpak と Flathub / 手順 4: 補足: 確認用のアプリ

- 確認用のアプリは、小さい [Flatseal](https://flathub.org/apps/com.github.tchx84.Flatseal)（Flatpak アプリの権限を GUI で変えるツール）にしてある

### Homebrew / 手順 2: 補足: Next steps を行わない理由

- `Next steps` の `~/.bashrc` への追記を行わないのは、共通の bash 設定が `brew shellenv` を読むため

### Homebrew / 手順 3: 補足: 日々の操作

- 日々の操作は[Homebrew の使い方の基本](../almalinux-setup.md#homebrew-の使い方の基本)

### Homebrew / 手順 4: 補足: IBus の PATH を固定する理由

- Anthy のエンジン（`/usr/libexec/ibus-engine-anthy`）は、`exec python3 /usr/share/ibus-anthy/engine/main.py` と書かれた sh の包みで、PATH で最初に見つかった `python3` で動く
- 共通の bash 設定は、Homebrew のディレクトリを PATH の先頭に置く。2026-10-11 の Hyper-V の VM では、`gnome-shell` と `ibus-daemon` の環境にも Homebrew を含む PATH があった。セッションへ取り込まれる具体的な経路は、確かめていない
- Homebrew の `python3` は、formula の依存として入る（2026-10-11 は、「yazi」の手順 2 の既定のツールで `python@3.15` が入った）。この `python3` には `gi`（PyGObject）が無いので、エンジンが `ModuleNotFoundError: No module named 'gi'` で起動しない
  - 上部バーの表示は `あ` に変わるが、打った字は英字のまま入り、Space でも変換されない
  - `ibus list-engine` は、エンジンが起動できない状態でも `anthy - Anthy` を出す。FXB では、入力不能の状態でも journal の `ModuleNotFoundError` は 0 行だった。この行が無いことだけでは、復旧したと判断できない
  - 入力不能の状態で出たのは、gnome-shell の `Gio.IOErrorEnum: タイムアウトしました`（`_setEngine`）。切り替えた後も `ibus engine` は `xkb:us::eng` のままで、Anthy のエンジンのプロセスは無かった。包みをその PATH で `--xml` 付きで呼ぶと、`ModuleNotFoundError` が出た
- GNOME のユーザーサービス `org.freedesktop.IBus.session.GNOME.service` が `ibus-daemon` を起動する（FXA・FXB の `systemctl --user show` の起動コマンド・PID と、プロセスの環境を照合）。ドロップインは、このユニットの PATH だけを `/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin` に置き換える
  - Homebrew を含まない、決め打ちの PATH であり、systemd のユーザーマネージャーの既定値を写したものではない。`~/.local/bin`・`~/bin` なども、このユニットの PATH から外れる
  - FXA のドロップインを置く前の `ibus-daemon` の PATH は、`/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/home/<USER>/.local/bin:/home/<USER>/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin` だった（Homebrew 本体は導入済み。`FXA/out/02-baseline-before-step4.txt`）。Homebrew 導入前のユーザーマネージャーの PATH は、今回の証跡では確かめていない
  - 検証した VM では、この設定の後に起動した `ibus-daemon` から、Anthy のエンジンは `/usr/bin/python3` で起動された。端末と `gnome-shell` の PATH は変わらない
  - GNOME 以外のセッションや、別の経路で `ibus-daemon` を起動する構成は対象の外で、確かめていない。セッションの PATH で起動される `/usr/libexec/ibus-setup-anthy`（Anthy の設定）が開くかも、確かめていない
- 2026-10-11 の通しでは、Hyper-V・VMware・VirtualBox の VM で、この設定が無いと変換できなかった。直しの確かめは Hyper-V の VM に限る（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#手順書を直した所とその確かめ)）
  - FXA では、Homebrew の `python3` が無い状態で手順 4 を置き、「yazi」の手順 2 で `python@3.15` を入れ、再起動した後に、テキストエディターで「日本語」への変換と確定を確かめた
  - FXB では、入力不能の状態から手順 4 と再起動を通し、テキストエディターと WezTerm の Neovim で日本語入力と IME 切り替えを確かめた。Neovim の整形は、初めから整形済みで、変化を見分けられなかった
  - ログインし直しだけで効くこと・VMware・VirtualBox・実機での直しは、確かめていない

### Homebrew を root のシェルでも使う / 手順 1: 補足: シェルごとの PATH

| 入口 | 読むファイル | Homebrew のコマンド |
|---|---|---|
| `su -`、ssh での root のログイン | `/etc/profile` → `/root/.bash_profile` → `/root/.bashrc` | 使える |
| `sudo -i` | 同上。PATH の始まりは sudo の `secure_path` | 使える |
| `sudo -s`、`su`（`-` 無し） | `/root/.bashrc`（`sudo -s` でも `HOME` は `/root`） | 使える |
| `sudo <コマンド>` | 読まない。PATH は `secure_path` の `/sbin:/bin:/usr/sbin:/usr/bin` | 使えない（`sudo: jq: command not found`）。[sudo でも使う](../almalinux-setup.md#homebrew-を-sudo-でも使う)の節で使える |

- **`su`（`-` 無し）も、Homebrew のユーザーの PATH を引き継がない**: PATH は root のものに置き換わる
- **cron や systemd の unit では見えない**: `~/.bashrc` を読まないため（[注意点](../extra/almalinux-setup.md#注意点)の「`~/.bashrc` を読まない文脈」と同じ）。フルパスで書く

### Homebrew を sudo でも使う / 手順 1: 補足: 使い方

- Homebrew で入れたコマンドを、`sudo jq --version` のように打てる
- `sudo` でどれが使われるかは、`sudo bash -c 'type -a <コマンド>'` で見る（先頭の行が使われる）

### Homebrew を sudo でも使う / 手順 1: 補足: 呼び出し方ごとの PATH

| 入口 | PATH | Homebrew のコマンド |
|---|---|---|
| `sudo <コマンド>`、`sudo -u <ユーザー> <コマンド>`、`sudo bash <スクリプト>` | `secure_path`（`/sbin:/bin:/usr/sbin:/usr/bin` の後ろに 2 つ） | 使える（`sudo jq --version` は `jq-1.8.2`） |
| `sudo -E <コマンド>` | 同上（`-E` でも、自分の PATH は渡らない） | 使える |
| `sudo -s` | `/root/.local/bin:/root/bin` の後ろに `secure_path` | 使える（PATH の末尾） |
| `sudo -i` | `/root/.local/bin:/root/bin:/usr/local/sbin` の後ろに `secure_path` | 使える（PATH の末尾） |
| `sudoedit`（`EDITOR=nvim`） | エディタを `secure_path` で探し、自分のユーザーと自分の環境で動かす | Homebrew の `nvim`。設定は自分の `~/.config/nvim` |
| `sudo EDITOR=nvim visudo` | エディタを `secure_path` で探し、root で動かす | Homebrew の `nvim`。設定は `/root/.config/nvim` |
| `su -`、`sudo su -`、ssh での root のログイン | sudo の `secure_path` を通らない | 使えない（[root のシェルでも使う](../almalinux-setup.md#homebrew-を-root-のシェルでも使う)の節で使える） |

### dnf-automatic で自動で更新する / 手順 2: 補足: 入れる更新の設定

- 何を入れるか（`upgrade_type`）などは `/etc/dnf/automatic.conf` にある。このタイマーは、その設定の `apply_updates` に関わらず、更新を入れる

### dnf-automatic で自動で更新する / 手順 3: 補足: GNOME Software の設定

- `download-updates` を `false` にすると、GNOME Software の「設定」の「自動更新」がオフになる
- 更新があることの通知と、手で入れる更新は、そのまま使える

### 日本語入力 / 手順 2: 補足: 入っているときと入れたとき

検証記録は[日本語入力の記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#日本語入力-の記録)を参照する。

- Workstation で入れた PC には、3 つとも最初から入っている
- 入れたときに「再起動と確認」の手順 1 の再起動を待つのは、動いている IBus が、ログインし直すまで Anthy を使えないため

### 日本語入力 / 手順 3: 補足: 入力ソースを切り替えるキー

- 最後の `get` の `['<Super>space', 'XF86Keyboard']` が、入力ソースを切り替えるキー（Super+Space）

### GNOME の表示と入力 / 手順 1: 補足: 変数の意味

- `DASH_FAVORITES` は、この項の手順 14 で、アクティビティの画面の下の Dash に並べるアプリ（`/usr/share/applications` の `.desktop` のファイル名）

### GNOME の表示と入力 / 手順 2: 補足: 中身とログインの窓

- 中身は、フォルダーごと移る
- 次のログインで「標準フォルダーの名前を現在の言語に合わせて更新しますか?」の窓は出ない（`~/.config/user-dirs.locale` は今の言語のまま）

### GNOME の表示と入力 / 手順 3: 補足: 設定アプリとの対応

- 設定の「外観」の「スタイル」の「ダーク」と同じで、すぐに効く

### GNOME の表示と入力 / 手順 4: 補足: 効く範囲

- 自分のセッションだけの設定。ログイン画面と、ほかのユーザーには効かない

### GNOME の表示と入力 / 手順 5: 補足: 既定値

- `button-layout` の既定は `'appmenu:close'`

### GNOME の表示と入力 / 手順 7: 補足: 2 つのスキーマ

- Files と GTK4 のアプリは `org.gtk.gtk4`、GTK3 のアプリは `org.gtk` を読む
- Files では Ctrl+H で、隠しファイルを出す・隠すを切り替えられる

### GNOME の表示と入力 / 手順 8: 補足: アプリごとの切り替え

- アプリごとの切り替えは Super+Tab に残る

### GNOME の表示と入力 / 手順 9: 補足: アクティビティの画面

- ホットコーナーを切った後も、アクティビティの画面は Super キーで開く

### GNOME の表示と入力 / 手順 10: 補足: 拡大率を選ぶ時期

- 拡大率を選ぶのは、「再起動と確認」の手順 1 の再起動の後に、同じ項の手順 4 で行う

### GNOME の表示と入力 / 手順 11: 補足: 版

- 入る `gnome-shell-extension-appindicator` は、AlmaLinux 10.2 では 61

### GNOME の表示と入力 / 手順 12: 補足: 効く時期

- 動いている GNOME Shell は、ログインし直すまで、入れたばかりの拡張を読まない。「再起動と確認」の手順 1 の再起動の後に、同じ項の手順 3 で確かめる

### GNOME の表示と入力 / 手順 13: 補足: 設定アプリでの表示

- 足したショートカットは、設定の「キーボード」→「キーボードショートカット」→「カスタムショートカット」にも出る

### 画面オフ・画面ロック・自動サスペンドを止める / 手順 1: 補足: 変数の有効な範囲

検証記録は[画面オフ・ロック・サスペンドの記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#画面オフロックサスペンド-の記録)を参照する。

- 変数はそのシェルの中だけで有効なので、新しいシェルを開いたら貼り直す

### 画面オフ・画面ロック・自動サスペンドを止める / 手順 1: 補足: 変数について

- 画面を消したいなら、`IDLE_DELAY` に秒数を入れる（`300` で 5 分）。消えたときにロックもするなら `LOCK_ENABLED=true`
- 放置したときにサスペンドするかどうかは変数にしていない。手順 2・3 で `nothing`（何もしない）を直接書く
  - 手順 4 でサスペンドとハイバネートを OS ごと止めるので、ほかに選べる値が無いため
- `POWER_BUTTON` も同じ理由で、`suspend` / `hibernate` は選ばない
  - `interactive` は、設定アプリの「電源ボタンの挙動」の「電源オフ」にあたる
  - 押すと何をするかを聞く画面が出て、何も選ばなければ 60 秒で電源が切れる（RHEL 10 の文書の 13.1.2 節）

### 画面オフ・画面ロック・自動サスペンドを止める / 手順 2: 補足: 読み戻し

- 最後の 3 つのコマンドで読み戻す

### 画面オフ・画面ロック・自動サスペンドを止める / 手順 3: 補足: ログイン画面の設定ファイル

- ファイルには、自動サスペンドと電源ボタンの設定を書く
- 文字列の値は引用符（`'`）で囲む。囲まないと、`dconf update` が失敗する

### 画面オフ・画面ロック・自動サスペンドを止める / 手順 4: 補足: mask の効き目

- GNOME のメニュー・蓋・電源ボタンなど、どこから頼まれてもサスペンドが始まらなくなる

### 画面オフ・画面ロック・自動サスペンドを止める / 手順 5: 補足: 蓋の既定値

- `HandleLidSwitch` の既定は `s "suspend"`
- 蓋の無い PC では何も変わらない（置いても害は無い）

### Git / 手順 1: 補足: 変数について

[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#git-補足の実測)

- GitHub に push するなら、メールアドレスに GitHub の noreply のアドレス（`<ID>+<GITHUB_USER>@users.noreply.github.com`）を使うと、私用のアドレスをコミットに載せずに済む。アドレスは GitHub の Settings の Emails で確かめる
- 名前に空白を入れるときは、引用符の中に書く（引用符が無いと、空白の後ろがコマンドとして実行される）
- 使うのは手順 3 だけ。後から変えるときは、手順 1 と手順 3 を貼り直す（`git config --global` は同じキーを上書きする）
- 変数はそのシェルの中だけで有効

### Git / 手順 4: 補足: 設定の意味

- `pull.rebase true`: `git pull` が、取ってきた履歴の上に自分のコミットを載せ直す（マージコミットを作らない）
- `rebase.autoStash true`: 未コミットの変更があっても pull できる（pull の前に stash し、後で戻す）
- `core.autocrlf false`: チェックアウトでもコミットでも、改行を変換しない

### Git / 手順 5: 補足: 推奨の設定と、入れなかった設定

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

- `merge.conflictStyle zdiff3` は [git-delta 手順 3](../almalinux-setup.md#git-delta) と同じ設定で、どちらを先に通してもよい

入れなかったもの:

- `core.editor`: 好みで決める。未設定なら、環境変数 `VISUAL`・`EDITOR` のエディタ、どちらも無ければ `vi` が開く。Windows では、インストーラで選んだエディタが `system` に入る
- `rerere.autoUpdate`: 覚えた解き方を当てた後に、`git add` までする。当てた結果を `git diff` で見てから add したいので入れない
- `fetch.pruneTags`: リモートに無いタグを、ローカルからも消す
- `pull.ff only`: 分岐したときの pull が、rebase せずに止まる（「Git」の手順 7）
- `push.default`: 既定の `simple`（今のブランチを、同じ名前の追跡ブランチにだけ push する）のままでよい

### Git / 手順 6: 補足: pull.ff

- 最後の `pull.ff` が何も出さないのは、設定が無いこと

### Git / 手順 8: 補足: 確かめている設定

- `?? 日本語.txt` がそのまま出るのは `core.quotepath`
- `i/crlf  w/crlf` は、CRLF のまま入ったこと（`core.autocrlf`）
- ブランチの `main` は `init.defaultBranch`
- `branch 'main' set up to track 'origin/main'.` は `push.autoSetupRemote`

### Git / 手順 9: 補足: 残る変更

- `M crlf.txt` は、pull の前の、未コミットの変更

### 改行を変換して clone したリポジトリを直す / 手順 2: 補足: 保存しなかったとき

- `No local changes to save` は、今回は保存していないこと

### 改行を変換して clone したリポジトリを直す / 手順 4: 補足: 別の stash を作らない理由

- `pop` は先頭の stash を戻すため

### git-delta / 手順 1: 補足: 変数について

検証記録は[git-deltaの記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#git-delta-の記録)を参照する。

- 3 つとも表示の好みなので、既定のままで進められる
- 3 つとも `~/.gitconfig` の `[delta]` に書かれる値で、後から `git config --global delta.side-by-side true` で変えられる
- `navigate` を `true` にすると、ページャ（`less`）の中で `n` が「次の変更へ」になる。delta が `less` に渡すオプションで実現しているので、`core.pager` 経由で起動したときだけ効く

### git-delta / 手順 2: 補足: 降ってくるボトル

aarch64 で降ってくるボトルは `git-delta--0.19.2.arm64_linux.bottle.tar.gz`。

- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない

### git-delta / 手順 2: 補足: formula 名とコマンド名

- formula 名は `git-delta` だが、入るコマンドは `delta`（`brew install delta` でも同じ formula に解決される）

### git-delta / 手順 3: 補足: git の設定の書き方

- `~/.gitconfig` を直接編集せず、`git config --global` で書く（既にある `[user]` や `[core]` を壊さない）
- ブロックの最後の行で、書けたか読み戻す
- `interactive.difffilter` と小文字で表示されるのは、git がキー名を正規化するため。`~/.gitconfig` の中では `diffFilter` のまま
- `merge.conflictstyle zdiff3` は delta とは独立した設定だが、コンフリクト表示が読みやすくなるので一緒に入れている
- `zdiff3` は git 2.35 以降で使える（AlmaLinux 10 の RPM は 2.52.0）
- [Git の手順 5](../almalinux-setup.md#git) でも同じ値を入れる。先に通していても、同じキーが書き直されるだけ

### git-delta / 手順 4: 補足: 差分の出し方

- ブロックの最後の行で、変更のあるリポジトリの差分を出す

### GitHub CLI / 手順 1: 補足: 生成される repo ファイルと、dnf4 と dnf5 の構文の違い

検証記録は[GitHub CLIの記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#github-cli-の記録)を参照する。

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

### GitHub CLI / 手順 2: 補足: 署名鍵

- 鍵が 2 本あるので、初回は取り込みを 2 回聞かれる

### GitHub CLI / 手順 4: 補足: 認証

トークンは OS の資格情報ストアに保存される。ストアを使えない場合は `~/.config/gh/hosts.yml` の平文保存に切り替わる。保存先は `gh auth status` で確認する。`gh auth token` の出力は**記録しない**。

### lazygit / 手順 1: 補足: ボトル

- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない

### lazygit / 手順 3・4: 補足: 起動時の注意

[この節の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#lazygit-実施手順--手順-3-補足-起動時の注意)

`lazygit --version` の `git version` 欄には、lazygit が呼ぶ git のバージョンが出る。

**git が入っていないと lazygit は起動しない。**

- Homebrew 版は git を依存に持たないので、RPM の git か `brew install git` のどちらかが要る

git 管理下でないディレクトリで起動すると `Would you like to create a new repository?` と聞かれる。意図せず `.git` を作らないよう、リポジトリのルートで起動する。

### lazygit の設定を更新する / 手順 2: 補足: force push と分岐点

- 持ち主が `custom` を新しい `main` の上へ載せ直すと、古い `custom` からは fast-forward で移れない。`git pull --ff-only` は `fatal: Not possible to fast-forward, aborting.` で止まる
- `git pull --rebase --autostash` は、fetch 前の `origin/custom` と、その reflog から分岐点（fork point）を求める
- 古い `custom` のコミットを重ねず、この clone だけのコミットを新しい `custom` の上に載せる
- clone 直後には `origin/custom` の reflog が無い。最初の fetch が作る reflog の行は、古い `custom` の位置も持つ。lazygit の自動の fetch などで先に取得していても、その reflog が残っていれば分岐点が分かる
- `--rebase --autostash` を明示するので、global の `pull.rebase`・`rebase.autoStash` の設定には頼らない

### lazygit の設定を更新する / 手順 3: 補足: 分岐点が分からないときの載せ直し

- 先に fetch 済みで、`origin/custom` の reflog も期限切れなどで無いと、古い `custom` のコミットを全部載せ直そうとする
- 最初のコミットで衝突すると `Could not apply` で止まり、`status` の 1 行目が `## HEAD (no branch)` になる。2 行目からは、止まったコミットの `UU` の行が出る（手順 4 の autostash の衝突とは別のもので、手順 4 には進まない）
- `rebase --abort` は rebase を始める前に戻し、autostash があれば手元の変更も戻す。その後の `rebase --autostash --onto origin/custom HEAD` は、載せ直すコミットが無いので、新しい `custom` に移るだけになる
- この方法では、この clone だけのコミットは新しい `custom` に載らない。前の位置は HEAD の reflog に残る
- `git reset --keep origin/custom` は、手元の変更のあるファイルを新しい `custom` も変えていると、`Entry '<ファイル>' not uptodate. Cannot merge.` で止まり、何も変えない
- `--onto` なら autostash の衝突も、[lazygit の設定を更新する](../almalinux-setup.md#lazygit-の設定を更新する)の手順 4 と同じ方法で扱える

### lazygit の設定を更新する / 手順 4: 補足: autostash の衝突と reset の範囲

- git 2.52.0 は、autostash を戻すときに衝突すると `Applying autostash resulted in conflicts.`・`Your changes are safe in the stash.` と出す。rebase 自体は終わり、終了コードは 0 になる
- 文言は git の版で違う。成功のメッセージや終了コードだけでは判定せず、`status` の 1 行目が `## custom...origin/custom` で、2 行目から `UU` の行があるかで見分ける。手元の変更は `stash@{0}: autostash` に残る
- この状態で使う `reset -q --hard` は、移動先を指定せず、作業ツリー全体を現在の HEAD（新しい `custom`）に戻す。ぶつからなかったファイルの手元の変更も作業ツリーから消えるが、autostash の stash にすべて残り、`stash show -p` で出る
- 最初から `git reset --hard origin/custom` で合わせる方法は採らない。stash に入っていない未コミットの変更が消え、この clone だけのコミットも新しい `custom` に載らない

### lazygit の設定を更新する / 手順 5: 補足: 版の表示と pager

- `origin/main` の最後のコミットの題は、上流の既定設定を取り込んだ版を示す。本体の `--version` の `version=` と比べる
- `git log` は設定済みの pager（delta）を通るので、`--no-pager` を付ける。`status` は pager を使わない

### excel-diff を導入・更新する / 手順 2: 補足: スクリプトを更新した後に導入し直す理由

- Excel の変換スクリプトの写しは、中身などから決まる名前で Git の設定に書かれる。`scripts/excel-textconv.py` を変える更新を取り込むと、前の設定では確認が失敗する
- [excel-diff を導入・更新する](../almalinux-setup.md#excel-diff-を導入更新する)の手順 2 の導入・確認を通し直すと、新しい変換スクリプトの名前で設定される

### yazi / 手順 1: 補足: 変数について

- `YAZI_EXTRAS` に並べているのは、yazi が外部コマンドとして呼ぶツール。役割は手順 2 の補足にまとめた
- `ffmpeg-full` と `imagemagick-full` は、Homebrew の `ffmpeg` / `imagemagick` に対してコーデック・フォーマットを広く有効にしたビルド（どちらも `homebrew/core` の formula）
- 既定は、プレビュー・検索用のツールを一緒に入れる想定になっている

### yazi / 手順 2: 補足: 一緒に入る python3 と curl

- 既定の `YAZI_EXTRAS` では、依存として Homebrew の `python3`（2026-10-11 は `python@3.15`）と `curl` も入る
- 共通の bash 設定が Homebrew のディレクトリを PATH の先頭に置くので、端末では、どちらも `/usr/bin` のものより先に見つかるようになる（2026-10-11 の 3 つの VM で、この後の `command -v curl` は `/home/linuxbrew/.linuxbrew/bin/curl` を返した）
- 日本語入力（IBus）を OS の `python3` で動かす設定は、「Homebrew」の手順 4

### yazi / 手順 2: 補足: ボトルと、依存ツールの役割

[この節の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#yazi-実施手順--手順-2-補足-ボトルと依存ツールの役割)

- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない

### yazi / 手順 4: 補足: y 関数

- `y` は yazi を閉じたディレクトリへ移る。空白や日本語を含むパスも扱い、同じ場所なら移動し直さない

### yazi / 手順 5: 補足: ya と y

- `ya` は付属のプラグイン管理コマンド
- ブロックの最後の `y` で起動して確認する
- `y` で起動したときは、終了時にそのディレクトリへ移動する

### yazi の設定を更新する / 手順 2: 補足: force push と分岐点

- `--ff-only` を使わない理由、fork point と reflog、`--rebase --autostash` を明示する理由は、[lazygit の設定を更新する / 手順 2 の補足](#lazygit-の設定を更新する--手順-2-補足-force-push-と分岐点)と同じ
- pull は新しい上流のタグも取得する。設定の元にした上流の版は、[yazi の設定を更新する](../almalinux-setup.md#yazi-の設定を更新する)の手順 5 の `describe --tags --abbrev=0` で確かめる

### yazi の設定を更新する / 手順 3: 補足: 分岐点が分からないときの載せ直し

- rebase が止まる条件と、`--onto origin/custom HEAD` でこの clone だけのコミットを載せない理由は、[lazygit の設定を更新する / 手順 3 の補足](#lazygit-の設定を更新する--手順-3-補足-分岐点が分からないときの載せ直し)と同じ

### yazi の設定を更新する / 手順 4: 補足: autostash の衝突と reset の範囲

- git 2.52.0 の文言、衝突しても終了コードが 0 になること、`UU` の行で判定する理由と、一律に `reset --hard origin/custom` を使わない理由は、[lazygit の設定を更新する / 手順 4 の補足](#lazygit-の設定を更新する--手順-4-補足-autostash-の衝突と-reset-の範囲)と同じ

### Firefox / 手順 1: 補足: 扱う範囲

- ESR / Beta の導入・確認は本書では扱わない
- 手順 1 のブロックは、最後の行で値を読み戻す

### Firefox / 手順 3: 補足: 期限切れの副鍵の warning

- `rpm --import` が出す期限切れの副鍵についての warning は、署名に使う副鍵が別にあるので問題ない

### Firefox / 手順 4: 補足: priority は保険

[この節の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#firefox-実施手順--手順-4-補足-priority-は保険)

Mozilla の案内する repo ファイルには `priority` が無い。`priority=10`（数字が小さいほど優先）は、将来のリポジトリ間の優先順位に備えて足している。

将来 AppStream 側の ESR が Mozilla 側の版を追い越す状況（Mozilla 側でリリースが巻き戻る、ESR が別番号体系になる、など）に備えた保険として残している。

`repo_gpgcheck=0` は Mozilla の案内どおりで、**パッケージの署名は検証する（`gpgcheck=1`）がリポジトリメタデータには署名が無い**、という意味。

このリポジトリは `baseurl` に `$basearch` を含まない**全アーキテクチャ共通**の作りなので、`dnf list` には `firefox.x86_64` の行も出る。インストールされるのは実行中のアーキテクチャのものだけ。

### Firefox / 手順 11: 補足: 起動し直す理由

- 起動中の Firefox は FFmpeg を読み直さない

### SSH を公開鍵だけにする / 手順 1: 補足: restorecon

- `restorecon` は、`~/.ssh` の SELinux のラベルを、sshd が読めるものに合わせる

### Wake on LAN を使う / 手順 2: 補足: Wake-on の値

- `Wake-on:` の `g` がマジック パケット
- VirtualBox の VM の e1000 は、`Supports Wake-on: umbg` でも `d` のままだった

### 再起動と確認 / 手順 1: 補足: 再起動で効くもの

- 「システムの設定」の手順 7 の kdump のメモリー（外したとき）、「日本語入力」の手順 2 で入れた ibus-anthy（入れたとき）、「GNOME の表示と入力」の手順 10 の拡大率、同じ項の手順 12 のトレイアイコン、「Flatpak と Flathub」の手順 4 の Flatseal のメニュー

### Claude Code / 手順 1: 補足: 変数について

- `CC_CHANNEL` は `baseurl` の末尾に埋まるだけ。入れた後でチャンネルを変えるときは、[stable チャンネルに切り替える（任意）](../ai-agents.md#almalinux-10-で-claude-code-を-stable-チャンネルに切り替える任意)の手順で repo ファイルを書き換える（`stable` へ移るときは版が下がるので、`upgrade` ではなく `distro-sync` を使う）
- ネイティブインストーラ版にある `autoUpdatesChannel` / `minimumVersion` の設定は dnf 版では効かない（更新を行うのが dnf のため）

### Codex CLI / 手順 3: 補足: インストーラーが置くもの

- Node.js・npm・Homebrew は不要。CPU に合う公式の配布物を取り、SHA-256 と導入後の版を確認する
- `~/.local/bin/codex` と `~/.local/bin/codex-code-mode-host` にリンクを置き、配布物は `~/.codex/packages/standalone/` に保存する
- `~/.local/bin` が PATH に無い場合、bash では `~/.bashrc` に `# >>> Codex installer >>>` から `# <<< Codex installer <<<` までのブロックを足す
- 自分用の [bash の設定](https://github.com/ryo-aoki-pc/bash)を入れたホストでも、追加の設定を手書きする必要は無い

### Codex CLI / 手順 3: 補足: パッケージマネージャーで入れない理由

- 配布はある: Homebrew の cask `codex`（Linux でも入る）、scoop の main の `codex`、WinGet の `OpenAI.Codex`
- どれも、そのパッケージマネージャーのコマンド（`brew upgrade --cask codex`・`scoop update codex`・`winget upgrade`）を打たないと上がらない
- Homebrew の cask で入れた Codex（AlmaLinux 10）では、`codex update` が `Could not detect the Codex installation method.` で止まった（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#codex-cli-付録-起動したときの更新とパッケージマネージャー2026-10-09)）
- standalone のインストーラーで入れたものは、起動したときの知らせから Enter 1 回で上がる（[更新: 補足](#更新-補足-codex-cli-の起動したときの知らせ)）。利用者の希望（自動で最新になるなら公式の方法でよい）に近いので、こちらを採る

### Codex CLI / 手順 3: 補足: Start Codex now? に n と答える理由

- `Start Codex now?` に `n` と答えるのは、同じ節の手順 8 で起動するため

### Codex CLI / 手順 4: 補足: 版

- 検証時の版は `0.160.0`

### Grok Build / 手順 1: 補足: 名前がぶつかるもの

- インストーラーは `~/.grok/bin` に `grok` と `agent` の 2 つのリンクを置く（中身は同じ）
- `~/.local/bin` が PATH にあって `~/.grok/bin` が無いときは、`~/.local/bin/grok`・`~/.local/bin/agent` にもリンクを置く。`ln -sf` なので、同じ名前のファイルがあっても置き換える
- Cursor の CLI も `agent` の名前を使う。両方を使うなら、PATH の順でどちらが動くかを確かめる

### Grok Build / 手順 2: 補足: インストーラーが置くものと `~/.bashrc`

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
- setup-notes では `~/.bashrc` への追記を [ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash) に集めているが、このブロックはインストーラーが毎回書くので、手順書では消さずに残す（Codex CLI のインストーラーが足すブロックと同じ扱い）
  - 共通の bash 設定より後ろで読まれるので、`~/.grok/bin` が PATH の先頭に来る
- インストーラー（`install.sh`）は、配布物のハッシュや署名を確かめない（Windows の `install.ps1` が同梱の Git の zip の SHA-256 を確かめるだけ）

### Grok Build / 手順 3: 補足: 版と PATH

- 検証時の版は `1.0.50`
- 新しく開いた端末で `grok` が通るのは、`~/.bashrc` のブロックが PATH を通すため

### Grok Build / 手順 4〜6: 補足: ログインの流れ

- `grok login` は SpaceXAI の OAuth（`auth.x.ai`）でログインする。ブラウザが開けないときは、`https://accounts.x.ai/oauth2/device?user_code=…` の URL と確認用のコードを出して待つ（`--device-auth` と同じ画面）
- ログインの情報は `~/.grok/auth.json`（Unix では `0600`）に入り、自動で更新される。更新できなくなると、もう一度ログインを求められる（公式の文書 02-authentication）
- `grok models` は、ログインしていなくても終了コード 0 で、`You are not authenticated.` と既定のモデルの一覧を出す（1.0.50）。Claude Code のプラグインの `/grok-build:check` も、この終了コードだけで「ログイン済み」と判定する（[コーディングエージェントの共同作業 の注意点](../extra/coding-agents.md#注意点)）

### Grok Build / 手順 6: 補足: 検証時のモデルの一覧

- ログインしていなくても出るモデルの一覧は、検証時は `grok-4.6` と `grok-4.5`

### Grok Build / 手順 7: 補足: フォルダーの信頼

- Grok は、信頼したフォルダーでだけ、起動のときにプロジェクトの指示書（AGENTS.md・CLAUDE.md など）・skills・MCP サーバー・hooks を読む
- 信頼は `~/.grok/trusted_folders.toml` に残る。対話の画面で答えるか、`--trust` を付けて起動すると記録される
- 信頼はそのリポジトリの下のディレクトリにも効く。入れ子の別の git のチェックアウトや、別の場所の worktree は、別に信頼する

### Grok Build / 手順 7: 補足: Linux の sandbox を起動できないとき

- Linux のファイルアクセス制限には Landlock が要る。カーネルの版が 5.13 以降でも、`CONFIG_SECURITY_LANDLOCK=y` で組み込まれ、起動中のカーネルで有効になっている必要がある。`/sys/kernel/security/lsm` に `landlock` があることを確かめる
- bubblewrap は、拒否するパスの遮蔽などに使う。bubblewrap があることだけでは `read-only` の書き込み制限が効くと判断しない
- `runtime-socket deny path /run/podman/podman.sock` の `Permission denied (os error 13)` は、ソケット本体に限らず、親ディレクトリを検索できないときも出る。Podman が停止し、ソケットが存在しなくても、親の検索権限が無ければ失敗する。親ディレクトリの検索権限を確かめ、ソケット本体の権限は緩めない
- `read-only` は起動時に `/run/docker.sock` と `/run/podman/podman.sock` を調べるが、`workspace` は調べない。`workspace` が `could not apply the 'workspace' sandbox profile` で止まるときは、ソケットの親ではなく Landlock の側を確かめる（Grok 1.0.50 の起動時のシステムコールを実機で追った。[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#grok-build-sandbox-の再起動なしの追加検証)）
- 親の検索権限を直した後も、カーネルの保護を適用できず起動を拒否する場合がある。Landlock が有効なカーネルで OS を起動してから、同じ sandbox を再試行する。Grok 1.0.50 の実機で確認した 2 つの原因と、対処の準備結果は[追加の調査記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#grok-build-sandbox-の追加原因調査と対処の準備)にある。今回の実機ではユーザーの指示により対処を適用せず、調査と準備までで終了した

### Grok Build / 手順 7: 補足: 会話のデータの扱い

- `/privacy` は、設定の Coding data, retention, and training を開き、Opt in / Opt out を選ぶ（公式の文書 04-slash-commands）
- 2026-07 に、ベータ版の `grok` がディレクトリの中身を xAI のクラウドのストレージに送ることがあったと報告された（Simon Willison のブログ、2026-07-15。二次情報）
  - 同じ記事が引く xAI の発表は「2026-07-12 から、すべての Grok Build の利用者で既定の保存を止めた」「それまでに送られたデータは削除する」としている
  - その後、ソースコードが Apache-2.0 で公開された（github.com/xai-org/grok-build）
- 秘密情報のあるディレクトリで `grok` を起動しない。sandbox（`--sandbox read-only` など。Linux と macOS だけ。Linux では有効な Landlock と bubblewrap が要る）で書き込める場所を絞れる

### AlmaLinux 10 で Claude Code を stable チャンネルに切り替える（任意） / 手順 3: 補足: 以後の更新

- 以後の `sudo dnf upgrade claude-code`（[AlmaLinux 10 の更新](../ai-agents.md#almalinux-10-の更新)）は `stable` の版を追う

### 更新: 補足: Git の dnf upgrade

- 通常の `sudo dnf upgrade` にも含まれる

### 更新: 補足: Firefox の RPM 版の更新

- Firefox 内蔵の自動更新機能は RPM 版では無効で（`/usr/lib/firefox` に一般ユーザーの書き込み権が無い）、更新は dnf 側で行う
- 本体だけ上げて言語パックを取り残すと UI が英語に戻るので、両方まとめて上げる

### 更新: 補足: dnf 版の Claude Code が自分で更新できない理由

[AI コーディングエージェントのセットアップの「AlmaLinux 10 の更新」](../ai-agents.md#almalinux-10-の更新)の補足。

- dnf 版の更新には root 権限が要るため、起動中の Claude Code は自分で更新できない

### 更新: 補足: Codex CLI の起動したときの知らせ

[AI コーディングエージェントのセットアップの「AlmaLinux 10 の更新」](../ai-agents.md#almalinux-10-の更新)の補足。

- 端末の Codex は、起動したときに、最新の版を GitHub（`api.github.com/repos/openai/codex/releases/latest`）に問い合わせ、`~/.codex/version.json` に控える。控えが無いか古いときだけ問い合わせる
- 控えた版が今の版より新しいと、起動の画面に `Update available!` を出す。`1. Update now` は、入れ方に合う更新のコマンドを動かす
- standalone のインストーラーで入れたものでは、`sh -c 'curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh'` を動かす
- Windows 用の `install.ps1` を使う同じ形のコマンドも、配布物の中にある
- `codex update` も、同じインストーラーを動かす

### 更新: 補足: Grok Build の自動の更新の仕組み

[AI コーディングエージェントのセットアップの「AlmaLinux 10 の更新」](../ai-agents.md#almalinux-10-の更新)の補足。

- 設定の `[cli] auto_update`（既定は有効）で、対話の画面の起動のときに新しい版を確かめる。環境変数 `GROK_DISABLE_AUTOUPDATER` でも止められる（同梱の文書 05-configuration・26-config-reference）
- 確かめた時刻は `~/.grok/version.json` の `checked_at` に残り、間もないうちは確かめない
- 新しい版は `~/.grok/downloads/grok-<版>-<OS>-<CPU>` に入り、`~/.grok/bin` の `grok`・`agent` のリンクが付け替わる。前の配布物は残る
- 更新の入れ方は、設定の `[cli] installer`（公式のインストーラーは `internal` を書く）で選ばれる（同梱の文書 26-config-reference）
- 確かめた範囲は[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#grok-build-付録-自動の更新とパッケージマネージャー2026-10-09)

### 更新 / 手順 2: 補足: もう一度実行したとき

[AI コーディングエージェントのセットアップの「AlmaLinux 10 の更新」](../ai-agents.md#almalinux-10-の更新)の補足。

- 公式インストーラーをもう一度実行すると、新しい配布物を導入する

### 更新 / 手順 4: 補足: 古い版の配布物

[AI コーディングエージェントのセットアップの「AlmaLinux 10 の更新」](../ai-agents.md#almalinux-10-の更新)の補足。

- 古い版の配布物は `~/.grok/downloads` に残ることがある。使っている量は `grok du` で見る

### 共通の bash 設定・Homebrew・Flatpak を上げる / 手順 2: 補足: 自動更新

- `brew install` / `brew upgrade` は既定で自動更新が走るので、普段は `brew update` を明示しなくてよい（抑えるには `HOMEBREW_NO_AUTO_UPDATE=1`）

### 共通の bash 設定・Homebrew・Flatpak を上げる / 手順 2: 補足: 先に確認する

- `brew outdated` で先に確認できる

### 共通の bash 設定・Homebrew・Flatpak を上げる / 手順 3: 補足: 確認と、上げた後の tmux・fzf・zoxide

- `[y/n]` を聞く条件は[注意点](../extra/almalinux-setup.md#注意点)
- 動いている tmux のサーバーは、前の版のまま動き続ける。新しい版を使うのは、セッションを全部閉じて `tmux ls` が `no server running on …` になってから
- fzf は、開いているシェルには前の版の `fzf --bash` が読まれたまま。新しい端末から新しい版になる。zoxide のデータベース（`~/.local/share/zoxide/db.zo`）は更新で消えない

### 選択した方針

- **sudo をパスワード無しにする（「ログインと sudo」の手順 3）**: このリポジトリの手順書は、`sudo` の後ろに続く行がパスワードの入力に食われないように、NOPASSWD を前提に書いてある（README の記法）。最初に設定する
  - `/etc/sudoers.d/nopasswd` に、このユーザーだけの 2 行を置く。`/etc/sudoers` の `%wheel ALL=(ALL) ALL` は残す
  - `Defaults:<USER> verifypw=any` も置く。`sudo -v`（`-v` は資格を更新するだけ）は、`verifypw` の既定の `all` では、そのユーザーに当たるすべての行が NOPASSWD のときだけパスワードを聞かない。`%wheel` の行が残るので、`verifypw=any` が無いと Homebrew のインストーラの `sudo -v` がパスワードを聞いた（sudoers(5) の `verifypw`）
  - 書く前に `visudo -cf -` で確かめ、`install -m 0440` で置き、最後に `visudo -c` で全体を確かめる（書式の誤りがあると `sudo` そのものが使えなくなるため）
- **ファームウェアは fwupd（「OS とファームウェアの更新」の手順 2・3）**: Workstation に入っている `fwupdmgr` で、LVFS から入れる。AlmaLinux 10 の既定では LVFS のリモートが無効で、`refresh` が有効にするかを聞く
  - `--assume-yes` を付けても、この問いは出た。問いに答えるため、`refresh` と `update` は別の手順にする
- **journal を永続にする（「システムの設定」の手順 5）**: `/etc/systemd/journald.conf.d/` のドロップインで `Storage=persistent` にする（`/etc/systemd/journald.conf` は書き換えない）
  - journald が作った `/var/log/journal` には、`systemd-journal` のグループと ACL が付かなかった。`systemd-tmpfiles --create --prefix /var/log/journal` で、パッケージの tmpfiles の定義どおりに付け直す
  - tmpfiles の定義（`/usr/lib/tmpfiles.d/systemd.conf` の `z`・`a+`）は、すでにあるものだけを直す。`/var/log/journal` は `journalctl --flush` のときに作られるので、tmpfiles はその後に行う（前に行うと、何も直らなかった）
- **kdump を止める（「システムの設定」の手順 6・7）**: カーネルが落ちたときの記録が要らない PC では、予約されるメモリー（`crashkernel=`）を空ける
  - `/etc/kdump.conf` の `auto_reset_crashkernel` を `no` にする。`yes` のままだと、カーネルを入れたときに kernel-install の `92-crashkernel.install` が `crashkernel=` を付け直す
  - `crashkernel=` は `grubby --update-kernel=ALL --remove-args=crashkernel` で、入っているすべてのカーネルの起動の項目から外す
- **PackageKit-command-not-found を外す（「システムの設定」の手順 8）**: 無いコマンドを打つたびにリポジトリを探して待たされるため。パッケージは `dnf provides` で探す
- **ホームのフォルダーの名前を英語にする（「GNOME の表示と入力」の手順 2）**: 端末で打ちやすく、Homebrew・WezTerm などの既定の場所と合わせるため
  - `xdg-user-dirs-update --force` は空のフォルダーを作り直すだけで、中身を移さない。中身を残すために、フォルダーを `mv` してから `xdg-user-dirs-update --set` で場所を書き換える
  - Files のサイドバーのブックマーク（`~/.config/gtk-3.0/bookmarks`）も、日本語の名前の URI のままになるので書き換える
  - `~/.config/user-dirs.locale` を今のロケールに合わせる。xdg-user-dirs-gtk は、このファイルのロケールが今のロケールと違うときに、ログインで「標準フォルダーの名前を現在の言語に合わせて更新しますか?」の窓を出す（xdg-user-dirs-gtk のソース）
- **GNOME の設定は `gsettings` の読み戻しで確かめる**: `gsettings` は書けなかったときも終了コード 0 で終わる。`/usr/bin/gsettings` で呼ぶ（Homebrew の glib の `gsettings` は dconf に書かない。[画面オフ・ロック・サスペンドの記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#画面オフロックサスペンド-実施手順--手順-2-補足-変える前の値0-にしても暗くなる理由設定アプリの項目)）
  - 一覧の値（`xkb-options`・`experimental-features`・`custom-keybindings`）は、まるごと置き換えず、無ければ足す。ほかの設定で入っている値を消さないため
- **Caps Lock を Ctrl に（「GNOME の表示と入力」の手順 4）**: XKB の `ctrl:nocaps`（xkeyboard-config の説明は「Caps Lock as Ctrl」）を `xkb-options` に足す。Caps Lock の働きは無くなる。自分のセッションの設定なので、ログイン画面と仮想コンソールは変わらない
- **拡大率（「GNOME の表示と入力」の手順 10）**: GNOME の設定に 125%・150% などの拡大率を出すのは、mutter の実験的な機能 `scale-monitor-framebuffer`。`xwayland-native-scaling` は、X11 のアプリをぼやけさせずに拡大する（mutter 49 の gschema の説明）。AlmaLinux 10.2 の mutter 49.4 の既定は `[]`
- **トレイアイコン（「GNOME の表示と入力」の手順 11・12）**: EPEL の `gnome-shell-extension-appindicator`（AppIndicator と KStatusNotifierItem を扱う）。AppStream の `gnome-shell-extension-status-icons` は、旧来の XEmbed のトレイアイコンだけを扱い、今のアプリが使う AppIndicator / KStatusNotifierItem を出さない
- **Ctrl+Alt+T（「GNOME の表示と入力」の手順 13）**: GNOME 49 の media-keys には端末を開くキーが無いので、カスタムのショートカットにする。コマンドは、新しい窓を開く `ptyxis --new-window`
- **SSH を公開鍵だけにする**: ドロップインのファイル名を `40-pubkey-only.conf` にする。sshd は最初に読んだ値を使い、Workstation の `50-redhat.conf` より前に読ませるため
- **dnf-automatic**: `dnf-automatic-install.timer` で、毎日更新を入れる（再起動はしない）。GNOME Software の自動の更新（`download-updates`）は切る。2 つの仕組みが同じ更新を落とし合わないようにするため
- **Wake on LAN**: NetworkManager の接続の `802-3-ethernet.wake-on-lan` に `magic` を入れる。`ethtool -s` で変えた値は再起動で消えるが、接続の設定は接続を上げるたびに入る

#### EPEL と RPM Fusion

- **署名を確かめて入れる**: Configuration の `--nogpgcheck` の例は使わず、keys ページの方法（鍵を先に取り込み、`localpkg_gpgcheck=1`）にした（「EPEL と RPM Fusion」の手順 4 の補足）
- **free だけ**: 本書を使う [Firefox の AAC・H.264](../almalinux-setup.md#firefox) は、free の `ffmpeg-libs` で足りる。nonfree は有効にしない
- **EPEL を前提にする**: `rpmfusion-free-release` が `epel-release` を要求し、RPM Fusion の Configuration も EPEL を先に有効にする順で書いている（「EPEL と RPM Fusion」の手順 4 の補足）

#### Homebrew

**Homebrew に揃える判断の実質は「更新の一元化」**。`brew upgrade` 1 本で、Homebrew から入れたものがまとめて上がる。

#### Git

| 経路 | 状況 | 採否 |
|---|---|---|
| **winget の `Git.Git` を `--scope machine` で** | 上流のインストーラを、winget が sha256 を確かめてから黙って動かす。`C:\Program Files\Git` に入り、`winget upgrade` で上がる。管理者の権限が要る | **採用** |
| winget の `--scope user` | 同じインストーラで、winget はスコープのスイッチを渡さない。入る先はインストーラが権限で決める | 不採用（PC 全体に入れるので、winget にも `machine` を指定する） |
| 上流のインストーラを落として、画面で入れる | 選択を画面で選べる。版の確認と更新は手作業 | 不採用 |
| scoop の `main/git` | Git for Windows の持ち運び版（PortableGit）を `~\scoop\apps\git` に入れ、`git` などを `~\scoop\shims` に置く。`C:\Program Files\Git\bin\bash.exe` が無い | 不採用（[Windows の OpenSSH サーバー](../windows-setup.md#ssh-の既定のシェルを-git-bash-にする)が `C:\Program Files\Git` を前提にしている。[Windows 11 の初期設定](../windows-setup.md)も、scoop の git を使わない） |

- **インストーラの選択は既定のまま**（winget の `--custom` や `--override` で `/o:` を渡さない）
  - 本書は `system` を変えず `global` で上書きするので、`system` の `core.autocrlf=true`・`pull.rebase=false`・`init.defaultBranch=master` は既定のままでよい（[実施手順](../almalinux-setup.md#git)の手順 6 で確かめる）
  - 既定の PATH の選択（`cmd` だけを足す）で、PowerShell・scoop・Claude Code から `git` が見つかる。Unix の道具まで足す選択は、Windows の `find`・`sort` を隠す（インストーラの画面の警告）
  - `--override` は、winget が渡す黙って動かすスイッチ（`/SP- /SILENT …`）ごと置き換える（winget のソース）
- **Git for Windows は、scoop の `scoop update` が使う git も兼ねる**
  - scoop は、scoop の git が入っていなければ `PATH` の `git` を使う（[Windows 11 で Git for Windows を入れる](../windows-setup.md#git-for-windows)の手順 3 の補足）

#### git-delta

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `git-delta 0.19.2` の `arm64_linux` ボトルがある。upstream の最新と一致。formula に `delta` という別名が付いているので `brew install delta` でも入る | **採用** |
| EPEL / AppStream / CRB | **`delta` も `git-delta` も無い**（`dnf list --available delta git-delta` → `Error: No matching Packages to list`）。※ `delta` という名前の無関係なパッケージも無い | 使えない |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-gnu` の tar と `.rpm` が置いてある。rpm を直接入れると dnf のリポジトリ管理外になり更新が手作業になる | 不採用（Homebrew に揃える） |
| `cargo install git-delta` | Rust toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |
| diff-so-fancy / difftastic | 別物（difftastic は EPEL に `0.67.0` がある）。構文木で比較する difftastic とは用途が違うので、置き換えではなく併用できる | 対象外 |

#### GitHub CLI

- 両方が有効なら、dnf はバージョンの高い `gh-cli` 側を選ぶ
- `armv6hl` や `i386` の行が見えるのは、このリポジトリが `baseurl` にアーキテクチャを含まない**全アーキテクチャ共通**の作りだから（Mozilla のリポジトリと同じ）

#### lazygit

- `atim/lazygit` でも同じ 403
- dnf を介さず `curl -L` で `repomd.xml` を取っても同じ。COPR の配信元（`download.copr.fedorainfracloud.org`）が S3 の署名付き URL にリダイレクトし、その署名が期限切れになっている
- 一方で COPR 全体が落ちているわけではない。同じ日に `lihaohong/yazi` の `epel-10-aarch64` はメタデータを取得できている（[yazi](../almalinux-setup.md#yazi)）
- **プロジェクトごとの問題で、いずれ直る可能性がある**

#### Firefox

[この節の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#firefox-選択した方針)

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

#### Claude Code

[この節の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#claude-code-選択した方針)

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
- リポジトリが別 URL になっているだけで、切り替えは `baseurl` の書き換え（[stable チャンネルに切り替える（任意）](../ai-agents.md#almalinux-10-で-claude-code-を-stable-チャンネルに切り替える任意)）

**既定を `latest` にした理由**:

- 本書の目的が最新版を入れることだから。`stable` のままだと 1 週間ほど遅れる
- ネイティブインストーラ（`install.sh` が取ってくる `bootstrap.sh`）も、まず `claude-code-releases/latest` が指す版を取ってくる
- 不具合に当たったときの逃げ道として、`stable` へ下げる節を用意した

- **インストーラは `& ([scriptblock]::Create(...)) <チャンネル>` の形で動かす**: 公式の文書がチャンネルを選ぶときに使う形。既定の `irm … | iex` は、インストーラの設定（`Set-StrictMode` など）を、入れた後の PowerShell に残す（[Windows 11 で使う](../ai-agents.md#windows-11-で-claude-code-を入れる)の手順 3 の補足）
- **`PATH` は本書で足す**: インストーラも `claude install` も足さず、足し方を出すだけなので、公式の文書の Verify your PATH と同じ書き方で、自分のユーザーの PATH に足す（同じ項の手順 4）
- **署名は入れた後に確かめる**: インストーラは sha256 しか照らさないので、公式の文書の `Get-AuthenticodeSignature` で `claude.exe` の署名を見る（同じ項の手順 6）。インストーラの中で動く前の確かめにはならない
- **Git for Windows を前提にした**: 公式の文書では任意だが、Claude Code の Bash のツール（と Monitor のツール）が Git Bash を使う。[Windows 11 の初期設定](../windows-setup.md)のリードの順で、先に入れる

#### Grok Build

- xAI の公式のインストーラー（`https://x.ai/cli/install.sh`・`install.ps1`）を使う
  - 公式のインストーラーで入れた Grok は、対話の画面の起動のときに、自分で新しい版に上がる（[更新: 自動の更新の仕組み](#更新-補足-grok-build-の自動の更新の仕組み)）。利用者の希望（自動で最新になるなら公式の方法でよい）に合う
  - Node.js を増やさず、両 OS で同じ配布元・同じ `grok update` で上げられる
- パッケージマネージャーでは入れない
  - 配布はある: Homebrew の cask `grok-build`（Linux でも入る）、WinGet の `xAI.GrokBuild`（portable）、npm の `@xai-official/grok`。scoop の main と extras には無い（2026-10-09）
  - Homebrew と WinGet の版は、`brew upgrade --cask grok-build`・`winget upgrade` を打たないと上がらない
  - npm の版は Node.js が要る
  - Homebrew の cask で入れた Grok でも、`grok update` は Homebrew を使わずに Grok 自身で入れる
  - `grok update --force-reinstall` を打つと、Homebrew の外（`~/.grok/bin`・`~/.grok/downloads`）に別の Grok が入り、Homebrew の版はそのままだった（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#grok-build-homebrew-の-cask)）
  - Homebrew で使うなら、自動の更新を止め（`[cli] auto_update = false`）、`brew upgrade --cask grok-build` で上げる形になる
  - WinGet で入れた Grok では、`grok update` は WinGet のコマンドを出すだけで何も変えない
  - Homebrew の formula の `grok`（`brew install grok`）は Grok Build ではない（正規表現でログを読む別のツール）
- ログインは grok.com のアカウント（ブラウザ）で行う
  - API キー（`XAI_API_KEY`）は、ログインが無いときだけ使われ、API の従量課金になる
  - 利用者の契約がサブスクリプション（SuperGrok / X Premium）なので、API キーの手順は置かない
- 非公式の grok-cli（superagent-ai の `grok-dev`）は採らない。同じ `grok` の名前と `~/.grok` を使い、2026-05 から更新が止まっている（調査時）
- 確認用のディレクトリでの起動は [Codex CLI](../ai-agents.md#codex-cli) と同じ形にした（`~/grok-sandbox`）

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
- [Windows 11 の初期設定](../windows-setup.md) — Windows 11 側の同じ形の手順書

#### EPEL と RPM Fusion

- [EPEL — Fedora Docs](https://docs.fedoraproject.org/en-US/epel/) — EPEL とは何か。入れ方は同じ文書の [Getting Started](https://docs.fedoraproject.org/en-US/epel/getting-started/)（CRB と `epel-release`）
- `man dnf`（`remove` の `--noautoremove`）
- [導入元一覧の導入経路と EL10 での注意](../tool-catalog.md#導入経路と-el10-での注意) — EPEL とほかの導入元の比較

- [Configuration — RPM Fusion](https://rpmfusion.org/Configuration) — free / nonfree の区別と、EL 向けの有効化（EPEL を先に有効にすること、`--nogpgcheck` の例、Alma・Rocky の `crb enable`）
- [Trusting Package Integrity — RPM Fusion](https://rpmfusion.org/keys) — 鍵の fingerprint と、鍵を先に取り込んで `localpkg_gpgcheck=1` で入れる方法
- `man dnf.conf`（`localpkg_gpgcheck`）
- [EPEL](../almalinux-setup.md) — 前提の手順書

#### 日本語入力

- [Enabling Chinese, Japanese, or Korean text input — Using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/using_the_gnome_desktop_environment/customizing-the-desktop-environment) — 8.2 節。日本語は `ibus-anthy`、切り替えは Super+Space
- [ibus/ibus-anthy](https://github.com/ibus/ibus-anthy) — Anthy のエンジン
- [CentOS Stream 10 の ibus-anthy](https://gitlab.com/redhat/centos-stream/rpms/ibus-anthy) — RHEL のビルドの設定（配列 `default`、切り替えのキー）と、ひらがなで始めるパッチ

#### 画面オフ・画面ロック・自動サスペンドを止める

- [Changing system power settings — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/changing-system-power-settings) — 電源ボタン（dconf と logind）と蓋（logind）の設定
- [gnome-settings-daemon 47.2 の電源のスキーマ](https://gitlab.gnome.org/GNOME/gnome-settings-daemon/-/blob/47.2/data/org.gnome.settings-daemon.plugins.power.gschema.xml.in) — `sleep-inactive-*`・`idle-dim`・`power-button-action` の既定値と説明
- [GDM 47.0 のログイン画面の既定の設定](https://gitlab.gnome.org/GNOME/gdm/-/blob/47.0/data/dconf/defaults/00-upstream-settings) — 電源のキーが無いこと
- `man dconf`（`dconf update` とプロファイル）/ `man 5 logind.conf`（`HandleLidSwitch`）/ `man systemctl`（`mask`）

#### Git

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

#### git-delta

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
- [Windows 11 の初期設定](../windows-setup.md) — 貼り付けの設定（「貼り付けの設定」の手順 1〜5）、scoop（「アプリを入れる」の手順 2・3）、「PowerShell 7 のプロファイルを設定する」
- [WezTerm の Windows 11 で使う](../shell-terminal.md#windows-11-で-wezterm-を入れる) — VC++ ランタイム（手順 3）と、Git Bash で開く自分用の設定

#### GitHub CLI

- [ScoopInstaller/Main — gh.json](https://github.com/ScoopInstaller/Main/blob/master/bucket/gh.json) — Windows 11 の scoop の定義（版・zip と sha256・`bin\gh.exe`）
- [winget-pkgs — GitHub.cli 2.102.0](https://github.com/microsoft/winget-pkgs/blob/master/manifests/g/GitHub/cli/2.102.0/GitHub.cli.installer.yaml) — MSI（machine）と portable（採らなかった経路）
- [gh 2.102.0 の login_flow.go](https://github.com/cli/cli/blob/v2.102.0/pkg/cmd/auth/shared/login_flow.go)・[git_credential.go](https://github.com/cli/cli/blob/v2.102.0/pkg/cmd/auth/shared/git_credential.go)・[gitcredentials](https://github.com/cli/cli/tree/v2.102.0/pkg/cmd/auth/shared/gitcredentials) — ログインの問いと、Git の認証に Yes と答えたときの動き
- [gh 2.102.0 の internal/config/config.go](https://github.com/cli/cli/blob/v2.102.0/internal/config/config.go)・[status.go](https://github.com/cli/cli/blob/v2.102.0/pkg/cmd/auth/status/status.go)・[logout.go（v2.102.0）](https://github.com/cli/cli/blob/v2.102.0/pkg/cmd/auth/logout/logout.go) — トークンの置き場所、状態の表示、ログアウト
- [gh 2.102.0 の internal/ghcmd/cmd.go](https://github.com/cli/cli/blob/v2.102.0/internal/ghcmd/cmd.go) — `GH_PATH` と自分の場所、新しい版の知らせ
- [cli/go-gh v2.16.1 — pkg/config/config.go](https://github.com/cli/go-gh/blob/v2.16.1/pkg/config/config.go) — 設定・状態・データ・キャッシュの場所
- [zalando/go-keyring v0.2.8 — keyring_windows.go](https://github.com/zalando/go-keyring/blob/v0.2.8/keyring_windows.go) — 資格情報マネージャーの項目の名前
- [GitHub CLI manual — gh help environment](https://cli.github.com/manual/gh_help_environment) — `GH_CONFIG_DIR`・`GH_PATH` など
- [Windows 11 の初期設定](../windows-setup.md) — 貼り付けの設定（「貼り付けの設定」の手順 1〜5）、scoop（「アプリを入れる」の手順 2・3）、「PowerShell 7 のプロファイルを設定する」。[Git](../almalinux-setup.md#git) — Git for Windows と、その Git Credential Manager

#### lazygit

- [jesseduffield/lazygit — README](https://github.com/jesseduffield/lazygit) — 各 OS のインストール方法と機能一覧
- [lazygit Config Docs](https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md) — `config.yml` の項目（`os.edit` など）
- [AlmaLinux 10 の初期設定](../almalinux-setup.md) — 「Homebrew」の手順 1〜3 が Homebrew 本体の導入手順。`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件は参考資料、`brew` の基本操作は同書の「Homebrew の使い方の基本」
- [atim/lazygit — Copr](https://copr.fedorainfracloud.org/coprs/atim/lazygit/) / [dejan/lazygit — Copr](https://copr.fedorainfracloud.org/coprs/dejan/lazygit/) — chroot の一覧（`epel-10-aarch64` はある）
- [ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit) — 自分用の設定（`config.yml`）。導入方法と変えた項目は README にある
- [ScoopInstaller/Extras — lazygit.json](https://github.com/ScoopInstaller/Extras/blob/master/bucket/lazygit.json) — Windows 11 の scoop の定義
- [lazygit Config Docs（v0.66.0）](https://github.com/jesseduffield/lazygit/blob/v0.66.0/docs/Config.md) — Windows の設定の場所（`%LOCALAPPDATA%\lazygit\config.yml`）と `LG_CONFIG_FILE`
- [ryo-aoki-pc/lazygit — README の導入方法](../almalinux-setup.md#lazygit-の設定を導入する) — 自分用の設定の Windows の clone の例

#### yazi

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

#### Claude Code

- [Advanced setup — Claude Code Docs](https://code.claude.com/docs/en/setup) — dnf / apt / apk リポジトリの設定、チャンネル、署名の検証。Windows 11 の節は、Set up on Windows・Install a specific version（チャンネルを選ぶ形）・Update manually・Binary integrity and code signing
- [Troubleshoot installation and login — Claude Code Docs](https://code.claude.com/docs/en/troubleshoot-install) — インストールが失敗したときの切り分け。Windows 11 の節は、Verify your PATH・Check for conflicting installations・`claude.exe` missing after an update on Windows・Claude Code does not support 32-bit Windows・Git Bash を探す順
- [CLI reference — Claude Code Docs](https://code.claude.com/docs/en/cli-reference) — `claude` のオプションとサブコマンド（[使い方の基本](../ai-agents.md#claude-code-の使い方の基本)）
- [Interactive mode](https://code.claude.com/docs/en/interactive-mode) / [Commands](https://code.claude.com/docs/en/commands) — セッションの中のキーとスラッシュコマンド
- [Run Claude Code programmatically](https://code.claude.com/docs/en/headless) — `-p` と `--output-format`
- [Connect Claude Code to tools via MCP](https://code.claude.com/docs/en/mcp) — `claude mcp` とスコープ
- [Continue local sessions from any device with Remote Control](https://code.claude.com/docs/en/remote-control) — `claude remote-control`
- `man dnf.conf`（`gpgcheck`、`baseurl`）
- [Authentication — Claude Code Docs](https://code.claude.com/docs/en/authentication) — 最初の起動のログインの流れと、Windows のログインの情報の置き場所（`.credentials.json`）
- [winget-pkgs の Anthropic.ClaudeCode](https://github.com/microsoft/winget-pkgs/tree/master/manifests/a/Anthropic/ClaudeCode) / [scoop の main/claude-code](https://github.com/ScoopInstaller/Main/blob/master/bucket/claude-code.json) — Windows 11 で採らなかった経路の定義
- [about_Preference_Variables（`$OutputEncoding`）— Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-5.1) — Windows PowerShell 5.1 が native のコマンドへパイプで渡す文字コード
- [Windows 11 の初期設定](../windows-setup.md) — 同じ PC で先に行う設定（貼り付けの設定と、この文書を通す順）
- [Claude Code の Remote Control](../ai-agents.md#claude-code-の-remote-control-windows-11-で使う) — Windows 11 の節で入れた Claude Code を、SSH の切断後も Remote Control で使う

#### Codex CLI

- [OpenAI: Codex CLI](https://learn.chatgpt.com/docs/codex/cli) — 導入・起動・更新
- [公式 Linux/macOS インストーラー](https://chatgpt.com/codex/install.sh)
- [公式 Windows インストーラー](https://chatgpt.com/codex/install.ps1)
- [OpenAI: Authentication](https://learn.chatgpt.com/docs/auth) — ChatGPT・API キー・デバイスコード・資格情報の保存
- [OpenAI: Windows sandbox](https://learn.chatgpt.com/docs/windows/windows-sandbox) — Windows 11、初回の管理者承認
- [OpenAI: Config basics](https://developers.openai.com/codex/config-basic) — ユーザー設定
- [Homebrew: codex](https://formulae.brew.sh/cask/codex) — Homebrew の cask（使わなかった経路）

#### Grok Build

- [xAI: Grok Build CLI の発表](https://x.ai/news/grok-build-cli)（2026-05-25。対象は SuperGrok と X Premium+）
- [xAI: Grok Build の文書](https://docs.x.ai/build/overview) — 導入・ログイン・使い方
- 手元の文書 `~/.grok/docs/user-guide/`（1.0.50 に同梱）: 01-getting-started・02-authentication・05-configuration・12-project-rules・14-headless-mode・18-sandbox・22-permissions-and-safety・26-config-reference
- [公式の Linux / macOS のインストーラー](https://x.ai/cli/install.sh)・[公式の Windows のインストーラー](https://x.ai/cli/install.ps1)
- [xai-org/grok-build](https://github.com/xai-org/grok-build) — ソース（Apache-2.0）
- [Homebrew: grok-build](https://formulae.brew.sh/cask/grok-build) — Homebrew の cask（使わなかった経路）
- [xAI: Models](https://docs.x.ai/developers/models) — モデルと料金（API キーで使うとき）
- [Simon Willison: xai-org/grok-build, now open source](https://simonwillison.net/2026/Jul/15/grok-build/)（二次情報）

## 省略できない初期設定

必要な項だけを通す場合も、次の手順は省略しない。

- [ログインと sudo](../almalinux-setup.md#ログインと-sudo)の手順 1〜3、[OS とファームウェアの更新](../almalinux-setup.md#os-とファームウェアの更新)の手順 1・4・5
- [システムの設定](../almalinux-setup.md#システムの設定)の手順 1、[共通の bash 設定](../shell-terminal.md#共通の-bash-設定)の手順 1・2
- [Homebrew](../almalinux-setup.md#homebrew)の手順 1〜3、[シェルのツール](../shell-terminal.md#シェルのツール)の手順 1・2
- [Git](../almalinux-setup.md#git)の手順 1〜6、[Firefox](../almalinux-setup.md#firefox)の手順 1〜7（ブラウザ認証に使う）
- [HackGen Console NF](../shell-terminal.md#hackgen-console-nf)の手順 1〜5（WezTerm と等幅のフォントに使う）、[WezTerm](../shell-terminal.md#wezterm)の手順 1〜5
- [再起動と確認](../almalinux-setup.md#再起動と確認)の手順 1
