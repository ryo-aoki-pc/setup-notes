# Claude Code から GNOME の GUI を撮って操作する手順（ヘッドレスのセッション）の参考資料

[手順書](../claude-code-gui.md)・[ロールバックと注意点](../extra/claude-code-gui.md)

## 補足

### 実施手順 / 手順 1: 補足: 変数について

[この節の検証記録](../verification/claude-code-gui.md#実施手順--手順-1-補足-変数について)

- `VIRTUAL_MONITOR` は、手順 2 で gnome-shell に付ける `--virtual-monitor` の値。Claude Code が撮る画面の大きさになる
- 小さくすると、画面の写しの PNG も小さくなる。後から変えるときは[仮想モニターの大きさを変える（任意）](../claude-code-gui.md#仮想モニターの大きさを変える任意)
- `REPO` は、手順 4〜6 と[仮想モニターの大きさを変える（任意）](../claude-code-gui.md#仮想モニターの大きさを変える任意)で `${REPO}/scripts/gnome-gui.py` を呼ぶためだけに使う
- 変数はそのシェルの中だけで有効

### 実施手順 / 手順 2: 補足: 仮想モニターが要る理由

- ヘッドレスのセッションには、モニターが 1 枚も無い。撮る画面が無く、窓も置き場所が無い
- `--virtual-monitor` は gnome-shell 49（Mutter）の「消えない仮想モニターを足す」オプション。セッションの間ずっと `Meta-0` という名前のモニターがあり、主のモニターになる
  - 起動のログ: `No seat assigned, running headlessly` の後に `Added virtual monitor Meta-0`
- RDP（[gnome-headless-session.md](../gnome-headless-session.md) の `grdctl --headless`）でつないだときにも仮想モニターはできるが、つないでいる間だけ（[注意点](../extra/claude-code-gui.md#注意点)）
- `ExecStart=` の空の行は、元の `ExecStart` を消すため（systemd のドロップインの決まり）
- 置き場所は、ユーザーの systemd のドロップイン（`~/.config/systemd/user/<unit>.d/`）。`/usr/lib/systemd/user/org.gnome.Shell@wayland.service` は変えない

### 実施手順 / 手順 2: 補足: 効く範囲

- このユーザーの GNOME のセッションすべてに効く（[注意点](../extra/claude-code-gui.md#注意点)）
- 動いているセッションには、同じ節の手順 3 で起動し直したときに効く

### 実施手順 / 手順 3: 補足: restart を使わない理由

[この節の検証記録](../verification/claude-code-gui.md#実施手順--手順-3-補足-restart-を使わない理由)

- `sudo systemctl restart` は、前のセッションの片付けと次の `start` が重なるため使わない
- `stop` は `gdm-new-session` を止めるだけで、前のセッションの片付けは後から進む。`start` は、その片付けが終わってから行う
- `gdm-new-session` は終了コード 0 で終わるので、unit の `Restart=on-failure` も効かない
- 前のセッションが `loginctl` から消えた後、ユーザーの D-Bus が起動し直される（`gnome-session-restart-dbus.service`）。それが終わるまで 3 秒待ってから起動する

### 実施手順 / 手順 3: 補足: 待ち方と loginctl の行

- `for` の行は、gnome-shell のバス名と `loginctl` のセッションの両方が出るまで、30 秒まで待つ
- `loginctl` の行は、このユーザーのヘッドレスのセッションの行だけを出す（[gnome-headless-session.md 手順 2](../gnome-headless-session.md#実施手順) の補足）

### 実施手順 / 手順 4: 補足: 画面の撮り方

[この節の検証記録](../verification/claude-code-gui.md#実施手順--手順-4-補足-画面の撮り方)

- `gnome-gui.py shot` は、Mutter の `org.gnome.Mutter.ScreenCast` で主のモニターを録画するセッションを作り、PipeWire のストリームから GStreamer で 1 コマを PNG にして、セッションを止める
- 撮っている間は、上部バーの右に画面共有の表示（オレンジ）が出て、写しにも写る
- GNOME Shell の `org.gnome.Shell.Screenshot` は、GNOME 41 から決まった相手（と unsafe mode）にしか使わせないので、使わない（[選択した方針](#選択した方針)）
- スクリプトは `/usr/bin/python3` で動く。Homebrew の `python3` が PATH の先頭にあっても、そちらには `gi` が無い（[注意点](../extra/claude-code-gui.md#注意点)）

### 実施手順 / 手順 5: 補足: 電卓の起動を待つ

- `gnome-gui-org.gnome.Calculator-<PID>` は、起動した unit の名前
- 窓の一覧に電卓が出るまで待つ。固定の `sleep 3` だけで起動完了を判断しない
- 最初の `key Escape` は、セッションを始めた直後に開いているアクティビティ画面を閉じる

### 実施手順 / 手順 6: 補足: 座標とキーの間合い

- 座標は、主のモニターの左上を `0 0` にした画素の位置。`shot` の PNG の座標と同じ
- `70 15` は、上部バーの左端のアクティビティのボタン
- ポインタは `NotifyPointerMotionAbsolute` で動かし、`NotifyPointerButton` でクリックする
- `Escape` と `ctrl+q` の間の `sleep 1` は、アクティビティ画面が閉じる動きを待つため。続けて送った版では `ctrl+q` が捨てられ、電卓が残った

### 選択した方針

- **撮影と入力は Mutter の公式の D-Bus API にする**
  - GNOME Shell の `Screenshot` と `Eval` は、GNOME 41 から、決まった相手か unsafe mode にしか使わせない
  - unsafe mode は、同じユーザーのどのプロセスにも、画面の撮影と任意の JavaScript の実行を許す。この手順書は使わない（検証の途中で、Claude Code の auto mode の安全判定にも止められた）
  - Mutter の ScreenCast と RemoteDesktop は、gnome-remote-desktop や xdg-desktop-portal-gnome が使う口。使っている間は、上部バーに画面共有の表示が出る
- **仮想モニターを gnome-shell のオプションで付ける**: ヘッドレスのセッションには、RDP のクライアントがつないでいる間しかモニターが無い。常に 1 枚あれば、いつでも撮れ、窓の位置も変わらない
- **人が同じ画面を見るときは、Claude Code が撮った画面を送る**: RDP（gnome-headless-session.md）でつなぐと、Claude Code が見ている仮想モニターとは別のモニターが足され、同じ画面は写らなかった（[注意点](../extra/claude-code-gui.md#注意点)）
- **ヘッドレスのセッションの手順書から分けた**: もとはひとつの手順書だった。利用者の依頼で、セッションの動かし方と RDP でつなぐところを [gnome-headless-session.md](../gnome-headless-session.md) に残し、Claude Code にかかわるところをこの手順書にした

### 参照

- [mutter の data/dbus-interfaces/org.gnome.Mutter.ScreenCast.xml と org.gnome.Mutter.RemoteDesktop.xml](https://gitlab.gnome.org/GNOME/mutter/-/tree/main/data/dbus-interfaces)
- `gnome-shell --help`（`--virtual-monitor`）/ `man systemd.unit`（ドロップイン）

---
