# Termux の Neovim の参考資料

[手順書](../android.md#termux-の-neovim)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/termux-neovim.md)・[注意点](../extra/termux.md)

## 選択した方針

- Neovim と、コンパイラー・パーサー・LSP・整形の外部コマンドは Termux の `pkg` で入れる。LazyVimStarter の custom と md-format を組み合わせる
- marksman は入れない。`dotnet-host` と `dotnet-runtime-9.0` に依存するので、Markdown のために入れるものを増やさない（利用者の決定。marksman の導入は確かめていない）

## 補足

### Termux の Neovim / 手順 1・2: 補足: Termux の Neovim と外部コマンド

- Termux の Neovim は、`LD_PRELOAD` に libluajit を足すラッパーで起動する。`has("android")` と `has("termux")` はどちらも `1`
- `tree-sitter` のパッケージには CLI も含まれる。パーサーは Termux の clang でビルドできた

### Termux の Neovim / Termux の Neovim: md-format を入れる / 手順 1・3: 補足: Markdown の整形と PATH

- LazyVimStarter は md-format を Markdown の整形に使う。md-format が無いと、保存時に `Formatter failed` が出る
- `mdfmt` は `~/.local/bin` に置かれる。共通の bash 設定を入れた新しいシェルで、この場所が PATH に入る
- md-format を入れた後は、Markdown の保存で行末の空白と、続いた空行が消えた

### Termux の Neovim / Termux の Neovim: LazyVim の設定を導入する / 手順 3: 補足: Mason と Termux の分岐

- Mason が入れる glibc 向けのバイナリは Termux で動かない。Mason の版が PATH の先に来ると、`pkg` で入れた外部コマンドも使われなくなる
- `lua/plugins/termux.lua` は `has("termux")` のときだけ設定を変え、lua_ls・taplo・marksman は PATH にあるものを使う。入っていない marksman は有効にしない
- Mason が入れるものは、npm の bash-language-server・json-lsp・yaml-language-server・markdownlint-cli2 だけ。`mason/bin` は PATH の後ろに置く
- blink.cmp は Lua の実装を使う。エミュレーターの x86_64 では、自動で取得した aarch64 向けの Rust のライブラリを読み込めなかった

### Termux の Neovim / Termux の Neovim: LazyVim の設定を導入する / 手順 4・5: 補足: 診断とクリップボード

- Termux 用の分岐で、pkg の lua_ls・taplo と、npm の bashls・jsonls・yamlls がつながり、シェルの shellcheck と Markdown の markdownlint の診断が出た
- lua_ls は、プロジェクトの印の無い場所の単独のファイルでは診断を出さなかった。`.luarc.json` を置くと診断が出た。Termux だけの動きではない
- Termux:API を入れた Termux の画面では、Neovim の標準の Termux 用 provider でヤンクした文字を Android のクリップボードへ送れた

## 参照

- [LazyVimStarter の custom の設定](https://github.com/ryo-aoki-pc/LazyVimStarter/tree/custom)
- [md-format](https://github.com/ryo-aoki-pc/md-format)
- [Termux の Neovim パッケージ](https://github.com/termux/termux-packages/tree/master/packages/neovim)
- [Neovim の手順書](../neovim.md)
