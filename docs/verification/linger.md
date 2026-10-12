# linger 有効化手順（AlmaLinux 10 / ログアウト中も自分のユーザーの systemd を動かす）の検証記録

[手順書](../almalinux-setup.md#ユーザーサービスの常駐-実施手順)・[ロールバックと注意点](../extra/linger.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 で、ログインしていない間も自分のユーザーの systemd（ユーザーのサービス・タイマー・Quadlet のコンテナ）を動かし続ける
- **進め方**: `loginctl enable-linger` を自分のユーザーに対して 1 度だけ行う。読者が編集する変数は無い
  - もとは [syncthing.md](../almalinux-setup.md#syncthing-実施手順)・[dropbox.md](../almalinux-setup.md#dropbox-実施手順)・[dropbox-rclone.md](../almalinux-setup.md#dropbox-と-rclone-実施手順)・[podman.md の Quadlet](../almalinux-setup.md#podman-quadlet-で自動起動する任意)の中にあった手順を、共有の前提として 1 本にした
- **状態**: **手順 2 の最初の 2 行は実機で本実行済み（2026-09-24）。現行の手順 1・2 とロールバックは、クリーンインストールした x86_64 の VM で本実行済み（2026-10-06）**
  - 2026-10-06: 先行検証とは別の新規 VM で現行本文を再検証した（[今回の記録](#付録-新規-vm-での現行手順の再検証2026-10-06)）。検証専用のアカウント・鍵・隔離 LAN を使った
  - 2026-10-11: Hyper-V の VM（AlmaLinux 10.2 / x86_64。Kickstart で入れた Workstation のクローンに、[AlmaLinux 10 の初期設定](../almalinux-setup.md)の実施手順を通した後の状態）で、`114c2b2` の手順 1・2 を、SSH の対話の bash に貼って通した（[付録](#付録-hyper-v-の-vm-で通した記録2026-10-11)）
    - 通らなかった手順は無い。手順 1 は `Linger=no`、手順 2 の後は `Linger=yes` と `<USER>`
    - 続けて通した [Podman の Quadlet の節](https://github.com/ryo-aoki-pc/setup-notes/blob/114c2b2bfd14b51f9e1925b150cbf72e1954f311/docs/podman.md#quadlet-で自動起動する任意)の再起動で、ユーザーの systemd と Quadlet のサービスが、最初のログイン（わざと遅らせた SSH）の 59 秒前に起動した
    - 未実施: [ロールバック](../extra/linger.md#ロールバック)（この通しの範囲の外）、手順 1 が `Linger=yes` を返して手順 2 を飛ばす側、実機、aarch64
  - 手順 2 のコマンドは、この文書に移す前に、次の検証でも通したもの
    - コンテナ: [dropbox.md](dropbox.md#付録-コンテナでの検証記録2026-09-27)・[dropbox-rclone.md](dropbox-rclone.md#付録-コンテナでの検証記録2026-09-27)（2026-09-27）、[podman.md](podman.md#付録-コンテナでの検証記録2026-09-27)（2026-09-27、Quadlet の節）
  - [ロールバック](../extra/linger.md#ロールバック)の手順 1 の 1 つ目の `ls` と手順 2 は、dropbox.md・dropbox-rclone.md のコンテナでの検証で通したもの（実機では未実行）
  - 2026-09-30 に、この文書のブロックを x86_64 のコンテナでもう一度通した（[付録](#付録-コンテナでの検証記録2026-09-30)）
    - 手順 1・2（手順 1 は `Linger=no` から）、[ロールバック](../extra/linger.md#ロールバック)
    - `podman.socket` を有効にしたときに、ロールバックの手順 1 の `ls` に何が出るか
  - 2026-10-02: もとの手順 2・3 をつないで `{ … }` で囲んだ（つないだ形は貼っていない。`bash -n` だけ）
  - **確認していないこと**: linger で、再起動の後にユーザーのサービスが起動すること（実機）。コンテナでは [podman.md の Quadlet](../almalinux-setup.md#podman-quadlet-で自動起動する任意) と [syncthing.md のバックアップの節](syncthing.md#付録-コンテナでのバックアップと復旧の検証2026-09-27)で、コンテナの再起動の後に起動した

| 項目 | 実機（syncthing.md） | 検証コンテナ（2026-09-30） |
|---|---|---|
| 実施日 | 2026-09-24 | 2026-09-30 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi） | AlmaLinux 10.2 / x86_64（`quay.io/almalinuxorg/10-init:10.2`、Docker 29.3.1） |
| systemd | 257 | 257（`systemd-257-23.el10_2.2.alma.1`） |
| linger | `Linger=no`（`/var/lib/systemd/linger/` は空）→ 有効 | 同左 |

> [!NOTE]
> 出力例の値は `<USER>` のプレースホルダで書いてある。読者が編集する変数は無い。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

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

### 付録: クリーンインストールした VM での検証（2026-10-06）

ISO から入れた AlmaLinux 10.2 Workstation の x86_64 VM で、一般ユーザーの SSH PTY に現行の手順 1・2 とロールバック 1・2 をブラケットペースト無しで貼った。

- 最初は `Linger=no`。手順 2 のひとまとまりのブロックで `Linger=yes` になり、`/var/lib/systemd/linger` に検証ユーザーのファイルができた
- この時点では独自のユーザーユニットは無く、ロールバック 1 の一覧は空だった。ロールバック 2 で `Linger=no` に戻り、同じ手順 2 で有効にし直せた
- 別のクリーン VM でも手順 1・2 を通し、Syncthing の Homebrew のユーザーサービスが SSH 切断後も稼働した
- 両 VM を再起動し、user manager と Syncthing が SSH の再ログインより前に起動した。サーバーでは設定バックアップの path/timer も同じ時刻に active だった。各起動時刻は [Syncthing の記録](syncthing.md#再起動更新ロールバック) に残した
- Syncthing とバックアップを外した後、サーバーではもう一度ロールバック 1・2 を通して `Linger=no` に戻った。相手 VM は Quadlet と RDP 検証のユーザーサービスがあるため linger を維持した

パスワード、SSH の使い捨て鍵、VM の名前はテスト専用。既存実機の linger は変えていない。

### 付録: 新規 VM での現行手順の再検証（2026-10-06）

同日の先行検証に使った VM と分け、ISO 導入直後の AlmaLinux 10.2 Workstation から新しい x86_64 VM を用意して、`5da3478` の現行本文を再検証した。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active。一般ユーザーの SSH PTY にブラケットペースト無しで貼り、手順ごとに結果を確認した。

新しいサーバー・相手 VM の両方で、手順 1・2 とロールバック 1・2 を通した。初期の `Linger=no` から yes、no、yes と切り替わった。ユーザーサービスが無いときのロールバック 1 の `ls` は表示無し・終了 2 で、ファイルが無い場合の想定どおりだった。

Syncthing と設定バックアップを導入して OS を再起動した。サーバーでは user manager と Syncthing が 14:00:45 JST、SSH セッションは 14:00:57。相手では user manager と Syncthing が 14:03:19、SSH は 14:03:28。いずれも SSH ログイン前に起動した。サーバーの backup path/timer も 14:00:44 に active だった。

ユーザーサービスとバックアップを外した後は、両 VM でロールバック 1・2 を通し、`Linger=no` に戻した。実機での再起動確認はこの VM 検証に含めていない。

### 付録: Hyper-V の VM で通した記録（2026-10-11）

- **何を**: [手順書](https://github.com/ryo-aoki-pc/setup-notes/blob/114c2b2bfd14b51f9e1925b150cbf72e1954f311/docs/linger.md)の実施手順の手順 1・2（コミット `114c2b2`）を、上から通した
  - [ロールバック](../extra/linger.md#ロールバック)は、この通しの範囲の外（流していない）
- **結果**: 2 手順とも通した。通らなかった手順・条件に当たらず飛ばした手順・未実施の手順は無い
- **どの状態から**: Hyper-V の VM（Kickstart で入れた AlmaLinux 10.2 の Workstation のクローン）に、[AlmaLinux 10 の初期設定](../almalinux-setup.md)の実施手順を通した後の状態（[その記録](almalinux-setup.md#付録-hyper-vvmwarevirtualbox-の-vm-で今の順番で通した記録2026-10-11)の Hyper-V の列の、スナップショット `after-AS4` の続き）
  - 直前に、同じ VM で、初期設定の任意節「画面オフ・画面ロック・自動サスペンドを止める（任意）」を通した（[その記録](almalinux-setup.md#付録-hyper-v-の-vm-で画面オフの任意節を通した記録2026-10-11)）
  - linger は無効だった（`Linger=no`。`/var/lib/systemd/linger` は空）
- **誰が・どう通したか**: Claude Code のサブエージェントが、手順書から抜き出したブロックを、SSH の対話の bash にブラケットペーストで 1 つずつ貼った（手順書の「デスクトップの端末か SSH」のうち、SSH の側）
  - 貼ったブロックは、手順書のものと 1 文字も違わない（`session/steps.jsonl` の `sha256` と `pastedSha256` が同じ。今の手順書のブロックとも、sha256 が同じ）
  - VM のコンソールは、同じユーザーで GNOME にログインした状態だった
  - sudo は NOPASSWD（初期設定の「ログインと sudo」の手順 3）で、パスワードは聞かれなかった
- 続けて、同じ VM で [Podman の手順書](https://github.com/ryo-aoki-pc/setup-notes/blob/114c2b2bfd14b51f9e1925b150cbf72e1954f311/docs/podman.md)を Quadlet の節まで通した（[Podman の検証記録の付録](podman.md#付録-hyper-v-の-vm-で通した記録2026-10-11)）。linger の効き目は、その節の再起動で見た
- **証跡**: 追跡していない `.verification/campaign/hv/CL1/`（このリポジトリには入っていない）。下のファイルの名前は、そこからの相対パス。`seq` は `session/steps.jsonl` の番号
- この VM の値は `<USER>` で書いた。パスワードと鍵は載せていない

#### 環境（Hyper-V、2026-10-11）

| 項目 | 内容 |
|---|---|
| ホスト | Windows 11 Pro 10.0.26300 |
| ハイパーバイザ | Hyper-V（第 2 世代の VM、VM の構成の版 12.0。`meta.json`） |
| VM | UEFI、Secure Boot オフ、2 vCPU、4096 MB、ディスク 64 GB、NIC 1 枚（`eth0`） |
| ゲスト | AlmaLinux 10.2 (Lavender Lion)、kernel `6.12.0-211.64.1.el10_2.x86_64`、x86_64、`systemd-257-23.el10_2.2.alma.1`、SELinux Enforcing、ロケール `ja_JP.UTF-8`。`systemd-detect-virt` は `microsoft` |
| 手順書 | `docs/linger.md`、コミット `114c2b2`（`114c2b2bfd14b51f9e1925b150cbf72e1954f311`） |
| 実施の日時 | 2026-10-11 10:49 UTC（ゲストの時計で 19:49 JST）。再起動は 10:52 UTC |
| 貼り方 | ドライバ（`rb.mjs paste`）で、SSH の対話の bash にブラケットペーストで 1 ブロックずつ。検証用に変えた値は無い |

#### 手順ごとの結果（Hyper-V、2026-10-11）

| 手順 | 判定 | 結果 | 根拠 |
|---|---|---|---|
| 1 | 通した | `Linger=no`（手順 2 へ進む側） | seq 15、`session/session-001.raw` |
| 2 | 通した | `enable-linger` は何も出さず、「確認」の後ろは `Linger=yes` と `<USER>` | seq 16、`session/after-confirm/0016-実施手順-2.txt` |

- 出力は、2 手順とも手順書の箇条書きのとおり。手順書どおりにいかなかった所は無い
- SSH から貼ったことで変わった出力は無い（手順書も SSH を認めている）
- Hyper-V に左右されたと思われる値は、この 2 手順の出力には無い

#### 再起動の後の起動（Hyper-V、2026-10-11）

手順書には、効き目を確かめる手順が無い。[Podman の Quadlet の節](https://github.com/ryo-aoki-pc/setup-notes/blob/114c2b2bfd14b51f9e1925b150cbf72e1954f311/docs/podman.md#quadlet-で自動起動する任意)の手順 3（再起動）・手順 4 を通したときに、別の SSH で読んだ（`quadlet-after-reboot.txt`・`facts-after-reboot.txt`）。

- 再起動のブロックを貼ったのは 19:52:17 JST（`session/session-001.raw` の、再起動の知らせの行の時刻）。起動し直した後の起動の時刻は 19:52:24（`quadlet-after-reboot.txt` の boot ID の次の行。`idle-check.txt` の journal の抜粋には 19:52:22 のカーネルの行があり、`last` の `reboot` の行は 19:52:26 で、数秒の幅がある）
- `<USER>` のユーザーの systemd と、logind の `manager` のセッション（Id 1）は 19:52:29 にできた。だれもログインしていない時点（コンソールは GDM のログイン画面で、それができたのは 19:52:40）
- 同じ 19:52:29 に、Quadlet のサービス `hello-web.service` が起動した（journal の `Starting hello-web.service` と `Started hello-web.service`）
- 再起動の後の最初のログインは、19:53:28 の SSH（手順 4 を貼った接続。前の接続が切れてから 70 秒後につなぎ直した。担当の報告では、「ログインより前」を意味のある差で見るために、わざと遅らせた）。logind のセッションは、Id 1 が `manager`、Id 2 が GDM、Id 3 がこの SSH。`last` も、`reboot` の行の次がこの SSH
- 再起動の後も `Linger=yes` で、`/var/lib/systemd/linger` に `<USER>` がある
- linger を有効にしないまま再起動したときとの比べは、この VM では行っていない

#### 指摘と状態（Hyper-V、2026-10-11）

- 手順書・[ロールバックと注意点](../extra/linger.md)・[参考資料](../reference/linger.md)への指摘は無い
- 手順書を直した所も無い

#### 確かめていないこと（Hyper-V、2026-10-11）

- ロールバック（`disable-linger` と、その前の `ls`）
- 手順 1 が `Linger=yes` を返して、手順 2 を飛ばす側
- デスクトップの端末（Ptyxis・WezTerm）に貼る形
- 実機、aarch64。今回は、VMware と VirtualBox の VM では通していない


### 実施手順 / 手順 2: 補足: linger が要る理由と、出力例

**linger が無いと、ログアウトした時点（SSH を切った時点）で、ユーザーのサービスも止まる。**

- ユーザーの systemd（`user@<UID>.service`）は、最後のログインのセッションが終わると止まり、その下で動くサービスやコンテナも一緒に止まる
  - [podman.md](../extra/podman.md#注意点) の検証では、linger の無いユーザーで `podman run -d` を動かしてログアウトすると、約 10 秒後にコンテナが止まった
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



### ロールバック / 手順 1: 補足: list-unit-files で判断しない理由と、出力例

- `systemctl --user list-unit-files --state=enabled` は、OS が既定で有効にしているユーザーのユニット（`dbus-broker.service` など。GNOME のデスクトップではさらに多い）まで出すので、自分で足したものを見分けにくい
- 自分で `enable` したものは `~/.config/systemd/user/<target>.wants/` のリンクになるので、そこだけを見る
- Quadlet の定義から作られるサービスは `enable` できず（[podman.md](../almalinux-setup.md#podman-quadlet-で自動起動する任意)）、`.wants/` にリンクができない。定義の置き場所を見る
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

