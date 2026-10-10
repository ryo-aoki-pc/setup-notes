# gdu インストール手順（AlmaLinux 10 / Homebrew）の参考資料

[手順書](../gdu.md)・[ロールバックと注意点](../extra/gdu.md)

## 補足

### 実施手順 / 手順 1: 補足: ボトルと依存

- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
- 依存は無い（Go の静的バイナリ 1 つ、約 20 MB）
- `brew install` の最後に出る caveat の出力例は[検証記録](../verification/gdu.md)

### 実施手順 / 手順 2: 補足: TUI で使う

- TUI で使うときは引数にディレクトリを渡すだけ（`gdu-go ~` など。`q` で終了）

### gdu の名前で呼ぶ（任意） / 手順 1: 補足: 共通設定

- gdu のエイリアスは共通設定にあるので、`~/.bashrc` への追記は不要

### gdu の名前で呼ぶ（任意） / 手順 2: 補足: シンボリックリンク

- `~/.local/bin` は AlmaLinux の既定の `~/.bashrc` で PATH に入っている
- リンク先を Cellar ではなく `/home/linuxbrew/.linuxbrew/bin` にしてあるので、`brew upgrade` で版が上がってもリンクは張り直さなくてよい
- ただし **PATH の順序では Homebrew のほうが先**なので、EPEL 版の `/usr/bin/gdu` を同時に入れている場合はどちらが呼ばれるか変わる（[注意点](../extra/gdu.md#注意点)）
- `sudo gdu` に効かないのは、`~/.local/bin` が sudo の PATH に無いため

### 参照

- [dundee/gdu — README](https://github.com/dundee/gdu) — 使い方、キーバインド、各ディストリビューションでの入手方法
- [gdu — Configuration](https://github.com/dundee/gdu/blob/master/docs/configuration.md) — `~/.gdu.yaml` の項目
- `gdu-go --help` — 全フラグ（非対話モード、除外、データベース出力など）
- [Homebrew の gdu formula](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/g/gdu.rb) — `gdu-go` にリネームしている箇所
- [AlmaLinux 10 の初期設定](../almalinux-setup.md) — 「Homebrew」の手順 1〜3 が Homebrew 本体の導入手順。`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件は参考資料、`brew` の基本操作は同書の「Homebrew の使い方の基本」

---
