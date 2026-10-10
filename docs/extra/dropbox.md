# Dropbox 公式クライアント導入手順（AlmaLinux 10 / x86_64 / headless + systemd ユーザーサービス）のロールバックと注意点

[手順書](../dropbox.md)・[検証記録](../verification/dropbox.md)・[参考資料](../reference/dropbox.md)

- 「手順 N」は[手順書](../dropbox.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- 上から順に実行する
- 同期していたファイルはクラウドに残る。この PC の `~/Dropbox` を消すのは、この節の手順 4 だけ
- 手順 2 で作られた `~/.gnupg` は、ほかでも使うので消さない
- linger も切るときは、この節の後に [linger.md のロールバック](linger.md#ロールバック)を行う（ほかに linger を使うものが無いかは、そこで確かめる）

> [!CAUTION]
> **この節の**手順 4 で、`~/.dropbox`（リンクの情報）と `~/Dropbox`（この PC の複製）を消す。まだ同期していない変更があれば失われる。
>
> - **デーモンが動いている間に `~/Dropbox` を消すと、クラウドからも消える**。手順 4 は、デーモンが動いていれば `中断:` で止まる
> - 入れ直す可能性があるなら残す

1. サービスを止めて外す。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user disable --now dropbox.service
   rm -f ~/.config/systemd/user/dropbox.service
   systemctl --user daemon-reload
   ```

   - `Removed '.../default.target.wants/dropbox.service'.` が出る

1. ブラウザで Dropbox の Web を開き、この PC のリンクを解除する。

   - アカウントの設定 → セキュリティ → デバイス にある

1. デーモンと CLI を消す。

   ```bash
   rm -rf ~/.dropbox-dist ~/.local/bin/dropbox
   ```

1. 完全に消すときだけ、リンクの情報とこの PC の複製を消す（取り戻せない）。

   ```bash
   if pgrep -u "$(id -un)" -x dropbox >/dev/null; then echo '中断: Dropbox のデーモンがまだ動いている。この節の手順 1 を先に貼る' >&2; else
   rm -rf ~/.dropbox ~/Dropbox
   fi
   ```

---

## 注意点

- **Basic（無料）プランは同時に 3 台まで**: 公式クライアントは、そのうちの 1 台に数えられる（公式ヘルプ。dropbox.com へのログインは数えない）
- **リンクすると全部落ちてくる**: headless では、最初に同期するフォルダを選べない。要らないフォルダは、リンクした直後に `dropbox exclude add` で外す（[使い方の基本](../dropbox.md#使い方の基本)）
- **LAN 同期の受信は開けていない**: firewalld の定義済みサービス `dropbox-lansync`（17500/tcp・udp）は開けていない
  - LAN 内にほかの公式クライアントが無ければ要らない（Raspberry Pi 5 は rclone なので、LAN 同期に加わらない）
  - 使うなら `sudo firewall-cmd --permanent --add-service=dropbox-lansync` と `sudo firewall-cmd --reload`
- **`dropbox stop` は戻される**: `Restart=always` なので 10 秒後に起こし直される。止めるなら `systemctl --user stop dropbox.service`
- **リンク用の URL は他人に見せない**: 開いた人のアカウントにこの PC がつながる。リンクするまでは journal にも 5 秒ごとに残る
- **眠ると止まる**: サスペンド中は同期しない。常時動かす PC は [画面オフ・画面ロック・自動サスペンドを止める（任意）](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意) の節で眠らないようにする
- **フォルダの場所は `~/Dropbox` のまま**: headless の `dropbox` コマンドには、場所を移す機能が無い
