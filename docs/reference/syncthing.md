# Syncthing インストール手順（AlmaLinux 10 は Homebrew + systemd ユーザーサービス / Windows 11 は公式の zip + タスク スケジューラ）の参考資料

[手順書](../syncthing.md)・[ロールバックと注意点](../extra/syncthing.md)

## 補足

### 実施手順 / 手順 1: 補足: 変数について

[この節の検証記録](../verification/syncthing.md#実施手順--手順-1-補足-変数について)

- `ST_GUI_USER` は **Syncthing の Web GUI にログインするための名前**で、OS のアカウントとも Samba のユーザーとも無関係。自動で OS と同じ名前が入るだけなので、別の名前にしてもよい
- `ST_LAN_IP` は設定には使わず、手順 8 の案内と、手順 9 のブラウザの URL にしか使わない。間違っていても Syncthing の設定は壊れない（[samba.md](../samba.md) の `SERVER_IP` と同じ扱い）
- `ST_GUI_ADDR` を `0.0.0.0:8384` にすると**すべての NIC で待ち受ける**
- 特定の 1 本に絞りたいなら `192.168.1.10:8384` のように IP を直接書く（その場合 firewalld は手順 7 のままでよい）
- パスワードは変数に置かない。手順 3 でその場で読み取り、設定したら `unset` する

### 実施手順 / 手順 2: 補足: noupgrade と入るファイル

aarch64 で降ってくるボトルは `syncthing--2.1.5.arm64_linux.bottle.tar.gz`。

- `noupgrade` は、**Syncthing 自身の自動アップグレード機能を無効にしてビルドされている**という印
  - 公式の tarball 版は自分で新しい版を取ってきて入れ替えるが、Homebrew の formula は `go run build.go --version ... --no-upgrade tar` でビルドするので、その機能が入らない
  - 更新は `brew upgrade` で行う（[更新](../syncthing.md#更新)）。パッケージマネージャ管理下のファイルを Syncthing が勝手に書き換えないので、こちらの方が都合がよい
- `modernc-sqlite` は 2.x で採用された SQLite 実装（cgo 無しの純 Go 版）。1.x の LevelDB から変わった部分（[注意点](../extra/syncthing.md#注意点)）

実行ファイルと man ページに加え、Homebrew が生成したサービス用ファイルが入る。**上流が配る systemd の unit とは別物**:

- `sh.brew.syncthing.service` は formula の `service do` ブロックから Homebrew が生成したもので、公式が配っている `etc/linux-systemd/user/syncthing.service` ではない（手順 5 の補足）
- man は `man syncthing` / `man syncthing-config` / `man syncthing-faq` などが読める

### 実施手順 / 手順 5: 補足: 生成される unit と、システムサービスにする道

**Homebrew が置く unit は公式のものではない。** formula の `service do` ブロックから生成された次の内容で、`brew services start` のたびに書き直される:

```
[Unit]
Description=Homebrew generated unit for syncthing

[Install]
WantedBy=default.target

[Service]
Type=simple
ExecStart="/home/linuxbrew/.linuxbrew/opt/syncthing/bin/syncthing" "--no-browser" "--no-restart"
Restart=on-failure
StandardOutput=append:/home/linuxbrew/.linuxbrew/var/log/syncthing.log
StandardError=append:/home/linuxbrew/.linuxbrew/var/log/syncthing.log
```

- **ログは journal ではなくファイルに出る。** `journalctl --user -u sh.brew.syncthing.service` は `No entries` になるので、`tail -f /home/linuxbrew/.linuxbrew/var/log/syncthing.log` を見る
- `--no-restart` は「Syncthing が自分を再起動しない」指定で、落ちたときの再起動は systemd の `Restart=on-failure` が受け持つ
- unit を直接書き換えても `brew services` が上書きするので、変えたいときは `~/.config/systemd/user/sh.brew.syncthing.service.d/` に drop-in を置く

**システムサービスにする道もある。**

- 公式は root 管理の `syncthing@<USER>.service` も用意していて、その場合 linger は要らない
- Homebrew 版には上流のシステムサービス用 unit が同梱されないので、自分で用意することになる。本書は Homebrew が生成するユーザーサービスを使う

### 実施手順 / 手順 8: 補足: 認証が効いているかの確かめ方

[この節の検証記録](../verification/syncthing.md#実施手順--手順-8-補足-認証が効いているかの確かめ方)

GUI のトップはログイン画面なので 200 が返る。**認証が効いていることは API で確かめる**。

API キーを付ければ通る。キーは `syncthing cli config gui apikey get` で読めるが、**パスワードと同じ重みの秘密**なので扱いに注意する。

### Windows 11 で使う / 手順 2: 補足: 変数について

- `$ST_GUI_USER` は **Syncthing の Web GUI にログインするための名前**で、Windows のアカウントとは関係が無い。自動で同じ名前が入るだけなので、別の名前にしてもよい（AlmaLinux 10 の[手順 1](../syncthing.md#実施手順)の `ST_GUI_USER` と同じ扱い）
- `$LAN_IF` は、この節の手順 7（ネットワークがプライベートか確かめる）・手順 11（GUI の URL を出す）で使う。式は [Windows の OpenSSH サーバー](../windows-openssh-server.md)の手順 2 と [Windows 11 の初期設定の手順 36](../windows-setup.md#実施手順) と同じ
- GUI の待ち受け（`0.0.0.0:8384`）と実行ファイルの場所（`%LOCALAPPDATA%\Programs\Syncthing\syncthing.exe`）は変える必要が無いので、変数にせずブロックに直接書いてある
- パスワードは変数に置いたままにしない。この節の手順 5 で読み取り、手順 6 で使ったら消す

### Windows 11 で使う / 手順 3: 補足: ほかの Syncthing と重ならないようにする理由

- Syncthing の設定と DB の置き場所は、Windows では `%LOCALAPPDATA%\Syncthing` に決まっている（ソースの `lib/locations`）。Syncthing Windows Setup の個人用の導入も、同じ場所を使う（その README）
- 同じ設定で 2 つの Syncthing を動かすことはできない（設定のフォルダーの `syncthing.lock` で、後から起動した方が止まる）
- 同じ待ち受けの番号（8384・22000）を、2 つの Syncthing で取り合うことにもなる

### Windows 11 で使う / 手順 7: 補足: 規則の中身と、最初の起動より前に作る理由

[この節の検証記録](../verification/syncthing.md#windows-11-で使う--手順-7-補足-規則の中身と最初の起動より前に作る理由)

- 3 つの規則は、AlmaLinux 10 の[手順 7](../syncthing.md#実施手順)の firewalld の `syncthing`（22000/tcp・22000/udp・21027/udp）と `syncthing-gui`（8384/tcp）に当たる。22000/tcp は同期、22000/udp は QUIC、21027/udp は同じ LAN の相手を見つけるため、8384/tcp は Web GUI
- どれも `syncthing.exe`（展開したフルパス）に限り、プライベートのネットワークだけで有効にする。持ち出した先のパブリックの Wi-Fi では開かない
- Windows のファイアウォールは、規則の無いプログラムが待ち受けると「Windows セキュリティの重要な警告」の窓を出す。そこで「キャンセル」を押すと、そのプログラムの**拒否**の規則ができ、拒否は許可より優先され、窓は二度と出ない。許可の規則は起動する前に作る
- Syncthing の公式の自動起動の説明は、「一度対話で起動して、ファイアウォールの窓で許可する」としている。本書はその代わりに、規則を先に作る
- Syncthing の FAQ も、パブリックのままでは直接つながらずリレー経由になりやすいので、プライベートにするよう書いている
- グループの名前（`Syncthing (setup-notes)`）は、ほかの導入の方法が作る規則と分けるためのもの

### Windows 11 で使う / 手順 8: 補足: タスクの設定のねらい

- **トリガー**: 自分のユーザーがサインインしたとき（`-AtLogOn -User`）。`-User` を外すと、どのユーザーのサインインでも動く
- **`-LogonType Interactive`**: サインインしている間のデスクトップのセッションで動く。パスワードをタスクに保存しない。サインアウトすると止まる
  - Syncthing の公式の説明は「ユーザーがログオンしているかどうかにかかわらず実行する」（パスワードを保存する）だが、本書はサインインしている間だけ動かす（[選択した方針](#選択した方針)）
- **実行レベル**: 既定の `Limited`（「最上位の特権で実行する」を付けない）。管理者の PowerShell から登録しても、Syncthing は管理者ではない自分のユーザーとして動く。管理者で動かすと、同期で作るファイルの所有者が `Administrators` になる
- **引数**: 公式の説明と同じ `--no-console --no-browser`
  - `--no-console` はコンソールの窓を隠す。Windows 11 24H2 以降は、`syncthing.exe` に入っている設定（`consoleAllocationPolicy` が `detached`）で、もともと窓を作らない
  - `--no-browser` は、起動のたびにブラウザで GUI を開かない
  - `--no-restart` は付けない。Syncthing は親（モニター）と子の 2 つのプロセスで動き、子が終わったとき（設定の変更・自動の更新）に親が起動し直す
- **`-ExecutionTimeLimit (New-TimeSpan)`**: 0（無制限）。既定の 3 日で止めないため（公式の説明の「長時間実行されている場合は停止」を外す）
- **`-AllowStartIfOnBatteries -DontStopIfGoingOnBatteries`**: ノート PC で、電池のときも起動し、電池になっても止めない（公式の説明の任意の設定）
- **`-MultipleInstances IgnoreNew`**: 既に動いていれば、二重に起動しない
- **`[System.Security.Principal.WindowsIdentity]::GetCurrent().Name`**: `<HOSTNAME>\<WIN_USER>`。SSH のセッションでも空にならない（[Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md)の手順 5 の補足）

### Windows 11 で使う / 手順 9: 補足: 2 つのプロセス

- タスクが起動するのは親（モニター）で、親が子（本体）を起動する。親は子が終わったときに起動し直すためのもの
- 子が 60 秒の間に 4 回起動すると、親はあきらめて終わる（ソースの `cmd/syncthing/monitor.go`）。止めて始め直す操作を短い間に繰り返さない
- 窓は出ない（タスクから起動したとき）。動いているかは、この手順のようにプロセスと待ち受けで見る

### 選択した方針

[この節の検証記録](../verification/syncthing.md#選択した方針)

- **起動方式はユーザーサービス + linger にした**
  - 同期するのはホームディレクトリ配下なので、ファイルの持ち主として動かすのが素直
  - root 管理の `syncthing@<USER>.service` でも同じことはできるが、Homebrew 版は上流のシステムサービス用 unit を同梱しないので、自分で用意することになる
- **GUI は LAN に公開し、認証と TLS を先に入れた**
  - 公開しない構成（`127.0.0.1:8384`）でも手順 6 で HTTPS を設定する。手順 7 は `syncthing-gui` を開けず、手順 9 はこのホストのブラウザで確かめる

- **firewalld は定義済みサービス（`syncthing` / `syncthing-gui`）で開けた。** ポート番号を直接書くより意図が読め、上流がポートを足したときにも追従する
- **設定のバックアップは、systemd のユーザーユニット（path + タイマー）で自動にした**（[設定を自動でバックアップする（任意）](../syncthing.md#設定を自動でバックアップする任意)）
  - Syncthing と同じユーザーの systemd に載せるので、root も cron も要らない。linger で、ログアウト中も動く
  - path ユニットなら、設定を変えた数秒後に取れる。1 日 1 回のタイマーは取りこぼしの保険
  - 取るのは鍵と `config.xml` だけで、DB は入れない（作り直せるうえ、動いている間のコピーは整合しない）
- **別の端末への複製は、Syncthing 自身の送信専用フォルダに任せた**
  - 公式のドキュメントが、設定ファイルのバックアップに勧めている形
  - restic（[導入元一覧](../tool-catalog.md#cli-開発運用)にある）で別のリポジトリへ送る方法もあるが、送り先を別に用意することになる

| 経路 | 状況 | 採否 |
|---|---|---|
| **公式の zip を固定の場所に置く** | GitHub のリリースの `syncthing-windows-amd64-v2.1.5.zip`（Authenticode の署名付き）。更新は Syncthing 自身の自動の更新で、同じ場所の実行ファイルを入れ替える | **採用** |
| winget の `Syncthing.Syncthing` | 2.1.5（公式の zip をそのまま）。版ごとに展開するフォルダーが変わる（`…\WinGet\Packages\Syncthing.Syncthing_…\syncthing-windows-amd64-v2.1.5\`）。`Links` のシンボリック リンクは、昇格も開発者モードも無いと作られない。Syncthing 自身の自動の更新は切られない | 不採用（パスが変わり、タスクと規則が更新で壊れる） |
| scoop の `main/syncthing` | 2.1.5。shim が `--home …\current\config --no-upgrade` を付け、設定は `~\scoop\persist\syncthing\config`。実行ファイルは `current` のジャンクションの先 | 不採用（shim を通さずに起動すると別の設定になる。ジャンクションの先のプログラムに規則が効くか確かめられない） |
| Chocolatey の `syncthing` | 2.1.5（コミュニティの保守）。自動起動も規則も無い | 不採用 |
| Syncthing Windows Setup（`BillStewart.SyncthingWindowsSetup` 2.0.2） | 公式のダウンロードのページが、新しい利用者に勧めるコミュニティのインストーラー。導入のときに最新の Syncthing を取り、ログオンのタスク・規則・開始と停止のショートカットを作る。サイレントの個人用の導入では規則を作らない | 不採用（画面の操作が中心になる。中身は本書とほぼ同じ） |
| SyncTrayzor v2（`GermanCoding.SyncTrayzor` 2.2.0）・Syncthing Tray（2.1.7） | タスクバーのトレイのアプリ。Syncthing を中に持つ | 不採用（GUI のアプリを足すことになる） |

### 参照

- [Getting Started — Syncthing documentation](https://docs.syncthing.net/intro/getting-started.html) — 初回起動からフォルダー共有までの流れ
- [Starting Syncthing Automatically — Syncthing documentation](https://docs.syncthing.net/users/autostart.html) — systemd のシステムサービス / ユーザーサービスと `enable-linger`。Windows のタスク スケジューラ（`--no-console --no-browser`、ファイアウォールの窓、タスクを終了してもモニターしか止まらないこと）、スタートアップのフォルダー、サービス
- [Firewall Setup — Syncthing documentation](https://docs.syncthing.net/users/firewall.html) — 22000/tcp・22000/udp・21027/udp の役割
- [Configuration — Syncthing documentation](https://docs.syncthing.net/users/config.html) — `config.xml` の各要素と設定ディレクトリの既定値（Windows は `%LOCALAPPDATA%\Syncthing`）、`autoUpgradeIntervalH`
- [Syncthing v2.0.0 リリースノート](https://github.com/syncthing/syncthing/releases/tag/v2.0.0) — SQLite への移行、構造化ログへの変更、廃止された項目（`--verbose` / `--logflags`）
- [homebrew-core の syncthing formula](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/s/syncthing.rb) — `--no-upgrade` ビルドと `service do` ブロック
- [Syncing Configuration Files — Syncthing documentation](https://docs.syncthing.net/users/config.html#syncing-configuration-files) — 設定ファイルを Syncthing でバックアップするなら送信専用フォルダにし、相手側で設定として使わない
- [Folder Types — Syncthing documentation](https://docs.syncthing.net/users/foldertypes.html) — 送信専用フォルダと「Override Changes」、受信専用フォルダ
- [FAQ — Syncthing documentation](https://docs.syncthing.net/users/faq.html) — 「My Syncthing database is corrupt」（DB を消して起動すると全フォルダを読み直す）と「folder marker missing」。自動の更新、Windows のネットワークをプライベートにする話（「Why do my Windows computers always connect through a relay?」）
- [Syncthing のダウンロード](https://syncthing.net/downloads/) — Windows の zip と、Syncthing Windows Setup・SyncTrayzor v2 の案内
- [Syncthing v2.1.5](https://github.com/syncthing/syncthing/releases/tag/v2.1.5) — リリースのファイルと `sha256sum.txt.asc`
- Syncthing 2.1.5 のソース — `lib/model/model.go` の `newFolder`（DB が空のフォルダはディレクトリと `.stfolder` を作る）、`lib/fs/tempname.go`（`.syncthing.` で始まる名前を一時ファイルとして扱う）、`syncthing generate` の `Key exists; will not overwrite`。Windows 11 の節は `cmd/syncthing/main.go`（`serve` の引数）、`cmd/syncthing/hideconsole_windows.go`（`--no-console`）、`cmd/syncthing/generate/generate.go`（`--gui-password=-`）、`cmd/syncthing/monitor.go`（モニターと `restartMonitorWindows`）、`lib/locations/locations.go`（設定とログの場所）
- `man syncthing`（`generate`、`cli`、`--gui-address`）/ `man syncthing-config`（`<gui>`）/ `man syncthing-faq` / `man loginctl`（`enable-linger`）/ `man systemd.path` / `man systemd.timer`
- [Console Allocation Policy — Microsoft Learn](https://learn.microsoft.com/en-us/windows/console/console-allocation-policy) — `consoleAllocationPolicy` の `detached`（Windows 11 24H2 以降）
- [about_Preference_Variables（`$OutputEncoding`）— Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-5.1) — Windows PowerShell 5.1 が native のコマンドへパイプで渡す文字コード
- [New-ScheduledTaskPrincipal](https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/new-scheduledtaskprincipal)・[New-ScheduledTaskSettingsSet](https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/new-scheduledtasksettingsset)・[New-NetFirewallRule](https://learn.microsoft.com/en-us/powershell/module/netsecurity/new-netfirewallrule)
- [linger](../linger.md) — AlmaLinux 10 の前提の手順書（ログアウト中もユーザーの systemd を動かす）
- [Windows の OpenSSH サーバー](../windows-openssh-server.md) — Windows 11 の同じ PC で使うことの多い手順書（LAN がプライベートである前提が同じ）

---
