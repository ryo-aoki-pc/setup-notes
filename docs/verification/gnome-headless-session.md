# GNOME のヘッドレスのセッションの手順（モニターの無い PC のデスクトップに RDP でつなぐ）の検証記録

[手順書](../almalinux-setup.md#gnome-のヘッドレスセッション-実施手順)・[ロールバックと注意点](../extra/gnome-headless-session.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 操作上の注意と併記されていた記録

- 2026-10-05 より前の手順などで退避が無い場合は、共用 TLS 設定と証明書を保持する。導入前の値に戻すには、別に残した記録が要る

### 対象と検証環境

- **目的**: モニターの無い PC で GNOME のデスクトップを常駐させ、別のマシンの RDP クライアントから、そのデスクトップにつなぐ
- **方式**: GDM のヘッドレスのセッション（`gnome-headless-session@<USER>.service`）と、そのセッションの gnome-remote-desktop（`grdctl --headless`、`gnome-remote-desktop-headless.service`）。RHEL 10 の文書の「1.4 headless server for a single user」と同じ
- **状態**: **aarch64 の実機（Raspberry Pi 5）で本実行済み（2026-10-01）。クリーンインストールした x86_64 の VM でも実施手順 1〜10・LAN 限定・ロールバック 2〜5 を本実行し、再起動後の自動起動と RDP の画面操作を確認した（2026-10-06。[今回の付録](#付録-クリーンインストールした-vm-での検証2026-10-06)）**
  - 2026-10-06: 別の新規 VM で現行手順を再検証した。今回の実施・解除・未実施範囲は[新しい付録](#付録-現行版の新規-vm-での再検証2026-10-06)に記録した
  - 通したもの: この文書のブロックを、SSH でログインしたユーザーの `bash -i`（擬似端末、ブラケットペースト無し）にそのまま貼った。書き換えたのは手順 1 の `SERVER_IP` と、任意節の `LAN_SUBNET` だけ
    - 実施手順 1〜9 → 手順 10（別のセッションの FreeRDP で接続）→ [接続元を LAN に絞る（任意）](../almalinux-setup.md#gnome-のヘッドレスセッション-接続元を-lan-に絞る任意) → [ロールバック](../extra/gnome-headless-session.md#ロールバック)の手順 2〜5
    - `grep headless` を直した後の版で、実施手順 1・2 → ロールバックの手順 5 → 実施手順 1・2 をもう一度通した（ほかのユーザーのヘッドレスのセッションがある状態で）
  - 確認したこと
    - リモートログイン（3389）が有効な PC で、`RDP_PORT` が 3390 になり、このセッションの RDP が 3390/tcp で待ち受ける
    - FreeRDP 3.10.3 で、証明書の Thumbprint が `TLS fingerprint` と一致し、正しいパスワードでつながり、違うパスワードで断られる
    - クライアントには、このセッションのデスクトップが、クライアントの大きさ（1600x900）で出る。クライアントからのクリックとキーで、アクティビティ画面から電卓が起動した
    - 切ってつなぎ直すと、同じデスクトップ（電卓が開いたまま）に戻る
    - 手順 7 の前は、別の network namespace からの接続が `No route to host` で断られ、後はつながる。LAN に絞ると、`LAN_SUBNET` の外からは断られる
    - ロールバックの後、firewalld・dconf・ホームは実施前と同じになる
    - SELinux が Enforcing のまま、AVC は出なかった
  - 確認していないこと
    - 再起動の後の自動起動（この Pi では WireGuard・Samba・Syncthing も動いているので、再起動しなかった）
    - 手順 10 のポートへ直接つなぐ場合の、Windows のリモート デスクトップ接続・Android のクライアント・LAN の別のマシン（実物）からの接続。Windows 11 から 3389 のリモートログインを経由する引き渡しは、下の 2026-10-02 の記録で確認済み
    - x86_64 の PC、サスペンドできる PC（ログイン画面が眠らせないこと）
    - 同じユーザーのローカルのログインとの重なり、後からリモートログインを有効にしたとき
  - 2026-10-02: リモートログインのログイン画面から同じユーザーで入ると、このセッションに引き渡された（Windows 11 の「リモートデスクトップ接続」で。[gnome-remote-desktop.md の付録](gnome-remote-desktop.md#付録-真っ暗な画面のまま切れた原因の調査記録環境-22026-10-02)）
    - 同じ日に、試験用のユーザーとコンテナの FreeRDP 3.10.3 で、3390 と 3389 の同時の接続と GDM の再起動を確かめた（[同書の付録の追加の確認](gnome-remote-desktop.md#追加の確認)。[注意点](../extra/gnome-headless-session.md#注意点)）
  - 2026-10-02: もとの手順 2・3 と、[ロールバック](../extra/gnome-headless-session.md#ロールバック)のもとの手順 5・6 をつなぎ、確かめの行を `if … fi` の `else` に入れた（つないだ形は貼っていない。`bash -n` だけ）
  - 2026-10-05: 手順 3・4 とロールバックの手順 3・4 に、共用 TLS 設定の退避・復元と、新規生成した証明書だけの削除を追加した。構文検査と一時ディレクトリ・スタブでの確認だけで、実機の RDP では流していない
  - 2026-10-08: 節「[リモートログインだけにする（併用をやめる）](../almalinux-setup.md#gnome-のヘッドレスセッション-リモートログインだけにする併用をやめる)」を足し、aarch64 の実機（同じ Raspberry Pi 5）で本実行した（[付録](#付録-実機でリモートログインだけにした記録2026-10-08)）
    - 通したもの: この節の手順 1・3〜5・7（手順 2 は、ヘッドレスのセッションの RDP を設定していなかったので飛ばした）。手順 6 は利用者の Windows の「リモート デスクトップ接続」
    - 確認したこと: リモートログインで入ると新しいセッション（`gdm-password`）ができ、gnome-shell は `--virtual-monitor` 無しで、モニターは RDP の 1 枚だけ。上部バーのあるデスクトップが出た（利用者の目視）。切断してつなぎ直すと、同じセッションへ 2 回とも引き渡された
    - 見つけたこと: リモートログインのセッションも `loginctl` の `TTY` の列が `headless` で、もとのロールバックの手順 5 の数え方では、ヘッドレスのセッションが無くても `1` になる。`Service=gdm-autologin` で数える形に直した（直した後の形は、この節の手順 4 として実機で流した）
    - 確認していないこと: ヘッドレスのセッションが動いている状態から、この節の手順 4 で止めること（利用者が先に止めていた）。この節の手順 2。もとの[手順 2](https://github.com/ryo-aoki-pc/setup-notes/blob/ae1981a48fee0e26540d82224d4c195492bae782/docs/gnome-headless-session.md#実施手順) の確かめの行は直していない
  - **2026-10-11 に、Hyper-V の VM（x86_64。Kickstart で入れた Workstation に、初期設定・画面オフの任意節の手順 1〜5・linger・Podman を通したもののクローン）で、実施手順 1〜10 を上から通した**（[付録](#付録-hyper-v-の-vm-で通した記録2026-10-11)）
    - 通し方: ブロックは、SSH の対話の bash に 1 つずつ貼った（書き換えたのは手順 1 の `SERVER_IP` だけ）。VM のコンソールにはログインしていない。手順 10 は、同じ仮想スイッチの別の VM（AlmaLinux 10.2）の FreeRDP 3.10.3 から行った
    - 結果: 通した 10、通らなかった 0、条件に当たらず飛ばした 0、未実施 0
    - 確認したこと: システムのリモートログインが無効な PC で `RDP_PORT` が 3389 になり、3389/tcp で待ち受ける。証明書は新しく作る側。FreeRDP の `Thumbprint:` が `TLS fingerprint` と同じで、正しいパスワードでつながり、デスクトップがクライアントの窓の大きさ（1024×768）で出る。クライアントのキーで電卓が起動し、切ってつなぎ直すと同じデスクトップに戻る。SELinux は Enforcing のまま
    - SELinux の拒否: 通しの中の読み（別の SSH から打った `ausearch` の `<no matches>`）は、読み方のせいで当てにならない。後から、同じ VM の監査ログのファイルを数え直して、AVC の行は 0 行だった（[数え直し](#selinux-の拒否の数え直し2026-10-11)）。クライアントの VM は、確かめていない
    - 通らなかったもの: 無い
    - 直した所: 手順 10 の箇条書き（FreeRDP が初めての接続でも出す警告、`(Y/T/N)` への答え方、2 回目から聞かれないこと、パスワードの後の Kerberos の `[ERROR]` の行、手順 9 のプローブがログに残す行）。文言だけで、コードブロックは変えていない。指摘は 4 つで、残る 1 つ（手順 3・9 の `openssl` が Homebrew のものになる）は未対応
    - 未実施の範囲と、確認していないこと: 任意節「接続元を LAN に絞る」、節「リモートログインだけにする（併用をやめる）」、ロールバック、再起動の後の自動起動、`RDP_PORT` が 3390 になる側、既にある証明書を使う側、Windows のクライアント、実機

| 項目 | 値 |
|---|---|
| 実施日 | 2026-10-01 |
| 機械 | Raspberry Pi 5 Model B（aarch64、メモリ 8 GB）。HDMI は 2 つとも `disconnected`（モニター無し） |
| OS | AlmaLinux 10.2 (Lavender Lion)、カーネル `6.12.96-20260724.v8.1.el10`、SELinux Enforcing |
| GNOME | `gdm-47.0-24.el10_2`、`gnome-shell-49.4-9.el10_2.alma.1`、`mutter-49.4-4.el10_2`、`gnome-session-46.0-11.el10`、`gnome-remote-desktop-49.3-4.el10_2` |
| そのほか | `firewalld-2.4.3-4.el10_2`、`openssl-3.5.8-1.el10_2.alma.1`、`sudo-1.9.17-10.p2.el10_2.6`（このユーザーは NOPASSWD）。リモートログイン（システムのデーモン）が有効 |
| クライアント | `freerdp-3.10.3-12.el10_2.11`（AlmaLinux 10 のコンテナ。同じ Pi の、試験用のユーザーのヘッドレスのセッションに描いた。[付録](#付録-実機での検証記録2026-10-01)） |


> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../almalinux-setup.md#gnome-のヘッドレスセッション-実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${SERVER_IP}` | クライアントが接続に使う PC の IP アドレス | `192.168.10.100` |
> | `${SERVER_NAME}` / `${SERVER_FQDN}` | PC のホスト名 / FQDN（`hostname` / `hostname -f` から自動で入る） | `my-pc` / `my-pc.lan` |
> | `${RDP_PORT}` | RDP で待ち受けるポート（リモートログインのデーモンが有効なら 3390、無ければ 3389。自動で入る） | `3390` |
> | `${LAN_SUBNET}` | LAN のサブネット。[接続元を LAN に絞る](../almalinux-setup.md#gnome-のヘッドレスセッション-接続元を-lan-に絞る任意)ときだけ、その節で設定する | `192.168.10.0/24` |
>
> 出力例・ログの中の値は `<HOSTNAME>` / `<SERVER_IP>` / `<RDP_PORT>` / `<USER>` / `<UID>` / `<SESSION_ID>` / `<PID>` / `<FINGERPRINT>`（証明書の TLS fingerprint）のプレースホルダで書いてある。`<...>` を含むコマンドは bash のコードブロックには置かない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| seat0 | GDM のログイン画面だけ（モニターがつながっていない） |
| ヘッドレスのセッション | 無し（`gnome-headless-session@<USER>.service` は `disabled`） |
| `~/.local/share/gnome-remote-desktop` | 無し。dconf の `/org/gnome/desktop/remote-desktop/` も空 |
| リモートログイン | システムの gnome-remote-desktop が 3389/tcp で待ち受けている |
| firewalld | public ゾーン。サービスに `rdp`、ポートは `22/tcp 51820/udp 445/tcp`（3390/tcp は無し） |
| gnome-power.md | 手順 1・2 を済ませてあった（前提） |

### 完了時点の状態

実施手順の後の出力:

```
$ grdctl --headless status
Init TPM credentials failed because No TPM device found, using GKeyFile as fallback.
Overall:
	Unit status: active
RDP:
	Status: enabled
	Port: 3390
	TLS certificate: /home/<USER>/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
	TLS fingerprint: <FINGERPRINT>
	TLS key: /home/<USER>/.local/share/gnome-remote-desktop/certificates/rdp-tls.key
	Negotiate port: no
	Username: (hidden)
	Password: (hidden)
$ ss -Hlnt "sport = :${RDP_PORT}"
LISTEN 0      5      *:3390 *:*
$ sudo firewall-cmd --list-ports
22/tcp 445/tcp 3390/tcp 51820/udp
```

- クライアントがつないでいる間は、`org.gnome.Mutter.DisplayConfig` の `GetCurrentState` に `Virtual remote monitor`（クライアントの大きさ）が 1 枚だけある。切ると消え、ジャーナルに `Removed virtual monitor` が出る

### 操作上の注意と併記されていた記録

- **起動し直すのは `restart` ではなく、`stop` → 待つ → `start`**: `sudo systemctl restart gnome-headless-session@<USER>.service` では、新しいセッションができなかった（[付録](#付録-実機での検証記録2026-10-01)）

### 注意点 / 手順 0: 本文中の記録

  - リモートログイン（[gnome-remote-desktop.md](../almalinux-setup.md#gnome-のリモートログイン-実施手順)）のログイン画面から同じユーザーで入ると、新しいセッションは作られず、このセッションに引き渡された（2026-10-02。同書の[注意点](../extra/gnome-remote-desktop.md#注意点)）

### 注意点 / 手順 0: 本文中の記録

  - 起動し直しが前のセッションの片付けとぶつかると、新しいセッションはすぐ終わる（2026-10-02 に、2 つのうち 1 つで起きた）

### 付録: 実機での検証記録（2026-10-01）

**環境**: [対象と検証環境](#対象と検証環境)の表の Raspberry Pi 5。前提の gnome-power.md 手順 1・2 は済ませてあった。

**クライアントの作り方**（検証の都合。手順書では要らない）:

- 同じ Pi に試験用のユーザーを作り、そのユーザーにもヘッドレスのセッションを起動した。そのセッションには、[claude-code-gui.md](../almalinux-setup.md#claude-code-の-gnome-操作-実施手順) と同じドロップインで 1600x900 の仮想モニターを付けた
- root の podman で、AlmaLinux 10 に `freerdp` を入れたコンテナを作り、そのセッションの Xwayland（`DISPLAY`・`XAUTHORITY`）に `xfreerdp /v:192.168.1.10:3390 /u:<RDP のユーザー名> /f` を描かせた（ネットワークは `--network host`）
- クライアントの画面は、試験用のユーザーのセッションで `scripts/gnome-gui.py shot` で撮り、入力も同じスクリプトで送った（クライアントの FreeRDP の窓へ）
- ファイアウォールの確かめには、veth でつないだ network namespace（`192.168.252.0/24` と `192.168.253.0/24`。[samba.md の付録](samba.md#network-namespace-から-firewalld-越しに到達する)と同じ手法）から、手順 9 のプローブを 192.168.1.10:3390 へ当てた
- 確かめた後に、試験用のユーザー（`userdel -r`）・コンテナとイメージ・network namespace を消した

**流し方**: この文書のブロックを Python のスクリプトで抜き出し、擬似端末で動かした `bash -i` に書き込んだ（ブラケットペースト無し。手順 5 と FreeRDP の問い合わせには、問い合わせが出てから答えた）。

| 手順 | 結果 |
|---|---|
| 1 | `RDP_PORT = 3390`（リモートログインのデーモンが enabled） |
| 2 | `Created symlink …`。`<SESSION_ID> <UID> <USER> - <PID> user headless no -` と `<PID> /usr/bin/gnome-shell` |
| 3 | `rdp-tls.crt`（`-rw-r--r--`）と `rdp-tls.key`（`-rw-------`）。最初は、検証の仕掛けのシェルの `umask 077` を引き継いで `rdp-tls.crt` も 0600 になったので、`umask 022` のシェルで貼り直した |
| 4 | `BIO_new failed for certificate`・`RDP server certificate is invalid.` が 1 回ずつと、TPM のメッセージが 4 回。貼り直したときは TPM のメッセージだけ |
| 5 | `Username:` と `Password:` を聞かれた |
| 6 | `enabled` |
| 7 の前 | network namespace から `No route to host`（`ss` では `*:3390` で待ち受けていた） |
| 7 | `success` が 2 行、`22/tcp 445/tcp 3390/tcp 51820/udp`。network namespace からつながった |
| 8・9 | [完了時点の状態](#完了時点の状態)のとおり。プローブは `selectedProtocol=0x2`・`TLSv1.3`・`fingerprint:` が `TLS fingerprint` と一致 |
| 10 | 下の「クライアントからの接続」 |
| LAN に絞る | `success` が 3 行、rich rule に `192.168.252.0/24` と `3390`。`192.168.252.2` からはつながり、`192.168.253.2` からは `No route to host` |
| ロールバック 2〜5 | `success` が 2 行（rich rule が消えた）、`disabled`、`Removed …`。firewalld の `--list-all` は runtime・permanent とも実施前と同じ。dconf の `/org/gnome/desktop/remote-desktop/` は空 |

**クライアントからの接続**（手順 10）:

- FreeRDP は、証明書の `Subject`・`Issuer`・`Thumbprint` を出して `Do you trust the above certificate? (Y/T/N)` と聞いた。`Thumbprint` は手順 8 の `TLS fingerprint` と同じだった
  - 新しいコンテナ（保存済みの証明書が無い）でも、`The host key for 192.168.1.10:3390 has changed` の警告を出した（理由は確かめていない）
- 続けて `Domain:`（空のまま Enter）と `Password:` を聞いた。正しいパスワードで、サーバーのジャーナルに `Added virtual monitor Meta-0` が出た
- クライアントの画面と、サーバー側で撮ったこのセッションの画面は、ほぼ同じだった（縮めて比べた画素の差の平均が 0.39/255）
- クライアントから、左上のアクティビティのボタンをクリックし、`calc` と打って Enter を押すと、このセッションで電卓が起動した（サーバー側の `windows` に `gnome-calculator` が出た）
- クライアントを止めると、サーバーのジャーナルに `[RDP] Network or intentional disconnect, stopping session` と `Removed virtual monitor Meta-0` が出た。電卓は動き続け、つなぎ直すと、電卓が開いたままのデスクトップが出た
- 違うパスワードでは、クライアントが `ERRCONNECT_AUTHENTICATION_FAILED`、サーバーが `AcceptSecurityContext status SEC_E_MESSAGE_ALTERED` と `client authentication failure` を出した

**手順書を直したこと**:

- 手順 2 とロールバックの手順 5 の確かめの行（もとの手順 3 とロールバックの手順 6）は、最初は `grep headless` で数えていた。試験用のユーザーのヘッドレスのセッションも数えられ、ロールバックの手順 5 の確かめの行が `1` を出した（30 秒待った後）。このユーザーの行だけを数える `awk` にして、ほかのユーザーのセッションがある状態で通し直した

**分ける前の版の検証で見つけたこと**（[claude-code-gui.md の付録](claude-code-gui.md#付録-実機での検証記録2026-10-01)）:

- ヘッドレスのセッションでも gsd-power が動き、既定のままでは、無操作の 15 分で `Error calling suspend action: … SleepVerbNotSupported …` を出した（サスペンドしようとした。この Pi はサスペンドできない）
- `sudo systemctl restart gnome-headless-session@<USER>.service` では、前のセッションの片付けと新しいセッションの起動が重なり、新しいセッションの gnome-session が `Transaction … is destructive` で起動をあきらめ、GDM が `Session never registered, failing` で終わらせた。`stop` → 前のセッションが `loginctl` から消えるのを待つ → 3 秒待つ → `start` では起動した
- GNOME のセッションが終わると、`gnome-session-restart-dbus.service` がユーザーの D-Bus を起動し直した
- リモートログインが有効な PC では、このセッションの中で `gnome-remote-desktop-handover.service` も起動した（TCP では待ち受けない）
- claude-code-gui.md のドロップインで仮想モニターを付けたセッションに RDP でつなぐと、クライアントには、その仮想モニターの右に足された別のモニター（`Virtual remote monitor`）が写った。`screen-share-mode` を `'mirror-primary'` と明示しても同じだった

#### 未確認事項

- 2026-10-01 の実機では、再起動の後にヘッドレスのセッションと RDP の待ち受けが自動で起動することは未確認。2026-10-06 の x86_64 の VM では確認した（末尾の付録）
- Windows のリモート デスクトップ接続・Android のクライアント・LAN の別のマシン（実物）からの接続
- x86_64 の PC と、サスペンドできる PC（ログイン画面が眠らせないこと）
- 同じユーザーでリモートログインやローカルのログインをしたときの動き
- 後からリモートログインを有効にしたとき（このセッションの RDP を 3389/tcp で使っていた場合）
- キーリングを開く窓が出たときの動き（RDP のクライアントからパスワードを入れて開けるか）

### 付録: クリーンインストールした VM での検証（2026-10-06）

AlmaLinux 10.2 Workstation を ISO から新規に入れた VirtualBox の VM（x86_64、1 vCPU、メモリ 6 GiB、SELinux Enforcing、日本語 UI、US 配列）で、検証用ユーザーの SSH PTY に現行のブロックを個別に貼った。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、GNOME Shell は `49.4-9.el10_2.alma.1`、Mutter は `49.4-4.el10_2`、GDM は `47.0-24.el10_2`、GNOME Remote Desktop は `49.3-4.el10_2`。利用者のアカウントは使っていない。

実施手順 1〜10、接続元を LAN に絞る任意節、ロールバック 2〜5 を本実行した。システムのリモートログインが有効な状態から、手順 1 の判定で `RDP_PORT=3390` になった。手順 2 は、Mutter のバス名が現れても loginctl の行がまだ無い場合があったので、両方を待つ形に直して再検証した。

手順 3 は、未設定だった共用 TLS の値を退避して新しい証明書・鍵を生成し、ハッシュを控えた。手順 4〜9 で 3390 番・ポート交渉なし・ヘッドレス資格情報を設定して有効化し、TLS 1.3、fingerprint、待ち受けを確認した。最初の `set-tls-cert` は鍵のパスが未設定のため `RDP server certificate is invalid` も出したが、続く `set-tls-key` の後は設定が揃い、実際の TLS と画面接続は通った。証明書・鍵を既に持つ環境や、既存の非空の TLS 設定を復元する分岐は、この VM では流していない。

クライアントは、LAN の別の AlmaLinux VM の FreeRDP 3.10.3（Xvfb 1600x900 上。準備と資格情報の扱いは [リモートログインの今回の記録](gnome-remote-desktop.md#付録-クリーンインストールした-vm-での検証2026-10-06)）。3390 番でデスクトップが表示され、キー入力による電卓の `12×34=408` を実画面で確認した。切断後も同じヘッドレスセッションが残り、再接続すると電卓の 408 に戻った。接続時には RDP 用の仮想モニターができ、切断後の DisplayConfig はモニター 0 枚だった。

LAN 限定の rich rule に替えてから VM を再起動した。ヘッドレスセッションと RDP の unit は自動起動し、3390 番の `RDP server started` は起動後に記録された。1 vCPU では unit が active になってからこのログまで約 25 秒かかった。続いて 3389 番の GDM からこのユーザーへ入ると、自動起動した `Service=gdm-autologin` の同じセッションに渡された。そこで計算した `9×9=81` は、3389 を切って 3390 に直接つなぎ直しても残った。LAN 制限後・再起動後も LAN の別 VM から接続でき、今回の AVC は無かった。

ロールバック 2〜5 は rich rule と資格情報を解除し、共用 TLS の cert / key を退避した未設定の値へ戻した。生成時の SHA-256 と 2 ファイルが一致してから、新規生成した証明書・鍵・退避を削除した。ヘッドレスの unit は disabled / inactive、loginctl の対象行は 0、3389 / 3390 番の待ち受けは消えた。GUI 検証を続けるため、その後は手順 1・2 だけを入れ直した。

今回の RDP は、GUI 検証用の固定 `--virtual-monitor` を外して測った。Windows / Android の直接接続、物理 PC、指定 LAN 外からの拒否、同じユーザーの物理画面への同時ログインは今回も確認していない。2026-10-01 の付録の未確認事項のうち、再起動後の自動起動は今回の x86_64 の VM で確認した。

実行ログは `.verification/desktop/` の `rdp-headless-plan-session`、`rdp-credentials-plan-session`、`rdp-probes-plan-session`、`rdp-lan-plan-session`、`rdp-rollback-plan-session`、`rdp-headless-boot-debug.log`、`rdp-rollback-state.log`。実画面は `rdp-headless-calc-result.png`、`rdp-headless-reconnected.png`、`rdp-direct-after-reboot.png` に保存した。

---

### 付録: 現行版の新規 VM での再検証（2026-10-06）

**環境と流し方**: `5da3478` の現行手順を、別のクリーンな AlmaLinux 10.2 Workstation / x86_64 の VM（1 vCPU、SELinux Enforcing、firewalld 稼働、US 配列）で実行した。SSH の一般ユーザーの対話 PTY に折り畳みの外のブロックを手順ごとに貼り、応答とプロンプトを待った。GUI は GNOME 49.4 のヘッドレスセッションに仮想モニターを付け、操作後の PNG を目視した。既存の実機・資格情報は使っていない。

実施手順 1〜9 と、手順 10 の RDP 接続を本実行した。システムの RDP が先に有効なので自動判定は `3390` だった。セッションの起動、共通 TLS 設定の退避、証明書・秘密鍵の作成と権限・ラベル、資格情報、有効化、待受と dconf を確認した。GNOME Remote Desktop は `49.3-4.el10_2`、暗号ネゴシエーションは TLS 1.3 だった。指定 LAN の rich rule も実行した。

別の新規 VM の FreeRDP `3.10.3` から、証明書の指紋を照合して接続した。固定の `1920x1080` 仮想モニターは残したため、RDP の `1600x900` は別のモニターになった。RDP のキーで Firefox の窓をそのモニターへ移し、画面・入力を確認した。再起動後もセッションと 3390 の待受が自動起動し、LAN 制限を保持して実再接続できた。起動完了前の接続は失敗したため、待受が出てから再試行した。

ロールバック 2〜5 を実行し、LAN の許可、RDP の資格情報・有効化、共通 TLS 設定、今回生成したファイルを解除した。証明書の sha256 の一致を確認してから削除する分岐も通った。最後に headless セッション数は `0`、サービスは `disabled` になった。Windows / Android クライアント、別ユーザー同時接続、LAN 外の拒否は今回実施していない。

---

### 付録: 実機でリモートログインだけにした記録（2026-10-08）

**環境**: [対象と検証環境](#対象と検証環境)の表と同じ Raspberry Pi 5（AlmaLinux 10.2、カーネル `6.12.96-20260724.v8.1.el10`、SELinux Enforcing）。`gdm-47.0-24.el10_2`、`gnome-shell-49.4-9.el10_2.alma.1`、`mutter-49.4-4.el10_2`、`gnome-remote-desktop-49.3-4.el10_2`、`systemd-257-23.el10_2.2.alma.1`。

**実施前の状態**:

- リモートログイン（[gnome-remote-desktop.md](../almalinux-setup.md#gnome-のリモートログイン-実施手順)。3389/tcp、手順 5 の `After=gdm.service` のドロップインあり）が有効
- 2026-10-02 の起動から、このユーザーのヘッドレスのセッション（実施手順 1・2 だけ。ヘッドレスのセッションの RDP は設定していない）と、[claude-code-gui.md](../almalinux-setup.md#claude-code-の-gnome-操作-実施手順) の `--virtual-monitor 1920x1080` のドロップインが動いていた
- このユーザーの linger は `yes`

**節を書く前に起きていたこと**:

- 22:09:01 に、利用者が SSH から `sudo systemctl disable --now gnome-headless-session@<USER>.service` を実行し、ヘッドレスのセッションが終わった（この節の手順 4 に当たる。ドロップインを外す前）
- 続けて利用者が Windows のリモートログインで入ると、新しいセッション（`Service=gdm-password`・`Remote=yes`・`Type=wayland`・`TTY=headless`）ができた
  - その gnome-shell は `--virtual-monitor 1920x1080` 付きで起動し、RDP のモニターは `Meta-1` として足された（journal の `Added virtual monitor Meta-1`）
  - 利用者は 1 分ほどで切断した。そのときクライアントに何が写っていたかは聞いていない
- Claude Code が、[claude-code-gui.md の注意点](../extra/claude-code-gui.md#注意点)（ドロップインがあるとリモートログインのクライアントには壁紙だけが写る）に当たる状態だと判断し、この節を書いて続きを流した

**流し方**: この節のブロックを、SSH で入ったこのユーザーの Claude Code の Bash ツール（非対話の bash）で、手順ごとに出力を見てから実行した。手順 6 は利用者が行った。

| 手順 | 結果 |
|---|---|
| 1 | `<SESSION_ID> gdm-password`・`disabled`・`disabled`・`virtual-monitor.conf`・`<PID> /usr/bin/gnome-shell --virtual-monitor 1920x1080`・`22/tcp 445/tcp 51820/udp`。rich rule は空 |
| 2 | 飛ばした（ヘッドレスのセッションの RDP は無かった） |
| 3 | `ExecStart=/usr/bin/gnome-shell` の 1 行。ドロップインのディレクトリも消えた |
| 4 | 既に `disabled`・`inactive` なので `systemctl` は何も出さず、1 秒かからずに `0`。同じ時点で、もとのロールバックの手順 5 の数え方（`TTY` の列だけ）では `1` だった |
| 5 | sudo 無しでセッションが終わり、約 1 秒で `0`。gnome-shell の行は出なかった。journal には `Removed virtual monitor Meta-0`、`gnome-session-restart-dbus.service` の起動、`Removed session <SESSION_ID>.` が出た。リモートログインのデーモンは `active` のまま、3389/tcp で待ち受けていた |
| 6 | 利用者が Windows の「リモート デスクトップ接続」でつなぎ、GDM のログイン画面からログインした。上部バーのあるデスクトップが出た。切断してつなぎ直すのを 2 回行い、どちらも同じデスクトップに戻った（利用者の報告。画面は撮っていない） |
| 7 | `<SESSION_ID> gdm-password` の 1 行・`<PID> /usr/bin/gnome-shell`・`disabled`・`LISTEN 0      5      *:3389 *:*` |

**手順 6 の間のサーバーの journal**:

- 1 回目の接続: GDM のログイン画面のセッションの後に、新しいセッション（`gdm-password`）ができた。gnome-shell が起動して `Added virtual monitor Meta-0` が出た（`Meta-1` は出なかった）
- 切断すると `Removed virtual monitor Meta-0` が出て、セッションは残った
- つなぎ直すと、ログイン画面でログインした後に `[RDP] Sending server redirection` と `discover_other_daemon: 1` が出て、同じ gnome-shell に `Added virtual monitor Meta-0` が出た（2 回とも）
- つないでいる間の `org.gnome.Mutter.DisplayConfig` の `GetCurrentState` は、`Meta-0`（`Virtual remote monitor`、モードは `1080x1196@60.000`）の 1 枚だけだった

**流した後に確かめたこと**:

- 手順書に載せた形のブロックを Python で抜き出し、`bash -n` を通した（この節の手順 1・3〜5・7 と、ロールバックの手順 1〜5）
- この節の手順 4 のブロックは、直したロールバックの手順 5 と同じ
- この節の手順 1・4・7 は、抜き出したブロックをもう一度実行した。手順 1 は、ドロップインが無く gnome-shell に `--virtual-monitor` が無い（手順 3・5 を飛ばしてよい）と読める出力になった
- この節の手順 5 は、利用者がつないでいたので流し直していない

**そのほか**:

- 接続のたびに、`gnome-remote-desktop-daemon` が journal のソケット（`/run/systemd/journal/socket`）へ `sendto` するのを SELinux が断った、という setroubleshoot のメッセージが出た。2026-10-02 の起動直後から出ていたもので、今回の操作とは関係ない（直していない）
- linger が `yes` なので、GNOME のセッションが無い間も、Syncthing（ユーザーの unit）は 2026-10-02 の起動から止まらずに動いていた

**確認していないこと**:

- ヘッドレスのセッションが動いている状態から、この節の手順 4 で止めること（利用者が先に止めていた）
- この節の手順 2（ヘッドレスのセッションの RDP を外す流れ）
- linger が無い PC での動き
- もとの[手順 2](https://github.com/ryo-aoki-pc/setup-notes/blob/ae1981a48fee0e26540d82224d4c195492bae782/docs/gnome-headless-session.md#実施手順) の確かめの行（`TTY` の列だけで見る）が、リモートログインのセッションがあると早く抜けること。手順 2 は直していない

---

### 付録: Hyper-V の VM で通した記録（2026-10-11）

- **何を**: [手順書](https://github.com/ryo-aoki-pc/setup-notes/blob/114c2b2bfd14b51f9e1925b150cbf72e1954f311/docs/gnome-headless-session.md)の実施手順 1〜10（コミット `114c2b2`）を、上から最後まで通した
  - 任意節「接続元を LAN に絞る」、節「リモートログインだけにする（併用をやめる）」、ロールバックは、この通しでは流していない
  - 続けて、同じ VM で [claude-code-gui.md](../almalinux-setup.md#claude-code-の-gnome-操作-実施手順) の実施手順 1〜6 を通した（[同書の検証記録の付録](claude-code-gui.md#付録-hyper-v-の-vm-で通した記録2026-10-11)）
- **結果**: 10 手順のうち、通した 10、通らなかった 0、条件に当たらず飛ばした 0、未実施 0
  - 手順 1〜9 の出力は、どれも手順書の箇条書きのとおりだった
  - 手順 10 に、箇条書きに無い出力が 3 つあった（FreeRDP が初めての接続でも出す警告、パスワードの後に出す Kerberos の `[ERROR]` の行、手順 10 で見るログに残る手順 9 のプローブの行。[指摘と状態](#指摘と状態2026-10-11)）
- **どの状態から**: Hyper-V の列の VM のスナップショット `after-CL1` のクローン
  - Kickstart で入れた AlmaLinux 10.2 の Workstation に、[初期設定](../almalinux-setup.md)の実施手順（[記録](almalinux-setup.md#付録-hyper-vvmwarevirtualbox-の-vm-で今の順番で通した記録2026-10-11)）、同書の任意節「画面オフ・画面ロック・自動サスペンドを止める」の手順 1〜5、[linger.md](../almalinux-setup.md#ユーザーサービスの常駐-実施手順)、[podman.md](../almalinux-setup.md#podman-実施手順) を通した後の状態
  - 前提（同じ任意節の手順 1・2。サスペンドできる PC では手順 3・4 も）は、満たしている
- **どう通したか**: 手順書から抜き出したブロックを、SSH の対話の bash に 1 つずつ貼った（手順書の「本人のシェル（SSH でよい）」のとおり）
  - VM のコンソールでは、GNOME にログインしていない（終わりまで GDM のログイン画面のまま）
  - 手順 10 は、同じ仮想スイッチにつないだ別の VM（以下「クライアント」）から行った
  - 実アカウントでのログインは無い。新しく決めたパスワードは、手順 5 の RDP のパスワードの 1 つ（OS のパスワードとは別の値）
- **誰が**: 通したのは、検証の担当のエージェント。この付録は、その報告と証跡のファイルを、VM に触れない別の担当が照らし合わせて書いた。その後、もう 1 人の担当（これも VM に触れていない）が、付録と手順書の直しを、証跡のファイルと PNG に当てて点検した
- **証跡**: 追跡していない `.verification/campaign/hv/CL2/`（このリポジトリには入っていない）。下のファイルの名前は、ここからの相対パス
  - `seq` は、主の VM が `session/steps.jsonl`、クライアントが `peer/session/steps.jsonl` の番号。`after-confirm/` は、それぞれの `session/after-confirm/`
- 出力の中の VM の値は、`<USER>`・`<UID>`・`<HOSTNAME>`・`<SERVER_IP>`・`<SESSION_ID>`・`<PID>`・`<FINGERPRINT>`・`<RDP のユーザー名>` で書いた。パスワードと鍵は載せていない

#### 環境（2026-10-11）

| 項目 | 内容 |
|---|---|
| ホスト | Windows 11 Pro 10.0.26300 |
| ハイパーバイザ | Hyper-V（担当の報告では `vmms.exe` 10.0.26100.8875）。層の `Get-VmvBackend` は `Generation=2`・`Version=12.0`・`HypervisorPresent=True`（`meta.json`） |
| VM | 第 2 世代（UEFI）、Secure Boot オフ、vTPM 無し、2 vCPU、3072 MB（ゲストから見えるのは 2900 MB）、ディスク 64 GB、NIC 1 枚（Default Switch） |
| クライアント | 同じ構成で 2048 MB（ゲストから見えるのは 1639 MB）。Kickstart で入れたベースのスナップショット `clean-install` のクローンで、初期設定は通していない（sudo はパスワードを聞く） |
| ゲスト | 2 台とも AlmaLinux 10.2 (Lavender Lion)、kernel `6.12.0-211.64.1.el10_2.x86_64`、x86_64（`meta.json`・`peer/meta.json`）。VM は SELinux Enforcing、firewalld 有効（`public`、`eth0`。`guest-facts-end.txt`）。ロケール `ja_JP.UTF-8` とキー配列 `us` は、Kickstart のベースの値で（[初期設定の通しの記録](almalinux-setup.md#付録-hyper-vvmwarevirtualbox-の-vm-で今の順番で通した記録2026-10-11)）、この通しでは読み直していない（出力は 2 台とも日本語。VM の入力ソースは `[('xkb', 'us'), ('ibus', 'anthy')]`）。クライアントの SELinux と firewalld は見ていない |
| VM に入っていた版 | `gnome-remote-desktop-49.3-4.el10_2`、`gnome-shell-49.4-9.el10_2.alma.1`、`mutter-49.4-4.el10_2`、`gdm-47.0-24.el10_2`、`pipewire-1.4.11-1.el10_2.1`、`wireplumber-0.5.10-1.el10`、`freerdp-libs-3.10.3-12.el10_2.14`、`firewalld-2.4.3-4.el10_2`、`python3-3.12.15-1.el10_2`、`openssl-3.5.8-2.el10_2.alma.1`（`guest-facts-start.txt`・`guest-facts-end.txt`） |
| VM の PATH | Homebrew が `/usr/bin` より前にある（初期設定を通した後なので。先頭は `~/.grok/bin`、その次が `/home/linuxbrew/.linuxbrew/bin`）。対話のシェルの `openssl` は `/home/linuxbrew/.linuxbrew/bin/openssl`（`OpenSSL 4.0.3 29 Sep 2026`）が先で、OS のものは `/usr/bin/openssl`（`OpenSSL 3.5.8 25 Aug 2026`）。`python3`・`gsettings` も Homebrew のものが先。`grdctl`・`dconf`・`busctl`・`file` は `/usr/bin` だけ（主の seq 21） |
| クライアントの版 | 入れたのは `freerdp-3.10.3-12.el10_2.14`（`xfreerdp --version` は `This is FreeRDP version 3.10.3 (n/a)`。`xfreerdp` と `wlfreerdp` が入り、`sdl-freerdp` は無い）。初めから入っていたのは `gnome-shell-49.4-9.el10_2.alma.1`、`gdm-47.0-24.el10_2`、`xorg-x11-server-Xwayland-24.1.9-4.el10_2.3`（`peer/guest-facts-start.txt`） |
| 手順書 | `docs/gnome-headless-session.md`、コミット `114c2b2`（`114c2b2bfd14b51f9e1925b150cbf72e1954f311`。`steps.jsonl` の `docCommit`） |
| 実施の日時 | 2026-10-11。手順 1〜9 は 11:10:32〜11:12:04 UTC（ゲストの時計で 20:10〜20:12 JST）。手順 10 は、クライアントの準備から最後の切断まで 11:13:01〜11:18:40 UTC |
| 貼り方 | ドライバ（`rb.mjs paste`）で、SSH の対話の bash にブラケットペーストで 1 ブロックずつ。貼った中身は手順書のまま（`steps.jsonl` の `sha256` と `pastedSha256` が同じ。`sha256` は、`114c2b2` の手順書のブロックとも、箇条書きを直した後の手順書のブロックとも同じ）。手順 1 の 1 つ目のブロックだけ、`SERVER_IP` に VM の IP を入れた |
| sudo | VM は NOPASSWD（初期設定の「ログインと sudo」）で、1 度もパスワードを聞かなかった |
| 検証用の値 | `SERVER_IP`（VM の Default Switch の IP）と、RDP のユーザー名・パスワード（この検証のために決めた値。記録に載せていない） |
| 始めの状態 | システムの `gnome-remote-desktop.service` と `gnome-headless-session@<USER>.service` は、どちらも `disabled`。`Linger=yes`。`~/.local/share/gnome-remote-desktop` は無い。`/usr/bin/gsettings` で `idle-delay` は `uint32 0`、`lock-enabled` は `false`。`sleep.target` と `suspend.target` は `masked`、logind の `CanSuspend` は `no`。このユーザーのセッションは `manager`（linger）と SSH だけで、コンソールは GDM のログイン画面（`guest-facts-start.txt`） |

#### 手順ごとの結果（2026-10-11）

| 手順 | 判定 | 出力と、確かめたこと | 根拠 |
|---|---|---|---|
| 1 | 通した | `USER = <USER>`・`SERVER_IP = <SERVER_IP>`・`SERVER_NAME = <HOSTNAME>`・`SERVER_FQDN = <HOSTNAME>.mshome.net`・`RDP_PORT = 3389`（システムのリモートログインが `disabled` なので、3389 の側） | 主の seq 1・2、`after-confirm/0002-実施手順-1.txt` |
| 2 | 通した | `Created symlink '/etc/systemd/system/graphical.target.wants/gnome-headless-session@<USER>.service' → '/usr/lib/systemd/system/gnome-headless-session@.service'.`、`<SESSION_ID> <UID> <USER> - <PID> user headless no -`、`<PID> /usr/bin/gnome-shell`。別の SSH で見ると、セッションは `TTY=headless`・`Remote=yes`・`Service=gdm-autologin`・`Type=wayland`・`State=active`、サービスは `active (running)`（`/usr/libexec/gdm-new-session <USER> --headless`） | 主の seq 3、`0003-実施手順-2.txt`、`facts-after-step2.txt` |
| 3 | 通した | 新しく作る側（退避した `tls-cert`・`tls-key` は 0 バイトで、共用の TLS の値は未設定だった）。「確認」の前に、`openssl req` が鍵を作る進み（`.` と `+` の行と `-----`）を出した。「確認」の後は、`合計 8`、`rdp-tls.crt`（`-rw-r--r--.`、1216 バイト）、`rdp-tls.key`（`-rw-------.`、1704 バイト）、`TLS の退避と証明書の準備が完了`。証明書は `CN=<HOSTNAME>`、SAN は `DNS:<HOSTNAME>, DNS:<HOSTNAME>.mshome.net, DNS:<SERVER_IP>, IP Address:<SERVER_IP>`、`TLS Web Server Authentication`、有効期間は 2026-10-11 から 2036-10-08 | 主の seq 4、`0004-実施手順-3.txt`、`facts-after-step3.txt`、`session/session-001.raw` |
| 4 | 通した | `[x509_utils_from_pem]: BIO_new failed for certificate` と `RDP server certificate is invalid.` が 1 回ずつ、`Init TPM credentials failed because No TPM device found, using GKeyFile as fallback.` が 4 行 | 主の seq 5、`0005-実施手順-4.txt` |
| 5 | 通した | `Init TPM credentials failed …` の 1 行の後に `Username:`、答えると `Password:`（打った文字は出ない）、答えるとプロンプトに戻った。確認の見出しの無い手順。入ったことは、手順 8 の `Username: (hidden)`・`Password: (hidden)` と、手順 10 の認証で確かめた | 主の seq 6〜8、`session/session-001.raw` |
| 6 | 通した | 「確認」の前に `Init TPM credentials failed …` が 1 行、後に `enabled` | 主の seq 9、`0009-実施手順-6.txt`、`session/session-001.raw` |
| 7 | 通した | `success`・`success`・`3389/tcp` | 主の seq 10、`0010-実施手順-7.txt` |
| 8 | 通した | `Init TPM credentials failed …` の 1 行の後に、`Unit status: active`・`Status: enabled`・`Port: 3389`・`TLS fingerprint: <FINGERPRINT>`・`Negotiate port: no`・`Username: (hidden)`・`Password: (hidden)`。`ss` は `LISTEN 0 5 *:3389 *:*` の 1 行 | 主の seq 11、`0011-実施手順-8.txt` |
| 9 | 通した | `negotiation: type=0x02 (RESPONSE) selectedProtocol=0x2`、`tls: TLSv1.3 TLS_AES_256_GCM_SHA384`、`fingerprint:` の値は、最後の `TLS fingerprint:` の値と同じ。`subject=CN=<HOSTNAME>`、SAN は手順 3 と同じ。`~/rdp_tls_probe.py` は消していない | 主の seq 12、`0012-実施手順-9.txt` |
| 10 | 通した | 下の「手順 10（クライアントからの接続）」 | 主の seq 13（メモ）、クライアントの seq 9〜21、`screens/step10-freerdp-*.png`（5 枚）、`facts-step10-connected.txt`、`facts-step10-disconnected.txt`、`grd-journal-full.txt`、`headless-session-journal.txt`、`peer/guest-facts-end.txt` |

- 条件に当たらなかった分岐: 手順 1 の `RDP_PORT` が 3390 になる側、手順 3 の「既にある証明書と鍵を使う」側と `中断:` の側、TPM のある PC の `grdctl` の出力
- sudo のある手順（2・7）は、パスワードを聞かれずに進んだ
- 手順ごとの時間（`steps.jsonl` の `durationMs`。出力が止まってからドライバが待つ 1.7〜1.9 秒を含む）: 手順 2 が 3.4 秒、手順 7 が 2.4 秒、ほかは 1.8〜1.9 秒。手順 5 は、入力待ちを含めて 20 秒ほど

**手順 10（クライアントからの接続）**:

- クライアントの用意（手順書の外）: `sudo dnf install -y freerdp`（入ったのは 1 個、138 k）。コンソールで GNOME にログインし、SSH のシェルに `DISPLAY=:0` と `XAUTHORITY`（`/run/user/<UID>/.mutter-Xwaylandauth.*`）を入れた
  - 手順書の形の `xfreerdp /v:<SERVER_IP>:3389 /u:<RDP のユーザー名>` を、その SSH のシェルから起動した。窓はクライアントのコンソールの画面に出て、入力待ち（証明書・`Domain:`・`Password:`）は SSH の端末に出た
- **1 回目**（クライアントの seq 10〜14）: `~/.config/freerdp` が無い状態で起動した（直前の seq 9 の `ls` が「そのようなファイルやディレクトリはありません」）
  - 出た順: `[verify_cb]: Certificate verification failure 'self-signed certificate (18)' at stack position 0` → `[x509_utils_from_pem]: BIO_new failed for certificate` → `[tls_print_new_certificate_warn]` の 12 行 → `Certificate details for <SERVER_IP>:3389 (RDP-Server):`（`Common Name`・`Subject`・`Issuer`・`Valid from`・`Valid to`・`Thumbprint`）→ `Do you trust the above certificate? (Y/T/N)`
  - 12 行の警告は、`The host key for <SERVER_IP>:3389 has changed`、`WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`、`IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!`、`Add correct host key in /home/<USER>/.config/freerdp/server/<SERVER_IP>_3389.pem to get rid of this message.`、`Host key verification failed.` など。初めての接続なのに出た
  - `Thumbprint:` は、手順 8 の `TLS fingerprint` と同じ値だった。`Y` と答えた
  - 続けて `Domain:`（空のまま Enter）、`Password:`（手順 5 のもの）の順に聞かれた
  - パスワードの後に、`[ERROR][com.winpr.sspi.Kerberos] - [kerberos_AcquireCredentialsHandleA]: krb5_parse_name (Configuration file does not specify default realm [-1765328160])` が 2 行出た。続けて `[WARN]` の 3 行（`expected messageChannelId=1008, got 1003` が 2 行と、`license binary blob::type BB_ERROR_BLOB, length=0, skipping.`）と `[INFO]` の行が出て、窓が開いた
  - クライアントのコンソールに `FreeRDP: <SERVER_IP>` という題の窓が出て、VM のヘッドレスのセッションのデスクトップ（上に検索欄のあるアクティビティ画面。上部バーに共有中の印）が写った（`screens/step10-freerdp-first-connect.png`）
  - VM の Mutter には、`Virtual remote monitor`（`Meta-0`、`1024x768@60.000`）が 1 枚できた（`facts-step10-connected.txt`。gnome-shell のログは `Added virtual monitor Meta-0`）
  - クライアントのコンソールから打った `calc` → Enter → `7*6` が届き、電卓に `7×6` が出た（`step10-freerdp-typed-calc.png`・`step10-freerdp-calculator-open.png`）
  - SSH の端末の Ctrl+C で切った。VM に、電卓のプロセスとセッションが残った（`facts-step10-disconnected.txt`）。gnome-shell のログに `Removed virtual monitor Meta-0`、デーモンのログに `[RDP] Network or intentional disconnect, stopping session` が出た
- **2 回目**（seq 15〜17）は、担当の操作の誤りで、認証に失敗して終わった
  - 1 回目に `Y` と答えたので、証明書が `~/.config/freerdp/server/<SERVER_IP>_3389.pem` に保存された（1216 バイト。指紋は `TLS fingerprint` と同じ。`peer/guest-facts-end.txt`）。2 回目は、証明書の確認が出ずに `Domain:` から始まった
  - 担当は、それを確かめずに、証明書の確認への答えのつもりで `T` と Enter を送った。`Domain:` に `T`、`Password:` に空が入り、`ERRCONNECT_AUTHENTICATION_FAILED` で終わった（パスワードは送っていない）
  - このときの Kerberos の `[ERROR]` の行は、`krb5glue_get_init_creds (Cannot find KDC for realm "T" [-1765328230])` の 2 行だった（`Domain:` に入った `T` を、realm として引いている）
- **3 回目**（seq 18〜21）: 証明書の確認は出ず、`Domain:`（空のまま Enter）→ `Password:` でつながった（Kerberos の `[ERROR]` の 2 行は、このときも出た）。`7×6` の電卓のある、同じデスクトップに戻った（`step10-freerdp-reconnect.png`）
  - 窓に Ctrl+Q を送ると、電卓が閉じた（`step10-freerdp-after-ctrl-q.png`。その後の `facts-step10-disconnected.txt` の 2 回目の記録に、電卓のプロセスは無い）
  - Ctrl+C で切ると、また `Removed virtual monitor Meta-0` が出た。セッションは残った
- `journalctl -b _SYSTEMD_USER_UNIT=gnome-remote-desktop-headless.service` は読めた（`grd-journal-full.txt`）
  - 手順 9 のプローブを貼った時刻（20:12:02）に、`BIO_read returned a system error 104: Connection reset by peer`・`[transport_accept_nla]: client authentication failure`・`[RDP] Network or intentional disconnect, stopping session` などの 7 行が残っていた。待ち受けと、その後の接続には響かなかった
- **認証だけの確かめ**（手順書の外。クライアントの seq 3〜8）: `xfreerdp /v:<SERVER_IP>:3389 /u:<RDP のユーザー名> /auth-only /from-stdin:force` の形
  - このままだと、`Password:` に答えた後、証明書の確認を聞かずに `[freerdp_tls_handshake]: certificate not trusted, aborting.` で終わった（終了コード 143）
  - `/cert:fingerprint:sha256:<FINGERPRINT>` を足すと、`Authentication only, exit status 1` で、終了コードは 131（認証が通った側）
  - 同じコマンドに、わざと違う値を答えると、`ERRCONNECT_AUTHENTICATION_FAILED` と `Authentication only, exit status 0` で、終了コードは 132。VM のログに `Message Integrity Check (MIC) verification failed!`・`AcceptSecurityContext status SEC_E_MESSAGE_ALTERED`・`client authentication failure` が出た

#### 通らなかった手順と、手順書の前提と違えた所（2026-10-11）

通らなかった手順は無い。手順書の前提と違えた所と、その見立ては、次のとおり。

- **SSH から貼ったせい**: 無い。手順書は「本人のシェル（SSH でよい）で貼る」と書いていて、SSH の対話の bash に貼るのは手順書のとおり
  - 手順 10 だけは、手順書が思い描く形（クライアントのデスクトップの端末で起動する）と違い、クライアントの SSH のシェルから `xfreerdp` を起動した。3 つの入力待ちが出た順は、手順書の箇条書きの順だった
- **Hyper-V のせい**: 確認の出力が変わった所は無い。値として変わるのは、`SERVER_FQDN` と証明書の SAN の `mshome.net`、Default Switch の IP、TPM が無いこと（下の表）
  - Default Switch の IP は、VM を起動し直すと変わりうる。変わると、手順 1 の `SERVER_IP` と証明書の SAN の IP が古くなり、FreeRDP は新しい IP を別のホストとして聞き直すはず、というのが担当の見立て。この通しでは確かめていない
- **手順書のせい**: 通らなかった所は無い。箇条書きに無い出力が 3 つ（手順 10 の FreeRDP の警告と Kerberos の `[ERROR]` の行、手順 10 で見るログに手順 9 のプローブが残す行）と、PATH に左右される所が 1 つ（`openssl`）。どれも[指摘と状態](#指摘と状態2026-10-11)
- **担当の操作の誤り**: 手順 10 の 2 回目の起動（上の記録）。箇条書きは「証明書の確認を聞かれたら」という条件付きの文で、誤りではない。2 回目から聞かれないことは、書いていなかった（今回足した）

#### Hyper-V に左右されたと思われる値（2026-10-11）

担当の報告が挙げた値（証跡と照らした）に、証跡から拾った 2 つ（グラフィックと、RDP のデーモンが待ち受けるまで）を足して、値のまま並べた。ほかのハイパーバイザや実機と比べて確かめたものではない。時間は、静かなホストで測ったものではない（同じ時刻に、ほかの単位の VM が動いていた）。性能の比べには使わない。

| 項目 | 値 |
|---|---|
| `systemd-detect-virt` | `microsoft`。`hostnamectl` は `Chassis: vm`・`Hardware Vendor: Microsoft Corporation`・`Hardware Model: Virtual Machine`・`Firmware Version: Hyper-V UEFI Release v4.1`（`guest-facts-end.txt`） |
| NIC と IP | 2 台とも `eth0` で、アドレスは `/20`（Default Switch。VM は `<SERVER_IP>/20`）。2 台のあいだは、この IP で直接届いた（クライアントからの ping は平均 0.4 ミリ秒。`peer/guest-facts-start.txt`） |
| ホスト名と FQDN | `hostname -f` は `<HOSTNAME>.mshome.net`。手順 1 の `SERVER_FQDN` と、手順 3 の証明書の SAN に、そのまま入った。`mshome.net` は、Default Switch が配る DNS のサフィックスとみる（担当の見立て。初期設定の通しの記録でも、ログインの案内に同じ名前が出ている） |
| TPM | 無い（`/dev/tpm*` が無い。VM に vTPM を付けていない）。`grdctl --headless` は、コマンドごとに `Init TPM credentials failed because No TPM device found, using GKeyFile as fallback.` を出した（手順 4 の箇条書きの「TPM の無い PC」の側）。資格情報は `~/.local/share/gnome-remote-desktop/credentials.ini`（82 バイト、`-rw-------`）に置かれた（中身は読んでいない） |
| コンソールの画面 | 2 台とも 1024×768（クライアントは `screens/step10-freerdp-*.png`。VM は `screens/main-console-end.png` で、画面が消えた後の止まった絵。[報告と証跡が食い違っていた所](#報告と証跡が食い違っていた所2026-10-11)）。クライアントの FreeRDP の窓（既定の 1024×768）は、題の帯のぶん画面からはみ出して、下の端が切れた（`screens/step10-freerdp-*.png`） |
| ヘッドレスのセッションのモニター | RDP がつながっているあいだだけ、`Virtual remote monitor`（`Meta-0`、`1024x768@60.000`。クライアントの窓の大きさ。選べる拡大率は 1.0 と 1.333）。つなぐと `Added virtual monitor Meta-0`、切ると `Removed virtual monitor Meta-0`（`headless-session-journal.txt`。つないで切ったのは 2 回） |
| グラフィック | RDP のデーモンが起動するたびに、ログに `libEGL warning: failed to get driver name for fd -1`・`libEGL warning: MESA-LOADER: failed to retrieve device information`・`MESA: error: ZINK: failed to choose pdev`・`libEGL warning: egl: failed to create dri2 screen` が出た（2 回。`grd-journal-full.txt`）。その後に `RDP server started` が出て、画面は写った。担当の報告には無い。初期設定の通しの記録では、同じ警告が WezTerm の起動で出ている（`/dev/dri/` が `hyperv_drm` の `card1` だけ）。同じ事情とみるが、この通しでは `/dev/dri/` を見ていない |
| RDP のデーモンが待ち受けるまで | デーモンの最初のログから `RDP server started` まで、手順 6 のときが 0.6 秒、claude-code-gui.md の手順 3 でセッションを起動し直したときが 3.0 秒（`grd-journal-full.txt`） |
| 起動などの時間 | クローンして SSH が通るまで、VM が 10.9 秒、クライアントが 10.5 秒（`meta.json`・`peer/meta.json`）。クライアントの `dnf install -y freerdp` は、sudo のパスワードに答えてから 11 秒 |
| メモリとディスク | VM の終わりの `free -m` は、合計 2900・使用 1692・available 1207（ヘッドレスのセッションと GDM のログイン画面が動いている状態）。`/` は 39G のうち 8.1G、`/home` は 19G のうち 6.2G。クライアントは、合計 1639・使用 1220・available 419（コンソールで GNOME にログインした状態） |
| 失敗しているユニット | `mcelog.service`（VM。初期設定の通しのときから同じ。手順には影響しない）。SELinux の拒否は、[SELinux の拒否の数え直し](#selinux-の拒否の数え直し2026-10-11)に書いた（通しの中の `ausearch -m avc -ts boot` の `<no matches>` は、当てにならない） |

#### 指摘と状態（2026-10-11）

- 行番号は、コミット `114c2b2` の `docs/gnome-headless-session.md` のもの。直した後の手順書では、行がずれている
- 指摘 1・2 は、担当の報告が挙げたもの（重大度と直し方の案も、報告のまま）。指摘 3・4 は、報告には無く、この付録を書くときに証跡から拾ったもの（重大度は、指摘 1 にそろえて付けた）
- 「状態」は、2026-10-11 に手順書を直した後のもの
- 手順書の指摘は 4（どれも低）。直した 3（どれも文言だけ）、未対応 1

| 連番 | 重大度 | 場所 | 何が起きたか | 切り分け | 直し方の案 | 状態 |
|---|---|---|---|---|---|---|
| 1 | 低 | 手順 10 の、証明書の確認の箇条書き（`:226`） | FreeRDP 3.10.3 は、初めてつなぐときも、証明書の確認の前に `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`・`Host key verification failed.` などを 12 行出す。その後に `Thumbprint:` と `Do you trust the above certificate? (Y/T/N)` が出る。箇条書きには、この警告も、`Y`・`T`・`N` のどれで答えるかも書いていなかった。`Y` と答えた後は、つなぎ直しても確認が出ず、`Domain:` から始まる（担当は、これに気付かずに 1 度まちがえた） | 手順書の書き落とし。クライアントは入れたばかりで、`~/.config/freerdp` は無かった。SSH にも Hyper-V にもよらない: 2026-10-01 の実機の記録でも、保存済みの証明書の無いコンテナの FreeRDP 3.10.3 が `The host key for … has changed` の警告を出している（[付録](#付録-実機での検証記録2026-10-01)）。[gnome-desktop-sharing.md](../almalinux-setup.md#gnome-のデスクトップ共有-実施手順) の「再起動の後に確かめてつなぐ」の手順 3 には、同じことがもう書いてある。警告の直前に `[x509_utils_from_pem]: BIO_new failed for certificate` が出ていて、保存した証明書が無いことを「変わった」と扱っているとみる（担当の見立て。確かめていない） | gnome-desktop-sharing.md と同じ 2 つの文を、手順 10 の箇条書きに足す | 直した（文言だけ。手順 10 の証明書の箇条書きの下に、入れ子の箇条書きを 3 つ足した。コードブロックは無い手順。参考資料にも補足を足した） |
| 2 | 低 | 手順 3 の `openssl`（`:95`・`:105`・`:106`）と、手順 9 のスクリプトの中の `openssl`（`:208`） | 初期設定を通した PC では、PATH で Homebrew が `/usr/bin` より前にあるので、`openssl` は Homebrew のもの（この VM では 4.0.3）に解決される。OS のものは `/usr/bin/openssl`（3.5.8）。この通しでは、作った証明書と鍵を GNOME Remote Desktop がそのまま読め、手順 4〜10 まで通った | 対話のシェルの `type -a openssl` が、Homebrew のものを先に返した（主の seq 21。`facts-after-step2.txt` も同じ）。同じ手順 9 は、`python3` には `/usr/bin/python3` と書いて Homebrew のものを避けている。害は出ていない。Homebrew の OpenSSL の版が上がると、作られる証明書の形が OS の側と離れうる、というのが担当の見立て | 手順 3 の 3 か所と、手順 9 のスクリプトの `['openssl', …]` を `/usr/bin/openssl` にそろえる。そのままにするなら、「Homebrew の OpenSSL 4.0.3 でも通った」を検証記録に残す | 未対応（コードブロックを変える直しで、変えた形は VM で貼っていない。害は見ていない。Homebrew の OpenSSL 4.0.3 で作った証明書と鍵で通ったことを、ここに残す） |
| 3 | 低 | 手順 10 の、パスワードの箇条書き（`:228`） | FreeRDP 3.10.3 は、`Password:` に答えた後、つながる前に `[ERROR][com.winpr.sspi.Kerberos] - [kerberos_AcquireCredentialsHandleA]: krb5_parse_name (Configuration file does not specify default realm [-1765328160])` を 2 行出す。エラーに見えるが、そのままつながった。箇条書きに無い | つながった 2 回（1 回目と 3 回目）と、`/auth-only` の 2 回（正しいパスワードと、わざと違う値）の、どれでも出た。クライアントは入れたばかりの AlmaLinux 10.2 で、Kerberos の設定はしていない。行が出る理由は、確かめていない。SSH にも Hyper-V にもよらないとみる: 2026-10-07 の VirtualBox の VM の記録（[gnome-desktop-sharing.md の検証記録](gnome-desktop-sharing.md)）にも、`krb5_parse_name (Configuration file does not specify default realm)` の後につながったとある | 箇条書きに「デスクトップが出れば、害は無い」と足す | 直した（文言だけ。パスワードの箇条書きの下に 1 つ足した。参考資料にも 1 行） |
| 4 | 低 | 手順 10 の、ログを見る箇条書き（`:230`） | 箇条書きが見るように言う `journalctl -b _SYSTEMD_USER_UNIT=gnome-remote-desktop-headless.service` には、うまくいっているときも、手順 9 のプローブの時刻に `client authentication failure` と `Network or intentional disconnect, stopping session` などの 7 行が残っている。認証の失敗に見える | 手順 9 のプローブは、TLS のハンドシェイクで証明書を受け取ると、認証をせずに接続を閉じる（スクリプトのとおり）。時刻が、プローブを貼った時刻と合う。Hyper-V にもよらない: 同じスクリプトを使う [gnome-remote-desktop.md の参考資料](../reference/gnome-remote-desktop.md#実施手順--手順-10-補足-tls-プローブとfreerdp-クライアントでの確かめ方)にも、この行が出て正常とある。担当の報告も、この行を「違う値のときだけ出る」と読み違えていた（[報告と証跡が食い違っていた所](#報告と証跡が食い違っていた所2026-10-11)） | 箇条書きに、プローブが残した行であることを足す | 直した（文言だけ。ログを見る箇条書きの下に 1 つ足した。参考資料の手順 9 の補足にも 1 行） |

環境と道具の指摘（手順書の外。このリポジトリでは直さない）:

- **FreeRDP 3.10.3 の `/auth-only`**: 認証が通っても、終了コードは 0 にならない（通ると 131 と `Authentication only, exit status 1`、違うパスワードは 132 と `exit status 0`）。`/from-stdin:force` を付けると、証明書の確認を聞かずに拒む。成否は、終了コードではなくログの行で読む。証明書は `/cert:fingerprint:sha256:<FINGERPRINT>` で渡す
- **非対話の SSH の `gsettings`**: PATH で先に見つかる Homebrew のものは、dconf の値ではなく既定値を返した（`idle-delay` が `uint32 300`、`lock-enabled` が `true`）。`/usr/bin/gsettings` は `uint32 0`・`false`（`guest-facts-start.txt` に両方ある）。[注意点](../extra/gnome-headless-session.md#注意点)に書いてあるとおり
- **ドライバ**: 51 行ある手順 3 のブロックを貼ると、ドライバが返す出力の中の、貼った文字の写しが崩れた（担当の報告による。確認の出力と実行の結果は正しく、貼った中身は `sha256` で確かめられる）
- **ゲスト**: `mcelog.service` が、起動のたびに failed になる

#### 手順書を直した所（2026-10-11）

通した後（`114c2b2` より後）に直した。どれも箇条書きの文言だけで、コードブロックは変えていない（手順 10 は、コマンドの無い手順）。VM で貼り直すものは無い。

- [手順書](../almalinux-setup.md#gnome-のヘッドレスセッション-実施手順)の手順 10: 「証明書の確認を聞かれたら…」の箇条書きの下に、入れ子の箇条書きを 3 つ足した（指摘 1）
  - FreeRDP は、`Thumbprint:` の後に `Do you trust the above certificate? (Y/T/N)` と聞く。同じなら `Y` で答える
  - FreeRDP は、初めてつなぐときも、その前に `REMOTE HOST IDENTIFICATION HAS CHANGED!` などの警告を出す。続く `Thumbprint:` で判断する
  - `Y` で答えた後は、同じクライアントからつなぎ直しても証明書の確認は出ず、`Domain:` から聞かれる
  - もとの 1 行（Windows のクライアントにもかかる文）は、変えていない
- 同じ手順 10: 「パスワードは手順 5 のもの…」の箇条書きの下に、Kerberos の `[ERROR]` の行が出ることがあり、デスクトップが出れば害は無い、という 1 行を足した（指摘 3）
- 同じ手順 10: 「問題があれば…`journalctl`…を見る」の箇条書きの下に、手順 9 を貼った時刻の `client authentication failure` などの行はプローブが残したもの、という 1 行を足した（指摘 4）
- 足した 5 つの文の元になった出力は、どれも、この通しの記録にある（クライアントの seq 10〜21 の `peer/session/session-001.raw` と、`grd-journal-full.txt`）
- [参考資料](../reference/gnome-headless-session.md)
  - 「実施手順 / 手順 10: 補足: FreeRDP の証明書の確認と、つなぐときの表示」を足した（証明書の保存先、`Y` の後は聞かれないこと、Kerberos の行。初めてでも警告が出る理由、`T`・`N` のときの動き、Kerberos の行が出る理由は、確かめていないと書いた）
  - 「実施手順 / 手順 9: 補足: TLS プローブ」に、プローブがデーモンのログに残す行のことを 1 行足した
  - 手順 9 の補足には、同じスクリプトが同じ行を残すと書いてある [gnome-remote-desktop.md の参考資料](../reference/gnome-remote-desktop.md#実施手順--手順-10-補足-tls-プローブとfreerdp-クライアントでの確かめ方)への案内を、手順 10 の補足には、Kerberos を設定していない環境で出る近い行が載っている [gnome-remote-desktop.md の検証記録](gnome-remote-desktop.md#常に出るが無害なログ)への案内を付けた

#### 報告と証跡が食い違っていた所（2026-10-11）

- **サーバーのログの `client authentication failure`**: 担当の報告は、`Message Integrity Check (MIC) verification failed!` と `client authentication failure` が出るのは「違う値のときだけ」と書く。証跡（`grd-journal-full.txt`）では、`client authentication failure` は 4 回出ている
  - 20:12:02（手順 9 のプローブ。TLS の後、認証せずに切る）、20:13:40（証明書を受け入れずに終わった `/auth-only`）、20:14:33（わざと違う値）、20:17:34（操作の誤りで、`Domain:` に `T`、パスワードが空）
  - `Message Integrity Check (MIC) verification failed!` と `SEC_E_MESSAGE_ALTERED` は、後ろの 2 回だけ。この付録は、証跡のほうで書いた
- **手順 3 の `openssl` の版**: 担当の報告は「Homebrew の 4.0.3 が使われた」と書く。根拠は、対話のシェルの `type -a openssl` の順と `openssl version` の出力で、証明書そのものからは、作った版は読めない（この付録は「解決される」と書いた）
- **つないでいるあいだの電卓のプロセス**: `facts-step10-connected.txt` の中の `pgrep -x gnome-calculator` は、名前が 15 文字を超えるという警告を出して、1 つも拾っていない。電卓が開いていたことは PNG で、切った後もプロセスが残ったことは `facts-step10-disconnected.txt` で読める
- **VM のコンソールの PNG**: 担当の報告は、VM のコンソールが終わりまで GDM のログイン画面のままだった根拠に、`screens/main-console-end.png`（20:21 JST に撮った）と `loginctl` を挙げる。この PNG は、ログイン画面だが、時計が `20:14` で、クライアントのログインの前の PNG（`screens/peer/login-20261011-111446-1-before.png`。20:14:46 JST に撮った）と sha256 が同じ
  - VM のログイン画面は、20:14 ごろから無操作の扱いだった（20:20:43 の `loginctl` が `c1 … greeter tty1 yes 6min ago`。`guest-facts-end.txt`）。Hyper-V の VM は、画面が消えているあいだに撮った PNG が、消える直前の絵のままになる（[初期設定の通しの記録](almalinux-setup.md#ハイパーバイザに左右された出力hyper-v)）。同じ事情とみるが、確かめていない
  - この付録の「GNOME にログインしていない」は、PNG ではなく、`loginctl` で書いた（始めも終わりも、seat0 にあるのは `c1 gdm seat0 … greeter tty1` だけで、このユーザーのセッションに seat0 のものは無い。`guest-facts-start.txt`・`guest-facts-end.txt`）

#### SELinux の拒否の数え直し（2026-10-11）

この付録と、同じ VM で続けて通した [claude-code-gui.md の検証記録の付録](claude-code-gui.md#付録-hyper-v-の-vm-で通した記録2026-10-11)の、両方にかかる。

- **通しの中の読みは、根拠にしない**: 担当は、2 つの通しの終わりに、ドライバとは別の SSH（`tools/side-ssh.sh`。`BatchMode` で、端末は無い）から `sudo -n ausearch -m avc -ts boot` を打ち、`<no matches>` を得た（`guest-facts-end.txt`。コマンドは、担当の報告による）
  - `--input-logs` を付けない `ausearch` は、標準入力が端末でないと、監査ログではなく標準入力を読む。標準入力がすぐ閉じれば、ログを見ないまま `<no matches>` を返す
  - 同じ日に、Samba と Syncthing の手順書を通した担当が見つけた（別の SSH から打った `ausearch` が 2 分止まった。追跡していない `.verification/campaign/hv/R3/result.md` の「4. 見つけた不具合」と `R3/facts-avc.txt`）。この VM で、`--input-logs` の有り無しを比べてはいない
- **後から、監査ログのファイルを数え直した**: 2026-10-11 12:44 UTC に、検証の司令塔（単位を担当に割り振る役。通した担当とは別）が、止めてあったこの VM（`vmv-hv-headless`）を起動し直して数えた。`type=AVC`・`type=USER_AVC`・`type=SELINUX_ERR` の行は、どれも 0 行。`getenforce` は `Enforcing`
  - 数え方: `sudo -n sh -c 'grep -h -c "^type=AVC" /var/log/audit/audit.log* | paste -sd+ | bc'` と、同じ形の `^type=USER_AVC`・`^type=SELINUX_ERR`（ファイルは `audit.log` と `audit.log.1` の 2 つ）。`sudo -n ausearch --input-logs -m AVC,USER_AVC,SELINUX_ERR` は `<no matches>` で、`denied` を含む行も無い
  - ログの範囲: 最初の記録が 2026-10-11 07:23:58 UTC（epoch 秒 `1791703438`。クローン元の VM を、初期設定の通しの始めに作って起動したころ。`.verification/campaign/hv/AS1/meta.json` の時刻は 07:24:02 UTC）、最後の記録が 12:44:54 UTC（`1791722694`。数え直した時刻）。この通し（11:10〜11:18 UTC）と、claude-code-gui.md の通し（11:19〜11:20 UTC）は、この範囲に入る
  - 証跡: 追跡していない `.verification/campaign/hv/AVC-recheck/vmv-hv-headless/avc.txt`（ゲストで打った行は、同じ `AVC-recheck/` の `remote.sh`）
- **確かめていない**: クライアントの VM（`vmv-hv-peer`）の監査ログは、数え直していない。通しの中でも、クライアントの SELinux は見ていない

#### 確かめていないこと（2026-10-11）

- クライアントの VM の SELinux の拒否（[数え直し](#selinux-の拒否の数え直し2026-10-11)は、主の VM だけ）
- Windows の「リモート デスクトップ接続」・Android のクライアント・実物の別のマシンからの接続（クライアントは、同じ仮想スイッチの AlmaLinux の VM の FreeRDP だけ）
- 手順 1 の `RDP_PORT` が 3390 になる側（システムのリモートログインが有効なとき）
- 手順 3 の「既にある証明書と鍵を使う」側と、`中断:` の側。TPM のある PC の `grdctl` の出力
- FreeRDP の証明書の確認に `T`・`N` で答えたとき。証明書を作り直した後の確認
- 再起動の後に、ヘッドレスのセッションと RDP の待ち受けが戻ること（この通しに、再起動は無い）
- 任意節「接続元を LAN に絞る」、節「リモートログインだけにする（併用をやめる）」、ロールバック
- 仮想モニターのドロップイン（claude-code-gui.md）を置いた後のセッションへの、RDP の接続（デーモンが `active` で、3389 を待ち受けていることまで）
- 放置したときの動き（ロック・サスペンド）。セッションの `LockedHint`・`IdleHint` を見たのは、作ってから 9 秒後と、作り直してから 1 分半後の 2 回だけ（どちらも `no`）
- VM を起動し直して、Default Switch の IP が変わったときの動き
- 手順 3・9 の `openssl` を `/usr/bin/openssl` にした形（指摘 2。直していない）
- 直した後の手順 10 の箇条書きを見ながらの通し（文言だけの直し。足した文の元になった出力は、この通しの記録にある）
- キーリングを開く窓、音、クリップボード、物理のモニターのある PC、実機

### 操作上の注意と併記されていた記録

  - seat0 には GDM のログイン画面が残り、Workstation で入れた PC ではそれも 15 分で PC を眠らせる（[gnome-power.md 手順 3 の補足](almalinux-setup.md#画面オフロックサスペンド-実施手順--手順-3-補足-ログイン画面の設定の置き場所とgdm-ユーザーで読む理由)）。サスペンドできる PC では、同書の手順 3・4 も行う（この Pi はサスペンドできないので、確かめていない）

## 参考資料から分離した記録

### 参考資料: 実施手順 / 手順 2: 補足: gnome-headless-session@.service と、セッションの見分け方

**gnome-headless-session@.service**:

- gdm の unit。`gdm` ユーザーで `gdm-new-session <USER> --headless` を動かし、GDM に、モニターの無いセッションを作らせる（RHEL 10 の文書の「1.4 headless server for a single user」と同じ unit）
- できるセッションは、`loginctl` で `Class=user`・`Type=wayland`・`TTY=headless`・`Remote=yes`・`Service=gdm-autologin`・seat 無し
- PAM は `gdm-autologin` で、パスワードを使わない。ログインのキーリングは開かない（[注意点](../extra/gnome-headless-session.md#注意点)）
- `WantedBy=graphical.target` なので、`enable` で起動時にも作られる。`Requires=gdm.service`
- 起動して 3 秒ほどで gnome-shell が動き、描画には GPU（Raspberry Pi 5 では `/dev/dri/renderD128` の v3d）を使った

**セッションの見分け方と、モニターが無い間**:

- `loginctl` の行の `awk` は、このユーザーのヘッドレスのセッションの行だけを出す。ほかのユーザーのヘッドレスのセッションも `TTY` が `headless` になる（検証では、`grep headless` にしていた版が、試験用のユーザーのセッションも数えた）
- このセッションには、RDP のクライアントがつないでいない間、モニターが 1 枚も無い。アプリはそのまま動き続ける
- クライアントがつなぐと、そのクライアントの窓の大きさの仮想モニターができ、切ると消える

### 参考資料: 実施手順 / 手順 3: 補足: 証明書

- 中身は [gnome-remote-desktop.md 手順 2](../almalinux-setup.md#gnome-のリモートログイン-実施手順) と同じ（SAN に IP を `DNS:` でも入れる理由も同書の補足）。違うのは、自分のホームに自分の所有で作ること
- RHEL の文書は `winpr-makecert` で作るが、ここでは SAN を付けるために openssl で作る
- `certificates` のディレクトリは、SELinux のラベルが `home_cert_t` になった。gnome-remote-desktop のユーザーのデーモンは `unconfined_t` で動き、Enforcing のまま読めた
- TLS のパスはデスクトップ共有と共用なので、最初に dconf の元値を `~/.local/state/gnome-headless-session-setup` に退避する。未設定だったキーは空ファイルになり、ロールバックでは `reset` で戻す
- 貼り直しても退避は上書きしない。`backup-complete` は退避完了、`ready` は証明書の準備完了、`created-certificate` はこの手順が新規生成したことの目印
- 新規生成したファイルの SHA-256 も `created.sha256` に保存する。ロールバックでは、中身が変わっていたりリンクへ置き換わっていたりすれば削除しない
- 既存の証明書を更新する手順ではない。以前の手順で残した `.old` なども、この手順とロールバックでは消さない
- `set -e` は丸括弧の中だけに効かせ、退避・生成・読み取りのどれかが失敗したら、そのブロックを止める

### 参考資料: 実施手順 / 手順 4: 補足: grdctl --headless

- `--headless` を付けた `grdctl` は、ヘッドレスのセッションのデーモン（`gnome-remote-desktop-headless.service`）の設定を変える
- 書き先は dconf。ポートなどは `/org/gnome/desktop/remote-desktop/rdp/headless/`、証明書と鍵は、デスクトップ共有と同じ `/org/gnome/desktop/remote-desktop/rdp/` に入った
- 資格情報（手順 5）は、TPM があれば TPM に、無ければ `~/.local/share/gnome-remote-desktop/credentials.ini`（GKeyFile）に置く。TPM の無い Raspberry Pi 5 では、`grdctl --headless` のどのコマンドも TPM のメッセージを出した
- `disable-port-negotiation` は、指定したポートが使われていたときに、次のポートを順に試すのを止める。ポートが勝手に変わって、手順 7 で開けたポートと食い違うのを防ぐ

### 参考資料: 実施手順 / 手順 5: 補足: 資格情報の置き場所

- TPM の無い PC では、`~/.local/share/gnome-remote-desktop/credentials.ini` に入る（0600。暗号化はされていない）
- このファイルは、`grdctl --headless status` を 1 度実行しただけでも、空のまま 0644 でできた。資格情報を書くと 0600 になった
- パスワードを変えるときも、この手順を貼り直す

### 参考資料: 実施手順 / 手順 6: 補足: grdctl --headless rdp enable

- `grdctl --headless rdp enable` は、`/org/gnome/desktop/remote-desktop/rdp/headless/enable` を true にし、ユーザーの unit `gnome-remote-desktop-headless.service` を enable して起動する（`~/.config/systemd/user/gnome-session.target.wants/` にリンクができる）。RHEL の文書の `systemctl --user enable --now gnome-remote-desktop-headless.service` は要らなかった
- unit は `WantedBy=gnome-session.target` なので、ヘッドレスのセッションと一緒に起動する

## 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

### 実施手順 / 手順 2

   - `for` の行で、gnome-shell のバス名と `loginctl` のセッションの両方が出るまで、30 秒まで待つ。バス名だけ先に出ることがあった（クリーンインストールした VM で確認）

### 補足

  - gnome-session のユーザーの unit（`gnome-session-manager@gnome.service` など）はユーザーに 1 組しか無いので、2 つ目のセッションは動かないはず（重なったときの動きは確かめていない）
