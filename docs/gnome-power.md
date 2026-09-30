# GNOME の画面オフ・画面ロック・自動サスペンドの設定手順（AlmaLinux 10）

## 実施手順

> [!IMPORTANT]
> - **GNOME にログインするユーザー本人のシェルで実行する**。`sudo -i` / `su -` したシェルでは行わない（手順 2 の `gsettings` は、実行したユーザーの設定しか変えないため）

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- GNOME を入れていない（デスクトップの無い）機械では、手順 5・6 だけを行う
- 手順の後: 戻すときは[ロールバック](#ロールバック)

> [!WARNING]
> **手順 1・2 のほかは、x86_64 のコンテナでのみ検証した手順書**。手順 1・2 だけは aarch64 の実機（Raspberry Pi 5）で本実行した。画面が消えないこと・眠らないこと、ログイン画面・蓋・電源ボタンの実際の動きは確かめていない（[対象と検証環境](#対象と検証環境)）。

1. 変数を設定する。

   ```bash
   IDLE_DELAY=0               # 無操作で画面を消すまでの秒数。0 は消さない（GNOME の既定は 300）
   LOCK_ENABLED=false         # 画面が消えたときにロックするか。true / false（既定は true）
   POWER_BUTTON=interactive   # 電源ボタンを押したとき。interactive（電源オフの確認を出す）/ nothing（何もしない）
   for v in USER IDLE_DELAY LOCK_ENABLED POWER_BUTTON; do
     printf '%-12s = %s\n' "$v" "${!v}"
   done
   ```

   - **編集が必須の変数は無い**。既定のままなら、画面を消さず、ロックもしない
   - 最後に値を読み戻して確かめる
   - `USER` が `root` になっているなら、ここで止めて、自分のユーザーのシェルで貼り直す
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**（SSH を張り直したあとも）、手順 1 のブロックを貼り直してから先へ進む

   <details>
   <summary>補足: 変数について</summary>

   - 画面を消したいなら、`IDLE_DELAY` に秒数を入れる（`300` で 5 分）。消えたときにロックもするなら `LOCK_ENABLED=true`
   - 放置したときにサスペンドするかどうかは変数にしていない。手順 2・3 で `nothing`（何もしない）を直接書く
     - 手順 5 でサスペンドとハイバネートを OS ごと止めるので、ほかに選べる値が無いため
   - `POWER_BUTTON` も同じ理由で、`suspend` / `hibernate` は選ばない
     - `interactive` は、設定アプリの「電源ボタンの挙動」の「電源オフ」にあたる
     - 押すと何をするかを聞く画面が出て、何も選ばなければ 60 秒で電源が切れる（RHEL 10 の文書の 13.1.2 節）

   </details>

1. 自分のセッションの画面オフ・減光・ロック・自動サスペンド・電源ボタンを変える。

   ```bash
   /usr/bin/gsettings set org.gnome.desktop.session idle-delay "${IDLE_DELAY:?手順 1 の IDLE_DELAY が空のまま。値を入れて貼り直す}"
   /usr/bin/gsettings set org.gnome.desktop.screensaver lock-enabled "${LOCK_ENABLED:?手順 1 の LOCK_ENABLED が空のまま。値を入れて貼り直す}"
   /usr/bin/gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
   /usr/bin/gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type nothing
   /usr/bin/gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type nothing
   /usr/bin/gsettings set org.gnome.settings-daemon.plugins.power power-button-action "${POWER_BUTTON:?手順 1 の POWER_BUTTON が空のまま。値を入れて貼り直す}"
   /usr/bin/gsettings get org.gnome.desktop.session idle-delay
   /usr/bin/gsettings get org.gnome.desktop.screensaver lock-enabled
   /usr/bin/gsettings list-recursively org.gnome.settings-daemon.plugins.power | grep -E 'idle-dim|sleep-inactive-(ac|battery)-type|power-button-action'
   ```

   - 最後の 3 つのコマンドで読み戻す
   - `uint32 0`、`false`、続いて `idle-dim false`・`power-button-action 'interactive'`・`sleep-inactive-ac-type 'nothing'`・`sleep-inactive-battery-type 'nothing'` の 4 行が出ればよい
   - 値が変わっていなければ、デスクトップの端末で手順 1 から貼り直す（`gsettings` は書けなかったときも終了コード 0 で終わる。この手順の補足）
   - **注意**: `/usr/bin/` を外さない（この手順の補足）

   <details>
   <summary>補足: 変える前の値、0 にしても暗くなる理由、設定アプリの項目</summary>

   **変える前の値**（コンテナの実測。`gnome-settings-daemon-server-defaults` が無い、Workstation と同じ条件）:

   ```
   $ gsettings get org.gnome.desktop.session idle-delay
   uint32 300
   $ gsettings get org.gnome.desktop.screensaver lock-enabled
   true
   $ gsettings list-recursively org.gnome.settings-daemon.plugins.power | grep -E 'idle-dim|sleep-inactive|power-button-action'
   org.gnome.settings-daemon.plugins.power idle-dim true
   org.gnome.settings-daemon.plugins.power power-button-action 'suspend'
   org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 900
   org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'suspend'
   org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 900
   org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend'
   ```

   - 既定では、5 分で画面が消えてすぐロックし、電源につないでいても 15 分（900 秒）で眠る
   - Server with GUI で入れた PC は、`gnome-settings-daemon-server-defaults` が `sleep-inactive-ac-timeout` を `0`（眠らない）にしている。電源ボタンは既定の `'suspend'` のまま（[注意点](#注意点)）
   - タイムアウトではなく方式（`sleep-inactive-*-type`）を `nothing` にするのは、設定アプリ（gnome-control-center 47.7）が「自動サスペンド」を切った状態をこの形で表すため（ソースの `cc-power-panel.c` から）

   **`idle-dim` も切る理由**: gnome-settings-daemon 47.2 は、`idle-dim` が true のとき、`idle-delay` が 0 でも 60 秒の無操作で画面を暗くする（ソースの `IDLE_DIM_BLANK_DISABLED_MIN`）。

   - 電源モードが省電力のときは、`idle-dim` にかかわらず 30 秒で暗くする（同じソースから。画面では確かめていない）

   **設定アプリの項目**（EL10 の gnome-control-center 47.7 に入っている日本語の翻訳から）:

   | キー | 設定アプリの項目 |
   |---|---|
   | `idle-delay` | 「電源」→「省電力」→「空白のスクリーン」、「プライバシーとセキュリティー」→「スクリーンロック」→「空白スクリーンの遅延」。0 は「なし」 |
   | `idle-dim` | 「電源」→「省電力」→「スクリーンを暗くする」 |
   | `sleep-inactive-ac-type` / `sleep-inactive-battery-type` | 「電源」→「省電力」→「自動サスペンド」の「プラグイン時」/「バッテリー動作時」 |
   | `power-button-action` | 「電源」→「電源ボタンの挙動」（サスペンド / 電源オフ / ハイバネート / なにもしない。電源オフが `interactive`） |
   | `lock-enabled` | 「プライバシーとセキュリティー」→「スクリーンロック」→「自動スクリーンロック」 |

   - 同じキーを書くので、動いているセッションにはログインし直さなくても効くはず（gsd は設定の変更を監視している。画面では確かめていない）

   **`gsettings` が書けなかったとき**: セッションバスに届かないシェルでは、警告を出して値を変えず、**終了コードは 0** になる。コンテナで、セッションバスを用意せずに実行したときの実測:

   ```
   $ gsettings set org.gnome.desktop.session idle-delay 0; echo "rc=$?"

   (process:2195): dconf-WARNING **: 08:33:08.265: failed to commit changes to dconf: Cannot spawn a message bus without a machine-id: Invalid machine ID in /var/lib/dbus/machine-id or /etc/machine-id
   rc=0
   $ gsettings get org.gnome.desktop.session idle-delay
   uint32 300
   ```

   - 警告の文面は環境で変わる。`failed to commit changes to dconf` が出たら、書けていない
   - 範囲の外の値（`POWER_BUTTON=poweroff` など）は `The provided value is outside of the valid range` で失敗し、終了コードは 1 になる。値は変わらない

   **Homebrew の `gsettings` のとき**: Homebrew の `gsettings` は、GNOME に効かないのに、読み戻しでは変わったように見える。

   - Homebrew の glib は dconf のモジュールを持たないので、`gsettings` は dconf ではなく `~/.config/glib-2.0/settings/keyfile` に書き、同じファイルから読み戻す。警告は出ず、終了コードも 0
   - Homebrew の formula の多く（cairo・ffmpeg・imagemagick など）が glib に依存するので、[homebrew.md](homebrew.md) を通したホストでは PATH の先頭の `gsettings` がこれになりやすい
   - 2026-10-01 に Raspberry Pi 5 の実機で確かめた
     - `command -v gsettings` が `/home/linuxbrew/.linuxbrew/bin/gsettings`（glib 2.90.0）のホスト
     - `G_MESSAGES_DEBUG=all` を付けると `Found default implementation keyfile (GKeyfileSettingsBackend)` と出た
     - `gsettings get org.gnome.desktop.session idle-delay` が `uint32 300` を返し、`/usr/bin/gsettings` は dconf の `uint32 0` を返した
     - Homebrew の `gsettings set` で書いた値は、Homebrew の `gsettings get` では変わって見え、`/usr/bin/gsettings get` では変わっていなかった
   - そのため、この手順と[ロールバック](#ロールバック)の手順 1 は `/usr/bin/gsettings` で書いてある（2026-10-01 に直した。それまでのコンテナの検証は、Homebrew の無い環境で `gsettings` のまま流した）

   </details>

1. ログイン画面（GDM）用の、自動サスペンドと電源ボタンの設定を書く。

   ```bash
   sudo tee /etc/dconf/db/gdm.d/90-power >/dev/null <<EOF
   [org/gnome/settings-daemon/plugins/power]
   sleep-inactive-ac-type='nothing'
   sleep-inactive-battery-type='nothing'
   power-button-action='${POWER_BUTTON:?手順 1 の POWER_BUTTON が空のまま。値を入れて貼り直す}'
   EOF
   ```

   - 文字列の値は引用符（`'`）で囲む。囲まないと、手順 4 の `dconf update` が失敗する
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: ログイン画面の設定の置き場所</summary>

   **Workstation で入れた PC のログイン画面は、既定では 15 分で眠る。** GDM 47 は、ログイン画面の電源のキーを何も設定していない（上流の `data/dconf/defaults/00-upstream-settings`）。

   - そのため gnome-settings-daemon の既定（電源につないでいても 900 秒でサスペンド）がそのまま効く
   - Server with GUI で入れた PC は、手順 2 の補足の override がログイン画面にも効くので、電源につないでいる間は眠らない
   - コンテナで、ログイン画面から見える値（手順 4 と同じ読み方）がそうなっていることを確かめた。実機で眠るところは確かめていない
   - 再起動した後や、GNOME Remote Desktop のリモートログインを待っている間は、ログイン画面のまま置かれる

   **置き場所**: ログイン画面は `gdm` ユーザーで動き、dconf のプロファイル `/usr/share/dconf/profile/gdm` を読む。

   ```
   user-db:user
   system-db:gdm
   system-db:local
   system-db:site
   system-db:distro
   file-db:/usr/share/gdm/greeter-dconf-defaults
   ```

   - RHEL の gdm は `system-db:gdm` などの行を足してある（CentOS Stream 10 の gdm のパッチ `0001-data-add-system-dconf-databases-to-gdm-profile.patch`）
   - そのため `/etc/dconf/db/gdm.d/` に置いたファイルは、ログイン画面にだけ効く
   - ファイル名の `90-` は、同じキーを書いたファイルが複数あると名前の順で後ろが勝つため、後ろに置いた（GDM の既定のファイルのコメントも、数字の大きい名前を勧めている）

   **書かなかったキー**: 画面を消す（`idle-delay`）とロックのキーは書いていない。

   - ログイン画面はもともとロックしない（GDM の既定で `disable-lock-screen=true`）
   - 画面は 5 分で消える。消したくないなら、`[org/gnome/desktop/session]` の節に `idle-delay=uint32 0` を、電源の節に `idle-dim=false` を足す
   - **`uint32` を付けずに `idle-delay=0` と書くと、エラーにならずに無視される**（コンテナで、ログイン画面から見える値が `uint32 300` のままだった）

   **引用符を付けなかったとき**（コンテナの実測。`91-test` は確かめるために置いたファイル）:

   ```
   $ sudo dconf update
   /etc/dconf/db/gdm.d: 91-test: [org/gnome/settings-daemon/plugins/power]: sleep-inactive-ac-type: invalid value: nothing: 0-7:unable to infer type
   error: failed to update at least one of the databases
   ```

   - 終了コードは 1 で、`/etc/dconf/db/gdm` は作り直されず、前の内容のまま残った

   </details>

1. dconf のデータベースを作り直し、ログイン画面から見える値を確かめる。

   ```bash
   {
     sudo dconf update
     sudo -u gdm env DCONF_PROFILE=gdm gsettings list-recursively org.gnome.settings-daemon.plugins.power | grep -E 'sleep-inactive-(ac|battery)-type|power-button-action'
   }
   ```

   - `dconf update` は、成功すると何も出さない。`invalid value` と出たら、手順 3 から貼り直す
   - `power-button-action 'interactive'`・`sleep-inactive-ac-type 'nothing'`・`sleep-inactive-battery-type 'nothing'` の 3 行が出ればよい

   <details>
   <summary>補足: gdm ユーザーで読む理由</summary>

   `sudo -u gdm env DCONF_PROFILE=gdm` は、ログイン画面と同じユーザー・同じプロファイルで読む。

   - 自分のユーザーのまま `DCONF_PROFILE=gdm` で読むと、プロファイルの先頭の `user-db:user` が自分の設定を指すので、手順 2 で変えた自分の値が見えてしまう
   - コンテナで、自分の `power-button-action` を `'nothing'`、ログイン画面用のファイルを `'interactive'` にして比べると、自分で読むと `'nothing'`、`gdm` ユーザーで読むと `'interactive'` だった
   - 読むと `/var/lib/gdm/.cache/dconf/user`（2 バイトの目印のファイル）が作られる。消さなくてよい
   - 動いているログイン画面に、いつから効くかは確かめていない。次にログイン画面が出たとき（ログアウトか再起動の後）には読まれるはず

   </details>

1. OS 全体で、サスペンドとハイバネートを止める。

   ```bash
   {
     sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
     systemctl is-enabled sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
   }
   ```

   - `Created symlink '/etc/systemd/system/sleep.target' → '/dev/null'.` のような行が 5 つ出て、`masked` が 5 行出ればよい
   - GNOME のメニュー・蓋・電源ボタンなど、どこから頼まれてもサスペンドが始まらなくなる（確かめたのは logind の答えだけ。この手順の補足）
   - **注意**: ノート PC は、蓋を閉じても電池が減っても眠らない。閉じたまま鞄に入れると熱を持つので、持ち歩くときは電源を切る

   <details>
   <summary>補足: mask で止まるもの</summary>

   `mask` は、unit のファイルを `/dev/null` へのシンボリックリンクで覆って、起動できなくする。

   - logind は、mask された target を使うサスペンドを「できない」と答える
   - コンテナで、logind の `CanSuspend` が mask の前の `"yes"` から、後で `"no"` に変わった
     - コンテナの `/sys/power` は、中身を偽物にした tmpfs に差し替えてある。本当には眠れない状態で確かめた（[付録](#付録-コンテナでの検証記録2026-09-27)）
   - 設定アプリ（gnome-control-center 47.7）は、`CanSuspend` が `"yes"` のときだけ「自動サスペンド」の行と電源ボタンの「サスペンド」を出す
     - ハイバネートもできないときは、「電源ボタンの挙動」の行ごと出さない
     - どちらもソースから読んだもので、画面では確かめていない
   - `suspend-then-hibernate.target` も systemd 257 にあるので、一緒に止める

   </details>

1. 蓋を閉じても何もしないように、logind のドロップインを置く。

   ```bash
   {
     sudo mkdir -p /etc/systemd/logind.conf.d
     sudo tee /etc/systemd/logind.conf.d/90-lid.conf >/dev/null <<'EOF'
   [Login]
   HandleLidSwitch=ignore
   EOF
     sudo systemctl reload systemd-logind
     busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager HandleLidSwitch
   }
   ```

   - `s "ignore"` と出ればよい（既定は `s "suspend"`）
   - 蓋の無い PC では何も変わらない（置いても害は無い）

   <details>
   <summary>補足: mask とは別に蓋の設定を置く理由</summary>

   手順 5 の後は、蓋を閉じても、logind は mask された target を使えないので眠らないはず（蓋のイベントは確かめていない）。それでも設定を置くのは、次の 2 つのため。

   - 「蓋を閉じても何もしない」ことを設定として残す。手順 5 の mask を外したときも、蓋では眠らない
   - 眠れないサスペンドを logind が試みることが無くなる

   **既定の値**（コンテナの実測）:

   - `HandleLidSwitchExternalPower`（電源につないでいるとき）は空で、`HandleLidSwitch` に従う
   - `HandleLidSwitchDocked`（外部ディスプレイをつないでいるときなど）は `"ignore"`
   - `/etc/systemd/logind.conf.d` は最初は無いので、`mkdir -p` で作る

   **`systemctl reload systemd-logind` で読み直す**: systemd 257 の logind は `Type=notify-reload` で、reload すると設定ファイルを読み直す。

   - journal に `Config file reloaded.` が出る

   **電源ボタンの `HandlePowerKey` は変えない**: GNOME が動いている間（ログイン画面を含む）は、手順 2・3 の `power-button-action` が効く。

   - `HandlePowerKey` は、GNOME が動いていないときの設定（RHEL 10 の文書の 13.1 節）

   </details>

---

## ロールバック

- 上から順に貼る。手順 1 の変数は要らない
- 自分のセッションとログイン画面は、変える前の値ではなく**既定値**に戻る
  - Server with GUI で入れた PC は、既定でも電源につないでいる間は眠らない（手順 2 の補足）
- ロールバックも、コンテナでのみ本実行した

1. 自分のセッションの値を既定値に戻す。

   ```bash
   /usr/bin/gsettings reset org.gnome.desktop.session idle-delay
   /usr/bin/gsettings reset org.gnome.desktop.screensaver lock-enabled
   /usr/bin/gsettings reset org.gnome.settings-daemon.plugins.power idle-dim
   /usr/bin/gsettings reset org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type
   /usr/bin/gsettings reset org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type
   /usr/bin/gsettings reset org.gnome.settings-daemon.plugins.power power-button-action
   /usr/bin/gsettings get org.gnome.desktop.session idle-delay
   /usr/bin/gsettings get org.gnome.desktop.screensaver lock-enabled
   /usr/bin/gsettings list-recursively org.gnome.settings-daemon.plugins.power | grep -E 'idle-dim|sleep-inactive-(ac|battery)-type|power-button-action'
   ```

   - `uint32 300`、`true`、続いて `idle-dim true`・`power-button-action 'suspend'`・`sleep-inactive-ac-type 'suspend'`・`sleep-inactive-battery-type 'suspend'` の 4 行が出ればよい

1. ログイン画面用の設定ファイルを消す。

   ```bash
   sudo rm -f /etc/dconf/db/gdm.d/90-power
   ```

   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

1. dconf のデータベースを作り直し、ログイン画面から見える値が戻ったか確かめる。

   ```bash
   {
     sudo dconf update
     sudo -u gdm env DCONF_PROFILE=gdm gsettings list-recursively org.gnome.settings-daemon.plugins.power | grep -E 'sleep-inactive-(ac|battery)-type|power-button-action'
   }
   ```

   - 3 行とも `'suspend'` になればよい

1. サスペンドとハイバネートの mask を外す。

   ```bash
   {
     sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
     systemctl is-enabled sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
   }
   ```

   - `Removed '/etc/systemd/system/sleep.target'.` のような行が 5 つ出て、`static` が 5 行出ればよい

1. 蓋のドロップインを消し、logind に読み直させる。

   ```bash
   {
     sudo rm -f /etc/systemd/logind.conf.d/90-lid.conf
     sudo systemctl reload systemd-logind
     busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager HandleLidSwitch
   }
   ```

   - `s "suspend"` と出ればよい
   - 空の `/etc/systemd/logind.conf.d` は残る

---

## 補足

### 対象と検証環境

- **目的**: 常時動かしておく PC で、GNOME が画面を消したり、ロックしたり、放置で眠ったりしないようにする。ログイン画面・蓋・OS のサスペンドも止める
  - [WireGuard](wireguard.md)・[Samba](samba.md)・[Syncthing](syncthing.md)・[Dropbox](dropbox.md)・[Dropbox（rclone）](dropbox-rclone.md)・[GNOME Remote Desktop](gnome-remote-desktop.md) のホストは、眠るとサービスが止まる
  - [GNOME のヘッドレスのセッション](gnome-headless-session.md)は、手順 1・2（サスペンドできる PC では手順 3〜5 も）を前提にしている。ヘッドレスのセッションでも gsd-power は、既定では 15 分の無操作でサスペンドしようとする
  - [Claude Code で GUI を確かめる](claude-code-gui.md)は、手順 1・2 を前提にしている。ロックされると、画面の前にいない Claude Code には解けない
- **進め方**: 自分のセッションは `gsettings`、ログイン画面は dconf の `gdm.d`、OS 全体は `systemctl mask`、蓋は logind のドロップインで変える。**読者が書き換える必要のある変数は無い**
- **状態**: **x86_64 のコンテナで検証済み（2026-09-27）。手順 1・2 だけは aarch64 の実機（Raspberry Pi 5）で本実行した（2026-10-01）**
  - 下表の 2 つのコンテナで、**この文書のコードブロックをそのまま貼って**、手順 1〜6 と[ロールバック](#ロールバック)を通した
    - 手順 1〜4 とロールバックの 1〜3: GNOME の一式を入れたコンテナで、`dbus-run-session` のセッションバスの中で実行
    - 手順 5・6 とロールバックの 4・5: systemd を PID 1 にしたコンテナで実行
  - [flatpak.md](flatpak.md) と同じ、x86_64 のクラウドホスト上の Docker で行った
  - 確認したこと:
    - `gsettings` で 6 つのキーが変わり、`reset` で既定値に戻る
    - ログイン画面から見える値（`gdm` ユーザーと `gdm` のプロファイルで読んだ値）が、`gdm.d` のファイルで変わり、消すと戻る
    - mask で、logind の `CanSuspend` が `"yes"` から `"no"` に変わる（本当には眠れないコンテナで）
    - logind の `HandleLidSwitch` が `"ignore"` になり、戻せる
  - **確認していないこと**: 画面が消えない・暗くならない・ロックしないこと、実際に眠らないこと、ログイン画面・蓋・電源ボタンの実際の動き、GNOME のメニューと設定アプリの表示。コンテナには画面も GNOME のセッションも無いため
  - 2026-09-28: 手順 4〜6 と、[ロールバック](#ロールバック)の手順 3〜5のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../README.md#記法)）
    - 中のコマンドは変えていない。囲んだ形は構文の検査だけで、流していない
  - 2026-10-01: 手順 2 と[ロールバック](#ロールバック)の手順 1 の `gsettings` を `/usr/bin/gsettings` にした（Homebrew の `gsettings` は GNOME に効かないため。手順 2 の補足）
    - ロールバックの手順 1 の、`/usr/bin/gsettings` にした形は流していない
  - 2026-10-01: 手順 1・2 を aarch64 の実機（Raspberry Pi 5）で本実行した（[付録](#付録-実機での検証記録2026-10-01)）
    - GNOME のヘッドレスのセッションの手順書（今の [gnome-headless-session.md](gnome-headless-session.md) と [claude-code-gui.md](claude-code-gui.md) に分ける前の版）の前提として、SSH でログインしたシェルに貼った（ブラケットペーストの無しと有り）
    - 読み戻しは[完了時点の状態](#完了時点の状態)と同じ。SSH のシェルから変えた値は、動いているヘッドレスのセッションにすぐ効いた
    - 手順 2 の後は、ヘッドレスのセッションを 16 分余り放置しても、サスペンドしようとしなかった（手順 2 の前は、15 分でしようとした）
    - 手順 3〜6 とロールバックは、実機では流していない

| 項目 | 実機 | コンテナ（GNOME の一式） | コンテナ（systemd） |
|---|---|---|---|
| 実施日 | 2026-10-01（手順 1・2 だけ） | 2026-09-27 | 2026-09-27 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/almalinux:10.2`、Docker 29.3.1） | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/10-init:10.2`） |
| GNOME | `gnome-shell-49.4-9.el10_2.alma.1`、`gnome-settings-daemon-47.2-10.el10_2.alma.1`、`glib2-2.80.4-12.el10_2.22`（ヘッドレスのセッション） | `gdm-47.0-24.el10_2`、`gnome-shell-49.4-9.el10_2.alma.1`、`gnome-settings-daemon-47.2-10.el10_2.alma.1`、`gsettings-desktop-schemas-47.1-4.el10`、`dconf-0.40.0-17.el10`（`gdm` と `gnome-control-center` を入れて依存で揃えた） | 無し |
| systemd | `systemd-257-23.el10_2.2.alma.1` | PID 1 ではない | `systemd-257-23.el10_2.2.alma.1`（`systemd-udev` も入れた） |
| セッションバス | ユーザーの systemd のセッションバス（SSH でログインしたシェルから） | `dbus-run-session`（GNOME のセッションの代わり） | — |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${IDLE_DELAY}` | 無操作で画面を消すまでの秒数（`0` は消さない） | `0`（既定）/ `300` |
> | `${LOCK_ENABLED}` | 画面が消えたときにロックするか | `false`（既定）/ `true` |
> | `${POWER_BUTTON}` | 電源ボタンを押したときの動作 | `interactive`（既定）/ `nothing` |
>
> 変数を使わない値（`nothing`、ファイル名の `90-power` / `90-lid.conf`）はコマンドに直接書いてある。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

コンテナで、手順 1 の前に確かめた状態:

| 項目 | 状態 |
|---|---|
| 自分のセッション | `idle-delay` が `uint32 300`、`lock-enabled` が `true`、`idle-dim` が `true`、`sleep-inactive-ac-type` / `sleep-inactive-battery-type` が `'suspend'`（タイムアウトはどちらも 900 秒）、`power-button-action` が `'suspend'` |
| ログイン画面から見える値 | 自分のセッションと同じ |
| `/etc/dconf/db/gdm.d` | 空の `locks` ディレクトリだけ |
| `gnome-settings-daemon-server-defaults` | 未導入（Workstation と同じ） |
| sleep 系の target | 5 つとも `static` |
| logind | `HandleLidSwitch` が `"suspend"`、`HandlePowerKey` が `"poweroff"`。`/etc/systemd/logind.conf.d` は無い |

### 選択した方針

| 変えるもの | 方法 | 採否 |
|---|---|---|
| 自分のセッション | `gsettings`（自分の dconf の `~/.config/dconf/user` に書く） | **採用**。設定アプリと同じキーで、自分にだけ効く |
| 自分のセッション | dconf の `local.d` にファイルを置いて `dconf update`（RHEL 10 の文書が電源ボタンの例で使う方法） | 不採用。自分で変えた値（`gsettings` や設定アプリ）が優先されて効かないことがあるうえ、RHEL の gdm のプロファイルは `system-db:local` も読むので、ログイン画面にもかかる |
| ログイン画面 | dconf の `gdm.d` | **採用**。ログイン画面のプロファイルだけが読む |
| ログイン画面 | `gdm` ユーザーとして `gsettings set` し、`gdm` ユーザー自身の設定に書く | 不採用。値が `/var/lib/gdm` の中に隠れ、`/etc` を見ても分からない |
| OS 全体 | sleep 系の target を `systemctl mask` | **採用**。`systemctl is-enabled` で状態を確かめられ、`unmask` で戻せる |
| OS 全体 | `/etc/systemd/sleep.conf.d/` で `AllowSuspend=no` などにする | 試していない（mask で `CanSuspend` が `"no"` になることを確かめたので足りた） |
| 電源ボタン | logind の `HandlePowerKey` | 変えない。GNOME が動いている間は `power-button-action` が効く（手順 6 の補足） |
| 蓋 | logind の `HandleLidSwitch=ignore`（ドロップイン） | **採用**。RHEL 10 の文書は `/etc/systemd/logind.conf` を直接書き換えるが、ドロップインなら消すだけで戻せる |

### 完了時点の状態

**GNOME の一式のコンテナ**（手順 4 の直後）:

```
$ gsettings get org.gnome.desktop.session idle-delay
uint32 0
$ gsettings get org.gnome.desktop.screensaver lock-enabled
false
$ gsettings list-recursively org.gnome.settings-daemon.plugins.power | grep -E 'idle-dim|sleep-inactive-(ac|battery)-type|power-button-action'
org.gnome.settings-daemon.plugins.power idle-dim false
org.gnome.settings-daemon.plugins.power power-button-action 'interactive'
org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
$ cat /etc/dconf/db/gdm.d/90-power
[org/gnome/settings-daemon/plugins/power]
sleep-inactive-ac-type='nothing'
sleep-inactive-battery-type='nothing'
power-button-action='interactive'
$ sudo -u gdm env DCONF_PROFILE=gdm gsettings list-recursively org.gnome.settings-daemon.plugins.power | grep -E 'sleep-inactive-(ac|battery)-type|power-button-action'
org.gnome.settings-daemon.plugins.power power-button-action 'interactive'
org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
```

**systemd のコンテナ**（手順 6 の直後）:

```
$ systemctl is-enabled sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
masked
masked
masked
masked
masked
$ cat /etc/systemd/logind.conf.d/90-lid.conf
[Login]
HandleLidSwitch=ignore
$ busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager HandleLidSwitch
s "ignore"
```

### 注意点

- **`gsettings` は、書けなかったときも終了コード 0 で終わる**: 手順 2 の読み戻しで確かめる（手順 2 の補足）
- **Homebrew の `gsettings` は GNOME に効かない**: dconf ではなくファイルに書き、読み戻しでは変わったように見える。この文書の `gsettings` は `/usr/bin/gsettings` で呼ぶ（手順 2 の補足）
  - `sudo -u gdm … gsettings` の行（手順 4 と[ロールバック](#ロールバック)の手順 3）は、そのままでよい。`sudo` は PATH を `secure_path`（`/sbin:/bin:/usr/sbin:/usr/bin`）に置き換えるので、Homebrew は探さない
    - Raspberry Pi 5 で、`sudo -u gdm env sh -c 'command -v gsettings'` が `/bin/gsettings` を返した（手順 4 そのものは実機で流していない）
- **dconf のファイルの型**: 文字列は `'nothing'` のように引用符で囲む。`idle-delay` のような uint32 は `uint32 0` と書く（手順 3 の補足）
  - 引用符が無いと `dconf update` が失敗し、データベースは前の内容のまま残る
  - `uint32` が無いと、エラーにならずに無視される
- **Server with GUI の設定も、同じ落とし穴を踏んでいる**: `gnome-settings-daemon-server-defaults` の override（`/usr/share/glib-2.0/schemas/org.gnome.settings-daemon.plugins.power.gschema.override`）は、次の 2 つを書いている
  - `sleep-inactive-ac-timeout=0` は効いていて、電源につないでいる間は眠らない
  - `power-button-action=nothing` は引用符が無いので、スキーマのコンパイルで読み飛ばされ、電源ボタンは既定の `'suspend'` のまま（コンテナで確認。同じ内容を `glib-compile-schemas --strict` に通すと `can not parse as value of type 's'` で止まる）
- **自分で変えた値が優先される**: dconf は、自分の設定（`gsettings` と設定アプリが書く user-db）を、`/etc/dconf/db` のデータベースより先に読む
  - 手順 2 を `gsettings` で行い、`local.d` を使わなかったのはこのため
- **仮想マシンの中では**: gnome-settings-daemon は放置によるサスペンドをしない（gsd 47.2 のソースから）
  - 電源ボタンは `nothing` 以外だと電源オフになる（`power-button-action` のスキーマの説明から）
- **設定アプリで後から変えるとき**: 手順 5 の後は「自動サスペンド」の行が出ないので、戻すなら `gsettings` か[ロールバック](#ロールバック)で行う（手順 5 の補足）

### 参照

- [Changing system power settings — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/changing-system-power-settings) — 電源ボタン（dconf と logind）と蓋（logind）の設定
- [gnome-settings-daemon 47.2 の電源のスキーマ](https://gitlab.gnome.org/GNOME/gnome-settings-daemon/-/blob/47.2/data/org.gnome.settings-daemon.plugins.power.gschema.xml.in) — `sleep-inactive-*`・`idle-dim`・`power-button-action` の既定値と説明
- [GDM 47.0 のログイン画面の既定の設定](https://gitlab.gnome.org/GNOME/gdm/-/blob/47.0/data/dconf/defaults/00-upstream-settings) — 電源のキーが無いこと
- `man dconf`（`dconf update` とプロファイル）/ `man 5 logind.conf`（`HandleLidSwitch`）/ `man systemctl`（`mask`）

---

### 付録: コンテナでの検証記録（2026-09-27）

x86_64 のクラウドホスト上の Docker で、使い捨てのコンテナを 2 つ使った。どちらも非 root ユーザーを作り、NOPASSWD の sudo を与えている。実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、実機で加えた変更は無い。

- **GNOME の一式のコンテナ**: `quay.io/almalinuxorg/almalinux:10.2` に `sudo`・`gdm`・`gnome-control-center` を `dnf install` で入れ、GNOME の一式を依存で揃えた（488 パッケージ）
  - GNOME のセッションの代わりに、`dbus-run-session -- bash` の中でコードブロックを実行した
  - 落とし穴の再現（引用符・`uint32`・セッションバスの無いシェル・自分のユーザーで読んだとき）と、Server with GUI との比較は、同じ構成の別のコンテナで行った
- **systemd のコンテナ**: `quay.io/almalinuxorg/10-init:10.2` に `systemd-udev`（sleep 系の target を含む）を入れ、イメージが mask している `systemd-logind` を戻して、systemd を PID 1 で動かした
  - ホストに触れないように、udev・sysctl・モジュールの読み込みなどの unit は mask した
  - `/sys/power` は、中身（`state` に `freeze mem disk` など）を書いた tmpfs に差し替えた。logind はサスペンドできると判断するが、本当には眠れない。サスペンドを呼ぶ操作は一度もしていない

| 手順 | 結果 |
|---|---|
| 1. 変数 | `USER = <USER>`、`IDLE_DELAY = 0`、`LOCK_ENABLED = false`、`POWER_BUTTON = interactive` |
| 2. 自分のセッション | 読み戻しは [完了時点の状態](#完了時点の状態) のとおり。`~/.config/dconf/user`（748 バイト）ができた。セッションバスを用意しないと `failed to commit changes to dconf` で値が変わらず、終了コードは 0 だった |
| 3〜4. ログイン画面 | `dconf update` は無出力で終了コード 0。`gdm` ユーザーで読んだ値が `'nothing'` 2 つと `'interactive'` になった。引用符を外したファイルでは `invalid value` で終了コード 1、`idle-delay=0` は無視されて `uint32 300` のまま（手順 3 の補足） |
| 5. mask | `Created symlink` が 5 行、`masked` が 5 行。logind の `CanSuspend` は mask の前が `"yes"`、後が `"no"` |
| 6. 蓋 | reload で journal に `Config file reloaded.`。`HandleLidSwitch` は `"suspend"` から `"ignore"` に |
| ロールバック 1 | `uint32 300`・`true`・`idle-dim true`・`'suspend'` が 3 つ |
| ロールバック 2〜3 | `gdm` ユーザーで読んだ値が 3 つとも `'suspend'` に戻った。`gdm.d` には `locks` だけが残った |
| ロールバック 4 | `Removed` が 5 行、`static` が 5 行。`CanSuspend` は `"yes"` に戻った |
| ロールバック 5 | `s "suspend"`。空の `/etc/systemd/logind.conf.d` が残った |
| 比較. Server with GUI | `gnome-settings-daemon-server-defaults` を入れると、自分のセッションとログイン画面の両方で `sleep-inactive-ac-timeout` が `0` になり、`power-button-action` は `'suspend'` のままだった（[注意点](#注意点)）。確かめた後に消した |

#### 未確認事項

- 実機（Raspberry Pi 5 / x86_64 PC）での実行と、aarch64 での実行
- 画面が消えない・暗くならない・ロックしないこと（GNOME のセッションで）
- 放置しても、ログイン画面のままでも眠らないこと
- 蓋を閉じたとき・電源ボタンを押したときの動き
- GNOME のメニューと設定アプリで、サスペンドの項目が消えること
- SSH で入ったシェルから `gsettings` で変えた値が、動いている GNOME のセッションに届くか
- 動いているログイン画面に、`dconf update` の後いつから効くか
- GNOME Remote Desktop のリモートログインのセッションを放置したときの動き

---

### 付録: 実機での検証記録（2026-10-01）

**環境**: Raspberry Pi 5（aarch64）の AlmaLinux 10.2。モニターはつながっておらず、[gnome-headless-session.md](gnome-headless-session.md) のヘッドレスのセッションを動かした（表の「実機」の列）。PATH の先頭は Homebrew で、`command -v gsettings` は `/home/linuxbrew/.linuxbrew/bin/gsettings`（glib 2.90.0）だった。

**流し方**: GNOME のヘッドレスのセッションの手順書（分ける前の版）の検証の中で、この文書の手順 1・2 のブロックを、SSH でログインしたユーザーの `bash -i`（擬似端末）にそのまま書き込んだ。1 回目はブラケットペースト無し、2 回目はブラケットペーストで貼った（その記録は、今の [claude-code-gui.md の付録](claude-code-gui.md#付録-実機での検証記録2026-10-01)）。

| 手順 | 結果 |
|---|---|
| 1. 変数 | `USER = <USER>`、`IDLE_DELAY = 0`、`LOCK_ENABLED = false`、`POWER_BUTTON = interactive` |
| 2. 自分のセッション | `uint32 0`・`false`・`idle-dim false`・`power-button-action 'interactive'`・`sleep-inactive-ac-type 'nothing'`・`sleep-inactive-battery-type 'nothing'`（2 回とも） |

- **実施前**: dconf には前から `idle-delay` の `uint32 0` と `lock-enabled` の `false` があり、電源のキーは既定値だった
- **Homebrew の `gsettings`**: 直す前の手順 2 の形（`gsettings`）では、この PC の PATH で Homebrew の `gsettings` が動く。Homebrew の `gsettings get org.gnome.desktop.session idle-delay` は `uint32 300` を返し（dconf の値は `uint32 0`）、Homebrew の `gsettings set` の値は `~/.config/glib-2.0/settings/keyfile` に入った（手順 2 の補足）
- **動いているセッションに効くか**: ヘッドレスのセッションが動いている間に、SSH のシェルから `/usr/bin/gsettings set org.gnome.desktop.interface clock-show-seconds true` を実行すると、上部バーの時計にすぐ秒が出た（画面を撮って確かめた。`reset` で消えた）
- **放置によるサスペンド**: 手順 2 の前（`sleep-inactive-ac-type` が `'suspend'`）は、ヘッドレスのセッションを無操作で 15 分置くと、gsd-power が `Error calling suspend action: … SleepVerbNotSupported …` を出した（サスペンドしようとした。この Pi はサスペンドできない）
  - 手順 2 の後（`'nothing'`）は、同じヘッドレスのセッションを 16 分余り放置しても、`Error calling suspend action` も「Suspending soon」の通知も出ず、画面も消えなかった。SSH のシェルから変えた値が、動いているセッションに効いた

#### 未確認事項

- 実機での手順 3〜6 とロールバック
- 画面が消えない・暗くならないこと（モニターのある PC で）
- x86_64 の PC
