# Samba サーバーの注意点

[手順書](../samba.md#samba-サーバー)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/samba.md)・[参考資料](../reference/samba.md)

- 「手順 N」は[手順書](../samba.md#samba-サーバー)の手順 N、「本書」「この文書」は手順書を指す

## 注意点

- **公開範囲は public ゾーンの全 NIC**: この環境では `wg0` も public にあるので、VPN 越しのクライアント（拠点 A の LAN や外出先の端末）からも 445 に届く。それを望まないなら[接続元を絞る](../samba.md#samba-サーバー-接続元を絞る)
- **LAN 上の通信は暗号化されない**: 署名だけ（`smbstatus` の `Encryption` 欄が `-`）
- **自ホストからの検証は firewalld を通らない**: 445 の開け忘れは、別ホストか network namespace から接続して初めて分かる
- **Samba のパスワードは OS と別**: OS のパスワードを変えても Samba 側は変わらない。変えるときは `sudo smbpasswd "${USER}"`
- **ユーザー名は OS アカウントと一致が必須**
  - 存在しないユーザー、間違ったパスワードは、どちらも `NT_STATUS_LOGON_FAILURE`
  - 他人のホーム（`//<SERVER_IP>/<別のユーザー>`。`[root]` を足していなければ `//<SERVER_IP>/root` も）は、認証が通っても `tree connect failed: NT_STATUS_ACCESS_DENIED`
- **root の共有は root と同じ重み**: [root のホームも公開した](../samba.md#samba-サーバー-root-のホームも公開する)ら、`<USER>` の Samba のパスワードで `/root/.bashrc` や `/root/.ssh/authorized_keys` を書き換えられる
- **`/home` の共有は、ほかのユーザーのホームも書ける**: [/home も公開した](../samba.md#samba-サーバー-home-も公開する)ら、`<USER>` の Samba のパスワードで、ほかのユーザーの `~/.bashrc` や `~/.ssh/authorized_keys` も書き換えられる。`sudo` を使えるユーザーがいれば、root と同じ重みになる
- **`create mask` を変えても既存ファイルのモードは変わらない**: 手順 3 の前にホームに置いていたファイルのモードはそのまま
- **`nmb` を起動しない構成なので、Windows のエクスプローラーで「ネットワーク」から見つけることはできない**: `\\<SERVER_IP>\<USER>` を直接入力する。一覧に出したいなら `wsdd`
- **クライアントにも、サーバーとは別の一覧のキャッシュがある**
  - GNOME Files（`smb://`）は、サーバーで変えたものを自動では出さない。F5 ですぐ出る（[Samba クライアント の注意点](samba-client.md#注意点)）
  - Windows は、ディレクトリのリースが無いときも、一覧を最長 10 秒キャッシュする（Microsoft の文書の `DirectoryCacheLifetime`）
  - macOS は、SMB 2/3 の一覧を手元にキャッシュする（Apple の文書。止めるには `nsmb.conf` の `dir_cache_max_cnt=0`）
