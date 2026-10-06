# Flatpak / Flathub 導入手順（AlmaLinux 10）

## 実施手順

- [検証記録](verification/flatpak.md)・[参考資料](reference/flatpak.md)

> [!IMPORTANT]
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（アプリは `sudo` でシステム全体に入れるが、起動は自分のユーザーで行う）
> - **手順 6 には対話入力がある**（確認が 2 回）。完了してから手順 7 を貼る

- 上から順にコードブロックを貼る
- 手順の後: [ツール一覧](tool-catalog.md#gui)の「Flathub」の行にある GUI アプリが入れられるようになる。日々の操作は[使い方の基本](#使い方の基本)、以後は[更新](#更新)・[ロールバック](#ロールバック)
- [Firefox](firefox.md) と [VS Code](vscode.md) は Flathub を使わず RPM で入れている（理由はそれぞれの「選択した方針」）

1. flatpak が入っているか確かめる。

   ```bash
   rpm -q flatpak || echo 'flatpak は未導入'
   ```

   - バージョンが出れば、手順 2 は飛ばす
   - `flatpak は未導入` と出たら、手順 2 で入れる

1. flatpak が未導入のときだけ、AppStream から入れる。

   ```bash
   sudo dnf install -y flatpak
   ```

1. flatpak のバージョンと、登録されているリモートを確かめる。

   ```bash
   flatpak --version
   flatpak remotes --show-details
   ```

   - `Flatpak 1.16.0` のように出る
   - **入れた直後は `flatpak remotes` が `error: While opening repository /var/lib/flatpak/repo: ...` を出すが、壊れているわけではない**。リモートがまだ無いだけ
   - 何も出ない場合も、リモートが無い状態
   - **`flathub` の行が既にあれば、手順 5 は何もしない**（`--if-not-exists` のため）

1. Flathub の登録ファイルに埋め込まれた公開鍵の fingerprint を確かめる。

   ```bash
   curl -fsSL https://dl.flathub.org/repo/flathub.flatpakrepo | sed -n 's/^GPGKey=//p' | base64 -d | gpg --show-keys --with-fingerprint
   ```

   - 次の値と一致することを目で確かめる
     - `6E5C 05D9 79C7 6DAF 93C0 8135 4184 DD4D 907A 7CAE`（Flathub Repo Signing Key &lt;flathub@flathub.org&gt;、有効期限 2027-06-14）
   - **次の手順は、一致するのを確かめてから貼る**（違っていれば先へ進まない）

1. Flathub を system に登録して、登録されたか確かめる。

   ```bash
   {
     sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
     flatpak remotes --show-details
   }
   ```

   - `flathub` の行が出て、`Options` の列が `system` になっていればよい

1. 確認用のアプリを入れる。

   ```bash
   sudo flatpak install flathub com.github.tchx84.Flatseal
   ```

   - 確認用のアプリは、小さい [Flatseal](https://flathub.org/apps/com.github.tchx84.Flatseal)（Flatpak アプリの権限を GUI で変えるツール）にしてある
   - **確認を 2 回聞かれる**。どちらも `y` で進める
     - 1 回目: runtime を入れるか（`Do you want to install it? [Y/n]`）
     - 2 回目: アプリの権限と入れるものの一覧を見せたうえでの最終確認（`Proceed with these changes to the system installation? [Y/n]`）
   - **次の手順は、2 回の確認に答え、完了してから貼る**（続けて貼ると答えとして食われる）

1. 確認用のアプリが入り、サンドボックスが起動できるか確かめる。

   ```bash
   flatpak list --app --columns=application,version,branch,installation
   flatpak info com.github.tchx84.Flatseal
   flatpak run --command=true com.github.tchx84.Flatseal && echo 'sandbox OK'
   ls /var/lib/flatpak/exports/share/applications/
   ```

   - `flatpak list` に `com.github.tchx84.Flatseal  2.4.1  stable  system` のように出る
   - `sandbox OK` が出れば、アプリのサンドボックスが起動できている
   - 最後の行に `com.github.tchx84.Flatseal.desktop` が出れば、デスクトップのメニューに載せるためのファイルができている
   - **flatpak を新しく入れた場合、メニューに載るのはログインし直してから**

---

## 使い方の基本

| コマンド | 用途 |
|---|---|
| `sudo flatpak update --appstream` | 検索用のアプリ一覧（appstream）を取り直す。**Flathub を登録した直後は、先にこれを 1 回実行しないと `flatpak search` が何も返さない** |
| `flatpak search <キーワード>` | Flathub のアプリを探す（ID が分かる） |
| `flatpak remote-info flathub <ID>` | 入れる前に大きさ・runtime・更新日を見る |
| `flatpak remote-ls flathub --app --arch=aarch64` | aarch64 向けに出ているアプリの一覧（Raspberry Pi で使えるか） |
| `sudo flatpak install flathub <ID>` | 入れる |
| `flatpak run <ID>` | 起動する（ふつうはデスクトップのメニューから起動する） |
| `flatpak list --app` | 入っているアプリ |
| `flatpak info --show-permissions <ID>` | アプリに与えられている権限（ファイル・デバイス・ネットワーク） |
| `sudo flatpak override <ID> --filesystem=<パス>` | 権限を足す（GUI でやるなら Flatseal） |
| `sudo flatpak override --reset <ID>` | 足した権限を元に戻す |
| `sudo flatpak uninstall <ID>` | 消す |
| `sudo flatpak uninstall --unused` | もう誰も使っていない runtime を消す |

`flatpak` の読み取り系（`search` / `list` / `info` / `remote-ls`）は `sudo` 無しで動く。

検索で見つからない場合:

- Flathub を登録した直後に `flatpak search flatseal` が `No matches found` を返す場合は、検索用のメタデータを取得してから検索し直す
- `sudo flatpak update --appstream` を実行し、検索し直してアプリの ID を確かめる

`sudo flatpak update` を 1 度実行したあとも、同じように検索できるようになる。

---

## 更新

1. Flatpak で入れたアプリを更新する。

   ```bash
   sudo flatpak update
   ```

   - 更新が無ければ `Nothing to do.` で終わる
   - **`dnf upgrade` では Flatpak のアプリは上がらない**（別の仕組み）

---

## ロールバック

- 確認用のアプリを消し、使われなくなった runtime を掃除してから、Flathub の登録自体を消す
- `flatpak` パッケージ自体は消さない（GNOME のデスクトップでは `gnome-software` が依存している）

1. 確認用のアプリを消す。

   ```bash
   sudo flatpak uninstall com.github.tchx84.Flatseal
   ```

   - 消す前に `[Y/n]` で聞かれる
   - アプリが自分のホームに作ったデータ（`~/.var/app/<ID>`）は `uninstall` では消えない。要らなければ手で消す
   - **次の手順は、答えて完了してから貼る**（続けて貼ると答えとして食われる）

1. 使われなくなった runtime を消す。

   ```bash
   sudo flatpak uninstall --unused
   ```

   - 消す前に `[Y/n]` で聞かれる
   - **次の手順は、答えて完了してから貼る**（続けて貼ると答えとして食われる）

1. Flathub から入れたアプリが残っていないか確かめる。

   ```bash
   flatpak list --app --columns=application,origin
   ```

   - **Flathub から入れたアプリが残っていると、Flathub の登録は消せない**
   - **次の手順は、`flathub` のものが無いことを確かめてから貼る**

1. Flathub の登録を消す。

   ```bash
   {
     sudo flatpak remote-delete flathub
     flatpak remotes --show-details
   }
   ```

   - 最後の `flatpak remotes --show-details` が何も出さなければ、リモートが無い状態に戻っている

---

## 注意点

- **容量が大きい**: アプリ本体に加え、runtime・翻訳・GL ドライバ・コーデックの拡張の容量も確保する
  - `sudo flatpak uninstall --unused` で、使われなくなった runtime を消せる
- **`dnf upgrade` では上がらない**: [更新](#更新)の `sudo flatpak update` を別に実行する
- **権限はアプリごとに違う**: 手順 6 で入れる前に表示される権限の一覧を確かめる
  - 入れた後は `flatpak info --show-permissions <ID>` で見られ、Flatseal か `sudo flatpak override` で変えられる
- **公開元を確認する**: Flathub のアプリには次の 2 種類がある。[ツール一覧](tool-catalog.md#gui)の表に書き分けてある
  - 検証済み: 公開元がアプリの作者本人だと確認されたもの
  - 未検証: 確認されていないもの。第三者が包んでいる場合がある
- **aarch64 に無いアプリがある**: Microsoft Edge などは Flathub でも x86_64 だけ（[ツール一覧](tool-catalog.md#aarch64-で使えないもの)）
- **RPM と Flatpak で同じアプリを二重に入れない**: [Firefox](firefox.md) のように RPM で入れたものを Flathub からも入れると、メニューに同じ名前が 2 つ並ぶと見込まれる
- **`sudo -i` した root のシェルで実行しない**: `flatpak run` はふつうのユーザーで行うもので、root で起動したアプリの設定は root のホームにできる
