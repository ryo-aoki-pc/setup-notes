# Dropbox 公式クライアント導入手順（AlmaLinux 10 / x86_64 / headless + systemd ユーザーサービス）の検証記録

[手順書](../dropbox.md)・[ロールバックと注意点](../extra/dropbox.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> **x86_64 の VM で導入と認証前のサービス起動まで検証した。アカウントのリンクと同期は未確認で、実機には入れていない**（[対象と検証環境](#対象と検証環境)）。

### 実施手順 / 手順 1: 補足: Dropbox の要件と、ARM 版が無いこと

公式ヘルプ（System requirements）が挙げる Linux の要件:

- 64 ビットで、glibc 2.27 以降（AlmaLinux 10 は 2.39）
- ファイルシステムは ext4・xfs・btrfs・eCryptFS（ext4 の上）
- 公式に対応するのは Ubuntu と Fedora だけで、ほかのディストリビューションは「要件を満たせば動く場合がある」扱い
- 「Dropbox doesn't support ARM processors for Linux」

配布の URL でも ARM 版が無いことを確かめた（2026-09-27）:

```
$ curl -sS -o /dev/null -w '%{http_code}\n' 'https://www.dropbox.com/download?plat=lnx.aarch64'
404
```

`plat=lnx.arm64` も 404 だった。検証コンテナでは `x86_64` / `ext2/ext3` と出た（ホストの ext4 のディレクトリをホームにした）。

### 実施手順 / 手順 2: 補足: 鍵の出どころと、EL10 で使えること

`gpg --show-keys` の実測（鍵束には取り込まない。`~/.gnupg` が無ければ最初の実行で作られる）:

```
pub   rsa2048 2010-02-11 [SC]
      1C61 A265 6FB5 7B7E 4DE0  F4C1 FC91 8B33 5044 912E
uid                      Dropbox Automatic Signing Key <linux@dropbox.com>
```

- 同じ鍵が、この URL・公式 RPM の `%post`・手順 5 で入れる `dropbox.py` の中（`DROPBOX_PUBLIC_KEY`）の 3 か所にある。`dropbox.py` の中の鍵も同じ fingerprint だった（コンテナで確認）
- 自己署名は 2 つある。2010 年のものは SHA-1、2025-12-23 に足されたものは SHA-256（`gpg --list-packets` の `digest algo 2` と `8`）
- この手順では鍵を rpm に取り込まず、手順 3 の `gpgv` で署名を確かめるだけに使う。EL10 の rpm が SHA-1 の自己署名の鍵を取り込まない問題（[tool-catalog.md の注意点](../tool-catalog.md#注意点)）とは関係しない

### 実施手順 / 手順 3: 補足: 飛び先を 1 回だけ引く理由

**`download?plat=lnx.x86_64` は、呼ぶたびに版を振り分ける**（段階的な配信）。2026-09-27 に 30 回引いたら、29 回が `270.4.3312`、1 回が `272.3.3756` だった。

- 署名の URL（`download?plat=lnx.x86_64&signature=1`）も別に振り分けられる。tarball と署名を別々に引くと、版が食い違うことがある
- 実際に、最初に書いた手順（この 2 つの URL を別々に引く形）をコンテナで流したら、tarball が `272.3.3756`、署名が `270.4.3312` になり、`BAD signature` で止まった（[付録](#付録-コンテナでの検証記録2026-09-27)）
- そこで、飛び先（版の入った URL）を 1 回だけ引き、その URL と、末尾に `.asc` を付けた URL を落とす形にした。`272.3.3756` にも専用の署名があり、`Good signature` になる

`dropbox.py` の `start -i`（デーモンを自分で落とす機能）も 2 つの URL を別々に引く作りなので、同じ食い違いが起こりうる。

その他:

- `gpgv` は、渡した鍵束の鍵を信頼して確かめるので、`gpg --verify` のような信頼度の警告を出さない。鍵束にする前の fingerprint の目視（手順 2）が、その代わりになる
- `gpg --dearmor` の出力をリダイレクトで書くのは、`-o` だと既存のファイルがあるときに `File '...' exists. Overwrite? (y/N)` と聞いて止まるため（貼り直したときに当たる。コンテナで確認）
- 署名は SHA-256（`digest algo 8`）

出力（コンテナの実測。進捗の行は省いた）:

```
https://edge.dropboxstatic.com/dbx-releng/client/dropbox-lnx.x86_64-270.4.3312.tar.gz
100 86.9M  100 86.9M    0     0  76.7M      0  0:00:01  0:00:01 --:--:-- 76.8M
gpgv: Signature made Tue Sep 15 01:49:43 2026 UTC
gpgv:                using RSA key 1C61A2656FB57B7E4DE0F4C1FC918B335044912E
gpgv: Good signature from "Dropbox Automatic Signing Key <linux@dropbox.com>"
```

### 実施手順 / 手順 9: 補足: リンクする前にできるもの

リンクする前でも、デーモンは `~/.dropbox` に設定・DB・ソケットを作る（コンテナの実測）:

```
$ ls ~/.dropbox
apex.sqlite3  apex.sqlite3-shm  apex.sqlite3-wal  boot_marker.dbx  command_socket  dropbox.pid
events  iface_socket  instance1  instance_db  logs  machine_storage  metrics
```

- `dropbox.pid` はデーモンの PID で、`dropbox` コマンドはこれを見て動いているかを判断する
- リンクの情報もここに入る（[ロールバック](../extra/dropbox.md#ロールバック)の手順 4 で消すと、リンクし直すことになる）

### 更新 / 手順 2: 本文中の記録

   - `Dropbox command-line interface version:` の行が新しい版になる（2026-09-27 の時点では `2026.05.06` のまま）

### ロールバック / 手順 4: 本文中の記録

   - 先頭の `if` は、デーモンが動いている間に貼ったときに、クラウドのファイルまで消えるのを防ぐ（コンテナで、動いている間は `中断:` が出て何も消えないことを確かめた）

### 対象と検証環境

- **目的**: x86_64 の AlmaLinux 10 で Dropbox の公式クライアントを headless で動かし、ログインしていない間も `~/Dropbox` をクラウドと同期し続ける
- **進め方**: 公式の tarball を、署名を確かめてから `~/.dropbox-dist` に展開する。操作用の `dropbox.py` を `~/.local/bin` に置き、自分で書いた systemd のユーザーサービスと、前提の [linger](../linger.md)（`loginctl enable-linger`）で常駐させる。**読者が書き換える変数は無い**
- **状態**: **x86_64 の VM で実施手順 1〜7を検証済み（2026-10-06）。アカウントのリンクと同期は未確認。実機には入れていない**
  - VM の実測は[今回の付録](#付録-vm-での検証記録2026-10-06)。以下のコンテナでの結果と未確認事項は、当時の検証範囲の記録。
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**、手順 1〜7・9・[更新](../dropbox.md#更新)・[ロールバック](../extra/dropbox.md#ロールバック)を通した
    - linger の有効化と解除（今の [linger.md](../linger.md) の手順 2 とロールバック。当時はこの文書の手順 6・7 とロールバックの手順 1・3）も、このとき通した
  - 確認したこと:
    - 署名が合えば展開され、版が食い違って `BAD signature` のときは展開されない
    - デーモンがユーザーサービスとして動き、`dropbox status` がリンク用の URL を出す（検証のときだけサービスにプロキシを渡した）
    - `dropbox stop` では 10 秒後に戻り、`systemctl --user stop` では止まったまま
    - ロールバックで元に戻り、デーモンが動いている間はロールバックの手順 4 が `中断:` で止まる
  - **確認していないこと**: アカウントのリンク、リンクした後の同期と `exclude` などの操作、デーモンの自己更新、GNOME のデスクトップでの挙動、SELinux が Enforcing の実機での動作、再起動後の自動起動

| 項目 | 実機（x86_64 PC） | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-27 |
| OS | AlmaLinux 10.2 (Lavender Lion) / x86_64 | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/10-init:10.2`、Docker 29.3.1、`--privileged`、systemd を PID 1） |
| systemd | — | `systemd-257-23.el10_2.2.alma.1` |
| Dropbox | 未導入 | デーモン 270.4.3312、CLI 2026.05.06 |
| gnupg2 | GNOME のデスクトップには入っている | 未導入だったので、手順 2 の箇条書きのとおり入れた（`gnupg2-2.4.5-4.el10_1`） |
| ホームのファイルシステム | 未確認 | ext4（ホストのディレクトリを bind mount した） |

> [!NOTE]
> 出力例・ログの値は `<USER>`（OS のアカウント名）/ `<HOSTNAME>` / `<NONCE>`（リンク用 URL の、1 回限りの値）のプレースホルダで書いてある。版（`270.4.3312`）は、実行日と配信の振り分けで変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

検証コンテナの状態:

| 項目 | 状態 |
|---|---|
| Dropbox | 未導入（`~/.dropbox-dist`・`~/.dropbox`・`~/Dropbox` のどれも無い） |
| gnupg2 | 未導入（`gpg` も `gpgv` も無い） |
| `~/.local/bin` | 無い（`~/.bashrc` が PATH には足している） |
| linger | `Linger=no` |

### 選択した方針

x86_64 の AlmaLinux 10 で Dropbox の公式クライアントを入れる経路を比べた（2026-09-27 時点）:

### 完了時点の状態

**検証コンテナでの出力**（手順 9 の直後。リンクはしていない）:

```
$ dropbox version
Dropbox daemon version: 270.4.3312
Dropbox command-line interface version: 2026.05.06
$ systemctl --user status dropbox.service --no-pager
● dropbox.service - Dropbox (headless)
     Loaded: loaded (/home/<USER>/.config/systemd/user/dropbox.service; enabled; preset: disabled)
     Active: active (running) since Sun 2026-09-27 15:56:06 UTC; 23s ago
   Main PID: 1997 (dropbox)
     CGroup: .../user.slice/user-1000.slice/user@1000.service/app.slice/dropbox.service
             └─1997 /home/<USER>/.dropbox-dist/dropbox-lnx.x86_64-270.4.3312/dropbox
$ loginctl show-user 1000 -p Linger
Linger=yes
```

### 注意点 / 手順 0: 本文中の記録

  - 使うなら `sudo firewall-cmd --permanent --add-service=dropbox-lansync` と `sudo firewall-cmd --reload`（本書では試していない）

### 注意点 / 手順 0: 本文中の記録

- **自己更新**: リンクしていない古い版（268.4.4124）を 8 分動かしたが、入れ替わらなかった（[付録](#付録-コンテナでの検証記録2026-09-27)）。更新されているかは、ときどき `dropbox version` で見る

### 付録: コンテナでの検証記録（2026-09-27）

`quay.io/almalinuxorg/10-init:10.2`（`sha256:a91c1066…fd73`）を x86_64 のクラウドホスト上の Docker 29.3.1（cgroup v1）で `--privileged`・`--network host` で立て、systemd を PID 1 で動かした。実機で加えた変更は無い。

検証の準備（手順書の外）:

- イメージが mask している `systemd-logind` を戻した
- イメージが削っていた `/var/log/journal` を、パッケージの既定どおり作った（無いと journal が永続化されず、`journalctl --user` が権限不足で何も読めなかった）
- プロキシの CA を信頼ストアに足した
- 非 root ユーザー（uid 1000、NOPASSWD の sudo）を作り、ホームはホストの ext4 のディレクトリを bind mount した

途中で手順 3 と手順 7 のブロックを直したので、書き上げた後に、コードブロックを文書から直接抜き出して手順 1〜7・9（と、今の [linger.md](../linger.md) に移した linger の手順）・更新・ロールバックをもう一度通した（下の表の結果と同じになった。手順 2 は `gnupg2` を入れた後なのでそのまま通り、手順 7 は再起動から 23 秒で URL が出た）。

実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、手順ごとに `docker exec` で、そのユーザーのログインシェル（`bash -l`）へ標準入力から流した。`docker exec` はログインセッションを作らないので、`XDG_RUNTIME_DIR` と `DBUS_SESSION_BUS_ADDRESS` を渡して `systemctl --user` を使えるようにした。

| 手順 | 結果 |
|---|---|
| 1 | `x86_64` / `ext2/ext3` / `Avail` 30G |
| 2 | `gpg: command not found`（終了コード 127）。箇条書きのとおり `sudo dnf install -y gnupg2`（依存込み 6 パッケージ）を入れて貼り直し、fingerprint と uid が一致した |
| 3（最初の版） | tarball と署名を別々の URL で落とす形で流したら、`gpgv: BAD signature` になり、`&&` の後ろの `tar` は動かなかった。落ちてきた tarball は 91,224,009 バイトで中の `VERSION` が `272.3.3756`、署名は `270.4.3312` のものだった。**`download?plat=lnx.x86_64` の飛び先は 30 回中 29 回が 270.4.3312、1 回が 272.3.3756** で、この食い違いが原因。手順 3 を、飛び先を 1 回だけ引く形に直した |
| 3 | `Good signature`、`~/.dropbox-dist` に展開された |
| 4 | `VERSION` / `dropbox-lnx.x86_64-270.4.3312` / `dropboxd`、`153M`。同梱のライブラリの `ldd` に `not found` は無かった |
| 5 | `/home/<USER>/.local/bin/dropbox`、`Dropbox daemon version: 270.4.3312`、`Dropbox command-line interface version: 2026.05.06`。`dropbox.py` の中の鍵も同じ fingerprint だった |
| linger.md 2 | 無出力、終了コード 0。`user@1000.service` が `active` になった |
| 6（当時は linger.md 3 の確認も同じブロック） | `Linger=yes` / `enabled` / `active`。`Main PID` は本体の `dropbox` |
| 7 | サービスにプロキシを渡さないうちは、`dropbox status` は `Connecting...` で、20 秒待っても journal にリンクの行は出なかった（コンテナはプロキシを通さないと外に出られない）。検証のためだけに `~/.config/systemd/user/dropbox.service.d/` にプロキシの環境変数の drop-in を置いて再起動すると、17〜23 秒で `dropbox status` がリンク用の URL を出した。このとき手順 7 のブロックの `sleep 15`（最初の版）では `Connecting...` だったので、`sleep 30` にした |
| 9 | リンクしていないので、`dropbox status` は URL の案内のまま、`ls ~/Dropbox` は `No such file or directory` |
| 使い方の基本 | 表のコマンドを実行した。リンクしていないので、`exclude add` / `exclude remove` / `lansync n` は無出力、`exclude list` は `Dropbox isn't responding!`（1 度だけ Python のトレースバックで落ちた）、`filestatus` は `File doesn't exist`、`sharelink` は `... does not exist`。`help` と `help exclude` は使い方を出し、`journalctl -f` はリンク用の URL の行を追った |
| 停止の挙動 | `dropbox stop` の直後は `ActiveState=activating` / `SubState=auto-restart` / `Result=success`、15 秒後に `NRestarts=1` で別の PID になった。`systemctl --user stop` の後は 15 秒たっても `inactive` で、`dropbox status` は `Dropbox isn't running!` |
| 自己更新（手順書の外） | サービスを止めて、署名を確かめた 268.4.4124 に入れ替えて起動し、8 分待ったが、`~/.dropbox-dist` は 268.4.4124 のままだった（リンクしていない。更新の間隔も分からない）。確かめた後、270.4.3312 に戻した |
| 更新 | `dropbox version` は手順 5 と同じ。dropbox.py を取り直しても `2026.05.06` のまま |
| 手での入れ直し | 署名を確かめた 268.4.4124 を入れてサービスで動かした状態から、更新の手順 1 の箇条書きのとおり止める → 手順 2〜4 → 動かすで、`dropbox version` と主プロセスが 270.4.3312 になった。古い 268.4.4124 のディレクトリは残り、`du` は `304M` になった |
| ロールバック | デーモンが動いている間に手順 4 を貼ると `中断: ...` が出て、`~/Dropbox`（目印のファイルを置いた）も `~/.dropbox` も残った。検証用の drop-in を消してから手順 1・3・4 と linger の解除（今の [linger.md のロールバック](../extra/linger.md#ロールバック)の手順 1・2。当時はこの文書の手順 1 の最後の `ls` と手順 3）を流すと、`Removed ...`、`ls` は無出力（終了コード 2。追加の確かめの後にもう一度流した回では 0）、`Linger=no`、`~/.dropbox-dist`・`~/.local/bin/dropbox`・`~/.dropbox`・`~/Dropbox` が消えた。空の `~/.config/systemd/user` と `~/.local/bin`、手順 2 の `~/.gnupg` は残った |

#### 未確認事項

- 実機（x86_64 PC）での導入
- アカウントのリンク（ブラウザでの承認）と、リンクした後の同期・`dropbox status` の表示
- リンクした後の `exclude` / `filestatus` / `sharelink` / `lansync` の動作
- デーモンの自己更新と、そのときの systemd（`Restart=always`）の振る舞い
- GNOME のデスクトップにログインしている PC での挙動（`UnsetEnvironment=` が効くか、トレイアイコンが出ないこと）
- SELinux が Enforcing の実機での動作
- 再起動後に、linger でサービスが自動で起動すること
- LAN 同期（`dropbox-lansync`）

---

### 付録: VM での検証記録（2026-10-06）

**環境**: [クリーンインストールからの検証記録](../almalinux-vm-verification.md)のコンテナ用 VM。公式 ISO から Workstation を入れた状態から始め、x86_64、SELinux Enforcing、firewalld 有効。本文のブロックを SSH の擬似端末で実行した。

- XFS のホームを持つクリーンインストール由来の VM で、linger を有効にした後、本文の手順 1〜7 を実行した。SELinux は Enforcing。
- 公式配布物の署名と鍵の fingerprint が合い、デーモン 272.4.3798 と CLI 2026.05.06 が入った。`~/.local/bin` から CLI を呼べた。
- ユーザーサービスが enabled / active になった。`dropbox status` は未リンクで starting を示し、リンク用 URL が出た。URL に含まれる認証値は記録に転載しない。
- VM の再起動後も未認証のサービスが active になった。サービス起動は 04:19:33、最初の SSH ログインは 04:20:12 で、ログイン前に起動した。アカウントのリンクや同期の結果ではない。
- アカウントをリンクしていないため、手順 8・9 のリンク・同期後の確認、自己更新、GNOME 上の挙動、更新・ロールバックは今回の確認に含めない。

---

### 付録: 現行版を新規 VM で再検証（2026-10-06）

**対象**: `setup-notes` の `5da3478` 版。公式 ISO で Workstation を入れた `clean-install` スナップショットから、新規の `alma10-current-20261006-containers` を作った。AlmaLinux 10.2 / x86_64 / SELinux Enforcing / firewalld 有効。共通 bash は `3d5323e` を新規導入した。以前の付録と別の試験で、現行ブロックを SSH の擬似端末で順に実行した。

実施手順 1〜6 を通した。x86_64 / XFS の専用ホームで、公開署名鍵の fingerprint を照合し、取得した 272.4.3798 の tarball に `Good signature` が出た。公式 CLI 2026.05.06 と本体が入り、ユーザーサービスは `enabled` / `active`。実アカウントへのリンク、同期、認証後の設定は行っていない。rclone の代役試験を始める前にこのサービスは停止した。

ロールバックの手順 1・3・4 で service、本体・CLI・設定、試験用ディレクトリを撤去した。実アカウントをリンクしていないので、手順 2 の Dropbox 側でのリンク解除は行っていない。

### 手順中の実測・検証状況の記録

- デーモンは、`~/.dropbox-dist` の中身を自分で入れ替えて更新する作り（tarball の README と `dropbox.py` の説明）。**本書では確かめていない**（[未確認事項](#未確認事項)）

### 実施手順 / 手順 4: 補足: 入るもの

- `~/.dropbox-dist/dropboxd` は起動用のシェルスクリプトで、版のディレクトリの `dropboxd` を `exec` する。それがさらに本体の `dropbox`（ELF）を `exec` するので、プロセスは 1 つのまま
- 中の ELF が外に求めるライブラリは glibc・libgcc_s・libstdc++ だけ（Python 3.11・libffi・libatomic は同梱）。Qt も GTK もリンクしていない
- コンテナでは、同梱のライブラリをすべて `ldd` に通して、`not found` は出なかった
- `VERSION` は末尾に改行が無いので、`cat` すると次の出力とつながる。版はディレクトリの名前で見る

### 実施手順 / 手順 6: 補足: unit の中身の理由

- **`Restart=always`**: デーモンが終了コード 0 で抜けても起こし直す
  - `dropbox stop` もデーモンを 0 で終わらせるので、10 秒後に戻る（コンテナで確認。`NRestarts=1` になった）。止めるときは `systemctl --user stop dropbox.service`
  - `Restart=on-failure` だと、0 で抜けたデーモンは起こし直されない。自己更新が 0 で抜けて入れ替わる作りでも止まらないように、`always` にした（自己更新そのものは確かめていない）
- **`UnsetEnvironment=`**: GNOME にログインしていると、ユーザーの systemd に `DISPLAY` などが入ることがある。それを引き継ぐと、デーモンが GUI の動作（トレイアイコンなど）に切り替わるので、常に headless で動かすために外す（GNOME での挙動は確かめていない）
- `network-online.target` は書かない（ユーザーの systemd からは使えない）。つながるまでは、デーモンが `Connecting...` のまま自分で待つ（コンテナで確認）
- `ExecStart` はシェルスクリプトの `dropboxd` だが、`exec` をつないでいるので、systemd の主プロセスは本体の `dropbox` になる（`Main PID: ... (dropbox)`）
- `dropbox start` は使わない。サービスを止めている間に実行すると、systemd の外でデーモンが立ち上がる

### 実施手順 / 手順 7: 補足: URL が出るまでの時間と、journal

コンテナでは、サービスの起動から URL が出るまで 17〜23 秒かかった。`sleep 15` では `Connecting...` のままだった。

```
$ dropbox status
Starting...
To link this computer to a Dropbox account, visit the following url:
https://www.dropbox.com/cli_link_nonce?nonce=<NONCE>
```

URL は、リンクするまで journal にも 5 秒ごとに出る:

```
$ journalctl --user -u dropbox.service -n 2 --no-pager
Sep 27 15:58:30 <HOSTNAME> dropboxd[2263]: This computer isn't linked to any Dropbox account...
Sep 27 15:58:30 <HOSTNAME> dropboxd[2263]: Please visit https://www.dropbox.com/cli_link_nonce?nonce=<NONCE> to link this device.
```

- 検証コンテナはプロキシを通さないと外に出られないので、検証のときだけサービスにプロキシの環境変数を渡した（本書の unit には入れていない）。渡さないうちは `Connecting...` のままだった
- 承認するときのブラウザの画面と、承認した後の表示は確かめていない

### 選択した方針

- **常駐はユーザーサービス + linger にした**
  - ファイルの持ち主として動かす
  - 公式の `autostart` は、GNOME へのログインで起動する形（RPM の `.desktop` が前提）で、ログインしている間しか動かない
- **headless で動かし、トレイアイコンは出さない**
  - 公式ヘルプによると、GNOME でトレイアイコンを出すには AppIndicator の拡張と `libappindicator-gtk3` が要る
  - EPEL 10 に `gnome-shell-extension-appindicator` と `libappindicator-gtk3` があるが、本書では入れていない

### 手順中の検証状況

- **リンクした後の表示は確かめていない**（コンテナではリンクしていない）

### 手順中の検証状況

- コンテナではリンクしていないので、表の `dropbox` のコマンドは本来の動作をしなかった。**リンクした後の動作は確かめていない**

### 手順中の検証状況

- **リンクすると全部落ちてくる**: headless では、最初に同期するフォルダを選べない。要らないフォルダは、リンクした直後に `dropbox exclude add` で外す（[使い方の基本](../dropbox.md#使い方の基本)。動作は確かめていない）

### 手順中の検証状況

- **SELinux**: Enforcing の実機では確かめていない。[syncthing.md](../syncthing.md) の実機では、ユーザーサービスは `unconfined` として動いた
