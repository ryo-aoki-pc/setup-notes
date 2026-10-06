# Syncthing インストール手順（AlmaLinux 10 は Homebrew + systemd ユーザーサービス / Windows 11 は公式の zip + タスク スケジューラ）

## 実施手順

- [検証記録](verification/syncthing.md)・[参考資料](reference/syncthing.md)

> [!IMPORTANT]
> - **この実施手順は AlmaLinux 10 のもの**。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)から通す（管理者の Windows PowerShell 5.1 に貼る）
> - **前提**: [Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **前提**: [linger](linger.md) を有効にしてあること（ログアウト中も Syncthing を動かすため）。`loginctl show-user "$(id -u)" -p Linger` が `Linger=yes` を返さなければ、先に通す
> - **自分のシェルで実行する**。Homebrew の導入・管理は一般ユーザーで行い、Syncthing も同期するファイルの持ち主として動かす
> - **手順 2・3 には対話入力がある**（手順 2 は Homebrew が依存の確認を出した場合、手順 3 はパスワード）。完了してから次の手順を貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 手順の後: 同期するフォルダは[同期フォルダとデバイスを追加する（任意）](#同期フォルダとデバイスを追加する任意)、GUI の接続元を制限するなら[接続元を絞る（任意）](#接続元を絞る任意)、鍵と設定を自動で取っておくなら[設定を自動でバックアップする（任意）](#設定を自動でバックアップする任意)。以後は[更新](#更新)・[ロールバック](#ロールバック)
- OS を入れ直したホストを同じデバイス ID で戻すなら、先に[バックアップから戻す](#バックアップから戻す)の手順 1・2・4・5 を行ってから、手順 1 から通す

1. 変数を設定する。

   ```bash
   ST_GUI_USER=$(id -un)               # GUI のログイン名。OS のアカウントとは別物（自動で同じ名前が入る）。<USER>
   ST_GUI_ADDR=0.0.0.0:8384            # GUI の待ち受け。LAN にも公開する。手元だけなら 127.0.0.1:8384
   ST_LAN_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | sed -n 's/.* src \([0-9.]*\).*/\1/p')   # 案内と検証に使う（自動）。<SERVER_IP>
   for v in USER ST_GUI_USER ST_GUI_ADDR ST_LAN_IP; do
     printf '%-12s = %s\n' "$v" "${!v}"
   done
   ```

   - **編集が必須の変数は無い**。Web GUI を LAN にも公開する前提で既定値が入っている
   - 手元のブラウザからしか開かないなら、`ST_GUI_ADDR` を `127.0.0.1:8384` にする
   - 最後に値を読み戻して確かめる
   - `USER` が `root` なら、ここで止めて自分のシェルに戻る。`ST_GUI_ADDR=0.0.0.0:8384` の場合は、`ST_LAN_IP` が空か意図した NIC の IP と違えば直す（localhost の URL には使わない）
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**（SSH を張り直したあとも）、手順 1 を貼り直す。手順 5〜7 へ進む場合は、認証設定の成功を確かめるため手順 3・4 もやり直す

1. brew で Syncthing を入れる。

   ```bash
   brew install syncthing
   ```

   - aarch64 でもビルド済みのボトルが降ってくるので、Go のビルドにはならない
   - 依存は無い（静的バイナリ 1 つ、約 30 MB）
   - **次の手順は、Homebrew の確認が出たら答え、導入が成功してプロンプトに戻ってから貼る**（続けて貼ると確認の答えとして食われる）

1. GUI のパスワードを読み取る。

   ```bash
   read -rsp 'Syncthing GUI のパスワード: ' ST_GUI_PASS; echo
   ```

   - **入力は画面に出ない**
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. サービスを起動する前に、鍵・証明書・設定ファイルを作り、GUI のログイン名とパスワードを入れる。

   ```bash
   ST_GUI_AUTH_READY=false
   if [ -z "${ST_GUI_USER}" ] || [ -z "${ST_GUI_PASS}" ]; then
     echo '中断: GUI のログイン名かパスワードが空。手順 1・3 で設定し直す' >&2
   elif printf '%s' "${ST_GUI_PASS}" | syncthing generate --gui-user="${ST_GUI_USER}" --gui-password=-; then
     ST_GUI_AUTH_READY=true
     brew list --versions syncthing
     syncthing --version
     syncthing device-id
   else
     echo '中断: GUI の認証設定に失敗した。原因を直して手順 3 からやり直す' >&2
   fi
   unset ST_GUI_PASS
   ```

   - LAN に開いたあとで認証を設定するのでは、その間 GUI が誰でも開ける状態になるため、サービスの起動より先に入れる
   - `中断:` が出たら手順 5〜7 へ進まない。認証設定に成功した同じシェルだけで、手順 5〜7 を実行できる
   - `Calculated device ID (device=...)` と `Updated GUI authentication user` / `Updated GUI authentication password` の 3 行が出る
   - [バックアップから戻した](#バックアップから戻す)ホストでは、先頭が `Key exists; will not overwrite` になり、鍵を作り直さない（デバイス ID は元のまま。ログイン名が同じなら `Updated GUI authentication user` の行は出ない）
   - 最後の `syncthing device-id` が出す 7 桁 x 8 の文字列が、**このホストのデバイス ID**。相手デバイスに教える値で、秘密ではない

1. Syncthing のサービスを開始する。

   ```bash
   if [ "${ST_GUI_AUTH_READY:-false}" != true ]; then
     echo '中断: このシェルで手順 3・4 の認証設定を完了してから貼る' >&2
   else
     brew services start syncthing &&
       brew services list &&
       systemctl --user is-enabled sh.brew.syncthing.service &&
       systemctl --user is-active sh.brew.syncthing.service
   fi
   ```

   - `Successfully started 'syncthing' (label: sh.brew.syncthing)` が出る
   - `~/.config/systemd/user/sh.brew.syncthing.service` が置かれる
   - [linger](linger.md) が有効なので、ログアウトしても止まらない（linger が無いと、SSH を切った時点で Syncthing も止まる）

1. GUI の待ち受けと HTTPS を設定し、再起動して確かめる。

   ```bash
   if [ "${ST_GUI_AUTH_READY:-false}" != true ]; then
     echo '中断: このシェルで手順 3・4 の認証設定を完了してから貼る' >&2
   elif [ -z "${ST_GUI_ADDR}" ]; then
     echo '中断: 手順 1 の ST_GUI_ADDR が空。値を入れて貼り直す' >&2
   else
     for attempt in 1 2; do
       syncthing cli config gui raw-address set "${ST_GUI_ADDR}" &&
         syncthing cli config gui raw-use-tls set true && break
       sleep 3
     done
     if ST_GUI_ACTUAL_ADDR=$(syncthing cli config gui raw-address get) &&
        ST_GUI_ACTUAL_TLS=$(syncthing cli config gui raw-use-tls get) &&
        [ "${ST_GUI_ACTUAL_ADDR}" = "${ST_GUI_ADDR}" ] &&
        [ "${ST_GUI_ACTUAL_TLS}" = true ]; then
       printf '%s\n' "${ST_GUI_ACTUAL_ADDR}" "${ST_GUI_ACTUAL_TLS}"
       brew services restart syncthing &&
         sleep 3 &&
         ss -ltnp | grep 8384
     else
       echo '中断: GUI の待ち受けか TLS が設定値と違う。サービスのログを調べ、手順 6 をやり直す' >&2
     fi
   fi
   ```

   - 手順 3〜4 で認証を入れてあるので、ここで待ち受けを広げる
   - 読み戻したアドレスが `ST_GUI_ADDR`、TLS が `true`、8384/tcp がそのアドレスで `LISTEN` ならよい（`0.0.0.0` は `*` と出る場合もある）
   - GUI の設定変更は API の待ち受けも切り替えるため、設定が保存されても CLI が `EOF` で終わることがある。3 秒待って 1 度だけ再試行し、読み戻した両方の値が一致してから再起動する。`中断:` が出たら手順 7 へ進まない

   - 設定後は再起動して待ち受けと TLS を確かめる
1. firewalld で同期用と、LAN に公開する場合の GUI 用のポートを開ける。

   ```bash
   if [ "${ST_GUI_AUTH_READY:-false}" != true ]; then
     echo '中断: このシェルで手順 3・4 の認証設定を完了してから貼る' >&2
   elif [ -z "${ST_GUI_ADDR}" ]; then
     echo '中断: 手順 1 の ST_GUI_ADDR を設定してから貼る' >&2
   else
     if [ "${ST_GUI_ADDR}" = 127.0.0.1:8384 ]; then
       sudo firewall-cmd --permanent --add-service=syncthing && sudo firewall-cmd --reload
     else
       sudo firewall-cmd --permanent --add-service=syncthing --add-service=syncthing-gui && sudo firewall-cmd --reload
     fi
     sudo firewall-cmd --list-services
   fi
   ```

   - `syncthing` は同期と探索（22000/tcp、22000/udp、21027/udp）
   - `syncthing-gui` は Web GUI（8384/tcp）
   - `127.0.0.1:8384` の場合は `syncthing` だけ、それ以外は両方が一覧に含まれればよい
   - どちらも firewalld に最初から入っている定義済みサービスで、自分で書く必要はない

1. サービスと待ち受けを確かめ、GUI の URL を出す。

   ```bash
   brew services list
   systemctl --user is-active sh.brew.syncthing.service
   ss -ltunp | grep -E ':(8384|22000|21027)'
   syncthing device-id
   tail -5 /home/linuxbrew/.linuxbrew/var/log/syncthing.log
   if [ -z "${ST_GUI_ADDR}" ] || [ -z "${ST_GUI_USER}" ]; then
     echo '中断: 手順 1 の変数を設定してから GUI の URL を確かめる' >&2
   elif [ "${ST_GUI_ADDR}" = 0.0.0.0:8384 ] && [ -z "${ST_LAN_IP}" ]; then
     echo '中断: 手順 1 の ST_LAN_IP が空。LAN の IP を設定する' >&2
   elif [ "${ST_GUI_ADDR}" = 0.0.0.0:8384 ]; then
     printf 'GUI: https://%s:8384/  （ログイン名 %s）\n' "${ST_LAN_IP}" "${ST_GUI_USER}"
   else
     printf 'GUI: https://%s/  （ログイン名 %s）\n' "${ST_GUI_ADDR}" "${ST_GUI_USER}"
   fi
   ```

   - 8384/tcp と 22000/tcp が `LISTEN`、22000/udp と 21027/udp が `UNCONN` で出れば待ち受けている

1. ブラウザで GUI に入り、デバイス ID を確かめる。

   - 手順 8 の URL を開き、自己署名証明書の警告を受け入れ、手順 3〜4 で決めたログイン名とパスワードで入る
   - `ST_GUI_ADDR=127.0.0.1:8384` の場合は、このホストのブラウザで開く。LAN に公開した場合は、LAN の別の端末から開いて firewalld 越しの到達も確かめる
   - Actions → Show ID で出るデバイス ID が、`syncthing device-id` と同じであることを確認する
   - **この時点では同期するフォルダは 1 つも無い**（Syncthing 2.x は既定フォルダを作らない）
   - バックアップから戻したホストでは、戻したフォルダが並ぶ。フォルダのディレクトリと `.stfolder` は Syncthing が作り、中身は相手の端末から届く

---

## 同期フォルダとデバイスを追加する（任意）

- **Syncthing 2.x は初回起動時に既定フォルダ（`~/Sync`）を作らない**。入れただけでは何も同期しないので、GUI から足す
- 操作は AlmaLinux 10 でも Windows 11 でも同じ。相手もどちらでもよい

> [!WARNING]
> **この節の手順 4 で、ホームディレクトリ（Windows 11 では `C:\Users\<WIN_USER>`）を丸ごと同期対象にしない。** `~/.local/state/syncthing`（Windows 11 では `AppData\Local\Syncthing`）自身や `~/.cache`、ほかのアプリのデータまで同期してしまう。
>
> - 同期したいものを入れる専用のディレクトリを作る（例: `~/Sync`、`C:\Users\<WIN_USER>\Sync`）
> - このホストは [Samba](samba.md) でホームを公開しているので、同じ領域を二重に扱うことになる点にも注意する
> - Windows 11 では、OneDrive に移したデスクトップ・ドキュメントや、Dropbox のフォルダーも入れない（2 つの同期が同じファイルを書き合う）

1. 相手側のデバイスでも同じように Syncthing を入れ、そのデバイス ID を控える。

   - 相手が AlmaLinux 10 なら[実施手順](#実施手順)、Windows 11 の PC なら [Windows 11 で使う](#windows-11-で使う)で入れる

1. GUI の「リモートデバイスを追加」に相手のデバイス ID を貼る。

   - 同じ LAN にいるなら、21027/udp のローカル探索で相手が自動的に見つかる
   - VPN 越しの拠点同士は探索が届かないことがある。その場合は、デバイスのアドレスに `tcp://10.99.0.1:22000`（`tcp://<相手の IP>:22000`）のように直接書く

1. 相手側の GUI に出る承認の通知で、このデバイスを承認する。

1. 「フォルダーを追加」でパス（例: `~/Sync`、Windows 11 では `C:\Users\<WIN_USER>\Sync`）とフォルダー ID を決め、「共有」タブで相手デバイスにチェックを入れる。

1. 相手側に「このデバイスがフォルダーを共有しようとしています」と出るので受け入れる。

---

## 接続元を絞る（任意）

- **接続元を制限しないなら、この節は不要**
- [手順 7](#実施手順) は、public ゾーンに属するすべての NIC（この環境では `end0` と `wg0`）で 8384/tcp を開く
- 同期そのもの（22000）まで絞ると、相手デバイスの側の経路が変わったときに黙って同期が止まる。**絞るのは GUI だけにしておく方が事故が少ない**

1. GUI だけを特定のサブネットに絞るため、`syncthing-gui` の開放を rich rule に置き換える。

   ```bash
   ST_ALLOW_FROM="192.168.1.0/24 10.99.0.0/30"     # ← 自分の値に書き換える。<ST_ALLOW_FROM>
   ```

   ```bash
   if [ -z "${ST_ALLOW_FROM}" ]; then echo '中断: ST_ALLOW_FROM が空のまま。値を入れて貼り直す' >&2; else
   sudo firewall-cmd --permanent --remove-service=syncthing-gui
   for src in ${ST_ALLOW_FROM}; do
     sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=${src} service name=syncthing-gui accept"
   done
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-rich-rules        # source address に実際のサブネットが入っていることを確認する
   fi
   ```

   - `ST_ALLOW_FROM` には、送信元を空白区切りで入れる
   - 先頭の `if` は、`ST_ALLOW_FROM` が空のままブロックを貼ったときに、`syncthing-gui` の開放だけ消えて rich rule が 1 本も入らないのを防ぐ
   - rich rule は**二重引用符**で囲む。単一引用符だと `${src}` が展開されないまま `success` で受理される（[samba.md](samba.md) と同じ落とし穴）

1. 元に戻すときは、絞ったときと同じ `ST_ALLOW_FROM` を入れてから、`syncthing-gui` の開放に戻す。

   ```bash
   if [ -z "${ST_ALLOW_FROM}" ]; then echo '中断: ST_ALLOW_FROM が空のまま。絞ったときと同じ値を入れて貼り直す' >&2; else
   for src in ${ST_ALLOW_FROM}; do
     sudo firewall-cmd --permanent --remove-rich-rule="rule family=ipv4 source address=${src} service name=syncthing-gui accept"
   done
   sudo firewall-cmd --permanent --add-service=syncthing-gui
   sudo firewall-cmd --reload
   fi
   ```

---

## 設定を自動でバックアップする（任意）

- 鍵（`cert.pem` / `key.pem`。デバイス ID のもと）・`config.xml`・GUI の証明書（`https-cert.pem` / `https-key.pem`）を、`~/syncthing-backup/syncthing-config-<日時>.tar.gz` にまとめる。DB（`index-v2`）は入れない
- `config.xml` が書き換わると数秒後に取る（systemd の path ユニット）。取りこぼしの保険として 1 日 1 回も取る（タイマー）
- 最新のアーカイブと中身が同じなら作らない。新しい順に 100 個残す
- この節の手順 4〜6 で `~/syncthing-backup` を送信専用フォルダにして、別の端末へ複製する
- **アーカイブには秘密鍵・GUI パスワードのハッシュ・API キーが入る**。複製先の端末も同じ重さで扱い、リポジトリやほかの共有には置かない
- 戻し方は[バックアップから戻す](#バックアップから戻す)

1. バックアップのスクリプトを置く。

   ```bash
   install -d -m 0700 ~/syncthing-backup
   mkdir -p ~/.local/bin
   cat > ~/.local/bin/syncthing-backup <<'EOF'
   #!/usr/bin/bash
   # Syncthing の鍵と設定を、引数で渡した保存先に syncthing-config-日時.tar.gz としてまとめる。
   # 最新のアーカイブと中身が同じなら作らない。新しい順に 100 個残す。
   set -euo pipefail
   shopt -s nullglob

   dest=${1:?保存先のディレクトリを引数に渡す}
   if [ ! -d "${dest}" ]; then
     echo "保存先が無い: ${dest}" >&2
     exit 1
   fi

   cd "${HOME}/.local/state/syncthing"
   files=(cert.pem key.pem config.xml)
   for f in https-cert.pem https-key.pem; do
     if [ -e "${f}" ]; then files+=("${f}"); fi
   done

   old=("${dest}"/syncthing-config-*.tar.gz)
   if ((${#old[@]})) &&
     [ "$(tar -tzf "${old[-1]}")" = "$(printf '%s\n' "${files[@]}")" ] &&
     [ "$(tar -xzOf "${old[-1]}" | sha256sum)" = "$(cat "${files[@]}" | sha256sum)" ]; then
     echo "変更なし: ${old[-1]##*/}"
     exit 0
   fi

   umask 077
   name="syncthing-config-$(date +%Y%m%d-%H%M%S).tar.gz"
   tmp="${dest}/.syncthing.${name}.tmp"
   trap 'rm -f "${tmp}"' EXIT
   tar -czf "${tmp}" "${files[@]}"
   mv "${tmp}" "${dest}/${name}"
   echo "作成: ${name}"

   old=("${dest}"/syncthing-config-*.tar.gz)
   if ((${#old[@]} > 100)); then
     rm -v -- "${old[@]:0:${#old[@]}-100}"
   fi
   EOF
   chmod 0755 ~/.local/bin/syncthing-backup
   ```

   - 保存先の `~/syncthing-backup`（0700）と、スクリプト `~/.local/bin/syncthing-backup` ができる
   - スクリプトは保存先のディレクトリが無いと、作らずに失敗する
   - 使うのは `tar`・`gzip`・`sha256sum` だけ（`cmp` は使わない。理由はこの手順の補足）

1. systemd のユーザーユニットを 3 つ置き、読み込ませる。

   ```bash
   mkdir -p ~/.config/systemd/user
   cat > ~/.config/systemd/user/syncthing-backup.service <<'EOF'
   [Unit]
   Description=Back up Syncthing keys and config.xml

   [Service]
   Type=oneshot
   ExecStartPre=/usr/bin/sleep 5
   ExecStart=%h/.local/bin/syncthing-backup %h/syncthing-backup
   EOF
   cat > ~/.config/systemd/user/syncthing-backup.path <<'EOF'
   [Unit]
   Description=Back up Syncthing config when config.xml changes

   [Path]
   PathChanged=%h/.local/state/syncthing/config.xml

   [Install]
   WantedBy=paths.target
   EOF
   cat > ~/.config/systemd/user/syncthing-backup.timer <<'EOF'
   [Unit]
   Description=Back up Syncthing config daily

   [Timer]
   OnCalendar=daily
   Persistent=true
   RandomizedDelaySec=1h

   [Install]
   WantedBy=timers.target
   EOF
   systemctl --user daemon-reload
   ```

   - `.service` がスクリプトを 1 回走らせる
   - `.path` は `config.xml` が書き換わったとき、`.timer` は毎日 0:00〜1:00 のどこかで `.service` を起動する
   - 何も表示されなければよい
   - **注意**: ユニットの検査に `systemd-analyze --user verify` を使わない（`systemctl --user` が使えなくなる。この手順の補足）

1. path とタイマーを有効にし、1 回目を取って確かめる。

   ```bash
   systemctl --user enable --now syncthing-backup.path syncthing-backup.timer
   systemctl --user start syncthing-backup.service
   systemctl --user show -p Result,ExecMainStatus syncthing-backup.service
   systemctl --user is-active syncthing-backup.path syncthing-backup.timer
   systemctl --user list-timers syncthing-backup.timer
   ls -l ~/syncthing-backup
   ```

   - `start` は 5 秒ほど戻らない（`ExecStartPre` の待ち）
   - `Result=success` と `ExecMainStatus=0`、続けて `active` が 2 行出る
   - `list-timers` の `NEXT` に、次の 0 時台の時刻が出る
   - `~/syncthing-backup` に `-rw-------` のアーカイブが 1 つできる
   - バックアップから戻したホストなら、この節の手順 4〜6 は飛ばす（送信専用フォルダは戻した `config.xml` に入っている）

1. `~/syncthing-backup` を送信専用フォルダとして登録し、相手と共有する（戻したホストでは要らない）。

   ```bash
   syncthing cli config folders add --id "syncthing-backup-$(uname -n)" --label "syncthing-backup ($(uname -n))" \
     --path "${HOME}/syncthing-backup" --type sendonly
   syncthing cli config folders list
   sleep 10
   ls -la ~/syncthing-backup
   ```

   - `folders list` に `syncthing-backup-<HOSTNAME>` が出る
   - `~/syncthing-backup` に `.stfolder` ができる
   - アーカイブが 1 つ増える（登録で `config.xml` が変わったため。path ユニットが働いていることの確認になる）

1. GUI で、このフォルダを相手の端末と共有する。

   - このフォルダの「編集」→「共有」タブを開き、相手の端末にチェックを入れて保存する
   - 相手の端末は、先に[同期フォルダとデバイスを追加する（任意）](#同期フォルダとデバイスを追加する任意)の手順 2・3 で追加しておく

1. 相手の端末で、共有を受け入れる。

   - フォルダーの種類を**受信専用**（Receive Only）にする
   - ファイルのバージョン管理（File Versioning）を**ゴミ箱**（Trash Can）にする。こちらで 100 個を超えて消した古いアーカイブは、相手でも消えるため
   - このフォルダを、相手自身の Syncthing の設定ディレクトリにしない

1. 元に戻すときは、ユニットとスクリプトを外し、送信専用フォルダの登録を消す。

   ```bash
   systemctl --user disable --now syncthing-backup.path syncthing-backup.timer
   rm -f ~/.config/systemd/user/syncthing-backup.{service,path,timer} ~/.local/bin/syncthing-backup
   systemctl --user daemon-reload
   for id in $(syncthing cli config folders list); do
     if [ "$(syncthing cli config folders "${id}" path get)" = "${HOME}/syncthing-backup" ]; then
       syncthing cli config folders "${id}" delete && echo "登録を消した: ${id}"
     fi
   done
   syncthing cli config folders list
   ```

   - `登録を消した: syncthing-backup-<HOSTNAME>` が出て、`folders list` から消える
   - フォルダは ID ではなくパスで探す（バックアップから戻したホストでは、ID に元のホスト名が入っている）
   - 登録を消すと、Syncthing が `~/syncthing-backup/.stfolder` も消す。アーカイブは残る
   - 相手の端末のコピーも残る。要らなければ、相手の GUI でフォルダを削除する

---

## バックアップから戻す

- **同じホストで設定を壊したとき**は、この節の手順 3〜6 を貼る
  - path ユニットは壊れた設定も取っている。壊す前の時刻のアーカイブを選ぶ
- **OS を入れ直したホストを、同じデバイス ID で戻すとき**は、この節の手順 1・2・4・5 を[実施手順](#実施手順)より先に行い、そのあと実施手順を手順 1 から通す
  - [手順 4](#実施手順) の `syncthing generate` は戻した鍵をそのまま使う。デバイス ID・フォルダ・API キーは戻したものになり、GUI のパスワードだけ入れ直す
  - 自動バックアップも、[設定を自動でバックアップする（任意）](#設定を自動でバックアップする任意)の手順 1〜3 で入れ直す
- DB は入っていないので、OS を入れ直したホストは初回の起動で全フォルダを読み直し、中身を相手の端末から受け取る。フォルダのディレクトリと `.stfolder` は Syncthing が作る
- 外付けディスクにあるフォルダは、Syncthing を起動する前にマウントしておく

> [!WARNING]
> - **同じアーカイブから戻した Syncthing を、2 台で同時に動かさない。** 同じデバイス ID が 2 つになる。元のホストを入れ直すときにだけ使う
> - **この節の手順 2 でアーカイブを全部持ってこないと、送信専用フォルダが「同期されていない」ままになる。** その状態で赤い上書きのボタン（Override Changes）を押すと、持ってこなかったアーカイブが相手の端末から消える

1. OS を入れ直したときだけ、アーカイブの置き場所を作る。

   ```bash
   install -d -m 0700 ~/syncthing-backup
   ```

1. OS を入れ直したときだけ、相手の端末からアーカイブを全部持ってくる。

   - 相手の端末の受信専用フォルダから、`syncthing-config-*.tar.gz` を全部 `~/syncthing-backup/` にコピーする（例: `scp '<相手のホスト>:<相手のフォルダ>/syncthing-config-*.tar.gz' ~/syncthing-backup/`）
   - OS を入れ直したホストでは、この節の手順 3 は飛ばす

1. 同じホストで戻すときだけ、Syncthing を止める。

   ```bash
   brew services stop syncthing
   ```

   - `Successfully stopped` が出る
   - 自動バックアップの path ユニットとタイマーは止めなくてよい

1. 戻すアーカイブを選び、中身を確かめる。

   ```bash
   ST_BACKUP=$(ls -1 ~/syncthing-backup/syncthing-config-*.tar.gz 2>/dev/null | tail -n 1)   # 戻すアーカイブ（自動で最新が入る）
   ```

   ```bash
   printf '%-10s = %s\n' ST_BACKUP "${ST_BACKUP}"
   ls -l ~/syncthing-backup
   tar -tzvf "${ST_BACKUP:?この節の手順 4 の ST_BACKUP が空のまま。アーカイブのパスを入れて貼り直す}"
   ```

   - `ST_BACKUP` には名前順で最後（＝最新）のアーカイブが入る
   - 壊したあとで戻すなら、`ls -l` の一覧から壊す前の時刻のものを選び、`ST_BACKUP=~/syncthing-backup/syncthing-config-<日時>.tar.gz` のように入れ直す
   - `tar` の一覧に `cert.pem`・`key.pem`・`config.xml` が並ぶ（TLS を有効にしてあれば `https-cert.pem`・`https-key.pem` も）
   - **次の手順は、表示された内容でよいか確かめてから貼る**

1. 設定ディレクトリに展開する。

   ```bash
   if [ -z "${ST_BACKUP}" ] || [ ! -f "${ST_BACKUP}" ]; then
     echo '中断: この節の手順 4 で存在するアーカイブを選び直す' >&2
   else
     install -d -m 0700 ~/.local/state/syncthing &&
       tar -xzf "${ST_BACKUP}" -C ~/.local/state/syncthing &&
       ls -la ~/.local/state/syncthing
   fi
   ```

   - `cert.pem`・`key.pem`・`config.xml` が並ぶ。同じホストでは DB（`index-v2`）もそのまま残る
   - 同じホストで自動バックアップを有効にしてあれば、展開した `config.xml` を path ユニットが新しいアーカイブとして取る（戻した設定が最新になるだけで、害は無い）
   - OS を入れ直したホストでは、この後[手順 1](#実施手順)から通す（この節の手順 6 は飛ばす）

1. 同じホストで戻すときだけ、Syncthing を開始して確かめる。

   ```bash
   brew services start syncthing
   sleep 3
   syncthing device-id
   syncthing cli config gui raw-address get
   syncthing cli config gui raw-use-tls get
   syncthing cli config folders list
   ```

   - デバイス ID が戻す前と同じ
   - GUI の待ち受け・TLS・フォルダが、選んだアーカイブの時点のものになっている
   - `brew services start` は、この節の手順 3 の `stop` で外れた自動起動の登録も戻す（`Created symlink ... default.target.wants/sh.brew.syncthing.service` が出る）

---

## 更新

- AlmaLinux 10 の手順。Windows 11 は [Windows 11 の更新](#windows-11-の更新)

1. Syncthing を更新する。

   ```bash
   brew upgrade syncthing
   ```

   - すべてまとめて上げるなら `brew upgrade`
   - **brew 版は自分では更新しない**（`noupgrade` ビルド）ので、放っておいても勝手に版が上がることはない
   - `brew upgrade` は実行ファイルを差し替えるだけなので、**動いているプロセスは古いままになる。再起動まで必ず行う**
   - **次の手順は、Homebrew の確認が出たら答え、更新が成功してプロンプトに戻ってから貼る**（続けて貼ると確認の答えとして食われる）

1. サービスを再起動し、更新した版を確かめる。

   ```bash
   brew services restart syncthing
   syncthing --version
   ```

   - `syncthing --version` が更新した版になっていることを確かめる

---

## ロールバック

- AlmaLinux 10 の手順。Windows 11 は [Windows 11 のロールバック](#windows-11-のロールバック)
- 上から順に実行する
- 接続元を絞る節を使った場合は `syncthing-gui` ではなく rich rule が入っているので、先に[接続元を絞る（任意）](#接続元を絞る任意)の手順 2 を貼る
- 自動バックアップを設定した場合は、Syncthing が動いているうちに、先に[設定を自動でバックアップする（任意）](#設定を自動でバックアップする任意)の手順 7 を貼る
- 同期していたファイル自体は、この節のどの手順でも消えない
- linger も切るときは、この節の後に [linger.md のロールバック](linger.md#ロールバック)を行う（ほかに linger を使うものが無いかは、そこで確かめる）

> [!CAUTION]
> **この節の**手順 3 で設定・鍵・DB を**消すとデバイス ID が失われ、相手デバイスからは別のデバイスとして見える**。入れ直す可能性があるなら残すか、自動バックアップのアーカイブ（`~/syncthing-backup`）を取っておく（[バックアップから戻す](#バックアップから戻す)で同じデバイス ID に戻せる）。

1. サービスを止めて、Syncthing を消す。

   ```bash
   brew services stop syncthing
   brew uninstall syncthing
   ```

   - Syncthing を動かしていたユーザー自身のシェルで貼る（Homebrew の削除・サービス管理も、そのユーザーで行う）
   - `brew services stop` は停止に加えて**自動起動の登録も外す**（`brew services --help` の「unregister it from launching at login」）
   - 設定・鍵・DB（`~/.local/state/syncthing`）とログ（`/home/linuxbrew/.linuxbrew/var/log/syncthing.log`）は残る

1. ファイアウォールの設定を外す。

   ```bash
   sudo firewall-cmd --permanent --remove-service=syncthing --remove-service=syncthing-gui && sudo firewall-cmd --reload
   ```

1. 完全に消すときだけ、設定・鍵・DB とログを消す（取り戻せない）。

   ```bash
   rm -rf ~/.local/state/syncthing /home/linuxbrew/.linuxbrew/var/log/syncthing.log
   ```

   - 自動バックアップのアーカイブ（`~/syncthing-backup`）は消えない

---

## Windows 11 で使う

> [!IMPORTANT]
> - **すべて Windows で行う**。この節の手順 1 で管理者の Windows PowerShell（5.1）を開き、この節の手順 2〜11・14 と、後ろの Windows 11 の 3 節（止める・更新・ロールバック）をそこに貼る。ログインするユーザーは Administrators の一員（この節の手順 7 の受信の規則と手順 8 のタスクの登録に、管理者の権限が要る）
> - 前提: [Windows 11 の初期設定の手順 16〜19](windows-setup.md#実施手順)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ貼り付けの設定）。通していなければ、ブロックは Ctrl+V で貼る
> - 前提: 相手とつながる LAN の接続がプライベートであること（[Windows 11 の初期設定の手順 43](windows-setup.md#実施手順)）。この節の手順 7 で確かめる
> - Syncthing そのものは、管理者ではない自分のユーザーとして、サインインしている間だけ動く（この節の手順 8 のタスク）
> - **この節の手順 5 には対話入力がある**（GUI のパスワード）。入力し終えてから手順 6 を貼る
> - **この節の手順 12 は LAN の別の端末のブラウザで、手順 13 はこの PC で行う**（サインアウトしてサインインし直す）

- 上から順にコードブロックを貼る。この節の手順 2 で変数を設定した PowerShell に貼る
- 手順の後: 同期するフォルダと相手のデバイスは[同期フォルダとデバイスを追加する（任意）](#同期フォルダとデバイスを追加する任意)、止めるときは[Windows 11 で止める・もう一度始める](#windows-11-で止めるもう一度始める)。以後は[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](#windows-11-のロールバック)
- この節の PC は、[実施手順](#実施手順)の AlmaLinux 10 の Syncthing の相手にもなる

1. Windows で、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く
   - PowerShell 7（`pwsh`）ではなく、Windows PowerShell 5.1 にする（この節の手順 6 のパイプの文字コードが違う）

1. 変数を設定する。

   ```powershell
   $ST_GUI_USER = $env:USERNAME          # GUI のログイン名。Windows のアカウントとは別物（自動で同じ名前が入る）。<WIN_USER>
   $LAN_IF = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).InterfaceAlias   # 相手とつながる LAN の接続（自動）。<LAN_IF>
   'ST_GUI_USER = {0}' -f $ST_GUI_USER
   'LAN_IF      = {0}' -f $LAN_IF
   ```

   - **編集が必須の変数は無い**
   - 最後に値を読み戻して確かめる
   - `LAN_IF` は、インターネットにつながっている接続の名前（`イーサネット`、`Wi-Fi` など）。相手とつながる接続と違えば、`$LAN_IF = 'Wi-Fi'` のように直す
   - 変数はその PowerShell の中だけで有効。**新しい PowerShell を開いたら**、この節の手順 2 のブロックを貼り直してから先へ進む

1. この PC に Syncthing が無いことを確かめる。

   ```powershell
   Get-Process -Name syncthing -ErrorAction SilentlyContinue | Format-Table Id, Path
   Get-ScheduledTask -TaskName 'Syncthing' -ErrorAction SilentlyContinue | Format-Table TaskName, State
   Get-NetTCPConnection -State Listen -LocalPort 8384, 22000 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess
   Test-Path "$env:LOCALAPPDATA\Syncthing\config.xml", "$env:LOCALAPPDATA\Programs\Syncthing"
   ```

   - 最初の 3 つは何も出さず、最後に `False` が 2 行出ればよい
   - 何か出たら、ほかの方法で入れた Syncthing（SyncTrayzor、Syncthing Windows Setup など）がある。それを止めて外してから始める
   - [Windows 11 のロールバック](#windows-11-のロールバック)の手順 1〜4 の後に入れ直すときは、1 行目の `True`（`config.xml`。前の鍵と設定）はそのままでよい。この節の手順 6 が前の鍵を使うので、デバイス ID は前と同じになる

1. 公式の zip を取って sha256 と署名を確かめ、`syncthing.exe` を置く。

   ```powershell
   & {
     $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
     $curl = "$env:WINDIR\System32\curl.exe"
     $arch = @{ AMD64 = 'amd64'; ARM64 = 'arm64' }[$env:PROCESSOR_ARCHITECTURE]
     $tmp = "$env:TEMP\syncthing-setup"
     if (Get-Process -Name syncthing -ErrorAction SilentlyContinue) { Write-Error '中断: Syncthing が動いている'; return }
     if (-not $arch) { Write-Error "中断: この手順は $env:PROCESSOR_ARCHITECTURE の Windows を扱わない"; return }
     Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
     New-Item -ItemType Directory -Path $tmp | Out-Null
     & $curl -fsSL -o "$tmp\sha256sum.txt.asc" https://github.com/syncthing/syncthing/releases/latest/download/sha256sum.txt.asc
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: sha256sum.txt.asc を取れない'; return }
     $m = Select-String -LiteralPath "$tmp\sha256sum.txt.asc" -CaseSensitive -Pattern "^([0-9a-f]{64})  (syncthing-windows-$arch-(v\d+\.\d+\.\d+)\.zip)$" | Select-Object -First 1
     if (-not $m) { Write-Error '中断: sha256sum.txt.asc に Windows 版の行が無い'; return }
     $hash = $m.Matches[0].Groups[1].Value
     $zip = $m.Matches[0].Groups[2].Value
     $ver = $m.Matches[0].Groups[3].Value
     & $curl -fsSL -o "$tmp\$zip" "https://github.com/syncthing/syncthing/releases/download/$ver/$zip"
     if ($LASTEXITCODE -ne 0) { Write-Error "中断: $zip を取れない"; return }
     if ((Get-FileHash -LiteralPath "$tmp\$zip" -Algorithm SHA256).Hash -ne $hash) { Write-Error "中断: $zip の sha256 が一致しない"; return }
     Expand-Archive -LiteralPath "$tmp\$zip" -DestinationPath $tmp -Force
     $new = Join-Path $tmp (($zip -replace '\.zip$', '') + '\syncthing.exe')
     $sig = Get-AuthenticodeSignature -LiteralPath $new
     if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notlike 'CN=Kastelo AB,*' -or -not $sig.TimeStamperCertificate) { Write-Error "中断: syncthing.exe の署名を確かめられない（$($sig.Status)）"; return }
     New-Item -ItemType Directory -Force -Path (Split-Path $exe) | Out-Null
     Copy-Item -LiteralPath $new -Destination $exe -Force
     Remove-Item -LiteralPath $tmp -Recurse -Force
     '{0}: sha256 一致、署名 {1}' -f $zip, $sig.Status
     & $exe --version
     icacls.exe (Split-Path $exe)
   }
   ```

   - `syncthing-windows-amd64-v2.1.5.zip: sha256 一致、署名 Valid` と、`syncthing v2.1.5 "Hafnium Hornet" (go1.27.1 windows-amd64) …` の 1 行が出ればよい（版は実行した日の最新）
   - `icacls` の一覧に、自分のユーザーの `(F)`（フル コントロール）の行がある（Syncthing の自動の更新が、このフォルダーに書くため）
   - `中断:` で始まるエラーが出たら、何も置いていない（取ってきたものは `%TEMP%\syncthing-setup` に残る。次に貼ったときに消して作り直す）
   - 何度貼ってもよい（Syncthing が動いているときは止まる）

1. GUI のパスワードを読み取る。

   ```powershell
   $ST_GUI_PASS = Read-Host -AsSecureString 'Syncthing GUI のパスワード'
   ```

   - **入力は `*` で表示される**
   - ASCII の英数字と記号だけにする（ほかの文字があると、この節の手順 6 で止まる）
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. 最初に起動する前に、鍵と設定を作り、GUI のログイン名とパスワードを入れる。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   if (-not $ST_GUI_USER) {
     Write-Error '手順 2 の $ST_GUI_USER が空'
   } elseif (-not $ST_GUI_PASS -or $ST_GUI_PASS.Length -eq 0) {
     Write-Error '手順 5 のパスワードが空'
   } else {
     $p = ([Net.NetworkCredential]::new('', $ST_GUI_PASS)).Password
     if ($p -cnotmatch '^[\x20-\x7e]+$') {
       Write-Error 'パスワードに ASCII でない文字がある（手順 5 からやり直す）'
     } else {
       $p | & $exe generate "--gui-user=$ST_GUI_USER" --gui-password=-
       if ($LASTEXITCODE -eq 0) { & $exe device-id }
     }
     Remove-Variable p
   }
   Remove-Variable ST_GUI_PASS -ErrorAction SilentlyContinue
   ```

   - `Calculated device ID`・`Updated GUI authentication user`・`Updated GUI authentication password` の行と、最後に 7 文字 x 8 の文字列が出ればよい
   - 最後の文字列が、**この PC のデバイス ID**。相手のデバイスに教える値で、秘密ではない
   - 前の鍵が残っている PC では、先頭が `Key exists; will not overwrite` になり、デバイス ID は前と同じ
   - エラーで止まったら、この節の手順 5 からやり直す（パスワードの変数はこの手順で消える）

1. LAN の接続がプライベートなことを確かめ、Syncthing の受信の規則を作る。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   $g = 'Syncthing (setup-notes)'
   if (-not $LAN_IF) {
     Write-Error '手順 2 の $LAN_IF が空'
   } elseif ((Get-NetConnectionProfile -InterfaceAlias $LAN_IF).NetworkCategory -ne 'Private') {
     Write-Error '中断: LAN の接続がプライベートではない（Windows 11 の初期設定の手順 43 でプライベートにする）'
   } else {
     Remove-NetFirewallRule -Group $g -ErrorAction SilentlyContinue
     New-NetFirewallRule -Name 'Syncthing-In-TCP' -DisplayName 'Syncthing (TCP 22000)' -Group $g -Direction Inbound -Action Allow -Profile Private -Program $exe -Protocol TCP -LocalPort 22000 | Out-Null
     New-NetFirewallRule -Name 'Syncthing-In-UDP' -DisplayName 'Syncthing (UDP 22000, 21027)' -Group $g -Direction Inbound -Action Allow -Profile Private -Program $exe -Protocol UDP -LocalPort 22000, 21027 | Out-Null
     New-NetFirewallRule -Name 'Syncthing-GUI-In-TCP' -DisplayName 'Syncthing GUI (TCP 8384)' -Group $g -Direction Inbound -Action Allow -Profile Private -Program $exe -Protocol TCP -LocalPort 8384 | Out-Null
     Get-NetConnectionProfile -InterfaceAlias $LAN_IF | Format-Table InterfaceAlias, NetworkCategory
     Get-NetFirewallRule -Group $g | Format-Table Name, Enabled, Profile, Direction, Action
   }
   ```

   - `<LAN_IF>  Private` と、3 つの規則が `True  Private  Inbound  Allow` で出ればよい
   - `中断:` が出たら、[Windows 11 の初期設定の手順 43](windows-setup.md#実施手順) でプライベートにしてから、この手順を貼り直す（規則はまだ作っていない）
   - 何度貼ってもよい（規則は消してから作り直す）
   - **注意**: プライベートの LAN では、プライベート向けのほかの許可の規則（ネットワーク探索など）も効く（[Windows の OpenSSH サーバー](windows-openssh-server.md)の手順 5 の補足）

1. サインインしたときに Syncthing を起動するタスクを登録する。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   $me = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
   $action = New-ScheduledTaskAction -Execute $exe -Argument '--no-console --no-browser' -WorkingDirectory (Split-Path $exe)
   $trigger = New-ScheduledTaskTrigger -AtLogOn -User $me
   $principal = New-ScheduledTaskPrincipal -UserId $me -LogonType Interactive
   $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
   Register-ScheduledTask -TaskName 'Syncthing' -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Format-List TaskName, State
   ```

   - `TaskName : Syncthing` と `State : Ready` が出ればよい
   - 同じ名前のタスクがあれば、上書きする（`-Force`）

1. タスクを開始し、Syncthing が起動したことを確かめる。

   ```powershell
   if (Get-Process -Name syncthing -ErrorAction SilentlyContinue) {
     Write-Error 'Syncthing はもう動いている'
   } else {
     Start-ScheduledTask -TaskName 'Syncthing'
     for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     (Get-ScheduledTask -TaskName 'Syncthing').State
     Get-CimInstance Win32_Process -Filter "Name='syncthing.exe'" | Format-Table ProcessId, ParentProcessId -AutoSize
     Get-NetTCPConnection -State Listen -LocalPort 8384, 22000 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess
   }
   ```

   - `Running` と、`syncthing.exe` が 2 つ（片方の `ParentProcessId` がもう片方の `ProcessId`）出ればよい
   - 新規導入では 8384 は `127.0.0.1`（この節の手順 10 で広げる）。設定を残した再導入では元の待ち受けでよい。22000 の行も出る
   - 最初の起動は DB と HTTPS の証明書を作るので、数秒かかる（ブロックは 30 秒まで待つ）
   - **注意**: 「Windows セキュリティの重要な警告」の窓が出たら、**キャンセルを押さない**（拒否の規則ができる）。「プライベート ネットワーク」だけにチェックして「アクセスを許可する」を押す

1. GUI の待ち受けを LAN に広げて HTTPS にする。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   & $exe cli config gui raw-address set 0.0.0.0:8384
   & $exe cli config gui raw-use-tls set true
   & $exe cli config gui raw-address get
   & $exe cli config gui raw-use-tls get
   for ($i = 0; $i -lt 30 -and (Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue).LocalAddress -contains '127.0.0.1'; $i++) { Start-Sleep -Seconds 1 }
   Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess
   ```

   - `0.0.0.0:8384` と `true` が出て、8384 の `LocalAddress` が `127.0.0.1` でなくなればよい（`::` か `0.0.0.0`）
   - この節の手順 6 で認証を入れてあるので、ここで待ち受けを広げる
   - `127.0.0.1` のままなら、[Windows 11 で止める・もう一度始める](#windows-11-で止めるもう一度始める)の手順 1・2 で起動し直す

1. 待ち受け・規則・デバイス ID を確かめ、GUI の URL を出す。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   $proc = @{ Label = 'Process'; Expression = { (Get-Process -Id $_.OwningProcess).ProcessName } }
   if (-not $LAN_IF) {
     Write-Error '手順 2 の $LAN_IF が空'
   } else {
     Get-NetTCPConnection -State Listen -LocalPort 8384, 22000 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, $proc
     Get-NetUDPEndpoint -LocalPort 22000, 21027 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, $proc
     Get-NetFirewallApplicationFilter | Where-Object Program -like '*\Programs\Syncthing\syncthing.exe' | Get-NetFirewallRule | Format-Table DisplayName, Enabled, Profile, Action
     Get-NetConnectionProfile -InterfaceAlias $LAN_IF | Format-Table InterfaceAlias, NetworkCategory
     & $exe device-id
     Get-Content -LiteralPath "$env:LOCALAPPDATA\Syncthing\syncthing.log" -Tail 5 -Encoding UTF8 -ErrorAction SilentlyContinue
     'GUI: https://{0}:8384/  （ログイン名 {1}）' -f (Get-NetIPAddress -InterfaceAlias $LAN_IF -AddressFamily IPv4).IPAddress, $ST_GUI_USER
   }
   ```

   - 8384/tcp・22000/tcp・22000/udp・21027/udp が、どれも `syncthing` で出ればよい
   - 規則はこの節の手順 7 の 3 つだけが `Allow` で出る（規則の一覧は数秒かかる）
   - **`Block` の行があれば**、警告の窓でキャンセルを押した跡。[Windows 11 のロールバック](#windows-11-のロールバック)の手順 2 で規則をすべて消し、この節の手順 7 を貼り直す
   - 最後の行の URL を、この節の手順 12 で使う

1. LAN の別の端末のブラウザで GUI に入り、デバイス ID を確かめる。

   - この節の手順 11 の URL を開き、自己署名の証明書の警告を受け入れ、手順 2 のログイン名と手順 5 のパスワードで入る
   - 最初に、利用状況の報告（Usage Reporting）を許可するかを聞かれる。どちらでもよい
   - Actions → Show ID のデバイス ID が、この節の手順 11 の `device-id` と同じであることを確かめる
   - 新規導入では同期するフォルダは 1 つも無い（Syncthing 2.x は既定のフォルダを作らない）。設定を残した再導入では、前のフォルダが並んでよい

1. この PC でサインアウトし、サインインし直す。

   - スタートメニューのユーザーのアイコン → 「サインアウト」
   - サインアウトすると、Syncthing も止まる
   - **次の手順は、サインインし直して管理者の Windows PowerShell を開いてから貼る**

1. サインインで Syncthing が起動したことを確かめる。

   ```powershell
   for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
   (Get-ScheduledTask -TaskName 'Syncthing').State
   Get-CimInstance Win32_Process -Filter "Name='syncthing.exe'" | Format-Table ProcessId, ParentProcessId -AutoSize
   Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess
   ```

   - `Running` と、`syncthing.exe` が 2 つ、8384 が `127.0.0.1` 以外で出ればよい
   - この節の手順 2 の変数は要らない

---

## Windows 11 で止める・もう一度始める

- タスク スケジューラでタスクを終了しても（`Stop-ScheduledTask` も）、親のプロセス（モニター）しか止まらず、本体は動き続ける（公式の説明）。止めるのはこの節の手順 1
- 自動の更新の後の Syncthing は、タスクの外で動く（[Windows 11 の更新](#windows-11-の更新)）。動いているかは、タスクの状態ではなくプロセスで見る

1. Syncthing を止める。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   if (-not (Get-Process -Name syncthing -ErrorAction SilentlyContinue)) {
     'Syncthing は動いていない'
   } else {
     & $exe cli operations shutdown
     for ($i = 0; $i -lt 30 -and (Get-Process -Name syncthing -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     Get-Process -Name syncthing -ErrorAction SilentlyContinue | Format-Table Id
     (Get-ScheduledTask -TaskName 'Syncthing').State
   }
   ```

   - プロセスの一覧は何も出ず、タスクは `Ready` になればよい
   - 次のサインインで、また起動する

1. もう一度始めるときは、タスクを開始する。

   ```powershell
   if (Get-Process -Name syncthing -ErrorAction SilentlyContinue) {
     Write-Error 'Syncthing はもう動いている'
   } else {
     Start-ScheduledTask -TaskName 'Syncthing'
     for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     (Get-ScheduledTask -TaskName 'Syncthing').State
     Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess
   }
   ```

   - `Running` と、8384 の待ち受けが出ればよい

---

## Windows 11 の更新

- Syncthing は稼働中、既定で 12 時間ごとに新しい版を確かめ、あれば自分で入れ替えて起動し直す（入れ替える前に、リリースの署名を確かめる）。サインアウト中・スリープ中・通信できない間は更新されない
- 入れ替えは同じ場所（`%LOCALAPPDATA%\Programs\Syncthing\syncthing.exe`）で行うので、タスクと受信の規則はそのまま使える。古い実行ファイルは、同じフォルダーに `syncthing.exe.old` として残る
- **自動で入れ替えた後の Syncthing は、タスクの外で動く**（タスクは `Ready` になる）。次のサインインからは、またタスクで起動する
- 待たずに上げるときは、この節の手順を貼る

1. 今の版と、新しい版があるかを確かめる。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   & $exe --version
   & $exe upgrade --check-only
   ```

   - 新しい版があれば、`Upgrade available` の行に今の版（`current`）と新しい版（`latest`）が出る
   - 新しい版が無ければ、`no upgrade available (current "v2.1.5" >= latest "v2.1.5")` のエラーが出る。そのときは、この節の手順 2 は飛ばす

1. 新しい版があるときだけ、今すぐ上げる。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   $before = & $exe --version
   & $exe cli operations upgrade
   for ($i = 0; $i -lt 60 -and (& $exe --version) -eq $before; $i++) { Start-Sleep -Seconds 1 }
   & $exe --version
   Start-Sleep -Seconds 5
   Get-CimInstance Win32_Process -Filter "Name='syncthing.exe'" | Format-Table ProcessId, ParentProcessId -AutoSize
   ```

   - `--version` が新しい版になり、`syncthing.exe` が 2 つ出ればよい

---

## Windows 11 のロールバック

- 上から順に、管理者の Windows PowerShell（5.1）に貼る（変数は使わない）。この節の手順 4 は Windows 11 の初期設定のロールバックで行う
- 同期していたファイル自体は、この節のどの手順でも消えない（同期したフォルダーの `.stfolder` も残る）

> [!CAUTION]
> **この節の手順 5 で、鍵・設定・DB（`%LOCALAPPDATA%\Syncthing`）を消すと、デバイス ID が失われる**。入れ直すと、相手からは別のデバイスとして見える。入れ直すかもしれないなら、手順 5 は行わない（手順 1〜4 だけなら、入れ直したときに同じデバイス ID に戻る）。

1. Syncthing を止め、タスクを消す。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   if (Get-Process -Name syncthing -ErrorAction SilentlyContinue) {
     & $exe cli operations shutdown
     for ($i = 0; $i -lt 30 -and (Get-Process -Name syncthing -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
   }
   Unregister-ScheduledTask -TaskName 'Syncthing' -Confirm:$false -ErrorAction SilentlyContinue
   Get-Process -Name syncthing -ErrorAction SilentlyContinue | Format-Table Id
   Get-ScheduledTask -TaskName 'Syncthing' -ErrorAction SilentlyContinue
   ```

   - 最後の 2 つが何も出さなければよい

1. 受信の規則を消す（警告の窓が作った規則も）。

   ```powershell
   Remove-NetFirewallRule -Group 'Syncthing (setup-notes)' -ErrorAction SilentlyContinue
   Get-NetFirewallApplicationFilter | Where-Object Program -like '*\Programs\Syncthing\syncthing.exe' | Get-NetFirewallRule | Remove-NetFirewallRule
   Get-NetFirewallApplicationFilter | Where-Object Program -like '*\Programs\Syncthing\syncthing.exe'
   ```

   - 最後のコマンドが何も出さなければよい（数秒かかる）

1. 実行ファイルを消す。

   ```powershell
   Remove-Item -LiteralPath "$env:LOCALAPPDATA\Programs\Syncthing" -Recurse -Force
   Test-Path "$env:LOCALAPPDATA\Programs\Syncthing"
   ```

   - `False` が出ればよい（`syncthing.exe.old` も消える）

1. LAN の接続をパブリックに戻すときだけ、[Windows 11 の初期設定のロールバック](windows-setup.md#ロールバック)の手順 33 を行う。

   - [Windows の OpenSSH サーバー](windows-openssh-server.md)やリモート デスクトップをこの LAN で使っているなら、戻さない（パブリックにすると SSH も届かなくなる）

1. 完全に消すときだけ、鍵・設定・DB・ログを消す（取り戻せない）。

   ```powershell
   Remove-Item -LiteralPath "$env:LOCALAPPDATA\Syncthing" -Recurse -Force
   Test-Path "$env:LOCALAPPDATA\Syncthing"
   ```

   - `False` が出ればよい

---

## 注意点

- **自分では更新しない**: Homebrew の formula は `--no-upgrade` でビルドしている（バージョン文字列の `noupgrade`）
  - 公式 tarball 版のような自己アップグレードは働かないので、`brew upgrade` で追う
  - **`brew upgrade` だけでは動いているプロセスが古いまま**なので、`brew services restart` まで行う
- **linger を切ると止まる**: `loginctl disable-linger` すると、ログアウトした時点で同期が止まる。止まっていること自体は GUI を開くまで気付きにくい
- **公開範囲は public ゾーンの全 NIC**: この環境では `wg0` も public にあるので、**VPN 越しの拠点からも 22000 と 8384 に届く**
  - 同期には好都合だが、GUI まで届くことは意識しておく。絞るなら[接続元を絞る（任意）](#接続元を絞る任意)
- **GUI の認証は必須**: LAN に開く構成なので、認証を設定しないまま待ち受けを広げると誰でも全設定を触れる。本書は手順 3〜4（認証）→ 手順 6（公開）→ 手順 7（firewalld）の順にしてある
- **証明書は自己署名**: ブラウザの警告は消えない。警告を無視する運用に慣れると本物の異常を見逃すので、常用するなら例外として明示的に登録する
- **GUI に入れる人は、Syncthing を動かすユーザーのファイルを読み書きできる**: Syncthing はそのユーザーとして動き、GUI からフォルダを足せる。GUI のパスワードは、OS のパスワードと同じ重みで扱う
- **API キーはパスワードと同じ重み**: `config.xml`（Windows 11 では `%LOCALAPPDATA%\Syncthing\config.xml`）にあり、これ 1 つで GUI の全操作ができる。ログや issue に貼らない
- **設定と DB は `~/.local/state/syncthing`**: 1.27.0 以降の既定
  - 戻すのに要るのは `cert.pem` / `key.pem`（失うとデバイス ID が変わる）と `config.xml`。DB（`index-v2`）は作り直せる
  - 自動で取っておくなら[設定を自動でバックアップする（任意）](#設定を自動でバックアップする任意)、戻すなら[バックアップから戻す](#バックアップから戻す)
- **2.x は DB 形式が 1.x と違う**: 2.0 で LevelDB から SQLite に変わり、1.x から上げると初回起動時に移行が走る（大きな構成では時間がかかる）
  - 上げる前に設定ディレクトリごと退避し、移行後の DB をそのまま 1.x に戻さない
  - 他のホストの 1.x から移すなら、上げる前に設定ディレクトリごと退避しておく
- **QUIC の受信バッファについて警告が出る**: 起動時に `failed to sufficiently increase receive buffer size (was: 208 kiB, wanted: 7168 kiB, got: 416 kiB)` と出る
  - 動作はする。消すなら `net.core.rmem_max` を上げる（本書では触っていない）
- **ホームを丸ごと同期しない**: `~/.local/state/syncthing`（Windows 11 では `AppData\Local\Syncthing`）自身やキャッシュまで対象になる。このホストは [Samba](samba.md) でホームを公開しているので、同じ領域を二重に扱うことにもなる
- **Windows 11 の注意点**
  - **パブリックのネットワークでは、直接はつながりにくい**: 規則はプライベートだけで有効。持ち出した先の Wi-Fi や、パブリックになっている VPN（WireGuard のトンネルの接続など）では、相手とはリレー（Syncthing のリレーのサーバー）経由になることが多い。外向きの接続だけでも同期はできる
  - **サインアウトとスリープの間は止まる**: タスクはサインインしている間だけ動く。スリープの間も同期しない。止まっている間の変更は、次に動いたときに同期される
  - **短い間に何度も起動し直さない**: 子のプロセスが 60 秒の間に 4 回起動すると、親はあきらめて終わる（[Windows 11 で使う](#windows-11-で使う)の手順 9 の補足）
  - **タスクの状態では、動いているかは分からない**: タスクを終了しても本体は止まらず、自動の更新の後はタスクの外で動く。止めるのは [Windows 11 で止める・もう一度始める](#windows-11-で止めるもう一度始める)の手順 1、確かめるのはプロセス
  - **Windows で使えない名前のファイル**: 相手（AlmaLinux 10 など）にある、`:` や `?` などを含む名前や、大文字と小文字だけが違う名前のファイルは、Windows では同期できない。Syncthing の GUI で同期できなかったファイルを確認する
  - **24H2 より前の Windows**: `syncthing.exe` に入っている「コンソールの窓を作らない」設定が効かず、タスクから起動したときにコンソールの窓が一瞬出て、`--no-console` で隠れるはず
  - **設定とログの場所**: `%LOCALAPPDATA%\Syncthing`（設定・鍵・DB・`syncthing.log`）。戻すのに要るのは `cert.pem` / `key.pem`（失うとデバイス ID が変わる）と `config.xml`
