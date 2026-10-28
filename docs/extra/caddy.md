# Caddy（AlmaLinux 10 / ホストで共通に使う HTTPS）の注意点

[AlmaLinux 10 の「Caddy」](../almalinux-setup.md#caddy)・[参考資料](../reference/caddy.md)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/caddy.md)

- 「Caddy: … の手順 N」は正本のその項の手順。「この項の手順 N」はこの文書の項内の手順を指す
- 貼った後は、反転表示の「確認」から後ろを箇条書きで確かめる

## 注意点

- 共通の Caddy を止める・更新する・認証局を作り直す操作は、同じホストの全サイトに影響する。アプリ 1 つの停止・撤去では共通の Caddy と認証局を消さない
- `root.crt` は配布してよいが、**`root.key` は、読まない・写さない・人に渡さない**。この認証局を信頼する端末は、この認証局が署名した別のサイトの証明書も信頼する
- 認証局の鍵が漏れた疑いがある場合は、全端末から該当ルート証明書を外す。全サイトへの影響を確認した上で認証局を作り直し、新しい指紋を照合して全端末に入れ直す
- HTTPS の証明書を入れても公開範囲は狭まらない。各サイトの `bind` と firewalld の宛先・ポート・送信元を合わせる
