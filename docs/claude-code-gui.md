# Claude Code から GNOME の GUI を撮って操作する手順（ヘッドレスのセッション）

## 実施手順

> [!IMPORTANT]
> - **Claude Code が動くユーザー本人のシェル（SSH でよい）で貼る**。`sudo -i` / `su -` したシェルでは貼らない
> - 前提は [gnome-headless-session.md 手順 1〜3](gnome-headless-session.md#実施手順)（ヘッドレスのセッションを動かすところまで。RDP の設定は要らない）と、[gnome-power.md 手順 1・2](gnome-power.md#実施手順)（ロックされると、画面の前にいない Claude Code には解けない）
> - **手順 3 は `sudo` のパスワードを聞かれることがある**。答えてから手順 4 を貼る
> - このリポジトリの [`scripts/gnome-gui.py`](../scripts/gnome-gui.py) を使う。clone した場所を手順 1 の `REPO` に入れる

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: Claude Code からの使い方は[使い方の基本](#使い方の基本)。仮想モニターの大きさを変えるなら[仮想モニターの大きさを変える（任意）](#仮想モニターの大きさを変える任意)。戻すときは[ロールバック](#ロールバック)

1. 変数を設定する。

   ```bash
   REPO=~/setup-notes                  # このリポジトリを clone した場所（scripts/gnome-gui.py を使う）。<REPO>
   VIRTUAL_MONITOR=1920x1080           # 仮想モニターの大きさ（幅x高さ）。<VIRTUAL_MONITOR>
   for v in USER REPO VIRTUAL_MONITOR; do
     printf '%-16s = %s\n' "$v" "${!v}"
   done
   ```

   - **編集が必須の変数は無い**。clone した場所が `~/setup-notes` なら、既定のままでよい
   - 最後に値を読み戻して確かめる
   - `USER` が `root` なら、ここで止めて、Claude Code が動くユーザーのシェルで貼り直す
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**、手順 1 のブロックを貼り直してから先へ進む

   <details>
   <summary>補足: 変数について</summary>

   - `VIRTUAL_MONITOR` は、手順 2 で gnome-shell に付ける `--virtual-monitor` の値。Claude Code が撮る画面の大きさになる
   - 小さくすると、画面の写しの PNG も小さくなる（1920x1080 で約 0.7 MB）。後から変えるときは[仮想モニターの大きさを変える（任意）](#仮想モニターの大きさを変える任意)
   - `REPO` は、手順 5〜7 と[仮想モニターの大きさを変える（任意）](#仮想モニターの大きさを変える任意)で `${REPO}/scripts/gnome-gui.py` を呼ぶためだけに使う

   </details>


1. gnome-shell に仮想モニターを付けるドロップインを置く。

   ```bash
   if [ -z "${VIRTUAL_MONITOR}" ]; then echo '中断: 手順 1 の VIRTUAL_MONITOR が空のまま。手順 1 を貼り直す' >&2; else
   mkdir -p ~/.config/systemd/user/org.gnome.Shell@wayland.service.d
   cat > ~/.config/systemd/user/org.gnome.Shell@wayland.service.d/virtual-monitor.conf <<EOF
   [Service]
   ExecStart=
   ExecStart=/usr/bin/gnome-shell --virtual-monitor ${VIRTUAL_MONITOR}
   EOF
   systemctl --user daemon-reload
   systemctl --user cat org.gnome.Shell@wayland.service | grep '^ExecStart'
   fi
   ```

   - `ExecStart=/usr/bin/gnome-shell`（元の行）・`ExecStart=`・`ExecStart=/usr/bin/gnome-shell --virtual-monitor <VIRTUAL_MONITOR>` の 3 行が出ればよい
   - このユーザーの GNOME のセッションすべてに効く（[注意点](#注意点)）
   - 動いているセッションには、手順 3 で起動し直したときに効く

   <details>
   <summary>補足: 仮想モニターが要る理由</summary>

   - ヘッドレスのセッションには、モニターが 1 枚も無い。撮る画面が無く、窓も置き場所が無い
   - `--virtual-monitor` は gnome-shell 49（Mutter）の「消えない仮想モニターを足す」オプション。セッションの間ずっと `Meta-0` という名前のモニターがあり、主のモニターになる
     - 起動のログ: `No seat assigned, running headlessly` の後に `Added virtual monitor Meta-0`
   - RDP（[gnome-headless-session.md](gnome-headless-session.md) の `grdctl --headless`）でつないだときにも仮想モニターはできるが、つないでいる間だけ（[注意点](#注意点)）
   - `ExecStart=` の空の行は、元の `ExecStart` を消すため（systemd のドロップインの決まり）
   - 置き場所は、ユーザーの systemd のドロップイン（`~/.config/systemd/user/<unit>.d/`）。`/usr/lib/systemd/user/org.gnome.Shell@wayland.service` は変えない

   </details>


1. セッションを止め、終わるのを待ってから起動し直す。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。セッションを使うユーザーのシェルで貼り直す' >&2
   else
     sudo systemctl stop "gnome-headless-session@${USER}.service"
     for i in $(seq 1 30); do [ -z "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless"')" ] && break; sleep 1; done
     sleep 3
     sudo systemctl start "gnome-headless-session@${USER}.service"
   fi
   ```

   - 何も出さずに終わる。動いていたアプリは閉じる
   - `systemctl restart` は使わない（この手順の補足）
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: restart を使わない理由</summary>

   - `sudo systemctl restart` で起動し直すと、新しいセッションができなかった。unit は `inactive (dead)` になり、セッションも消えた
   - `stop` は `gdm-new-session` を止めるだけで、前のセッションの片付けは後から進む。`start` がその途中に重なり、新しいセッションの gnome-session が `Transaction for gnome-session-wayland@gnome.target/start is destructive` で systemd の起動をあきらめ、GDM が `Session never registered, failing` で終わらせた
   - `gdm-new-session` は終了コード 0 で終わるので、unit の `Restart=on-failure` も効かない
   - 前のセッションが `loginctl` から消えた後、ユーザーの D-Bus が起動し直される（`gnome-session-restart-dbus.service`）。それが終わるまで 3 秒待ってから起動する

   </details>


1. 仮想モニターの付いたセッションができたかを確かめる。

   ```bash
   for i in $(seq 1 30); do busctl --user status org.gnome.Mutter.ScreenCast >/dev/null 2>&1 && break; sleep 1; done
   loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless"'
   pgrep -a -u "${USER}" -x gnome-shell
   ```

   - `<SESSION_ID> <UID> <USER> - <PID> user headless no -` の形の行と、`<PID> /usr/bin/gnome-shell --virtual-monitor <VIRTUAL_MONITOR>` が出ればよい
   - 最初の行は、gnome-shell が起動し終わるまで、30 秒まで待つ。2 行目は、このユーザーのヘッドレスのセッションの行だけを出す（[gnome-headless-session.md 手順 3](gnome-headless-session.md#実施手順) の補足）

1. 画面を撮って、大きさを確かめる。

   ```bash
   if [ -z "${REPO}" ]; then echo '中断: 手順 1 の REPO が空のまま。手順 1 を貼り直す' >&2; else
   "${REPO}/scripts/gnome-gui.py" shot ~/gnome-gui-test.png
   file ~/gnome-gui-test.png
   fi
   ```

   - PNG のパスと、`/home/<USER>/gnome-gui-test.png: PNG image data, <幅> x <高さ>, 8-bit/color RGBA, non-interlaced` の 2 行が出ればよい（大きさは `VIRTUAL_MONITOR`）
   - Claude Code は、この PNG を Read で開いて画面を見る。人が見るなら、scp などで手元に持ってきて開く
   - セッションを始めた直後の画面は、上に検索欄のあるアクティビティ画面（手順 6 の最初の `key Escape` で閉じる）

   <details>
   <summary>補足: 画面の撮り方</summary>

   - `gnome-gui.py shot` は、Mutter の `org.gnome.Mutter.ScreenCast` で主のモニターを録画するセッションを作り、PipeWire のストリームから GStreamer で 1 コマを PNG にして、セッションを止める。1 回 0.4 秒ほど
   - 撮っている間は、上部バーの右に画面共有の表示（オレンジ）が出て、写しにも写る
   - GNOME Shell の `org.gnome.Shell.Screenshot` は、GNOME 41 から決まった相手（と unsafe mode）にしか使わせないので、使わない（[選択した方針](#選択した方針)）
   - スクリプトは `/usr/bin/python3` で動く。Homebrew の `python3` が PATH の先頭にあっても、そちらには `gi` が無い（[注意点](#注意点)）

   </details>

1. 電卓を起動して、キーボードの入力が届くかを確かめる。

   ```bash
   if [ -z "${REPO}" ]; then echo '中断: 手順 1 の REPO が空のまま。手順 1 を貼り直す' >&2; else
   "${REPO}/scripts/gnome-gui.py" key Escape
   "${REPO}/scripts/gnome-gui.py" launch org.gnome.Calculator
   sleep 3
   "${REPO}/scripts/gnome-gui.py" windows
   "${REPO}/scripts/gnome-gui.py" type '12*34'
   "${REPO}/scripts/gnome-gui.py" key Return
   "${REPO}/scripts/gnome-gui.py" shot ~/gnome-gui-calc.png
   fi
   ```

   - `gnome-gui-org.gnome.Calculator-<PID>`（起動した unit の名前）、`gnome-calculator` と `Calculator` の行（間はタブ）、PNG のパスが出ればよい
   - `~/gnome-gui-calc.png` に、電卓の窓と `12×34 = 408` が写っていればよい
   - 最初の `key Escape` は、セッションを始めた直後に開いているアクティビティ画面を閉じる（この手順の補足）

   <details>
   <summary>補足: 入力の送り方と起動の仕方</summary>

   - `key` と `type` は、Mutter の `org.gnome.Mutter.RemoteDesktop` のセッションを作り、キーを押して離す（`NotifyKeyboardKeysym`）。送り終えたらセッションを止める
   - セッションを作った直後の入力と、止める直前の入力は、Mutter に捨てられることがあった（最初の数文字や最後の 1 文字が抜けた）。スクリプトは、害の無い入力を先に送り、前後に 0.3 秒ずつ置く
   - キー配列に無い文字（`é`・`日本語`・`←` など）は、エラーにならずに捨てられる。日本語は、IBus（[japanese-input.md](japanese-input.md)）でローマ字を打つ形になるはず（確かめていない）
   - `launch` は、`.desktop` の `Exec` を `systemd-run --user` の一時的なサービスとして動かす
     - `gio launch` を `systemd-run` で動かすと、`gio` が終わったときにサービスごとアプリが止められて、窓が出なかった
     - 実行ファイルは、ユーザーの systemd の `PATH`（GNOME Shell から起動したときと同じ）で探す
   - `windows` は AT-SPI（アクセシビリティ）で、アプリの名前と窓のタイトルを出す。GTK4 のアプリは、どの窓にフォーカスがあるかを出さなかった
   - アクティビティ画面が開いたまま起動した窓には、フォーカスが移らず、打った文字は検索欄に入る
   - `key Escape` を入れる前の版では、アクティビティ画面が開いたまま電卓を起動したので、電卓にフォーカスが移らなかった
     - `12*34` は検索欄に入り、`Return` で検索の結果（電卓の検索プロバイダー）が選ばれて、2 つ目の電卓（`gnome-calculator --equation 12*34`）が開いた
     - アクティビティ画面を閉じてから起動すると、電卓にフォーカスが移り、`408` が出た

   </details>

1. ポインタの入力が届くかを確かめて、電卓を閉じる。

   ```bash
   if [ -z "${REPO}" ]; then echo '中断: 手順 1 の REPO が空のまま。手順 1 を貼り直す' >&2; else
   "${REPO}/scripts/gnome-gui.py" click 70 15
   "${REPO}/scripts/gnome-gui.py" shot ~/gnome-gui-overview.png
   "${REPO}/scripts/gnome-gui.py" key Escape
   sleep 1
   "${REPO}/scripts/gnome-gui.py" key ctrl+q
   sleep 1
   "${REPO}/scripts/gnome-gui.py" windows
   fi
   ```

   - `~/gnome-gui-overview.png` が、アクティビティ画面（上に検索欄、真ん中に電卓の窓）になっていればよい
   - 最後の `windows` が何も出さなければ、電卓は閉じた
   - 確かめ用の PNG は、要らなければ `rm ~/gnome-gui-*.png` で消す

   <details>
   <summary>補足: 座標とキーの間合い</summary>

   - 座標は、主のモニターの左上を `0 0` にした画素の位置。`shot` の PNG の座標と同じ
   - `70 15` は、上部バーの左端のアクティビティのボタン
   - ポインタは `NotifyPointerMotionAbsolute` で動かし、`NotifyPointerButton` でクリックする
   - `Escape` と `ctrl+q` の間の `sleep 1` は、アクティビティ画面が閉じる動きを待つため。続けて送った版では `ctrl+q` が捨てられ、電卓が残った

   </details>

---

## 使い方の基本

Claude Code は、リポジトリの直下で `scripts/gnome-gui.py` を呼び、撮った PNG を Read で見て、次の操作を決める。

| コマンド | すること |
|---|---|
| `scripts/gnome-gui.py shot FILE.png [--no-cursor]` | 画面を PNG にする（既定ではポインタも写す） |
| `scripts/gnome-gui.py windows` | アプリの名前と窓のタイトルを出す |
| `scripts/gnome-gui.py launch DESKTOP_ID [ARG...]` | アプリを起動する（`/usr/share/applications` の `.desktop` の名前。例: `org.gnome.TextEditor`） |
| `scripts/gnome-gui.py key KEY...` | キーを押して離す（`Return`・`Escape`・`Tab`・`F1`・`ctrl+l`・`super` など。`+` でつなぐと同時押し。文字キーは小文字で書く。大文字は Shift も付く） |
| `scripts/gnome-gui.py type TEXT` | 文字を打つ（キー配列にある文字だけ。改行は `Return`） |
| `scripts/gnome-gui.py move X Y` | ポインタを動かす |
| `scripts/gnome-gui.py click X Y [left\|middle\|right] [--double]` | クリックする |
| `scripts/gnome-gui.py scroll X Y STEPS` | ホイールを回す（正で下、負で上） |

- 操作の後は `shot` で撮り直して、効いたかを確かめる
- アクティビティ画面が開いているとき（セッションを始めた直後も）に `launch` した窓には、フォーカスが移らず、`type` の文字は検索欄に入る。先に `key Escape` で閉じる
- 画面が動くキー（アクティビティ画面を閉じる `Escape`・開く `super` など）の後は、`sleep 1` を挟んでから次のキーを送る。動いている間に送ったキーは捨てられた
- `scroll` と `click` は、ポインタの下にあるものに効く。デスクトップの上で `scroll` すると、ワークスペースが切り替わった
- `windows` は、同じ窓を 2 行出すことがある（Text Editor で見た）
- 撮った PNG を利用者に見せるときは、リモートコントロールのチャットに送る
- アプリを閉じるのは、アプリのキー（`ctrl+q` など）か、`systemctl --user stop gnome-gui-<名前>-<PID>`（`launch` が出した unit の名前）

---


## 仮想モニターの大きさを変える（任意）

- 大きさの値は、手順 1 の `VIRTUAL_MONITOR` だけに置く（この節で別に設定しない）

> [!WARNING]
> **この節の手順 1 は、セッションを起動し直す**。動いているアプリは閉じ、保存していない内容は失われる。

1. [手順 1](#実施手順) の `VIRTUAL_MONITOR` を新しい大きさに書き換えて、[手順 1〜3](#実施手順) のブロックを貼り直す。

   - 手順 1 の読み戻しに新しい大きさが出て、手順 2 の最後の行が `ExecStart=/usr/bin/gnome-shell --virtual-monitor <VIRTUAL_MONITOR>`（新しい大きさ）になればよい
   - **次の手順は、[手順 3](#実施手順) が終わってから貼る**（手順 3 の `sudo` が、続けて貼った行を読んで捨てる）

1. 新しい大きさで撮れるかを確かめる。

   ```bash
   if [ -z "${REPO}" ]; then echo '中断: 手順 1 の REPO が空のまま。手順 1 を貼り直す' >&2; else
   for i in $(seq 1 30); do busctl --user status org.gnome.Mutter.ScreenCast >/dev/null 2>&1 && break; sleep 1; done
   "${REPO}/scripts/gnome-gui.py" shot ~/gnome-gui-test.png
   file ~/gnome-gui-test.png
   fi
   ```

   - `PNG image data, <幅> x <高さ>` が新しい大きさになっていればよい

---

## ロールバック

- この手順書で足したもの（ドロップイン）だけを戻す。ヘッドレスのセッションは、仮想モニターの無い形で動き続ける
- セッションも止めるなら、続けて [gnome-headless-session.md のロールバック](gnome-headless-session.md#ロールバック)
- 手順 1 の変数は要らない。Claude Code が動くユーザーのシェルで、上から順に貼る

1. ドロップインを消す。

   ```bash
   rm ~/.config/systemd/user/org.gnome.Shell@wayland.service.d/virtual-monitor.conf
   rmdir ~/.config/systemd/user/org.gnome.Shell@wayland.service.d
   systemctl --user daemon-reload
   systemctl --user cat org.gnome.Shell@wayland.service | grep '^ExecStart'
   ```

   - `ExecStart=/usr/bin/gnome-shell` の 1 行が出ればよい
   - `rmdir` が `Directory not empty` で失敗したら、ほかのドロップインがあるので、そのまま残す

1. セッションを止め、終わるのを待ってから起動し直す（仮想モニターの無い形に戻る）。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。セッションを使うユーザーのシェルで貼り直す' >&2
   else
     sudo systemctl stop "gnome-headless-session@${USER}.service"
     for i in $(seq 1 30); do [ -z "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless"')" ] && break; sleep 1; done
     sleep 3
     sudo systemctl start "gnome-headless-session@${USER}.service"
   fi
   ```

   - 何も出さずに終わる。動いていたアプリは閉じる
   - `systemctl restart` は使わない（[手順 3](#実施手順) の補足）
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

1. 仮想モニターの無いセッションに戻ったかを確かめる。

   ```bash
   for i in $(seq 1 30); do busctl --user status org.gnome.Mutter.ScreenCast >/dev/null 2>&1 && break; sleep 1; done
   pgrep -a -u "${USER}" -x gnome-shell
   ```

   - `<PID> /usr/bin/gnome-shell`（`--virtual-monitor` の無い形）が出ればよい
   - 確かめ用の PNG が残っていれば `rm ~/gnome-gui-*.png` で消す

---

## 補足

### 対象と検証環境

- **目的**: [gnome-headless-session.md](gnome-headless-session.md) で常駐させた GNOME のヘッドレスのセッションを、同じ PC の上で動く Claude Code（リモートコントロールで使うときも）が、画面を撮り、キーボードとポインタで操作して、GUI の動作を確かめられるようにする
- **方式**: gnome-shell に `--virtual-monitor` で仮想モニターを常に付け、Mutter の ScreenCast と RemoteDesktop の D-Bus で撮って操作する（[`scripts/gnome-gui.py`](../scripts/gnome-gui.py)）
- **状態**: **aarch64 の実機（Raspberry Pi 5）で本実行済み（2026-10-01）**
  - 通したもの: この文書のブロックを、SSH でログインしたユーザーの `bash -i`（擬似端末）にそのまま貼った
    - 書き換えたのは手順 1 の `REPO`（PR #68 の作業ツリーを指した。`scripts/gnome-gui.py` がまだ main に無いため）と、任意節で書き換える `VIRTUAL_MONITOR` だけ
    - 分ける前の版（ヘッドレスのセッションの起動と、ひとつの手順書だった）で 3 回通した（ブラケットペーストの無しと有り、レビューで直した後の版。[付録](#付録-実機での検証記録2026-10-01)）
    - 分けた後のこの版（ブラケットペースト無し）: [gnome-headless-session.md 手順 1〜3](gnome-headless-session.md#実施手順) の後に、実施手順 1〜7 → [ロールバック](#ロールバック) → 実施手順 1〜7 → [仮想モニターの大きさを変える（任意）](#仮想モニターの大きさを変える任意)で 1280x720 にして、1920x1080 に戻した。**この状態を残した**
  - 確認したこと
    - 仮想モニター（1920x1080 と 1280x720）の画面を撮れる
    - キーボードの入力（電卓で `12×34 = 408`）、ポインタのクリック・ダブルクリック・右クリック・スクロール、アプリの起動（ファイルを渡すときも）
    - SSH のシェルから `/usr/bin/gsettings` で変えた値が、動いているセッションにすぐ効く（上部バーの時計の秒）
    - 前提の gnome-power.md 手順 1・2 の後は、16 分余り放置しても、サスペンドしようとせず、ロックもされない
    - ロールバックで、ドロップインと仮想モニターが無くなり、ヘッドレスのセッションは動き続ける
    - ほかのユーザーのヘッドレスのセッションがあっても、手順 3・4 とロールバックが、このユーザーのセッションだけを見る
    - SELinux が Enforcing のまま、AVC は出なかった
  - 確認していないこと
    - 再起動の後の自動起動（この Pi では Claude Code と WireGuard・Samba・Syncthing が動いているので、再起動しなかった）
    - x86_64 の PC、モニターのある PC
    - IBus での日本語の入力、キーリングを開く窓が出たときの動き

| 項目 | 値 |
|---|---|
| 実施日 | 2026-10-01 |
| 機械 | Raspberry Pi 5 Model B（aarch64、メモリ 8 GB）。HDMI は 2 つとも `disconnected`（モニター無し） |
| OS | AlmaLinux 10.2 (Lavender Lion)、カーネル `6.12.96-20260724.v8.1.el10`、SELinux Enforcing |
| GNOME | `gdm-47.0-24.el10_2`、`gnome-shell-49.4-9.el10_2.alma.1`、`mutter-49.4-4.el10_2`、`gnome-session-46.0-11.el10`、`gnome-settings-daemon-47.2-10.el10_2.alma.1` |
| 撮影と入力 | `pipewire-gstreamer-1.4.11-1.el10_2.1`、`gstreamer1-1.26.7-5.el10`、`gstreamer1-plugins-base-1.26.7-2.el10_2.2`、`gstreamer1-plugins-good-1.26.7-2.el10_2.8`、`gtk4-4.16.7-4.el10`（キーの名前の変換）、`python3-gobject-3.46.0-7.el10`、`at-spi2-core-2.56.1-1.el10`、`python3-3.12.14-1.el10_2`（どれも Workstation の GNOME と一緒に入っていた） |
| そのほか | `sudo-1.9.17-10.p2.el10_2.6`（このユーザーは NOPASSWD）、`systemd-257-23.el10_2.2.alma.1`。リモートログイン（`gnome-remote-desktop-49.3-4.el10_2` のシステムのデーモン）が有効。PATH の先頭は Homebrew（`python3` 3.14.7、`glib` 2.90.0） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${REPO}` | このリポジトリを clone した場所 | `~/setup-notes` |
> | `${VIRTUAL_MONITOR}` | 仮想モニターの大きさ | `1920x1080` |
>
> 出力例・ログの中の値は `<USER>` / `<UID>` / `<SESSION_ID>` / `<PID>` / `<VIRTUAL_MONITOR>`（`<幅>` と `<高さ>`）/ `<REPO>` / `<名前>`（`.desktop` の名前）/ `<ノードの ID>`（PipeWire のノード）のプレースホルダで書いてある。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| ヘッドレスのセッション | [gnome-headless-session.md 手順 1〜3](gnome-headless-session.md#実施手順) の後。gnome-shell は `--virtual-monitor` 無しで動いている |
| ユーザーの systemd | `org.gnome.Shell@wayland.service` のドロップインは無い |
| dconf | 前提の gnome-power.md 手順 1・2 を済ませてあった |
| PATH | 先頭が Homebrew（`python3`・`gsettings`・`gdbus`・`gio` が Homebrew のもの） |

### 選択した方針

- **撮影と入力は Mutter の公式の D-Bus API にする**
  - GNOME Shell の `Screenshot` と `Eval` は、GNOME 41 から、決まった相手か unsafe mode にしか使わせない
  - unsafe mode は、同じユーザーのどのプロセスにも、画面の撮影と任意の JavaScript の実行を許す。この手順書は使わない（検証の途中で、Claude Code の auto mode の安全判定にも止められた）
  - Mutter の ScreenCast と RemoteDesktop は、gnome-remote-desktop や xdg-desktop-portal-gnome が使う口。使っている間は、上部バーに画面共有の表示が出る
- **仮想モニターを gnome-shell のオプションで付ける**: ヘッドレスのセッションには、RDP のクライアントがつないでいる間しかモニターが無い。常に 1 枚あれば、いつでも撮れ、窓の位置も変わらない
- **人が同じ画面を見るときは、Claude Code が撮った画面を送る**: RDP（gnome-headless-session.md）でつなぐと、Claude Code が見ている仮想モニターとは別のモニターが足され、同じ画面は写らなかった（[注意点](#注意点)）
- **ヘッドレスのセッションの手順書から分けた**: もとはひとつの手順書だった。利用者の依頼で、セッションの動かし方と RDP でつなぐところを [gnome-headless-session.md](gnome-headless-session.md) に残し、Claude Code にかかわるところをこの手順書にした

### 完了時点の状態

実施手順の後（分けた後のこの版）の出力:

```
$ loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless"'
<SESSION_ID> <UID> <USER> -     <PID> user          headless no  -
$ pgrep -a -u "${USER}" -x gnome-shell
<PID> /usr/bin/gnome-shell --virtual-monitor 1920x1080
$ cat ~/.config/systemd/user/org.gnome.Shell@wayland.service.d/virtual-monitor.conf
[Service]
ExecStart=
ExecStart=/usr/bin/gnome-shell --virtual-monitor 1920x1080
```

- 起動のログ（`journalctl -b _UID=<UID>`）: `No seat assigned, running headlessly`・`Added device '/dev/dri/renderD128' (v3d) using no mode setting.`・`Added virtual monitor Meta-0`
- `org.gnome.Mutter.DisplayConfig` の `GetCurrentState` では、`Meta-0`（`MetaVirtualMonitor`、`1920x1080@60.000`）が 1 枚だけで、主のモニター

### 注意点

- **Homebrew が PATH の先頭にあると、GLib のコマンドが Homebrew のものになる**（[homebrew.md の注意点](homebrew.md#注意点)）
  - `python3` には `gi` が無い。`scripts/gnome-gui.py` は `#!/usr/bin/python3` で動く
  - `gsettings` は dconf ではなく `~/.config/glib-2.0/settings/keyfile` に書き、GNOME には効かないのに、読み戻すと変わったように見える。[gnome-power.md](gnome-power.md) の手順は `/usr/bin/gsettings` で書く
  - `gdbus` と `gio` も Homebrew のものになる。手で使うときは `/usr/bin/` を付ける
- **RDP でつないだ人には、Claude Code の画面は写らない**: [gnome-headless-session.md](gnome-headless-session.md) の RDP でつなぐと、この手順書の仮想モニター（`Meta-0`）の右に、クライアントの大きさの別のモニター（`Virtual remote monitor`）が足され、クライアントにはそちらが写る
  - 上部バーは主のモニター（`Meta-0`）にしか出ないので、クライアントの画面には上部バーが無かった
  - RDP だけで使うなら、[ロールバック](#ロールバック)でドロップインを外すと、クライアントの画面がデスクトップ全体になる
- **ドロップインは、このユーザーの GNOME のセッションすべてに効く**: 後からモニターをつないで、このユーザーで PC の画面からログインすると、見えない仮想モニターも足されるはず（確かめていない）。そのときは[ロールバック](#ロールバック)で外す
- **ログインのキーリングは開いていない**: パスワードを読もうとするアプリは、キーリングを開く窓を出す。Claude Code には答えられない（`Escape` で閉じられるかは確かめていない）
- **手順 3 とロールバックの手順 2 は、ユーザーの D-Bus も起動し直す**: GNOME のセッションが終わると、`gnome-session-restart-dbus.service` がユーザーのセッションバスを起動し直す
- **起動し直すのは `restart` ではなく、`stop` → 待つ → `start`**: `restart` では新しいセッションができなかった（手順 3 の補足）

### 参照

- [mutter の data/dbus-interfaces/org.gnome.Mutter.ScreenCast.xml と org.gnome.Mutter.RemoteDesktop.xml](https://gitlab.gnome.org/GNOME/mutter/-/tree/main/data/dbus-interfaces)
- `gnome-shell --help`（`--virtual-monitor`）/ `man systemd.unit`（ドロップイン）

---

### 付録: 実機での検証記録（2026-10-01）

**分けた後のこの版の検証**（ブラケットペースト無し。[gnome-headless-session.md](gnome-headless-session.md) の検証のすぐ後に、ほかのユーザーのヘッドレスのセッションがある状態で）:

| 手順 | 結果 |
|---|---|
| 前提 | gnome-headless-session.md 手順 1〜3（`<PID> /usr/bin/gnome-shell`） |
| 1・2 | 読み戻しと、`ExecStart` の 3 行（最後が `--virtual-monitor 1920x1080`） |
| 3・4 | 何も出さずに終わり、このユーザーの `headless` の 1 行と `<PID> /usr/bin/gnome-shell --virtual-monitor 1920x1080` |
| 5〜7 | `PNG image data, 1920 x 1080`、電卓の unit の名前と窓、`12×34 = 408`、最後の `windows` は何も出さなかった |
| ロールバック | `ExecStart=/usr/bin/gnome-shell` の 1 行、何も出さずに起動し直し、`<PID> /usr/bin/gnome-shell` |
| もう一度 1〜7 | 同じ |
| 任意節 | 手順 1 の値を書き換えて手順 1〜3 を貼り直し、`1280 x 720`。戻して `1920 x 1080` |

以下は、分ける前の版（ヘッドレスのセッションの起動と、ひとつの手順書だった）の記録。手順の番号はその版のもので、手順 3 がセッションの有効化（今の gnome-headless-session.md 手順 2）、ロールバックがセッションの停止を含んでいた。

**環境**: [対象と検証環境](#対象と検証環境)の表の Raspberry Pi 5。検証した Claude Code も、この Pi の上（tmux の中の `claude remote-control`）で動かした。

**手順書を書く前に、手で確かめたこと**:

- モニター: `/sys/class/drm/card1-HDMI-A-1/status` と `HDMI-A-2` はどちらも `disconnected`。PC の画面を写すデスクトップ共有（PR #68 の最初の版）は、写す画面が無いので使えない
- ヘッドレスのセッション: `sudo systemctl start gnome-headless-session@<USER>.service` の 3 秒後に gnome-shell が動いた。ドロップインが無いと、モニターは 0 枚
- 画面の撮影
  - GNOME Shell の unsafe mode（`--unsafe-mode`）で `Screenshot` と `Eval` を使う案は、ドロップインを書くところで Claude Code の auto mode の安全判定に止められた。利用者と相談して、Mutter の API にした
  - `pipewiresrc target-object=<ノードの ID>` は `target not found` で失敗し、`path=<ノードの ID>` で撮れた（1920x1080 の PNG が 0.3〜0.4 秒）
- 入力
  - RemoteDesktop のセッションを作った直後に送ったキーは、数文字から 8 文字ほど捨てられた（`Hello` の `Hell` が抜けた）。0.5 秒待ってからでも、最初の 2 つが抜けた
  - `Shift_L` を押して離してから 0.1〜0.3 秒待つと、抜けなかった
  - セッションを止める直前のキーも抜けた（`ABCDEF` の `F`）。止める前に 0.3 秒置くと抜けなかった
  - キー配列（us）に無い文字（`é`・`ü`・`ß`・`日本語`・`←`）は、エラーにならずに捨てられた。間の空白は入った
  - スクリプトにした後は、`type` を 3 回続けて、どれも全部の文字が入った
- アプリの起動: `systemd-run --user -- gio launch …` では窓が出なかった（`gio` が終わると unit ごと止められた）。`systemd-run` は `gio` をこのシェルの PATH で探し、Homebrew の `gio` を動かしていた
- Homebrew: `python3`（3.14.7）には `gi` が無く、`gsettings`（glib 2.90.0）は keyfile のバックエンドだった（[gnome-power.md 手順 2 の補足](gnome-power.md#実施手順)）
- AT-SPI: 窓の一覧は取れた。GTK4 のアプリの窓は、フォーカスがあっても `active` の状態を出さなかった
- gsd-power: 電源のキーが既定のまま（`sleep-inactive-ac-type` が `'suspend'`）だと、無操作が続いて「Automatic suspend — Suspending soon because of inactivity.」の通知が出た
  - 15 分（900 秒）で `gsd-power: Error calling suspend action: GDBus.Error:org.freedesktop.login1.SleepVerbNotSupported: Sleep verb 'suspend' is not configured or configuration is not supported by kernel` が出た
  - この Pi はサスペンドできない（logind の `CanSuspend` が `na`）。サスペンドできる PC では、眠ったはず
- ロック: この Pi は前から `idle-delay` が `0`・`lock-enabled` が `false` で、15 分を超えて放置してもロックされなかった
- ヘッドレスの RDP（`grdctl --headless`）
  - 設定は dconf の `/org/gnome/desktop/remote-desktop/rdp/headless/`（`port`・`negotiate-port`・`enable`）と、デスクトップ共有と共有の `/org/gnome/desktop/remote-desktop/rdp/`（`tls-cert`・`tls-key`）に入った
  - 資格情報は `~/.local/share/gnome-remote-desktop/credentials.ini`（TPM が無いので GKeyFile）。`grdctl --headless status` を 1 度実行しただけで空の 0644 のファイルができ、資格情報を書いた後は 0600 になった
  - `grdctl --headless rdp enable` は `gnome-remote-desktop-headless.service` を enable して起動した（RHEL の文書の `systemctl --user enable --now` は要らなかった）
  - この Pi の上のコンテナの FreeRDP（3.10.3）でつなぐと、`Meta-1`（`Virtual remote monitor`、1280x720）が `Meta-0` の右（`1920,0`）に足され、FreeRDP には何も無い画面が写った。`screen-share-mode` を `'mirror-primary'` と明示しても同じだった
  - 確かめた後は、`grdctl --headless rdp disable`・`clear-credentials`・`dconf reset -f /org/gnome/desktop/remote-desktop/`・証明書と `credentials.ini` の削除で戻した
- そのほかのログ（害は見えなかった）
  - リモートログインが有効なので、セッションの中で `gnome-remote-desktop-handover.service` が起動した（TCP では待ち受けない）
  - seat が無いので `/dev/dri/card1`（vc4）を開けず、`MESA: error: Opening /dev/dri/card1 failed: Permission denied` が出た
  - GTK4 のアプリ（電卓など）は `VK_ERROR_OUT_OF_DEVICE_MEMORY`（`vkCreateSwapchainKHR()`）を出したが、窓は描かれた
  - Xwayland が起動するときに、xkbcomp の警告（`Unsupported maximum keycode 708` など）が出た

**流し方**:

- この文書と gnome-power.md の bash のブロックを Python のスクリプトで抜き出し、擬似端末で動かした `bash -i` に書き込んだ（ユーザーの `~/.bashrc` を読むので、PATH の先頭は Homebrew）
  - 1 回目は `bind 'set enable-bracketed-paste off'` の後に、ブロックの中身をそのまま書き込んだ（ブラケットペースト無し）
  - 2 回目は `on` にして、ブロックを `ESC[200~` と `ESC[201~` で囲んで書き込んだ
- ブロックの後に、終わりの目印の行（`printf`）を書き込んだ
  - 最初は、`sudo` で終わる手順 3（今の gnome-headless-session.md 手順 2）の直後にその行を続けて書き込み、`sudo` に読まれて捨てられた（NOPASSWD で、パスワードは聞かれなかった。[samba-client.md の付録](samba-client.md#付録-sudo-の後ろの行が失われる条件2026-09-28)と同じ）
  - 以後は、プロンプトに戻ってから書き込んだ
- 画面は、ブロックが作った PNG を Read で見た

| 手順 | 1 回目（ブラケットペースト無し） | 2 回目（ブラケットペースト） | 3 回目（レビューで直した後。ブラケットペースト無し） |
|---|---|---|---|
| gnome-power.md 1・2 | `uint32 0`・`false` と 4 行（`idle-dim false` など） | 同じ | —（流していない） |
| 1 | 3 つの値を読み戻した（`REPO` は作業ツリー） | 同じ | 同じ |
| 2 | `ExecStart` の 3 行（最後が `--virtual-monitor 1920x1080`） | 同じ | 同じ |
| 3（今の gnome-headless-session.md 手順 2） | `Created symlink …`（手順 4 から後は、新しいシェルで手順 1 を貼り直して続けた） | `Created symlink …` | `Created symlink …` |
| 4 | `<SESSION_ID> <UID> <USER> - … user headless no -` と `/usr/bin/gnome-shell --virtual-monitor 1920x1080` | 同じ | 同じ |
| 5 | `PNG image data, 1920 x 1080` | 同じ | 同じ |
| 6 | 直す前の版: 電卓にフォーカスが移らず、2 つ目の電卓が開いた（手順 6 の補足）。直した版（任意節の後）: `12×34 = 408` | `12×34 = 408` | `12×34 = 408` |
| 7 | 直す前の版: `ctrl+q` が捨てられ、電卓が残った。直した版: 最後の `windows` が何も出さなかった | 同じ（直した版） | 同じ |
| 任意節 | 直す前の版（`restart`、変数をこの節で設定する形）: セッションが消えた（今のこの文書の手順 3 の補足）。直した版: `PNG image data, 1280 x 720` | — | 手順 1 の値を書き換える形で、`1280 x 720`、戻して `1920 x 1080` |
| ロールバック（今の gnome-headless-session.md のロールバックの手順 5・6 と、この文書のロールバックの手順 1） | `Removed …`、`ExecStart=/usr/bin/gnome-shell` と `0`。`~/.config/systemd/user` は実施前と同じ | — | 同じ（セッションの終わりを待つ行を足した版） |

- SELinux の AVC は、`ausearch -m AVC,USER_AVC -ts today` で、起動時（手順より前）の 5 件だけだった

**追加の確認**（手順書の外。2 回目の後のセッションで）:

- `launch org.gnome.TextEditor /usr/share/doc/bash/README` でファイルが開いた。`windows` は同じ窓を 2 行出した
- 本文の単語の上の `click … --double` で単語が選ばれ、本文の上の `scroll … 5` で本文が下へ動いた
- デスクトップの上の `scroll` はワークスペースを切り替え、デスクトップの上の `click … right` はデスクトップのメニュー（Change Background… など）を開いた
- `/usr/bin/gsettings set org.gnome.desktop.interface clock-show-seconds true` で、上部バーの時計に秒が出た（`03:39:02`）。`reset` で消えた
- 2 回目の後に 16 分余り放置した。gsd-power はサスペンドしようとせず（ジャーナルに `Error calling suspend action` も「Suspending soon」の通知も無い）、画面は消えず、ロックもされなかった（`LockedHint=no`）

#### 未確認事項

- 再起動の後に、ヘッドレスのセッションが自動で起動すること
- x86_64 の PC と、モニターのある PC
- サスペンドできる PC で、ログイン画面（seat0 の GDM）が PC を眠らせないこと（gnome-power.md 手順 3〜5）
- 同じユーザーでリモートログインやローカルのログインをしたときの動き（ヘッドレスのセッションと重なったとき）
- キーリングを開く窓が出たときの動き（`Escape` で閉じられるか）
- IBus での日本語の入力

