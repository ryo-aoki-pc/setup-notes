# distrobox インストール手順（AlmaLinux 10 / EPEL）のロールバックと注意点

[手順書](../distrobox.md)・[検証記録](../verification/distrobox.md)・[参考資料](../reference/distrobox.md)

- 「手順 N」は[手順書](../distrobox.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- 上から順に実行する
- ホームはボックスと共有しているので、ボックスを消してもホームのファイルは残る。消えるのは、ボックスの中に入れたパッケージとボックスの `/etc` など

1. ホストから呼べるようにしていたときだけ、書き出したスクリプトを消す。

   ```bash
   distrobox enter "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- distrobox-export --bin /usr/bin/ffmpeg --export-path ~/.local/bin --delete
   ```

   - `/usr/bin/ffmpeg from ubuntu removed successfully from /home/<USER>/.local/bin.` が出る
   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

1. ボックスを消す。

   ```bash
   distrobox rm "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}"
   ```

   - `Do you really want to delete containers: ubuntu? [Y/n]` に `y` と答える
   - ボックスが動いていると、続けて `Container  ubuntu running, do you want to force delete them? [Y/n]` も聞かれる。これも `y`
   - **次の手順は、答えて完了してから貼る**（続けて貼ると答えとして食われる）

1. ボックスの元にしたイメージを消し、ボックスが無くなったことを確かめる。

   ```bash
   podman rmi "${DBX_IMAGE:?手順 1 の DBX_IMAGE が空のまま。値を入れて貼り直す}"
   printf '\n\033[7m 確認 \033[0m\n'
   distrobox list
   ```

   - `distrobox list` が見出しの行だけになればよい

1. distrobox を消す。

   ```bash
   sudo dnf remove distrobox
   ```

   - `[y/N]` で聞かれる
   - 依存で入った `hicolor-icon-theme` も、ほかに使うものが無ければ一緒に消える
   - **EPEL 自体は消さない**（ほかのパッケージが使っている可能性がある）。消すなら [AlmaLinux 10 の初期設定のロールバックの「Flatpak・RPM Fusion・EPEL を消す」](almalinux-setup.md#flatpakrpm-fusionepel-を消す)の手順 7・8

---

## 注意点

- **ボックスは隔離ではない**: ホームを共有し、ホストのファイルシステム全体が `/run/host` に見え、ネットワークとプロセスもホストと同じ（参考資料を参照）。信用できないソフトを試す場所にはしない
- **ボックスの `sudo` はホストの root ではない**: 本書の `--userns keep-id` では、ボックスの root はホストの subordinate UID に対応する。自分の UID はボックス内の同じ UID に対応し、ホストの root の権限は得られない
- **`distrobox enter` が動いている間に貼った行は、ボックスへの入力になる**: 端末の入力をボックスの中のコマンドへ渡し続けるため
  - `distrobox enter <名前> -- <コマンド>` の処理が終了してプロンプトに戻ってから、次の手順を貼る
  - 本書の手順は、どれも `distrobox enter` で終わるように分けてある
- **書き出したスクリプトの名前が、ホストのコマンドと重なることがある**: `~/.local/bin` は PATH の途中にある
  - 同じ名前のコマンドがほかの場所にもあると、どちらが呼ばれるかは PATH の順で決まる
  - Homebrew の `brew shellenv` は、自分の場所を PATH の先頭に足す
- **`podman system reset` でボックスも消える**: ボックスは podman のコンテナなので、[podman.md のロールバック](podman.md#ロールバック)の手順 5 で一緒に消える
- 必要な空き容量は、導入予定のパッケージとトランザクション表で確かめる
