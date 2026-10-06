# Visual Studio Code インストール手順（AlmaLinux 10 / Microsoft 公式 dnf リポジトリ）

## 実施手順

- [検証記録](verification/vscode.md)・[参考資料](reference/vscode.md)

> [!IMPORTANT]
> - **すべて対象ホスト上で実行する**。デスクトップが要るのは手順 6（GUI の起動）だけ
> - **手順 6 は、デスクトップにログインした端末から実行する**。TTY やディスプレイが無いシェル（ssh や自動化）からは実行しない
> - **手順 4 と手順 6 には対話入力がある**（`[y/N]` と、開いたウィンドウ）。答えるかウィンドウを閉じてから、次の手順を貼る

- 上から順にコードブロックを貼る
- 手順の後: 拡張機能は[拡張機能を入れる（任意）](#拡張機能を入れる任意)。以後は[更新](#更新)・[ロールバック](#ロールバック)

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
     cat /etc/yum.repos.d/vscode.repo
   }
   ```

   - ヒアドキュメントは `<<'EOF'`（クォート付き）。この中に展開したい変数は無い

1. 何が入るかを先に見てから、VS Code を入れる。

   ```bash
   {
     sudo dnf install --assumeno code
     sudo dnf install code
   }
   ```

   - 先に何が入るかだけ見る（`--assumeno` は必ず中断する）
   - `code ... 318 M` と `Installed size: 953 M` が出る。よければ、続く `dnf install` の `[y/N]` に答えて入れる
   - 弱い依存として `socat` が一緒に入る
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. VS Code が入ったか確かめる。

   ```bash
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
   ls -d ~/.config/Code ~/.vscode
   code --list-extensions
   ```

   - 初回起動で `~/.config/Code`（設定と履歴）ができる
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
   - **rpm 版では VS Code 内蔵のアップデータは使わない**（dnf が管理しているため。[firefox.md](firefox.md) と同じ論点）

---

## ロールバック

> [!CAUTION]
> **この節の**手順 3 の `rm -rf ~/.config/Code ~/.vscode` は、**VS Code の設定・履歴・拡張機能を消す**。残すなら、この節の手順 3 は貼らない。

1. VS Code を消す。

   ```bash
   sudo dnf remove code
   ```

   - `socat` がほかから使われていなければ、dnf の自動掃除で一緒に消える（クリーンインストールの VM では `code` と `socat` の 2 パッケージだけが消えた）
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. リポジトリのファイルを消す。

   ```bash
   sudo rm -f /etc/yum.repos.d/vscode.repo
   ```

   - Microsoft の署名鍵は `gpg-pubkey-be1229cf-5631588c` として残る（`rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n'` で確認できる）
   - 消すなら `sudo rpm -e gpg-pubkey-be1229cf-5631588c`。**ほかに Microsoft のリポジトリを使っていないことを確かめてから**にする

1. 設定・履歴・拡張機能も消すときだけ、`~/.config/Code` と `~/.vscode` を消す（取り戻せない）。

   ```bash
   rm -rf ~/.config/Code ~/.vscode      # 設定・履歴・拡張機能も消す場合
   ```

---

## 注意点

- **`.el8` のタグに驚かなくてよい**: Microsoft が EL 共通に 1 本だけ出している rpm で、EL10 向けの別ビルドは存在しない。`rpm -qi` の `Vendor` が `Microsoft Corporation` であることを確かめれば十分（[手順 5 の補足](#実施手順)）
- **`~/.config/code-flags.conf` は効かない**: Microsoft の rpm のラッパーは読まない（[手順 6 の補足](#実施手順)）
- 容量が不足する場合は、インストール前にトランザクション表と空き容量を確かめる
- **内蔵のアップデータは使わない**: rpm 版は dnf が管理する。VS Code が更新を促してきても `sudo dnf upgrade code` で上げる
- **`code-insiders` と併存できる**: コマンド名も設定ディレクトリ（`~/.config/Code - Insiders`）も別
- **Electron なので X11 のライブラリを要求する**: `libX11` / `libXcomposite` などが rpm の requires に並ぶ
  - これは XWayland 経由でも動くようにするためで、**ライブラリが入っていることは「X11 で動いている」ことを意味しない**
- **root では起動できない**: ラッパーが `--user-data-dir` の指定を要求する。そもそも root で使うものではない
- **TTY もディスプレイも無いシェルからは GUI を起動できなかった**: デスクトップの端末からは起動する
  - 原因は特定できていない
