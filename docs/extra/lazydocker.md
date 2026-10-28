# lazydocker の注意点

[手順書](../containers.md#lazydocker)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/lazydocker.md)・[参考資料](../reference/lazydocker.md)

- 「手順 N」は[手順書](../containers.md#lazydocker)の手順 N、「本書」「この文書」は手順書を指す

## 注意点

- **`E` と `a` は `docker` コマンドを呼ぶ**: podman だけの PC では、`+ docker exec -it <ID> /bin/sh -c ...` と `Press enter to return to lazydocker ...` が出るだけで、エラーも出ない
  - シェルは [podman exec の節](../containers.md#lazydocker-podman-exec-でシェルを開く)の `c` で開く
  - `a` は `-it` で起動したコンテナにだけ使える。`-it` でないコンテナでは `Container does not support attaching. ...` と出る
- **UBI のイメージのコンテナは、イメージの名前で並ぶ**: lazydocker はコンテナの `name` ラベルを名前として出す（参考資料を参照）
  - 同じイメージのコンテナが並ぶと見分けにくい。操作する前に、右の枠の `Config` タブの `ID` を `podman ps` と見比べる
  - 自分で動かすコンテナなら、手順 3 のように `podman run` の `--label name=<名前>` で分けられる
- **`r` は確認なしで再起動する**: `s`（止める）は確認が出るが、`r` はすぐに実行する
- **`DOCKER_HOST` が無いか API ソケットが止まっていると、枠が空のまま**: 手順 2 の補足のエラーが出る
- **pod とシークレットは出ない**: Docker の API に無いため。pod は [podman-tui](../containers.md#podman-tui) で見る
- **設定ファイルの同じキーを重ねない**: `cat >>` で同じトップレベルのキーを 2 回書くと、後ろだけが効く（[podman exec の節](../containers.md#lazydocker-podman-exec-でシェルを開く)の手順 2 の補足）
- **`sudo lazydocker` は root のコンテナにつながらない**: `sudo` が `DOCKER_HOST` を消す（Homebrew の lazydocker は、そのままでは `sudo` の PATH にも無い。[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)）
  - root のコンテナは、[root でも使う](../containers.md#lazydocker-root-でも使う)の節を通して `sudo -i lazydocker` で見る
