# linger 有効化手順（AlmaLinux 10 / ログアウト中も自分のユーザーの systemd を動かす）

## 実施手順

> [!IMPORTANT]
> - **常駐させるユーザー自身のシェル（デスクトップの端末か SSH）で実行する**。`sudo -i` した root のシェルでは行わない（`${USER}` が `root` になる）

- 上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 以後は[ロールバック](#ロールバック)
- 通すと使えるようになるもの（ログアウトしている間も動く）:
  - [Syncthing](syncthing.md)、[Dropbox（公式クライアント）](dropbox.md)、[Dropbox（rclone）](dropbox-rclone.md)
  - [Podman の Quadlet（任意）](podman.md#quadlet-で自動起動する任意)で動かすコンテナ

1. linger が有効になっているか確かめる。

   ```bash
   loginctl show-user "$(id -u)" -p Linger
   ```

   - `Linger=yes` が出れば、手順 2 は飛ばす（ほかの手順書で有効にしてある）
   - `Linger=no` と出たら、手順 2 で有効にする

1. linger が無効のときだけ、linger を有効にして、有効になったか確かめる。

   ```bash
   {
     sudo loginctl enable-linger "${USER}"
     loginctl show-user "$(id -u)" -p Linger
     ls /var/lib/systemd/linger
   }
   ```

   - linger を有効にすると、ログインしていない間もユーザーの systemd が動き続ける
   - `enable-linger` は何も出さない
   - `Linger=yes` と、自分のユーザー名が出ればよい

   <details>
   <summary>補足: linger が要る理由と、出力例</summary>

   **linger が無いと、ログアウトした時点（SSH を切った時点）で、ユーザーのサービスも止まる。**

   - ユーザーの systemd（`user@<UID>.service`）は、最後のログインのセッションが終わると止まり、その下で動くサービスやコンテナも一緒に止まる
     - [podman.md](podman.md#注意点) の検証では、linger の無いユーザーで `podman run -d` を動かしてログアウトすると、約 10 秒後にコンテナが止まった
   - `sudo loginctl enable-linger` は `/var/lib/systemd/linger/<USER>` を作る。PC の起動時からユーザーの systemd が動き、`enable` してあるユーザーのサービスも起動する
   - 設定はユーザーごとに 1 つなので、どの手順書で有効にしても同じ。2 回目に貼っても害は無い

   **出力例**: 検証のコンテナ（SSH でログインしたシェル）での出力:

   ```
   $ loginctl show-user "$(id -u)" -p Linger
   Linger=yes
   $ ls /var/lib/systemd/linger
   <USER>
   ```

   - 手順 1 の前は、`/var/lib/systemd/linger` は空だった（`ls` は何も出さない）
   - ほかのユーザーが linger を有効にしていれば、その名前も並ぶ

   </details>

---

## ロールバック

> [!WARNING]
> **linger を切ると、ログアウトしている間は、自分のユーザーのサービスがすべて止まる**（Syncthing・Dropbox・Quadlet のコンテナなど）。止まっていること自体は気付きにくい。

- linger を使う手順書（[Syncthing](syncthing.md#ロールバック)・[Dropbox](dropbox.md#ロールバック)・[Dropbox（rclone）](dropbox-rclone.md#ロールバック)・[Podman の Quadlet](podman.md#ロールバック)）のロールバックを先に行う
- この節の手順も、そのユーザー自身のシェルで貼る

1. ほかに自分で有効にしたユーザーのサービスと、Quadlet の定義が残っていないか見る。

   ```bash
   ls ~/.config/systemd/user/*.wants/ 2>/dev/null
   ls ~/.config/containers/systemd/ 2>/dev/null
   ```

   - どちらも何も出さなければ、この節の手順 2 で linger を切る
   - 1 つ目の `ls` が何か出す（Syncthing の `sh.brew.syncthing.service`、Dropbox（rclone）の `dropbox-rclone.timer` など）なら、linger はそれが使っているので、この節の手順 2 は飛ばす
   - 2 つ目の `ls` が何か出す（`hello-web.container` など）なら、[Podman の Quadlet](podman.md#quadlet-で自動起動する任意) のコンテナが linger を使っているので、この節の手順 2 は飛ばす
   - 1 つ目の `ls` が `podman.socket` だけを出すときは、linger を切ってよい（[podman.md 手順 7](podman.md#実施手順) の API ソケット。ログインしている間に使うもの）

   <details>
   <summary>補足: <code>list-unit-files</code> で判断しない理由と、出力例</summary>

   - `systemctl --user list-unit-files --state=enabled` は、OS が既定で有効にしているユーザーのユニット（`dbus-broker.service` など。GNOME のデスクトップではさらに多い）まで出すので、自分で足したものを見分けにくい
   - 自分で `enable` したものは `~/.config/systemd/user/<target>.wants/` のリンクになるので、そこだけを見る
   - Quadlet の定義から作られるサービスは `enable` できず（[podman.md](podman.md#quadlet-で自動起動する任意)）、`.wants/` にリンクができない。定義の置き場所を見る
   - 何も無ければ `ls` は何も出さない（終了コードは 0 のことも 2 のこともあったが、どちらでもよい）

   検証のコンテナで、`podman.socket` を有効にし、確かめ用のユーザーのサービスと Quadlet の定義を置いたときの出力:

   ```
   /home/<USER>/.config/systemd/user/default.target.wants/:
   dummy.service

   /home/<USER>/.config/systemd/user/sockets.target.wants/:
   podman.socket
   hello-web.container
   ```

   - `.wants/` のディレクトリが 1 つだけなら、見出しの行は出ず、中の名前だけが出る（`podman.socket` だけのときは `podman.socket` の 1 行）

   </details>

1. ほかにユーザーのサービスを常駐させていないときだけ、linger を切る。

   ```bash
   sudo loginctl disable-linger "${USER}"
   ```

   - 何も出さずに終わる。`loginctl show-user "$(id -u)" -p Linger` は `Linger=no` になる

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 で、ログインしていない間も自分のユーザーの systemd（ユーザーのサービス・タイマー・Quadlet のコンテナ）を動かし続ける
- **進め方**: `loginctl enable-linger` を自分のユーザーに対して 1 度だけ行う。読者が編集する変数は無い
  - もとは [syncthing.md](syncthing.md)・[dropbox.md](dropbox.md)・[dropbox-rclone.md](dropbox-rclone.md)・[podman.md の Quadlet](podman.md#quadlet-で自動起動する任意)の中にあった手順を、共有の前提として 1 本にした
- **状態**: **手順 2 の最初の 2 行（`sudo loginctl enable-linger` と `loginctl show-user`）は実機で本実行済み**（2026-09-24、aarch64 の Raspberry Pi の [syncthing.md](syncthing.md#対象と検証環境) の本実行の中で）
  - 手順 2 のコマンドは、この文書に移す前に、次の検証でも通したもの
    - コンテナ: [dropbox.md](dropbox.md#付録-コンテナでの検証記録2026-09-27)・[dropbox-rclone.md](dropbox-rclone.md#付録-コンテナでの検証記録2026-09-27)（2026-09-27）、[podman.md](podman.md#付録-コンテナでの検証記録2026-09-27)（2026-09-27、Quadlet の節）
  - [ロールバック](#ロールバック)の手順 1 の 1 つ目の `ls` と手順 2 は、dropbox.md・dropbox-rclone.md のコンテナでの検証で通したもの（実機では未実行）
  - 2026-09-30 に、この文書のブロックを x86_64 のコンテナでもう一度通した（[付録](#付録-コンテナでの検証記録2026-09-30)）
    - 手順 1・2（手順 1 は `Linger=no` から）、[ロールバック](#ロールバック)
    - `podman.socket` を有効にしたときに、ロールバックの手順 1 の `ls` に何が出るか
  - 2026-10-02: もとの手順 2・3 をつないで `{ … }` で囲んだ（つないだ形は貼っていない。`bash -n` だけ）
  - **確認していないこと**: linger で、再起動の後にユーザーのサービスが起動すること（実機）。コンテナでは [podman.md の Quadlet](podman.md#quadlet-で自動起動する任意) と [syncthing.md のバックアップの節](syncthing.md#付録-コンテナでのバックアップと復旧の検証2026-09-27)で、コンテナの再起動の後に起動した

| 項目 | 実機（syncthing.md） | 検証コンテナ（2026-09-30） |
|---|---|---|
| 実施日 | 2026-09-24 | 2026-09-30 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi） | AlmaLinux 10.2 / x86_64（`quay.io/almalinuxorg/10-init:10.2`、Docker 29.3.1） |
| systemd | 257 | 257（`systemd-257-23.el10_2.2.alma.1`） |
| linger | `Linger=no`（`/var/lib/systemd/linger/` は空）→ 有効 | 同左 |

> [!NOTE]
> 出力例の値は `<USER>` のプレースホルダで書いてある。読者が編集する変数は無い。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 選択した方針

- **ユーザーのサービス + linger にする**: 常駐させるものを、同期するファイルやコンテナの持ち主のユーザーで動かす。root も cron も要らない
  - 代わりに root が管理するシステムのサービス（Syncthing の `syncthing@<USER>.service` など）にすれば linger は要らないが、使う側の手順書はどれもユーザーのサービスにしている（[syncthing.md の選択した方針](syncthing.md#選択した方針)）
- **確認は `loginctl show-user` で行う**: `Linger=` の値は logind が持つ状態そのもの。`/var/lib/systemd/linger/<USER>` のファイルは、その記録
- **独立した手順書にした**: linger を使う手順書が 4 本になり、同じ有効化・確認・ロールバックの手順が各文書に重なっていたため

### 注意点

- **linger はユーザーごとに 1 つで、使う側の手順書で共有する**: どれか 1 本で有効にすれば、ほかの手順書では手順 1 で `Linger=yes` を確かめるだけでよい。切るのは、どれも使わなくなったときだけ（[ロールバック](#ロールバック)）
- **ログアウト中も動かすなら、PC を眠らせない**: linger はサスペンドを止めない（[gnome-power.md](gnome-power.md)。Workstation で入れた PC は、ログイン画面のまま 15 分で眠る）
- **`sudo -iu` で切り替えたシェルでは、`systemctl --user` が失敗する**: `XDG_RUNTIME_DIR` が無いため（[podman.md 手順 7](podman.md#実施手順) の補足）。常駐させるユーザーで、直接ログインしたシェルを使う

### 参照

- `man loginctl`（`enable-linger` / `disable-linger` / `show-user`）
- `man logind.conf`（`KillUserProcesses=`）/ `man user@.service`

---

### 付録: コンテナでの検証記録（2026-09-30）

**環境**: Ubuntu 24.04 / x86_64 のクラウドホスト上の Docker 29.3.1（cgroup v1）で、`quay.io/almalinuxorg/10-init:10.2`（`sha256:a91c1066…fd73`）を `--privileged`・`--network host` で立て、systemd を PID 1 で動かした。実機で加えた変更は無い。

**手順書の外で行った準備**（検証環境の都合）:

- イメージが mask している `systemd-logind` を戻し、`/var/log/journal` を作った（[dropbox.md の付録](dropbox.md#付録-コンテナでの検証記録2026-09-27)と同じ）
- プロキシの CA を信頼ストアに足し、dnf にプロキシを設定して、`openssh-server`・`sudo`・`podman` を入れた
- NOPASSWD の `sudo` を与えた非 root ユーザー（uid 1000）を作り、sshd を 2222 番で動かして、コンテナの中から鍵で SSH ログインした（logind のセッションができる）

**流し方**: この文書の bash のブロックをファイルから抜き出し、SSH でログインしたそのユーザーのシェルに流した。

| 手順 | 結果 |
|---|---|
| 1 | `Linger=no`（`/var/lib/systemd/linger` は空） |
| 2 | `sudo loginctl enable-linger` は無出力、終了コード 0。確かめの行（もとの手順 3）は `Linger=yes` と `<USER>` |
| ロールバック 1 | 何も置いていないときは、2 つの `ls` とも無出力（終了コード 2）。`systemctl --user enable --now podman.socket` の後は `podman.socket` の 1 行（`Created symlink '/home/<USER>/.config/systemd/user/sockets.target.wants/podman.socket'`）。確かめ用に `default.target.wants/` のリンクと `hello-web.container` を置くと、ロールバックの手順 1 の補足の出力になった |
| ロールバック 2 | 無出力、終了コード 0。`Linger=no` に戻り、`/var/lib/systemd/linger` は空になった |

#### 未確認事項

- 実機での手順 1 とロールバック
- 再起動の後に、linger でユーザーのサービスが起動すること（実機）
