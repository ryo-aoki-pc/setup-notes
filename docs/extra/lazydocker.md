# lazydocker インストール手順（AlmaLinux 10 / Homebrew）のロールバックと注意点

[手順書](../lazydocker.md)・[検証記録](../verification/lazydocker.md)・[参考資料](../reference/lazydocker.md)

- 「手順 N」は[手順書](../lazydocker.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す

## ロールバック

- 上から順に実行する
- [root でも使う](../lazydocker.md#root-でも使う任意)の節を通したなら、先にその節の手順 6〜8 で戻す（この節の手順 3 で、root の lazydocker も消える）
- `DOCKER_HOST` の行と API ソケットは、ほかのツールも使うので残す。消すなら [podman.md のロールバック](podman.md#ロールバック)の手順 2・3
- compose の任意節で使った `~/compose-sample` は、[podman-compose のロールバック](podman-compose.md#ロールバック)で消す

1. 確認用のコンテナを消す。

   ```bash
   podman rm -f lazydocker-web
   ```

   - `lazydocker-web` と出る

1. 同じイメージをほかで使っていないときだけ、イメージを消す。

   ```bash
   podman rmi registry.access.redhat.com/ubi10/httpd-24:latest
   ```

   - 同じイメージを使うもの: [podman.md の Quadlet](../podman.md#quadlet-で自動起動する任意)、[podman-compose](../podman-compose.md)、[podman-tui](../podman-tui.md)
   - 使っているコンテナが残っていると、消せずにエラーになる

1. lazydocker を消す。

   ```bash
   brew uninstall lazydocker
   ```

   - `Uninstalling /home/linuxbrew/.linuxbrew/Cellar/lazydocker/0.25.2...` と出る

1. 設定も消すときだけ、`~/.config/lazydocker` を消す。

   ```bash
   rm -rf ~/.config/lazydocker
   ```

   - 任意節で足した設定も消える

---

## 注意点

- **`E` と `a` は `docker` コマンドを呼ぶ**: podman だけの PC では、`+ docker exec -it <ID> /bin/sh -c ...` と `Press enter to return to lazydocker ...` が出るだけで、エラーも出ない
  - シェルは [podman exec の節](../lazydocker.md#podman-exec-でシェルを開く任意)の `c` で開く
  - `a` は `-it` で起動したコンテナにだけ使える。`-it` でないコンテナでは `Container does not support attaching. ...` と出る
- **UBI のイメージのコンテナは、イメージの名前で並ぶ**: lazydocker はコンテナの `name` ラベルを名前として出す（参考資料を参照）
  - 同じイメージのコンテナが並ぶと見分けにくい。操作する前に、右の枠の `Config` タブの `ID` を `podman ps` と見比べる
  - 自分で動かすコンテナなら、手順 3 のように `podman run` の `--label name=<名前>` で分けられる
- **`r` は確認なしで再起動する**: `s`（止める）は確認が出るが、`r` はすぐに実行する
- **`DOCKER_HOST` が無いか API ソケットが止まっていると、枠が空のまま**: 手順 2 の補足のエラーが出る
- **pod とシークレットは出ない**: Docker の API に無いため。pod は [podman-tui](../podman-tui.md) で見る
- **設定ファイルの同じキーを重ねない**: `cat >>` で同じトップレベルのキーを 2 回書くと、後ろだけが効く（[podman exec の節](../lazydocker.md#podman-exec-でシェルを開く任意)の手順 2 の補足）
- **`sudo lazydocker` は root のコンテナにつながらない**: `sudo` が `DOCKER_HOST` を消す（Homebrew の lazydocker は、そのままでは `sudo` の PATH にも無い。[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)）
  - root のコンテナは、[root でも使う](../lazydocker.md#root-でも使う任意)の節を通して `sudo -i lazydocker` で見る
