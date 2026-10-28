# GNOME のヘッドレスセッションの注意点

[手順書](../gnome-remote.md#gnome-のヘッドレスセッション)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/gnome-headless-session.md)・[参考資料](../reference/gnome-headless-session.md)

- 「手順 N」は[手順書](../gnome-remote.md#gnome-のヘッドレスセッション)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## 注意点

- **Homebrew が PATH の先頭にあると、`gsettings`・`gdbus`・`gio`・`python3` が Homebrew のものになる**（[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)）。前提の[画面オフ・画面ロック・自動サスペンドを止める](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める)の手順は `/usr/bin/gsettings` で書いてある（Homebrew の `gsettings` は GNOME に効かない）
- **同じユーザーの GNOME のセッションは 1 つにする**: PC の画面から同じユーザーで入るときは、先に `sudo systemctl stop gnome-headless-session@<USER>.service` でヘッドレスのセッションを止める
  - gnome-session のユーザーの unit（`gnome-session-manager@gnome.service` など）はユーザーに 1 組しか無いので、2 つ目のセッションは動かないはず
  - このセッションにつなげるのは 1 つだけ。3390 とリモートログインから同時につなぐと、後からつないだ方が残り、先の接続は切られた（どちらが先でも同じ）
  - PC の画面のセッションを共有する[デスクトップ共有](../gnome-remote.md#gnome-のデスクトップ共有)とは、同じユーザーでは併用できない（ヘッドレスの RDP のデーモンの unit に `Conflicts=gnome-remote-desktop.service` がある）
- **リモートログインのセッションも、`loginctl list-sessions` の `TTY` の列は `headless` になる**: ヘッドレスのセッションと見分けるときは、`loginctl show-session` の `Service` が `gdm-autologin`（ヘッドレス）か `gdm-password`（リモートログイン）かで見る
  - [手順 2](../gnome-remote.md#gnome-のヘッドレスセッション) の確かめの行は `TTY` の列だけで見るので、同じユーザーのリモートログインのセッションがあると、ヘッドレスのセッションができる前に抜けるはず（確かめていない）
- **起動し直すときは `stop` → 待つ → `start` を使う**。前のセッションの片付けを待ってから新しいセッションを始める
- **GDM を再起動すると、このセッションも止まって起動し直される**（`Requires=gdm.service`）
  - GDM を再起動したら `systemctl is-active gnome-headless-session@<USER>.service` を見て、`inactive` なら `sudo systemctl start gnome-headless-session@<USER>.service` で起動する
- **セッションを止めると、ユーザーの D-Bus が起動し直される**: GNOME のセッションが終わると、`gnome-session-restart-dbus.service` がユーザーのセッションバスを起動し直す
- **ログインのキーリングは開いていない**: パスワード無しで作るセッションなので、キーリング（`login`）はロックされたまま。パスワードを読もうとするアプリは、キーリングを開く窓を出す
- **サスペンドとロック**: ヘッドレスのセッションでも gsd-power は動き、既定では 15 分の無操作で PC をサスペンドしようとする。前提の[画面オフ・画面ロック・自動サスペンドを止める](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める)の手順 1・2 で止める
  - seat0 には GDM のログイン画面が残り、Workstation で入れた PC ではそれも 15 分で PC を眠らせる。サスペンドできる PC では、[画面オフ・画面ロック・自動サスペンドを止める](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める)の手順 3・4 も行う
- **リモートログインを有効にしている PC**: セッションの中で `gnome-remote-desktop-handover.service` も起動する（リモートログインの受け渡し役。TCP では待ち受けない）
  - リモートログインのデーモン（`gnome-remote-desktop.service`）を起動し直したら、この受け渡し役のデーモンも再起動する（[GNOME のリモートログインの「デーモンを起動し直す」](../gnome-remote.md#gnome-のリモートログイン-デーモンを起動し直す)の手順 2）。しないと、リモートログインからこのセッションへ渡せなくなるはず
- **自己署名証明書**: クライアントは初回に証明書の確認を出す。証明書を作り直したら、クライアントで保存済みの証明書を消すか、変更の警告を承認する（gnome-remote-desktop.md の注意点と同じ）
- **資源**: セッションを起動すると、`free` の `available` が約 600 MB 減った（Raspberry Pi 5、アプリを開いていないとき）
