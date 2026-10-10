# Samba でホームディレクトリを公開する手順（`[homes]` 共有 / smbd + firewalld）のロールバックと注意点

[手順書](../samba.md)・[検証記録](../verification/samba.md)・[参考資料](../reference/samba.md)

- 「手順 N」は[手順書](../samba.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す

## ロールバック

- 上から順に実行する
- 接続元を絞る節を使った場合は 445/tcp ではなく rich rule が入っているので、先に[接続元を絞る（任意）](../samba.md#接続元を絞る任意)の手順 2 を貼る

> [!CAUTION]
> `passdb.tdb` は Samba のパスワード DB（`smbpasswd` で登録したパスワードの保存先。[検証記録](../verification/samba.md)・[参考資料](../reference/samba.md)）。**この節の**手順 3 の「完全に消すなら」で消すと、中の登録は取り戻せない。

1. サービスを止め、ファイアウォール・Samba ユーザー・SELinux・smb.conf を元に戻す。

   ```bash
   {
     sudo umount /mnt/smbtest 2>/dev/null; sudo rmdir /mnt/smbtest 2>/dev/null   # 検証のマウントが残っていれば
     sudo systemctl disable --now smb.service
     sudo firewall-cmd --permanent --remove-port=445/tcp && sudo firewall-cmd --reload
     sudo smbpasswd -x "${USER}"
     sudo setsebool -P samba_enable_home_dirs off
     sudo cp -a /etc/samba/smb.conf.orig /etc/samba/smb.conf
   }
   ```

   - 公開したユーザー自身のシェルで貼る（`sudo -i` した root のシェルでは `${USER}` が `root` になる）
   - 並びは、`smbpasswd`（`samba-common-tools`）が消える前に Samba ユーザーを消すため
   - [root のホームも公開した](../samba.md#root-のホームも公開する任意)ときの `[root]` の節と、[/home も公開した](../samba.md#home-も公開する任意)ときの `[home]` の節も、最後の `smb.conf` の復元で消える

1. root のホームも公開していたときだけ、SELinux のモジュールを外す。

   ```bash
   sudo semodule -r samba_root_home
   ```

   - `libsemanage.semanage_direct_remove_key: Removing last samba_root_home module …` の 1 行が出て終わればよい

1. パッケージも消すときだけ、samba・samba-client・cifs-utils を消す。

   ```bash
   sudo dnf remove -y samba samba-client cifs-utils
   ```

   - `samba-common` は実施前から入っていたので残す
   - Workstation などで `cifs-utils` も実施前から入っていたなら、上のコマンドから `cifs-utils` を外す（ほかの共有のマウントにも使うため）
   - `dnf remove` 後も、`/var/lib/samba/private/passdb.tdb`（Samba のパスワード DB）と `/var/log/samba/` は残る
   - 完全に消すなら `sudo rm -rf /var/lib/samba/private/passdb.tdb /var/log/samba`（取り戻せない）

---

## 注意点

- **公開範囲は public ゾーンの全 NIC**: この環境では `wg0` も public にあるので、VPN 越しのクライアント（拠点 A の LAN や外出先の端末）からも 445 に届く。それを望まないなら[接続元を絞る](../samba.md#接続元を絞る任意)
- **LAN 上の通信は暗号化されない**: 署名だけ（`smbstatus` の `Encryption` 欄が `-`）。VPN 越しは WireGuard が暗号化する
- **自ホストからの検証は firewalld を通らない**: 445 の開け忘れは、別ホストか network namespace から接続して初めて分かる
- **Samba のパスワードは OS と別**: OS のパスワードを変えても Samba 側は変わらない。変えるときは `sudo smbpasswd "${USER}"`
- **ユーザー名は OS アカウントと一致が必須**
  - 存在しないユーザー、間違ったパスワードは、どちらも `NT_STATUS_LOGON_FAILURE`
  - 他人のホーム（`//<SERVER_IP>/<別のユーザー>`。`[root]` を足していなければ `//<SERVER_IP>/root` も）は、認証が通っても `tree connect failed: NT_STATUS_ACCESS_DENIED`
- **root の共有は root と同じ重み**: [root のホームも公開した](../samba.md#root-のホームも公開する任意)ら、`<USER>` の Samba のパスワードで `/root/.bashrc` や `/root/.ssh/authorized_keys` を書き換えられる
- **`/home` の共有は、ほかのユーザーのホームも書ける**: [/home も公開した](../samba.md#home-も公開する任意)ら、`<USER>` の Samba のパスワードで、ほかのユーザーの `~/.bashrc` や `~/.ssh/authorized_keys` も書き換えられる。`sudo` を使えるユーザーがいれば、root と同じ重みになる
- **`create mask` を変えても既存ファイルのモードは変わらない**: 手順 3 の前にホームに置いていたファイルのモードはそのまま
- **`nmb` を起動しない構成なので、Windows のエクスプローラーで「ネットワーク」から見つけることはできない**: `\\<SERVER_IP>\<USER>` を直接入力する。一覧に出したいなら `wsdd`
- **クライアントにも、サーバーとは別の一覧のキャッシュがある**
  - GNOME Files（`smb://`）は、サーバーで変えたものを自動では出さない。F5 ですぐ出る（[samba-client.md の注意点](samba-client.md#注意点)）
  - Windows は、ディレクトリのリースが無いときも、一覧を最長 10 秒キャッシュする（Microsoft の文書の `DirectoryCacheLifetime`）
  - macOS は、SMB 2/3 の一覧を手元にキャッシュする（Apple の文書。止めるには `nsmb.conf` の `dir_cache_max_cnt=0`）
