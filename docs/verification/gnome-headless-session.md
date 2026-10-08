# GNOME のヘッドレスのセッションの手順（モニターの無い PC のデスクトップに RDP でつなぐ）の検証記録

[手順書](../gnome-headless-session.md)

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
    - 実施手順 1〜9 → 手順 10（別のセッションの FreeRDP で接続）→ [接続元を LAN に絞る（任意）](../gnome-headless-session.md#接続元を-lan-に絞る任意) → [ロールバック](../gnome-headless-session.md#ロールバック)の手順 2〜5
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
    - 同じ日に、試験用のユーザーとコンテナの FreeRDP 3.10.3 で、3390 と 3389 の同時の接続と GDM の再起動を確かめた（[同書の付録の追加の確認](gnome-remote-desktop.md#追加の確認)。[注意点](../gnome-headless-session.md#注意点)）
  - 2026-10-02: もとの手順 2・3 と、[ロールバック](../gnome-headless-session.md#ロールバック)のもとの手順 5・6 をつなぎ、確かめの行を `if … fi` の `else` に入れた（つないだ形は貼っていない。`bash -n` だけ）
  - 2026-10-05: 手順 3・4 とロールバックの手順 3・4 に、共用 TLS 設定の退避・復元と、新規生成した証明書だけの削除を追加した。構文検査と一時ディレクトリ・スタブでの確認だけで、実機の RDP では流していない

| 項目 | 値 |
|---|---|
| 実施日 | 2026-10-01 |
| 機械 | Raspberry Pi 5 Model B（aarch64、メモリ 8 GB）。HDMI は 2 つとも `disconnected`（モニター無し） |
| OS | AlmaLinux 10.2 (Lavender Lion)、カーネル `6.12.96-20260724.v8.1.el10`、SELinux Enforcing |
| GNOME | `gdm-47.0-24.el10_2`、`gnome-shell-49.4-9.el10_2.alma.1`、`mutter-49.4-4.el10_2`、`gnome-session-46.0-11.el10`、`gnome-remote-desktop-49.3-4.el10_2` |
| そのほか | `firewalld-2.4.3-4.el10_2`、`openssl-3.5.8-1.el10_2.alma.1`、`sudo-1.9.17-10.p2.el10_2.6`（このユーザーは NOPASSWD）。リモートログイン（システムのデーモン）が有効 |
| クライアント | `freerdp-3.10.3-12.el10_2.11`（AlmaLinux 10 のコンテナ。同じ Pi の、試験用のユーザーのヘッドレスのセッションに描いた。[付録](#付録-実機での検証記録2026-10-01)） |


> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../gnome-headless-session.md#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${SERVER_IP}` | クライアントが接続に使う PC の IP アドレス | `192.168.10.100` |
> | `${SERVER_NAME}` / `${SERVER_FQDN}` | PC のホスト名 / FQDN（`hostname` / `hostname -f` から自動で入る） | `my-pc` / `my-pc.lan` |
> | `${RDP_PORT}` | RDP で待ち受けるポート（リモートログインのデーモンが有効なら 3390、無ければ 3389。自動で入る） | `3390` |
> | `${LAN_SUBNET}` | LAN のサブネット。[接続元を LAN に絞る](../gnome-headless-session.md#接続元を-lan-に絞る任意)ときだけ、その節で設定する | `192.168.10.0/24` |
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

  - リモートログイン（[gnome-remote-desktop.md](../gnome-remote-desktop.md)）のログイン画面から同じユーザーで入ると、新しいセッションは作られず、このセッションに引き渡された（2026-10-02。同書の[注意点](../gnome-remote-desktop.md#注意点)）

### 注意点 / 手順 0: 本文中の記録

  - 起動し直しが前のセッションの片付けとぶつかると、新しいセッションはすぐ終わる（2026-10-02 に、2 つのうち 1 つで起きた）

### 付録: 実機での検証記録（2026-10-01）

**環境**: [対象と検証環境](#対象と検証環境)の表の Raspberry Pi 5。前提の gnome-power.md 手順 1・2 は済ませてあった。

**クライアントの作り方**（検証の都合。手順書では要らない）:

- 同じ Pi に試験用のユーザーを作り、そのユーザーにもヘッドレスのセッションを起動した。そのセッションには、[claude-code-gui.md](../claude-code-gui.md) と同じドロップインで 1600x900 の仮想モニターを付けた
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


### 操作上の注意と併記されていた記録

  - seat0 には GDM のログイン画面が残り、Workstation で入れた PC ではそれも 15 分で PC を眠らせる（[gnome-power.md 手順 3 の補足](almalinux-setup.md#画面オフロックサスペンド-実施手順--手順-3-補足-ログイン画面の設定の置き場所とgdm-ユーザーで読む理由)）。サスペンドできる PC では、同書の手順 3・4 も行う（この Pi はサスペンドできないので、確かめていない）

## 参考資料から分離した記録

### 参考資料: 実施手順 / 手順 2: 補足: gnome-headless-session@.service と、セッションの見分け方

**gnome-headless-session@.service**:

- gdm の unit。`gdm` ユーザーで `gdm-new-session <USER> --headless` を動かし、GDM に、モニターの無いセッションを作らせる（RHEL 10 の文書の「1.4 headless server for a single user」と同じ unit）
- できるセッションは、`loginctl` で `Class=user`・`Type=wayland`・`TTY=headless`・`Remote=yes`・`Service=gdm-autologin`・seat 無し
- PAM は `gdm-autologin` で、パスワードを使わない。ログインのキーリングは開かない（[注意点](../gnome-headless-session.md#注意点)）
- `WantedBy=graphical.target` なので、`enable` で起動時にも作られる。`Requires=gdm.service`
- 起動して 3 秒ほどで gnome-shell が動き、描画には GPU（Raspberry Pi 5 では `/dev/dri/renderD128` の v3d）を使った

**セッションの見分け方と、モニターが無い間**:

- `loginctl` の行の `awk` は、このユーザーのヘッドレスのセッションの行だけを出す。ほかのユーザーのヘッドレスのセッションも `TTY` が `headless` になる（検証では、`grep headless` にしていた版が、試験用のユーザーのセッションも数えた）
- このセッションには、RDP のクライアントがつないでいない間、モニターが 1 枚も無い。アプリはそのまま動き続ける
- クライアントがつなぐと、そのクライアントの窓の大きさの仮想モニターができ、切ると消える

### 参考資料: 実施手順 / 手順 3: 補足: 証明書

- 中身は [gnome-remote-desktop.md 手順 2](../gnome-remote-desktop.md#実施手順) と同じ（SAN に IP を `DNS:` でも入れる理由も同書の補足）。違うのは、自分のホームに自分の所有で作ること
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
