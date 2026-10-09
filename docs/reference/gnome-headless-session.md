# GNOME のヘッドレスのセッションの手順（モニターの無い PC のデスクトップに RDP でつなぐ）の参考資料

[手順書](../gnome-headless-session.md)

[検証記録](../verification/gnome-headless-session.md#参考資料から分離した記録)

## 補足

### 実施手順 / 手順 1: 補足: 変数について

- `SERVER_IP`・`SERVER_NAME`・`SERVER_FQDN` は、[gnome-remote-desktop.md](../gnome-remote-desktop.md) の手順 1 と同じ。証明書の SAN に入れる（手順 3）
- `RDP_PORT` の判定に使う `systemctl is-enabled gnome-remote-desktop.service` は、`--user` を付けないのでシステムの unit を見る
- リモートログインのデーモンは 3389/tcp で待ち受けるので、同じ PC ではヘッドレスのセッションの RDP を 3390/tcp にする

### 実施手順 / 手順 2: 補足: gnome-headless-session@.service と、セッションの見分け方

**gnome-headless-session@.service**:

- gdm の unit。`gdm` ユーザーで `gdm-new-session <USER> --headless` を動かし、GDM に、モニターの無いセッションを作らせる（RHEL 10 の文書の「1.4 headless server for a single user」と同じ unit）
- できるセッションは、`loginctl` で `Class=user`・`Type=wayland`・`TTY=headless`・`Remote=yes`・`Service=gdm-autologin`・seat 無し
- PAM は `gdm-autologin` で、パスワードを使わない。ログインのキーリングは開かない（[注意点](../gnome-headless-session.md#注意点)）
- `WantedBy=graphical.target` なので、`enable` で起動時にも作られる。`Requires=gdm.service`

**セッションの見分け方と、モニターが無い間**:

- `loginctl` の行の `awk` は、このユーザーのヘッドレスのセッションの行だけを出す。ほかのユーザーのヘッドレスのセッションも `TTY` が `headless` になる
- このセッションには、RDP のクライアントがつないでいない間、モニターが 1 枚も無い。アプリはそのまま動き続ける
- クライアントがつなぐと、そのクライアントの窓の大きさの仮想モニターができ、切ると消える

### 実施手順 / 手順 3: 補足: 証明書

- 中身は [gnome-remote-desktop.md 手順 2](../gnome-remote-desktop.md#実施手順) と同じ（SAN に IP を `DNS:` でも入れる理由も同書の補足）。違うのは、自分のホームに自分の所有で作ること
- RHEL の文書は `winpr-makecert` で作るが、ここでは SAN を付けるために openssl で作る
- TLS のパスはデスクトップ共有と共用なので、最初に dconf の元値を `~/.local/state/gnome-headless-session-setup` に退避する。未設定だったキーは空ファイルになり、ロールバックでは `reset` で戻す
- 貼り直しても退避は上書きしない。`backup-complete` は退避完了、`ready` は証明書の準備完了、`created-certificate` はこの手順が新規生成したことの目印
- 新規生成したファイルの SHA-256 も `created.sha256` に保存する。ロールバックでは、中身が変わっていたりリンクへ置き換わっていたりすれば削除しない
- 既存の証明書を更新する手順ではない。以前の手順で残した `.old` なども、この手順とロールバックでは消さない
- `set -e` は丸括弧の中だけに効かせ、退避・生成・読み取りのどれかが失敗したら、そのブロックを止める

### 実施手順 / 手順 4: 補足: grdctl --headless

- `--headless` を付けた `grdctl` は、ヘッドレスのセッションのデーモン（`gnome-remote-desktop-headless.service`）の設定を変える
- 書き先は dconf。ポートなどは `/org/gnome/desktop/remote-desktop/rdp/headless/`、証明書と鍵は、デスクトップ共有と同じ `/org/gnome/desktop/remote-desktop/rdp/` に入る
- 資格情報（手順 5）は、TPM があれば TPM に、無ければ `~/.local/share/gnome-remote-desktop/credentials.ini`（GKeyFile）に置く
- `disable-port-negotiation` は、指定したポートが使われていたときに、次のポートを順に試すのを止める。ポートが勝手に変わって、手順 7 で開けたポートと食い違うのを防ぐ

### 実施手順 / 手順 5: 補足: 資格情報の置き場所

- TPM の無い PC では、`~/.local/share/gnome-remote-desktop/credentials.ini` に入る（0600。暗号化はされていない）
- パスワードを変えるときも、この手順を貼り直す

### 実施手順 / 手順 6: 補足: grdctl --headless rdp enable

- `grdctl --headless rdp enable` は、`/org/gnome/desktop/remote-desktop/rdp/headless/enable` を true にし、ユーザーの unit `gnome-remote-desktop-headless.service` を enable して起動する（`~/.config/systemd/user/gnome-session.target.wants/` にリンクができる）。
- unit は `WantedBy=gnome-session.target` なので、ヘッドレスのセッションと一緒に起動する

### 実施手順 / 手順 7: 補足: ファイアウォール

- firewalld の定義済みサービス `rdp` は 3389/tcp だけなので、ポートで開ける
- public ゾーンで開けるので、public ゾーンに属するすべての NIC で開く（gnome-remote-desktop.md と同じ）

### 実施手順 / 手順 9: 補足: TLS プローブ

- スクリプトは [gnome-remote-desktop.md 手順 10](../gnome-remote-desktop.md#実施手順) と同じもの。第 2 引数でポートを渡す
- `/usr/bin/python3` で動かすのは、Homebrew が PATH の先頭にあるときも、同じ Python にするため（どちらでも動く）

### リモートログインだけにする（併用をやめる） / 手順 1・3〜5: 補足: セッションの見分け方と、ドロップインを外す理由

- **`Service` で見分ける**: GDM がリモートログインで作るセッションも seat が無く、`loginctl list-sessions` の `TTY` の列は `headless` になる。ヘッドレスのセッションは PAM の `gdm-autologin`、リモートログインのセッションは `gdm-password` で作られるので、`loginctl show-session` の `Service` で分ける（[検証記録](../verification/gnome-headless-session.md#付録-実機でリモートログインだけにした記録2026-10-08)）
- **ドロップインを外す**: [claude-code-gui.md](../claude-code-gui.md) の `--virtual-monitor` は、このユーザーの GNOME のセッションすべてに効く。リモートログインで作られたセッションでも主のモニター（`Meta-0`）になり、RDP のモニターはその右に足される。上部バーは主のモニターにしか出ない（[claude-code-gui.md の注意点](../claude-code-gui.md#注意点)）
- **ドロップインを外す前に入ったセッションを終わらせる**: ドロップインは gnome-shell が起動するときにだけ読まれる。リモートログインのセッションは切断しても残り、次のログインでそこへ引き渡されるので、終わらせないと仮想モニターが付いたままになる
- **`grdctl --headless status` で確かめない**: `~/.local/share/gnome-remote-desktop/credentials.ini` が無いと、空のまま作る（[実施手順 5 の補足](#実施手順--手順-5-補足-資格情報の置き場所)）

### 選択した方針

- **ヘッドレスのセッションにする**（RHEL 10 の文書の 1.4）
  - デスクトップ共有（設定アプリの「デスクトップ共有」。CLI で設定する手順は [gnome-desktop-sharing.md](../gnome-desktop-sharing.md)）は、PC の物理の画面を写す。モニターの無い PC には写す画面が無い
  - リモートログイン（[gnome-remote-desktop.md](../gnome-remote-desktop.md)）は、GDM で認証し、そのユーザーのセッションが無ければ作成する。切断後のセッションや、ここで常駐させたヘッドレスのセッションがあれば、そこへ引き渡す
  - ヘッドレスのセッションは RDP 接続より前から常駐し、手順 10 の接続では GDM のログイン画面を通らず、そのデスクトップへ入る
- **証明書は openssl で作る** — SAN に IP を入れる理由は gnome-remote-desktop.md と同じ
- **ポートを固定し、ポートのネゴシエーションを切る** — ファイアウォールで開けたポートと食い違わないように

### 参照

- [Chapter 1. Remotely accessing the desktop — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/remotely-accessing-the-desktop)（1.4 headless server for a single user）
- [GNOME/gnome-remote-desktop README.md](https://github.com/GNOME/gnome-remote-desktop/blob/master/README.md)（Headless の節）

---
