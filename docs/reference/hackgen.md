# HackGen Console NF インストール手順（AlmaLinux 10 は Homebrew / Windows 11 は上流の zip）の参考資料

[手順書](../hackgen.md)

[検証記録](../verification/hackgen.md#参考資料から分離した記録)

## 補足

### 選択した方針

| 経路 | 状況 | 採否 |
|---|---|---|
| **Homebrew の cask `font-hackgen-nerd`** | `brew upgrade` で上がり、`brew uninstall` で消せる。自分のユーザーにだけ入る | **採用**（Homebrew 系の手順書と揃える） |
| GitHub のリリースの zip を手で展開 | `~/.local/share/fonts` に置く。Homebrew が要らないが、**更新は手作業** | 不採用（Homebrew がある環境では cask で足りる） |
| 全ユーザー向け（`/usr/local/share/fonts` に置く） | root で置けば全ユーザーから見えるが、cask は自分のホームに置く。複数ユーザーで使う機会が無いので要らない | 不採用 |

- upstream の README は、Linux 向けの導入手順を書いていない（GitHub のリリースの ttf と、Mac の Homebrew、Windows の Chocolatey を案内している）
- Homebrew の cask は upstream の README では Mac 向けとして紹介されている

| 経路 | 状況 | 採否 |
|---|---|---|
| **上流の zip を版と sha256 を固定して、自分のユーザーに入れる** | 管理者の権限も scoop も要らず、Windows PowerShell 5.1 で動く。更新は手作業 | **採用** |
| scoop の個人のバケット mo-san の `font-hackgen-console-nf` | リリースの zip を使い、scoop と UniGet UI で上げられる。ただし、インストールのスクリプトが `Join-Path` に 3 つ以上の引数を渡していて、Windows PowerShell 5.1 の `Join-Path`（`-Path` と `-ChildPath` だけ）では失敗するはず。scoop はそのスクリプトを、`scoop` を打った PowerShell の中で動かす | 不採用（PowerShell 7 が要り、個人の保守） |
| scoop の nerd-fonts のバケット | HackGen は無い | — |
| winget | 既定のソース（winget-pkgs）に HackGen は無い。winget の一覧のサイトには `yuru7.HackGen`（第三者の `dfirr/winget-hackgen` が作り直したインストーラで、PC 全体に入れる）が載っている | 不採用 |
| Chocolatey | 上流の README が Windows 向けに案内している | 不採用（別のパッケージ マネージャーを足し、管理者が要る） |
| PC 全体（`C:\Windows\Fonts`）に入れる | 管理者が要る | 不採用（AlmaLinux 10 と同じく自分のユーザーだけ） |

- **Windows 11 の手順もこの文書に置いた**: 同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、OS ごとにファイルを分けない。手順が OS で違うので、[syncthing.md](../syncthing.md) と同じく後ろの節に分けた

### 参照

- [yuru7/HackGen](https://github.com/yuru7/HackGen) — フォントの特徴、ファミリーの種類、ライセンス、リリース
- [Homebrew Formulae — font-hackgen-nerd](https://formulae.brew.sh/cask/font-hackgen-nerd) — cask の版と中身
- [Nerd Fonts](https://www.nerdfonts.com/) — 追加されているアイコンの一覧（コードポイントの確認に使える）
- `man fc-list` / `man fc-match` / `man fc-cache` — fontconfig の照会と、キャッシュの作り直し
- [wezterm-nightly.md](../wezterm-nightly.md) — WezTerm の導入と設定ファイルの置き場所
- [AlmaLinux 10 の初期設定](../almalinux-setup.md) — 手順 46〜48 が Homebrew 本体の導入手順。`brew` の基本操作は同書の「Homebrew の使い方の基本」
- [HackGen v2.10.0](https://github.com/yuru7/HackGen/releases/tag/v2.10.0) — Windows 11 の節で取る `HackGen_NF_v2.10.0.zip`
- [Join-Path（5.1）— Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/join-path?view=powershell-5.1) — `-Path` と `-ChildPath` だけ（scoop の個人のバケットを採らなかった理由）
- [matthewjberger/scoop-nerd-fonts](https://github.com/matthewjberger/scoop-nerd-fonts) — Windows で自分のユーザーにフォントを入れる定義（issue #198 のアクセス権）
- [mo-san/scoop-bucket](https://github.com/mo-san/scoop-bucket) — 採らなかった scoop の個人のバケット
- [Windows 11 の初期設定](../windows-setup.md) — Windows のインストール直後にまとめて行う設定（scoop・UniGet UI・Caps Lock・表示・電源・リモート デスクトップなど）。この節は、そのリードから案内される

---
