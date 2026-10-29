# Windows 11 のセットアップの注意点

[手順書](../windows-setup.md)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-setup.md)・[参考資料](../reference/windows-setup.md)

- 手順書の手順は、番号付きリストを持つ見出し（項）ごとに 1 から数える。「<項>の手順 N」は手順書のその項の手順、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## 注意点

- **Windows Sandbox の窓を閉じると、内部の状態が消える**: Sandbox の内部だけに置いたファイルと、インストールしたアプリは破棄される。Windows 11 22H2 以降では、Sandbox の中で Windows を再起動しただけなら状態は残る
- **Sandbox から共有したホストのファイルは残る**: ホストへコピーした結果や、`.wsb` の `MappedFolders` で共有したホスト側のファイルは、Sandbox の窓を閉じても消えない。書き込みを許可した共有フォルダーへの変更もホスト側に残る

- **重ねると、触れる人がそのまま使える PC になる**: 放置でロックしない（[PC 全体の設定](../windows-setup.md#pc-全体の設定)の手順 7）と、PC の前にいる人がこのユーザー（Administrators の一員）として操作できる。インラインの sudo（[PC 全体の設定](../windows-setup.md#pc-全体の設定)の手順 6）・リモート デスクトップ（[ネットワークとリモート](../windows-setup.md#ネットワークとリモート)の手順 4）・Windows Hello 以外のサインイン（[サインイン・検索・キーボード](../windows-setup.md#サインイン検索キーボード)の手順 2）は、このユーザーのパスワードを知る人の入口を増やす。人が触れる場所にある PC では、[PC 全体の設定](../windows-setup.md#pc-全体の設定)の手順 7 は行わない
- **Caps Lock の働きは無くなる**: Caps Lock を左 Ctrl にするだけで、Caps Lock をほかのキーに割り当てない。大文字を続けて打つときは Shift を押す
- **Scancode Map は、すべてのユーザー・すべてのキーボードにかかる**: PC 全体の設定。この PC にサインインするほかのユーザーと、つないだ外付けのキーボードにもかかる
- **JIS 配列では「英数」のキーが Ctrl になる**: 日本語の配列のキーボードの Caps Lock は「英数」のキー（スキャン コード `0x3A`）なので、そのキーの IME の働き（英数への切り替え）も無くなるはず
- **リモート デスクトップと Scancode Map**: Microsoft の文書は、Scancode Map がターミナル サービスでは正しく働かないことがあると書いている
- **Ctrl+Space はアプリでは使えなくなる**: IME が受け取るので、PowerShell（PSReadLine の `MenuComplete`）・VS Code・Excel などの Ctrl+Space は効かなくなるはず（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-setup.md)・[参考資料](../reference/windows-setup.md)）
  - PowerShell 7 では、`MenuComplete` を Tab に割り当てられる（[PowerShell 7 のプロファイルを設定する](../shell-terminal.md#powershell-7-のプロファイルを設定する)の手順 3）
- **管理者の PowerShell は conhost の窓で開く**: 既定の端末を Windows Terminal にしても（[表示と入力](../windows-setup.md#表示と入力)の手順 7）、管理者として開いた PowerShell は conhost の窓になる。右クリックで貼れるのは、[貼り付けの設定](../windows-setup.md#貼り付けの設定)の手順 1〜5 のプロファイルの設定による
- **外したアプリと提案は、機能の更新で戻ることがある**: 自分のユーザーから外したアプリ（[自動起動と標準アプリ](../windows-setup.md#自動起動と標準アプリ)の手順 3・4）は、PC に置かれた元が残るので、Windows の大きな更新の後に戻ってくることがある。[表示と入力](../windows-setup.md#表示と入力)の手順 4 と[自動起動と標準アプリ](../windows-setup.md#自動起動と標準アプリ)の手順 1〜4 を貼り直す
- **サポート外の設定**: 旧形式のコンテキストメニュー（[表示と入力](../windows-setup.md#表示と入力)の手順 3）は Microsoft が説明していない設定で、Windows の更新で効かなくなることがある。そのときは、[貼り付けの設定](../windows-setup.md#貼り付けの設定)の手順 3 の `ClassicMenu` と[表示と入力](../windows-setup.md#表示と入力)の手順 3 の `reg.exe query` で、設定が残っているかを見る。[表示と入力](../windows-setup.md#表示と入力)の手順 2・4 と[自動起動と標準アプリ](../windows-setup.md#自動起動と標準アプリ)の手順 2 の値の多くも、Microsoft の文書には値が書かれておらず、広く使われているもの
- **PowerShell 7 で scoop を使うとき**: 実行ポリシーは Windows PowerShell 5.1 とは別に持つ。UniGet UI は、PowerShell 7 があればそれで scoop を動かす（`-ExecutionPolicy Bypass` 付き）
- **PowerShell 7 のプロファイルは別**: [貼り付けの設定](../windows-setup.md#貼り付けの設定)の手順 5 の行は Windows PowerShell 5.1 のプロファイルにだけ書く。PowerShell 7（[アプリを入れる](../windows-setup.md#アプリを入れる)の手順 6）は `Documents\PowerShell\Microsoft.PowerShell_profile.ps1` を読む。この文書の手順書群は、Windows PowerShell 5.1 に貼る
  - 同じ貼り付けの設定を PowerShell 7 にも足すなら、[PowerShell 7 のプロファイルを設定する](../shell-terminal.md#powershell-7-のプロファイルを設定する)
- **scoop のアプリは自分のユーザーだけ**: `~\scoop` に入るので、ほかのユーザーには見えない。scoop の `--global` は管理者が要り、本書では使わない
- **貼ったブロックは、Enter を押すまで動かない**: コピーボタンの中身は末尾に改行が無いため。[貼り付けの設定](../windows-setup.md#貼り付けの設定)の手順 1〜5 の後の conhost の窓では、ブロック全体が 1 つの入力になり、Enter で 1 回で動く
- **Ctrl+Enter で上に行を作る操作（`InsertLineAbove`）は使えなくなる**: 下に行を作る Shift+Ctrl+Enter（`InsertLineBelow`）と、Shift+Enter（`AddLine`）はそのまま
- **このユーザーの Windows PowerShell のコンソールの窓すべてに効く**: 管理者の窓も同じプロファイルを読む
- **ほかの項にもサポート外の設定がある**: ギャラリーとホームを消す値（[表示・入力・音・ストレージを控えて変える](../windows-setup.md#表示入力音ストレージを控えて変える)の手順 6）は、[表示と入力](../windows-setup.md#表示と入力)の手順 3 と同じく Microsoft が説明していない方法で、更新で効かなくなることがある。任意節のほかの値の多くも、Microsoft の文書には無く、広く使われているもの
- **Edge に「組織によって管理」と出る**: [Edge の常駐をポリシーで止める](../windows-setup.md#edge-の常駐をポリシーで止める)の手順 2 のポリシーで出る。[サインイン・検索・キーボード](../windows-setup.md#サインイン検索キーボード)の手順 4 の `EdgeUpdate` だけで出るかは、確かめていない
- **ストレージ センサーはファイルを消す**: [表示・入力・音・ストレージを控えて変える](../windows-setup.md#表示入力音ストレージを控えて変える)の手順 11 は、ごみ箱に 30 日を超えて置いたファイルと一時ファイルを毎月消す（取り戻せない）。OneDrive のファイルは、[表示・入力・音・ストレージを控えて変える](../windows-setup.md#表示入力音ストレージを控えて変える)の手順 12 で外さないと、オンラインだけにされうる
- **WSL をミラーにすると、WSL から Windows には `127.0.0.1` でつなぐ**: [WSL のネットワークをミラーにする](../windows-setup.md#wsl-のネットワークをミラーにする)の後は、WSL から Windows のサービスに LAN の IP あてではつながらないはず
  - Windows が使っているポートは、WSL の中のサーバーで使えない
- **ツールの OS に依らない注意は、[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)**: Git・Firefox・git-delta・lazygit・GitHub CLI・yazi のもの。Neovim の注意は、両 OS とも [Neovim のセットアップの注意点](neovim.md#注意点) に、HackGen Console NF・WezTerm・Windows Terminal・シェルのツールの注意は、両 OS とも [シェルと端末のセットアップの注意点](shell-terminal.md#注意点) にある。ここには Windows 11 だけの注意を書く
- **Git: Windows の PowerShell や cmd から呼ぶ git** も、同じ `global`（`C:/Users/<WIN_USER>/.gitconfig`）を読む
  - Windows 11 の PC で、Git Bash・PowerShell・cmd の `git config --global --list --show-origin` が同じファイルを示した
- **Git: Git for Windows を上げるときは、Git の bash を使うものを閉じる**
  - Git Bash の窓、WezTerm のタブ（自分用の設定では Git Bash）など。動いていると、winget で上げてもインストーラが入れ替えずに終わるはず（[Git for Windows・Firefox・WezTerm を上げる](../windows-setup.md#git-for-windowsfirefoxwezterm-を上げる)の[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#git-の記録)・[参考資料](../reference/almalinux-setup.md#git--手順-1-補足-変数について)）
- **Git: Git for Windows 2.56.0 から、内部のパスが `mingw64` から `ucrt64` に変わった**（上流のリリースノート）
  - `C:\Program Files\Git\mingw64\bin\git.exe` を直接指す設定は、上げた後に見直す
- **git-delta: Windows 11 の PowerShell と cmd で打つ git も、delta を通る**: `~/.gitconfig` は Git Bash と同じファイル
  - PowerShell の `git`（`C:\Program Files\Git\cmd\git.exe`）は、Git の `usr\bin` を PATH の先頭に足してから git を動かすので、delta は Git Bash と同じ Git for Windows の less をページャに使う（ソースを読んだだけ。[参考資料](../reference/windows-setup.md#git-delta--手順-5-補足-ページャの-less-と-powershell-の-git)）
  - そのため、scoop の less は入れていない。PowerShell で delta を直に動かす（`git diff | delta` など）ときは、PATH に less が無いので、ページャを使わずに出る
- **GitHub CLI: Windows 11 のトークンの置き場所**: 資格情報マネージャー（Windows 資格情報の汎用資格情報）を優先し、使えない場合は `%APPDATA%\GitHub CLI\hosts.yml` に平文で保存する
- **GitHub CLI: Windows 11 では、gh と git が別々に GitHub にログインする**: git の HTTPS は、Git for Windows の Git Credential Manager が自分のサインインで行う
  - [「GitHub CLI」の手順 4](../windows-setup.md#github-cli)で、Git の認証に `n` と答えるため
  - `gh auth logout`・GitHub CLI の認可の取り消し・gh を消すことは、git の HTTPS の認証に影響しない
- **lazygit: Windows 11 では、winget の lazygit（`JesseDuffield.lazygit`）と両方入れない**: どちらが使われるかが `PATH` の順で決まり、分かりにくくなる。どちらか一方にする
- **yazi: Windows 11 では、`file` を `YAZI_FILE_ONE` で渡す**: 無いと PowerShell から起動した yazi はファイルの種類が分からず、開く・プレビューの規則が効かない（[「yazi」の手順 5](../windows-setup.md#yazi)）。Git for Windows を外すと、同じことになる
  - PowerShell の `PATH` には `file` が無い（Git Bash には `/usr/bin/file` がある）
- **yazi: Windows 11 の画像プレビューは、端末と ConPTY に依存する**: WezTerm（nightly）か Windows Terminal（1.22.10352.0 以降）で出る。ConPTY の制約で、Linux と同じには出ないことがある
- **Firefox: AAC と H.264 のために足すものは無い**: Windows の Media Foundation で復号する（[「Firefox」の手順 4](../windows-setup.md#firefox)の補足）。N エディションの Windows では、Media Feature Pack が要るはず
- **Firefox: 管理者の PowerShell から Firefox を起動しない**: Firefox が管理者の権限で動き、プロファイルに管理者の持ち物のファイルができうる。起動はスタートメニューから
- **Firefox: 言語パックを足さない**: 閉じている間の更新（Background Update）が止まる。別の言語にしたいなら、その言語の `Mozilla.Firefox.<言語>` を入れ直す
- **Firefox: Firefox を開いたまま `winget upgrade` しない**: 入れ替えが途中で終わることがある（[Git for Windows・Firefox・WezTerm を上げる](../windows-setup.md#git-for-windowsfirefoxwezterm-を上げる)の手順 4 の補足）
- **Firefox: 英語版の `Mozilla.Firefox` と同じ `ProductCode`**: winget の定義では、`Mozilla.Firefox` と言語ごとの `Mozilla.Firefox.<言語>` の `ProductCode` が同じ。言語を指定して更新する
