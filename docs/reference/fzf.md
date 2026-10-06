# fzf インストール手順（AlmaLinux 10 / Homebrew）の参考資料

[手順書](../fzf.md)

## 補足

### 実施手順 / 手順 1: 補足: 依存と、入れてあるホストで貼る意味

[この節の検証記録](../verification/fzf.md#実施手順--手順-1-補足-依存と入れてあるホストで貼る意味)

- fzf の依存は `ncurses` だけ（`brew deps fzf`）
- yazi.md や zoxide.md で入れた fzf は、`brew install zoxide fzf` のように名前を挙げて入れているので、Homebrew の「頼まれて入れた」印（`installed_on_request`）が付いている。`brew install fzf` を貼り直しても害は無く、印が無かったホストでは付く（印が無いと、zoxide や yazi を `brew uninstall` した際の自動削除や、明示的な `brew autoremove` で fzf も消えうる）

### 参照

- [fzf — README](https://github.com/junegunn/fzf#readme)（Key bindings for command-line、Fuzzy completion for bash、Search syntax、Environment variables）
- [fzf — ADVANCED.md](https://github.com/junegunn/fzf/blob/master/ADVANCED.md)（プレビューの例）
- `man fzf`（`--preview`・`--line-range` は bat 側）
- [Homebrew の fzf の formula](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/f/fzf.rb)（caveat の `fzf --bash`）
- [bash の履歴・補完・キー操作](../bash-settings.md) — bash-completion と Homebrew の補完、`~/.inputrc`。fzf の行との並び
- [zoxide](../zoxide.md) — `zi` が fzf を使う。[yazi](../yazi.md) — `z` / `Z` キーが fzf を使う
- [bat](../bat.md) — プレビューに使う。[Homebrew](../homebrew.md) — Homebrew 本体の導入と、Homebrew 系に共通の注意

---
