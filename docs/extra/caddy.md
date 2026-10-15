# Caddy（AlmaLinux 10 / ホストで共通に使う HTTPS）のロールバックと注意点

[AlmaLinux 10 の「Caddy」](../almalinux-setup.md#caddy)・[参考資料](../reference/caddy.md)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/caddy.md)

- 「Caddy: … の手順 N」は正本のその項の手順。「この項の手順 N」はこの文書の項内の手順を指す
- 貼った後は、反転表示の「確認」から後ろを箇条書きで確かめる

## ロールバック

### 共通の Caddy を撤去する

- 前提: [Forgejo のロールバック](forgejo.md#ロールバック)・[Codeg のロールバック](grok-build-remote.md#ロールバック)などで、すべてのサイトを外してある
- 実行場所: Caddy を動かす一般ユーザー自身の bash。`sudo` は使わない
- linger は共有前提なので、ここでは切らない。ほかに使うものが無いときだけ[linger のロールバック](linger.md#ロールバック)を使う

> [!CAUTION]
> **この項の手順 3** で認証局の鍵を消すと取り戻せない。接続する端末に入れたルート証明書は役に立たなくなる。すべてのサイトを撤去し、その認証局を使わなくなったと確かめてから進む。

1. すべてのサイトを外してあることを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   ls -la ~/.config/caddy/sites
   if compgen -G "$HOME/.config/caddy/sites/*.caddy" >/dev/null; then
     echo '中断: サイトが残っている。各アプリのロールバックを先に通す' >&2
   else
     echo 'サイト: 無し'
   fi
   ```

   - `サイト: 無し` が出ればよい。別の場所から読み込む設定を足していれば、そのサイトも先に外す

1. 共通のサービスを停止し、自動起動を外す。

   ```bash
   if compgen -G "$HOME/.config/caddy/sites/*.caddy" >/dev/null; then
     echo '中断: サイトが残っている' >&2
   elif ! grep -qx '# setup-notes: caddy' ~/.config/systemd/user/caddy.service; then
     echo '中断: この手順が作ったサービスではない' >&2
   else
     systemctl --user disable --now caddy.service &&
     rm ~/.config/systemd/user/caddy.service &&
     systemctl --user daemon-reload
     printf '\n\033[7m 確認 \033[0m\n'
     systemctl --user is-active caddy.service
     ss -ltnp | awk 'NR == 1 || /caddy/'
   fi
   ```

   - `inactive` で、この Caddy の待ち受けが無ければよい
   - 中断・停止失敗が出たら削除へ進まない

1. 本体・設定・認証局の鍵と証明書を削除する（取り戻せない）。

   ```bash
   if [ -e ~/.config/systemd/user/caddy.service ] ||
      systemctl --user is-active --quiet caddy.service || compgen -G "$HOME/.config/caddy/sites/*.caddy" >/dev/null; then
     echo '中断: サービスまたはサイトが残っている' >&2
   else
     rm -rf ~/.local/opt/caddy ~/.config/caddy ~/.local/share/caddy ~/.cache/caddy-dl
     printf '\n\033[7m 確認 \033[0m\n'
     ls -d ~/.local/opt/caddy ~/.config/caddy ~/.local/share/caddy ~/.cache/caddy-dl
   fi
   ```

   - 4 つとも `No such file or directory` ならよい
   - [端末からルート証明書を消す](#端末からルート証明書を消す)も通す

### 端末からルート証明書を消す

- 前提: このホストの認証局を使うサイトをすべて撤去してある。Windows の Codeg 専用 Caddy を撤去したときも、この項の同じ操作を使う
- 実行場所: 接続していた Android・Windows の PC

1. Android で、このホストのルート証明書を消す。

   - 設定の「信頼できる認証情報」→「ユーザー」で、`Caddy <ホスト名>`（Windows 11 の認証局は `Codeg <ホスト名>`）を開き、名前と控えた指紋を確かめて削除する
   - ほかのホストの証明書は消さない

1. Windows の PC で、このホストのルート証明書を消す。

   - 管理者ではない Windows PowerShell で `Get-ChildItem Cert:\CurrentUser\Root | Where-Object { $_.Subject -like 'CN=Caddy *' -or $_.Subject -like 'CN=Codeg *' }` を実行する
   - 消す証明書の `Subject` と `Thumbprint` を確かめ、「ユーザー証明書の管理」（`certmgr.msc`）の「信頼されたルート証明機関」で、その証明書だけを削除する

---

## 注意点

- 共通の Caddy を止める・更新する・認証局を作り直す操作は、同じホストの全サイトに影響する。アプリ 1 つの停止・撤去では共通の Caddy と認証局を消さない
- `root.crt` は配布してよいが、**`root.key` は、読まない・写さない・人に渡さない**。この認証局を信頼する端末は、この認証局が署名した別のサイトの証明書も信頼する
- 認証局の鍵が漏れた疑いがある場合は、全端末から該当ルート証明書を外す。全サイトへの影響を確認した上で認証局を作り直し、新しい指紋を照合して全端末に入れ直す
- HTTPS の証明書を入れても公開範囲は狭まらない。各サイトの `bind` と firewalld の宛先・ポート・送信元を合わせる
