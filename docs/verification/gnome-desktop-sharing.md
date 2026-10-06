# GNOME のデスクトップ共有の手順（PC の画面のデスクトップに RDP でつなぐ。CLI だけで設定する）の検証記録

[手順書](../gnome-desktop-sharing.md)

## 補足

### 対象と検証環境

- **目的**: PC の画面で GNOME にログインしているユーザーのデスクトップを、別のマシンの RDP クライアントから共有して使う。設定は、そのユーザーの SSH のシェルから CLI だけで行う
- **方式**: ユーザーのモードの gnome-remote-desktop（オプション無しの `grdctl`、ユーザーの `gnome-remote-desktop.service`）。RHEL 10 の文書の「1.1 Enabling desktop sharing on the server by using GNOME」と同じ仕組みを、設定アプリの代わりに `grdctl` で設定する
- **状態**: **実機でも VM でも流していない（未検証。2026-10-06 に書いた）**
  - 書いた環境は、KVM の無いクラウドの Linux のコンテナ（Ubuntu 24.04、x86_64）。QEMU の TCG で AlmaLinux 10.2 の GenericCloud に Workstation のパッケージを入れる VM を用意し始めたが、`dnf upgrade` の途中で、利用者の判断で VM での検証を見送った。VM では手順書のブロックを 1 つも貼っていない
  - 確かめたこと（[付録](#付録-資料とブロックの確認2026-10-06)）
    - 上流の gnome-remote-desktop 49.3 のソース・README と、AlmaLinux の `gnome-remote-desktop-49.3-4.el10_2` の spec（パッチがデスクトップ共有のふるまいを変えないこと）
    - gnome-shell 49.4（ロック画面で画面の共有を止めること）、gnome-control-center 47.7（同じキーリングの項目と証明書のパスを使うこと）、libsecret 0.21.2・gnome-keyring 42.1 のソース
    - RHEL 10 の文書の 1.1・1.3・1.4
    - 手順書の bash のブロック 24 個が `bash -n` を通ること
    - [自動ログインで使う（任意）](../gnome-desktop-sharing.md#自動ログインで使う任意)の手順 1・2 と、同節の手順 7 の `busctl` の行を、AlmaLinux 10.2 のコンテナの gnome-keyring と grdctl で模擬したこと（PC の画面も GDM も無い）
  - 確かめていないこと
    - 実施手順のすべて（PC の画面のセッションでの `grdctl` の設定・資格情報の保存・有効化・ファイアウォール・待ち受け・TLS のプローブ・クライアントからの接続）
    - 任意節（見るだけにする・接続元を LAN に絞る・自動ログイン）を GNOME のセッションで流すこと。自動ログインの後に、PC の画面にキーリングの窓が出ずにつながること
    - ロールバック
    - ロックと無操作で接続が切れること、再起動とログインの後の自動起動、リモートログインやほかのユーザーのヘッドレスのセッションとの併用、Windows などのクライアント
- 下表は、手順書が対象にする版（AlmaLinux 10.2 の AppStream と BaseOS にある 2026-10-06 の最新。コンテナの `dnf repoquery` と `rpm -q` で確かめた）

| 項目 | 値 |
|---|---|
| OS | AlmaLinux 10.2 (Lavender Lion)、GNOME の Workstation |
| GNOME | `gnome-remote-desktop-49.3-4.el10_2`、`gnome-shell-49.4-9.el10_2.alma.1`、`mutter-49.4-4.el10_2`、`gdm-47.0-24.el10_2`、`gnome-session-46.0-11.el10`、`gnome-control-center-47.7-7.el10` |
| キーリング | `gnome-keyring-42.1-20.el10`、`libsecret-0.21.2-8.el10`、`glib2-2.80.4-12.el10_2.22`、`python3-gobject-base-3.46.0-7.el10` |
| そのほか | `firewalld-2.4.3-4.el10_2`、`openssl-3.5.8-1.el10_2.alma.1` |
| クライアント | 想定は AppStream の `freerdp-3.10.3-12.el10_2.13`（`xfreerdp`）と、Windows の「リモート デスクトップ接続」 |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../gnome-desktop-sharing.md#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${SERVER_IP}` | クライアントが接続に使う PC の IP アドレス | `192.168.10.100` |
> | `${SERVER_NAME}` / `${SERVER_FQDN}` | PC のホスト名 / FQDN（`hostname` / `hostname -f` から自動で入る） | `my-pc` / `my-pc.lan` |
> | `${RDP_PORT}` | RDP で待ち受けるポート（リモートログインのデーモンが有効なら 3390、無ければ 3389。自動で入る） | `3389` |
> | `${LAN_SUBNET}` | LAN のサブネット。[接続元を LAN に絞る](../gnome-desktop-sharing.md#接続元を-lan-に絞る任意)ときだけ、その節で設定する | `192.168.10.0/24` |
>
> 出力例・ログの中の値は `<HOSTNAME>` / `<SERVER_IP>` / `<RDP_PORT>` / `<USER>` / `<UID>` / `<SESSION_ID>` / `<N>` のプレースホルダで書いてある。`<...>` を含むコマンドは bash のコードブロックには置かない。

### 実施前の状態

- 記録は無い（実機でも VM でも流していない）

### 完了時点の状態

- 記録は無い（実機でも VM でも流していない）
- 手順書の確認の箇条書きにある出力（`grdctl status` の行、`ss` の `users:(("gnome-remote-de",…))` など）は、上流のソースから書いたもので、実物の出力ではない

### 付録: 資料とブロックの確認（2026-10-06）

**ソースと文書**:

- 上流 49.3 の `src/grd-ctl.c`: オプション無しの `grdctl` は `GRD_RUNTIME_MODE_SCREEN_SHARE`。`rdp enable` は `/usr/libexec/gnome-remote-desktop-enable-service <PID> user true` を動かし、セッションの systemd に `gnome-remote-desktop.service` の StartUnit と EnableUnitFiles を頼む。`status` の `View-only:` はこのモードだけに出る
- 上流 49.3 の `src/org.gnome.desktop.remote-desktop.gschema.xml.in`: `view-only` の既定は true、`negotiate-port` は true、`port` は 3389、`screen-share-mode` は `mirror-primary`。ヘッドレスの schema（`rdp/headless/`）にあるのは `port`・`negotiate-port`・`enable` だけで、`tls-cert`・`tls-key` は共用
- 上流 49.3 の `src/grd-settings.c` と `src/grd-credentials-libsecret.c`: デスクトップ共有の資格情報は libsecret の既定のコレクションに、schema `org.gnome.RemoteDesktop.RdpCredentials` で置く
- 上流 49.3 の `data/gnome-remote-desktop.service.in`（`WantedBy=gnome-session.target`）と `data/gnome-remote-desktop-headless.service.in`（`Conflicts=gnome-remote-desktop.service`）
- gnome-shell 49.4 の `js/ui/main.js`・`js/ui/sessionMode.js`・`js/ui/screenShield.js` と mutter 49.4 の `meta-dbus-session-manager.c`: ロック画面のモードでは `inhibit_remote_access` が呼ばれ、リモートのセッションが閉じられる。無操作のシールドも同じモードに入る
- AlmaLinux の `gnome-remote-desktop.spec`（`imports/c10/gnome-remote-desktop-49.3-4.el10_2`）のパッチは、VNC の暗号化・接続の数の制限・マルチタッチ・ヘッドレスとリモートログインの受け渡しで、デスクトップ共有の設定と資格情報の置き場所は変えない
- RHEL 10 の文書の 1.1 は設定アプリでの操作だけで、CLI の手順は無い。リモートログインと併用するとポートが 3390 になることは書いてある

**ブロックの構文と、部品の確かめ**:

- 手順書の `bash` のブロック 24 個を抜き出し、ホスト（Ubuntu 24.04 の bash 5.2）の `bash -n` にかけた。どれも通った
- `gdm-47.0-24.el10_2` の RPM の `/etc/gdm/custom.conf` には `[daemon]` の行がある。その写しに、[自動ログインで使う（任意）](../gnome-desktop-sharing.md#自動ログインで使う任意)の手順 3 と同節の手順 7 の `sed` をかけ、`[daemon]` の直後に 2 行が入り、消すと元に戻ることを確かめた（コンテナの GNU sed）
- コンテナの dconf 0.40.0 で、`grdctl rdp set-port 3390` の後の `dconf read …/rdp/port` が `uint16 3390` になり、その文字列を `dconf write` で書き戻せ、`dconf reset` で読み出しが空に戻ることを確かめた（[ロールバック](../gnome-desktop-sharing.md#ロールバック)の手順 3 の戻し方）。`/usr/bin/gsettings list-recursively org.gnome.desktop.remote-desktop.rdp` は `port uint16 3389` の形で出す

**自動ログインの節のキーリングの操作の模擬**:

- 環境: `quay.io/almalinuxorg/almalinux:10.2` のコンテナに、`gnome-keyring-42.1-20.el10`・`libsecret-0.21.2-8.el10`・`python3-gobject-base-3.46.0-7.el10`・`gnome-remote-desktop-49.3-4.el10_2` を入れた。一般ユーザーで `dbus-run-session` の中に gnome-keyring-daemon（secrets）を立てた。systemd・GNOME のセッション・GDM・gcr の窓は無い
- 用意: `gnome-keyring-daemon --unlock` で、パスワード付きのログインのキーリングを作って開き、`secret-tool store` で、`grdctl rdp set-credentials` と同じ形の項目（schema・ラベル・GVariant の値）を置いた
- 手順書の初めの版（ログインのキーリングの項目を残して、パスワードの無いキーリングへ写すだけ）では、デーモンを立て直してパスワード無しで起こすと、写したキーリングも `Locked` が `b true` で、`secret-tool lookup` は何も返さなかった
  - 写したキーリングのファイルは、暗号化されない文字のファイル（`~/.local/share/keyrings/rdp.keyring`）だった
  - 写したキーリングだけを `Unlock` すると、窓（prompt）無しで `b false` になり、`secret-tool lookup` が値を返した
  - ログインのキーリングのパスワードを空にした場合も、起こした直後は `b true` で、`Unlock` は窓無しで通った
  - libsecret は、同じ属性の項目が閉じたキーリングにしか無いと、それらを開こうとする。ログインのキーリングの項目が残っていると、そのキーリングを開く窓が要る、と判断した
- 直した版（写した後に、ログインのキーリングの項目を消す）で、次を確かめた
  - 手順 1 で `移した先: /org/freedesktop/secrets/collection/rdp/1`、貼り直すと `すでに移してある:`
  - 手順 2 で `aoao 1 "/org/freedesktop/secrets/collection/rdp/1" 0` と `b false`
  - デーモンを立て直してパスワード無しで起こした後に、`grdctl status` が `Username: (hidden)`・`Password: (hidden)` を出した（grdctl 自身の libsecret の読み出し）。続けて、ログインのキーリングは `b true`、移したキーリングは `b false`
  - 同節の手順 7 の `Collection.Delete` で `o "/"` が出て、`rdp.keyring` が消えた
- この模擬で確かめていないこと: GDM の自動ログイン、GNOME のセッションの中の gnome-keyring（PAM の `pam_gnome_keyring` が起こすもの）、gnome-remote-desktop のデーモンが接続のときに読み出すこと、PC の画面に窓が出ないこと

---
