# Claude Code から GNOME の GUI を撮って操作する手順（ヘッドレスのセッション）のロールバックと注意点

[手順書](../claude-code-gui.md)・[検証記録](../verification/claude-code-gui.md)・[参考資料](../reference/claude-code-gui.md)

- 「手順 N」は[手順書](../claude-code-gui.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- この手順書で足したもの（ドロップイン）だけを戻す。ヘッドレスのセッションは、仮想モニターの無い形で動き続ける
- セッションも止めるなら、続けて [gnome-headless-session.md のロールバック](gnome-headless-session.md#ロールバック)
- ヘッドレスのセッションをやめてリモートログインだけにするなら、この節ではなく [gnome-headless-session.md の「リモートログインだけにする（併用をやめる）」](../gnome-headless-session.md#リモートログインだけにする併用をやめる)（この節の手順 2 はヘッドレスのセッションを起動し直すため）
- 手順 1 の変数は要らない。Claude Code が動くユーザーのシェルで、上から順に貼る

1. ドロップインを消す。

   ```bash
   rm ~/.config/systemd/user/org.gnome.Shell@wayland.service.d/virtual-monitor.conf
   printf '\n\033[7m 確認 \033[0m\n'
   rmdir ~/.config/systemd/user/org.gnome.Shell@wayland.service.d
   systemctl --user daemon-reload
   systemctl --user cat org.gnome.Shell@wayland.service | grep '^ExecStart'
   ```

   - `ExecStart=/usr/bin/gnome-shell` の 1 行が出ればよい
   - `rmdir` が `Directory not empty` で失敗したら、ほかのドロップインがあるので、そのまま残す

1. セッションを止め、終わるのを待って起動し直し、仮想モニターの無い形に戻ったかを確かめる。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。セッションを使うユーザーのシェルで貼り直す' >&2
   else
     sudo systemctl stop "gnome-headless-session@${USER}.service"
     for i in $(seq 1 30); do [ -z "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless"')" ] && break; sleep 1; done
     sleep 3
     sudo systemctl start "gnome-headless-session@${USER}.service"
     for i in $(seq 1 30); do busctl --user status org.gnome.Mutter.ScreenCast >/dev/null 2>&1 && break; sleep 1; done
     printf '\n\033[7m 確認 \033[0m\n'
     pgrep -a -u "${USER}" -x gnome-shell
   fi
   ```

   - `stop` と `start` は何も出さない。動いていたアプリは閉じる
   - `<PID> /usr/bin/gnome-shell`（`--virtual-monitor` の無い形）が出ればよい
   - `systemctl restart` は使わない（[手順 3](../claude-code-gui.md#実施手順) の補足）
   - 確かめ用の PNG が残っていれば `rm ~/gnome-gui-*.png` で消す

---

## 注意点

- **Homebrew が PATH の先頭にあると、GLib のコマンドが Homebrew のものになる**（[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)）
  - `python3` には `gi` が無い。`scripts/gnome-gui.py` は `#!/usr/bin/python3` で動く
  - `gsettings` は dconf ではなく `~/.config/glib-2.0/settings/keyfile` に書き、GNOME には効かないのに、読み戻すと変わったように見える。[AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順は `/usr/bin/gsettings` で書く
  - `gdbus` と `gio` も Homebrew のものになる。手で使うときは `/usr/bin/` を付ける
- **RDP でつないだ人には、Claude Code の画面は写らない**: [gnome-headless-session.md](../gnome-headless-session.md) の RDP でつなぐと、この手順書の仮想モニター（`Meta-0`）の右に、クライアントの大きさの別のモニター（`Virtual remote monitor`）が足され、クライアントにはそちらが写る
  - 上部バーは主のモニター（`Meta-0`）にしか出ないので、クライアントの画面には上部バーが無かった
    - 同じドロップインを置いた試験用のユーザーで、FreeRDP で同じように入ると、クライアントには壁紙だけが写った（上部バーもウィンドウも無い）
  - RDP だけで使うなら、[ロールバック](#ロールバック)でドロップインを外すと、クライアントの画面がデスクトップ全体になる
  - ヘッドレスのセッションもやめてリモートログインだけにするなら、[gnome-headless-session.md の「リモートログインだけにする（併用をやめる）」](../gnome-headless-session.md#リモートログインだけにする併用をやめる)でドロップインも外す
- **ドロップインは、このユーザーの GNOME のセッションすべてに効く**: 後からモニターをつないで、このユーザーで PC の画面からログインすると、見えない仮想モニターも足されるはず。そのときは[ロールバック](#ロールバック)で外す
- **ログインのキーリングは開いていない**: パスワードを読もうとするアプリは、キーリングを開く窓を出す。Claude Code には答えられない
- **手順 3 とロールバックの手順 2 は、ユーザーの D-Bus も起動し直す**: GNOME のセッションが終わると、`gnome-session-restart-dbus.service` がユーザーのセッションバスを起動し直す
- **起動し直すのは `restart` ではなく、`stop` → 待つ → `start`**: `restart` では新しいセッションができなかった（参考資料を参照）
