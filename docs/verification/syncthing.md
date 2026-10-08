# Syncthing インストール手順（AlmaLinux 10 は Homebrew + systemd ユーザーサービス / Windows 11 は公式の zip + タスク スケジューラ）の検証記録

[手順書](../syncthing.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順 / 手順 2: 本文中の記録

   - 版は手順 4 で確かめる。検証した aarch64 の末尾は `[modernc-sqlite, noupgrade]`、x86_64 は `[noupgrade]`（意味はこの手順の補足）

### 実施手順 / 手順 4: 補足: 設定の置き場所とパスワードの渡し方

**設定と DB は `~/.local/state/syncthing`**（`$XDG_STATE_HOME/syncthing`）。1.27.0 で `~/.config/syncthing` から移った。古い版から引き継ぐときは元の場所も見に行く。この手順で作られる必須ファイルは次の 3 つ:

```
$ ls -la ~/.local/state/syncthing/
-rw-r--r--. 1 <USER> <USER>  623 cert.pem        # デバイス ID のもとになる証明書（新規 x86_64 VM の実測）
-rw-------. 1 <USER> <USER>  119 key.pem         # その秘密鍵
-rw-------. 1 <USER> <USER> 6613 config.xml      # 設定（GUI のユーザー名・パスワードハッシュ・API キーを含む）
```

**`--gui-password=-` は標準入力からパスワードを読む。**

- `--gui-password="..."` と直接書くと、その間だけとはいえ `ps` の出力とシェルの履歴に平文が残る。`printf` からのパイプにすればどちらにも残らない
- `config.xml` に入るのは bcrypt ハッシュで、平文は保存されない
- パスワードを後から変えるなら、GUI の Actions → Settings → GUI か、同じコマンドをもう一度（`syncthing generate` は既存の設定を壊さずに認証情報だけ更新する）

`syncthing generate` は `.syncthing.tmp.<数字>` という一時ファイルを残すことがある（[付録](#付録-実機での検証記録2026-09-24)）。消しても動作に影響はない。

### 実施手順 / 手順 6: 本文中の記録

   - 本手順は実機検証時と同様に再起動して確かめる。同じ版の Linux で、待ち受けと TLS は再起動前に変わった実測もある（[Windows 11 の節の補足](../syncthing.md#windows-11-で使う)）

### 実施手順 / 手順 6: 補足: 自己署名証明書と、別のやり方

**証明書は Syncthing が自分で作る自己署名のもの**（`https-cert.pem` / `https-key.pem`）。

- ブラウザは初回に警告を出すので、例外に追加して進む
- 自前の証明書を使いたいなら、設定ディレクトリのこの 2 ファイルを置き換えて再起動する（GUI からは差し替えられない）
- TLS を有効にすると、平文の `http://` で来た接続は **307 で `https://` に飛ばされる**（[付録](#付録-実機での検証記録2026-09-24)）。有効にしないと GUI のパスワードが LAN に平文で流れる

`syncthing cli` は起動中の Syncthing に REST API で話しかけるので、**サービスが動いている状態で実行する**。

- 設定ファイルから API キーを自分で読むため、キーを渡す必要はない
- プロパティ名は `syncthing cli config gui --help` で一覧できる（`raw-address` / `raw-use-tls` は `config.xml` の `<address>` / `tls` 属性に対応する）

待ち受けアドレスは環境変数 `STGUIADDRESS` でも上書きできる。`brew services` なら `~/.homebrew/services/syncthing.env` に `STGUIADDRESS=0.0.0.0:8384` と書く方式だが、設定が 2 か所に分かれるので本書では `config.xml` に寄せている。

### 実施手順 / 手順 7: 補足: 公開範囲と、自ホストからでは確認できないこと

定義の中身:

```
$ sudo firewall-cmd --info-service=syncthing
syncthing
  ports: 22000/tcp 22000/udp 21027/udp
$ sudo firewall-cmd --info-service=syncthing-gui
syncthing-gui
  ports: 8384/tcp
```

- 22000/tcp は同期本体、22000/udp は QUIC、21027/udp は同じ LAN にいる相手を見つけるためのブロードキャスト / マルチキャスト
- **公開範囲は public ゾーンの全 NIC**。この環境では `wg0` も public にあるので、VPN 越しの拠点からも 22000 と 8384 に届く。絞るなら[接続元を絞る（任意）](../syncthing.md#接続元を絞る任意)
- **自ホストからの `curl https://<SERVER_IP>:8384/` は firewalld を通らない**（ローカル宛のパケットは `lo` 経由で先に受理される）。開け忘れはサーバー上の確認では見つからないので、別ホストか network namespace から試す（[付録](#付録-実機での検証記録2026-09-24)）

### 設定を自動でバックアップする（任意） / 手順 0: 本文中の記録

- この節は**実機で本実行していない**。コンテナ（2026-09-27）と、クリーンインストールした x86_64 の VM（2026-10-06）で本実行した（[VM の記録](#付録-クリーンインストールした-vm-での検証2026-10-06)）

### 設定を自動でバックアップする（任意） / 手順 1: 補足: スクリプトの作り

**DB（`index-v2`）は入れない。**

- 2.x の DB は SQLite で、動いている間にファイルをコピーしても整合しない
- 無くても困らない。戻したあとの初回起動で全フォルダを読み直して作り直す（公式 FAQ の「My Syncthing database is corrupt」と同じ扱い）

**最新のアーカイブとの比べ方**

- アーカイブのメンバーの並びと、中身を連結した sha256 を、今のファイルと比べる。更新時刻は見ないので、`touch` だけでは新しいアーカイブにならない
- 最初は `cmp` で比べていたが、コンテナの AlmaLinux 10 には `diffutils`（`cmp` を含む）が入っておらず、`cmp: command not found` で比較が常に失敗して毎回作っていた（[付録](#付録-コンテナでのバックアップと復旧の検証2026-09-27)）
- 比較に失敗したときは「変わった」側に倒れる（新しいアーカイブを作る）

**そのほかの決めごと**

- **保存先を作らない**: 保存先を外付けディスクなどに変えたとき、外れた空のマウントポイントの下へ黙って書かないため。保存先はマウント先の下のディレクトリにしておくと、外れているときは失敗する
- **書きかけの名前**: `.syncthing.` で始まる名前は、Syncthing のスキャナが一時ファイルとして無視する（ソースの `lib/fs/tempname.go`）。書きかけのアーカイブが送信専用フォルダから相手に送られない
- **名前にホスト名を入れない**: 名前順＝時刻順で最新と古いものを決めている。OS を入れ直してホスト名が変わっても、順番が崩れない
- **100 個**: 1 個 3〜4 KB。path ユニットは設定を保存するたびに取るので、GUI で何度も保存するとすぐに数十個になる
- `set -e` の下で配列が空でも止まらないよう、`${old[-1]}` は個数を確かめてから読み、古いものの削除は `if` で書いている（`&&` で終えると、消すものが無いときに終了コードが 1 になる）

### 設定を自動でバックアップする（任意） / 手順 2: 補足: ユニットの作りと、systemd-analyze --user verify の落とし穴

**path ユニット**

- `PathChanged=` は、Syncthing が一時ファイルからの rename で `config.xml` を置き換えたときも、`tar -x` で上書きしたときも働いた（[付録](#付録-コンテナでのバックアップと復旧の検証2026-09-27)）
- path ユニットは、`.service` が動いている間の変更を拾わない。`ExecStartPre=/usr/bin/sleep 5` で 5 秒待ってから読むので、続けて書き換えられても最後の状態を取れる
- コンテナで 0.5 秒おきに 5 回変えたとき、アーカイブは 1 つだけで、中身は最後の設定だった
- それでも取りこぼしたとき（保存先が無かった、など）は、タイマーが拾う。`Persistent=true` なので、0 時台に止まっていたら次の起動のあとに走る

**`WantedBy=`**

- ユーザーの `basic.target` が `paths.target` と `timers.target` を引く（`/usr/lib/systemd/user/basic.target` の `Wants=`）
- linger でユーザーの systemd が上がったときにも有効になる。コンテナを再起動し、ログインしないまま両方が `active` になることを確かめた

**`systemd-analyze --user verify` を実行すると、`systemctl --user` が `Connection refused` になる。**

- 検査そのものは通る（3 つとも何も出さずに終了コード 0）
- ただし systemd 257 では、`$XDG_RUNTIME_DIR/systemd/private` を置き換えてしまう。以後 `systemctl --user`（`brew services` も）が `Failed to connect to user scope bus via local transport: Connection refused` で失敗する
- `sudo systemctl restart user@$(id -u).service` でユーザーの systemd を再起動するまで直らない（このとき Syncthing も再起動する）

### 設定を自動でバックアップする（任意） / 手順 3: 補足: 出力の例と、失敗の見方

コンテナでの出力（名前と日時は実行時のもの）:

```
Created symlink '/home/<USER>/.config/systemd/user/paths.target.wants/syncthing-backup.path' → '/home/<USER>/.config/systemd/user/syncthing-backup.path'.
Created symlink '/home/<USER>/.config/systemd/user/timers.target.wants/syncthing-backup.timer' → '/home/<USER>/.config/systemd/user/syncthing-backup.timer'.
Result=success
ExecMainStatus=0
active
active
NEXT                        LEFT LAST PASSED UNIT                   ACTIVATES
Mon 2026-09-28 00:47:31 UTC   8h -         - syncthing-backup.timer syncthing-backup.service
...
-rw------- 1 <USER> <USER> 3154 Sep 27 16:18 syncthing-config-20260927-161803.tar.gz
```

中身は `tar -tzvf ~/syncthing-backup/syncthing-config-<日時>.tar.gz` で見られる（`cert.pem`・`key.pem`・`config.xml`・`https-cert.pem`・`https-key.pem` の 5 つ）。

**失敗は `systemctl --user status syncthing-backup.service` で見る。**

- `Process:` の行に、`ExecStartPre` と `ExecStart` の終了コードが出る（保存先が無いときは `status=1/FAILURE`）
- `journalctl --user -u syncthing-backup.service` は、ユーザーの journal を読めない環境では何も出ない。コンテナでは `No journal files were opened due to insufficient permissions.` だった（実機でも `sh.brew.syncthing.service` について `No journal files were found.` の実測がある。[付録](#付録-実機での検証記録2026-09-24)）
- [linger](../linger.md) が有効なので、ログアウト中も path ユニットとタイマーは動く

### 設定を自動でバックアップする（任意） / 手順 4: 補足: 送信専用にする理由と、コマンドで入る値

**公式のドキュメント（Configuration の「Syncing Configuration Files」）が、この形を勧めている。**

- 設定ファイルを Syncthing でバックアップするなら、送信専用フォルダにする
- 相手側では、そのフォルダを相手自身の設定として使わない
- こちらは送るだけなので、相手側で何か変わっても、こちらのアーカイブは書き換わらない

**`folders add` で入る値**

- GUI で足したときの既定値（`config.xml` の `<defaults>` の `<folder>`）と比べると、違うのは `minDiskFree` が 0（既定は 1%）の 1 か所だけだった
- 送信専用フォルダは受け取らないので、この違いは効かない
- `--path` は `"${HOME}/syncthing-backup"` と書く。`--path=~/syncthing-backup` の形では、シェルが `~` を展開しない

**コンテナでは、同じコンテナの 2 つ目の Syncthing を相手に見立てた**（[付録](#付録-コンテナでのバックアップと復旧の検証2026-09-27)）。

- アーカイブが相手の受信専用フォルダに届いた
- こちらで 100 個を超えて消えたものは、相手でも消え、相手の `.stversions`（ゴミ箱）に残った
- 確かめた時点で、相手のフォルダに書きかけの `.syncthing.*.tmp` は無かった
- 共有と受け入れは CLI で同じ設定を入れた。GUI での操作は試していない

### バックアップから戻す / 手順 0: 本文中の記録

  - DB が空のフォルダには Syncthing が `.stfolder` を作るので、外れたままだと空のマウントポイントへ受け取り始める（ソースとコンテナの挙動からの推定で、外付けディスクでは試していない）

### バックアップから戻す / 手順 0: 本文中の記録

- この節は**実機で本実行していない**。コンテナ（2026-09-27）では OS を入れ直した相当も、x86_64 の VM（2026-10-06）では同じホストの設定復元を本実行した（[VM の記録](#付録-クリーンインストールした-vm-での検証2026-10-06)）

### ロールバック / 手順 0: 本文中の記録

- この節の手順 1〜3 は、クリーンインストールした x86_64 の VM 2 台で本実行した（2026-10-06）。実機では本実行していない

### Windows 11 で使う: 検証状況の記録

> [!WARNING]
> **この節と、後ろの Windows 11 の 3 節は、Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、配布物の中身と署名、Syncthing のソース、Linux の同じ版での CLI の動き、PowerShell の構文だけ（[対象と検証環境](#対象と検証環境)）。

### Windows 11 で使う / 手順 4: 補足: 確かめていることと、ブロックの作り

**sha256 と署名**

- `sha256sum.txt.asc` は、公式のリリースのファイルの sha256 の一覧（GPG で署名した平文）。その中の `syncthing-windows-<構成>-<版>.zip` の行と、取ってきた zip を比べる。GPG の署名はここでは確かめないので、この比較で分かるのは zip が壊れていないことまで
- 本物かどうかは、`syncthing.exe` の Authenticode の署名で確かめる。署名者は `CN=Kastelo AB`（Syncthing の開発元の会社）で、Microsoft の Trusted Signing の証明書。証明書の期限は 3 日と短いので、タイムスタンプが付いていること（`TimeStamperCertificate`）も見る（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）
- 署名者の名前は `CN=` の部分だけを見る（`L=` に ASCII でない文字があるため）

**ブロックの作り**

- 全体を `& { … }` で囲み、確かめられなかったら `return` でそこで止める（後ろの行を動かさない）
- 最新の版は、`releases/latest/download/sha256sum.txt.asc`（最新のリリースへ飛ぶ）の中の zip の名前から取る。版を調べるための別の問い合わせ（GitHub の API）はしない
- `curl.exe` は `C:\Windows\System32\curl.exe` を呼ぶ。Git for Windows や scoop の `curl` が `PATH` の先にある PC でも、同じものを使うため（[Windows の OpenSSH サーバー](../windows-openssh-server.md)の手順 7 の補足と同じ理由）
- `curl.exe` で取ったファイルには、ブラウザで取ったときのような「インターネットから来た」印（Mark of the Web）が付かないので、SmartScreen の確認は出ないはず（確かめていない）
- `%PROCESSOR_ARCHITECTURE%` が `AMD64` なら `amd64`、`ARM64` なら `arm64` の zip を取る。arm64 の版は試していない

**置き場所**

- `%LOCALAPPDATA%\Programs\Syncthing` は、自分のユーザーだけが使うプログラムの置き場所。Syncthing Windows Setup の個人用の導入も同じ場所を使う
- 置くのは `syncthing.exe` だけ（zip のほかのファイルは `README.txt` などと、Linux・macOS 向けの `etc/`）
- 管理者の PowerShell で作ったフォルダーとファイルは、所有者が `BUILTIN\Administrators` になるが、アクセス権は `%LOCALAPPDATA%` から受け継ぐので、自分のユーザー（管理者ではない Syncthing）も書き換えられる。それを `icacls` で確かめる

### Windows 11 で使う / 手順 6: 補足: パスワードの渡し方と、作られるもの

**パスワードは標準入力で渡す**（`--gui-password=-`）。

- コマンドラインに書くと、その間だけとはいえ、ほかのプロセスからコマンドラインが見える。AlmaLinux 10 の[手順 4](../syncthing.md#実施手順)と同じ渡し方
- Windows PowerShell 5.1 は、文字列をパイプで渡すときに、末尾に改行（CR LF）を足し、ASCII の文字コードで送る（`$OutputEncoding` の既定）。Syncthing は 1 行目だけを読み、末尾の CR LF を捨てる（ソースは `bufio.Reader.ReadLine`。Linux の同じ版で、CR LF 付きで渡したパスワードでログインできた。[付録](#付録-windows-11-の-cli-と-powershell-のブロックの-linux-での確認2026-10-03)）
- ASCII でない文字は `?` に置き換わって送られるはずなので、先に弾いている（`-cmatch` は大文字と小文字を区別する比較。区別しない `-match` だと、ケルビン記号などが通る）
- `config.xml` に入るのは bcrypt のハッシュで、平文は残らない

**作られるもの**（`%LOCALAPPDATA%\Syncthing`）

- `cert.pem` / `key.pem`（デバイス ID のもとになる証明書と秘密鍵）と `config.xml`（設定。GUI のログイン名・パスワードのハッシュ・API キーを含む）
- Linux の同じ版では、`.syncthing.tmp.<数字>` という空の一時ファイルも残った（消してよい）
- 新規導入の GUI は `127.0.0.1:8384`（この PC からだけ）。設定を残した再導入では、元の待ち受け・TLS・フォルダの設定を引き継ぐ

### Windows 11 で使う / 手順 10: 補足: syncthing cli と、起動し直さなくてよい理由

- `syncthing cli` は、動いている Syncthing に REST API で話しかける。API キーは `config.xml` から自分で読むので、渡さなくてよい（AlmaLinux 10 の[手順 6](../syncthing.md#実施手順)の補足と同じ）
- Linux の同じ版（2.1.5）では、この 2 つを入れた直後から、起動し直さずに `0.0.0.0:8384` で HTTPS の待ち受けに変わった（平文の `http://` は 307 で `https://` へ飛ばされた。[付録](#付録-windows-11-の-cli-と-powershell-のブロックの-linux-での確認2026-10-03)）
- 証明書は Syncthing が作る自己署名のもの（`%LOCALAPPDATA%\Syncthing\https-cert.pem`）。ブラウザは警告を出す
- Go は `0.0.0.0` の待ち受けを IPv4 と IPv6 の両方で開くので、`Get-NetTCPConnection` では `::` と出るはず（確かめていない）

### Windows 11 で使う / 手順 11: 補足: ログと、自分の PC から開いた GUI

- Windows の Syncthing は、ログを `%LOCALAPPDATA%\Syncthing\syncthing.log` に書く（10 MiB ごとに切り替え、古いものを 3 つ残す。ソースの既定値）。文字コードは UTF-8 なので、`-Encoding UTF8` を付けて読む（付けないと、Windows PowerShell 5.1 は日本語の Windows の既定の文字コードで読む）
- この PC のブラウザで `https://127.0.0.1:8384/` を開いても GUI は使えるが、ファイアウォールを通らないので、この節の手順 7 の規則を確かめたことにはならない（AlmaLinux 10 の[手順 7](../syncthing.md#実施手順)の補足と同じ）

### Windows 11 の更新 / 手順 2: 補足: 更新の動き

- 自動の更新の間隔は、設定の `autoUpgradeIntervalH`（既定 12）。0 にすると自動では上げない（GUI の Actions → Settings → General の「自動アップグレード」でも変えられる）
- 更新では、実行ファイルのフォルダーに一時ファイルを書き、前の `syncthing.exe.old` を消し、動いている `syncthing.exe` を `syncthing.exe.old` に名前を変え、新しいものを置く（ソースの `lib/upgrade/upgrade_supported.go`）。子は終了コード 4 で終わり、Windows では親（モニター）が新しい親を起動してから終わる（ソースの `restartMonitorWindows`）。そのため、タスクが起動した親はいなくなり、タスクは `Ready` になる
- 更新したことはログに `Automatically upgraded` と出る
- 本書では、新しい版が出ていないので、更新を試していない（[対象と検証環境](#対象と検証環境)）

### 対象と検証環境

- **目的**: AlmaLinux 10 と Windows 11 に [Syncthing](https://syncthing.net/) の最新版を入れ、互いに（ほかの端末とも）フォルダを同期する。Web GUI は LAN からも開けるようにする
  - AlmaLinux 10 では、ログインしていない間も動き続けるファイル同期デーモンにする
  - Windows 11 では、サインインしている間だけ動かす
- **進め方**: どちらも **GUI の認証を先に設定してから**待ち受けを LAN に広げる。読者が書き換える値は無い（既定のままで通る）
  - **AlmaLinux 10**（[実施手順](../syncthing.md#実施手順)）: Homebrew で入れ、`brew services` が作る systemd ユーザーサービスと、前提の [linger](../linger.md)（`loginctl enable-linger`）で常駐させる。最後に firewalld を開ける
  - **Windows 11**（[Windows 11 で使う](../syncthing.md#windows-11-で使う)）: 公式の zip の `syncthing.exe` を `%LOCALAPPDATA%\Programs\Syncthing` に置き、タスク スケジューラのタスクで、サインインしている間だけ動かす
    - 受信の規則は、最初の起動より前に作る
    - 更新は、Syncthing 自身の自動の更新に任せる
    - すべて管理者の Windows PowerShell 5.1 に貼る
- **状態（AlmaLinux 10）**: **実機で本実行済み（2026-09-24）。クリーンインストールした x86_64 の VM でも現行ブロックと、設定バックアップ・同じホストへの復元を本実行した（2026-10-06）**
  - 2026-10-06: 先行検証とは別の新規 VM で現行本文を再検証した（[今回の記録](#付録-新規-vm-での現行手順の再検証2026-10-06)）。検証専用のアカウント・鍵・隔離 LAN を使った
  - 下表のホストで、AlmaLinux 10 の各手順のコマンドを上から順に実行した。AlmaLinux 10 の手順はその実測をもとに書き起こしたもので、コードブロックを機械的に貼り直してはいない
    - linger の有効化（今の [linger.md](../linger.md) の手順 2 の最初の 2 行。当時はこの文書の手順 5 と、次の手順の 1 行目だった）も、このとき通した
  - 結果として、次の状態になっている
    - `syncthing 2.1.5`（Homebrew、`arm64_linux` のボトル）が入っている
    - `sh.brew.syncthing.service` が `enabled` / `active`
    - 8384/tcp・22000/tcp が `LISTEN`、22000/udp・21027/udp が `UNCONN`
    - firewalld に `syncthing` と `syncthing-gui` が入っている
  - **firewalld 越しの到達は、network namespace から 8384/tcp と 22000/tcp について確認済み**（[付録](#付録-実機での検証記録2026-09-24)）
  - このホストは**一度構築したあとクリーンインストールした直後**の環境で、Homebrew に formula が 1 本も入っていない状態から始めている
  - **2026-09-24 の実機で本実行していないこと**: ブラウザでの GUI ログイン、別デバイスとの実際の同期（フォルダ共有・競合処理）、再起動後の自動起動、21027/udp と 22000/udp の実疎通、[接続元を絞る（任意）](../syncthing.md#接続元を絞る任意)、ロールバック
  - **バックアップと復旧の 2 節は、コンテナのみで検証した（2026-09-27）**
    - 対象は[設定を自動でバックアップする（任意）](../syncthing.md#設定を自動でバックアップする任意)と[バックアップから戻す](../syncthing.md#バックアップから戻す)、[手順 4](../syncthing.md#実施手順)・[手順 9](../syncthing.md#実施手順) に足した「戻したホスト」の箇条書き
    - AlmaLinux 10.2 x86_64 のコンテナ（systemd を PID 1）に Homebrew と `syncthing 2.1.5` を入れ、実施手順 1〜6（と、[linger.md](../linger.md) に移した linger の有効化）のあとに両節のコードブロックを貼って通した（[付録](#付録-コンテナでのバックアップと復旧の検証2026-09-27)）
    - 確認したこと: path ユニットとタイマーで取れる、中身が同じなら作らない、100 個を超えたら古いものから消す、送信専用フォルダから受信専用の相手（同じコンテナの 2 つ目の Syncthing）へ届く、同じホストで戻せる、新しいコンテナで戻すとデバイス ID・API キー・フォルダが戻って中身が相手から届く
    - 確認していないこと: 実機（aarch64 を含む）、別のマシンの相手、GUI での共有と受け入れ、実際の 0 時台のタイマーと `Persistent=true` の追いかけ実行
  - 2026-09-28: 手順 7 のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../writing-guide.md#記法)）
    - 中のコマンドは変えていない。囲んだ形は構文の検査だけで、流していない
  - 2026-10-05: 必須入力と認証成功の確認、localhost の案内、復旧時の入力確認、Homebrew の完了待ちを修正した
    - 空のログイン名・空パスワード・`generate` 失敗・成功の 4 通りをスタブで確認し、失敗時はサービス起動・GUI 変更・firewalld の開放へ進まなかった
    - localhost（LAN の IP が空の場合も）・全 NIC・特定 IP の URL をスタブで確認した。変更した bash ブロックは構文検査済みで、実機には適用していない
- **状態（Windows 11）**: **Windows の実機では流していない（未検証。2026-10-03 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）:
    - 配布物: 2.1.5 の Windows の zip の中身、`sha256sum.txt.asc` の行との一致（その GPG の署名も）、`syncthing.exe` の Authenticode の署名者・証明書の連なり・タイムスタンプ・埋め込みの設定（`consoleAllocationPolicy`）。Linux で PE を読んだだけで、Windows の `Get-AuthenticodeSignature` は通していない
    - Syncthing 2.1.5 のソース: 設定とログの場所、`--no-console`、`generate` のパスワードの読み方、モニターの起動し直しと自動の更新の動き
    - Linux の公式の tarball の同じ版（2.1.5）での CLI（[付録](#付録-windows-11-の-cli-と-powershell-のブロックの-linux-での確認2026-10-03)）: CR LF 付きのパスワードの `generate`、[Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 10 の 4 つのコマンドと起動し直さずに変わること、`cli operations restart` / `shutdown` / `upgrade`（新しい版が無いとき）、`upgrade --check-only`
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査（構文とコマンドの引数だけ）。[Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 4・6 のブロックは、Linux の pwsh で偽物の署名と Linux の `syncthing` を使って流した（同じ付録）
  - **確かめていないこと**: Windows で貼ること（すべての手順）、タスクの登録と起動・サインインでの起動・サインアウトで止まること、受信の規則と警告の窓、LAN の別の端末からの GUI と同期、自動の更新とその後のタスクの状態、arm64 の Windows、24H2 より前の Windows
  - 2026-10-03: 別の手順書（`docs/windows-syncthing.md`）として書いたものを、同じ日にこの文書の Windows 11 の節へ移した。コマンドは変えていない（手順の番号も節の中で同じ）
  - 2026-10-03（後）: LAN をプライベートにする操作を [Windows 11 の初期設定の手順 43](../windows-setup.md#実施手順) へ移し、この節の手順 7 を確かめてから規則を作る形に、[Windows 11 のロールバック](../syncthing.md#windows-11-のロールバック)の手順 4 をそこを指す手順に変えた。手順 7 の今のブロックも、構文の検査と、偽物の `Get-NetConnectionProfile` での模擬だけ
  - 2026-10-05: 設定を残した再導入の確認条件と、参照先の Windows の版を訂正した。Windows のコマンドは変更せず、実機未検証のまま

AlmaLinux 10 の実機:

| 項目 | 値 |
|---|---|
| 実施日 | 2026-09-24 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi） |
| カーネル | 6.12.96 |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`。formula 0 本の状態から開始） |
| 入った Syncthing | `syncthing 2.1.5`（`syncthing v2.1.5 "Hafnium Hornet" (go1.27.1 linux-arm64) ... [modernc-sqlite, noupgrade]`） |
| 依存で入ったもの | 無し（静的バイナリ 1 つ、25 ファイル / 30.3 MB） |
| systemd | 257。unit は `~/.config/systemd/user/sh.brew.syncthing.service`（Homebrew 生成） |
| firewalld | 2.4.3。既定ゾーン `public` に `end0` と `wg0` |
| SELinux | Enforcing（サービスは `unconfined` のユーザーサービスとして動く） |
| NIC | `end0` = <SERVER_IP>/24、`wg0` = <WG_IP>/30（ともに public ゾーン） |
| デスクトップ | GNOME 49.4 / `graphical.target` |

Windows 11 の手順が前提にしている環境（ほかの Windows の手順書の実機の記録と同じ PC を想定）:

| 項目 | 値 |
|---|---|
| OS | Windows 11（24H2 以降。[Windows の OpenSSH サーバー](../windows-openssh-server.md)の実機記録は 25H2） |
| PowerShell | Windows PowerShell 5.1（管理者として実行） |
| ユーザー | Administrators の一員（Microsoft アカウントでもローカル アカウントでもよい） |
| Syncthing | 2.1.5（2026-09-08。`syncthing-windows-amd64-v2.1.5.zip`） |
| ネットワーク | LAN の接続（[Windows 11 の初期設定の手順 43](../windows-setup.md#実施手順) でプライベートにする） |

> [!NOTE]
> 環境固有の値は**変数**で書いてある。AlmaLinux 10 は[手順 1](../syncthing.md#実施手順)のシェル変数、Windows 11 は[Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 2 の PowerShell の変数に 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${ST_GUI_USER}` | Web GUI のログイン名。OS のアカウントとは別物（自動で同じ名前が入る） | `<USER>` |
> | `${ST_GUI_ADDR}` | GUI の待ち受けアドレス | `0.0.0.0:8384`（既定）/ `127.0.0.1:8384` |
> | `${ST_LAN_IP}` | 案内と検証にだけ使う LAN 側 IP（デフォルト経路の送信元から自動で入る） | `192.168.1.10` |
> | `${ST_ALLOW_FROM}` | 送信元サブネットのリスト（空白区切り）。[接続元を絞る](../syncthing.md#接続元を絞る任意)場合だけ、その節の冒頭で設定する | `192.168.1.0/24 10.99.0.0/30` |
> | `${ST_BACKUP}` | 戻すアーカイブ。[バックアップから戻す](../syncthing.md#バックアップから戻す)場合だけ、その節の手順 4 で設定する（自動で最新が入る） | `~/syncthing-backup/syncthing-config-<日時>.tar.gz` |
> | `$ST_GUI_USER` | Windows 11 の Web GUI のログイン名。Windows のアカウントとは別物（自動で同じ名前が入る）。[Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 2 で設定する | `<WIN_USER>` |
> | `$LAN_IF` | Windows 11 で、相手とつながる LAN の接続の名前（自動で入る）。[Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 2 で設定する | `イーサネット` |
> | `$ST_GUI_PASS` | Windows 11 の GUI のパスワード。[Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 5 で読み取り、手順 6 で消す | — |
>
> 出力例・ログ・表の中の値は `<HOSTNAME>`（Windows ではコンピューター名）/ `<SERVER_IP>` / `<WG_IP>`（`wg0` のアドレス）/ `<USER>`（OS アカウント名）/ `<WIN_USER>`（Windows のユーザー名）/ `<LAN_IF>` / `<IP>` / `<DEVICE_ID>` / `<APIKEY>` のプレースホルダで書いてある。バージョン（`2.1.5`）は実行日によって変わる。
>
> **GUI のパスワードと API キーはこの文書に載せない。** デバイス ID は公開してよい値だが、実機のものはプレースホルダにしてある。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

AlmaLinux 10 の実機（2026-09-24）。Windows 11 の PC は、[Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 3 で確かめる。

| 項目 | 状態 |
|---|---|
| Syncthing | 未導入（`syncthing` 無し、RPM も無し、`~/.local/state/syncthing` と `~/.config/syncthing` も無し） |
| Homebrew | 7.0.6 が `/home/linuxbrew/.linuxbrew` に導入済み。**formula は 0 本**（`~/.bashrc` に `brew shellenv` の行だけ） |
| 8384 / 22000 / 21027 の LISTEN | 無し |
| firewalld | active、default zone = `public`、`end0` と `wg0` が所属。services: `cockpit dhcpv6-client rdp ssh`、ports: `22/tcp 445/tcp 51820/udp` |
| linger | `Linger=no`（`/var/lib/systemd/linger/` は空）。`~/.config/systemd/user/` も未作成 |
| EPEL | 未設定（`epel-release` も未導入） |
| Go | 未導入（`go` 無し、`golang` RPM も無し） |

[samba.md](../samba.md) の「実施前の状態」には firewalld の ports に `8384/tcp` が載っているが、**あれはクリーンインストール前の環境の記録**で、今回の実施前には開いていない。

### 選択した方針

AlmaLinux 10 / aarch64 で Syncthing を入れる経路を比べた（2026-09-24 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew の `syncthing`** | `2.1.5`。上流の最新リリース（v2.1.5、2026-09-08）と一致。`arm64_linux` のボトルがあるのでビルド不要。更新は `brew upgrade` | **採用** |
| EPEL 10 の `syncthing` | `syncthing-2.1.3-1.el10_3.aarch64`。`epel-release` は AlmaLinux の extras から入るので導入自体は容易で、systemd unit も同梱される。ただし 2 パッチぶん古い | 不採用（最新版ではない） |
| 公式の tarball（`release.syncthingcdn.net`） | `2.1.5`。公式の unit（`etc/linux-systemd/user/syncthing.service`）が付き、自己アップグレード機能も使える。配置も更新も手作業 | 不採用（更新が手作業になる） |
| 公式の RPM リポジトリ | **存在しない。** 公式が維持しているのは Debian / Ubuntu 向けの `apt.syncthing.net` だけ | — |

Windows 11 で Syncthing を入れる経路を比べた（2026-10-03 時点。中身はどれも公式の `syncthing.exe`）:

- **Windows 11 では、固定の場所に置き、Syncthing 自身に更新させた**
  - タスクの実行ファイルと、受信の規則のプログラムが、更新の後も同じパスを指す
  - 自動の更新は、入れ替える前にリリースの署名を確かめる。稼働中に定期確認するので、`winget upgrade` や `scoop update` を自分で走らせなくてよい
  - 初回だけは本書が取ってくるので、sha256 と Authenticode の署名を確かめてから置く（[Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 4）
  - AlmaLinux 10 の Homebrew 版は逆に、Syncthing 自身の更新を切ってある（`noupgrade`。[注意点](../syncthing.md#注意点)）
- **Windows 11 では、サインインしている間だけ、タスク スケジューラで動かした**
  - Syncthing の公式の説明は、タスク スケジューラ（「ユーザーがログオンしているかどうかにかかわらず実行する」とパスワードの保存）か、スタートアップのフォルダーのショートカット。サービスにするのは、ほとんどの使い方では勧めていない
  - 本書は、利用者の使い方（サインインしている間だけ同期すればよい）に合わせて `-LogonType Interactive` にし、パスワードを保存しない
  - スタートアップのフォルダーより、タスクの方が、電池・実行時間・二重起動の設定と、`Start-ScheduledTask` での開始ができる
- **Windows 11 の受信の規則は、プログラムとプライベートに絞り、最初の起動より前に作った**（[Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 7 の補足）
  - 公式の説明の「一度対話で起動して、警告の窓で許可する」は、窓でキャンセルを押すと拒否の規則ができ、後から気付きにくい
- **Windows 11 でも GUI は LAN に公開した**（AlmaLinux 10 と同じく、認証 → 起動 → 待ち受けを広げる順）
  - この PC からだけ開くなら、[Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 10 を貼らない（`127.0.0.1:8384` のまま）。そのときは同じ節の手順 7 の `Syncthing-GUI-In-TCP` は要らない
- **ネットワークをプライベートにするのは、[Windows 11 の初期設定の手順 43](../windows-setup.md#実施手順)**
  - もとは [Windows の OpenSSH サーバー](../windows-openssh-server.md)の手順 5 と、この文書の Windows 11 の手順 7 の両方で同じ操作をしていた。2026-10-03 に、Windows のインストール直後の作業として Windows 11 の初期設定にまとめ、この文書は確かめるだけにした
  - そのため、[Windows 11 のロールバック](../syncthing.md#windows-11-のロールバック)の手順 4 は、OpenSSH サーバーを使っているなら飛ばす

- このホストは GNOME も入っていて、LAN 内の別 PC から触りたいので公開する方を採った

### 完了時点の状態

AlmaLinux 10 の実機（2026-09-24）。Windows 11 は流していないので、記録は無い。

```
$ syncthing --version
syncthing v2.1.5 "Hafnium Hornet" (go1.27.1 linux-arm64) linuxbrew@00f3194ed880 2026-09-08 06:57:55 UTC [modernc-sqlite, noupgrade]
$ brew services list
Name      Status User      File
syncthing started <USER>   ~/.config/systemd/user/sh.brew.syncthing.service
$ systemctl --user is-enabled sh.brew.syncthing.service
enabled
$ systemctl --user is-active sh.brew.syncthing.service
active
$ loginctl show-user 1000 -p Linger
Linger=yes
$ ss -ltunp | grep -E ':(8384|22000|21027)'
udp UNCONN 0 0   0.0.0.0:21027 0.0.0.0:* users:(("syncthing",pid=12157,fd=14))
udp UNCONN 0 0         *:21027       *:* users:(("syncthing",pid=12157,fd=13))
udp UNCONN 0 0         *:22000       *:* users:(("syncthing",pid=12157,fd=15))
tcp LISTEN 0 4096      *:8384        *:* users:(("syncthing",pid=12157,fd=21))
tcp LISTEN 0 4096      *:22000       *:* users:(("syncthing",pid=12157,fd=18))
$ sudo firewall-cmd --list-services
cockpit dhcpv6-client rdp ssh syncthing syncthing-gui
$ ls ~/.local/state/syncthing/
cert.pem  config.xml  https-cert.pem  https-key.pem  index-v2  key.pem  syncthing.lock
$ syncthing cli config folders list
(空。フォルダーは 1 つも無い)
```

- `index-v2` が 2.x の SQLite データベース
- `https-cert.pem` / `https-key.pem` は、手順 6 で TLS を有効にしたときに Syncthing が自分で作った自己署名証明書（`cert.pem` / `key.pem` はデバイス ID のもとになる別物）

`config.xml` の `<gui>` 節は次の形になっている（パスワードは bcrypt ハッシュ、API キーは伏せた）:

```
<gui enabled="true" tls="true" sendBasicAuthPrompt="false">
    <address>0.0.0.0:8384</address>
    <user><USER></user>
    <password>$2a$10$...</password>
    <apikey><APIKEY></apikey>
    <theme>default</theme>
    <sessionCookieDurationS>604800</sessionCookieDurationS>
</gui>
```

### 付録: 実機での検証記録（2026-09-24）

上記の手順を実機で本実行したときに取った記録。手順本文の根拠になった実測を残す。

#### ボトルが降りること

`brew install syncthing` はビルドに落ちず、`arm64_linux` のボトルをそのまま展開した:

```
==> Fetching downloads for: syncthing
✔︎ Bottle syncthing (2.1.5)
==> Pouring syncthing--2.1.5.arm64_linux.bottle.tar.gz
🍺  /home/linuxbrew/.linuxbrew/Cellar/syncthing/2.1.5: 25 files, 30.3MB
```

Go は導入していない（formula の `depends_on "go" => :build` はボトルを使う限り効かない）。

#### 初回起動のログ

`brew services start` 直後の `/home/linuxbrew/.linuxbrew/var/log/syncthing.log`（2.x の構造化ログ。`log.pkg=` が付く）:

```
INF syncthing v2.1.5 "Hafnium Hornet" (go1.27.1 linux-arm64) ... [modernc-sqlite, noupgrade] (log.pkg=main)
INF Calculated our device ID (device=<DEVICE_ID> log.pkg=syncthing)
INF Using discovery mechanism (identity="global discovery server https://discovery-lookup.syncthing.net/v2/?noannounce" log.pkg=discover)
INF Using discovery mechanism (identity="IPv4 local broadcast discovery on port 21027" log.pkg=discover)
INF Relay listener starting (id=dynamic+https://relays.syncthing.net/endpoint log.pkg=connections)
INF failed to sufficiently increase receive buffer size (was: 208 kiB, wanted: 7168 kiB, got: 416 kiB). ...
INF QUIC listener starting (address="[::]:22000" log.pkg=connections)
INF GUI and API listening (address=127.0.0.1:8384 log.pkg=api)
INF Loaded configuration (name=<HOSTNAME> log.pkg=syncthing)
INF Measured hashing performance (perf="1288.02 MB/s" log.pkg=syncthing)
```

`journalctl --user -u sh.brew.syncthing.service` は `No journal files were found.` になる（unit がファイルへリダイレクトしているため）。

#### TLS を有効にした前後

```
$ syncthing cli config gui raw-address get
127.0.0.1:8384
$ syncthing cli config gui raw-use-tls get
false
$ syncthing cli config gui raw-address set 0.0.0.0:8384
$ syncthing cli config gui raw-use-tls set true
$ brew services restart syncthing
$ ss -ltnp | grep 8384
LISTEN 0 4096 *:8384 *:* users:(("syncthing",pid=12157,fd=21))
```

再起動後のログは `GUI and API listening (address="[::]:8384")` と `Access the GUI via the following URL: https://127.0.0.1:8384/` に変わる。平文で叩くと HTTPS に飛ばされる:

```
$ curl -sk -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8384/
307
$ curl -sk -o /dev/null -w '%{http_code}\n' https://127.0.0.1:8384/
200
$ curl -sk -o /dev/null -w '%{http_code}\n' https://127.0.0.1:8384/rest/system/status
403
```

最後の 403 が、認証なしでは API を叩けないことの確認。API キーを付けると `myID` が `syncthing device-id` と一致する。

#### network namespace から firewalld 越しに到達する

自ホストから `https://<SERVER_IP>:8384/` を叩いてもローカル宛として処理され、firewalld を通らない。そこで veth で結んだ network namespace から接続した。ゾーン未割り当ての veth は既定ゾーン（public）の扱いになるので、public に開けたポートがそのまま効く（[samba.md](../samba.md) の付録と同じ手法）:

```bash
sudo ip netns add sttest
sudo ip link add veth-st type veth peer name veth-stns
sudo ip link set veth-stns netns sttest
sudo ip addr add 192.168.251.1/24 dev veth-st && sudo ip link set veth-st up
sudo ip netns exec sttest ip addr add 192.168.251.2/24 dev veth-stns
sudo ip netns exec sttest ip link set veth-stns up
```

結果:

```
$ sudo firewall-cmd --get-zone-of-interface=veth-st
no zone
$ sudo ip netns exec sttest curl -sk -o /dev/null -w '%{http_code}\n' --max-time 5 https://192.168.251.1:8384/
200
$ sudo ip netns exec sttest curl -sk -o /dev/null -w '%{http_code}\n' --max-time 5 https://192.168.251.1:8384/rest/system/status
403
$ sudo ip netns exec sttest timeout 5 bash -c 'exec 3<>/dev/tcp/192.168.251.1/22000'
（成功。出力なし）
$ sudo ip netns exec sttest timeout 5 bash -c 'exec 3<>/dev/tcp/192.168.251.1/9999'
bash: connect: No route to host
```

最後の 9999/tcp は対照。開けていないポートは `No route to host` で弾かれるので、**8384 と 22000 に届いたのは firewalld が実際に許可しているから**だと言える。後片付け:

```bash
sudo ip link del veth-st
sudo ip netns del sttest
```

#### `syncthing generate` が残す一時ファイル

手順 4 の直後、設定ディレクトリに `config.xml` と同じ大きさの一時ファイルが残っていた:

```
$ ls -la ~/.local/state/syncthing/
-rw-------. 1 <USER> <USER> 6613 .syncthing.tmp.229885971
-rw-------. 1 <USER> <USER> 6613 config.xml
```

Syncthing は設定を一時ファイルに書いてから `rename` する。その一時ファイルが残ったもので、以降の起動でも読まれない。消しても動作は変わらない。

#### 未確認事項

- ブラウザでの GUI ログイン（自己署名証明書の警告を越えて入るところ）
- 別デバイスとのペアリングと実際の同期（フォルダー共有、競合ファイル、`.stignore`）
- 再起動後に linger でサービスが自動起動すること（再起動していない）
- 21027/udp（ローカル探索）と 22000/udp（QUIC）の実疎通。TCP の 22000 と 8384 しか試していない
- VPN 越し（`wg0`）の相手デバイスとの接続
- [接続元を絞る（任意）](../syncthing.md#接続元を絞る任意)の rich rule
- ロールバック（`brew services stop` / `disable-linger` / `brew uninstall`）の本実行
- EPEL 版（2.1.3）との併用や、そこからの乗り換え
- 1.x からの DB 移行と、移行後に 1.x へ戻せるか（今回は新規導入なので移行そのものが走っていない）

---

### 付録: コンテナでのバックアップと復旧の検証（2026-09-27）

[設定を自動でバックアップする（任意）](../syncthing.md#設定を自動でバックアップする任意)と[バックアップから戻す](../syncthing.md#バックアップから戻す)を、コンテナで貼って通したときの記録。実機では試していない。

#### 環境

| 項目 | 値 |
|---|---|
| 実施日 | 2026-09-27 |
| 土台 | クラウド上の Docker 29.3.1（ホストは cgroup v1。ホストの `/sys/fs/cgroup/unified`（cgroup2）をコンテナの `/sys/fs/cgroup` に渡した） |
| コンテナ | `almalinux:10`（AlmaLinux 10.2、x86_64）を `--privileged --network host` で、`/sbin/init`（systemd 257）を PID 1 にして起動。イメージがマスクしている `systemd-logind` を戻し、`<USER>`（uid 1000）に `loginctl enable-linger` |
| Homebrew | 7.0.6（[homebrew.md](../almalinux-setup.md) と同じインストーラ） |
| Syncthing | `syncthing 2.1.5`（`x86_64_linux` のボトル。バージョン文字列の末尾は `[noupgrade]` で、aarch64 のボトルのような `modernc-sqlite` は付かない） |
| 相手の端末 | 同じコンテナの 2 つ目の Syncthing（`--home=~/peer`、`tcp://127.0.0.1:22001` で待ち受け、探索・リレー・NAT は切った） |
| 通していない手順 | [手順 7](../syncthing.md#実施手順)（firewalld を入れていない） |

実施手順 1〜6 と linger の有効化（今の [linger.md](../linger.md) の手順 2）のあと（手順 3 のパスワードはブロックに直接書いた）、両節のコードブロックをそのまま貼った。相手の端末での操作（共有の受け入れ、受信専用、ゴミ箱）は、GUI の代わりに `syncthing cli --home=~/peer config ...` で同じ設定を入れた。

#### スクリプトの動き

```
$ ~/.local/bin/syncthing-backup ~/syncthing-backup
作成: syncthing-config-20260927-161638.tar.gz
$ ~/.local/bin/syncthing-backup ~/syncthing-backup
変更なし: syncthing-config-20260927-161638.tar.gz
$ touch ~/.local/state/syncthing/config.xml; ~/.local/bin/syncthing-backup ~/syncthing-backup
変更なし: syncthing-config-20260927-161638.tar.gz
$ ~/.local/bin/syncthing-backup /nonexistent/dir; echo $?
保存先が無い: /nonexistent/dir
1
$ ls -d /nonexistent
ls: cannot access '/nonexistent': No such file or directory
```

- `https-key.pem` を一時的に動かすと、メンバーの並びが変わるので新しいアーカイブになった。戻すとまた新しいアーカイブになった
- 読み取り専用のディレクトリを保存先にすると、`tar` が `Cannot open: Permission denied` で失敗し、終了コードは 2。書きかけの `.syncthing.*.tmp` は残らなかった
- 105 個のダミー（`syncthing-config-20260101-000NNN.tar.gz`）を置いて走らせると、新しく作った 1 個を含む 100 個が残り、古い 6 個を `removed '...'` で消した
- ShellCheck 0.11.0 で 0 件（`bash -n` も通る）

**最初は `cmp` で比べていて、毎回作っていた。** 最小構成のイメージには `diffutils` が入っていない:

```
$ ~/.local/bin/syncthing-backup ~/syncthing-backup
/home/<USER>/.local/bin/syncthing-backup: line 21: cmp: command not found
作成: syncthing-config-20260927-161619.tar.gz
$ rpm -q diffutils
package diffutils is not installed
```

`if` の条件の中なので `set -e` でも止まらず、「変わった」側に倒れていた。比較を `sha256sum`（coreutils）と文字列の比較に替えた。

#### path ユニットとタイマー

GUI のテーマを変えて、`config.xml` を書き換えた:

```
$ syncthing cli config gui theme set dark
$ sleep 1; systemctl --user is-active syncthing-backup.service
activating
$ sleep 7; ls ~/syncthing-backup
syncthing-config-20260927-161803.tar.gz
syncthing-config-20260927-161817.tar.gz
```

- 0.5 秒おきに 5 回変えると、アーカイブは 1 つだけ増え、中身の `<theme>` は最後に入れた値だった（`ExecStartPre` の 5 秒の待ちの間に書き換えが終わる）
- 送受信フォルダ `docs` の追加と、その相手との共有を 1 秒の間に続けて入れたときも、アーカイブは 1 つだった。直後にスクリプトを手で走らせると「変更なし」で、両方の変更が入っていた
- `brew services restart syncthing` を 3 回続けても、アーカイブは増えなかった。起動では `config.xml` は書き換わらない（inode と更新時刻が同じ）
- `tar -x` で `config.xml` を上書きしたとき（[バックアップから戻す](../syncthing.md#バックアップから戻す)の手順 5）も、path ユニットが走った
- `docker restart` のあと、ログインしないまま `sh.brew.syncthing.service`・`syncthing-backup.path`・`syncthing-backup.timer` が `active` になった（linger）
- `systemd-analyze calendar daily` は `*-*-* 00:00:00`。`RandomizedDelaySec=1h` なので、`list-timers` の `NEXT` は 0:00〜1:00 のどこかになる（2 つのコンテナで 00:47 と 00:40）
- `journalctl --user -u syncthing-backup.service` は `No journal files were opened due to insufficient permissions.`（コンテナに `/var/log/journal` が無く、journal は揮発）。`systemctl --user status` の `Process:` の行には終了コードが出る

#### `systemd-analyze --user verify` で `systemctl --user` が使えなくなる

ユニットの検査のつもりで流したら、以後の `systemctl --user` がすべて失敗した:

```
$ stat -c '%y %n' /run/user/1000/systemd/private
2026-09-27 16:17:41.195249431 +0000 /run/user/1000/systemd/private
$ systemd-analyze --user verify ~/.config/systemd/user/syncthing-backup.{service,path,timer}; echo verify-rc=$?
verify-rc=0
$ stat -c '%y %n' /run/user/1000/systemd/private
2026-09-27 16:17:49.827381261 +0000 /run/user/1000/systemd/private
$ systemctl --user is-system-running
Failed to connect to user scope bus via local transport: Connection refused
```

- 検査は通る（何も出さず、終了コード 0）が、ユーザーの systemd の private ソケットが置き換わる。`brew services` も同じ理由で失敗する
- root で `systemctl restart user@1000.service` すると戻る（Syncthing も再起動し、`active` に戻った）

#### 送信専用フォルダと相手

[設定を自動でバックアップする（任意）](../syncthing.md#設定を自動でバックアップする任意)の手順 4 で入った `config.xml` のフォルダ:

```
<folder id="syncthing-backup-<HOSTNAME>" label="syncthing-backup (<HOSTNAME>)" path="/home/<USER>/syncthing-backup" type="sendonly" rescanIntervalS="3600" fsWatcherEnabled="true" fsWatcherDelayS="10" fsWatcherTimeoutS="0" ignorePerms="false" autoNormalize="true">
```

- `<defaults>` の `<folder>` と比べて違うのは、`<minDiskFree unit="">0</minDiskFree>`（既定は `unit="%"` の 1）だけ
- 相手に共有すると、相手の受信専用フォルダ（`~/peer-recv`）にアーカイブが届いた。確かめた時点で、相手のフォルダに `.tmp` の名前のファイルは無かった
- 102 個にしてから設定を変えると、こちらは 100 個になり、相手も 100 個になって、消えた 3 個は相手の `.stversions` に入った

#### 同じホストで戻す

GUI の待ち受けを `127.0.0.1:9999` に変えて壊した（壊した設定も path ユニットが取った）。壊す前のアーカイブを `ST_BACKUP` に入れ直して、[バックアップから戻す](../syncthing.md#バックアップから戻す)の手順 3〜6 を貼った:

```
$ tar -tzvf "${ST_BACKUP}"
-rw-r--r-- <USER>/<USER> 623 2026-09-27 16:15 cert.pem
-rw------- <USER>/<USER> 119 2026-09-27 16:15 key.pem
-rw------- <USER>/<USER> 9294 2026-09-27 16:23 config.xml
-rw-r--r-- <USER>/<USER>  684 2026-09-27 16:15 https-cert.pem
-rw------- <USER>/<USER>  227 2026-09-27 16:15 https-key.pem
...
$ syncthing device-id
<DEVICE_ID>
$ syncthing cli config gui raw-address get
0.0.0.0:8384
$ syncthing cli config gui raw-use-tls get
true
```

デバイス ID は壊す前と同じ。`https://127.0.0.1:8384/` は 200 に戻った。展開した `config.xml` を path ユニットが取り、戻した設定が最新のアーカイブになった。

#### OS を入れ直した相当（新しいコンテナ）

元のコンテナの Syncthing を止め（相手の 2 つ目の Syncthing は動かしたまま）、Homebrew だけ入れた新しいコンテナで戻した。元のコンテナには、送信専用フォルダのほかに、相手と共有した送受信フォルダ `docs`（`~/Sync`、ファイル 2 つ）を足しておいた。

- [バックアップから戻す](../syncthing.md#バックアップから戻す)の手順 1・2・4・5 を、Syncthing を入れる前に貼った。アーカイブは相手の受信専用フォルダから全部（9 個）コピーした（`scp` の代わりに `docker exec` の `tar` のパイプを使った）
- そのあと実施手順 2〜6 と 8（と、今の [linger.md](../linger.md) の手順 2 に当たる linger の有効化）を通した

[手順 4](../syncthing.md#実施手順) の `syncthing generate`:

```
WRN Key exists; will not overwrite (log.pkg=github)
INF Calculated device ID (device=<DEVICE_ID> log.pkg=github)
INF Updated GUI authentication password (log.pkg=github)
```

- `cert.pem` / `key.pem` の sha256 は戻したものと同じ。デバイス ID も元のコンテナと同じ
- `config.xml` の API キー・フォルダ（`docs` と `syncthing-backup-<HOSTNAME>`）・`<address>0.0.0.0:8384</address>`・`tls="true"` は残り、パスワードのハッシュだけ変わった

[手順 5](../syncthing.md#実施手順) で起動したあとのログ（抜粋）:

```
INF Ready to synchronize (folder.id=docs folder.type=sendreceive log.pkg=model)
INF Ready to synchronize (folder.label="syncthing-backup (<HOSTNAME>)" folder.id=syncthing-backup-<HOSTNAME> folder.type=sendonly log.pkg=model)
WRN Peer has mismatching index ID for us (device=<PEER> folder.id=docs ...)
INF Peer has a new index ID (device=<PEER> folder.id=docs ...)
INF Synced file (folder.id=docs folder.type=sendreceive file.name=b.txt ...)
INF Synced file (folder.id=docs folder.type=sendreceive file.name=a.txt ...)
```

- `~/Sync` は無かったが、Syncthing が `.stfolder` ごと作り、`a.txt` / `b.txt` を相手から受け取った。`~/syncthing-backup` にも `.stfolder` が作られた
- REST の `/rest/db/status` で、`docs` も送信専用フォルダも `idle`、`needFiles` 0。相手から見たこちらの完了率は 100
- 相手の `/rest/cluster/pending/devices` は `{}`。新しいデバイスとしての承認待ちにはならなかった
- そのあと[設定を自動でバックアップする（任意）](../syncthing.md#設定を自動でバックアップする任意)の手順 1〜3 を貼ると、アーカイブが 1 つ増えた（`generate` でパスワードのハッシュが変わったため）

#### アーカイブを 1 つだけ戻したとき

同じ新しいコンテナで、Syncthing を止めて DB（`index-v2`）を消し、`~/syncthing-backup` を最新の 1 個だけにして起動した:

```
state=idle needFiles=8 localFiles=1 globalFiles=9
```

- 送信専用フォルダは相手の 8 個を取りに行かず、「同期されていない」ままだった。相手の 9 個はそのまま
- ここで `POST /rest/db/override`（GUI の上書きのボタンと同じ）を送ると、`needFiles` 0・`globalFiles` 1 になり、相手の受信専用フォルダは 1 個になった。消えた 8 個は相手の `.stversions` に入った

#### 元に戻す

[設定を自動でバックアップする（任意）](../syncthing.md#設定を自動でバックアップする任意)の手順 7 を、戻したコンテナで貼った:

```
Removed '/home/<USER>/.config/systemd/user/paths.target.wants/syncthing-backup.path'.
Removed '/home/<USER>/.config/systemd/user/timers.target.wants/syncthing-backup.timer'.
登録を消した: syncthing-backup-<HOSTNAME>
docs
```

- `~/.config/systemd/user` には `sh.brew.syncthing.service` だけが残り、`~/.local/bin` は空になった
- `~/syncthing-backup/.stfolder` は Syncthing が消した。アーカイブは残った
- 最初は `syncthing-backup-$(uname -n)` を ID で消す形にしていたが、戻したホストでは ID に元のホスト名が入っていて、ホスト名が違うと消せない。パスで探す形に替えた

#### 未確認事項

- 実機（本書の Raspberry Pi の aarch64 を含む）での実行
- 別のマシンの相手と、VPN 越し（`wg0`）の複製
- GUI での共有・受け入れ・受信専用の選択・ゴミ箱の設定（コンテナでは CLI で同じ値を入れた）
- 実際に 0 時台にタイマーが走ること、止まっていた間の分を `Persistent=true` で追いかけて走ること
- ユーザーの journal が読める環境での `journalctl --user` の出力
- 外付けディスクを保存先や同期フォルダにしたときの、マウントが外れている場合の挙動
- firewalld（手順 7）を含めた入れ直し

---

### 付録: Windows 11 の配布物と資料の調査（2026-10-03）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、配布物とソースと資料を読んだ記録。

#### リリースのファイル

最新は v2.1.5（2026-09-08。次の候補は v2.1.6-rc.4）。`releases/latest/download/sha256sum.txt.asc` は v2.1.5 のファイルへ飛んだ:

```
$ curl -sS -o /dev/null -w '%{http_code} %{redirect_url}\n' https://github.com/syncthing/syncthing/releases/latest/download/sha256sum.txt.asc
302 https://github.com/syncthing/syncthing/releases/download/v2.1.5/sha256sum.txt.asc
```

`sha256sum.txt.asc` の Windows の行（改行は LF。[Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 4 の正規表現で、amd64 と arm64 の行がそれぞれ 1 つだけ合った）:

```
39571e4d0900c2a2cab14c0b170f49751340a869e49734ccc8079d9b98a7974b  syncthing-windows-amd64-v2.1.5.zip
082de37dc99621064bde8378ea26b28378f312f0a4147f52844ce7425f1baab0  syncthing-windows-arm64-v2.1.5.zip
```

取ってきた amd64 の zip の sha256 は `39571e4d…7974b` で一致した。`.asc` の GPG の署名は、`https://syncthing.net/release-key.txt` の鍵で確かめられた（もう 1 つ、その鍵の一覧に無い古い鍵の署名も付いていた）:

```
gpg: Good signature from "Syncthing Release Management <release@syncthing.net>" [unknown]
Primary key fingerprint: FBA2 E162 F2F4 4657 B38F  0309 E566 5F9B D597 0C47
gpg:                using RSA key 37C84554E7E0A261E4F76E1ED26E6ED000654A3E
gpg: Can't check signature: No public key
```

zip の中（`syncthing-windows-amd64-v2.1.5/` の下）は `syncthing.exe`（27,448,104 バイト）・`README.txt`・`LICENSE.txt`・`AUTHORS.txt`・`metadata/release.sig`・`etc/`（`linux-systemd`・`macos-launchd` など。Windows 用は無い）。

#### `syncthing.exe` の署名と埋め込みの設定

PE の証明書テーブルを openssl で読んだ（Windows の `Get-AuthenticodeSignature` は通していない）:

```
subject=C = SE, ST = Sk\C3\A5ne, L = H\C3\B6llviken, O = Kastelo AB, CN = Kastelo AB
issuer=C = US, O = Microsoft Corporation, CN = Microsoft ID Verified CS AOC CA 04
subject=C = US, O = Microsoft Corporation, CN = Microsoft ID Verified CS AOC CA 04
issuer=C = US, O = Microsoft Corporation, CN = Microsoft ID Verified Code Signing PCA 2021
subject=C = US, O = Microsoft Corporation, CN = Microsoft ID Verified Code Signing PCA 2021
issuer=C = US, O = Microsoft Corporation, CN = Microsoft Identity Verification Root Certificate Authority 2020
```

- 署名者の証明書の有効期間は 2026-09-06〜2026-09-09（3 日）
- RFC 3161 のタイムスタンプ（OID `1.3.6.1.4.1.311.3.3.1`）が付いていて、時刻は 2026-09-08。期限の切れた後も、タイムスタンプで署名が有効とみなされる
- 埋め込みの manifest に `<consoleAllocationPolicy xmlns="http://schemas.microsoft.com/SMI/2024/WindowsSettings">detached</consoleAllocationPolicy>` がある（v2.1.2 から）

#### ソース（v2.1.5）

- `cmd/syncthing/generate/generate.go`: `--gui-password=-` は `bufio.NewReader(os.Stdin)` の `ReadLine()` で 1 行を読む（Go の説明: 返す行は `\r\n` も `\n` も含まない）
- `cmd/syncthing/hideconsole_windows.go`: `--no-console`（環境変数は `STHIDECONSOLE`）。説明は「Hide console window (Always enabled on Windows 11 24H2 and later)」
- `cmd/syncthing/monitor.go`: 子が 60 秒の間に 4 回起動すると `Too many restarts; not retrying further` で終わる。子が終了コード 4（更新）で終わると、Windows では `restartMonitorWindows` が新しい親を `exec.Command(...).Start()` で起動して、今の親は終わる（Linux などは `syscall.Exec` で同じプロセスのまま）
- `lib/locations/locations.go`: Windows の設定と DB は `%LOCALAPPDATA%\Syncthing`（無ければ `%APPDATA%\Syncthing`）。ログの既定は Windows だけ `syncthing.log`（ほかは標準出力）
- 自動の更新の既定は `autoUpgradeIntervalH` が 12

#### パッケージの定義（採らなかった経路）

- winget の `Syncthing.Syncthing` 2.1.5: `InstallerType: zip`、`NestedInstallerType: portable`、`RelativeFilePath: syncthing-windows-amd64-v2.1.5/syncthing.exe`、`InstallerUrl` は GitHub の公式の zip、`UpgradeBehavior: uninstallPrevious`
- scoop の `main/syncthing` 2.1.5: `"bin": [[ "syncthing.exe", "syncthing", "--home \"$dir\\config\" --no-upgrade" ]]`、`"persist": "config"`、`notes` は公式の自動起動の説明へのリンク
- `BillStewart.SyncthingWindowsSetup` 2.0.2（2026-03-19）: Inno Setup。README は、個人用の導入でログオンのタスクを作ること、対話の導入では規則を作るかを聞き、サイレントの個人用の導入では規則を作らないことを書いている。Syncthing の自動の更新は既定のまま（12 時間）
- Syncthing の公式のドキュメント（autostart）は「There is currently no official installer available for Windows.」と書いている

---

### 付録: Windows 11 の CLI と PowerShell のブロックの Linux での確認（2026-10-03）

本書の[Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 6・10 と、後ろの Windows 11 の節で使う `syncthing` のコマンドが 2.1.5 でそのとおり動くかを、Linux の公式の tarball（`syncthing-linux-amd64-v2.1.5.tar.gz`、`syncthing v2.1.5 "Hafnium Hornet" (go1.27.1 linux-amd64) builder@github.syncthing.net 2026-09-08 06:57:55 UTC`）で確かめた。一時的な `HOME` で、親（モニター）付き（`--no-restart` 無し）で動かした。Windows だけのもの（`--no-console`・タスク・ファイアウォール・ログのファイル）は確かめられない。最後に、本書の PowerShell のブロックを Linux の PowerShell 7 で確かめた記録を置く。

**`generate` に CR LF 付きでパスワードを渡す**（[Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 6 の Windows PowerShell 5.1 のパイプに当たる）:

```
$ printf 'pw-Test_1\r\n' | syncthing generate --gui-user=winuser --gui-password=-
INF Generating key and certificate (cn=syncthing log.pkg=syncthing)
INF Calculated device ID (device=<DEVICE_ID> log.pkg=github)
INF Updated GUI authentication user (name=winuser log.pkg=github)
INF Updated GUI authentication password (log.pkg=github)
$ printf '' | syncthing generate --gui-user=x --gui-password=-; echo $?
syncthing: error: failed reading GUI password: EOF
1
```

起動した後に、GUI のログインの API に送った:

```
POST /rest/noauth/auth/password  {"username":"winuser","password":"pw-Test_1"}    → 204
POST /rest/noauth/auth/password  {"username":"winuser","password":"pw-Test_1\r"}  → 403
```

CR を落としたパスワードでだけログインできた。`generate` の直後の設定は `<gui enabled="true" tls="false" …>` と `<address>127.0.0.1:8384</address>` で、空の `.syncthing.tmp.<数字>` が残った。

**[Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 10 のコマンド**: 4 つとも終了コード 0 で、`0.0.0.0:8384` と `true` を読み戻した。起動し直す前から、待ち受けは `0.0.0.0:8384` に変わり、HTTPS になっていた:

```
https://127.0.0.1:8384/                  → 200
http://127.0.0.1:8384/                   → 307
https://127.0.0.1:8384/rest/system/status → 403（認証無し）
```

**`cli operations restart`**: 終了コード 0。子のプロセスだけが入れ替わり（PID が変わった）、親は同じだった。3 秒で HTTPS の待ち受けに戻った。

**`cli operations shutdown`**: 終了コード 0。親と子の 2 つのプロセスが終わった（ログの最後は `Exiting`）。止まった後にもう 1 度送ると、`dial tcp 0.0.0.0:8384: connect: connection refused` で終了コード 1（`0.0.0.0` の待ち受けへの接続は、ループバックに向く）。

**更新の確認**（新しい版が無いとき）:

```
$ syncthing upgrade --check-only; echo $?
ERR Failed to check for upgrade (error="no upgrade available (current \"v2.1.5\" >= latest \"v2.1.5\")." log.pkg=main)
2
$ syncthing cli operations upgrade; echo $?
0
```

`config.xml` の `autoUpgradeIntervalH` は 12、`urAccepted` は 0（利用状況の報告をまだ聞いていない）だった。

**PowerShell のブロック**:

- 本書の `powershell` のブロック 20 個を、Linux の PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer 1.25.0 の `PSUseCompatibleSyntax`（Windows PowerShell 5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。互換の指摘は 0（ほかの規則の指摘は、[Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 5 の `$ST_GUI_PASS` を手順 6 で使うことへの 1 つだけ）。わざと PowerShell 7 だけの書き方（`??`、`Get-Content -AsByteStream`、`ForEach-Object -Parallel`）を入れたファイルでは、それぞれ指摘が出た
- [Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 4 のブロックを、Linux の pwsh で、パスの `\` を `/` に替え、`Get-AuthenticodeSignature` と `icacls.exe` を偽物にして流した。最新の版の行を `sha256sum.txt.asc` から取り、zip を取って sha256 が一致し、展開した `syncthing.exe` を `%LOCALAPPDATA%` に当たる場所へ置いて、一時フォルダーを消した。偽物の署名の `Status` を `Valid` 以外にすると、`中断: syncthing.exe の署名を確かめられない（HashMismatch）` で止まり、何も置かなかった
- [Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 6 のブロックを、Linux の pwsh で、`$exe` を Linux の `syncthing` にして流した。`ConvertTo-SecureString` で作ったパスワードで `generate` が通り、起動した後にそのパスワードでログインできた（204）。`パス1` は `パスワードに ASCII でない文字がある` で止まった。どちらも最後に `$ST_GUI_PASS` が消えていた。PowerShell 7 はパイプの文字コードが UTF-8 で、改行は LF なので、Windows PowerShell 5.1 と同じではない

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと
1. `Get-AuthenticodeSignature` が `Valid` を返し、署名者が `CN=Kastelo AB, …` で始まること
1. タスクで起動したときに窓が出ないこと、サインインでの起動、サインアウトで止まること
1. 受信の規則を先に作れば、警告の窓が出ないこと
1. LAN の別の端末からの GUI と、相手との同期
1. 自動の更新と、その後のタスクの状態（`Ready`）、`syncthing.exe.old`
1. arm64 の Windows、24H2 より前の Windows

### 付録: クリーンインストールした VM での検証（2026-10-06）

ISO から入れた AlmaLinux 10.2 Workstation の x86_64 VM 2 台で、Homebrew と linger を前提手順から用意し、現行の手順 1〜8 を一般ユーザーの SSH PTY にブラケットペースト無しで貼った。SELinux Enforcing、カーネル `6.12.0-211.61.1.el10_2.x86_64`、1 vCPU、Homebrew 7.0.8、Syncthing 2.1.5 の `[noupgrade]` ボトル。GUI の認証・デバイス・ファイルは検証専用。

- 一方は全 NIC、もう一方は localhost の GUI とした。サービスは enabled/active、HTTPS と 8384/tcp、同期の TCP/UDP の待ち受けができた。トップの HTML は認証なしでも 200 のログイン画面を返すが、保護された REST API は認証なしで 403、API キーを VM 内で読んだ問い合わせは成功した
- GUI の接続元を隔離 LAN の帯だけに絞る節を実行し、別 VM から到達（認証なしの REST は 403）、許可帯外の network namespace からは拒否されることを確認した
- 自動バックアップ 1〜4 を通し、path/timer は active、oneshot の Result は success、最初の 0600 の archive ができた。送信専用フォルダの登録後は path が設定変更を拾い、archive がもう 1 つできた
- 同じホストの復元 3〜6 を通した。変更前の archive と device ID を控え、帯域制限を 0 → 17 に変えて新しい archive ができた後、控えた変更前 archive を選び直して展開した。サービスの再起動後は帯域制限が 0、device ID は元と一致、GUI のアドレス・TLS・フォルダも戻った
- 相手 VM のデバイス登録と受け入れの一部は、API キーを表示せず VM 内の REST API から設定した。GUI と API のどちらで通したかは、以下の追加の確認に記録する

#### GUI と別 VM への同期

別の Workstation VM の Firefox 157 から、サーバー VM の HTTPS の GUI に検証ユーザーでログインした。フォルダーを追加する画面で `gui-verify` と専用のパスを入れ、「共有」タブで peer にチェックを入れて保存した。日本語 UI の同期完了表示は「最新」だった。

日本語名のファイルをサーバーから peer へ、別のファイルを peer からサーバーへ作り、それぞれ実体が届いて内容が一致した。両方の REST の `needFiles`・`needBytes` は 0、接続方式は直接 TCP。設定バックアップも GUI の編集 → 共有 → peer のチェック → 保存で共有し、受信側に届いた 8 個の archive のファイル名と sha256 がすべて一致した。

相手デバイスの登録と、peer のフォルダの受け入れは REST API で設定した。バックアップの受信側は receiveonly と trashcan にした。peer 側の GUI で承認・受け入れを操作した確認ではない。

#### TLS 切り替えの EOF と修正

localhost の GUI を使った VM の初回の手順 6 は、`raw-use-tls set true` の `Post ... /rest/system/config: EOF` で終了 1 になった。設定自体は HTTPS に変わったが、`&&` の後ろの読み戻し・再起動・待ち受け確認は実行されなかった。同じブロックをもう一度貼って通っただけでは、初回の成功とは扱っていない。

GUI 設定の変更時に API の待ち受けを切り替えることと、HTTP サーバーの停止待ちが 100 ms であることは [2.1.5 の api.go](https://github.com/syncthing/syncthing/blob/v2.1.5/lib/api/api.go)、設定の保存後に応答する処理は [confighandler.go](https://github.com/syncthing/syncthing/blob/v2.1.5/lib/api/confighandler.go) にある。VM の応答が停止の猶予に間に合わなかったと推定した。

手順 6 を 3 秒待って 1 度再試行し、実際のアドレスと TLS が両方一致してから restart する形へ修正。初回失敗時の設定を控えて、新しい鍵・設定から手順 1・3〜8 を通し直すと、読み戻し・HTTPS・restart・LISTEN まで成功した。修正後の新規設定では EOF 自体は出なかった。全 NIC の VM では、修正前の初回も成功していた。

#### 再起動・更新・ロールバック

両 VM を順に再起動した。サーバーは OS の起動時刻 04:15:10、user manager・Syncthing・backup path/timer は 04:15:49、SSH での再ログインは 04:16:18。相手は OS 04:18:51、Syncthing は 04:19:33、SSH は 04:20:12。いずれも SSH ログイン前にユーザーサービスが起動した。再接続後は両フォルダーが idle、needFiles/needBytes が 0、直接 TCP のままで、バックアップは 8 個から増えなかった。これは timer が実際の 0 時台を迎えた確認ではない。

更新 1・2 は、`2.1.5 already installed` の後に restart と版表示が通った。新しい版への入れ替えは試していない。GUI の接続元制限を戻す手順も通した。

バックアップの解除 7 とロールバック 1〜3 を実行し、サーバーの登録・path/timer・スクリプト、両 VM の Homebrew の Syncthing・ユーザーサービス・受信規則・現行の設定と鍵・DB が消えた。保存先の 8 個の archive と相手へ届いたコピーは残った。サーバーはほかのユーザーサービスが無いことを確かめて linger も無効へ戻した。相手は Quadlet と RDP 検証が使うため linger を維持した。

今回の VM では OS を入れ直したホストへの Syncthing 復元、実際の 0 時台の timer と Persistent の追いかけ、競合処理、インターネット経由の relay、UDP/QUIC での同期はまだ検証していない。Windows の節は今回の確認に含めていない。

### 付録: 新規 VM での現行手順の再検証（2026-10-06）

同日の先行検証に使った VM と分け、ISO 導入直後の AlmaLinux 10.2 Workstation から新しい x86_64 VM を用意して、`5da3478` の現行本文を再検証した。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active。一般ユーザーの SSH PTY にブラケットペースト無しで貼り、手順ごとに結果を確認した。

Homebrew と linger は前提の手順書から導入した。両 VM の手順 1〜8 は初回から成功し、Homebrew 7.0.8 の Syncthing 2.1.5 `[noupgrade]`、GUI の `0.0.0.0:8384` と TLS、enabled/active、同期ポートが確認できた。保護された REST API は認証無しで 403 だった。今回の手順 6 では EOF は出なかった。

- 別の新規 Workstation VM の Firefox で自己署名証明書の警告、認証、Show ID を確認した。双方のデバイス登録と承認、`current-vm-test` フォルダの作成・共有・相手側のパス指定を、両方の GUI で操作した
- 日本語ファイルを双方から作成し、相手側からの更新と削除も同期した。内容・sha256 が一致し、両方で idle、needFiles/needBytes が 0、接続方式は直接 TCP だった
- GUI の接続元制限 1 は検証用 LAN だけを許可した。LAN の相手から 8384/tcp へ到達し、許可帯外の WireGuard クライアントは拒否された。解除 2 も成功した
- 設定バックアップ 1〜4 は path/timer が active、oneshot は success、変更時だけ 0600 の archive が増えた。5・6 の GUI の共有と相手側の承認・受信専用・ゴミ箱（0 日）も操作した。最初に届いた 7 個の名前と sha256 はすべて一致した
- 同じホストの復元 3〜6 は、変更前の archive を控え、送信帯域制限を 0 → 17 にしてから控えた archive を選んで戻した。再起動後は 0、device ID は元と一致、アドレス・TLS・共有フォルダも戻った

両 VM の OS 再起動後、Syncthing は SSH ログイン前に起動した。サーバーは 14:00:45 JST（SSH セッション 14:00:57）、相手は 14:03:19（SSH 14:03:28）。両フォルダは idle、needFiles/needBytes は 0、設定バックアップは双方に 9 個あった。

更新 1・2 は `2.1.5 already installed` と restart・版表示を確認した。新しい版への更新ではない。バックアップ解除 7 とロールバック 1〜3 を通し、両 VM のサービス・受信規則・Homebrew の Syncthing・現行の設定と鍵・DB が消えた。9 個の archive と相手のコピーは残し、linger は両 VM で無効に戻した。

この再検証では OS を入れ直したホストへの復元、0 時台の timer と Persistent の追いかけ、競合、relay、UDP/QUIC、Windows の節は確かめていない。証明書 `cert.pem` と `https-cert.pem` は 0644、秘密鍵と `config.xml` は 0600 だった。

### 手順中の実測・検証状況の記録

- **24H2 より前の Windows**: `syncthing.exe` に入っている「コンソールの窓を作らない」設定が効かず、タスクから起動したときにコンソールの窓が一瞬出て、`--no-console` で隠れるはず（確かめていない）

### 実施手順 / 手順 2: 補足: noupgrade と入るファイル

```
$ brew list syncthing
/home/linuxbrew/.linuxbrew/Cellar/syncthing/2.1.5/bin/syncthing
/home/linuxbrew/.linuxbrew/Cellar/syncthing/2.1.5/sh.brew.syncthing.service
/home/linuxbrew/.linuxbrew/Cellar/syncthing/2.1.5/sh.brew.syncthing.plist
/home/linuxbrew/.linuxbrew/Cellar/syncthing/2.1.5/share/man/man1/syncthing.1
/home/linuxbrew/.linuxbrew/Cellar/syncthing/2.1.5/share/man/man5/syncthing-config.5
/home/linuxbrew/.linuxbrew/Cellar/syncthing/2.1.5/share/man/man7/syncthing-faq.7
...
```

### 実施手順 / 手順 8: 補足: 認証が効いているかの確かめ方

GUI のトップはログイン画面なので 200 が返る。**認証が効いていることは API で確かめる**:

```
$ curl -sk -o /dev/null -w '%{http_code}\n' https://127.0.0.1:8384/rest/system/status
403
```

API キーを付ければ通る（キーは `syncthing cli config gui apikey get` で読めるが、**パスワードと同じ重みの秘密**なので扱いに注意する）:

```
$ curl -sk -H "X-API-Key: <APIKEY>" https://127.0.0.1:8384/rest/system/status
（JSON が返る。その中の "myID" が syncthing device-id と一致する）
```

### バックアップから戻す / 手順 2: 補足: 全部持ってくる理由

- 送信専用フォルダは、相手にあってこちらに無いファイルを取りに行かない
- 1 つだけ持ってきて起動すると、残りは相手にしか無いまま「同期されていない」表示が続く。コンテナでは `needFiles` が 8 のままだった
- その状態で上書きのボタンを押すと、こちらに無いファイルは消されたものとして相手に伝わる。コンテナでは相手の 9 個が 1 個になった（相手のゴミ箱を有効にしていたので、`.stversions` に残った）
- 全部持ってくれば、DB が空の初回起動でも両方の一覧が一致し、同期済み（`needFiles` が 0）になる

### 手順中の検証状況

- **Windows で使えない名前のファイル**: 相手（AlmaLinux 10 など）にある、`:` や `?` などを含む名前や、大文字と小文字だけが違う名前のファイルは、Windows では同期できない（Syncthing は、そのファイルを同期できなかったものとして GUI に出す。確かめていない）

### 手順内の実測・検証状況

- **移行後に 1.x へ戻せるかどうかは本書では確認していない**

### 実施手順 / 手順 1: 補足: 変数について

- `ST_GUI_ADDR` を `0.0.0.0:8384` にすると**すべての NIC で待ち受ける**。この環境では `end0`（LAN）と `wg0`（VPN）の両方から開ける

### Windows 11 で使う / 手順 7: 補足: 規則の中身と、最初の起動より前に作る理由

- Windows のファイアウォールは、規則の無いプログラムが待ち受けると「Windows セキュリティの重要な警告」の窓を出す。そこで「キャンセル」を押すと、そのプログラムの**拒否**の規則ができ、拒否は許可より優先され、窓は二度と出ない。先に許可の規則を作っておけば、少なくともこの LAN では窓は出ないはず（確かめていない）
