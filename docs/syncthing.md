# Syncthing のセットアップ（AlmaLinux 10・Windows 11）

- Syncthing を AlmaLinux 10・Windows 11 の PC に入れて常駐させ、PC どうしでフォルダーを同期する
- 検証記録・参考資料・ロールバックと注意点は、各項のリードから開く

> [!IMPORTANT]
> - **前提と実行場所は、各項のリードに従う**。AlmaLinux 10 の項は、同期するファイルの持ち主の自分のユーザーの bash で行い、`sudo -i`・`su -` のシェルでは行わない
> - AlmaLinux 10 の項は、[AlmaLinux 10 のセットアップ](almalinux-setup.md)と同じく、パスワードを聞かない `sudo` を前提に書いてある。各項のリードの前提に無くても、その項を行うユーザーで[ログインと sudo](almalinux-setup.md#ログインと-sudo)を先に通す
> - Windows 11 の項は、[Windows 11 のセットアップ](windows-setup.md)と同じく、**この PC のデスクトップで、Administrators のユーザーが行う**。PowerShell のブロックは **Windows PowerShell 5.1** に貼る。管理者・通常（管理者ではない）の窓は、各項のリードに従う
> - Windows 11 で[貼り付けの設定](windows-setup.md#貼り付けの設定)より前は **Ctrl+V で貼る**。設定後は GitHub のコピーボタンでコピーし、右クリックで貼れる

- どの項も単独で通せる。目的の項のリードの前提を先に満たす
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 新しい端末では、使う項の変数の手順を貼り直す
- Windows 11 で GitHub のコピーボタンでコピーしたブロックは末尾に改行が無いので、貼った後に Enter を押す
- 入れたものを上げるときは、[Syncthing: 更新](#syncthing-更新)・[Syncthing: Windows 11 の更新](#syncthing-windows-11-の更新)を通す

## AlmaLinux 10 で使う

- Syncthing

### Syncthing

- Homebrew で Syncthing を入れ、ユーザーサービスとして常駐させ、Web GUI を HTTPS とパスワードで開けるようにする
- 前提: [Homebrew](almalinux-setup.md#homebrew)の手順 1〜3 と、[ユーザーサービスの常駐](almalinux-setup.md#ユーザーサービスの常駐)（linger。ログアウト中も Syncthing を動かすため）を通してある
  - `command -v brew` で何も出なければ、先に[Homebrew](almalinux-setup.md#homebrew)を通す
  - `loginctl show-user "$(id -u)" -p Linger` が `Linger=yes` を返さなければ、先に[ユーザーサービスの常駐](almalinux-setup.md#ユーザーサービスの常駐)を通す
- 実行場所: 同期するファイルの持ち主の、自分のユーザーの bash（デスクトップの端末か SSH）
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/syncthing.md)・[参考資料](reference/syncthing.md)・[ロールバックと注意点](extra/syncthing.md)
- AlmaLinux 10 の手順。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で-syncthing-を使う)から通す（管理者の Windows PowerShell 5.1 に貼る）
- **手順 2・3 には対話入力がある**（手順 2 は Homebrew が依存の確認を出した場合、手順 3 はパスワード）。完了してから次の手順を貼る
- この項の手順 1 で変数を設定したシェルに貼る
- OS を入れ直したホストを同じデバイス ID で戻すなら、先に[バックアップから戻す](#syncthing-バックアップから戻す)の手順 1・2・4・5 を行ってから、手順 1 から通す

> [!IMPORTANT]
> - **自分のシェルで実行する**（`sudo -i` した root のシェルでは行わない）。Homebrew の導入・管理は一般ユーザーで行い、Syncthing も同期するファイルの持ち主として動かす

1. 変数を設定する。

   ```bash
   ST_GUI_USER=$(id -un)               # GUI のログイン名。OS のアカウントとは別物（自動で同じ名前が入る）。<USER>
   ST_GUI_ADDR=0.0.0.0:8384            # GUI の待ち受け。LAN にも公開する。手元だけなら 127.0.0.1:8384
   ST_LAN_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | sed -n 's/.* src \([0-9.]*\).*/\1/p')   # 案内と検証に使う（自動）。<SERVER_IP>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in USER ST_GUI_USER ST_GUI_ADDR ST_LAN_IP; do
     printf '%-12s = %s\n' "$v" "${!v}"
   done
   ```

   - **編集が必須の変数は無い**。Web GUI を LAN にも公開する前提で既定値が入っている
   - 手元のブラウザからしか開かないなら、`ST_GUI_ADDR` を `127.0.0.1:8384` にする
   - 最後に値を読み戻して確かめる
   - `USER` が `root` なら、ここで止めて自分のシェルに戻る。`ST_GUI_ADDR=0.0.0.0:8384` の場合は、`ST_LAN_IP` が空か意図した NIC の IP と違えば直す
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、手順 1 を貼り直す。手順 5〜7 へ進む場合は、手順 3・4 もやり直す

1. brew で Syncthing を入れる。

   ```bash
   brew install syncthing
   ```

   - `Warning: Landlock ABI 10 or later is required to deny all network access; found ABI 6.` の行は、気にしなくてよい
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
   printf '\n\033[7m 確認 \033[0m\n'
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

   - `中断:` が出たら手順 5〜7 へ進まない。認証設定に成功した同じシェルだけで、手順 5〜7 を実行できる
   - `Generating key and certificate` の行に続いて、`Calculated device ID (device=...)` と `Updated GUI authentication user` / `Updated GUI authentication password` の 3 行が出る
   - 復元済みのホストの `Key exists; will not overwrite` は正常。鍵とデバイス ID は変わらない
   - ログイン名が同じなら `Updated GUI authentication user` は出ない
   - 最後の `syncthing device-id` が出す 7 桁 x 8 の文字列が、**このホストのデバイス ID**。相手デバイスに教える値で、秘密ではない

1. Syncthing のサービスを開始する。

   ```bash
   if [ "${ST_GUI_AUTH_READY:-false}" != true ]; then
     echo '中断: このシェルで手順 3・4 の認証設定を完了してから貼る' >&2
   else
     printf '\n\033[7m 確認 \033[0m\n'
     brew services start syncthing &&
       brew services list &&
       systemctl --user is-enabled sh.brew.syncthing.service &&
       systemctl --user is-active sh.brew.syncthing.service
   fi
   ```

   - ``Successfully started `syncthing` (label: sh.brew.syncthing)`` が出る

1. GUI の待ち受けと HTTPS を設定し、再起動して確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
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

   - 読み戻したアドレスが `ST_GUI_ADDR`、TLS が `true`、8384/tcp がそのアドレスで `LISTEN` ならよい（`0.0.0.0` は `*` と出る場合もある）
   - 設定が保存されても CLI が `EOF` で終わることがある。`中断:` が出たら手順 7 へ進まない

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
     printf '\n\033[7m 確認 \033[0m\n'
     sudo firewall-cmd --list-services
   fi
   ```

   - `127.0.0.1:8384` の場合は `syncthing` だけ、それ以外は両方が一覧に含まれればよい

1. サービスと待ち受けを確かめ、GUI の URL を出す。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
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
   - 初めて入ると、「匿名で使用状況をレポートすることを許可しますか？」と聞かれる。「はい」「いいえ」のどちらでもよい
   - `ST_GUI_ADDR=127.0.0.1:8384` の場合は、このホストのブラウザで開く。LAN に公開した場合は、LAN の別の端末から開いて firewalld 越しの到達も確かめる
   - 「メニュー」→「IDを表示」（英語の表示では Actions → Show ID）で出るデバイス ID が、`syncthing device-id` と同じであることを確認する
   - **この時点では同期するフォルダは 1 つも無い**
   - バックアップから戻したホストでは、戻したフォルダが並ぶ

#### Syncthing: 同期フォルダとデバイスを追加する

- Syncthing の GUI で相手のデバイスを登録し合い、同期するフォルダを共有する
- 前提: このホストで[Syncthing](#syncthing)（Windows 11 の PC は[Windows 11 で使う](#windows-11-で-syncthing-を使う)）を通してある。相手のデバイスには、この項の手順 1 で入れる
- 実行場所: このホストと相手のデバイスの、Syncthing の Web GUI（ブラウザ）
- **Syncthing 2.x は初回起動時に既定フォルダ（`~/Sync`）を作らない**。入れただけでは何も同期しないので、GUI から足す
- 操作は AlmaLinux 10 でも Windows 11 でも同じ。相手もどちらでもよい
- ボタン・欄・通知の名前は、GUI の表示が日本語のときのもの

> [!WARNING]
> **この項の手順 4・5 で、ホームディレクトリ（Windows 11 では `C:\Users\<WIN_USER>`）を丸ごと同期対象にしない。** `~/.local/state/syncthing`（Windows 11 では `AppData\Local\Syncthing`）自身や `~/.cache`、ほかのアプリのデータまで同期してしまう。
>
> - 同期したいものを入れる専用のディレクトリを作る（例: `~/Sync`、`C:\Users\<WIN_USER>\Sync`）
> - [Samba サーバー](samba.md#samba-サーバー)でホームを公開しているホストでは、同じ領域を二重に扱うことになる点にも注意する
> - Windows 11 では、OneDrive に移したデスクトップ・ドキュメントや、Dropbox のフォルダーも入れない（2 つの同期が同じファイルを書き合う）

1. 相手側のデバイスでも同じように Syncthing を入れ、そのデバイス ID を控える。

   - 相手が AlmaLinux 10 なら[Syncthing](#syncthing)、Windows 11 の PC なら [Windows 11 で使う](#windows-11-で-syncthing-を使う)で入れる

1. GUI の「接続先デバイスを追加」を押し、「デバイスID」の欄に相手のデバイス ID を貼って保存する。

   - 同じ LAN にいるなら、21027/udp のローカル探索で相手が自動的に見つかる（欄の下の「近くに検出された以下のデバイス」に ID が並ぶ）
   - その一覧には、同じ LAN のほかの Syncthing の ID も並ぶ。欄に入れた ID が、相手の `syncthing device-id` と同じであることを確かめてから保存する
   - VPN 越しの拠点同士は探索が届かないことがある。その場合は、デバイスのアドレスに `tcp://10.99.0.1:22000`（`tcp://<相手の IP>:22000`）のように直接書く

1. 相手側の GUI に出る承認の通知で、このデバイスを承認する。

   - 通知は「新規デバイス」（「デバイス「<このホストの名前>」 (…) が接続を求めています。新しいデバイスとして追加しますか？」）。「デバイスを追加」を押し、開いた画面で「保存」を押す

1. 「フォルダーを追加」でパス（例: `~/Sync`、Windows 11 では `C:\Users\<WIN_USER>\Sync`）とフォルダー ID を決め、「共有」タブで相手デバイスにチェックを入れて保存する。

1. 相手側の GUI に出る「新規フォルダー」の通知で「追加」を押し、フォルダーパスを入れて保存する。

   - 通知の文は「<このホストの名前> がフォルダー「<フォルダー名>」 (<フォルダー ID>) を共有するよう求めています。新しいフォルダーとして追加しますか？」
   - 「追加」で開く画面は、フォルダー名とフォルダー ID が入っていて、「フォルダーパス」が空。相手側で同期するディレクトリ（例: `~/Sync`）を入れるまで、「保存」を押せない
   - 保存した後、両方の GUI でフォルダーが「最新」になればよい

#### Syncthing: 接続元を絞る

- Syncthing の Web GUI（8384/tcp）に届く送信元を、指定したサブネットだけに絞る
- 前提: [Syncthing](#syncthing)を、GUI を LAN にも公開する設定（`ST_GUI_ADDR` が `127.0.0.1:8384` 以外）で通してある
- 実行場所: Syncthing を動かすホストの、自分のユーザーの bash（デスクトップの端末か SSH）
- **接続元を制限しないなら、この項は不要**
- [Syncthing](#syncthing)の手順 7 は、public ゾーンに属するすべての NIC（この環境では `end0` と `wg0`）で 8384/tcp を開く
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
   printf '\n\033[7m 確認 \033[0m\n'
   sudo firewall-cmd --list-rich-rules        # source address に実際のサブネットが入っていることを確認する
   fi
   ```

   - `ST_ALLOW_FROM` には、送信元を空白区切りで入れる
   - rich rule は**二重引用符**で囲む。単一引用符だと `${src}` が展開されないまま `success` で受理される（[Samba サーバー](samba.md#samba-サーバー) と同じ落とし穴）

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

#### Syncthing: 設定を自動でバックアップする

- Syncthing の鍵（`cert.pem`・`key.pem`）、`config.xml`、GUI の証明書（`https-cert.pem`・`https-key.pem`）を、自動で控える。DB（`index-v2`）は除く
- 前提: [Syncthing](#syncthing)を通してある。この項の手順 5 の前に、複製先の端末を[同期フォルダとデバイスを追加する](#syncthing-同期フォルダとデバイスを追加する)の手順 2・3 で追加しておく
- 実行場所: Syncthing を動かすホストの、自分のユーザーの bash（デスクトップの端末か SSH）。この項の手順 5 は GUI、手順 6 は相手の端末の GUI
- 保存先は `~/syncthing-backup/syncthing-config-<日時>.tar.gz`
- `config.xml` が書き換わると数秒後に取る（systemd の path ユニット）。取りこぼしの保険として 1 日 1 回も取る（タイマー）
- 最新のアーカイブと中身が同じなら作らない。新しい順に 100 個残す
- この項の手順 4〜6 で `~/syncthing-backup` を送信専用フォルダにして、別の端末へ複製する
- **アーカイブには秘密鍵・GUI パスワードのハッシュ・API キーが入る**。複製先の端末も同じ重さで扱い、リポジトリやほかの共有には置かない
- 戻し方は[バックアップから戻す](#syncthing-バックアップから戻す)

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

1. systemd のユーザーユニットを 3 つ置き、読み込ませる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
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

   - 何も表示されなければよい
   - **注意**: ユニットの検査に `systemd-analyze --user verify` を使わない（`systemctl --user` が使えなくなる。この手順の補足）

1. path とタイマーを有効にし、1 回目を取って確かめる。

   ```bash
   systemctl --user enable --now syncthing-backup.path syncthing-backup.timer
   systemctl --user start syncthing-backup.service
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user show -p Result,ExecMainStatus syncthing-backup.service
   systemctl --user is-active syncthing-backup.path syncthing-backup.timer
   systemctl --user list-timers syncthing-backup.timer
   ls -l ~/syncthing-backup
   ```

   - `start` は 5 秒ほど戻らない
   - `Result=success` と `ExecMainStatus=0`、続けて `active` が 2 行出る
   - `list-timers` の `NEXT` に、次の 0 時台の時刻が出る
   - `~/syncthing-backup` に `-rw-------` のアーカイブが 1 つできる
   - バックアップから戻したホストなら、この項の手順 4〜6 は飛ばす

1. `~/syncthing-backup` を送信専用フォルダとして登録し、相手と共有する（戻したホストでは要らない）。

   ```bash
   syncthing cli config folders add --id "syncthing-backup-$(uname -n)" --label "syncthing-backup ($(uname -n))" \
     --path "${HOME}/syncthing-backup" --type sendonly
   printf '\n\033[7m 確認 \033[0m\n'
   syncthing cli config folders list
   sleep 10
   ls -la ~/syncthing-backup
   ```

   - `folders list` に `syncthing-backup-<HOSTNAME>` が出る
   - `~/syncthing-backup` に `.stfolder` ができる
   - アーカイブが 1 つ増える

1. GUI で、このフォルダを相手の端末と共有する。

   - このフォルダの「編集」→「共有」タブを開き、相手の端末にチェックを入れて保存する
   - 相手の端末は、先に[同期フォルダとデバイスを追加する](#syncthing-同期フォルダとデバイスを追加する)の手順 2・3 で追加しておく

1. 相手の端末で、共有を受け入れる。

   - フォルダーの種類を**受信専用**（Receive Only）にする
   - ファイルのバージョン管理（File Versioning）を**ゴミ箱**（Trash Can）にする
   - このフォルダを、相手自身の Syncthing の設定ディレクトリにしない

1. 元に戻すときは、ユニットとスクリプトを外し、送信専用フォルダの登録を消す。

   ```bash
   systemctl --user disable --now syncthing-backup.path syncthing-backup.timer
   rm -f ~/.config/systemd/user/syncthing-backup.{service,path,timer} ~/.local/bin/syncthing-backup
   systemctl --user daemon-reload
   printf '\n\033[7m 確認 \033[0m\n'
   for id in $(syncthing cli config folders list); do
     if [ "$(syncthing cli config folders "${id}" path get)" = "${HOME}/syncthing-backup" ]; then
       syncthing cli config folders "${id}" delete && echo "登録を消した: ${id}"
     fi
   done
   syncthing cli config folders list
   ```

   - `登録を消した: syncthing-backup-<HOSTNAME>` が出て、`folders list` から消える
   - 相手の端末のコピーも残る。要らなければ、相手の GUI でフォルダを削除する

#### Syncthing: バックアップから戻す

- [設定を自動でバックアップする](#syncthing-設定を自動でバックアップする)で取ったアーカイブから、Syncthing の鍵と設定を戻す
- 前提: [設定を自動でバックアップする](#syncthing-設定を自動でバックアップする)でアーカイブを取ってある。OS を入れ直したホストでは、そのアーカイブを相手の端末に複製してある
- 実行場所: 戻すホストの、自分のユーザーの bash（デスクトップの端末か SSH）
- **同じホストで設定を壊したとき**は、この項の手順 3〜6 を貼る
  - path ユニットは壊れた設定も取っている。壊す前の時刻のアーカイブを選ぶ
- **OS を入れ直したホストを、同じデバイス ID で戻すとき**は、この項の手順 1・2・4・5 を[Syncthing](#syncthing)より先に行い、そのあと[Syncthing](#syncthing)を手順 1 から通す
  - [Syncthing](#syncthing)の手順 4 の `syncthing generate` は戻した鍵をそのまま使う。デバイス ID・フォルダ・API キーは戻したものになり、GUI のパスワードだけ入れ直す
  - 自動バックアップも、[設定を自動でバックアップする](#syncthing-設定を自動でバックアップする)の手順 1〜3 で入れ直す
- DB は入っていないので、OS を入れ直したホストは初回の起動で全フォルダを読み直し、中身を相手の端末から受け取る。フォルダのディレクトリと `.stfolder` は Syncthing が作る
- 外付けディスクにあるフォルダは、Syncthing を起動する前にマウントしておく

> [!WARNING]
> - **同じアーカイブから戻した Syncthing を、2 台で同時に動かさない。** 同じデバイス ID が 2 つになる。元のホストを入れ直すときにだけ使う
> - **この項の手順 2 でアーカイブを全部持ってこないと、送信専用フォルダが「同期されていない」ままになる。** その状態で赤い上書きのボタン（Override Changes）を押すと、持ってこなかったアーカイブが相手の端末から消える

1. OS を入れ直したときだけ、アーカイブの置き場所を作る。

   ```bash
   install -d -m 0700 ~/syncthing-backup
   ```

1. OS を入れ直したときだけ、相手の端末からアーカイブを全部持ってくる。

   - 相手の受信専用フォルダの `syncthing-config-*.tar.gz` を、すべて `~/syncthing-backup/` にコピーする
   - 例: `scp '<相手のホスト>:<相手のフォルダ>/syncthing-config-*.tar.gz' ~/syncthing-backup/`
   - OS を入れ直したホストでは、この項の手順 3 は飛ばす

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
   printf '\n\033[7m 確認 \033[0m\n'
   printf '%-10s = %s\n' ST_BACKUP "${ST_BACKUP}"
   ls -l ~/syncthing-backup
   tar -tzvf "${ST_BACKUP:?この項の手順 4 の ST_BACKUP が空のまま。アーカイブのパスを入れて貼り直す}"
   ```

   - 壊したあとで戻すなら、`ls -l` の一覧から壊す前の時刻のものを選び、`ST_BACKUP=~/syncthing-backup/syncthing-config-<日時>.tar.gz` のように入れ直す
   - `tar` の一覧に `cert.pem`・`key.pem`・`config.xml` が並ぶ（TLS を有効にしてあれば `https-cert.pem`・`https-key.pem` も）
   - **次の手順は、表示された内容でよいか確かめてから貼る**

1. 設定ディレクトリに展開する。

   ```bash
   if [ -z "${ST_BACKUP}" ] || [ ! -f "${ST_BACKUP}" ]; then
     echo '中断: この項の手順 4 で存在するアーカイブを選び直す' >&2
   else
     printf '\n\033[7m 確認 \033[0m\n'
     install -d -m 0700 ~/.local/state/syncthing &&
       tar -xzf "${ST_BACKUP}" -C ~/.local/state/syncthing &&
       ls -la ~/.local/state/syncthing
   fi
   ```

   - `cert.pem`・`key.pem`・`config.xml` が並ぶ。同じホストでは DB（`index-v2`）もそのまま残る
   - OS を入れ直したホストでは、この後[Syncthing](#syncthing)を手順 1 から通す（この項の手順 6 は飛ばす）

1. 同じホストで戻すときだけ、Syncthing を開始して確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   brew services start syncthing
   sleep 3
   syncthing device-id
   syncthing cli config gui raw-address get
   syncthing cli config gui raw-use-tls get
   syncthing cli config folders list
   ```

   - デバイス ID が戻す前と同じ
   - GUI の待ち受け・TLS・フォルダが、選んだアーカイブの時点のものになっている
   - `brew services start` は、この項の手順 3 の `stop` で外れた自動起動の登録も戻す（`Created symlink ... default.target.wants/sh.brew.syncthing.service` が出る）

#### Syncthing: 更新

- Homebrew で入れた Syncthing を上げ、サービスを再起動する
- 前提: [Syncthing](#syncthing)を通してある
- 実行場所: Syncthing を動かすホストの、自分のユーザーの bash（デスクトップの端末か SSH）
- AlmaLinux 10 の手順。Windows 11 は [Windows 11 の更新](#syncthing-windows-11-の更新)

1. Syncthing を更新する。

   ```bash
   brew upgrade syncthing
   ```

   - すべてまとめて上げるなら `brew upgrade`
   - **動いているプロセスは古いままになる。再起動まで必ず行う**
   - **次の手順は、Homebrew の確認が出たら答え、更新が成功してプロンプトに戻ってから貼る**（続けて貼ると確認の答えとして食われる）

1. サービスを再起動し、更新した版を確かめる。

   ```bash
   brew services restart syncthing
   printf '\n\033[7m 確認 \033[0m\n'
   syncthing --version
   ```

   - `syncthing --version` が更新した版になっていることを確かめる

---

## Windows 11 で使う

- Syncthing

### Windows 11 で Syncthing を使う

- この PC に Syncthing を入れ、サインイン中の自動起動と GUI を設定する
- 前提: [ネットワークとリモート](windows-setup.md#ネットワークとリモート)を通し、相手とつながる LAN の接続をプライベートにしてある
- 実行場所: この PC のデスクトップの管理者の Windows PowerShell（5.1）。この項の手順 1 で開く。手順 12 は LAN の別の端末のブラウザ、手順 13 はこの PC のデスクトップ
- フォルダー追加は[同期フォルダとデバイスを追加する](#syncthing-同期フォルダとデバイスを追加する)を通す
- この PC は、[AlmaLinux 10 の Syncthing](#syncthing)の相手にもなる
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/syncthing.md)・[参考資料](reference/syncthing.md)・[ロールバックと注意点](extra/syncthing.md)

> [!IMPORTANT]
> - **ホーム全体は同期しない**。同期するフォルダーだけを追加する
> - Syncthing は、管理者ではない自分のユーザーとして、サインインしている間だけ動く（この項の手順 8 のタスク）

1. Windows で、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く
   - PowerShell 7（`pwsh`）ではなく、Windows PowerShell 5.1 にする

1. 変数を設定する。

   ```powershell
   $ST_GUI_USER = $env:USERNAME          # GUI のログイン名。Windows のアカウントとは別物（自動で同じ名前が入る）。<WIN_USER>
   $LAN_IF = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).InterfaceAlias   # 相手とつながる LAN の接続（自動）。<LAN_IF>
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'ST_GUI_USER = {0}' -f $ST_GUI_USER
   'LAN_IF      = {0}' -f $LAN_IF
   ```

   - **編集が必須の変数は無い**
   - 最後に値を読み戻して確かめる
   - `LAN_IF` は、インターネットにつながっている接続の名前（`イーサネット`、`Wi-Fi` など）。相手とつながる接続と違えば、`$LAN_IF = 'Wi-Fi'` のように直す
   - **新しい PowerShell を開いたら**、この項の手順 2 のブロックを貼り直してから先へ進む

1. この PC に Syncthing が無いことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Process -Name syncthing -ErrorAction SilentlyContinue | Format-Table Id, Path
   Get-ScheduledTask -TaskName 'Syncthing' -ErrorAction SilentlyContinue | Format-Table TaskName, State
   Get-NetTCPConnection -State Listen -LocalPort 8384, 22000 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess
   Test-Path "$env:LOCALAPPDATA\Syncthing\config.xml", "$env:LOCALAPPDATA\Programs\Syncthing"
   ```

   - 最初の 3 つは何も出さず、最後に `False` が 2 行出ればよい
   - 何か出たら、ほかの方法で入れた Syncthing（SyncTrayzor、Syncthing Windows Setup など）がある。それを止めて外してから始める
   - [Windows 11 のロールバック](extra/syncthing.md#windows-11-のロールバック)の手順 1〜4 の後に入れ直すときは、1 行目の `True`（`config.xml`。前の鍵と設定）はそのままでよい

1. 公式の zip を取って sha256 と署名を確かめ、`syncthing.exe` を置く。

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
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

   - `syncthing-windows-amd64-v2.1.5.zip: sha256 一致、署名 Valid` と、`syncthing v2.1.5 "Hafnium Hornet" (go1.27.1 windows-amd64) …` の 1 行が出ればよい
   - `icacls` の一覧に、自分のユーザーの `(F)`（フル コントロール）の行がある
   - `中断:` で始まるエラーが出たら、何も置いていない
   - 何度貼ってもよい（Syncthing が動いているときは止まる）

1. GUI のパスワードを読み取る。

   ```powershell
   $ST_GUI_PASS = Read-Host -AsSecureString 'Syncthing GUI のパスワード'
   ```

   - **入力は `*` で表示される**
   - ASCII の英数字と記号だけにする
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. 最初に起動する前に、鍵と設定を作り、GUI のログイン名とパスワードを入れる。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not $ST_GUI_USER) {
     Write-Error 'この項の手順 2 の $ST_GUI_USER が空'
   } elseif (-not $ST_GUI_PASS -or $ST_GUI_PASS.Length -eq 0) {
     Write-Error '手順 5 のパスワードが空'
   } else {
     $p = ([Net.NetworkCredential]::new('', $ST_GUI_PASS)).Password
     if ($p -cnotmatch '^[\x20-\x7e]+$') {
       Write-Error 'パスワードに ASCII でない文字がある（この項の手順 5 からやり直す）'
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
   - エラーで止まったら、この項の手順 5 からやり直す

1. LAN の接続がプライベートなことを確かめ、Syncthing の受信の規則を作る。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   $g = 'Syncthing (setup-notes)'
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not $LAN_IF) {
     Write-Error 'この項の手順 2 の $LAN_IF が空'
   } elseif ((Get-NetConnectionProfile -InterfaceAlias $LAN_IF).NetworkCategory -ne 'Private') {
     Write-Error '中断: LAN の接続がプライベートではない（Windows 11 の初期設定の「ネットワークとリモート」の手順 3 でプライベートにする）'
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
   - `中断:` が出たら、[Windows 11 の初期設定の「ネットワークとリモート」の手順 3](windows-setup.md#ネットワークとリモート) でプライベートにしてから、この手順を貼り直す
   - 何度貼ってもよい
   - **注意**: プライベートの LAN では、プライベート向けのほかの許可の規則（ネットワーク探索など）も効く（[Windows 11 の初期設定の「OpenSSH サーバー」の手順 5](windows-setup.md#openssh-サーバー)の補足）

1. サインインしたときに Syncthing を起動するタスクを登録する。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   $me = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
   $action = New-ScheduledTaskAction -Execute $exe -Argument '--no-console --no-browser' -WorkingDirectory (Split-Path $exe)
   $trigger = New-ScheduledTaskTrigger -AtLogOn -User $me
   $principal = New-ScheduledTaskPrincipal -UserId $me -LogonType Interactive
   $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Register-ScheduledTask -TaskName 'Syncthing' -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Format-List TaskName, State
   ```

   - `TaskName : Syncthing` と `State : Ready` が出ればよい

1. タスクを開始し、Syncthing が起動したことを確かめる。

   ```powershell
   if (Get-Process -Name syncthing -ErrorAction SilentlyContinue) {
     Write-Error 'Syncthing はもう動いている'
   } else {
     Start-ScheduledTask -TaskName 'Syncthing'
     for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     (Get-ScheduledTask -TaskName 'Syncthing').State
     Get-CimInstance Win32_Process -Filter "Name='syncthing.exe'" | Format-Table ProcessId, ParentProcessId -AutoSize
     Get-NetTCPConnection -State Listen -LocalPort 8384, 22000 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess
   }
   ```

   - `Running` と、`syncthing.exe` が 2 つ（片方の `ParentProcessId` がもう片方の `ProcessId`）出ればよい
   - 新規導入では 8384 は `127.0.0.1`。設定を残した再導入では元の待ち受けでよい。22000 の行も出る
   - 最初の起動は、数秒かかる
   - **注意**: 「Windows セキュリティの重要な警告」の窓が出たら、**キャンセルを押さない**（拒否の規則ができる）。「プライベート ネットワーク」だけにチェックして「アクセスを許可する」を押す

1. GUI の待ち受けを LAN に広げて HTTPS にする。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   & $exe cli config gui raw-address set 0.0.0.0:8384
   & $exe cli config gui raw-use-tls set true
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & $exe cli config gui raw-address get
   & $exe cli config gui raw-use-tls get
   for ($i = 0; $i -lt 30 -and (Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue).LocalAddress -contains '127.0.0.1'; $i++) { Start-Sleep -Seconds 1 }
   Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess
   ```

   - `0.0.0.0:8384` と `true` が出て、8384 の `LocalAddress` が `127.0.0.1` でなくなればよい（`::` か `0.0.0.0`）
   - `127.0.0.1` のままなら、[Windows 11 で止める・もう一度始める](#syncthing-windows-11-で止めるもう一度始める)の手順 2・3 で起動し直す

1. 待ち受け・規則・デバイス ID を確かめ、GUI の URL を出す。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   $proc = @{ Label = 'Process'; Expression = { (Get-Process -Id $_.OwningProcess).ProcessName } }
   if (-not $LAN_IF) {
     Write-Error 'この項の手順 2 の $LAN_IF が空'
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
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
   - 規則はこの項の手順 7 の 3 つだけが `Allow` で出る（規則の一覧は数秒かかる）
   - **`Block` の行があれば**、警告の窓でキャンセルを押した跡。[Windows 11 のロールバック](extra/syncthing.md#windows-11-のロールバック)の手順 2 で規則をすべて消し、この項の手順 7 を貼り直す
   - 最後の行の URL を、この項の手順 12 で使う

1. LAN の別の端末のブラウザで GUI に入り、デバイス ID を確かめる。

   - この項の手順 11 の URL を開き、自己署名の証明書の警告を受け入れ、この項の手順 2 のログイン名とこの項の手順 5 のパスワードで入る
   - 最初に、利用状況の報告（Usage Reporting）を許可するかを聞かれる。どちらでもよい
   - Actions → Show ID のデバイス ID が、この項の手順 11 の `device-id` と同じであることを確かめる
   - 新規導入では同期するフォルダは 1 つも無い。設定を残した再導入では、前のフォルダが並んでよい

1. この PC でサインアウトし、サインインし直す。

   - スタートメニューのユーザーのアイコン → 「サインアウト」
   - **次の手順は、サインインし直して管理者の Windows PowerShell を開いてから貼る**

1. サインインで Syncthing が起動したことを確かめる。

   ```powershell
   for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-ScheduledTask -TaskName 'Syncthing').State
   Get-CimInstance Win32_Process -Filter "Name='syncthing.exe'" | Format-Table ProcessId, ParentProcessId -AutoSize
   Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess
   ```

   - `Running` と、`syncthing.exe` が 2 つ、8384 が `127.0.0.1` 以外で出ればよい
   - この項の手順 2 の変数は要らない

#### Syncthing: Windows 11 で止める・もう一度始める

- Syncthing を止め、必要なときにもう一度始める
- 前提: [Syncthing](#windows-11-で-syncthing-を使う)を通してある
- 実行場所: この PC のデスクトップの管理者の Windows PowerShell（5.1）。この項の手順 1 で開く
- 動いているかは、タスクの状態ではなくプロセスで見る。止めるのはこの項の手順 2

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開き、UAC の確認に答える

1. Syncthing を止める。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   if (-not (Get-Process -Name syncthing -ErrorAction SilentlyContinue)) {
     'Syncthing は動いていない'
   } else {
     & $exe cli operations shutdown
     for ($i = 0; $i -lt 30 -and (Get-Process -Name syncthing -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-Process -Name syncthing -ErrorAction SilentlyContinue | Format-Table Id
     (Get-ScheduledTask -TaskName 'Syncthing').State
   }
   ```

   - プロセスの一覧は何も出ず、タスクは `Ready` になればよい

1. もう一度始めるときは、タスクを開始する。

   ```powershell
   if (Get-Process -Name syncthing -ErrorAction SilentlyContinue) {
     Write-Error 'Syncthing はもう動いている'
   } else {
     Start-ScheduledTask -TaskName 'Syncthing'
     for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     (Get-ScheduledTask -TaskName 'Syncthing').State
     Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess
   }
   ```

   - `Running` と、8384 の待ち受けが出ればよい

#### Syncthing: Windows 11 の更新

- 自動更新を待たずに、Syncthing を上げる
- 前提: [Syncthing](#windows-11-で-syncthing-を使う)を通し、Syncthing が動いている
- 実行場所: この PC のデスクトップの管理者の Windows PowerShell（5.1）。この項の手順 1 で開く
- Syncthing は稼働中、既定で 12 時間ごとに新しい版を確かめ、あれば自分で入れ替えて起動し直す。サインアウト中・スリープ中・通信できない間は更新されない
- **自動で入れ替えた後の Syncthing は、タスクの外で動く**（タスクは `Ready` になる）。次のサインインからは、またタスクで起動する

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開き、UAC の確認に答える

1. 今の版と、新しい版があるかを確かめる。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & $exe --version
   & $exe upgrade --check-only
   ```

   - 新しい版があれば、`Upgrade available` の行に今の版（`current`）と新しい版（`latest`）が出る
   - 新しい版が無ければ、`no upgrade available (current "v2.1.5" >= latest "v2.1.5")` のエラーが出る。そのときは、この項の手順 3 は飛ばす

1. 新しい版があるときだけ、今すぐ上げる。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   $before = & $exe --version
   & $exe cli operations upgrade
   for ($i = 0; $i -lt 60 -and (& $exe --version) -eq $before; $i++) { Start-Sleep -Seconds 1 }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & $exe --version
   Start-Sleep -Seconds 5
   Get-CimInstance Win32_Process -Filter "Name='syncthing.exe'" | Format-Table ProcessId, ParentProcessId -AutoSize
   ```

   - `--version` が新しい版になり、`syncthing.exe` が 2 つ出ればよい

---
