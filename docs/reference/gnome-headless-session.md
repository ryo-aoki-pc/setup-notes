# GNOME のヘッドレスセッションの参考資料

[AlmaLinux 10 の「GNOME のヘッドレスセッション」](../gnome-remote.md#gnome-のヘッドレスセッション)・[注意点](../extra/gnome-headless-session.md)

[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/gnome-headless-session.md#補足の実測)

## 補足

### GNOME のヘッドレスセッション / 手順 1: 補足: 変数について

- `SERVER_IP`・`SERVER_NAME`・`SERVER_FQDN` は、[AlmaLinux 10 の「GNOME のリモートログイン」](../gnome-remote.md#gnome-のリモートログイン) の手順 1 と同じ。証明書の SAN に入れる（手順 3）
- `RDP_PORT` の判定に使う `systemctl is-enabled gnome-remote-desktop.service` は、`--user` を付けないのでシステムの unit を見る
- リモートログインのデーモンは 3389/tcp で待ち受けるので、同じ PC ではヘッドレスのセッションの RDP を 3390/tcp にする
- `RDP_PORT` は、リモートログインのシステムのデーモン（`gnome-remote-desktop.service`）が有効なら `3390`、そうでなければ `3389` になる
- 任意の変数のブロックは、最後に値を読み戻す
- 変数はそのシェルの中だけで有効なので、新しいシェルでは手順 1 の 2 つのブロックを貼り直す

### GNOME のヘッドレスセッション / 手順 2: 補足: gnome-headless-session@.service と、セッションの見分け方

**gnome-headless-session@.service**:

- gdm の unit。`gdm` ユーザーで `gdm-new-session <USER> --headless` を動かし、GDM に、モニターの無いセッションを作らせる（RHEL 10 の文書の「1.4 headless server for a single user」と同じ unit）
- できるセッションは、`loginctl` で `Class=user`・`Type=wayland`・`TTY=headless`・`Remote=yes`・`Service=gdm-autologin`・seat 無し
- PAM は `gdm-autologin` で、パスワードを使わない。ログインのキーリングは開かない（[注意点](../extra/gnome-headless-session.md#注意点)）
- `WantedBy=graphical.target` なので、`enable` で起動時にも作られる。`Requires=gdm.service`

**セッションの見分け方と、モニターが無い間**:

- `loginctl` の行の `awk` は、このユーザーのヘッドレスのセッションの行だけを出す。ほかのユーザーのヘッドレスのセッションも `TTY` が `headless` になる
- `for` の行で、gnome-shell のバス名と `loginctl` のセッションの両方が出るまで、30 秒まで待つ
- このセッションには、RDP のクライアントがつないでいない間、モニターが 1 枚も無い。アプリはそのまま動き続ける
- クライアントがつなぐと、そのクライアントの窓の大きさの仮想モニターができ、切ると消える

### GNOME のヘッドレスセッション / 手順 3: 補足: 証明書

- 中身は [AlmaLinux 10 の「GNOME のリモートログイン」の手順 2](../gnome-remote.md#gnome-のリモートログイン) と同じ（SAN に IP を `DNS:` でも入れる理由も同書の補足）。違うのは、自分のホームに自分の所有で作ること
- RHEL の文書は `winpr-makecert` で作るが、ここでは SAN を付けるために openssl で作る
- TLS のパスはデスクトップ共有と共用なので、最初に dconf の元値を `~/.local/state/gnome-headless-session-setup` に退避する。未設定だったキーは空ファイルになる
- 貼り直しても退避は上書きしない。`backup-complete` は退避完了、`ready` は証明書の準備完了、`created-certificate` はこの手順が新規生成したことの目印
- 新規生成したファイルの SHA-256 も `created.sha256` に保存する。[リモートログインだけにする（併用をやめる）](../gnome-remote.md#gnome-のヘッドレスセッション-リモートログインだけにする併用をやめる)では、中身が変わっていたりリンクへ置き換わっていたりすれば削除しない
- 既存の証明書を更新する手順ではない
- `set -e` は丸括弧の中だけに効かせ、退避・生成・読み取りのどれかが失敗したら、そのブロックを止める
- 既存の証明書と鍵は上書きしない
- `中断:` のとき、生成途中で照合用の記録も作れなかった場合は、ファイルは自動削除されず残る
- 置き場所は、RHEL 10 の文書の 1.4 と同じ

### GNOME のヘッドレスセッション / 手順 4: 補足: grdctl --headless

- `--headless` を付けた `grdctl` は、ヘッドレスのセッションのデーモン（`gnome-remote-desktop-headless.service`）の設定を変える
- 書き先は dconf。ポートなどは `/org/gnome/desktop/remote-desktop/rdp/headless/`、証明書と鍵は、デスクトップ共有と同じ `/org/gnome/desktop/remote-desktop/rdp/` に入る
- 資格情報（手順 5）は、TPM があれば TPM に、無ければ `~/.local/share/gnome-remote-desktop/credentials.ini`（GKeyFile）に置く
- `disable-port-negotiation` は、指定したポートが使われていたときに、次のポートを順に試すのを止める。ポートが勝手に変わって、手順 7 で開けたポートと食い違うのを防ぐ
- 初めて設定するときだけ出る `[x509_utils_from_pem]: BIO_new failed for certificate` と `RDP server certificate is invalid.` は、設定する前の空の値を読んだもの

### GNOME のヘッドレスセッション / 手順 5: 補足: 資格情報の置き場所

- TPM の無い PC では、`~/.local/share/gnome-remote-desktop/credentials.ini` に入る（0600。暗号化はされていない）
- パスワードを変えるときも、この手順を貼り直す
- 引数なしで打つのは、パスワードをシェルの履歴に残さないため

### GNOME のヘッドレスセッション / 手順 6: 補足: grdctl --headless rdp enable

- `grdctl --headless rdp enable` は、`/org/gnome/desktop/remote-desktop/rdp/headless/enable` を true にし、ユーザーの unit `gnome-remote-desktop-headless.service` を enable して起動する（`~/.config/systemd/user/gnome-session.target.wants/` にリンクができる）。
- unit は `WantedBy=gnome-session.target` なので、ヘッドレスのセッションと一緒に起動する

### GNOME のヘッドレスセッション / 手順 7: 補足: ファイアウォール

- firewalld の定義済みサービス `rdp` は 3389/tcp だけなので、ポートで開ける
- public ゾーンで開けるので、public ゾーンに属するすべての NIC で開く（gnome-remote-desktop.md と同じ）
- リモートログインと併用している PC でも、ここで 3390/tcp を足す（3389/tcp はリモートログインの `rdp` サービスで開いている）

### GNOME のヘッドレスセッション / 手順 9: 補足: TLS プローブ

- スクリプトは [AlmaLinux 10 の「GNOME のリモートログイン」の手順 10](../gnome-remote.md#gnome-のリモートログイン) と同じもの。第 2 引数でポートを渡す
- `/usr/bin/python3` で動かすのは、Homebrew が PATH の先頭にあるときも、同じ Python にするため（どちらでも動く）
- `~/rdp_tls_probe.py` は、この手順書が作る唯一の作業ファイル
- プローブは、TLS のハンドシェイクで証明書を受け取ると、認証をせずに接続を閉じる。デーモンは、この接続を `client authentication failure` などのエラーの行としてログに残す（2026-10-11 の Hyper-V の VM では 7 行。待ち受けと、その後の接続には響かなかった）
  - 同じスクリプトを使う [GNOME のリモートログイン の参考資料](gnome-remote-desktop.md#gnome-のリモートログイン--手順-10-補足-tls-プローブとfreerdp-クライアントでの確かめ方)にも、この行が出て正常とある

### GNOME のヘッドレスセッション / 手順 10: 補足: FreeRDP の証明書の確認と、つなぐときの表示

- FreeRDP 3.10.3 は、保存した証明書（`~/.config/freerdp/server/<SERVER_IP>_<RDP_PORT>.pem`）が無い初めての接続でも、`REMOTE HOST IDENTIFICATION HAS CHANGED!` の警告を出してから、証明書の確認（`Do you trust the above certificate? (Y/T/N)`）を出す。初めてでも警告が出る理由は、確かめていない
- `Y` で答えると、証明書がこのファイルに保存され、次からは聞かれない（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/gnome-headless-session.md#付録-hyper-v-の-vm-で通した記録2026-10-11)）。`T` と `N` で答えたときの動きは、確かめていない
- FreeRDP 3.10.3 は、`Password:` の後に `[ERROR][com.winpr.sspi.Kerberos] - [kerberos_AcquireCredentialsHandleA]: krb5_parse_name (Configuration file does not specify default realm [-1765328160])` を 2 行出してから、つながった（2026-10-11 の Hyper-V の VM。この行が出る理由は、確かめていない）
  - [GNOME のリモートログイン の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/gnome-remote-desktop.md#常に出るが無害なログ)には、近い行（`kerberos_AcquireCredentialsHandleA: krb5_init_context ...`）が、Kerberos を設定していない環境で NTLM に切り替わるときの出力として載っている

### 接続元を LAN に絞る / 手順 2: 補足: 引用符

- rich rule は**二重引用符**で囲む。単一引用符だと変数が展開されない（[AlmaLinux 10 の「GNOME のリモートログイン: 接続元を LAN に絞る」](../gnome-remote.md#gnome-のリモートログイン-接続元を-lan-に絞る)）

### リモートログインだけにする（併用をやめる） / 手順 1・6: 補足: セッションの見分け方

- **`Service` で見分ける**: GDM がリモートログインで作るセッションも seat が無く、`loginctl list-sessions` の `TTY` の列は `headless` になる。ヘッドレスのセッションは PAM の `gdm-autologin`、リモートログインのセッションは `gdm-password` で作られるので、`loginctl show-session` の `Service` で分ける（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/gnome-headless-session.md#付録-実機でリモートログインだけにした記録2026-10-08)）
- **`grdctl --headless status` で確かめない**: `~/.local/share/gnome-remote-desktop/credentials.ini` が無いと、空のまま作る（[実施手順 8 の補足](#gnome-のヘッドレスセッション--手順-5-補足-資格情報の置き場所)）
- 同じ項の手順 1 の `for` の行は、`<SESSION_ID> <Service>` を 1 セッション 1 行で出す
- 同じ項の手順 6 の最後の数は、このユーザーの `gdm-autologin` のセッションだけを数え、リモートログインのセッションは数えない。`for` の行で、セッションが終わるまで、30 秒まで待つ
### 選択した方針

- **ヘッドレスのセッションにする**（RHEL 10 の文書の 1.4）
  - デスクトップ共有（設定アプリの「デスクトップ共有」。CLI で設定する手順は [AlmaLinux 10 の「GNOME のデスクトップ共有」](../gnome-remote.md#gnome-のデスクトップ共有)）は、PC の物理の画面を写す。モニターの無い PC には写す画面が無い
  - リモートログイン（[AlmaLinux 10 の「GNOME のリモートログイン」](../gnome-remote.md#gnome-のリモートログイン)）は、GDM で認証し、そのユーザーのセッションが無ければ作成する。切断後のセッションや、ここで常駐させたヘッドレスのセッションがあれば、そこへ引き渡す
  - ヘッドレスのセッションは RDP 接続より前から常駐し、手順 10 の接続では GDM のログイン画面を通らず、そのデスクトップへ入る
- **証明書は openssl で作る** — SAN に IP を入れる理由は gnome-remote-desktop.md と同じ
- **ポートを固定し、ポートのネゴシエーションを切る** — ファイアウォールで開けたポートと食い違わないように

### 参照

- [Chapter 1. Remotely accessing the desktop — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/remotely-accessing-the-desktop)（1.4 headless server for a single user）
- [GNOME/gnome-remote-desktop README.md](https://github.com/GNOME/gnome-remote-desktop/blob/master/README.md)（Headless の節）

---
