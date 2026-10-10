# Visual Studio Code インストール手順（AlmaLinux 10 / Microsoft 公式 dnf リポジトリ）

## 実施手順

- [検証記録](verification/vscode.md)・[参考資料](reference/vscode.md)・[ロールバックと注意点](extra/vscode.md)

> [!IMPORTANT]
> - **すべて対象ホスト上で実行する**。デスクトップが要るのは手順 6（GUI の起動）だけ
> - **手順 6 は、デスクトップにログインした端末から実行する**。TTY やディスプレイが無いシェル（ssh や自動化）からは実行しない
> - **手順 4 と手順 6 には対話入力がある**（`[y/N]` と、開いたウィンドウ）。答えるかウィンドウを閉じてから、次の手順を貼る

- 上から順にコードブロックを貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 手順の後: 拡張機能は[拡張機能を入れる（任意）](#拡張機能を入れる任意)。以後は[更新](#更新)・[ロールバック](extra/vscode.md#ロールバック)

1. 署名鍵を落として、取り込む前に fingerprint を見る。

   ```bash
   curl -fsSL https://packages.microsoft.com/keys/microsoft.asc -o /tmp/microsoft.asc
   gpg --show-keys --with-fingerprint /tmp/microsoft.asc
   ```

   - 次の値と一致することを目で確かめる。違っていればここで止める
     - fingerprint `BC52 8686 B50D 79E3 39D3 721C EB3E 94AD BE12 29CF`
     - uid `Microsoft (Release signing) <gpgsecurity@microsoft.com>`
   - **次の手順は、一致したのを確かめてから貼る**

1. fingerprint が一致したら署名鍵を取り込み、確かめて鍵ファイルを消す。

   ```bash
   {
     sudo rpm --import /tmp/microsoft.asc
     rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i microsoft
     rm -f /tmp/microsoft.asc
   }
   ```

   - `gpg-pubkey-be1229cf-5631588c Microsoft (Release signing) ...` が出れば入っている

1. リポジトリを追加する。

   ```bash
   {
     sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
   [vscode]
   name=Visual Studio Code
   baseurl=https://packages.microsoft.com/yumrepos/vscode
   enabled=1
   gpgcheck=1
   gpgkey=https://packages.microsoft.com/keys/microsoft.asc
   EOF
     printf '\n\033[7m 確認 \033[0m\n'
     cat /etc/yum.repos.d/vscode.repo
   }
   ```

1. 何が入るかを先に見てから、VS Code を入れる。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     sudo dnf install --assumeno code
     sudo dnf install code
   }
   ```

   - 先に何が入るかだけ見る（`--assumeno` は必ず中断する）
   - `code ... 318 M` と `Installed size: 953 M` が出る。よければ、続く `dnf install` の `[y/N]` に答えて入れる
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. VS Code が入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   code --version
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' code
   rpm -qi code | sed -n '/^Vendor/p;/^Build Date/p'
   ldd /usr/share/code/code | grep -c 'not found'
   rpm -ql code | grep '/applications/.*\.desktop$'
   ```

   - バージョン / コミットハッシュ / アーキテクチャ（`x64` または `arm64`）の 3 行が出る
   - `from_repo` が `vscode`、`Vendor` が `Microsoft Corporation` になる
   - **`ldd` の `not found` が `0`** なら、必要な共有ライブラリがすべて EL10 側で解決できている

1. デスクトップにログインした端末から、GUI を起動する。

   ```bash
   code
   ```

   - アプリ一覧の「Visual Studio Code」からでも同じ
   - **注意**: ssh や自動化など、TTY もディスプレイも無いシェルからは起動できなかった（冒頭の前提と、この手順の補足）
   - ウィンドウが開き、初回は Welcome 画面が出る。1.140.0 では `Continue without Signing In` を選ぶとサインインせず進められる
   - ウィンドウが出たことを確かめる
   - **次の手順は、ウィンドウを閉じてから貼る**（続けて貼ると VS Code への操作として食われる）

1. 初回起動で設定のディレクトリができたか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   ls -d ~/.config/Code ~/.vscode
   code --list-extensions
   ```

   - 初回起動で `~/.config/Code` ができる
   - `~/.vscode` は、起動を試みた時点で `argv.json` だけ作られる
   - 拡張を入れていなければ、`code --list-extensions` は何も返さない

---

## 拡張機能を入れる（任意）

- CLI から入れられる
- Settings Sync・Remote-SSH・Marketplace の利用条件は扱わない

1. 入っている拡張機能を一覧する。

   ```bash
   code --list-extensions --show-versions
   ```

   - 入れるときは `code --install-extension <publisher.name>` の形で ID を渡す。たとえば [ShellCheck](shellcheck.md) をエディタから使うなら `timonwong.shellcheck`
   - 消すときは `code --uninstall-extension <publisher.name>`

---

## 更新

- VS Code は通常の更新に含まれる

1. VS Code を更新する。

   ```bash
   sudo dnf upgrade code
   ```

   - システム全体なら `sudo dnf upgrade`
   - **rpm 版では VS Code 内蔵のアップデータは使わない**
