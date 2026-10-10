# HackGen Console NF インストール手順（AlmaLinux 10 は Homebrew / Windows 11 は上流の zip）のロールバックと注意点

[手順書](../hackgen.md)・[検証記録](../verification/hackgen.md)・[参考資料](../reference/hackgen.md)

- 「手順 N」は[手順書](../hackgen.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 のロールバック](#windows-11-のロールバック)
- **Homebrew そのものを消すとき**（[AlmaLinux 10 の初期設定のロールバックの「Homebrew と bash-completion を消す」](almalinux-setup.md#homebrew-と-bash-completion-を消す)の手順 1〜3）は、先にこの節の手順 1 の `brew uninstall --cask` を実行しておく
  - `~/.local/share/fonts` は Homebrew の外なので、このフォントを外すときは上の削除手順も行う

1. HackGen を消し、fontconfig から消えたか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   brew uninstall --cask font-hackgen-nerd
   ls ~/.local/share/fonts/
   fc-list : family | grep -c HackGen
   ```

   - `==> Removing Font '/home/<USER>/.local/share/fonts/...'` が 4 行出る
   - `ls` が何も出さず、`grep -c` が `0` になれば消えている（空の `~/.local/share/fonts` は残る）

1. WezTerm で使う（任意）を通したときだけ、書き換えた行を元のフォントに戻す。

   ```bash
   sed -i "s/^config.font = wezterm.font '${HACKGEN_FAMILY:?手順 1 の HACKGEN_FAMILY が空のまま。値を入れて貼り直す}'/config.font = wezterm.font 'Noto Sans Mono'/" ~/.config/wezterm/wezterm.lua
   printf '\n\033[7m 確認 \033[0m\n'
   grep -n '^config.font = ' ~/.config/wezterm/wezterm.lua
   ```

   - [WezTerm で使う（任意）](../hackgen.md#wezterm-で使う任意)で書き換えた行は、元のフォントに戻す
   - このコマンドは、wezterm-nightly.md の最小の例（`Noto Sans Mono`）に戻す場合

---

## Windows 11 のロールバック

- この節の手順 1・3 は、Windows PowerShell（5.1）に貼る
- フォントのファイルは読み込まれている間は消せないので、登録を消してからサインインし直し、その後でファイルを消す

1. HackGen の登録を消す。

   ```powershell
   $key = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
   (Get-Item -LiteralPath $key).Property -like 'HackGen*ConsoleNF-* (TrueType)' | ForEach-Object { Remove-ItemProperty -LiteralPath $key -Name $_ }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-Item -LiteralPath $key).Property -like 'HackGen*'
   ```

   - 最後のコマンドが何も出さなければよい

1. この PC でサインアウトし、サインインし直す。

   - 再起動でもよい
   - **次の手順は、サインインし直して Windows PowerShell（5.1）を開いてから貼る**

1. フォントのファイルを消す。

   ```powershell
   Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\HackGen*ConsoleNF-*.ttf"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" -Filter 'HackGen*'
   ```

   - 最後のコマンドが何も出さなければよい
   - [Windows 11 で使う](../hackgen.md#windows-11-で使う)の手順 3 の `icacls` で足した読み取りの許可は残す（ほかのフォントにも要る）

---

## 注意点

- **自分のユーザーにしか入らない**: 置き場所が `~/.local/share/fonts` なので、別のユーザーや root で動くアプリからは見えない
- **`unzip` が要る**: Homebrew の formula（ボトル）は `unzip` 無しで入るが、zip で配られる cask は展開に `unzip` を使う
- **Console 版は記号が半角になる**: 矢印などが 1 セル幅で出る（[WezTerm で使う（任意）](../hackgen.md#wezterm-で使う任意)の `→` が `cells=1`）
  - Console ではない通常版（HackGen / HackGen35）は NF 版の zip に入っておらず、NF 無しの cask `font-hackgen` にある
- **NF 版と NF 無しの版は別の cask**: `font-hackgen-nerd`（Console の 2 ファミリー × NF）と `font-hackgen`（4 ファミリー、アイコン無し）
  - ファミリー名は NF 版だけ末尾に ` NF` が付く
- **ファミリー名は `HackGen Console NF`**（スペース入り）。ファイル名（`HackGenConsoleNF-Regular.ttf`）や PostScript 名（`HackGenConsoleNF-Regular`）とは違う。アプリの設定にはファミリー名を書く
- **等幅だけを一覧に出すアプリ**: fontconfig はこのフォントを `spacing=90`（`dual`）と見なす
- **GNOME の端末や VS Code など WezTerm 以外のアプリ**: それぞれの設定でファミリー名 `HackGen Console NF` を指定する
- **Powerline の記号**: WezTerm は `U+E0B0` などの一部の記号を既定で自分で描く（`custom_block_glyphs`）。ほかの端末ではフォントのグリフが使われる
- **Windows 11 では、自分のユーザーのフォントが見えないアプリがある**: ユーザーごとのフォントは Windows 10 1809 からで、古いアプリには見えないことがある。そのアプリだけ、PC 全体に入れ直す（本書では扱わない）
- **Windows 11 では、読み込まれているフォントのファイルを置き換えられない**: 入れ替え（更新）と削除は、登録を消してサインインし直してから行う（[Windows 11 のロールバック](#windows-11-のロールバック)）
