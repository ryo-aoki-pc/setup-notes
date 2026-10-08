# Claude Code から GNOME の GUI を撮って操作する手順（ヘッドレスのセッション）の検証記録

[手順書](../claude-code-gui.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順 / 手順 5: 補足: 入力の送り方と起動の仕方

- `key` と `type` は、Mutter の `org.gnome.Mutter.RemoteDesktop` のセッションを作り、キーを押して離す（`NotifyKeyboardKeysym`）。送り終えたらセッションを止める
- セッションを作った直後の入力と、止める直前の入力は、Mutter に捨てられることがあった（最初の数文字や最後の 1 文字が抜けた）。スクリプトは、害の無い入力を先に送り、前後に 0.3 秒ずつ置く
- キー配列に無い文字（`é`・`日本語`・`←` など）は、エラーにならずに捨てられる。IBus の Anthy ではこの keysym の経路でローマ字が本文に入らなかった。別の検証用プローブの keycode の経路では「日本語」が確定した（[japanese-input.md の VM の付録](almalinux-setup.md#日本語入力-付録-クリーンインストールした-vm-での検証2026-10-06)）
- `launch` は、`.desktop` の `Exec` を `systemd-run --user` の一時的なサービスとして動かす
  - `gio launch` を `systemd-run` で動かすと、`gio` が終わったときにサービスごとアプリが止められて、窓が出なかった
  - 実行ファイルは、ユーザーの systemd の `PATH`（GNOME Shell から起動したときと同じ）で探す
- `windows` は AT-SPI（アクセシビリティ）で、アプリの名前と窓のタイトルを出す。GTK4 のアプリは、どの窓にフォーカスがあるかを出さなかった
- アクティビティ画面が開いたまま起動した窓には、フォーカスが移らず、打った文字は検索欄に入る
- `key Escape` を入れる前の版では、アクティビティ画面が開いたまま電卓を起動したので、電卓にフォーカスが移らなかった
  - `12*34` は検索欄に入り、`Return` で検索の結果（電卓の検索プロバイダー）が選ばれて、2 つ目の電卓（`gnome-calculator --equation 12*34`）が開いた
  - アクティビティ画面を閉じてから起動すると、電卓にフォーカスが移り、`408` が出た

### 対象と検証環境

- **目的**: [gnome-headless-session.md](../gnome-headless-session.md) で常駐させた GNOME のヘッドレスのセッションを、同じ PC の上で動く Claude Code（リモートコントロールで使うときも）が、画面を撮り、キーボードとポインタで操作して、GUI の動作を確かめられるようにする
- **方式**: gnome-shell に `--virtual-monitor` で仮想モニターを常に付け、Mutter の ScreenCast と RemoteDesktop の D-Bus で撮って操作する（[`scripts/gnome-gui.py`](../../scripts/gnome-gui.py)）
- **状態**: **aarch64 の実機（Raspberry Pi 5）で本実行済み（2026-10-01）。クリーンインストールした x86_64 の VM でも実施手順 1〜6・1280x720 への変更・ロールバックを本実行し、1920x1080 へ戻して再起動後の自動起動と撮影・入力を確認した（2026-10-06）**
  - 2026-10-06: 別の新規 VM で現行手順を再検証した。今回の実施・解除・未実施範囲は[新しい付録](#付録-現行版の新規-vm-での再検証2026-10-06)に記録した
  - 2026-10-06: クリーンな x86_64 の VM でも現行の実施手順 1〜6、1280x720 への変更、ロールバックを本実行した（末尾の付録）。初回案内と電卓の起動待ちを実測に合わせて修正した
  - 通したもの: この文書のブロックを、SSH でログインしたユーザーの `bash -i`（擬似端末）にそのまま貼った
    - 書き換えたのは手順 1 の `REPO`（PR #68 の作業ツリーを指した。`scripts/gnome-gui.py` がまだ main に無いため）と、任意節で書き換える `VIRTUAL_MONITOR` だけ
    - 分ける前の版（ヘッドレスのセッションの起動と、ひとつの手順書だった）で 3 回通した（ブラケットペーストの無しと有り、レビューで直した後の版。[付録](#付録-実機での検証記録2026-10-01)）
    - 分けた後のこの版（ブラケットペースト無し）: [gnome-headless-session.md 手順 1・2](../gnome-headless-session.md#実施手順) の後に、実施手順 1〜6 → [ロールバック](../claude-code-gui.md#ロールバック) → 実施手順 1〜6 → [仮想モニターの大きさを変える（任意）](../claude-code-gui.md#仮想モニターの大きさを変える任意)で 1280x720 にして、1920x1080 に戻した。**この状態を残した**
  - 確認したこと
    - 仮想モニター（1920x1080 と 1280x720）の画面を撮れる
    - キーボードの入力（電卓で `12×34 = 408`）、ポインタのクリック・ダブルクリック・右クリック・スクロール、アプリの起動（ファイルを渡すときも）
    - SSH のシェルから `/usr/bin/gsettings` で変えた値が、動いているセッションにすぐ効く（上部バーの時計の秒）
    - 前提の gnome-power.md 手順 1・2 の後は、16 分余り放置しても、サスペンドしようとせず、ロックもされない
    - ロールバックで、ドロップインと仮想モニターが無くなり、ヘッドレスのセッションは動き続ける
    - ほかのユーザーのヘッドレスのセッションがあっても、手順 3 とロールバックが、このユーザーのセッションだけを見る
    - SELinux が Enforcing のまま、AVC は出なかった
    - 2026-10-02: Windows 11 のリモートログインから同じユーザーで入ると、既存のヘッドレスのセッションへ引き渡される（[注意点](../claude-code-gui.md#注意点)）
  - 確認していないこと
    - 再起動の後の自動起動（この Pi では Claude Code と WireGuard・Samba・Syncthing が動いているので、再起動しなかった）
    - x86_64 の PC、モニターのある PC
    - IBus での日本語の入力、キーリングを開く窓が出たときの動き
    - 同じユーザーでローカルの画面にも同時にログインしたときの動き（付録の未確認事項のうち、リモートログイン側は上の 2026-10-02 に確認済み）
  - 2026-10-02: もとの手順 3・4 と、[ロールバック](../claude-code-gui.md#ロールバック)のもとの手順 2・3 をつなぎ、確かめの行を `if … fi` の `else` に入れた（つないだ形は貼っていない。`bash -n` だけ）

| 項目 | 値 |
|---|---|
| 実施日 | 2026-10-01 |
| 機械 | Raspberry Pi 5 Model B（aarch64、メモリ 8 GB）。HDMI は 2 つとも `disconnected`（モニター無し） |
| OS | AlmaLinux 10.2 (Lavender Lion)、カーネル `6.12.96-20260724.v8.1.el10`、SELinux Enforcing |
| GNOME | `gdm-47.0-24.el10_2`、`gnome-shell-49.4-9.el10_2.alma.1`、`mutter-49.4-4.el10_2`、`gnome-session-46.0-11.el10`、`gnome-settings-daemon-47.2-10.el10_2.alma.1` |
| 撮影と入力 | `pipewire-gstreamer-1.4.11-1.el10_2.1`、`gstreamer1-1.26.7-5.el10`、`gstreamer1-plugins-base-1.26.7-2.el10_2.2`、`gstreamer1-plugins-good-1.26.7-2.el10_2.8`、`gtk4-4.16.7-4.el10`（キーの名前の変換）、`python3-gobject-3.46.0-7.el10`、`at-spi2-core-2.56.1-1.el10`、`python3-3.12.14-1.el10_2`（どれも Workstation の GNOME と一緒に入っていた） |
| そのほか | `sudo-1.9.17-10.p2.el10_2.6`（このユーザーは NOPASSWD）、`systemd-257-23.el10_2.2.alma.1`。リモートログイン（`gnome-remote-desktop-49.3-4.el10_2` のシステムのデーモン）が有効。PATH の先頭は Homebrew（`python3` 3.14.7、`glib` 2.90.0） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../claude-code-gui.md#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
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
| ヘッドレスのセッション | [gnome-headless-session.md 手順 1・2](../gnome-headless-session.md#実施手順) の後。gnome-shell は `--virtual-monitor` 無しで動いている |
| ユーザーの systemd | `org.gnome.Shell@wayland.service` のドロップインは無い |
| dconf | 前提の gnome-power.md 手順 1・2 を済ませてあった |
| PATH | 先頭が Homebrew（`python3`・`gsettings`・`gdbus`・`gio` が Homebrew のもの） |

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

### 注意点 / 手順 0: 本文中の記録

  - リモートログイン（[gnome-remote-desktop.md](../gnome-remote-desktop.md)）のログイン画面からこのユーザーで入ったときも、このセッションに引き渡され、gnome-shell のログに `Added virtual monitor Meta-1` が出た（2026-10-02、Windows 11 の「リモートデスクトップ接続」）

### 注意点 / 手順 0: 本文中の記録

- **GDM を再起動すると、このセッションが消えることがある**: 2026-10-02 に GDM を再起動したとき、このセッションは起動し直されたが 1 秒で終わった（[gnome-headless-session.md の注意点](../gnome-headless-session.md#注意点)）。`sudo systemctl start gnome-headless-session@<USER>.service` で起動すると、ドロップインの `Meta-0` も戻った

### 付録: 実機での検証記録（2026-10-01）

**分けた後のこの版の検証**（ブラケットペースト無し。[gnome-headless-session.md](../gnome-headless-session.md) の検証のすぐ後に、ほかのユーザーのヘッドレスのセッションがある状態で）:

| 手順 | 結果 |
|---|---|
| 前提 | gnome-headless-session.md 手順 1・2（`<PID> /usr/bin/gnome-shell`） |
| 1・2 | 読み戻しと、`ExecStart` の 3 行（最後が `--virtual-monitor 1920x1080`） |
| 3 | `stop` と `start` は何も出さずに終わり、このユーザーの `headless` の 1 行と `<PID> /usr/bin/gnome-shell --virtual-monitor 1920x1080` |
| 4〜6 | `PNG image data, 1920 x 1080`、電卓の unit の名前と窓、`12×34 = 408`、最後の `windows` は何も出さなかった |
| ロールバック | `ExecStart=/usr/bin/gnome-shell` の 1 行、何も出さずに起動し直し、`<PID> /usr/bin/gnome-shell` |
| もう一度 1〜6 | 同じ |
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
- Homebrew: `python3`（3.14.7）には `gi` が無く、`gsettings`（glib 2.90.0）は keyfile のバックエンドだった（[gnome-power.md 手順 2 の補足](almalinux-setup.md#画面オフロックサスペンド-実施手順--手順-2-補足-変える前の値0-にしても暗くなる理由設定アプリの項目)）
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
| 6 | 直す前の版: 電卓にフォーカスが移らず、2 つ目の電卓が開いた（今の手順 5 の補足）。直した版（任意節の後）: `12×34 = 408` | `12×34 = 408` | `12×34 = 408` |
| 7 | 直す前の版: `ctrl+q` が捨てられ、電卓が残った。直した版: 最後の `windows` が何も出さなかった | 同じ（直した版） | 同じ |
| 任意節 | 直す前の版（`restart`、変数をこの節で設定する形）: セッションが消えた（今のこの文書の手順 3 の補足）。直した版: `PNG image data, 1280 x 720` | — | 手順 1 の値を書き換える形で、`1280 x 720`、戻して `1920 x 1080` |
| ロールバック（今の gnome-headless-session.md のロールバックの手順 5 と、この文書のロールバックの手順 1） | `Removed …`、`ExecStart=/usr/bin/gnome-shell` と `0`。`~/.config/systemd/user` は実施前と同じ | — | 同じ（セッションの終わりを待つ行を足した版） |

- SELinux の AVC は、`ausearch -m AVC,USER_AVC -ts today` で、起動時（手順より前）の 5 件だけだった

**追加の確認**（手順書の外。2 回目の後のセッションで）:

- `launch org.gnome.TextEditor /usr/share/doc/bash/README` でファイルが開いた。`windows` は同じ窓を 2 行出した
- 本文の単語の上の `click … --double` で単語が選ばれ、本文の上の `scroll … 5` で本文が下へ動いた
- デスクトップの上の `scroll` はワークスペースを切り替え、デスクトップの上の `click … right` はデスクトップのメニュー（Change Background… など）を開いた
- `/usr/bin/gsettings set org.gnome.desktop.interface clock-show-seconds true` で、上部バーの時計に秒が出た（`03:39:02`）。`reset` で消えた
- 2 回目の後に 16 分余り放置した。gsd-power はサスペンドしようとせず（ジャーナルに `Error calling suspend action` も「Suspending soon」の通知も無い）、画面は消えず、ロックもされなかった（`LockedHint=no`）

#### 未確認事項

- 2026-10-01 の実機では、再起動の後にヘッドレスのセッションが自動で起動することは未確認。2026-10-06 の x86_64 の VM では確認した（末尾の付録）
- x86_64 の PC と、モニターのある PC
- サスペンドできる PC で、ログイン画面（seat0 の GDM）が PC を眠らせないこと（gnome-power.md 手順 3・4）
- 同じユーザーでリモートログインやローカルのログインをしたときの動き（ヘッドレスのセッションと重なったとき）
- キーリングを開く窓が出たときの動き（`Escape` で閉じられるか）
- IBus での日本語の入力

### 付録: クリーンインストールした VM での検証（2026-10-06）

AlmaLinux 10.2 Workstation を ISO から新規に入れた VirtualBox の VM（x86_64、1 vCPU、メモリ 6 GiB、SELinux Enforcing、日本語 UI、US 配列）で、検証用ユーザーの SSH PTY に現行のブロックを個別に貼った。利用者のアカウントは使っていない。

実施手順 1〜6 を、初回に見つけた待ち時間の不足を直して通した。GNOME のバス名と loginctl のセッションの両方を待つ手順 3 は、headless の行と `--virtual-monitor 1920x1080` を返した。電卓の窓を待つ手順 5 は、実画面に `12×34 = 408` が出た。手順 6 のクリックは Activities を開き、Escape と Ctrl+Q で電卓が閉じ、窓の一覧は空になった。1280x720 への変更も PNG の実寸で確認した。

最初のセッションには「AlmaLinux へようこそ」の案内が重なり、閉じても Activities が残った。また初回の電卓は 1 vCPU で約 18 秒かかった。旧手順の固定 `sleep 3` では窓が間に合わず、入力が Activities の検索へ入った。案内と Activities を画面で確かめ、窓の一覧を待つ形へ直して再検証した。IBus の keysym と keycode の違いは japanese-input.md の今回の付録に記録した。

ロールバック 1・2 はドロップインを消し、`gnome-shell` が `--virtual-monitor` 無しになった。DisplayConfig の物理・論理モニターはともに 0、headless のセッションは動き続け、RDP の標準構成の検証へ進んだ。

RDP の標準構成の試験とロールバックを終えた後、ヘッドレスの手順 1・2 と本書の実施手順 1〜6 を入れ直して 1920x1080 に戻し、VM をもう一度再起動した。ヘッドレスセッションは自動起動し、`gnome-shell --virtual-monitor 1920x1080` が動いた。再起動後は手順 4〜6 だけを流し、1920x1080 の撮影、電卓の `12×34=408`、Activities のクリックと電卓の終了を実画面で確認した。初回の AT-SPI の列挙に `GetItems` の警告が 1 回出たが、窓の一覧と入力・撮影は通った。再起動後の AVC は無かった。

最後に RDP クライアント・Xvfb の補助プロセスと RDP 用の試験アカウントを終了・削除した。VM は GUI 用の仮想モニターと電源設定を残し、3389 / 3390 の RDP は disabled、待ち受けも無い。電卓は閉じた。利用者の変更を含む `scripts/gnome-gui.py` は書き換えず、コピーを使った。

ログは `.verification/desktop/gui-final-plan-session/` と `gui-after-boot-plan-session/`、`gui-final-state.log`、`desktop-cleanup.log`。実画面は `gui-after-reboot-calc.png`、最後の窓が無い画面は `gui-final.png` に保存した。実機の再起動、物理画面への同時ログイン、キーリングの解除は今回も確認していない。

---

### 付録: 現行版の新規 VM での再検証（2026-10-06）

**環境と流し方**: `5da3478` の現行手順を、別のクリーンな AlmaLinux 10.2 Workstation / x86_64 の VM（1 vCPU、SELinux Enforcing、firewalld 稼働、US 配列）で実行した。SSH の一般ユーザーの対話 PTY に折り畳みの外のブロックを手順ごとに貼り、応答とプロンプトを待った。GUI は GNOME 49.4 のヘッドレスセッションに仮想モニターを付け、操作後の PNG を目視した。既存の実機・資格情報は使っていない。

実施手順 1〜6 を実行した。`1920x1080` のスクリーンショットと、電卓の `12*34` → `408` を画面で確認した。最初の起動では、D-Bus と loginctl の準備ができていても約 15 秒の撮影中に最初のフレームが出ず、空ファイルになった。後から同じ撮影を再実行すると正常な PNG になった。約 1 分待った事実を、どの環境でも必ず成功する待ち時間とはしていない。

実施手順 4 と解像度変更の確認を、撮影の成功・MIME `image/png` を確認してから情報を表示し、失敗時は中断を明示するブロックへ修正した。読者にも PNG を開いて画面を確認してから次へ進むようにした。改訂後の両ブロックを再実行し、`1920x1080` と `1280x720` の正常な PNG と画面を確認した。VM 再起動後の GNOME 自動起動も確認した。

ロールバック 1・2 で drop-in を削除し、`ExecStart=/usr/bin/gnome-shell` に戻してセッションを起動し直した。GUI 補助スクリプトそのものは変更していない。物理モニター、長時間の放置試験、全アプリの操作は今回実施していない。

### 手順中の実測・検証状況の記録

- **ドロップインは、このユーザーの GNOME のセッションすべてに効く**: 後からモニターをつないで、このユーザーで PC の画面からログインすると、見えない仮想モニターも足されるはず（確かめていない）。そのときは[ロールバック](../claude-code-gui.md#ロールバック)で外す

### 手順中の検証状況

- **ログインのキーリングは開いていない**: パスワードを読もうとするアプリは、キーリングを開く窓を出す。Claude Code には答えられない（`Escape` で閉じられるかは確かめていない）

### 手順内の実測・検証状況

- 起動直後は、手順 3 のバス名とセッションが出ても最初の映像がまだ届かず、`15 秒以内に PipeWire のストリームから 1 コマも届かなかった` になることがあった。少し待って同じブロックを貼り直し、正常な PNG が撮れたことを確かめる。繰り返しても撮れなければ、手順 3 に記したサービスの状態とログを見る（新しいクリーン VM で、初回の失敗と再試行の成功を確認）

### 手順内の実測・検証状況

- クリーンインストール後の最初のセッションでは「AlmaLinux へようこそ」の案内が重なることがある。そのときは先に `key Escape` → `sleep 1` → `shot` で案内を閉じたことを確かめてから、手順 5 へ進む。案内を閉じてもアクティビティ画面は残る（VM で確認）

### 手順内の実測・検証状況

- 窓の一覧に電卓が出るまで待つ。1 vCPU の VM の初回は 18 秒ほどかかり、固定の `sleep 3` では足りなかった

### 実施手順 / 手順 1: 補足: 変数について

- 小さくすると、画面の写しの PNG も小さくなる（1920x1080 で約 0.7 MB）。後から変えるときは[仮想モニターの大きさを変える（任意）](../claude-code-gui.md#仮想モニターの大きさを変える任意)

### 実施手順 / 手順 4: 補足: 画面の撮り方

- `gnome-gui.py shot` は、Mutter の `org.gnome.Mutter.ScreenCast` で主のモニターを録画するセッションを作り、PipeWire のストリームから GStreamer で 1 コマを PNG にして、セッションを止める。1 回 0.4 秒ほど

### 実施手順 / 手順 3: 補足: restart を使わない理由

- `sudo systemctl restart` で起動し直すと、新しいセッションができなかった。unit は `inactive (dead)` になり、セッションも消えた

- `stop` は `gdm-new-session` を止めるだけで、前のセッションの片付けは後から進む。`start` がその途中に重なり、新しいセッションの gnome-session が `Transaction for gnome-session-wayland@gnome.target/start is destructive` で systemd の起動をあきらめ、GDM が `Session never registered, failing` で終わらせた

