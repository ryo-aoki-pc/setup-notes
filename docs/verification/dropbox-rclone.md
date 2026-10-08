# Dropbox を rclone で同期する手順（AlmaLinux 10 / Raspberry Pi 5 / Homebrew + systemd ユーザータイマー）の検証記録

[手順書](../dropbox-rclone.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 操作上の注意と併記されていた記録

  - 本当に消すのなら、rclone の案内のとおり `--force` を付けて手で 1 回動かす（本書では試していない）

### 操作上の注意と併記されていた記録

   - 先頭の `if` は、タイマーを止めないまま貼ったときに、削除が Dropbox 側へ伝わるのを防ぐ（コンテナで、動いている間は `中断:` が出て何も消えないことを確かめた）

### 実施手順: 検証状況の記録

> [!WARNING]
> **x86_64 の VM で rclone の導入と OAuth 待ち受けまで検証した。Dropbox の認証と実際の同期は未確認。手順 4 以降の代役のリモートによる確認は、以前のコンテナ検証の範囲**（[対象と検証環境](#対象と検証環境)）。

### 実施手順 / 手順 2: 補足: 出る表示と、トークンの扱い

コンテナでの表示（許可はせず、20 秒で打ち切った）。案内はすべて標準エラーに出るので、`>/dev/null` を付けても見える:

```
NOTICE: Config file "/home/<USER>/.config/rclone/rclone.conf" not found - using defaults
NOTICE: Make sure your Redirect URL is set to "http://localhost:53682/" in your custom config.
ERROR : Failed to open browser automatically (exec: "xdg-open": executable file not found in $PATH) - please go to the following link: http://127.0.0.1:53682/auth?state=<STATE>
NOTICE: Log in and authorize rclone for access
NOTICE: Waiting for code...
```

- `xdg-open` があればブラウザを自動で開こうとする（コンテナには無いので `Failed to open browser automatically` と出た）
- その URL は、rclone が `127.0.0.1:53682` で待ち受けている一時的な Web サーバーで、Dropbox の認証画面（`https://www.dropbox.com/oauth2/authorize`）へ 307 で飛ばす（コンテナで `curl` して確かめた）
- 許可しないまま打ち切ると、`rclone.conf` は書かれない
- SSH のトンネル（rclone の文書の「Configuring using SSH Tunnel」の形）は試していない

**登録が終わると、`rclone config create` はトークン入りの設定を標準出力に出す**。ダミーのトークンで確かめた:

```
[probe2]
type = dropbox
token = {"access_token":"<DUMMY>","token_type":"bearer","refresh_token":"<DUMMY>","expiry":"2030-01-01T00:00:00Z"}
```

- トークンは `~/.config/rclone/rclone.conf` に平文で入る（権限は 600）
- 中身を確かめるときは `rclone config redacted dropbox`（`token = XXX` と伏せて出す）を使い、`rclone config show` は使わない

### 実施手順 / 手順 4: 補足: コンテナでの表示

コンテナでは代役（`alias`）のリモートなので、種類は `alias`、容量はコンテナのディスクの値になる:

```
dropbox: alias
Total:   251.972 GiB
Used:    8.568 GiB
Free:    28.480 GiB
        4096 2026-09-27 16:21:31        -1 Documents
        4096 2026-09-27 16:21:31        -1 Photos
        4096 2026-09-27 16:21:31        -1 Work
```

本物の Dropbox での `rclone about` の表示は確かめていない。

### 実施手順 / 手順 6: 補足: 絞ったときの動き

フィルタは上の行から順に当てはめ、最初に当たった行で決まる。`+ /Documents/**` と `+ /Photos/**` の後に `- **` を置くと、その 2 つのフォルダだけが同期の対象になる。

コンテナでは、[同期するフォルダを変える（任意）](../dropbox-rclone.md#同期するフォルダを変える任意)で同じ 3 行を有効にして（`vi` の代わりに `sed` で書き換えた）、次を確かめた:

- Dropbox 側の `Documents` に足したファイルは手元に来て、`Work` に足したファイルは来なかった
- 外した `Work` の手元の複製は、消えずに残った（同期されなくなるだけ）

### 実施手順 / 手順 8: 補足: できるものと、途中で止まったとき

終わると、次のものができる:

- `~/Dropbox` の中身
- フィルタのハッシュ `~/.config/rclone/dropbox-filters.txt.md5`
- 両側の一覧 `~/.cache/rclone/bisync/*.path1.lst` / `*.path2.lst`（次の回からの比較に使う）

**途中で止まると、ロック（`~/.cache/rclone/bisync/*.lck`）と書きかけ（`*.partial`）が残る**。コンテナで、SSH が切れたときと同じ SIGHUP を送って確かめた:

- rclone はその場で終わった（終了コード 129）
- すぐに貼り直すと `prior lock file found`（`Valid lock file found. Expires at ... (1m53s from now)`）で止まった
- `--max-lock 2m` があるので、ロックは最後の更新から 2 分で切れる。切れた後に貼り直すと、最初からやり直して `Bisync successful` になり、書きかけは Dropbox に上がらなかった（フィルタの `- *.partial`）
- `--max-lock` を付けないとロックは切れず、rclone が案内するコマンドでロックを手で消すことになる

### 実施手順 / 手順 10: 補足: コンテナでの出力

```
Result=success
... rclone[3747]: INFO  : Building Path1 and Path2 listings
... rclone[3747]: INFO  : No changes found
... rclone[3747]: INFO  : Bisync successful
... systemd[3663]: Finished dropbox-rclone.service - rclone bisync (Dropbox <-> ~/Dropbox).
NEXT                            LEFT LAST PASSED UNIT                 ACTIVATES
Sun 2026-09-27 16:18:26 UTC 4min 58s -         - dropbox-rclone.timer dropbox-rclone.service
```

- `NEXT` は、ユーザーの systemd が起動してから 5 分後だった。コンテナの中では、`OnBootSec` を systemd の起動時刻から数えるため
- 実機では PC の起動から数え、timer を有効にした時点でもう過ぎていれば、すぐに動く（`man systemd.timer` の「If a timer configured with OnBootSec= ... is already in the past when the timer unit is activated, it will immediately elapse」。実機では確かめていない）
- timer が自分で動かした回の後は、`LAST` に前回の時刻、`NEXT` にその 15 分後が出た

### 対象と検証環境

- **目的**: Raspberry Pi 5（aarch64）の AlmaLinux 10 で、ログインしていない間も `~/Dropbox` を Dropbox と同期し続ける。Dropbox の公式クライアントは ARM の Linux で動かないので、rclone の双方向同期（bisync）を systemd の timer で 15 分ごとに回す
- **進め方**: Homebrew で rclone を入れ、ブラウザで Dropbox を登録し、`--resync` で最初の同期をしてから、ユーザーの timer と、前提の [linger](../linger.md)（`loginctl enable-linger`）で定期的に動かす。**読者が書き換える変数は無い**
- **状態**: **x86_64 の VM で rclone の導入と OAuth 待ち受けまで検証済み（2026-10-06）。現行版は新規 VM のローカル alias で、同期・timer・ロールバックも再検証した**（[今回の付録](#付録-現行版を新規-vm-で再検証2026-10-06)）。Dropbox との認証・クラウド同期は未確認
  - VM の実測は[今回の付録](#付録-vm-での検証記録2026-10-06)。以下のコンテナでの結果と未確認事項は、当時の検証範囲の記録。
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**、手順 1・2・4〜10・[同期するフォルダを変える（任意）](../dropbox-rclone.md#同期するフォルダを変える任意)・[更新](../dropbox-rclone.md#更新)・[ロールバック](../dropbox-rclone.md#ロールバック)を通した（手順 6 は飛ばし、同じ編集は任意の節で `vi` の代わりに `sed` で行った）
    - linger の有効化と解除（今の [linger.md](../linger.md) の手順 2 とロールバック。当時はこの文書の手順 9・10 とロールバックの手順 1・2）も、このとき通した
  - 手順 2 は本物の Dropbox で、URL が出て、`127.0.0.1:53682` が Dropbox の認証画面へ飛ばすところまで確かめた（許可はしていない）
  - **手順 4 以降は、`dropbox` という名前で、コンテナの中のディレクトリを指す代役のリモート（種類 `alias`）で確かめた**
  - 確認したこと:
    - フィルタの行が効く（`desktop.ini` などが同期されない）、`--resync` で手元に落ちてくる
    - 追加・変更・削除が両方向に伝わる、競合では新しい方が残り古い方が `.conflict1` で残る
    - 半分を超える削除で `Safety abort` になり、戻すと次の回は成功する
    - フィルタを変えて `--resync` を忘れると止まる
    - 途中で止まったとき（`kill -9` / SIGHUP / SIGTERM）の、ロックと書きかけと回復
    - timer が自分で動き、次の回が 15 分後になる
    - ロールバックで元に戻る
  - **確認していないこと**: Dropbox との実際の同期（Dropbox の API の制限、大文字と小文字、Dropbox が受け付けない名前）、aarch64 での導入と実行、SSH のトンネルでの認証、再起動後の timer、SELinux が Enforcing の実機での動作
  - 2026-10-05: 手順 1 の導入と確認を分け、確認を手順 2 の冒頭へ移した。更新も完了を待ってから別の手順で確認する形にした。ロールバックの手順 5 は共有の bisync キャッシュを残す形にした。変更後は構文検査と一時ディレクトリ・スタブでの確認だけで、Dropbox との同期はしていない

| 項目 | 実機（Raspberry Pi 5） | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-27 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64 | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/10-init:10.2`、Docker 29.3.1、`--privileged`、systemd を PID 1） |
| Homebrew | 7.0.6（[syncthing.md](../syncthing.md) の 2026-09-24 の記録） | 7.0.6（[homebrew.md](../almalinux-setup.md) の手順 1〜3 で新規導入） |
| rclone | 未導入 | 1.75.1（`x86_64_linux` のボトル）。`arm64_linux` のボトルもある（formulae.brew.sh の JSON） |
| Dropbox のリモート | — | 手順 2 は本物（URL が出るまで）、手順 4 以降は代役（`alias`） |
| linger | Syncthing のために有効（syncthing.md の記録） | 無効から始めた |

> [!NOTE]
> 出力例・ログの値は `<USER>`（OS のアカウント名）/ `<HOSTNAME>` / `<STATE>`（OAuth の 1 回限りの値）/ `<DUMMY>`（ダミーのトークン）のプレースホルダで書いてある。本物のトークンはこの文書に載せない。版（`1.75.1`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

検証コンテナの状態:

| 項目 | 状態 |
|---|---|
| rclone | 未導入（`~/.config/rclone` も `~/.cache/rclone` も無い） |
| Homebrew | 7.0.6（formula は 0 本） |
| `~/Dropbox` | 無い |
| linger | `Linger=no` |

### 選択した方針

Raspberry Pi 5（aarch64）の AlmaLinux 10 で Dropbox と同期する経路を比べた（2026-09-27 時点）:

| 経路 | aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew の rclone** | 1.75.1。`arm64_linux` のボトルがある。`brew upgrade` で上がる | **採用** |
| EPEL 10 の rclone | 1.74.3 | 不採用（Homebrew より古い。[導入元一覧](../tool-catalog.md#選び方)の CLI の選び方） |
| Dropbox の公式クライアント | 無い（`download?plat=lnx.aarch64` が 404。公式ヘルプも ARM は非対応） | —（x86_64 では [dropbox.md](../dropbox.md)） |
| Maestral | オープンソースの Dropbox クライアント（1.9.6、2025-11-04）。公式と同じく常駐して同期する。RPM も Linux 向けの Homebrew の formula も無く（cask は macOS だけ）、pip か uv で入れる | 不採用（dnf にも brew にも乗らない） |
| Flathub `com.dropbox.Client` | x86_64 のみ | — |

- **`rclone bisync`（双方向同期）にした**
  - 手元に複製があり、つながっていなくても読める
  - Samba や Syncthing からも、ふつうのファイルとして見える
- `rclone mount`（FUSE でマウントする）は、手元に複製を持たず、つながっていないと開けない（本書では試していない）
- **間隔は 15 分にした**。bisync は毎回、Dropbox と手元の一覧を全部取るので、短くすると Dropbox の API の呼び出しが増える（大きなアカウントでは広げる）

### 完了時点の状態

**検証コンテナでの出力**（手順 10 の直後。代役のリモート）:

```
$ systemctl --user list-timers dropbox-rclone.timer --no-pager
NEXT                            LEFT LAST PASSED UNIT                 ACTIVATES
Sun 2026-09-27 16:18:26 UTC 4min 58s -         - dropbox-rclone.timer dropbox-rclone.service
$ loginctl show-user 1000 -p Linger
Linger=yes
$ ls ~/.config/rclone/
dropbox-filters.txt  dropbox-filters.txt.md5  rclone.conf
$ find ~/Dropbox -type f | sort
/home/<USER>/Dropbox/Documents/memo.txt
/home/<USER>/Dropbox/Documents/plan.md
/home/<USER>/Dropbox/Photos/2026/img001.jpg
/home/<USER>/Dropbox/Photos/2026/img002.jpg
/home/<USER>/Dropbox/Work/old/2019.txt
/home/<USER>/Dropbox/Work/report.txt
```

代役の側にあった `desktop.ini` と `Documents/~memo.tmp` は、フィルタで外れて手元に来ていない。

### 操作上の注意と併記されていた記録

  - 既定では rclone 全体で共有の Dropbox の app key を使う。`too_many_requests` が続くなら、間隔を広げるか、rclone の文書のとおり自分の app key を作る（本書では試していない）

### 操作上の注意と併記されていた記録

- **Dropbox は大文字と小文字を区別しない**: 手元で大文字と小文字だけが違う 2 つのファイルは、Dropbox 側でぶつかる。Dropbox が受け付けない名前もある（本書では試していない）

### 付録: コンテナでの検証記録（2026-09-27）

`quay.io/almalinuxorg/10-init:10.2`（`sha256:a91c1066…fd73`）を x86_64 のクラウドホスト上の Docker 29.3.1（cgroup v1）で `--privileged`・`--network host` で立て、systemd を PID 1 で動かした。実機で加えた変更は無い。検証の準備（`systemd-logind` を戻す、`/var/log/journal` を作る、プロキシの CA、非 root ユーザー、ホームの bind mount）と、コードブロックの流し方は [dropbox.md の付録](dropbox.md#付録-コンテナでの検証記録2026-09-27)と同じ。Homebrew は [homebrew.md](../almalinux-setup.md) の手順 1〜3 を、インストーラだけ `NONINTERACTIVE=1` を付けて通した。

途中で手順のブロックを直したので、書き上げた後に、コードブロックを文書から直接抜き出して手順 1・2・4〜10（手順 6 は飛ばした。linger は今の [linger.md](../linger.md) の手順に当たるもの）・任意の節・更新・ロールバックをもう一度通した。下の表はその結果と、途中の確かめ（中断・競合など）をまとめたもの。

**代役のリモート**: 手順 2 を打ち切った後、`rclone config create dropbox alias remote=/home/<USER>/fake-dropbox` で、同じ名前 `dropbox` のリモートを作った。`fake-dropbox` には、`Documents`（2 ファイルと `~memo.tmp`）・`Photos/2026`（2 ファイル）・`Work`（`old/2019.txt` を含む 2 ファイル）・`desktop.ini` を置いた。

| 手順 | 結果 |
|---|---|
| 1 | `rclone v1.75.1`、`os/arch: linux/amd64`、`/home/linuxbrew/.linuxbrew/bin/rclone`。ロールバックの後にもう一度流しても同じだった |
| 2 | 本物の Dropbox で実行。案内が標準エラーに出て `Waiting for code...` で待った。`127.0.0.1:53682/auth?state=...` を `curl` すると `307` で `https://www.dropbox.com/oauth2/authorize` へ飛んだ。20 秒で打ち切り（終了コード 124）、`rclone.conf` は書かれなかった。ダミーのトークンで作ったリモートでは、標準出力にトークン入りの設定が出た |
| 4〜5 | 代役で、`dropbox: alias`・容量・3 つのフォルダ。フィルタの有効な行は 7 行 |
| 7〜8 | `--dry-run` も本番も `Bisync successful`。6 ファイルがコピーされ、`desktop.ini` と `~memo.tmp` は外れた。`.md5` と一覧ができた |
| 8 の中断 | 20 MB のファイルを足し、`--bwlimit 1M` を付けた同じコマンドに SIGHUP を送ると、終了コード 129 で止まり、ロックと `video.mp4.<16 進>.partial` が残った。すぐ貼り直すと `prior lock file found`（期限まで 1m53s）。期限の後に手順 8 を貼り直すと、`Lock file found, but it expired at ... Will delete it and proceed.` の後に `Bisync successful` になり、書きかけは代役に上がらなかった |
| linger.md 2、本書の 9・10 | `Linger=yes`、`enabled`、`Result=success`、`No changes found`、`list-timers` に `NEXT` |
| 双方向 | 手元で足したファイルが代役に、代役で変えたファイルが手元に、手元で消したファイルが代役から消えた |
| 競合 | 両方で `plan.md` を変えると `The winner is: Path2`（新しい手元の方）、代役の方が `plan.md.conflict1` になって両側に残った |
| 削除の安全装置 | 手元の 6 ファイル中 4 つを消すと `ERROR : Safety abort: too many deletes (>50%, 4 of 6)`、`Result=exit-code`。次の回も同じ。手元に戻すと成功した。代役のファイルは消えなかった |
| フィルタの変更 | `--resync` せずに行を足すと `Bisync critical error: filters file has changed (must run --resync)`。戻すと成功した |
| `kill -9`（フィルタに `*.partial` が無いとき） | 残った書きかけが、次の回（timer が自分で動かした回）で新しいファイルとして代役に上がった。これを受けて、フィルタに `- *.partial` を足した |
| `kill -9`（`- *.partial` を足した後） | 書きかけは上がらず、次の回で本物のファイルがコピーされた。この確認では、期限を待たずにロックを手で消した |
| SIGTERM | `Attempting to gracefully shutdown.` の 15 秒後に `Graceful shutdown completed successfully.`（終了コード 143）。ロックも書きかけも残らず、次の回は成功した |
| timer | 予定（`NEXT`）の 43 秒後に timer が自分で動かし、期限の切れたロックを消して `--recover` で回復した（`Listings not found. Reverting to prior backup as --recover is set.`）。その後の `NEXT` は、終わってから 15 分後だった |
| 任意の節 | 手順 1 は `vi` の代わりに `sed` で 3 行の `# ` を外した。`--resync` の後、代役の `Documents` に足したファイルは手元に来て、`Work` に足したファイルは来なかった。手元の `Work` は残った |
| 更新 | `Warning: rclone 1.75.1 already installed` |
| ロールバック | タイマーが動いている間に手順 5 を貼ると `中断: ...` が出て、何も消えなかった。手順 1・2・4・5 と linger の解除（今の [linger.md のロールバック](../linger.md#ロールバック)の手順 1・2。当時はこの文書の手順 1 の最後の `ls` と手順 2）は `Removed ...`、`ls` は無出力、`Linger=no`、`listremotes` は無出力、`Uninstalling ... rclone/1.75.1`、手順 5 で `~/Dropbox` などが消えた。空の `rclone.conf` と `~/.cache/rclone` は残った。linger を切った後は、`docker exec` にはログインセッションが無いのでユーザーの systemd が止まり、手順 5 の `systemctl --user is-active` は `Failed to connect to user scope bus` を出した（実機でログインしていれば、ユーザーの systemd は動いている） |

#### 未確認事項

- 実機（Raspberry Pi 5 / aarch64）での導入と実行
- Dropbox の認証（ブラウザでの許可）と、本物の Dropbox との同期
- SSH のトンネル（`ssh -L`）を通した認証
- Dropbox の API の制限（`too_many_requests`）が、15 分の間隔とアカウントの大きさでどう出るか
- 大文字と小文字だけが違うファイル、Dropbox が受け付けない名前、Dropbox Paper などの扱い
- 再起動した後に、linger で timer が動くこと
- SELinux が Enforcing の実機での動作
- `--force` を付けた削除の反映
- `rclone mount` での使い方

---

### 付録: VM での検証記録（2026-10-06）

**環境**: [クリーンインストールからの検証記録](almalinux-vm.md)のコンテナ用 VM。公式 ISO から Workstation を入れた状態から始め、x86_64、SELinux Enforcing、firewalld 有効。本文のブロックを SSH の擬似端末で実行した。

- 本文の手順 1 で Homebrew の rclone 1.75.1 が入った。手順 2 では版とコマンドの場所を確認し、Dropbox リモートの作成が認証 URL と `127.0.0.1:53682` の待ち受けを出した。
- ブラウザで許可する前に Ctrl+C 相当で中断した。手順 2 の設定作成は未完了で、手順 3 以降は実行していない。今回の VM では代役のリモートを使った同期もしていない。
- Dropbox のアカウント・トークンは使っていない。以前のコンテナでの alias リモートによる bisync・timer の結果と、今回の導入確認を区別する。

---

### 付録: 現行版を新規 VM で再検証（2026-10-06）

**対象**: `setup-notes` の `5da3478` 版。公式 ISO で Workstation を入れた `clean-install` スナップショットから、新規の `alma10-current-20261006-containers` を作った。AlmaLinux 10.2 / x86_64 / SELinux Enforcing / firewalld 有効。共通 bash は `3d5323e` を新規導入した。以前の付録と別の試験で、現行ブロックを SSH の擬似端末で順に実行した。

実施手順 1 で Homebrew の rclone 1.75.1 を新規導入した。認証後の仕組みは、試験用のローカルディレクトリを `alias` remote の `dropbox:` として用意した補助試験で確認した。実施手順 4・5・7〜10 のブロックを通し、dry-run、初回 resync、ユーザー service の `Result=success`、timer の `enabled` / `active` が得られた。続く通常 bisync で、代役側から手元、手元から代役側へのファイルの伝播を `cmp` で確認した。実 Dropbox の OAuth・容量・クラウド同期を検証した結果とは扱わない。

代役試験の後、ロールバックの手順 1・2・4・5 で timer / service、代役の remote、本体、試験用の同期先とフィルタを撤去した。実アカウントを認証していないので、手順 3 の Dropbox 側での許可撤回は行っていない。


### 実施手順 / 手順 1: 補足: 入るものと、EPEL 版との違い

- コンテナでは `rclone--1.75.1.x86_64_linux.bottle` のボトルが入った（11 ファイル、110.4 MB。依存は無い）
- Raspberry Pi 5 向けの `arm64_linux` のボトルもある（formulae.brew.sh の JSON で確認。aarch64 には入れていない）
- EPEL 10 にも `rclone` があるが 1.74.3 で、1 マイナー古い（[導入元一覧](../tool-catalog.md#選び方)の CLI の選び方で Homebrew にした）
- bash の補完は `/home/linuxbrew/.linuxbrew/etc/bash_completion.d` に入る

## 参考資料から分離した記録

### 参考資料: 実施手順 / 手順 5: 補足: フィルタの中身

- 前の 6 行は、rclone の bisync の文書にある「Example filters file for Dropbox」の、Dropbox が同期しないファイルの行をそのまま使った（Office の一時ファイル、Windows の `desktop.ini` など）
- **`- *.partial` は本書で足した**。rclone は転送中のファイルを `<名前>.<16 進>.partial` として書き、終わってから名前を変える
  - `kill -9` や電源断で止まるとこれが残り、フィルタに無いと、次の回で新しいファイルとして Dropbox に上がった（コンテナで確認）
  - 足した後は、残った書きかけは上がらず、次の回で本物のファイルがコピーされた
- このファイルは、手順 7・8 と手順 9 の timer から、いつも `--filters-file` で渡す。bisync は中身のハッシュを `~/.config/rclone/dropbox-filters.txt.md5` に覚えていて、変えたのに `--resync` をしないと止まる（[同期するフォルダを変える（任意）](../dropbox-rclone.md#同期するフォルダを変える任意)）

### 参考資料: 実施手順 / 手順 7: 補足: Path1 と Path2、--resync の意味

- `dropbox:` が Path1、`~/Dropbox` が Path2。`--resync` は、両方にあって中身が違うファイルでは Path1（Dropbox）を正とし（`--resync-mode path1`）、片方にしか無いファイルはもう片方へコピーする
- `--resync` は最初の 1 回と、フィルタを変えたときだけ使う。ふだんの同期（手順 9 の timer）には付けない
- `--max-lock 2m` は、途中で止まったときに残るロックを 2 分で切らせる（手順 8 の補足）
- アカウントが大きいと、ファイルの数だけ行が出る

コンテナでの出力（抜粋。フィルタにある `desktop.ini` と `~memo.tmp` はコピーの対象に出ない）:

```
INFO  : Synching Path1 "/home/<USER>/fake-dropbox/" with Path2 "/home/<USER>/Dropbox/"
INFO  : Using filters file /home/<USER>/.config/rclone/dropbox-filters.txt
NOTICE: - Path2    Resync is copying files to         - Path1
INFO  : There was nothing to transfer
NOTICE: - Path1    Resync is copying files to         - Path2
NOTICE: Work/report.txt: Skipped copy as --dry-run is set (size 7)
NOTICE: Documents/memo.txt: Skipped copy as --dry-run is set (size 5)
...
INFO  : Bisync successful
```

### 参考資料: 実施手順 / 手順 9: 補足: unit の中身の理由

- **rclone は絶対パスで書く**。systemd は `~/.bashrc` を読まないので、Homebrew の PATH が無い。`/home/linuxbrew/.linuxbrew/bin/rclone` は `brew upgrade` で付け替わるリンクなので、更新しても書き換えなくてよい
- `%h` は systemd がホームディレクトリに置き換える
- `Type=oneshot` なので、`systemctl --user start` は同期が終わるまで戻らない。timer は、前の回が動いている間は次を始めない
- フラグは、rclone の bisync の文書が無人で回すときに勧めている組み合わせ
  - `--resilient`: 軽いエラーのあと、`--resync` をしなくても次の回で続けられる
  - `--recover`: 途中で止まっても、次の回で自動で回復する
  - `--max-lock 2m`: 途中で止まって残ったロックを 2 分で切らせる
  - `--conflict-resolve newer`: 両方で変わったファイルは新しい方を残す（古い方は `<名前>.conflict1` として残る）
- `OnBootSec=5min` は起動から 5 分後、`OnUnitInactiveSec=15min` は前の同期が終わってから 15 分後に動かす
  - `OnUnitInactiveSec` は 1 回動いた後から効く。手順 10 で 1 回動かしておく
  - 動く時刻は最大 1 分ずれる（systemd の既定の `AccuracySec=1min`。コンテナでは予定の 43 秒後に動いた）
- ユーザーの systemd からは `network-online.target` を使えないので、起動直後はつながっていないことがある。`OnBootSec` で 5 分待ち、失敗しても `--resilient` で次の回に続ける

## 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

### 使い方の基本

  - 誤って消したのなら、手元に戻すと次の回から元どおりに動く（コンテナで確認）

- 両方で変えたファイルは新しい方が残り、古い方は `<名前>.conflict1` として両側に残る（コンテナで確認）

### 同期するフォルダを変える（任意）

- フィルタを変えたら、次の同期は `--resync` で行う。しないと `Bisync critical error: filters file has changed (must run --resync)` で止まる（コンテナで確認）

### 補足

- **止めるときは `systemctl --user stop`**: SIGTERM を受けた rclone は、転送中のファイルを片づけて止まる（`Graceful shutdown completed successfully.`。ロックも書きかけも残らなかった）

  - ロックは `--max-lock 2m` で 2 分後に切れ、timer の次の回が `--recover` で回復した（コンテナで確認）

- **端末の上限**: Basic（無料）プランは同時に 3 台まで。rclone のような連携アプリが数えられるかは、公式ヘルプに書かれていない（確かめていない）
