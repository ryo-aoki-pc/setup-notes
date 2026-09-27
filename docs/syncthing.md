# Syncthing インストール手順（AlmaLinux 10 / Homebrew + systemd ユーザーサービス）

## 実施手順

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew は root で動かず、Syncthing も同期するファイルの持ち主として動かすため）
> - **手順 3 には対話入力がある**（パスワード）。入力し終えてから手順 4 を貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 同期するフォルダは[同期フォルダとデバイスを追加する（任意）](#同期フォルダとデバイスを追加する任意)、GUI の接続元を制限するなら[接続元を絞る（任意）](#接続元を絞る任意)、鍵と設定を自動で取っておくなら[設定を自動でバックアップする（任意）](#設定を自動でバックアップする任意)。以後は[更新](#更新)・[ロールバック](#ロールバック)
- OS を入れ直したホストを同じデバイス ID で戻すなら、先に[バックアップから戻す](#バックアップから戻す)の手順 1・3・4 を貼ってから、手順 1 から通す

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
   - `USER` が `root` になっている（root でサービスを動かしてしまう）、`ST_LAN_IP` が空、または意図した NIC の IP でないなら、ここで止めて直す
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**（SSH を張り直したあとも）、手順 1 のブロックを貼り直してから先へ進む

   <details>
   <summary>補足: 変数について</summary>

   - `ST_GUI_USER` は **Syncthing の Web GUI にログインするための名前**で、OS のアカウントとも Samba のユーザーとも無関係。自動で OS と同じ名前が入るだけなので、別の名前にしてもよい
   - `ST_LAN_IP` は設定には使わず、手順 9 の案内とブラウザの URL にしか使わない。間違っていても Syncthing の設定は壊れない（[samba.md](samba.md) の `SERVER_IP` と同じ扱い）
   - `ST_GUI_ADDR` を `0.0.0.0:8384` にすると**すべての NIC で待ち受ける**。この環境では `end0`（LAN）と `wg0`（VPN）の両方から開ける
   - 特定の 1 本に絞りたいなら `192.168.1.10:8384` のように IP を直接書く（その場合 firewalld は手順 8 のままでよい）
   - パスワードは変数に置かない。手順 3 でその場で読み取り、設定したら `unset` する

   </details>

1. brew で Syncthing を入れる。

   ```bash
   brew install syncthing
   brew list --versions syncthing
   syncthing --version
   ```

   - aarch64 でもビルド済みのボトルが降ってくるので、Go のビルドにはならない
   - 依存は無い（静的バイナリ 1 つ、約 30 MB）
   - バージョン文字列の末尾に `[modernc-sqlite, noupgrade]` と出る（意味はこの手順の補足）

   <details>
   <summary>補足: <code>noupgrade</code> と入るファイル</summary>

   aarch64 で降ってくるボトルは `syncthing--2.1.5.arm64_linux.bottle.tar.gz`。

   - `noupgrade` は、**Syncthing 自身の自動アップグレード機能を無効にしてビルドされている**という印
     - 公式の tarball 版は自分で新しい版を取ってきて入れ替えるが、Homebrew の formula は `go run build.go --version ... --no-upgrade tar` でビルドするので、その機能が入らない
     - 更新は `brew upgrade` で行う（[更新](#更新)）。パッケージマネージャ管理下のファイルを Syncthing が勝手に書き換えないので、こちらの方が都合がよい
   - `modernc-sqlite` は 2.x で採用された SQLite 実装（cgo 無しの純 Go 版）。1.x の LevelDB から変わった部分（[注意点](#注意点)）

   入るのは実行ファイル 1 つと man ページだけで、**systemd の unit ファイルは入らない**:

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

   - `sh.brew.syncthing.service` は formula の `service do` ブロックから Homebrew が生成したもので、公式が配っている `etc/linux-systemd/user/syncthing.service` ではない（手順 6 の補足）
   - man は `man syncthing` / `man syncthing-config` / `man syncthing-faq` などが読める

   </details>

1. GUI のパスワードを読み取る。

   ```bash
   read -rsp 'Syncthing GUI のパスワード: ' ST_GUI_PASS; echo
   ```

   - **入力は画面に出ない**
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. サービスを起動する前に、鍵・証明書・設定ファイルを作り、GUI のログイン名とパスワードを入れる。

   ```bash
   printf '%s' "${ST_GUI_PASS}" | syncthing generate \
     --gui-user="${ST_GUI_USER:?手順 1 の ST_GUI_USER が空のまま。値を入れて貼り直す}" --gui-password=-
   unset ST_GUI_PASS
   syncthing device-id
   ```

   - LAN に開いたあとで認証を設定するのでは、その間 GUI が誰でも開ける状態になるため、サービスの起動より先に入れる
   - `Calculated device ID (device=...)` と `Updated GUI authentication user` / `Updated GUI authentication password` の 3 行が出る
   - [バックアップから戻した](#バックアップから戻す)ホストでは、先頭が `Key exists; will not overwrite` になり、鍵を作り直さない（デバイス ID は元のまま。ログイン名が同じなら `Updated GUI authentication user` の行は出ない）
   - 最後の `syncthing device-id` が出す 7 桁 x 8 の文字列が、**このホストのデバイス ID**。相手デバイスに教える値で、秘密ではない

   <details>
   <summary>補足: 設定の置き場所とパスワードの渡し方</summary>

   **設定と DB は `~/.local/state/syncthing`**（`$XDG_STATE_HOME/syncthing`）。1.27.0 で `~/.config/syncthing` から移った。古い版から引き継ぐときは元の場所も見に行く。この手順で作られるのは次の 4 つ:

   ```
   $ ls -la ~/.local/state/syncthing/
   -rw-------. 1 <USER> <USER>  623 cert.pem        # デバイス ID のもとになる証明書
   -rw-------. 1 <USER> <USER>  119 key.pem         # その秘密鍵
   -rw-------. 1 <USER> <USER> 6613 config.xml      # 設定（GUI のユーザー名・パスワードハッシュ・API キーを含む）
   ```

   **`--gui-password=-` は標準入力からパスワードを読む。**

   - `--gui-password="..."` と直接書くと、その間だけとはいえ `ps` の出力とシェルの履歴に平文が残る。`printf` からのパイプにすればどちらにも残らない
   - `config.xml` に入るのは bcrypt ハッシュで、平文は保存されない
   - パスワードを後から変えるなら、GUI の Actions → Settings → GUI か、同じコマンドをもう一度（`syncthing generate` は既存の設定を壊さずに認証情報だけ更新する）

   `syncthing generate` は `.syncthing.tmp.<数字>` という一時ファイルを残すことがある（[付録](#付録-実機での検証記録2026-09-24)）。消しても動作に影響はない。

   </details>

1. 常時起動にするため、linger を有効にする。

   ```bash
   sudo loginctl enable-linger "${USER}"
   ```

   - linger を有効にすると、ログインしていない間もユーザーの systemd が動き続ける
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: linger が要る理由</summary>

   **linger が無いと、SSH を切った時点で Syncthing も止まる。**

   - ユーザーの systemd（`user@1000.service`）はログインセッションが無くなると終了し、その配下のサービスも一緒に落ちるため
   - `sudo loginctl enable-linger` は `/var/lib/systemd/linger/<USER>` を作り、起動時にユーザーの systemd を立ち上げてこのサービスを開始させる

   </details>

1. linger が有効になったか確かめ、Syncthing のサービスを開始する。

   ```bash
   loginctl show-user "$(id -u)" -p Linger                 # Linger=yes
   brew services start syncthing
   brew services list
   systemctl --user is-enabled sh.brew.syncthing.service   # enabled
   systemctl --user is-active  sh.brew.syncthing.service   # active
   ```

   - `Successfully started 'syncthing' (label: sh.brew.syncthing)` が出る
   - `~/.config/systemd/user/sh.brew.syncthing.service` が置かれる

   <details>
   <summary>補足: 生成される unit と、システムサービスにする道</summary>

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
   - Homebrew 版には unit が同梱されないので自分で書くことになる。ホームディレクトリを同期する用途では、ユーザーサービスの方が素直（ファイルの持ち主が変わらない）

   </details>

1. GUI の待ち受けを LAN に広げて HTTPS にし、再起動して反映する。

   ```bash
   syncthing cli config gui raw-address set "${ST_GUI_ADDR:?手順 1 の ST_GUI_ADDR が空のまま。値を入れて貼り直す}"
   syncthing cli config gui raw-use-tls set true
   syncthing cli config gui raw-address get      # 0.0.0.0:8384
   syncthing cli config gui raw-use-tls get      # true
   brew services restart syncthing
   sleep 3
   ss -ltnp | grep 8384                          # *:8384 で LISTEN
   ```

   - 手順 3〜4 で認証を入れてあるので、ここで待ち受けを広げる
   - 反映には再起動が要る

   <details>
   <summary>補足: 自己署名証明書と、別のやり方</summary>

   **証明書は Syncthing が自分で作る自己署名のもの**（`https-cert.pem` / `https-key.pem`）。

   - ブラウザは初回に警告を出すので、例外に追加して進む
   - 自前の証明書を使いたいなら、設定ディレクトリのこの 2 ファイルを置き換えて再起動する（GUI からは差し替えられない）
   - TLS を有効にすると、平文の `http://` で来た接続は **307 で `https://` に飛ばされる**（[付録](#付録-実機での検証記録2026-09-24)）。有効にしないと GUI のパスワードが LAN に平文で流れる

   `syncthing cli` は起動中の Syncthing に REST API で話しかけるので、**サービスが動いている状態で実行する**。

   - 設定ファイルから API キーを自分で読むため、キーを渡す必要はない
   - プロパティ名は `syncthing cli config gui --help` で一覧できる（`raw-address` / `raw-use-tls` は `config.xml` の `<address>` / `tls` 属性に対応する）

   待ち受けアドレスは環境変数 `STGUIADDRESS` でも上書きできる。`brew services` なら `~/.homebrew/services/syncthing.env` に `STGUIADDRESS=0.0.0.0:8384` と書く方式だが、設定が 2 か所に分かれるので本書では `config.xml` に寄せている。

   </details>

1. firewalld で `syncthing` と `syncthing-gui` を開ける。

   ```bash
   sudo firewall-cmd --permanent --add-service=syncthing --add-service=syncthing-gui && sudo firewall-cmd --reload
   sudo firewall-cmd --list-services            # syncthing と syncthing-gui が含まれる
   ```

   - `syncthing` は同期と探索（22000/tcp、22000/udp、21027/udp）
   - `syncthing-gui` は Web GUI（8384/tcp）
   - どちらも firewalld に最初から入っている定義済みサービスで、自分で書く必要はない

   <details>
   <summary>補足: 公開範囲と、自ホストからでは確認できないこと</summary>

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
   - **公開範囲は public ゾーンの全 NIC**。この環境では `wg0` も public にあるので、VPN 越しの拠点からも 22000 と 8384 に届く。絞るなら[接続元を絞る（任意）](#接続元を絞る任意)
   - **自ホストからの `curl https://<SERVER_IP>:8384/` は firewalld を通らない**（ローカル宛のパケットは `lo` 経由で先に受理される）。開け忘れはサーバー上の確認では見つからないので、別ホストか network namespace から試す（[付録](#付録-実機での検証記録2026-09-24)）

   </details>

1. サービスと待ち受けを確かめ、GUI の URL を出す。

   ```bash
   brew services list
   systemctl --user is-active sh.brew.syncthing.service
   ss -ltunp | grep -E ':(8384|22000|21027)'
   syncthing device-id
   tail -5 /home/linuxbrew/.linuxbrew/var/log/syncthing.log
   printf 'GUI: https://%s:8384/  （ログイン名 %s）\n' "${ST_LAN_IP}" "${ST_GUI_USER}"
   ```

   - 8384/tcp、22000/tcp、22000/udp、21027/udp が LISTEN していれば動いている
   - LAN 上のブラウザで確かめる
     - その URL を開き、自己署名証明書の警告を受け入れ、手順 3〜4 で決めたログイン名とパスワードで入る
     - Actions → Show ID で出るデバイス ID が、`syncthing device-id` と同じであることを確認する
   - **この時点では同期するフォルダは 1 つも無い**（Syncthing 2.x は既定フォルダを作らない）
   - バックアップから戻したホストでは、戻したフォルダが並ぶ。フォルダのディレクトリと `.stfolder` は Syncthing が作り、中身は相手の端末から届く

   <details>
   <summary>補足: 認証が効いているかの確かめ方</summary>

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

   </details>

---

## 同期フォルダとデバイスを追加する（任意）

- **Syncthing 2.x は初回起動時に既定フォルダ（`~/Sync`）を作らない**。入れただけでは何も同期しないので、GUI から足す

> [!WARNING]
> **この節の手順 3 で、ホームディレクトリを丸ごと同期対象にしない。** `~/.local/state/syncthing` 自身や `~/.cache` まで同期してしまう。
>
> - 同期したいものを入れる専用のディレクトリを作る
> - このホストは [Samba](samba.md) でホームを公開しているので、同じ領域を二重に扱うことになる点にも注意する

1. 相手側のデバイスでも同じように Syncthing を入れ、そのデバイス ID を控える。

1. GUI の「リモートデバイスを追加」に相手のデバイス ID を貼る。

   - 相手側にも承認の通知が出るので、双方で承認する
   - 同じ LAN にいるなら、21027/udp のローカル探索で相手が自動的に見つかる
   - VPN 越しの拠点同士は探索が届かないことがある。その場合は、デバイスのアドレスに `tcp://10.99.0.1:22000` のように直接書く

1. 「フォルダーを追加」でパス（例: `~/Sync`）とフォルダー ID を決め、「共有」タブで相手デバイスにチェックを入れる。

1. 相手側に「このデバイスがフォルダーを共有しようとしています」と出るので受け入れる。

---

## 接続元を絞る（任意）

- **接続元を制限しないなら、この節は不要**
- 手順 8 は、public ゾーンに属するすべての NIC（この環境では `end0` と `wg0`）で 8384/tcp を開く
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
- この節の手順 4 で `~/syncthing-backup` を送信専用フォルダにして、別の端末へ複製する
- **アーカイブには秘密鍵・GUI パスワードのハッシュ・API キーが入る**。複製先の端末も同じ重さで扱い、リポジトリやほかの共有には置かない
- 戻し方は[バックアップから戻す](#バックアップから戻す)
- この節は**実機で本実行していない**（AlmaLinux 10 のコンテナで検証した。[付録](#付録-コンテナでのバックアップと復旧の検証2026-09-27)）

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

   <details>
   <summary>補足: スクリプトの作り</summary>

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

   </details>

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

   <details>
   <summary>補足: ユニットの作りと、<code>systemd-analyze --user verify</code> の落とし穴</summary>

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

   </details>

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
   - バックアップから戻したホストなら、この節の手順 4 は飛ばす（送信専用フォルダは戻した `config.xml` に入っている）

   <details>
   <summary>補足: 出力の例と、失敗の見方</summary>

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
   - linger が有効なので（[手順 5](#実施手順)）、ログアウト中も path ユニットとタイマーは動く

   </details>

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
   - GUI でこのフォルダの「編集」→「共有」タブを開き、相手の端末にチェックを入れて保存する
   - 相手の端末は、先に[同期フォルダとデバイスを追加する（任意）](#同期フォルダとデバイスを追加する任意)の手順 2 で追加しておく
   - 相手の端末で共有を受け入れるときは、次のようにする
     - フォルダーの種類を**受信専用**（Receive Only）にする
     - ファイルのバージョン管理（File Versioning）を**ゴミ箱**（Trash Can）にする。こちらで 100 個を超えて消した古いアーカイブは、相手でも消えるため
     - このフォルダを、相手自身の Syncthing の設定ディレクトリにしない

   <details>
   <summary>補足: 送信専用にする理由と、コマンドで入る値</summary>

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

   </details>

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

- **同じホストで設定を壊したとき**は、この節の手順 2〜5 を貼る
  - path ユニットは壊れた設定も取っている。壊す前の時刻のアーカイブを選ぶ
- **OS を入れ直したホストを、同じデバイス ID で戻すとき**は、この節の手順 1・3・4 を[実施手順](#実施手順)より先に貼り、そのあと実施手順を手順 1 から通す
  - [手順 4](#実施手順) の `syncthing generate` は戻した鍵をそのまま使う。デバイス ID・フォルダ・API キーは戻したものになり、GUI のパスワードだけ入れ直す
  - 自動バックアップも、[設定を自動でバックアップする（任意）](#設定を自動でバックアップする任意)の手順 1〜3 で入れ直す
- DB は入っていないので、OS を入れ直したホストは初回の起動で全フォルダを読み直し、中身を相手の端末から受け取る。フォルダのディレクトリと `.stfolder` は Syncthing が作る
- 外付けディスクにあるフォルダは、Syncthing を起動する前にマウントしておく
  - DB が空のフォルダには Syncthing が `.stfolder` を作るので、外れたままだと空のマウントポイントへ受け取り始める（ソースとコンテナの挙動からの推定で、外付けディスクでは試していない）
- この節は**実機で本実行していない**（コンテナで検証した。[付録](#付録-コンテナでのバックアップと復旧の検証2026-09-27)）

> [!WARNING]
> - **同じアーカイブから戻した Syncthing を、2 台で同時に動かさない。** 同じデバイス ID が 2 つになる。元のホストを入れ直すときにだけ使う
> - **この節の手順 1 でアーカイブを全部持ってこないと、送信専用フォルダが「同期されていない」ままになる。** その状態で赤い上書きのボタン（Override Changes）を押すと、持ってこなかったアーカイブが相手の端末から消える

1. OS を入れ直したときだけ、置き場所を作り、相手の端末からアーカイブを全部持ってくる。

   ```bash
   install -d -m 0700 ~/syncthing-backup
   ```

   - 相手の端末の受信専用フォルダから、`syncthing-config-*.tar.gz` を全部 `~/syncthing-backup/` にコピーする（例: `scp '<相手のホスト>:<相手のフォルダ>/syncthing-config-*.tar.gz' ~/syncthing-backup/`）
   - OS を入れ直したホストでは、この節の手順 2 は飛ばす

   <details>
   <summary>補足: 全部持ってくる理由</summary>

   - 送信専用フォルダは、相手にあってこちらに無いファイルを取りに行かない
   - 1 つだけ持ってきて起動すると、残りは相手にしか無いまま「同期されていない」表示が続く。コンテナでは `needFiles` が 8 のままだった
   - その状態で上書きのボタンを押すと、こちらに無いファイルは消されたものとして相手に伝わる。コンテナでは相手の 9 個が 1 個になった（相手のゴミ箱を有効にしていたので、`.stversions` に残った）
   - 全部持ってくれば、DB が空の初回起動でも両方の一覧が一致し、同期済み（`needFiles` が 0）になる

   </details>

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
   tar -tzvf "${ST_BACKUP:?この節の手順 3 の ST_BACKUP が空のまま。アーカイブのパスを入れて貼り直す}"
   ```

   - `ST_BACKUP` には名前順で最後（＝最新）のアーカイブが入る
   - 壊したあとで戻すなら、`ls -l` の一覧から壊す前の時刻のものを選び、`ST_BACKUP=~/syncthing-backup/syncthing-config-<日時>.tar.gz` のように入れ直す
   - `tar` の一覧に `cert.pem`・`key.pem`・`config.xml` が並ぶ（TLS を有効にしてあれば `https-cert.pem`・`https-key.pem` も）
   - **次の手順は、表示された内容でよいか確かめてから貼る**

1. 設定ディレクトリに展開する。

   ```bash
   install -d -m 0700 ~/.local/state/syncthing
   tar -xzf "${ST_BACKUP:?この節の手順 3 の ST_BACKUP が空のまま。アーカイブのパスを入れて貼り直す}" -C ~/.local/state/syncthing
   ls -la ~/.local/state/syncthing
   ```

   - `cert.pem`・`key.pem`・`config.xml` が並ぶ。同じホストでは DB（`index-v2`）もそのまま残る
   - 同じホストで自動バックアップを有効にしてあれば、展開した `config.xml` を path ユニットが新しいアーカイブとして取る（戻した設定が最新になるだけで、害は無い）
   - OS を入れ直したホストでは、この後[手順 1](#実施手順)から通す（この節の手順 5 は飛ばす）

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
   - `brew services start` は、この節の手順 2 の `stop` で外れた自動起動の登録も戻す（`Created symlink ... default.target.wants/sh.brew.syncthing.service` が出る）

---

## 更新

1. Syncthing を更新し、サービスを再起動する。

   ```bash
   brew upgrade syncthing
   brew services restart syncthing
   syncthing --version
   ```

   - すべてまとめて上げるなら `brew upgrade`
   - **brew 版は自分では更新しない**（`noupgrade` ビルド）ので、放っておいても勝手に版が上がることはない
   - `brew upgrade` は実行ファイルを差し替えるだけなので、**動いているプロセスは古いままになる。再起動まで必ず行う**

---

## ロールバック

- 上から順に実行する
- 接続元を絞る節を使った場合は `syncthing-gui` ではなく rich rule が入っているので、先に[接続元を絞る（任意）](#接続元を絞る任意)の手順 2 を貼る
- 自動バックアップを設定した場合は、Syncthing が動いているうちに、先に[設定を自動でバックアップする（任意）](#設定を自動でバックアップする任意)の手順 5 を貼る
- 同期していたファイル自体は、この節のどの手順でも消えない
- 本書ではロールバックは**本実行していない**

> [!CAUTION]
> **この節の**手順 5 で設定・鍵・DB を**消すとデバイス ID が失われ、相手デバイスからは別のデバイスとして見える**。入れ直す可能性があるなら残すか、自動バックアップのアーカイブ（`~/syncthing-backup`）を取っておく（[バックアップから戻す](#バックアップから戻す)で同じデバイス ID に戻せる）。

1. サービスを止めて、Syncthing を消す。

   ```bash
   brew services stop syncthing
   brew uninstall syncthing
   ```

   - Syncthing を動かしていたユーザー自身のシェルで貼る（`sudo -i` した root のシェルでは、この節の手順 4 の `${USER}` が `root` になる）
   - `brew services stop` は停止に加えて**自動起動の登録も外す**（`brew services --help` の「unregister it from launching at login」）
   - 設定・鍵・DB（`~/.local/state/syncthing`）とログ（`/home/linuxbrew/.linuxbrew/var/log/syncthing.log`）は残る

1. ファイアウォールの設定を外す。

   ```bash
   sudo firewall-cmd --permanent --remove-service=syncthing --remove-service=syncthing-gui && sudo firewall-cmd --reload
   ```

   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

1. ほかに自分で有効にしたユーザーサービスがあるか見る。

   ```bash
   ls ~/.config/systemd/user/*.wants/ 2>/dev/null
   ```

   - 何も出さなければ、この節の手順 4 で linger を切る
   - 何か出す（[Dropbox（rclone）](dropbox-rclone.md) の `dropbox-rclone.timer` など）なら、linger はそれが使っているので、この節の手順 4 は飛ばす
   - [podman.md の Quadlet](podman.md#quadlet-で自動起動する任意) で動かしているコンテナは、この `ls` に出ない。`~/.config/containers/systemd/` に定義を置いているなら、この節の手順 4 は飛ばす

1. ほかにユーザーサービスを常駐させていないときだけ、linger を切る。

   ```bash
   sudo loginctl disable-linger "${USER}"
   ```

   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

1. 完全に消すときだけ、設定・鍵・DB とログを消す（取り戻せない）。

   ```bash
   rm -rf ~/.local/state/syncthing /home/linuxbrew/.linuxbrew/var/log/syncthing.log
   ```

   - 自動バックアップのアーカイブ（`~/syncthing-backup`）は消えない

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 に [Syncthing](https://syncthing.net/) の最新版を入れ、ログインしていない間も動き続けるファイル同期デーモンにする。Web GUI は LAN からも開けるようにする
- **進め方**: Homebrew で入れ、`brew services` が作る systemd ユーザーサービスと `loginctl enable-linger` で常駐させる
  - **GUI の認証を先に設定してから**待ち受けを LAN に広げ、最後に firewalld を開ける
  - 読者が書き換える値は無い（既定のままで通る）
- **状態**: **実機で本実行済み（2026-09-24）**
  - 下表のホストで、本書の各手順のコマンドを上から順に実行した。本書はその実測をもとに書き起こしたもので、コードブロックを機械的に貼り直してはいない
  - 結果として、次の状態になっている
    - `syncthing 2.1.5`（Homebrew、`arm64_linux` のボトル）が入っている
    - `sh.brew.syncthing.service` が `enabled` / `active`
    - 8384/tcp・22000/tcp・22000/udp・21027/udp が LISTEN
    - firewalld に `syncthing` と `syncthing-gui` が入っている
  - **firewalld 越しの到達は、network namespace から 8384/tcp と 22000/tcp について確認済み**（[付録](#付録-実機での検証記録2026-09-24)）
  - このホストは**一度構築したあとクリーンインストールした直後**の環境で、Homebrew に formula が 1 本も入っていない状態から始めている
  - **本実行していないこと**: ブラウザでの GUI ログイン、別デバイスとの実際の同期（フォルダ共有・競合処理）、再起動後の自動起動、21027/udp と 22000/udp の実疎通、[接続元を絞る（任意）](#接続元を絞る任意)、ロールバック
  - **バックアップと復旧の 2 節は、コンテナのみで検証した（2026-09-27）**
    - 対象は[設定を自動でバックアップする（任意）](#設定を自動でバックアップする任意)と[バックアップから戻す](#バックアップから戻す)、[手順 4](#実施手順)・[手順 9](#実施手順) に足した「戻したホスト」の箇条書き
    - AlmaLinux 10.2 x86_64 のコンテナ（systemd を PID 1）に Homebrew と `syncthing 2.1.5` を入れ、実施手順 1〜7 のあとに両節のコードブロックを貼って通した（[付録](#付録-コンテナでのバックアップと復旧の検証2026-09-27)）
    - 確認したこと: path ユニットとタイマーで取れる、中身が同じなら作らない、100 個を超えたら古いものから消す、送信専用フォルダから受信専用の相手（同じコンテナの 2 つ目の Syncthing）へ届く、同じホストで戻せる、新しいコンテナで戻すとデバイス ID・API キー・フォルダが戻って中身が相手から届く
    - 確認していないこと: 実機（aarch64 を含む）、別のマシンの相手、GUI での共有と受け入れ、実際の 0 時台のタイマーと `Persistent=true` の追いかけ実行

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

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${ST_GUI_USER}` | Web GUI のログイン名。OS のアカウントとは別物（自動で同じ名前が入る） | `<USER>` |
> | `${ST_GUI_ADDR}` | GUI の待ち受けアドレス | `0.0.0.0:8384`（既定）/ `127.0.0.1:8384` |
> | `${ST_LAN_IP}` | 案内と検証にだけ使う LAN 側 IP（デフォルト経路の送信元から自動で入る） | `192.168.1.10` |
> | `${ST_ALLOW_FROM}` | 送信元サブネットのリスト（空白区切り）。[接続元を絞る](#接続元を絞る任意)場合だけ、その節の冒頭で設定する | `192.168.1.0/24 10.99.0.0/30` |
> | `${ST_BACKUP}` | 戻すアーカイブ。[バックアップから戻す](#バックアップから戻す)場合だけ、その節の手順 3 で設定する（自動で最新が入る） | `~/syncthing-backup/syncthing-config-<日時>.tar.gz` |
>
> 出力例・ログ・表の中の値は `<HOSTNAME>` / `<SERVER_IP>` / `<WG_IP>`（`wg0` のアドレス）/ `<USER>`（OS アカウント名）/ `<DEVICE_ID>` / `<APIKEY>` のプレースホルダで書いてある。バージョン（`2.1.5`）は実行日によって変わる。
>
> **GUI のパスワードと API キーはこの文書に載せない。** デバイス ID は公開してよい値だが、実機のものはプレースホルダにしてある。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| Syncthing | 未導入（`syncthing` 無し、RPM も無し、`~/.local/state/syncthing` と `~/.config/syncthing` も無し） |
| Homebrew | 7.0.6 が `/home/linuxbrew/.linuxbrew` に導入済み。**formula は 0 本**（`~/.bashrc` に `brew shellenv` の行だけ） |
| 8384 / 22000 / 21027 の LISTEN | 無し |
| firewalld | active、default zone = `public`、`end0` と `wg0` が所属。services: `cockpit dhcpv6-client rdp ssh`、ports: `22/tcp 445/tcp 51820/udp` |
| linger | `Linger=no`（`/var/lib/systemd/linger/` は空）。`~/.config/systemd/user/` も未作成 |
| EPEL | 未設定（`epel-release` も未導入） |
| Go | 未導入（`go` 無し、`golang` RPM も無し） |

[samba.md](samba.md) の「実施前の状態」には firewalld の ports に `8384/tcp` が載っているが、**あれはクリーンインストール前の環境の記録**で、今回の実施前には開いていない。

### 選択した方針

AlmaLinux 10 / aarch64 で Syncthing を入れる経路を比べた（2026-09-24 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew の `syncthing`** | `2.1.5`。上流の最新リリース（v2.1.5、2026-09-08）と一致。`arm64_linux` のボトルがあるのでビルド不要。更新は `brew upgrade` | **採用** |
| EPEL 10 の `syncthing` | `syncthing-2.1.3-1.el10_3.aarch64`。`epel-release` は AlmaLinux の extras から入るので導入自体は容易で、systemd unit も同梱される。ただし 2 パッチぶん古い | 不採用（最新版ではない） |
| 公式の tarball（`release.syncthingcdn.net`） | `2.1.5`。公式の unit（`etc/linux-systemd/user/syncthing.service`）が付き、自己アップグレード機能も使える。配置も更新も手作業 | 不採用（更新が手作業になる） |
| 公式の RPM リポジトリ | **存在しない。** 公式が維持しているのは Debian / Ubuntu 向けの `apt.syncthing.net` だけ | — |

- **起動方式はユーザーサービス + linger にした**
  - 同期するのはホームディレクトリ配下なので、ファイルの持ち主として動かすのが素直
  - root 管理の `syncthing@<USER>.service` でも同じことはできるが、Homebrew 版は unit を同梱しないので自分で書くことになる
- **GUI は LAN に公開し、認証と TLS を先に入れた**
  - 公開しない構成（`127.0.0.1:8384` のまま、SSH ポートフォワードで開く）なら、手順 7 と `syncthing-gui` の開放が要らない
  - このホストは GNOME も入っていて、LAN 内の別 PC から触りたいので公開する方を採った
- **firewalld は定義済みサービス（`syncthing` / `syncthing-gui`）で開けた。** ポート番号を直接書くより意図が読め、上流がポートを足したときにも追従する
- **設定のバックアップは、systemd のユーザーユニット（path + タイマー）で自動にした**（[設定を自動でバックアップする（任意）](#設定を自動でバックアップする任意)）
  - Syncthing と同じユーザーの systemd に載せるので、root も cron も要らない。linger で、ログアウト中も動く
  - path ユニットなら、設定を変えた数秒後に取れる。1 日 1 回のタイマーは取りこぼしの保険
  - 取るのは鍵と `config.xml` だけで、DB は入れない（作り直せるうえ、動いている間のコピーは整合しない）
- **別の端末への複製は、Syncthing 自身の送信専用フォルダに任せた**
  - 公式のドキュメントが、設定ファイルのバックアップに勧めている形
  - restic（[導入元一覧](tool-catalog.md#cli-開発運用)にある）で別のリポジトリへ送る方法もあるが、送り先を別に用意することになる

### 完了時点の状態

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
- `https-cert.pem` / `https-key.pem` は、手順 7 で TLS を有効にしたときに Syncthing が自分で作った自己署名証明書（`cert.pem` / `key.pem` はデバイス ID のもとになる別物）

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

### 注意点

- **自分では更新しない**: Homebrew の formula は `--no-upgrade` でビルドしている（バージョン文字列の `noupgrade`）
  - 公式 tarball 版のような自己アップグレードは働かないので、`brew upgrade` で追う
  - **`brew upgrade` だけでは動いているプロセスが古いまま**なので、`brew services restart` まで行う
- **linger を切ると止まる**: `loginctl disable-linger` すると、ログアウトした時点で同期が止まる。止まっていること自体は GUI を開くまで気付きにくい
- **公開範囲は public ゾーンの全 NIC**: この環境では `wg0` も public にあるので、**VPN 越しの拠点からも 22000 と 8384 に届く**
  - 同期には好都合だが、GUI まで届くことは意識しておく。絞るなら[接続元を絞る（任意）](#接続元を絞る任意)
- **GUI の認証は必須**: LAN に開く構成なので、認証を設定しないまま待ち受けを広げると誰でも全設定を触れる。本書は手順 3〜4（認証）→ 手順 7（公開）→ 手順 8（firewalld）の順にしてある
- **証明書は自己署名**: ブラウザの警告は消えない。警告を無視する運用に慣れると本物の異常を見逃すので、常用するなら例外として明示的に登録する
- **API キーはパスワードと同じ重み**: `config.xml` にあり、これ 1 つで GUI の全操作ができる。ログや issue に貼らない
- **設定と DB は `~/.local/state/syncthing`**: 1.27.0 以降の既定
  - 戻すのに要るのは `cert.pem` / `key.pem`（失うとデバイス ID が変わる）と `config.xml`。DB（`index-v2`）は作り直せる
  - 自動で取っておくなら[設定を自動でバックアップする（任意）](#設定を自動でバックアップする任意)、戻すなら[バックアップから戻す](#バックアップから戻す)
- **2.x は DB 形式が 1.x と違う**: 2.0 で LevelDB から SQLite に変わり、1.x から上げると初回起動時に移行が走る（大きな構成では時間がかかる）
  - **移行後に 1.x へ戻せるかどうかは本書では確認していない**
  - 他のホストの 1.x から移すなら、上げる前に設定ディレクトリごと退避しておく
- **QUIC の受信バッファについて警告が出る**: 起動時に `failed to sufficiently increase receive buffer size (was: 208 kiB, wanted: 7168 kiB, got: 416 kiB)` と出る
  - 動作はする。消すなら `net.core.rmem_max` を上げる（本書では触っていない）
- **ホームを丸ごと同期しない**: `~/.local/state/syncthing` 自身やキャッシュまで対象になる。このホストは [Samba](samba.md) でホームを公開しているので、同じ領域を二重に扱うことにもなる

### 参照

- [Getting Started — Syncthing documentation](https://docs.syncthing.net/intro/getting-started.html) — 初回起動からフォルダー共有までの流れ
- [Autostarting Syncthing — Syncthing documentation](https://docs.syncthing.net/users/autostart.html) — systemd のシステムサービス / ユーザーサービスと `enable-linger`
- [Firewall Setup — Syncthing documentation](https://docs.syncthing.net/users/firewall.html) — 22000/tcp・22000/udp・21027/udp の役割
- [Configuration — Syncthing documentation](https://docs.syncthing.net/users/config.html) — `config.xml` の各要素と設定ディレクトリの既定値
- [Syncthing v2.0.0 リリースノート](https://github.com/syncthing/syncthing/releases/tag/v2.0.0) — SQLite への移行、構造化ログへの変更、廃止された項目（`--verbose` / `--logflags`）
- [homebrew-core の syncthing formula](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/s/syncthing.rb) — `--no-upgrade` ビルドと `service do` ブロック
- [Syncing Configuration Files — Syncthing documentation](https://docs.syncthing.net/users/config.html#syncing-configuration-files) — 設定ファイルを Syncthing でバックアップするなら送信専用フォルダにし、相手側で設定として使わない
- [Folder Types — Syncthing documentation](https://docs.syncthing.net/users/foldertypes.html) — 送信専用フォルダと「Override Changes」、受信専用フォルダ
- [FAQ — Syncthing documentation](https://docs.syncthing.net/users/faq.html) — 「My Syncthing database is corrupt」（DB を消して起動すると全フォルダを読み直す）と「folder marker missing」
- Syncthing 2.1.5 のソース — `lib/model/model.go` の `newFolder`（DB が空のフォルダはディレクトリと `.stfolder` を作る）、`lib/fs/tempname.go`（`.syncthing.` で始まる名前を一時ファイルとして扱う）、`syncthing generate` の `Key exists; will not overwrite`
- `man syncthing`（`generate`、`cli`、`--gui-address`）/ `man syncthing-config`（`<gui>`）/ `man syncthing-faq` / `man loginctl`（`enable-linger`）/ `man systemd.path` / `man systemd.timer`

---

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

自ホストから `https://<SERVER_IP>:8384/` を叩いてもローカル宛として処理され、firewalld を通らない。そこで veth で結んだ network namespace から接続した。ゾーン未割り当ての veth は既定ゾーン（public）の扱いになるので、public に開けたポートがそのまま効く（[samba.md](samba.md) の付録と同じ手法）:

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
- [接続元を絞る（任意）](#接続元を絞る任意)の rich rule
- ロールバック（`brew services stop` / `disable-linger` / `brew uninstall`）の本実行
- EPEL 版（2.1.3）との併用や、そこからの乗り換え
- 1.x からの DB 移行と、移行後に 1.x へ戻せるか（今回は新規導入なので移行そのものが走っていない）

---

### 付録: コンテナでのバックアップと復旧の検証（2026-09-27）

[設定を自動でバックアップする（任意）](#設定を自動でバックアップする任意)と[バックアップから戻す](#バックアップから戻す)を、コンテナで貼って通したときの記録。実機では試していない。

#### 環境

| 項目 | 値 |
|---|---|
| 実施日 | 2026-09-27 |
| 土台 | クラウド上の Docker 29.3.1（ホストは cgroup v1。ホストの `/sys/fs/cgroup/unified`（cgroup2）をコンテナの `/sys/fs/cgroup` に渡した） |
| コンテナ | `almalinux:10`（AlmaLinux 10.2、x86_64）を `--privileged --network host` で、`/sbin/init`（systemd 257）を PID 1 にして起動。イメージがマスクしている `systemd-logind` を戻し、`<USER>`（uid 1000）に `loginctl enable-linger` |
| Homebrew | 7.0.6（[homebrew.md](homebrew.md) と同じインストーラ） |
| Syncthing | `syncthing 2.1.5`（`x86_64_linux` のボトル。バージョン文字列の末尾は `[noupgrade]` で、aarch64 のボトルのような `modernc-sqlite` は付かない） |
| 相手の端末 | 同じコンテナの 2 つ目の Syncthing（`--home=~/peer`、`tcp://127.0.0.1:22001` で待ち受け、探索・リレー・NAT は切った） |
| 通していない手順 | [手順 8](#実施手順)（firewalld を入れていない） |

実施手順 1〜7 のあと（手順 3 のパスワードはブロックに直接書いた）、両節のコードブロックをそのまま貼った。相手の端末での操作（共有の受け入れ、受信専用、ゴミ箱）は、GUI の代わりに `syncthing cli --home=~/peer config ...` で同じ設定を入れた。

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
- `tar -x` で `config.xml` を上書きしたとき（[バックアップから戻す](#バックアップから戻す)の手順 4）も、path ユニットが走った
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

[設定を自動でバックアップする（任意）](#設定を自動でバックアップする任意)の手順 4 で入った `config.xml` のフォルダ:

```
<folder id="syncthing-backup-<HOSTNAME>" label="syncthing-backup (<HOSTNAME>)" path="/home/<USER>/syncthing-backup" type="sendonly" rescanIntervalS="3600" fsWatcherEnabled="true" fsWatcherDelayS="10" fsWatcherTimeoutS="0" ignorePerms="false" autoNormalize="true">
```

- `<defaults>` の `<folder>` と比べて違うのは、`<minDiskFree unit="">0</minDiskFree>`（既定は `unit="%"` の 1）だけ
- 相手に共有すると、相手の受信専用フォルダ（`~/peer-recv`）にアーカイブが届いた。確かめた時点で、相手のフォルダに `.tmp` の名前のファイルは無かった
- 102 個にしてから設定を変えると、こちらは 100 個になり、相手も 100 個になって、消えた 3 個は相手の `.stversions` に入った

#### 同じホストで戻す

GUI の待ち受けを `127.0.0.1:9999` に変えて壊した（壊した設定も path ユニットが取った）。壊す前のアーカイブを `ST_BACKUP` に入れ直して、[バックアップから戻す](#バックアップから戻す)の手順 2〜5 を貼った:

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

- [バックアップから戻す](#バックアップから戻す)の手順 1・3・4 を、Syncthing を入れる前に貼った。アーカイブは相手の受信専用フォルダから全部（9 個）コピーした（`scp` の代わりに `docker exec` の `tar` のパイプを使った）
- そのあと実施手順 2〜7 と 9 を通した

[手順 4](#実施手順) の `syncthing generate`:

```
WRN Key exists; will not overwrite (log.pkg=github)
INF Calculated device ID (device=<DEVICE_ID> log.pkg=github)
INF Updated GUI authentication password (log.pkg=github)
```

- `cert.pem` / `key.pem` の sha256 は戻したものと同じ。デバイス ID も元のコンテナと同じ
- `config.xml` の API キー・フォルダ（`docs` と `syncthing-backup-<HOSTNAME>`）・`<address>0.0.0.0:8384</address>`・`tls="true"` は残り、パスワードのハッシュだけ変わった

[手順 6](#実施手順) で起動したあとのログ（抜粋）:

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
- そのあと[設定を自動でバックアップする（任意）](#設定を自動でバックアップする任意)の手順 1〜3 を貼ると、アーカイブが 1 つ増えた（`generate` でパスワードのハッシュが変わったため）

#### アーカイブを 1 つだけ戻したとき

同じ新しいコンテナで、Syncthing を止めて DB（`index-v2`）を消し、`~/syncthing-backup` を最新の 1 個だけにして起動した:

```
state=idle needFiles=8 localFiles=1 globalFiles=9
```

- 送信専用フォルダは相手の 8 個を取りに行かず、「同期されていない」ままだった。相手の 9 個はそのまま
- ここで `POST /rest/db/override`（GUI の上書きのボタンと同じ）を送ると、`needFiles` 0・`globalFiles` 1 になり、相手の受信専用フォルダは 1 個になった。消えた 8 個は相手の `.stversions` に入った

#### 元に戻す

[設定を自動でバックアップする（任意）](#設定を自動でバックアップする任意)の手順 5 を、戻したコンテナで貼った:

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
- firewalld（手順 8）を含めた入れ直し
