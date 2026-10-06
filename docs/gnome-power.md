# GNOME の画面オフ・画面ロック・自動サスペンドの設定手順（AlmaLinux 10）

## 実施手順

- [検証記録](verification/gnome-power.md)・[参考資料](reference/gnome-power.md)

> [!IMPORTANT]
> - **GNOME にログインするユーザー本人のシェルで実行する**。`sudo -i` / `su -` したシェルでは行わない（手順 2 の `gsettings` は、実行したユーザーの設定しか変えないため）

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- GNOME を入れていない（デスクトップの無い）機械では、手順 4・5 だけを行う
- 手順の後: 戻すときは[ロールバック](#ロールバック)

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
   - 値が変わっていなければ、デスクトップの端末で手順 1 から貼り直す（`gsettings` は書けなかったときも終了コード 0 で終わる。[検証記録](verification/gnome-power.md)・[参考資料](reference/gnome-power.md)）
   - **注意**: `/usr/bin/` を外さない

1. ログイン画面（GDM）用の設定を書き、dconf を作り直して、ログイン画面から見える値を確かめる。

   ```bash
   if [ -z "${POWER_BUTTON}" ]; then echo '中断: 手順 1 の POWER_BUTTON が空のまま。値を入れて貼り直す' >&2; else
     sudo tee /etc/dconf/db/gdm.d/90-power >/dev/null <<EOF
   [org/gnome/settings-daemon/plugins/power]
   sleep-inactive-ac-type='nothing'
   sleep-inactive-battery-type='nothing'
   power-button-action='${POWER_BUTTON:?手順 1 の POWER_BUTTON が空のまま。値を入れて貼り直す}'
   EOF
     sudo dconf update
     sudo -u gdm env DCONF_PROFILE=gdm /usr/bin/gsettings list-recursively org.gnome.settings-daemon.plugins.power | grep -E 'sleep-inactive-(ac|battery)-type|power-button-action'
   fi
   ```

   - ファイルには、自動サスペンドと電源ボタンの設定を書く
   - 文字列の値は引用符（`'`）で囲む。囲まないと、`dconf update` が失敗する
   - `dconf update` は、成功すると何も出さない。`invalid value` と出たら、この手順を貼り直す
   - `power-button-action 'interactive'`・`sleep-inactive-ac-type 'nothing'`・`sleep-inactive-battery-type 'nothing'` の 3 行が出ればよい
   - `中断:` と出たら、何も書いていない

1. OS 全体で、サスペンドとハイバネートを止める。

   ```bash
   {
     sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
     systemctl is-enabled sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
   }
   ```

   - `Created symlink '/etc/systemd/system/sleep.target' → '/dev/null'.` のような行が 5 つ出て、`masked` が 5 行出ればよい
   - GNOME のメニュー・蓋・電源ボタンなど、どこから頼まれてもサスペンドが始まらなくなる
   - **注意**: ノート PC は、蓋を閉じても電池が減っても眠らない。閉じたまま鞄に入れると熱を持つので、持ち歩くときは電源を切る

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

---

## ロールバック

- 上から順に貼る。手順 1 の変数は要らない
- 自分のセッションとログイン画面は、変える前の値ではなく**既定値**に戻る
  - Server with GUI で入れた PC は、既定でも電源につないでいる間は眠らない

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

1. ログイン画面用の設定ファイルを消し、dconf を作り直して、ログイン画面から見える値が戻ったか確かめる。

   ```bash
   {
     sudo rm -f /etc/dconf/db/gdm.d/90-power
     sudo dconf update
     sudo -u gdm env DCONF_PROFILE=gdm /usr/bin/gsettings list-recursively org.gnome.settings-daemon.plugins.power | grep -E 'sleep-inactive-(ac|battery)-type|power-button-action'
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

## 注意点

- **`gsettings` は、書けなかったときも終了コード 0 で終わる**: 手順 2 の読み戻しで確かめる
- **Homebrew の `gsettings` は GNOME に効かない**: dconf ではなくファイルに書き、読み戻しでは変わったように見える。この文書の `gsettings` は `/usr/bin/gsettings` で呼ぶ
  - `sudo -u gdm` の行（手順 3 と[ロールバック](#ロールバック)の手順 2）も `/usr/bin/gsettings` を明示する
    - [homebrew.md の sudo でも使う](homebrew.md#sudo-でも使う任意)の節を通しても、Homebrew は `secure_path` の末尾なので、`/bin/gsettings` が先に見つかる
- **dconf のファイルの型**: 文字列は `'nothing'` のように引用符で囲む。`idle-delay` のような uint32 は `uint32 0` と書く
  - 引用符が無いと `dconf update` が失敗し、データベースは前の内容のまま残る
  - `uint32` が無いと、エラーにならずに無視される
- **Server with GUI の設定も、同じ落とし穴を踏んでいる**: `gnome-settings-daemon-server-defaults` の override（`/usr/share/glib-2.0/schemas/org.gnome.settings-daemon.plugins.power.gschema.override`）は、次の 2 つを書いている
  - `sleep-inactive-ac-timeout=0` は効いていて、電源につないでいる間は眠らない
  - `power-button-action=nothing` は引用符が無いので、スキーマのコンパイルで読み飛ばされ、電源ボタンは既定の `'suspend'` のまま
- **自分で変えた値が優先される**: dconf は、自分の設定（`gsettings` と設定アプリが書く user-db）を、`/etc/dconf/db` のデータベースより先に読む
  - 手順 2 を `gsettings` で行い、`local.d` を使わなかったのはこのため
- **仮想マシンの中では**: gnome-settings-daemon は放置によるサスペンドをしない（gsd 47.2 のソースから）
  - 電源ボタンは `nothing` 以外だと電源オフになる（`power-button-action` のスキーマの説明から）
- **設定アプリで後から変えるとき**: 手順 4 の後は「自動サスペンド」の行が出ないので、戻すなら `gsettings` か[ロールバック](#ロールバック)で行う
