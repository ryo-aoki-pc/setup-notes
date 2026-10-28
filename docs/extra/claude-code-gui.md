# Claude Code の GNOME 操作の注意点

[手順書](../ai-agents.md#claude-code-の-gnome-操作-almalinux-10-で使う)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/claude-code-gui.md)・[参考資料](../reference/claude-code-gui.md)

- 「手順 N」は[手順書](../ai-agents.md#claude-code-の-gnome-操作-almalinux-10-で使う)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## 注意点

- **Homebrew が PATH の先頭にあると、GLib のコマンドが Homebrew のものになる**（[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)）
  - `python3` には `gi` が無い。`scripts/gnome-gui.py` は `#!/usr/bin/python3` で動く
  - `gsettings` は dconf ではなく `~/.config/glib-2.0/settings/keyfile` に書き、GNOME には効かないのに、読み戻すと変わったように見える。[AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順は `/usr/bin/gsettings` で書く
  - `gdbus` と `gio` も Homebrew のものになる。手で使うときは `/usr/bin/` を付ける
- **RDP でつないだ人には、Claude Code の画面は写らない**: [GNOME のヘッドレスセッション](../gnome-remote.md#gnome-のヘッドレスセッション) の RDP でつなぐと、この手順書の仮想モニター（`Meta-0`）の右に、クライアントの大きさの別のモニター（`Virtual remote monitor`）が足され、クライアントにはそちらが写る
  - 上部バーは主のモニター（`Meta-0`）にしか出ないので、クライアントの画面には上部バーが無かった
    - 同じドロップインを置いた試験用のユーザーで、FreeRDP で同じように入ると、クライアントには壁紙だけが写った（上部バーもウィンドウも無い）
  - ヘッドレスのセッションもやめてリモートログインだけにするなら、[GNOME のヘッドレスセッションの「リモートログインだけにする（併用をやめる）」](../gnome-remote.md#gnome-のヘッドレスセッション-リモートログインだけにする併用をやめる)でドロップインも外す
- **ドロップインは、このユーザーの GNOME のセッションすべてに効く**: 後からモニターをつないで、このユーザーで PC の画面からログインすると、見えない仮想モニターも足されるはず
- **ログインのキーリングは開いていない**: パスワードを読もうとするアプリは、キーリングを開く窓を出す。Claude Code には答えられない
- **手順 3 は、ユーザーの D-Bus も起動し直す**: GNOME のセッションが終わると、`gnome-session-restart-dbus.service` がユーザーのセッションバスを起動し直す
- **起動し直すのは `restart` ではなく、`stop` → 待つ → `start`**: `restart` では新しいセッションができなかった（参考資料を参照）
