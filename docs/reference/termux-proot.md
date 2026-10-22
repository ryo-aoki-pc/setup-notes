# Termux の proot-distro の参考資料

[手順書](../android.md#termux-の-proot-distro)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/termux-proot.md)・[注意点](../extra/termux-proot.md)

## 選択した方針

- Termux のパッケージで足りない glibc の環境だけを proot-distro の Ubuntu に置く。シェル・Git・Neovim・Codex CLI は Termux のネイティブの環境を使う
- Ubuntu へ入るときは `--isolated` を付け、Termux のホームと共有のストレージをつながない

## 補足

### Termux の proot-distro / 手順 2: 補足: Ubuntu のイメージ

- `proot-distro install ubuntu` は Docker Hub の公式の `ubuntu:latest` を使う。入る版は導入時点の `latest` による
- エミュレーターでは Ubuntu 26.04.1 LTS の x86_64 が入り、ログイン先は root だった。実機の aarch64 は確かめていない
- コンテナは `$PREFIX/var/lib/proot-distro/containers/ubuntu` に置かれる

### Termux の proot-distro / 手順 3: 補足: isolated の範囲

- 既定のモードは `/data/data/com.termux`（Termux のホームと `$PREFIX`）・`/sdcard`・`/storage/emulated/0` などをコンテナにつなぎ、PATH の末尾に `$PREFIX/bin` も足す
- `--isolated` を付けると、コンテナから `/data/data/com.termux` が見えず、PATH にも Termux の `$PREFIX/bin` は入らない
- `--isolated` の Ubuntu でもネットワークは使え、Claude Code の `--version` が動いた

### Termux の proot-distro / 手順 4: 補足: debconf の案内

- Ubuntu のイメージには、debconf の対話の画面の道具（dialog など）が無い。`apt-get upgrade` の途中で `debconf: unable to initialize frontend: Dialog` などが出て、`Teletype` に切り替えて進んだ

## 参照

- [proot-distro](https://github.com/termux/proot-distro)
- [Docker Hub の Ubuntu 公式イメージ](https://hub.docker.com/_/ubuntu)
- [Termux の AI エージェントの手順書](../android.md#termux-の-ai-エージェント)
