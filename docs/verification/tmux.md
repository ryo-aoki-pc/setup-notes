# tmux インストール手順（AlmaLinux 10 / Homebrew）の検証記録

[手順書](../tmux.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 操作上の注意と併記されていた記録

   - この節の手順 4 は、tmux の中で確認した作業ディレクトリの名前を Remote Control のセッション名にする

### 操作上の注意と併記されていた記録

   - 前の版のサーバーへ新しい版のクライアントからつなぐと、つなげないことがある（[手順 2](../tmux.md#実施手順) の補足の BaseOS の tmux と同じ。Homebrew の版が上がる更新は試していない）

### 実施手順: 検証状況の記録

> [!WARNING]
> **x86_64 のクリーン VM で実施手順を本実行済み**（2026-10-06）。コンテナでも検証したが、実機では本書の手順を通していない（[対象と検証環境](#対象と検証環境)）。[Claude Code を tmux の中で動かす（任意）](../tmux.md#claude-code-を-tmux-の中で動かす任意)の Remote Control の接続は、確かめていない。

### 実施手順 / 手順 2: 補足: BaseOS の tmux と並べたとき

BaseOS の `tmux-3.3a-13.20230918gitb202a2f.el10` を一緒に入れて試した（コンテナ）。

- `/usr/bin/tmux -V` は `tmux next-3.4` と出る（RPM の版は 3.3a だが、中身は 3.4 の前の git の版）
- PATH では `/home/linuxbrew/.linuxbrew/bin` が先なので、`tmux` と打つと Homebrew の 3.7c が動く。`/usr/bin/tmux` と打てば BaseOS のものが動く
- 2 つは同じソケット（`/tmp/tmux-<UID>/default`）を使う。版の違うクライアントとサーバーは、うまくつながらなかった

| サーバー（セッションを始めた方） | クライアント | 結果 |
|---|---|---|
| BaseOS（3.3a） | Homebrew（3.7c） | `tmux ls` は動くが、`tmux attach` は `open terminal failed: not a terminal` |
| Homebrew（3.7c） | BaseOS（3.3a） | `ls` も `attach` も `server exited unexpectedly`（サーバーは止まらずに残った） |

- BaseOS のサーバーのセッションを閉じるときは、`/usr/bin/tmux attach` で入って中で `exit` する（全部閉じてよければ `/usr/bin/tmux kill-server`）
- BaseOS の tmux は、`/usr/bin/tmux capture-pane -p` でサーバーごと落ちた（`server exited unexpectedly`。[podman-tui.md の付録](podman-tui.md#付録-コンテナでの検証記録2026-09-28)の実機の記録と同じ）。Homebrew の 3.7c では落ちなかった

### 使い方の基本 / 手順 0: 本文中の記録

- 表のキーとコマンドは、コンテナの tmux 3.7c で確かめた（[付録](#付録-コンテナでの検証記録2026-10-01)）

### Claude Code を tmux の中で動かす（任意）: 検証状況の記録

> [!WARNING]
> **この節の Remote Control の接続は確かめていない**。コンテナでは claude.ai にログインできず、`claude remote-control` が `You must be logged in to use Remote Control.` で終わるところまでを確かめた（`--name` と `--spawn same-dir` での接続は、[Windows の実機](windows-claude-remote-control.md#対象と検証環境)でだけ確かめてある）。Remote Control をつなぐと、この claude.ai のアカウントで入れる人が、スマートフォンやブラウザからこのホストで、このユーザーとして Claude Code を動かせる（ファイルの読み書きとコマンドの実行）。

### Claude Code を tmux の中で動かす（任意） / 手順 4: 補足: tmux の中のシェルで始める理由

- `tmux new-session -s claude claude remote-control …` のように、tmux に直接 `claude` を起動させると、`claude` が終わった時点でセッションも消える。コンテナ（未ログイン）では `[exited]` だけが出て、エラーの文が読めなかった
- tmux の中のシェルから起動すれば、`claude` が終わってもシェルとその表示が残り、`tmux attach -t claude` で理由を読める
- `--spawn same-dir` を付けないと、`Choose [1/2]`（`same-dir` か `worktree` か）を聞かれる（Windows の実機の実測）。本書は Windows の手順書と同じ `same-dir`（1 つのディレクトリを共有）にする
- 信頼のダイアログ・`Enable Remote Control?`・URL の表示は、Windows の実機の記録（[Windows の手順書](../windows-claude-remote-control.md#実施手順)の手順 4）。この手順書では見ていない
- セッション名を `claude` にしたのは、ステータス行の左端が既定で 10 文字までのため（`claude-rc` は `[claude-rc` で切れた）
- 対話の `claude` の中で `/remote-control` と打っても、そのセッションを Remote Control につなげる（公式ドキュメント。本書では試していない）

### 対象と検証環境

- **目的**: AlmaLinux 10 に [tmux](https://github.com/tmux/tmux)（端末の多重化。1 つの端末の中に複数のシェルを持ち、SSH を切ってもシェルとその中のコマンドを動かし続ける）を入れ、基本の使い方と、Claude Code を SSH の切断後も動かし続ける使い方をまとめる
- **進め方**: Homebrew で入れる。**読者が書き換える変数は無い**
- **状態**: **x86_64 のクリーン VM で実施手順 1〜5 と任意設定を本実行済み（2026-10-06）。コンテナでも検証済み（2026-10-01）**
  - 通したこと: SSH でログインした対話の bash に、この文書の bash のブロックをそのまま貼り、実施手順・任意節・[更新](../tmux.md#更新)・[ロールバック](../tmux.md#ロールバック)を、ブラケットペーストの無しと有りで 1 回ずつ通した（[付録](#付録-コンテナでの検証記録2026-10-01)）
  - 確認したこと
    - 実施手順 1〜5、[使い方の基本](../tmux.md#使い方の基本)の表のキーとコマンド、[設定ファイル（任意）](../tmux.md#設定ファイル任意)（ホイール・クリック・境界のドラッグは、マウスの信号を端末に送って確かめた）、[ロールバック](../tmux.md#ロールバック)
    - SSH のクライアントを落としても tmux のセッションとその中のコマンドが残り、ログインし直して戻れること
    - BaseOS の tmux と並べたときの挙動（[手順 2](../tmux.md#実施手順) の補足）
    - [Claude Code を tmux の中で動かす（任意）](../tmux.md#claude-code-を-tmux-の中で動かす任意)のうち、ログインしていない `claude` で通るところ（その節の手順 1〜3・5、手順 4 のエラー。手順 4 の代わりに対話の `claude` を動かして、手順 6 で SSH を切った後も残り、手順 8 で戻れること）
  - **確認していないこと**
    - 実機（aarch64 の Raspberry Pi 5 を含む）
    - Remote Control の接続と、スマートフォン・ブラウザからの操作（claude.ai のアカウントでのログインが要る）
    - 端末（WezTerm など）から送るマウスと Shift+Enter、[更新](../tmux.md#更新)で Homebrew の版が上がるとき
  - 実機の Raspberry Pi 5 では、tmux の中で `claude remote-control` を動かしている（[claude-code-gui.md の付録](claude-code-gui.md#付録-実機での検証記録2026-10-01)）。この手順書の手順どおりには通しておらず、その tmux が BaseOS と Homebrew のどちらかも確かめていない
  - 2026-10-05: 設定の読み込みを両パスに対応させ、確認用セッションの作成に失敗した場合は後続を止めた。一時ファイルとスタブで、旧パスのみ・新パスのみ・両方・作成失敗の 4 通りを確認した
  - 同日の変更で、`-A` で既存セッションへ戻る場合は作業場所と実行中コマンドを確認する説明を追加した。変更後の TUI と Remote Control は実機で実行していない

| 項目 | 検証コンテナ |
|---|---|
| 実施日 | 2026-10-01 |
| OS | AlmaLinux 10.2 (Lavender Lion)（`quay.io/almalinuxorg/10-init`。パッケージは `x86_64_v2`） |
| コンテナ | クラウドのホストの Docker 29.6.2、`--privileged`。systemd を PID 1 にし、sshd と systemd-logind を動かした |
| Homebrew | 7.0.7（`/home/linuxbrew/.linuxbrew`） |
| tmux | 3.7c（Homebrew）。比べるために BaseOS の `tmux-3.3a-13.20230918gitb202a2f.el10` も入れて消した |
| Claude Code | `claude-code-2.1.287-1`（[claude-code.md](../claude-code.md) の `latest`）。ログインしていない |
| 端末 | ホストの tmux 3.4 のペイン（160x45）から `docker exec -it` で `ssh -t` し、`TERM=xterm-256color` |

> [!NOTE]
> 出力例・ログの中の値は `<USER>` / `<HOSTNAME>` / `<UID>` / `<PID>` / `<名前>`（tmux のセッションや Remote Control のセッションの名前）/ `<PROJECT_DIR>` / `<SESSION_ID>` のプレースホルダで書いてある。Claude のアカウント、Remote Control の URL と QR コードは載せない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| tmux | 未導入（`rpm -q tmux` も `brew list tmux` も無し） |
| Homebrew | 7.0.7 導入済み。formula は無し |
| systemd-logind | `KillUserProcesses` は既定のまま（`no`） |

### 選択した方針

- **Homebrew の 3.7c にした**（[導入元一覧](../tool-catalog.md)の規則。RPM が Homebrew より古いので Homebrew）
  - BaseOS の RPM は 3.3a（中身は `next-3.4`）。`capture-pane -p` でサーバーが落ちるのを、実機（[podman-tui.md の付録](podman-tui.md#付録-コンテナでの検証記録2026-09-28)）とコンテナの両方で見た
  - Homebrew で入れると、そのままでは `sudo tmux` では見えないが、tmux は自分のユーザーで使うものなので困らない
- **screen は使わない**: AlmaLinux 10 の BaseOS・AppStream に無い（コンテナの `dnf list --available screen` は `No matching Packages`）。EPEL は調べていない
- **zellij は手順書にしない**: [導入元一覧](../tool-catalog.md#cli-定番の置き換え)の 1 行のまま。Windows では zellij のペインで Claude Code が動かなかった（[Windows の手順書の選択した方針](windows-claude-remote-control.md#選択した方針)）。Linux では試していない
- **Claude Code の Remote Control は、tmux の中のシェルから始める**: tmux に直接起動させると、終わったときに表示が残らない（[Claude Code を tmux の中で動かす（任意）](../tmux.md#claude-code-を-tmux-の中で動かす任意)の手順 4 の補足）
- **Claude Code 自身の裏で動かす機能は試していない**: `claude --help` には、セッションを裏で始める `--bg` と、それに入る `claude attach` がある。SSH の切断後も残るかは確かめていない

### 完了時点の状態

実施手順の後（セッションは残っていない）:

```
$ tmux -V
tmux 3.7c
$ command -v tmux
/home/linuxbrew/.linuxbrew/bin/tmux
$ brew list --versions tmux
tmux 3.7c
$ tmux ls
no server running on /tmp/tmux-<UID>/default
```

- 入るファイルは `/home/linuxbrew/.linuxbrew/Cellar/tmux/3.7c/` の 9 ファイル（実行ファイル・man・`example_tmux.conf` など）と依存の 5 つ
- [設定ファイル（任意）](../tmux.md#設定ファイル任意)を通すと `~/.config/tmux/tmux.conf` ができる
- tmux のソケットは `/tmp/tmux-<UID>/default`

### 操作上の注意と併記されていた記録

- **Claude Code の `Ctrl+B` は、tmux の中では 2 回押す**: Claude Code は `Ctrl+B` で動いているコマンドを裏へ回すが、tmux の中では 1 回目を tmux が取る（公式ドキュメント）。`Ctrl+b` → `Ctrl+b` で中のアプリに `Ctrl+b` が届くことは、tmux の側で確かめた（`bind-key -T prefix C-b send-prefix`）

### 付録: コンテナでの検証記録（2026-10-01）

**環境**: [対象と検証環境](#対象と検証環境)の表のとおり。コンテナには NOPASSWD の sudo を持つ一般ユーザーを作り、root から `ssh -p 2222 <USER>@127.0.0.1` でログインした（systemd-logind は、イメージで mask されていたのを外して起動した）。

**検証の準備**（本書の手順には含めない）:

- このホストの外向きの HTTPS はプロキシを通るので、プロキシの CA を `/etc/pki/ca-trust/source/anchors/` に置き、`/etc/dnf/dnf.conf` の `proxy=` と、ログインシェルの `HTTPS_PROXY` などを足した
- AlmaLinux の `mirrorlist=` を止めて、コメントの `baseurl=https://repo.almalinux.org/...` を有効にした（[claude-code.md の付録](claude-code.md#付録-latest-チャンネルの検証記録2026-09-26)と同じ）
- Homebrew は `NONINTERACTIVE=1` 付きの公式インストーラで入れた（[homebrew.md](../homebrew.md)）

**流し方**:

- ホストの tmux のペインで `docker exec -it … ssh -t` したログインシェルに、この文書の bash のブロック（折り畳みの外のもの）を抜き出して、手順ごとに `tmux paste-buffer` で書き込んだ（npm-offline.md の付録と同じ形）
- 1 回目はブラケットペースト無しで、2 回目は `paste-buffer -p`（ブラケットペースト有り。貼った後に Enter を送った）で、実施手順から[ロールバック](../tmux.md#ロールバック)まで通した。2 回の間に、1 回目で見つけたことを直した（下の表）
- 画面は `tmux capture-pane` で読み、`y`・`Ctrl+b d`・`exit` はキーとして送った
- 中の tmux の状態は、`tmux list-windows` / `list-panes` / `show -g` を同じユーザーで別に呼んで読んだ
- 表の「設定ファイル」と「Claude Code」は、[設定ファイル（任意）](../tmux.md#設定ファイル任意)と[Claude Code を tmux の中で動かす（任意）](../tmux.md#claude-code-を-tmux-の中で動かす任意)の手順

| 手順 | 結果（2 回とも同じ。違ったものは書き分けた） |
|---|---|
| 1 | `Would install 5 dependencies for tmux` の後に `[y/n]`。`y` で 6 つのボトルが入り、caveat が出た |
| 2 | `tmux 3.7c`、`/home/linuxbrew/.linuxbrew/bin/tmux`、`tmux 3.7c`、`package tmux is not installed` |
| 3 | ステータス行に `[work] 0:bash*`。`Ctrl+b d` で `[detached (from session work)]` |
| 4 | `work: 1 windows (created …)`。`attach` で戻り、`exit` で `[exited]` |
| 5 | `no server running on /tmp/tmux-<UID>/default` |
| 設定ファイル 1・2 | 4 行が出た。`mouse on`、`history-limit 50000`。設定ファイルがあるときにもう一度貼ると `中断:` が出た |
| Claude Code 1 | `2.1.287 (Claude Code)`、`tmux 3.7c`、`Not logged in. Run claude auth login to authenticate.`。直す前は `claude auth status --text` が 2 行目で、1 回目は後ろの `tmux -V` が実行されなかった（この手順の補足） |
| Claude Code 2・3・4 | `cd` の後、`[claude] 0:bash*` で、プロンプトは手順 2 のディレクトリ。`claude remote-control` は `Error: You must be logged in to use Remote Control.` で終わり、tmux の中のシェルに戻った。`exit` で `[exited]` |
| Claude Code 3・5（1 回目、もう一度） | 手順 4 の代わりに対話の `claude` を起動してデタッチした。`claude: 1 windows (created …)`。`pgrep -af 'claude remote-control'` は何も出さなかった（Remote Control は動いていない） |
| Claude Code 6・8（1 回目） | `exit` で SSH が切れた後も、tmux と `claude` のプロセスは残った。ログインし直して `tmux attach -t claude` で `claude` の画面に戻った。最初の設定の画面は `Ctrl+C` では終わらなかったので、ロールバックの手順 1 で止めた |
| 更新 | `Warning: tmux 3.7c already installed`（上がる版が無かった） |
| ロールバック | `kill-server` は何も出さないか、`no server running on …`。`brew uninstall tmux` が依存の 5 つも消し（`Autoremoving 5 unneeded formulae:`）、`openssl@3` と `ca-certificates` の設定ファイルを残したという警告が出た。直す前は `brew autoremove` も並べていたが、消すものが残っていなかった。`hash -r` の後の `command -v tmux` は何も返さなかった |

**追加の確認**（手順書の外）:

- 使い方の基本のキー: `Ctrl+b` の後の `c`・`p`・`n`・`0`・`%`・`"`・`o`・`←`・`z`（2 回）・`x`→`y`・`[`→`q` を送るたびに、ウィンドウとペインの数・大きさ・選ばれているものが表のとおりに変わった。`w`・`s`・`?` の一覧、`$`・`,` の名前の変更、`:` で打った `display-message hello` も確かめた。コピーモードの PageUp・PageDown・`q` と、プレフィックスの後の `Ctrl+b`（`send-prefix`）は `tmux list-keys` で確かめた
- 使い方の基本のコマンド: `new-session -d -s bg top -d 5`・`ls`・`kill-session -t bg`・`kill-server`。2 つ目の SSH から `new-session -A -s work` で同じセッションに入り（`tmux ls` に `(attached)`）、`attach -d -t work` で 1 つ目の端末が `[detached (from session work)]` になった
- マウス: 設定ファイルの後に、SGR のマウスの信号を端末に送った。ホイールで `[5/258]` のコピーモードに入り、クリックで左のペインが選ばれ、境界のドラッグで左のペインの幅が 80 から 69 になった
- `man tmux`: コンテナに `man-db` を足すと、`man -w tmux` は `/home/linuxbrew/.linuxbrew/Cellar/tmux/3.7c/share/man/man1/tmux.1` を返した
- `history-limit`: 設定ファイルを読む前に作ったペインでも、`source-file` の後に 5000 行を出すと 4973 行をさかのぼれた
- SSH の切断: tmux の中で `top` を動かしたまま SSH のクライアントを `kill -KILL` した。tmux と `top` は残り（`loginctl` のセッションは `closing`）、ログインし直して `tmux attach -t work` で `top` の画面に戻った
- 対話の `claude`（ログインしていない）を tmux の中で起動すると、テーマを選ぶ最初の画面が出た。`pgrep -af` には起動したときの引数のまま出た（`claude --name pgtest`）
- `tmux new-session -s claude-rc claude remote-control …` と tmux に直接起動させると、`[exited]` だけが出てエラーの文が読めなかった。ステータス行の左端は `[claude-rc` で切れた

#### 未確認事項

- 実機（aarch64 の Raspberry Pi 5、x86_64 の PC）での本実行
- Remote Control の接続、スマートフォン・ブラウザからの操作、約 10 分のネットワーク断での終了と、4 時間以内の再開
- 端末（WezTerm など）からのマウスの操作と、Shift を押しながらの文字の選択
- Claude Code の `Ctrl+B` を tmux の中で 2 回押したときの動き、Shift+Enter
- Homebrew の版が上がる `brew upgrade tmux` と、前の版のサーバーへのつなぎ直し
- `claude --bg` と `claude attach`

---

### 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1〜5、設定ファイル（任意）の手順 1・2。

**結果**: Homebrew の tmux 3.7c を導入した。`work` の TUI に入り、`Ctrl+b d` でデタッチ、`tmux attach -t work` で復帰し、`exit` で終了した。手順 5 は `no server running`。設定ファイルを置いた後の確認用セッションで `mouse on` と `history-limit 50000` を読み戻した。端末捕捉用ライブラリの private DSR 対応不足で初回の画面読み取りが止まったため、検証補助だけを直して同じセッションに入り直し、手順 3〜5 の操作を再確認した。

**今回の未確認範囲**: マウス・Shift+Enter・Claude Code と Remote Control の任意節、更新・ロールバックは今回確認していない。

### 付録: 現行版の別の新規 VM での再検証（2026-10-06）

- `5da3478` の実施手順 1〜5 と設定ファイル（任意）の手順 1・2 を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM で共通 bash の導入後に確認した。Homebrew の tmux 3.7c の bottle・版・PATH が揃った
- 利用者のセッションを巻き込まない専用ソケットで `work` を作り、Ctrl+b d でデタッチ、一覧、attach、実キーの `exit`、`no server running` を確認した。任意設定は本文どおり新規作成し、専用の確認用セッションで `mouse on` / `history-limit 50000` を読み戻した
- マウス・Shift+Enter・Claude Code / Remote Control の任意節、SSH の切断後の維持、更新・削除はこの再検証には含めない


### 操作上の注意と併記されていた記録

- 本書のロールバックは、x86_64 のコンテナで通した


### 実施手順 / 手順 1: 補足: 依存と出力

コンテナ（Homebrew 7.0.7、ほかの formula が無い状態）での出力の抜粋:

```
==> Would install 1 formula:
tmux 3.7c
==> Would install 5 dependencies for tmux:
ca-certificates
openssl@3
libevent
ncurses
utf8proc
==> Do you want to proceed with the installation? [y/n]
...
==> Installing tmux
==> Pouring tmux--3.7c.x86_64_linux.bottle.1.tar.gz
🍺  /home/linuxbrew/.linuxbrew/Cellar/tmux/3.7c: 9 files, 1.8MB
==> Caveats
==> tmux
Example configuration has been installed to:
  /home/linuxbrew/.linuxbrew/opt/tmux/share/tmux
```

- 依存がすでに入っていれば、一覧は短くなる。全部入っていれば聞かれない
- `[y/n]` を聞くのは Homebrew 7.0.7 の ask mode（[homebrew.md の注意点](../homebrew.md#注意点)）
- `example_tmux.conf` は、プレフィックスを `Ctrl+a` に変えるなど好みの強い例なので、本書は読み込まない



### 実施手順 / 手順 3: 補足: SSH が切れたとき

- コンテナで、SSH でログインしたシェルから tmux のセッションを作り、中で `top` を動かしたまま SSH のクライアントを `kill -KILL` で落とした。tmux のサーバーと `top` は残り、ログインし直して `tmux attach -t work` で `top` の画面に戻れた
- 残るのは、systemd-logind の `KillUserProcesses` が既定で `no` のため（`/usr/lib/systemd/logind.conf` に `#KillUserProcesses=no`、`busctl` で読んだ値も `false`）。SSH のセッション（`loginctl`）は `closing` のまま残る
- [linger](../linger.md) は要らない（tmux は systemd のユーザーのサービスではない）

## 参考資料から分離した記録

### 参考資料: 設定ファイル（任意） / 手順 1: 補足: 読み込む場所と、足さなかった行

- 両方のファイルを置いて試すと、両方の設定が効いた（`~/.tmux.conf` の `mouse on` と `~/.config/tmux/tmux.conf` の `history-limit`）
- Homebrew の tmux のシステムの設定ファイルは `/home/linuxbrew/.linuxbrew/etc/tmux.conf`（`man tmux`）。`/etc/tmux.conf` は読まない
- `escape-time`（Esc の後に待つ時間）は、3.7c の既定ですでに 10 ミリ秒なので足さない。Neovim などのために 0〜10 にする例は、古い版の既定の 500 ミリ秒を縮めるためのもの
- Claude Code の公式ドキュメントには、tmux の設定の推奨は無かった（Shift+Enter のための `extended-keys` なども）。本書では足していない

### 参考資料: Claude Code を tmux の中で動かす（任意） / 手順 1: 補足: claude auth status を最後に置く理由

- ブラケットペースト無しで貼ると、`claude auth status --text` は、端末に残っていた後ろの行を読んで捨てた（後ろの `tmux -V` や `echo` が実行されなかった）
- `claude --version` と `claude doctor` では、後ろの行も実行された

## 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

### 設定ファイル（任意）

- マウスを on にすると、マウスでの文字の選択は tmux が受け取る。端末の選択を使うときは、端末の決まりに従う（WezTerm などは Shift を押しながら。本書では確かめていない）

### 補足

- **ログアウトしてもセッションが残るのは、`KillUserProcesses=no` のとき**: AlmaLinux 10 の既定。`yes` にしたホストでは、ログアウトでセッションも止まるはず（確かめていない）
