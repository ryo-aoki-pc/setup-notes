# Dropbox へのバックアップの参考資料

[手順書](../dropbox.md#dropbox-へのバックアップ)・[注意点](../extra/dropbox-backup.md)

[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/dropbox-backup.md)

## 補足

### Dropbox へのバックアップ / 手順 1: 補足: read -rs と unset

- `read -r` はバックスラッシュをそのまま受け取り、`-s` は入力を画面に出さない。コマンドにパスワードの文字列を書かず、対話で受け取るので、シェルの履歴にパスワードを残さない
- 手順 2 の登録後と手順 10 の確認後に `unset` し、入力した値をシェルの変数から外す。手順 9 ではパスワードの管理から写して入力し、保存した値で戻せることを確かめる

### Dropbox へのバックアップ / 手順 2: 補足: crypt を重ねる理由

- [Forgejo の「Forgejo: バックアップ」の手順 4](../forgejo.md#forgejo-バックアップ)は、外部の共有先へ置く前にアーカイブを暗号化する。`dropbox:` の上に `crypt` を重ね、Forgejo のアーカイブも、選んだほかのファイルも、手元で中身を暗号化してから Dropbox へ送る
- `dropbox-backup:` は `dropbox:Backup/<ホスト名>` を指す。`current` が現在の版、`old/<UTC 日時>` が削除・上書き前の版の保管先になる

### Dropbox へのバックアップ / 手順 2: 補足: ファイル名を暗号化しない理由

- `filename_encryption=off` でファイル名を残し、Dropbox 側でもフォルダーとファイルを名前で見分けられるようにする。`directory_name_encryption=false` も指定するが、ファイル名の暗号化が `off` のときは、ディレクトリ名もそのままになる
- Dropbox 側のファイル名には `.bin` が付く。`dropbox-backup:` から見る名前には付かず、中身は読み出すときに復号される。名前・構造・大きさ・日時を隠す方式ではない（[Crypt](https://rclone.org/crypt/)）

### Dropbox へのバックアップ / 手順 2: 補足: --obscure

- [`rclone config create` の NB](https://rclone.org/commands/rclone_config_create/) は、22 文字以上で base64 の文字だけからなるパスワードを、難読化済みと取り違える場合があるとしている。`--obscure` で入力を必ず難読化してから設定へ入れる
- 設定の難読化は、ファイルの中身の暗号化とは別。難読化した値は元に戻せるので、`rclone.conf` を他人に読ませない
- `>/dev/null` は、登録後に出る設定を端末に表示しないため

### Dropbox へのバックアップ / 手順 2: 補足: 登録済みなら止める

- `rclone config create` は、同じ名前のリモートがあると上書きする（使い捨ての設定で、2 回目でパスワードが変わることを確かめた）。上書きすると、それまで Dropbox に上げたバックアップは、新しいパスワードでは戻せない
- そのため、`rclone listremotes` に `dropbox-backup:` があれば登録しない

### Dropbox へのバックアップ / 手順 2: 補足: パスワードはコマンドの引数に載る

- `rclone config create` に渡す `password=…` は、登録が終わるまでの間、そのプロセスの引数として、同じホストのほかのユーザーからもプロセスの一覧（`ps`）で読める
- `read -rs` と `unset` は、画面とシェルの履歴とシェルの変数に残さないためで、この間の引数は隠さない。ほかのユーザーがログインしているホストでは、その人がいない間に行う

### Dropbox へのバックアップ / 手順 3: 補足: フィルタの最後の行

- フィルタは上から判定され、先に一致した行が使われる。`+` の行だけでは、それ以外のファイルも対象になるので、最後の `- **` で外す（[Filtering](https://rclone.org/filtering/)）
- スクリプトは、コメントと空行を除いた最後の行が `- **` かを最初に確かめる。ファイルの欠落や最後の行の消し忘れで、ホーム全体を上げるのを防ぐ
- Forgejo の行は毎日のアーカイブだけを含める。稼働中のデータを直接上げず、停止中に取ったアーカイブを使う

### Dropbox へのバックアップ / 手順 5: 補足: --one-file-system

- ホームの下に別のファイルシステムをマウントしていても、その先へ進まない。外付けディスクなどを意図せず上げるのを防ぐ（[Local Filesystem](https://rclone.org/local/#one-file-system)）

### Dropbox へのバックアップ / 手順 5: 補足: sync と --backup-dir

- `copy` は手元で消えたファイルを送信先に残す。`sync` は対象に含まれるファイルについて `current` を手元と合わせ、`--backup-dir` で削除・上書き前の版を `old/<UTC 日時>` へ移す（[sync](https://rclone.org/commands/rclone_sync/)・[--backup-dir](https://rclone.org/docs/#backup-dir-dir)）
- 移動は同じリモート内で行い、対応するバックエンドでは server-side の移動になる。前の版を手元へダウンロードしてから上げ直す必要はない
- フィルタは送信先にも効く。`--delete-excluded` を付けていないので、フィルタから外したファイルは `current` に残り、`old` へは移らない（[Filtering の --delete-excluded](https://rclone.org/filtering/#delete-excluded-delete-files-on-dest-excluded-from-sync)）
- `old/<日時>` にあるのは、その回で削除・上書きされたファイルだけ。ホーム全体の、その日時の完全な複製ではない

### Dropbox へのバックアップ / 手順 5: 補足: 保持期間は日時の名前で判定する

- `STAMP` は UTC の `YYYYMMDDTHHMMSSZ`。スクリプトはこの形のディレクトリだけを選び、30 日前の UTC 日時より古い名前を消す
- 移したファイルの更新時刻は古いままなので、ファイルの更新時刻で 30 日を数えると、移した直後に消えることがある。ディレクトリ名で、古い版になってからの期間を数える
- 削除はバックアップを実行した回に行う。タイマーを止めている間は、30 日を過ぎても残る
- `old` の一覧取得はプロセス置換で行い、その終了状態は `status` に反映していない。一覧を取れなかった回は、古い版が残っていても `Result=success` になることがある

### Dropbox へのバックアップ / 手順 5: 補足: Forgejo のロックと停止・起動

- Quadlet `~/.config/containers/systemd/forgejo.container` があれば、[Forgejo の「Forgejo: バックアップ」](../forgejo.md#forgejo-バックアップ)と同じデータと Quadlet をアーカイブにする。ファイル名（`forgejo-daily-*`）、自動更新のロック、元から止まっていれば起動しないことは、毎日の自動の実行に合わせて変えてある
- `~/.local/state/forgejo-auto-update/lock` は自動更新と共通。`flock -n` で待たずに取り、取れなければ Forgejo の部分を飛ばして失敗を残す。ほかのファイルの送信と古い版の削除は続け、最後は非 0 で終わる
- 元から起動していた Forgejo は、止める前に印のファイル（`~/.local/state/dropbox-backup/forgejo-stopped`）を作り、起動し直せたら消す。元から止まっていれば、印は作らず起動もしない
- 前の回で起動し直せずに印が残っていれば、次の回は、先に起動し直してから（動いていれば印を消すだけ）、いつもどおり止めてアーカイブを取る。起動できなければ、Forgejo の部分を失敗にして、ほかは続ける
- Quadlet が無くなった後に印だけ残っていれば、`--after-stop` は起動を試さずに印を消す
- 途中で失敗したときは、`EXIT` の `trap` が起動し直す。明示の `start` が失敗したときも `trap` を残して戻り、`trap` の `start` も失敗したときだけ `Forgejo: 起動し直せなかった` を出す。`trap` は、明示の `start` が成功してから外す
- `systemctl --user stop dropbox-backup.service` などで止められたときは、`trap` に頼れない（Forgejo を止めている最中に止めると、`trap` があっても Forgejo は止まったままだった）。service の `ExecStopPost=` が `dropbox-backup --after-stop` を呼び、印が残っていれば起動し直す（同じ場合で 1.5 秒後に起動し直した）
- 保管ディレクトリは 0700、アーカイブは `umask 077` で 0600 にする。まず `.tmp` に書き、完了したら `forgejo-daily-<UTC 日時>.tar.gz` に変える
- 手元の `forgejo-daily-*` は新しい 3 つを残す。自動更新の `forgejo-auto-*` や手動のアーカイブは、この処理では消さない

### Dropbox へのバックアップ / 手順 5: 補足: user_systemctl

- `systemctl --user` が `Failed to connect to user scope bus` で失敗したときだけ、現在のユーザーの `--machine="$(id -un)@.host"` で再試行する。Forgejo の自動更新と同じ扱いで、ほかのエラーはそのまま返す
- このホストでは、`systemd-analyze --user verify` を実行すると、ユーザーの systemd の private ソケットのファイルが作り直され、待ち受けの無いファイルが残って、この状態になった（`daemon-reload` だけでは起きなかった）
- 手で貼るコマンドで出たときに直す `env -u XDG_RUNTIME_DIR systemctl --user daemon-reexec` は、`XDG_RUNTIME_DIR` を外して private ソケットを使わず、ユーザーの D-Bus から systemd を実行し直させる。実行し直した systemd は private ソケットを作り直し、動いているサービスは止まらない（実測は検証記録）
- 状態の説明は[注意点](../extra/dropbox-backup.md#注意点)に置く

### Dropbox へのバックアップ / 手順 6: 補足: podman-user-wait-network-online.service

- `Wants` と `After` で、Podman のネットワーク待ちの後にバックアップを始める。ユーザーの systemd からは、システム側の `network-online.target` を直接の待ち合わせには使えない
- このサービスが無いホストでも、`Wants` は `Requires` と違い、依存先が無いことだけではバックアップを失敗にしない。Dropbox に届かなければ、rclone 側が失敗を返す（[`man systemd.unit`](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html#Wants=)）
- `ExecStopPost=` は、成功・失敗・止められたのどれでも、service が止まった後に動く。印が無ければ何もしない（手順 5 の補足「Forgejo のロックと停止・起動」）
- `Type=oneshot` なので、手で `start` したときは完了まで戻らない。前の回が動いている間は、timer が同じサービスを重ねて始めることもない
- `%h` は systemd がホームに置き換える。スクリプト内の rclone は、systemd がシェルの設定を読まないので、Homebrew の絶対パスで呼ぶ

### Dropbox へのバックアップ / 手順 6: 補足: 03:10 と Persistent=true

- 03:10 はホストのローカル時刻。Forgejo の自動更新（04:00〜04:30）と Codeg の自動更新（04 時台）より前にバックアップを取る時刻にした
- `Persistent=true` は、止まっている間に実行時刻を過ぎていたら、タイマーを動かしたときに 1 回実行する。止まっていた日数分を繰り返す設定ではない（[`man systemd.timer`](https://www.freedesktop.org/software/systemd/man/latest/systemd.timer.html)）
- 起動後の追いつきで自動更新と重なっても、Forgejo は共通のロックで同時停止を避ける。時刻だけで競合を避ける仕組みではない

### Dropbox へのバックアップ / 手順 6: 補足: Nice と IOSchedulingClass

- `Nice=10` で CPU の優先度を下げ、`IOSchedulingClass=idle` でディスク I/O を空いているときに回す方針にする。I/O の優先度の効き方は、ディスクのスケジューラーにも依存する（[`man systemd.exec`](https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#Nice=)）

### Dropbox へのバックアップ / 手順 7: 補足: 初回の Forgejo のアーカイブ

- Forgejo のアーカイブは、手順 8 で初めてスクリプトが作る。手順 7 の時点ではまだ無いので、その行は出ない

### Dropbox へのバックアップ / 手順 8: 補足: journalctl --user-unit

- `journalctl --user-unit dropbox-backup.service` は、ユーザー unit を条件にログを読む。`journalctl --user -u ...` がユーザーの journal ファイルを見つけられない揮発の journal でも読める形にし、永続の journal でも同じコマンドを使う（[`man journalctl`](https://www.freedesktop.org/software/systemd/man/latest/journalctl.html#--user-unit=)）

### Dropbox へのバックアップ / 手順 10: 補足: 保存したパスワードの確認

- `current` にある空でないファイルのうち、一番小さいものを 1 つ選び（`--format sp` の大きさで並べる）、保存したパスワードから、そのコマンドの間だけ有効な `pwcheck:` を環境変数で組み立てる。登録済みの `dropbox-backup:` の設定は書き換えない
- crypt の `password` に渡す値は難読化済みにする必要がある。`rclone obscure -` は標準入力から受け取り、難読化した値を返す（[obscure](https://rclone.org/commands/rclone_obscure/)）
- `rclone check --download` で、`pwcheck:` で復号した中身と、登録済みの `dropbox-backup:` で復号した中身を比べる。どちらかの読み出し（復号）に失敗しても、中身が違っても、終了コードが 0 以外になり `NG` になる。パスワードの文字列や復号した中身は画面へ出さない
- `--min-size 1B` で空のファイルを外す。空のファイルは暗号化しても認証するデータが無く、違うパスワードでも空として読めてしまう
- `--files-from` で、選んだ 1 つのパスをそのまま渡す（`--include` と違い、パスの `*`・`[` などを模様として読まない）
- この確認は、選んだ 1 ファイルの比較。すべてのバックアップの完全性を検査するものではない

### Dropbox へのバックアップ: 戻す / 手順 2: 補足: --include の 2 行

- `--include "/${RESTORE_PATH}"` はそのパスのファイルを、`--include "/${RESTORE_PATH}/**"` はフォルダーの中身を選ぶ。同じ手順でファイルとフォルダーの両方を戻せる
- パスは `RESTORE_FROM` で選んだ `current` または `old/<日時>` からの相対パス。`rclone copy` はそのパスの階層を `~/dropbox-restore` の下にも残す

### 選択した方針

- `~/Dropbox` の双方向同期は使わず、ホームから Dropbox への片方向のバックアップにする。Dropbox 側の削除を手元へ伝えず、手元の削除・上書き前の版を `old` に残す
- Raspberry Pi 5 の aarch64 には Dropbox の公式クライアントが無いので、Homebrew の rclone を使う。認証までを[Dropbox と rclone](../dropbox.md#dropbox-と-rclone)の手順 1〜4 で通し、双方向同期の設定へは進まない

### 参照

- [Crypt — rclone](https://rclone.org/crypt/) — crypt の構成、ファイル名とディレクトリ名、パスワード、更新時刻
- [sync — rclone](https://rclone.org/commands/rclone_sync/)・[--backup-dir — rclone](https://rclone.org/docs/#backup-dir-dir) — 片方向の同期と、削除・上書き前の版の退避
- [Filtering — rclone](https://rclone.org/filtering/) — フィルタの順序、`+` と `-`、`--include`、`--delete-excluded`
- [config create — rclone](https://rclone.org/commands/rclone_config_create/) — `--obscure` と NB
- [obscure — rclone](https://rclone.org/commands/rclone_obscure/) — 設定に渡すパスワードの難読化と標準入力
- [`man systemd.timer`](https://www.freedesktop.org/software/systemd/man/latest/systemd.timer.html)（`OnCalendar=` / `Persistent=`）
- [Forgejo: バックアップ](../forgejo.md#forgejo-バックアップ)・[Forgejo: バックアップから復元する](../forgejo.md#forgejo-バックアップから復元する)

---
