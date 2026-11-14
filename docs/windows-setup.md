# Windows 11 のセットアップ

- 補足・注意点と検証記録は、冒頭と用途末尾の「補足と注意点」から開く

> [!IMPORTANT]
> - **この PC のデスクトップで、Administrators のユーザーが行う**。別の PC や SSH・RDP で行う操作は、各項の実行場所に従う
> - PowerShell のブロックは **PowerShell 7** に貼る（[公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)）。複数行は、[「Windows Terminal で複数行を 1 つの入力として貼る」](shell-terminal.md#windows-terminal-で複数行を-1-つの入力として貼る)を通した窓に貼る。Windows PowerShell 5.1 に貼る項は、その項のリードに書く。管理者・通常の窓は、各項のリードに従う
> - conhost の窓で複数行を右クリックで貼るときは、使う版の PSReadLine の Ctrl+Enter が `AddLine` に割り当てられ、貼った行が順番どおりに 1 つの入力になることを前提にする。未設定の窓では Ctrl+V で貼る

- 新しく入れた PC では、カテゴリを上から順に、要る項を選んで通す
- どの項も単独で通せる。リードの前提を先に満たす
- bash のブロックは、ブラケットペーストの効く端末（GNOME の端末・WezTerm・SSH の先）に貼り、貼った後に Enter を押す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- GitHub のコピーボタンでコピーしたブロックは末尾に改行が無いので、貼った後に Enter を押す
- 設定を更新するときは[更新](#更新)を使う
- 仮想マシン（Hyper-V・VirtualBox・VMware Workstation Pro・Windows Sandbox）は、[仮想マシンのセットアップの「Windows 11 で使う」](virtual-machines.md#windows-11-で使う)で作って使う
- フォント（HackGen Console NF）・Windows Terminal・WezTerm・Git Bash と共通の bash 設定・シェルのツール・PowerShell 7 のプロファイル・PowerShell の開発の設定は、[シェルと端末のセットアップの「Windows 11 で使う」](shell-terminal.md#windows-11-で使う)で整える
- Neovim と Samba のクライアントは、[Neovim のセットアップ](neovim.md#windows-11-で使う)と[Samba のセットアップ](samba.md#windows-11-で使う)の「Windows 11 で使う」で入れる

<details id="この文書の補足と注意点">
  <summary>この文書の補足と注意点</summary>

**注意点**

- **管理者の PowerShell は conhost の窓で開く**: 既定の端末が Windows Terminal でも、管理者として開いた PowerShell は conhost の窓になる

- ツールの OS に依らない注意は、[AlmaLinux 10 のセットアップ](almalinux-setup.md)の各用途の末尾の「補足と注意点」にある。Neovim の注意は、両 OS とも [Neovim のセットアップ](neovim.md)の、HackGen Console NF・WezTerm・Windows Terminal・シェルのツールの注意は、両 OS とも [シェルと端末のセットアップ](shell-terminal.md)の各用途の末尾の「補足と注意点」にある。この文書には Windows 11 だけの注意を書く

**参照**

PowerShell 7 のプロファイル・Windows Terminal の項の資料。「文書」は Microsoft の文書、「コード」はソースと定義。

- 文書: [about_Profiles](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7.6)・[about_Execution_Policies](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.6)・[about_PowerShell_Config](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_powershell_config?view=powershell-7.6)・[about_PSReadLine](https://learn.microsoft.com/en-us/powershell/module/psreadline/about/about_psreadline?view=powershell-7.6)・[about_PSReadLine_Functions](https://learn.microsoft.com/en-us/powershell/module/psreadline/about/about_psreadline_functions?view=powershell-7.6)・[Set-PSReadLineOption](https://learn.microsoft.com/en-us/powershell/module/psreadline/set-psreadlineoption?view=powershell-7.6)・[Using predictors in PSReadLine](https://learn.microsoft.com/en-us/powershell/scripting/learn/shell/using-predictors)・[about_Update_Notifications](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_update_notifications?view=powershell-7.6)・[about_Telemetry](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_telemetry?view=powershell-7.6) — Microsoft Learn

- コード: [PowerShell/PowerShell](https://github.com/PowerShell/PowerShell)（`CorePsPlatform.cs`・`ConsoleHost.cs`・`build.psm1`・`src/Modules/PSGalleryModules.csproj`）・[PowerShell/PSReadLine](https://github.com/PowerShell/PSReadLine)（`KeyBindings.cs`・`History.cs`・`Cmdlets.cs`・`SamplePSReadLineProfile.ps1`）

- コード: [zoxide の templates/powershell.txt](https://github.com/ajeetdsouza/zoxide/blob/v0.10.0/templates/powershell.txt)（0.9.9 も同じ形）・[starship の src/init/starship.ps1](https://github.com/starship/starship/blob/v1.26.0/src/init/starship.ps1)、自分用の設定の [ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm)（`lua/shells.lua`・`shell/wezterm.ps1`）と [ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)（`bashrc`）

- 文書: [Windows Terminal の settings.json の場所](https://learn.microsoft.com/en-us/windows/terminal/install#settings-json-file)・[JSON fragment extensions](https://learn.microsoft.com/en-us/windows/terminal/json-fragment-extensions)・[Profile - Appearance](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-appearance)・[Interaction](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/interaction)・[Startup](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/startup) — Microsoft Learn（interaction のページは古い名前だけ）

- コード: [microsoft/terminal](https://github.com/microsoft/terminal)（`TerminalSettingsModel/MTSMSettings.h`・`CascadiaSettingsSerialization.cpp`・`CascadiaSettings.cpp`・`userDefaults.json`・`TerminalApp/TerminalPage.cpp`・`src/host/VtIo.cpp`・`src/types/utils.cpp`、日本語の訳の `Resources.resw`）

実施環境と再実行の結果は検証記録（`docs/verification/windows-setup.md` の「付録: Windows 11 Pro の VM での導入検証（2026-10-06）」）を参照。

- 検証記録（`docs/verification/windows-setup.md`）

- 検証記録（`docs/verification/windows-setup.md` の「補足の実測」）

</details>

## デスクトップ

- ホットキー競合と、HackGen Console NF を入れた後の再起動とフォントの確認。フォントの導入と Windows Terminal の設定は、[シェルと端末のセットアップの「Windows 11 で使う」](shell-terminal.md#windows-11-で使う)で行う

### Windows のホットキー競合

- 問題が起きるキーを使っているアプリを調べる
- 前提: [Hotkey Screener](https://www.ntwind.com/freeware/hotkey-screener.html)が入っている
- 実行場所: 問題が起きるユーザー・ログインセッションのデスクトップ（Hotkey Screener）

- 問題が起きる Windows 11 のユーザー・ログインセッションで実施する
- 検出時には対象キーが実際に入力され、対応する操作が実行されることもある。先に作業を保存する

- 調べるキーだけ検出する。複数の操作を実行する `Detect All` は使わない

1. Hotkey Screener を起動する。

   - Hotkey Screener を入れた場所の `hkscr64.exe` を開く
   - 問題が起きているアプリと、普段使う常駐アプリを起動した状態で行う
   - アプリの起動・終了後に一覧を更新するときは `Refresh` を押す

1. 一覧から調べたいキーの行を選択する。

   - `Key Combination` 列で、Ctrl・Alt・Shift・Win と通常キーの組み合わせを照合する
   - 一覧は通常キーごとにまとまっている。スクロールして該当するキーを探す
   - キーが見つからない場合は `Refresh` で更新し、それでも無ければ[使用アプリが分からない場合の切り分け](#windows-のホットキー競合-使用アプリが分からない場合の切り分け)へ進む

1. 対象行の使用アプリ検出を実行する。

   - `Application` 列の `Click to detect application` をクリックする
   - 検出中は別のキーを押さず、結果が表示されるまで待つ
   - `Restart as Administrator?` が出た場合は、必要な権限を確認して自分で承認する。権限を使えない環境では管理者へ相談する

1. 表示された使用アプリを確認する。

   - 対象行の `Application` 列に出た実行ファイル名と PID を控える
   - 名前だけで分からなければ、[使用アプリが分からない場合の切り分け](#windows-のホットキー競合-使用アプリが分からない場合の切り分け)の手順 5 で PID と実行パスを照合する
   - 使用アプリが表示されない場合は切り分けへ進む。「未使用」とは判断しない
   - 表示はキーに応答したアプリの情報。元の問題の原因かどうかは次の設定変更で確認する

1. 使用アプリのホットキー設定を変更して動作を確認する。

   - 使用アプリの「ホットキー」「ショートカット」などの設定を開き、変更前のキーと有効状態を控える
   - 対象キーの変更または無効化を行い、元のアプリで問題の操作を同じ条件で試す
   - アプリが再起動を要求する場合は、作業を保存してそのアプリを通常の方法で開き直す
   - 解消しなければ変更を戻し、切り分けへ進む。設定は一度に 1 つだけ変更する
   - 解消した場合は、変更が保存され、通常起動でも必要な操作が動くことを確認する

1. 結果を控えて Hotkey Screener を終了する。

   - 日時、キー、検出されたアプリ、変更前後の設定、実操作の結果を記録する
   - 検出できなかった条件と、元に戻した設定も残す
   - `Command → Exit` またはウィンドウ右上の閉じるボタンで終了する
   - 書き方は検証記録（`docs/verification/windows-hotkey-conflict.md`）を参照する

#### Windows のホットキー競合: 使用アプリが分からない場合の切り分け

- 入力条件と候補アプリを一つずつ変えて、ホットキーの問題を切り分ける
- 前提: [Windows のホットキー競合](#windows-のホットキー競合)で検出を試してある
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7 と、問題が起きるユーザー・ログインセッションのデスクトップ。この項の手順 1 で開く

- 対象キーが一覧にない場合、検出でアプリが表示されない場合、設定変更で解消しない場合に行う

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる
   - 窓の名前に「管理者:」が付いていないことを確かめる

1. 対象キーと、メニューからの操作結果を記録する。

   - キー、対象アプリ、期待する動作、実際の動作を控える
   - メニューやコマンドパレットから同じ機能を実行する
   - メニューからも動かない場合は、機能・設定・アプリのエラーを先に調べる

1. キー割り当てとフォーカスを確認する。

   - 対象アプリの設定で、キー・操作・有効な画面やモードを確認する
   - 入力領域をクリックしてから、対象キーと正常な比較用キーを試す
   - アプリが入力ログ機能を持つ場合は、押下・解放・実行された操作を確認する
   - 押下が届かないことだけで、使用アプリ名は特定できない

1. IME と接続条件を変えて結果を比較する。

   - IME のオン・オフ、入力モード、キーボードレイアウトを控えてから 1 条件ずつ試す
   - リモート接続中なら、接続元・接続先とキーの転送設定を確認する
   - 可能なら PC の画面とキーボードでも比較し、試験後は入力条件を元に戻す

1. Windows で実行中のアプリを一覧にする。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-CimInstance Win32_Process |
       Sort-Object Name, ProcessId |
       Select-Object Name, ProcessId, SessionId, ExecutablePath |
       Format-Table -AutoSize -Wrap
   ```

   - 名前・PID・実行パスから、タスクトレイの常駐アプリと照合する
   - 画面録画、オーバーレイ、クリップボード管理、キー変更、リモート接続のアプリを確認する
   - 実行パスが空のプロセスもある。空という理由だけで除外しない
   - 実行中というだけでは原因を確定しない。共有する出力ではユーザー名などを伏せる

1. 候補アプリ 1 つのホットキーを無効化する。

   - 設定画面で対象キー、対応する操作、有効状態を確認して控える
   - アプリにフォーカスがある間だけのキーか、ほかのアプリ上でも使うキーかを区別する
   - 対象キーの設定だけ無効化する。設定が無ければ作業を保存してアプリを通常終了する
   - ドライバーやシステムサービスの停止、候補の一括終了は行わない

1. 同じ条件で問題の操作を確認する。

   - 解消しなければ候補の設定を元に戻し、終了した候補を通常起動してから、この項の手順 6 で次の候補を調べる
   - 解消した場合は[Windows のホットキー競合](#windows-のホットキー競合)の手順 5 で必要な設定と保存状態を確認し、同じ項の手順 6 で結果を残して終了する
   - 特定できない場合は、[ホットキーの登録可否を確認する](#windows-のホットキー競合-ホットキーの登録可否を確認する)も使い、試した入力条件・候補・ログを追加調査用に残す

#### Windows のホットキー競合: ホットキーの登録可否を確認する

- 対象キーを一時登録して、登録できるかを確かめる
- 前提: [使用アプリが分からない場合の切り分け](#windows-のホットキー競合-使用アプリが分からない場合の切り分け)で対象キーを絞ってある
- 実行場所: この PC のデスクトップの、問題が起きるユーザー・ログインセッションの新しい管理者ではない PowerShell 7。この項の手順 1 で開く

- アプリ名を返す試験ではない。登録成功でも、IME や入力フックによる処理は除外できない

- 試験中だけ対象キーを一時登録し、直ちに解除する。コードの実行中は対象キーを押さない

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる
   - 窓の名前に「管理者:」が付いていないことを確かめる

1. 試験する修飾キーと仮想キーコードを設定する。

   ```powershell
   $taskHotkeyModifiers = 0x0001 -bor 0x0002 -bor 0x0004
   ```

   ```powershell
   $taskHotkeyVirtualKey = 0x79
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'Modifiers=0x{0:X}; VirtualKey=0x{1:X}' -f $taskHotkeyModifiers, $taskHotkeyVirtualKey
   ```

   - 例は Ctrl+Alt+Shift+F10。対象キーに合わせて両方の値を変える。Alt は `0x0001`、Ctrl は `0x0002`、Shift は `0x0004`、Windows は `0x0008` を `-bor` で結ぶ
   - A〜Z は `0x41`〜`0x5A`、0〜9 は `0x30`〜`0x39`。ほかのキーは[公式の仮想キー一覧](https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes)で調べる
   - 例のままなら `Modifiers=0x7; VirtualKey=0x79` が出る。変えた場合は、指定した修飾キーと通常キーの値になっていること

1. 同じスレッドで登録・解除する診断コードを読み込む。

   ```powershell
   # ホットキーの登録可否を調べる操作を定義する
   if (-not ('HotkeyAvailabilityProbe' -as [type])) {
       Add-Type -TypeDefinition @'
   using System;
   using System.ComponentModel;
   using System.Runtime.InteropServices;
   using System.Threading;

   public static class HotkeyAvailabilityProbe {
       [DllImport("user32.dll", SetLastError = true)]
       [return: MarshalAs(UnmanagedType.Bool)]
       private static extern bool RegisterHotKey(IntPtr hwnd, int id, uint mods, uint vk);

       [DllImport("user32.dll", SetLastError = true)]
       [return: MarshalAs(UnmanagedType.Bool)]
       private static extern bool UnregisterHotKey(IntPtr hwnd, int id);

       // -1 は登録成功・解除済み。それ以外は登録失敗のエラー番号。
       public static int Test(uint modifiers, uint virtualKey) {
           int result = 0;
           int releaseError = 0;
           bool releaseFailed = false;
           Exception failure = null;
           Thread thread = new Thread(delegate() {
               bool registered = false;
               try {
                   registered = RegisterHotKey(IntPtr.Zero, 1, modifiers, virtualKey);
                   result = registered ? -1 : Marshal.GetLastWin32Error();
               } catch (Exception ex) {
                   failure = ex;
               } finally {
                   if (registered && !UnregisterHotKey(IntPtr.Zero, 1)) {
                       releaseError = Marshal.GetLastWin32Error();
                       releaseFailed = true;
                   }
               }
           });
           thread.Start();
           thread.Join();
           if (failure != null) {
               throw new InvalidOperationException("Hotkey probe failed", failure);
           }
           if (releaseFailed) {
               throw new Win32Exception(releaseError, "Hotkey cleanup failed");
           }
           return result;
       }
   }
   '@
   }
   ```

   - エラーが出た場合は次の手順を実行せず、PowerShell を閉じてコードを確認する

1. 対象キーの登録可否を確認する。

   ```powershell
   # ホットキーの登録可否を試験する
   $taskHotkeyResult = [HotkeyAvailabilityProbe]::Test($taskHotkeyModifiers, $taskHotkeyVirtualKey)
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   switch ($taskHotkeyResult) {
       -1 { '登録可能。試験用の登録は解除済み。入力フックや IME は別途確認する。' }
       1409 { '既に登録済み。使用アプリ名はこの結果からは分からない。' }
       default { '登録失敗。エラー番号: {0}。1409 以外を競合と断定しない。' -f $taskHotkeyResult }
   }
   ```

   - 1409 なら、候補アプリ 1 つの無効化前後で同じ試験と実操作を比較する
   - `Hotkey cleanup failed` などの例外が出た場合は成功扱いにせず、この PowerShell を閉じる
   - [使用アプリが分からない場合の切り分け](#windows-のホットキー競合-使用アプリが分からない場合の切り分け)の手順 6へ戻り、アプリ設定と実操作で候補を絞る

<details id="windows-のホットキー競合-の補足と注意点">
  <summary>Windows のホットキー競合 の補足と注意点</summary>

**[Windows のホットキー競合](#windows-のホットキー競合)の手順 1・2: 登録一覧に載るホットキー**

- Hotkey Screener の公式説明では、`RegisterHotKey` で登録されたシステム全体のホットキーを列挙する
- アプリ内だけで使うキー割り当てや、入力フックで処理するキーを網羅する一覧ではない
- 対象の組み合わせが一覧に無くても、そのキーを使うアプリが無いとは判断しない

| キーを処理する仕組み | 調べる範囲 |
| --- | --- |
| `RegisterHotKey` による登録 | Hotkey Screener の登録一覧と、対象キーの検出結果 |
| アプリ内のキー割り当て | 対象アプリの設定、フォーカス、操作モード |
| キーボードフックなどの入力処理 | 常駐アプリの機能と、入力条件をそろえた変更前後の動作 |

- `RegisterHotKey` の資料は、ホットキーをシステム全体の登録として定義している（[Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-registerhotkey)）
- 主手順で調べるのは、登録一覧にある対象キーに反応したアプリ。すべての入力処理の所有者を列挙した結果として扱わない

**[Windows のホットキー競合](#windows-のホットキー競合)の手順 3: Detect application の検出方式**

- 検証した画面の `Application` 列にある `Click to detect application` が、公式説明の `Detect application` に当たる操作
- 公式説明では、グローバルなメッセージフックの DLL を使い、選んだホットキーの入力を模擬して、そのイベントを待つ（[Hotkey Screener](https://www.ntwind.com/freeware/hotkey-screener.html)）
- 検出は登録情報だけを読む操作ではない
- 公式は 32 bit・64 bit、通常権限・管理者権限のプロセスへの対応を説明している。個々の環境での検出成否は検証記録で管理する

**[Windows のホットキー競合](#windows-のホットキー競合)の手順 4: 使用アプリの情報と Windows の通知**

- `RegisterHotKey` で登録したキーが押されると、Windows は登録先へ `WM_HOTKEY` を投稿する
- `WM_HOTKEY` の `wParam` はホットキーの識別子、`lParam` は修飾キーと仮想キーコードを表す。メッセージのパラメーターに使用アプリ名や PID が入っているわけではない（[WM_HOTKEY](https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-hotkey)）
- 登録先のウィンドウハンドルが分かる場合は、`GetWindowThreadProcessId` でそのウィンドウを作成したスレッドとプロセスの ID を取得できる。この関数はキーの組み合わせから所有アプリを検索するものではない（[Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowthreadprocessid)）
- `RegisterHotKey` の `hWnd` が `NULL` なら、通知先は登録したスレッドのメッセージキューになる。特定のウィンドウを経由しない登録もある
- Hotkey Screener が `hWnd = NULL` の登録をどこまで検出するかは、公式ページに明示されていない。今回確認した登録方式は検証記録に残し、全種類の登録への対応を保証しない
- 表示されたアプリ名と PID を実行中のプロセスと照合する。同名の実行ファイルが複数ある場合も、名前だけで同じプロセスと判断しない
- 検出結果はアプリを調べる手がかりとして使い、そのアプリの対象キーの設定と変更後の動作を照合する

**[Windows のホットキー競合](#windows-のホットキー競合)の手順 5: 設定を一つずつ変える理由**

- 検出したアプリの同じキーを解除または変更し、変更前と同じウィンドウ・入力方式・キー操作で比較する
- 複数のアプリをまとめて止めると、どの変更で競合が解消したか分からなくなる
- 設定変更で改善しなかった場合は元に戻す。アプリを終了して比較した場合は、通常起動してから次の候補へ進む
- 設定画面に同じキーがあるだけでは、その時点で取り込んでいることまでは確定しない。設定の一致、検出結果、変更後の実操作を区別して記録する
- 解消した競合を記録するために、問題の設定を再び有効にすることは必須にしない

**[Windows のホットキー競合](#windows-のホットキー競合)の手順 6: 記録と診断ツールの終了**

- 対象キー、検出したアプリ情報、変更前後の設定、実操作の結果を残す。未検出の状態と、登録一覧に無い状態は分けて書く
- 調査したユーザー・ログインセッションや入力方式が違えば結果も変わり得るため、比較した条件を残す
- Hotkey Screener の終了時に、検出用 DLL が各プロセスから直ちに解放されるかは公式ページに明示されていない
- ツールの終了確認と、DLL の解放確認は同じではない。終了だけで DLL の解放まで確認したと記録しない
- 共有する記録では、ユーザー名などを含む実行パスの固有部分を伏せる

**[Windows のホットキー競合: 使用アプリが分からない場合の切り分け](#windows-のホットキー競合-使用アプリが分からない場合の切り分け)のリード**

- 表示がない理由と、入力フック・アプリ内ショートカットの検出範囲はこの折りたたみの「参照」を参照する

**[Windows のホットキー競合: 使用アプリが分からない場合の切り分け](#windows-のホットキー競合-使用アプリが分からない場合の切り分け)の手順 1〜7: 登録と入力フックを分ける**

- Hotkey Screener の公式説明には、あるアプリが登録したキーを、別のアプリが低レベルキーボードフックや raw input で抑止するため、検出できない場合がある
- `WH_KEYBOARD_LL` のフックは `RegisterHotKey` と別の仕組み。フックが非ゼロを返すと、キーを後続のフックや対象ウィンドウへ渡さないことができる（[LowLevelKeyboardProc](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/legacy/ms644985(v=vs.85))）
- ツールがメッセージフックを使うことは、入力を抑止した低レベルフックの所有アプリまで調べられることを意味しない
- 一覧に対象キーが無い場合と、一覧にはあるが検出結果が表示されない場合は区別する。どちらも「使用アプリ無し」の証明にはしない
- 対象アプリのメニューからの動作、入力方式、フォーカス、接続方法をそろえ、常駐アプリの設定を一つずつ比較する
- 入力ログにキーの押下が無い場合も、そのログだけで特定アプリを原因と決めない

**[Windows のホットキー競合: ホットキーの登録可否を確認する](#windows-のホットキー競合-ホットキーの登録可否を確認する)の手順 3・4: 同じスレッドで解除する理由**

- `hWnd = NULL` で登録したホットキーは呼び出したスレッドに属する。`UnregisterHotKey` は呼び出しスレッドが登録したホットキーを解除する（[RegisterHotKey](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-registerhotkey)、[UnregisterHotKey](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-unregisterhotkey)）
- PowerShell から登録と解除を別々に呼ぶ構成にせず、同じスレッド内で登録、エラー取得、解除まで完了する構成にする
- 登録失敗のエラーはその直後に取得する。成功時の古いエラー値を今回の結果として使わない
- 解除するのは、試験自身が登録に成功した場合だけ。競合で登録に失敗したときに、既存アプリの登録を解除しようとしない
- 解除の成否も確認する。解除失敗を登録可能の正常結果に含めず、診断用 PowerShell を閉じてから対象アプリの確認へ進む

**[Windows のホットキー競合: ホットキーの登録可否を確認する](#windows-のホットキー競合-ホットキーの登録可否を確認する)の手順 4: RegisterHotKey で分かる範囲**

| 試験結果 | 分かること | この結果だけでは分からないこと |
| --- | --- | --- |
| 登録成功 | その実行環境と時点で登録が成功した | 入力フックの有無、対象アプリへ実入力が届くこと、アプリ内の割り当ての正しさ |
| 登録失敗・エラー 1409 | 対象ホットキーが既に登録されている | 既存登録の使用アプリや PID |
| 登録失敗・それ以外のエラー | 指定した登録試験が失敗した | 別アプリとの競合が原因かどうか |

- エラー 1409 は `ERROR_HOTKEY_ALREADY_REGISTERED`（[System Error Codes](https://learn.microsoft.com/en-us/windows/win32/debug/system-error-codes--1300-1699-)）
- `RegisterHotKey` の戻り値は成否で、既存の登録先のウィンドウ、スレッド、PID を返す引数や戻り値は無い
- 登録成功を「誰もこのキーを使っていない」と言い換えない。OS の一部の既定ホットキーは、アプリが前面にある条件で上書きできることも資料に記載されている
- 登録試験は対象キーの入力を模擬しない。実入力と対象アプリの動作は別に確認する
- この試験は一瞬でもシステム全体のホットキーを登録するため、完全な読み取り専用操作ではない。対象の一組だけを短時間登録して、すぐ解除する補助として使う

**選択した方針**

- 対象キーの使用アプリを調べる主手順は、Hotkey Screener の登録一覧から対象を選んで検出する形にする
- 検出したアプリのキー設定と、変更後の実操作を合わせて判断する
- 一覧に無いキーや未検出の状態は、一般的な入力の切り分けへ進む分岐として残す
- PowerShell の登録可否試験は任意の補助にする。使用アプリを取得する機能ではなく、入力フックなども検出できないため
- ツールの実機での確認範囲は検証記録へ分け、公式説明だけで実機検証済みにしない

**参照**

- [Hotkey Screener — NTWind Software](https://www.ntwind.com/freeware/hotkey-screener.html)（登録一覧、検出方式、Windows 対応、権限、未検出の条件）
- [RegisterHotKey — Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-registerhotkey)（システム全体の登録、成否、スレッドへの所属、OS の既定ホットキー）
- [WM_HOTKEY — Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-hotkey)（通知先、識別子、修飾キー、仮想キーコード）
- [GetWindowThreadProcessId — Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowthreadprocessid)（指定したウィンドウの作成元スレッドとプロセス）
- [UnregisterHotKey — Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-unregisterhotkey)（呼び出しスレッドが登録したホットキーの解除）
- [System Error Codes (1300–1699) — Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/debug/system-error-codes--1300-1699-)（1409）
- [LowLevelKeyboardProc — Microsoft Learn](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/legacy/ms644985(v=vs.85))（低レベルフックによる入力の抑止）

- 検証記録（`docs/verification/windows-hotkey-conflict.md`）

</details>

---

### 再起動

- HackGen Console NF をアプリで使えるようにするため、この PC を再起動する
- 前提: [Windows 11 で HackGen Console NF を入れる](shell-terminal.md#windows-11-で-hackgen-console-nf-を入れる)を通してある
- 実行場所: この PC のデスクトップの管理者の PowerShell 7。この項の手順 1 で開く
- この項の手順 2 は、すぐに再起動を始める。保存していない作業は先に保存する

1. 管理者の PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、右クリックして「管理者として実行」を選ぶ（「Windows PowerShell」ではない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる
   - UAC の確認で「はい」を押す。窓の名前が「管理者:」で始まる

1. 再起動する。

   ```powershell
   Restart-Computer
   ```

   - ほかのユーザーがサインインしていると、エラーで止まる。そのときは、スタートメニューの電源から再起動する
   - 起動してサインインしてから、後の項へ進む

<details id="再起動-の補足と注意点">
  <summary>再起動 の補足と注意点</summary>

**参照**

- 検証記録（`docs/verification/windows-setup.md`）

</details>

---

### 再起動の後に確かめる

- HackGen Console NF がフォントの一覧に出ることを確かめる
- 前提: [Windows 11 で HackGen Console NF を入れる](shell-terminal.md#windows-11-で-hackgen-console-nf-を入れる)を通し、再起動またはサインアウトしてサインインし直してある
- 実行場所: この PC のデスクトップ（設定・メモ帳）

1. フォントの一覧で、HackGen Console NF が出ることを確かめる。

   - 設定 → 個人用設定 → フォント を開き、「HackGen」で探すと、`HackGen Console NF` と `HackGen35 Console NF` が出る（どちらも「2 フォント フェイス」）
   - ライセンス認証していない Windows では、フォントの画面の検索欄が使えないことがある。そのときは一覧をスクロールして探す
   - メモ帳のフォントの一覧に出ても同じ
   - 端末のフォントにするなら、アプリの設定にファミリー名 `HackGen Console NF` を書く（WezTerm は `config.font = wezterm.font 'HackGen Console NF'`。自分用の設定（`ryo-aoki-pc/wezterm`）は、もうこのフォントを使う）

<details id="再起動の後に確かめる-の補足と注意点">
  <summary>再起動の後に確かめる の補足と注意点</summary>

**参照**

- 検証記録（`docs/verification/windows-setup.md`）

</details>

---

## ネットワークとリモート操作

- RDP の切断

### RDP をロックせずに切断

- RDP のセッションをこの PC の画面へ移し、ロックせずに切断する
- 前提: [リモート デスクトップの公式の案内](https://support.microsoft.com/en-us/windows/how-to-use-remote-desktop-5fe128d5-8fb1-7a23-3b8a-41e636865e8c)に従って RDP を有効にした Windows 11 Pro 以上に、サインイン中の Administrators のユーザーで RDP 接続している
- 実行場所: この PC のデスクトップ（RDP 接続先）の管理者の PowerShell 7。この項の手順 1 で開く。切断後は接続先の PC の画面で確かめる

- この項の手順 1〜3 は RDP のセッションの中で行う。この項の手順 3 を貼ると、その場で RDP が切れる
- この項の手順 4 は、接続先の PC の画面で行う

> [!WARNING]
> - **この項の手順 3 で切断した後の PC の画面はロックされない**。PC の前にいる人が、このユーザー（Administrators の一員）としてそのまま操作できる。人が触れる場所にある PC では使わない

1. RDP でつないだセッションの中で、管理者の PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、右クリックして「管理者として実行」を選ぶ（「Windows PowerShell」ではない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる
   - UAC の確認で「はい」を押す
   - ウィンドウのタイトルが「管理者:」で始まる
   - **次の手順は、このウィンドウが開いてから、そこに貼る**

1. 今のセッションが RDP であることと、その ID を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   quser
   'このセッションの ID: {0}' -f (Get-Process -Id $PID).SessionId
   ```

   - `quser` の自分の行（先頭に `>` が付く）のセッション名が `rdp-tcp#<N>` で、状態が `Active`
   - その行の ID と、最後の行の ID が同じ
   - 自分の行のセッション名が `console` なら、PC の前のセッション（RDP ではない）。この項の手順 3 は貼らない

1. セッションを PC の画面（コンソール）へ移し、RDP を切る。

   ```powershell
   tscon.exe (Get-Process -Id $PID).SessionId /dest:console
   ```

   - RDP のクライアントの窓が閉じる（クライアントが切断を知らせる）
   - 切れずに PowerShell にエラーが出たときは、管理者の PowerShell かを確かめて、この項の手順 1 からやり直す
   - **次の手順は、RDP が切れてから、接続先の PC の画面で行う**（切断後は、接続先の PC の画面でデスクトップを確かめる）

1. 接続先の PC の画面で、デスクトップに戻ったことを確かめる。

   - ロック画面ではなく、RDP で開いていたままのデスクトップが出ていればよい

#### RDP をロックせずに切断: ショートカットで切断する

- 作ってあるショートカットで、RDP をロックせずに切断する
- 前提: [リモート デスクトップの公式の案内](https://support.microsoft.com/en-us/windows/how-to-use-remote-desktop-5fe128d5-8fb1-7a23-3b8a-41e636865e8c)に従って RDP を有効にした Windows 11 Pro 以上に、サインイン中の Administrators のユーザーで RDP 接続している。デスクトップに「RDP をロックせずに切断」の、管理者として実行するショートカットがある。切断の注意は[RDP をロックせずに切断](#rdp-をロックせずに切断)を先に読む
- 実行場所: この PC のデスクトップ（RDP 接続先）。切断後は接続先の PC の画面で確かめる

- **この項の手順 1 で切断した後の画面はロックされない**。人が触れる場所にある PC では使わない

1. 切断するときは、RDP でつないだセッションの中で、デスクトップのショートカットをダブルクリックする。

   - UAC の確認（Windows PowerShell）で「はい」を押すと、RDP が切れる（[RDP をロックせずに切断](#rdp-をロックせずに切断)の手順 3 と同じ）
   - 切れないときは、[RDP をロックせずに切断](#rdp-をロックせずに切断)の手順 1〜3 で切って、エラーを見る
   - PC の前（コンソール）では使わない
   - 切った後の確かめ方は、[RDP をロックせずに切断](#rdp-をロックせずに切断)の手順 4 と同じ

<details id="rdp-をロックせずに切断-の補足と注意点">
  <summary>RDP をロックせずに切断 の補足と注意点</summary>

**注意点**

- PC の前で Win+L を押すとロックできる
- **次に RDP でつなぐと、PC の画面はまたロック画面になる**: セッションが RDP へ移るため。切るときは、また [RDP をロックせずに切断](#rdp-をロックせずに切断)の手順で切る
- **ふつうに切断してしまったとき**: もう 1 度 RDP でつないでから、[RDP をロックせずに切断](#rdp-をロックせずに切断)の手順で切る
- **画面の大きさ**: セッションは PC のモニターの解像度に戻るので、RDP の窓に合わせて並べた窓の位置や大きさが変わることがある
- **モニターの無い PC・蓋を閉じたノート PC**: 蓋を閉じたときの動作は Windows の電源設定に従う。事前にスリープの設定を確かめる
- **クリップボード**: SmartBear の資料は、クリップボードが空でないまま切ると、RDP のクリップボードの共有（`rdpclip.exe`）が失敗することがあると書いている

**[RDP をロックせずに切断](#rdp-をロックせずに切断)の手順 1: 管理者の PowerShell を使う理由**

検証記録（`docs/verification/windows-rdp-disconnect.md` の「実施手順 / 手順 1: 補足: 管理者の PowerShell を使う理由」）

- `tscon` で今のセッションを PC の画面（コンソール）へ移すときは、管理者として実行する（SmartBear の TestComplete の資料）
- Microsoft の `tscon` の資料は、別のセッションにつなぐには、フル コントロールか「接続」の特殊なアクセス許可が要ると書いている
- 管理者として開いた PowerShell も、RDP でつないだのと同じセッションで動く。[RDP をロックせずに切断](#rdp-をロックせずに切断)の手順 2・3 は、このプロセスのセッションの ID を使う
- 32 ビットの PowerShell では `System32` が `SysWOW64` に読み替えられ、`tscon.exe` が見つからないことがある

**[RDP をロックせずに切断](#rdp-をロックせずに切断)の手順 2: RDP でつないだときのセッション**

検証記録（`docs/verification/windows-rdp-disconnect.md` の「実施手順 / 手順 2: 補足: RDP でつないだときのセッション」）

- Windows 11 の Pro では、PC にサインインしているのと同じユーザーで RDP でつなぐと、新しいセッションは作られず、そのセッションが RDP へ移る。PC の画面はロック画面になる
- ふつうに切断する（RDP の窓を閉じる）と、セッションは `Disc`（切断）の状態で残り、PC の画面はロック画面のまま。アプリは動き続ける
- セッションの ID はつなぎ直しても変わらず、セッション名だけが `console` と `rdp-tcp#<N>` で入れ替わる（`<N>` はつなぐたびに変わる）

**[RDP をロックせずに切断](#rdp-をロックせずに切断)の手順 3: tscon がすること**

- `tscon <セッションの ID> /dest:console` は、そのセッションを `console`（PC の画面とキーボード）につなぎ、今つないでいる RDP を切る（Microsoft の `tscon` の資料の `/dest`）
- 同じユーザーのセッションなので、`/password` は要らない（資料は、別のユーザーのセッションにつなぐときに要ると書いている）
- Microsoft の資料の注意書きの「コンソールのセッションにはつなげない」は、つなぐ先のセッション（最初の引数）に `console` を指すことを言う、と読める。本書は最初の引数に今の RDP のセッションを指し、`/dest:` に `console` を指す（SmartBear の資料と同じ使い方）
- セッションの ID は、`quser` の出力を切り出さずに、この PowerShell のプロセスのセッションの ID（`Process.SessionId`。ターミナル サービスのセッションの ID）から取る。出力の列の位置に頼らないため
- PC の画面は、ロック画面を通らずにデスクトップになる。開いていたアプリはそのまま

**[RDP をロックせずに切断: ショートカットで切断する](#rdp-をロックせずに切断-ショートカットで切断する)のリード**

- UAC の確認は毎回出る。ショートカットは、管理者として実行する Windows PowerShell で `tscon` を動かす

**[RDP をロックせずに切断: ショートカットで切断する](#rdp-をロックせずに切断-ショートカットで切断する)の手順 1: 切れないとき**

- ショートカットは窓を隠して動かすので、切れないときのエラーが見えない。そのため、[RDP をロックせずに切断](#rdp-をロックせずに切断)の手順 1〜3 で切ってエラーを見る

**選択した方針**

検証記録（`docs/verification/windows-rdp-disconnect.md` の「選択した方針」）

- **`tscon` で、今のセッションを PC の画面（コンソール）へ移して切る**

  - UI の自動テストの道具（SmartBear の TestComplete など）が、テストを動かしたまま RDP を切る方法として、同じことを案内している
- **セッションの ID は、PowerShell のプロセスから取る**
  - SmartBear の資料のバッチは、`query user` の出力の 3 列目を ID として取る
  - 本書は出力の列の位置に頼らず、この PowerShell が動いているセッション（RDP でつないでいるセッション）の ID を `(Get-Process -Id $PID).SessionId` で取る
- **採らなかった案**
  - ふつうの切断（RDP の窓を閉じる）: PC の画面がロック画面になる
  - サインアウト: セッションが終わり、動いていたアプリも終わる

**参照**

- [tscon — Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/tscon)（`/dest`、`/password` が要る条件、コンソールのセッションの注意書き）
- [quser — Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/quser)（列の意味、今のセッションに付く `>`）
- [Enable Remote Desktop on your PC — Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/remotepc/remote-desktop-allow-access)（設定の「システム → リモート デスクトップ」、Home は RDP でつながれる側になれないこと）
- [Process.SessionId — Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.process.sessionid)（プロセスのターミナル サービスのセッションの ID）
- [Disconnecting From Remote Desktop While Running Automated Tests — SmartBear TestComplete](https://support.smartbear.com/testcomplete/docs/testing-with/running/via-rdp/keeping-computer-unlocked.html)（`tscon … /dest:console` を管理者として実行する、ロックされないことの注意、`rdpclip.exe`）

- 検証記録（`docs/verification/windows-rdp-disconnect.md`）

</details>

---

## SSH

- Windows の OpenSSH クライアントと、接続先の認証

### Windows の OpenSSH クライアント

- Windows と Git の ssh で同じ接続設定と鍵を使い、AlmaLinux 10 のホストにログインする
- 前提: [Git for Windows](https://gitforwindows.org/)を通してある。つなぐ先の AlmaLinux 10 のホストでは sshd が動き、そのユーザーのパスワードで SSH に入れる（[AlmaLinux 10 のセットアップ](almalinux-setup.md)の標準の Workstation）。WezTerm の起動メニューを試すときは[Git Bash と WezTerm の設定](shell-terminal.md#git-bash-と-wezterm-の設定)も通してある
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く。この項の手順 8 は AlmaLinux 10 のホストの自分のユーザーの端末（bash）
- Windows で変えるのは、自分のユーザーの `%USERPROFILE%\.ssh` だけ。ホストでは、この項の手順 9 で自分のユーザーの `~/.ssh/authorized_keys` に足す
- ssh-agent は使わない。鍵にパスフレーズを付けたら、その鍵を使うたびに聞かれる

1. Windows で、管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. 変数を設定する（`SSH_HOST` と `SSH_ALIAS` は必ず値を入れる）。

   ```powershell
   $SSH_HOST = ''                        # ← AlmaLinux 10 のホストの IP アドレスか DNS 名。<SSH_HOST>
   ```

   ```powershell
   $SSH_ALIAS = ''                       # ← ssh で打つ短い名前（英数字と - _ だけ。例 alma）。<SSH_ALIAS>
   ```

   ```powershell
   $SSH_USER = $env:USERNAME             # ホストのユーザー名（自動で Windows のユーザー名が入る。違えば直す）。<SSH_USER>
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'SSH_HOST  = {0}' -f $SSH_HOST
   'SSH_ALIAS = {0}' -f $SSH_ALIAS
   'SSH_USER  = {0}' -f $SSH_USER
   ```

   - `SSH_USER` は、AlmaLinux 10 のホストのユーザー名にする。Windows のユーザー名（`C:\Users\` の下のフォルダーの名前）と、大文字・小文字やつづりが違えば直す
   - `SSH_USER` に `root` は使わない
   - **新しい PowerShell を開いたら**、この項の手順 2 の 3 つのブロックを貼り直してから先へ進む

1. 2 つの ssh の版と `PATH` の順、鍵・config・Git の ssh の設定を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # Windows と Git の SSH の版と場所を確認する
   & "$env:WINDIR\System32\OpenSSH\ssh.exe" -V
   & 'C:\Program Files\Git\usr\bin\ssh.exe' -V
   Get-Command ssh, ssh-keygen -All -ErrorAction SilentlyContinue | Format-Table Source
   # SSH の鍵と設定ファイルの有無を確認する
   Test-Path "$env:USERPROFILE\.ssh\id_ed25519", "$env:USERPROFILE\.ssh\id_ed25519.pub", "$env:USERPROFILE\.ssh\config"
   # Git の SSH とホームの指定を確認する
   git config --show-origin --get-all core.sshCommand
   'GIT_SSH={0} GIT_SSH_COMMAND={1} HOME={2}' -f $env:GIT_SSH, $env:GIT_SSH_COMMAND, $env:HOME
   ```

   - 1 行目に Windows の OpenSSH 9.5p2 以降の版、2 行目に Git の OpenSSH の版が出ればよい
   - 1 行目が「認識されません」のエラーなら、Windows の OpenSSH クライアントが無い。設定の「オプション機能」（`ms-settings:optionalfeatures`）で「OpenSSH クライアント」を追加してから始める（追加には管理者の承認が要る）
   - `core.sshCommand` の行は出ず、最後の行は `GIT_SSH= GIT_SSH_COMMAND= HOME=` であればよい
   - どれかに値があれば、git が別の ssh か別の `.ssh` を使う。その設定を外すまで、この項の手順 7・9 の Git の ssh の確かめは、git の動きと一致しない

1. 鍵ペアが無いときだけ、ed25519 で作る（公開鍵だけが無ければ作り直す）。

   ```powershell
   # SSH の鍵の保存先を設定する
   $k = "$env:USERPROFILE\.ssh\id_ed25519"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if ((Test-Path -LiteralPath $k) -and (Test-Path -LiteralPath "$k.pub")) {
     "既にある: $k（この鍵を使う）"
   } elseif (Test-Path -LiteralPath $k) {
     $p = & "$env:WINDIR\System32\OpenSSH\ssh-keygen.exe" -y -f $k
     if ([string]$p -match '^ssh-ed25519 AAAA') {
       Set-Content -LiteralPath "$k.pub" -Value $p -Encoding ascii
       "公開鍵を作り直した: $k.pub"
     } else {
       Write-Error "中断: $k から ed25519 の公開鍵を作れなかった"
     }
   } else {
     New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.ssh" | Out-Null
     & "$env:WINDIR\System32\OpenSSH\ssh-keygen.exe" -t ed25519 -f $k
   }
   ```

   - 鍵の対があれば、`既にある: …` と出て何もしない
   - 秘密鍵だけがあれば、秘密鍵から公開鍵（`id_ed25519.pub`）を作り直し、`公開鍵を作り直した: …` と出る。秘密鍵にパスフレーズがあれば聞かれる
   - `中断: … 公開鍵を作れなかった` の前に `UNPROTECTED PRIVATE KEY FILE!` が出ていれば、この項の手順 5・6 で秘密鍵のアクセス権を直してから、この手順を貼り直す
   - その表示が無ければ、パスフレーズが違う。この手順を貼り直す
   - 鍵が無ければ、`Enter passphrase (empty for no passphrase):` と `Enter same passphrase again:` でパスフレーズを 2 回聞かれ、鍵の指紋が出る
   - パスフレーズを付けると、鍵を使うたびに聞かれる。空にすると聞かれないが、秘密鍵のファイルを持つ人は誰でも入れる
   - **次の手順は、パスフレーズを入力し終えてから貼る**（終わる前に貼ると、動いているコマンドへの入力になる）

1. 秘密鍵のアクセス権を確かめる。

   ```powershell
   icacls.exe "$env:USERPROFILE\.ssh\id_ed25519"
   ```

   - 出てくる主体が `NT AUTHORITY\SYSTEM`・`BUILTIN\Administrators`・自分のユーザー（`<HOSTNAME>\<WIN_USER>`）の 3 つだけならよい（`(I)` の付いた、受け継いだものでもよい）
   - ほかの主体（`Everyone`・`BUILTIN\Users`・`NT AUTHORITY\Authenticated Users` など）があれば、この項の手順 6 で直す。無ければこの項の手順 6 は飛ばす

1. ほかの主体に許可があるときだけ、秘密鍵のアクセス権を直す。

   ```powershell
   # 秘密鍵のアクセス権を設定する
   $f = "$env:USERPROFILE\.ssh\id_ed25519"
   $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
   icacls.exe $f /reset
   icacls.exe $f /inheritance:r /grant:r "*${sid}:F" /grant:r '*S-1-5-18:F' /grant:r '*S-1-5-32-544:F'
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   icacls.exe $f
   ```

   - 最後の `icacls` に、`NT AUTHORITY\SYSTEM:(F)`・`BUILTIN\Administrators:(F)`・`<HOSTNAME>\<WIN_USER>:(F)` の 3 行だけが出ればよい

1. `~/.ssh/config` に接続先を足し、Windows と Git の両方の ssh で読めることを確かめる。

   ```powershell
   # SSH の接続値と設定ファイルを確認する
   $f = "$env:USERPROFILE\.ssh\config"
   if (-not $SSH_HOST -or -not $SSH_ALIAS -or -not $SSH_USER) {
     Write-Error '中断: この項の手順 2 の SSH_HOST・SSH_ALIAS・SSH_USER のどれかが空のまま。値を入れて貼り直す'
   } elseif ($SSH_ALIAS -notmatch '^[A-Za-z0-9_-]+$' -or $SSH_HOST -notmatch '^[A-Za-z0-9.:_-]+$' -or $SSH_USER -notmatch '^[A-Za-z0-9._-]+$') {
     Write-Error '中断: この項の手順 2 の値は、ASCII の英数字と . : _ - だけにする（空白・ワイルドカードは使わない）'
   } elseif ((Test-Path -LiteralPath $f) -and ((([IO.File]::ReadAllBytes($f) | Select-Object -First 2) -join ',') -match '^(239,187|255,254|254,255)$')) {
     Write-Error "中断: $f の先頭に BOM がある（Git の ssh と、ssh を使う git が読めない）。BOM の無い UTF-8 で保存し直してから貼り直す"
   } elseif ((Test-Path -LiteralPath $f) -and (Select-String -LiteralPath $f -Pattern "^\s*Host(\s*=\s*|\s+)(.*\s)?$([regex]::Escape($SSH_ALIAS))(\s|$)" -Quiet)) {
     Write-Error "中断: Host $SSH_ALIAS は $f にもうある"
   } else {
     # 接続先を設定ファイルに登録する
     New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.ssh" | Out-Null
     $lines = @("# BEGIN windows-ssh-client.md $SSH_ALIAS", "Host $SSH_ALIAS", "  HostName $SSH_HOST", "  User $SSH_USER", '  IdentityFile ~/.ssh/id_ed25519', '  IdentitiesOnly yes', "# END windows-ssh-client.md $SSH_ALIAS")
     if ((Test-Path -LiteralPath $f) -and (Get-Item -LiteralPath $f).Length -gt 0 -and -not (Get-Content -LiteralPath $f -Raw).EndsWith("`n")) { $lines = @('') + $lines }
     Add-Content -LiteralPath $f -Value $lines -Encoding ascii
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     & "$env:WINDIR\System32\OpenSSH\ssh.exe" -G $SSH_ALIAS | Select-String -Pattern '^(hostname|user|identityfile|identitiesonly) '
     & 'C:\Program Files\Git\usr\bin\ssh.exe' -G $SSH_ALIAS | Select-String -Pattern '^(hostname|user|identityfile|identitiesonly) '
   }
   ```

   - `user <SSH_USER>`・`hostname <SSH_HOST>`・`identitiesonly yes`・`identityfile ~/.ssh/id_ed25519` の 4 行が出ればよい
   - Windows の ssh と Git の ssh で 1 回ずつ出る。順は ssh による
   - `user` などがこの項の手順 2 の値と違えば、config の前の方の `Host *` などが先に効いている。その行を直す
   - `Bad configuration option` が出たら、前からある config に、片方の ssh が知らない設定がある（[Windows の OpenSSH クライアント の補足と注意点](#windows-の-openssh-クライアント-の補足と注意点)の「注意点」）
   - `Bad owner or permissions on …config` が出たら、config にほかの主体の書き込みの許可がある（[Windows の OpenSSH クライアント の補足と注意点](#windows-の-openssh-クライアント-の補足と注意点)の「注意点」）
   - `中断: … BOM がある` ときは、メモ帳で config を開き、「名前を付けて保存」の文字コードを「UTF-8」（BOM なし）にして保存し直す

1. AlmaLinux 10 のホストで、ホスト鍵の指紋を表示する。

   ```bash
   ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
   ```

   - ホストの画面の端末か、すでにホストに入れている別の端末に貼る（`sudo` は要らない）
   - `SHA256:` の指紋と `(ED25519)` が出ればよい。この指紋を、この項の手順 9 の初回の接続で照合する
   - 同じ LAN から `ssh-keyscan` で取った指紋は、照合に使えない
   - **次の手順は、指紋を控えてから、この項の手順 2 の変数を設定した PowerShell に貼る**（次のブロックは PowerShell の構文なので、ホストの bash には貼らない）

1. 公開鍵を登録し、Windows と Git の ssh による鍵認証を確認する。

   ```powershell
   # SSH の接続先と公開鍵を確認する
   $pub = "$env:USERPROFILE\.ssh\id_ed25519.pub"
   if (-not $SSH_ALIAS) {
     Write-Error '中断: この項の手順 2 の SSH_ALIAS が空のまま。値を入れて貼り直す'
   } elseif (-not (Test-Path -LiteralPath $pub) -or [string](Get-Content -LiteralPath $pub -TotalCount 1) -notmatch '^ssh-ed25519 AAAA[0-9A-Za-z+/=]+( |$)') {
     Write-Error "中断: $pub が無いか、ed25519 の公開鍵の形でない"
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     # ホストに公開鍵を登録する
     Get-Content -LiteralPath $pub -TotalCount 1 | & "$env:WINDIR\System32\OpenSSH\ssh.exe" -o PubkeyAuthentication=no $SSH_ALIAS 'umask 077; mkdir -p ~/.ssh && if [ -s ~/.ssh/authorized_keys ] && [ $(tail -c1 ~/.ssh/authorized_keys | wc -l) -eq 0 ]; then echo >> ~/.ssh/authorized_keys; fi && tr -d ''\r'' | sed ''1s/^\xEF\xBB\xBF//'' >> ~/.ssh/authorized_keys && echo added; if type restorecon >/dev/null 2>&1; then restorecon -F ~/.ssh ~/.ssh/authorized_keys; fi'
   }
   # 公開鍵での接続を確認する
   if (-not $SSH_ALIAS) {
     Write-Error '中断: この項の手順 2 の SSH_ALIAS が空のまま。値を入れて貼り直す'
   } else {
     & "$env:WINDIR\System32\OpenSSH\ssh.exe" -o PreferredAuthentications=publickey $SSH_ALIAS 'whoami; ls -lZ ~/.ssh/authorized_keys'
     & 'C:\Program Files\Git\usr\bin\ssh.exe' -o PreferredAuthentications=publickey $SSH_ALIAS whoami
   }
   ```

   - 初回は、ED25519 の `SHA256:` の指紋を示して接続の確認を聞かれる
   - その指紋がこの項の手順 8 の指紋と同じなら `yes`、違えば `no` で止める
   - `<SSH_USER>@<SSH_HOST>'s password:` で、ホストのユーザーのパスワードを入れる
   - `added` と出ればよい
   - パスワードを聞かれずに `Permission denied` で終わるときは、ホストがパスワードでのログインを受け付けていない（[Windows の OpenSSH クライアント の補足と注意点](#windows-の-openssh-クライアント-の補足と注意点)の「注意点」）
   - パスワードを聞かれずに、`<SSH_USER>` と、`authorized_keys` の行、もう一度 `<SSH_USER>` が出ればよい
   - `authorized_keys` の行は、group と other に書き込みが無く（`-rw-------` など）、`ssh_home_t` が付いていればよい
   - 鍵にパスフレーズを付けたなら、2 回聞かれる
   - Git の ssh でホスト鍵を聞かれたら、Git の ssh が別の known_hosts を見ている（この項の手順 3 の `HOME`）
   - `Permission denied (publickey…)` なら、鍵が登録されていないか、Windows の ssh が秘密鍵を使っていない。`UNPROTECTED PRIVATE KEY FILE!` が出ていれば、この項の手順 6 で直す

1. WezTerm を自分用の設定で使うときだけ、起動メニューから接続先を開けることを確かめる。

   - 前提の WezTerm の設定を入れていなければ、この手順は飛ばす
   - WezTerm で Ctrl+Shift+R（設定の読み直し）を押してから、Ctrl+Shift+M で起動メニューを開く
   - `ssh <SSH_ALIAS>` が並び、選ぶと新しいタブでホストのシェルに入ればよい（パスフレーズを付けたなら聞かれる）

#### Windows の OpenSSH クライアント: 更新

- 更新後や config の変更後に、Windows と Git の ssh の版と設定を確かめる
- 前提: [Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)を通してある
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く
- Windows の ssh は[Windows Update](https://support.microsoft.com/en-us/windows/install-windows-updates-3c5ae7fc-9fb6-9af1-1984-b5e0412c556a)、Git の ssh は[Git for Windows の更新](#git-for-windowsfirefoxwezterm-を上げる)の手順 2 で上がる。この項で別に上げるものは無い

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. 変数を設定する（`SSH_ALIAS` は必ず値を入れる）。

   ```powershell
   $SSH_ALIAS = ''                       # ← ssh で打つ短い名前（英数字と - _ だけ）。<SSH_ALIAS>
   ```

   ```powershell
   'SSH_ALIAS = {0}' -f $SSH_ALIAS
   ```

   - [Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 2 と同じ値を入れる
   - **新しい PowerShell を開いたら**、この項の手順 2 のブロックを貼り直してから先へ進む

1. 2 つの ssh の版と、両方が config を読めることを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not $SSH_ALIAS) {
     Write-Error '中断: この項の手順 2 の SSH_ALIAS が空のまま。値を入れて貼り直す'
   } else {
     # SSH の版を確認する
     & "$env:WINDIR\System32\OpenSSH\ssh.exe" -V
     & 'C:\Program Files\Git\usr\bin\ssh.exe' -V
     # SSH の接続先を確認する
     & "$env:WINDIR\System32\OpenSSH\ssh.exe" -G $SSH_ALIAS | Select-String -Pattern '^(hostname|user) '
     & 'C:\Program Files\Git\usr\bin\ssh.exe' -G $SSH_ALIAS | Select-String -Pattern '^(hostname|user) '
   }
   ```

   - 版が 2 行と、`user <SSH_USER>`・`hostname <SSH_HOST>` が 2 組出ればよい
   - `Bad configuration option` が出たら、片方の ssh が知らない設定が config にある（[Windows の OpenSSH クライアント の補足と注意点](#windows-の-openssh-クライアント-の補足と注意点)の「注意点」）

<details id="windows-の-openssh-クライアント-の補足と注意点">
  <summary>Windows の OpenSSH クライアント の補足と注意点</summary>

**注意点**

- パスフレーズを付けた同じ鍵を GitHub にも登録しているなら、git の fetch・push のたびにもパスフレーズを聞かれる
- パスフレーズを後から付ける・変えるのは、`& "$env:WINDIR\System32\OpenSSH\ssh-keygen.exe" -p -f "$env:USERPROFILE\.ssh\id_ed25519"`
- **2 つの ssh が、同じ `%USERPROFILE%\.ssh` を使う**: Windows の ssh（PowerShell・WezTerm の起動メニュー）と Git の ssh（Git Bash・git）は、鍵・config・known_hosts を共有する
  - WSL の AlmaLinux 10 の ssh は、WSL のホームの `~/.ssh` を使う（別のもの）。WSL から入るなら、WSL の中で鍵を作る
- **config を BOM 付きや UTF-16 で保存しない**: Windows PowerShell 5.1 の `-Encoding UTF8`・`>`・`>>`・`Out-File` は、BOM 付きの UTF-8 か UTF-16 で書く
  - Windows の ssh は UTF-8 の BOM を読み飛ばすが、Git の ssh は `Bad configuration option` で止まり、ssh を使う git（GitHub への push など）も失敗する。UTF-16 は両方が読めない
  - メモ帳で書くなら、文字コードを「UTF-8」（BOM なし）にする
- **config には、両方の ssh が知っている設定だけを書く**: Windows の ssh（9.5p2）が知らない新しい設定を書くと、Windows の ssh が止まる。書いた後は、[Windows の OpenSSH クライアント: 更新](#windows-の-openssh-クライアント-更新)の手順 3 で両方を確かめる
- **ssh の設定は、最初に見つけた値が効く**: config の前の方の `Host *` などにある `User`・`IdentityFile` は、[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 7 で足した値より先に効く
- **Git の `usr\bin` が `PATH` の先にある PC**: PowerShell と WezTerm の起動メニューの `ssh` が、Git のものになる。この手順書のブロックは、どちらもフルパスで呼ぶ
- **秘密鍵のアクセス権**: Windows の ssh は、ほかの主体（Everyone・Users など）に許可のある秘密鍵を、`UNPROTECTED PRIVATE KEY FILE!` と出して使わない（[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 5・6）
- **config のアクセス権**: Windows の ssh は、ほかの主体に書き込みの許可のある config を読まず、`Bad owner or permissions on …config` で止まる
  - ほかの PC から写した config や、同期した config で起こりうる
  - [Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 6 のブロックの 1 行目の `id_ed25519` を `config` に書き換えて貼り、[Windows の OpenSSH クライアント: 更新](#windows-の-openssh-クライアント-更新)の手順 3 で確かめ直す
- **ホストがパスワードでのログインを受け付けないとき**（`PasswordAuthentication no` にしたホストなど）: [Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 9 は使えない。[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 9 の公開鍵の 1 行（`id_ed25519.pub` の中身）を、ホストの画面などで `~/.ssh/authorized_keys` に足す
  - [SSH を公開鍵だけにする](almalinux-setup.md#ssh-を公開鍵だけにする)を通したホストが、これに当たる。足すのは、その項の手順 1（`SSH_PUBKEY` に公開鍵の 1 行を入れる）でよい
  - その節をまだ通していないホストでは、この手順書を先に通す（[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 9 でパスワードを使う）
- **FIPS モードのホスト**: ed25519 の鍵は使えない（RHEL 10 の文書）。この手順書では扱わない

**[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)のリード**

- 鍵・config・known_hosts は `%USERPROFILE%\.ssh` に置き、Windows と Git の両方の ssh で使う

**[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 2**

- 最後に値を読み戻して確かめる

**[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 2: 変数について**

- `SSH_USER` に `root` を使わないのは、AlmaLinux 10 の既定では、root はパスワードで SSH に入れないため
- 変数はその PowerShell の中だけで有効

**[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 3**

- Windows の版の例は `OpenSSH_for_Windows_9.5p2, LibreSSL 3.8.2`、Git の版の例は `OpenSSH_10.5p1`

**[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 3: 2 つの ssh と、共有する .ssh**

- Windows 11 には、2 つの OpenSSH クライアントがある
  - Windows の OpenSSH クライアント（`C:\Windows\System32\OpenSSH\ssh.exe`。Windows のオプション機能で、Windows Update で上がる）。PowerShell で `ssh` と打ったときと、WezTerm の自分用の設定の起動メニュー（`ssh.exe` を名前で起動する）は、ふつうはこちら
  - Git for Windows に入っている ssh（`C:\Program Files\Git\usr\bin\ssh.exe`）。git が SSH でつなぐとき（`git@github.com:…` など）と、Git Bash で `ssh` と打ったときは、こちら。Git for Windows のインストーラの既定（`SSH Option=OpenSSH`、同梱の ssh を使う）のまま入れた PC の形
- どちらも `%USERPROFILE%\.ssh` を `~/.ssh` として使うので、鍵・config・known_hosts は 1 組になる
  - Windows の ssh は、ホームをユーザーのプロファイルのパスから取る（`HOME` を見ない）
  - git は、`HOME` が無ければ `%HOMEDRIVE%%HOMEPATH%`（または `%USERPROFILE%`）を `HOME` にして、Git の ssh を動かす
- そのため、`HOME` を別の場所にしていると、Git の ssh だけが別の `.ssh` を使う。git が使う ssh は、`GIT_SSH_COMMAND` → `core.sshCommand` → `GIT_SSH` → `PATH` の `ssh` の順に決まるので、[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 3 でこの 3 つも空なことを確かめる
- ブロックの中では、どちらの ssh もフルパスで呼ぶ。ユーザーの `PATH` の先頭側に Git の `usr\bin` があると、`ssh`・`ssh-keygen` が Git のものになる
- [Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 3 の `Get-Command` の一覧の先頭が `C:\Windows\System32\OpenSSH\…` でなく Git の `usr\bin` なら、PowerShell と WezTerm の起動メニューの `ssh` は Git のものになる（この折りたたみの「注意点」）
- [Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 3 の最後の行が `GIT_SSH= GIT_SSH_COMMAND= HOME=` なら、git は Git の ssh を使い、Windows の ssh と同じ `%USERPROFILE%\.ssh` を読む

**[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 3: 鍵と config の有無**

- `Test-Path` の 3 行は、秘密鍵・公開鍵・config が既にあるか
- 秘密鍵と公開鍵がどちらも `True` なら、その鍵を使う（[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 4 は何もしない）
- 秘密鍵だけが `True` なら、[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 4 で秘密鍵から公開鍵を作り直す

**[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 4: 鍵の種類とパスフレーズ**

- ED25519 は、Windows の ssh・Git の ssh・AlmaLinux 10 の sshd のどれも扱え、鍵が短い。Microsoft の文書も、種類を指定しないときの既定を Ed25519 としている
- パスフレーズは `ssh-keygen` に聞かせるため、`-N ''`（空のパスフレーズ）は書かない。Windows PowerShell 5.1 はネイティブのコマンドに空の文字列の引数を渡さず、`-N` の値が抜ける。PowerShell 7.3 以降は空の文字列も渡す
- パスフレーズは、秘密鍵のファイルが漏れたときの守り。ssh-agent を使わないので、付けると鍵を使うたびに聞かれる（この折りたたみの「選択した方針」）。後から付けるなら、この折りたたみの「注意点」の `ssh-keygen -p`
- 既に `id_ed25519` があれば作らない。GitHub に登録した鍵をそのまま使える。ホストごとに鍵を分ける形にはしなかった（鍵の管理が増えるため）
- 秘密鍵だけがあるとき（秘密鍵だけをほかの PC から写したときなど）は、`ssh-keygen -y` で秘密鍵から公開鍵を作り直す。`ssh-keygen -t` を流すと、上書きを聞かれる
  - 出力が `ssh-ed25519 AAAA` で始まるときだけ、`Set-Content -Encoding ascii` で `id_ed25519.pub` に書く。`>` は、Windows PowerShell 5.1 では UTF-16 で書くので使わない
  - Win32-OpenSSH の `ssh-keygen -y` は、秘密鍵を読む前にアクセス権を確かめる（`authfile.c` の `sshkey_load_private_type` が `sshkey_perm_ok` を呼ぶ）
  - 写した鍵は `Everyone` などが付いていることがあるので、そのときは[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 5・6 で直してから作り直す

**[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 5: 秘密鍵のアクセス権**

- Windows の ssh は、秘密鍵の所有者が本人・Administrators・SYSTEM（か TrustedInstaller）で、ほかの主体に許可が無いことを確かめる。合わなければ `WARNING: UNPROTECTED PRIVATE KEY FILE!` と出して、その鍵を使わない（Win32-OpenSSH のソース）
- `%USERPROFILE%` の下に作ったファイルは、プロファイルから SYSTEM・Administrators・本人の許可を受け継ぐので、そのままで合う
- Windows の `ssh-keygen` で作った秘密鍵は、受け継がない 3 つの許可になるはず（Windows では確かめていない）
  - Win32-OpenSSH v9.5.0.0 のソースでは、`authfile.c` の `sshkey_save_private_blob` が秘密鍵を `0600` で開く
  - `contrib/win32/win32compat/fileio.c` の `createFile_flags_setup` が、そのモードを `O:<本人>D:PAI(A;;FA;;;BA)(A;;FA;;;SY)(A;;<読み書き>;;;<本人>)` の SDDL にする
  - `D:PAI` は受け継ぎを切った DACL。Administrators と SYSTEM はフル コントロール、本人は読み書き（フル コントロールではない）
- ほかの PC から写した鍵や、共有のフォルダーを通した鍵は、`Everyone` などの許可が付くことがある。そのときだけ[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 6 で直す
- Git の ssh は、このアクセス権の確かめをしない。秘密鍵のアクセス権が悪いと、Windows の ssh だけが鍵を使わない

**[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 6: アクセス権の直し方**

- `icacls <鍵> /reset` で明示の許可をすべて外して受け継ぐ形に戻し、`/inheritance:r` で受け継いだ許可も外してから、`/grant:r` で本人・SYSTEM（`S-1-5-18`）・Administrators（`S-1-5-32-544`）だけにフル コントロールを付ける
- `/inheritance:r` と `/grant:r` だけでは、`Everyone` などの明示の許可が残る（`/grant:r` は、名指しした主体の許可だけを置き換える）。そのため先に `/reset` を行う
- 主体は SID で渡す（表示の言語に左右されないため）。本人の SID は `[Security.Principal.WindowsIdentity]::GetCurrent().User.Value`。`"*${sid}:F"` と波かっこで書くのは、`$sid:F` がスコープ付きの変数として読まれないため

**[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 7: config の書き方と文字コード**

- 足すのは `Host`・`HostName`・`User`・`IdentityFile`・`IdentitiesOnly` の 5 行と、前後の印の 2 行。印（`#` で始まる行）は ssh が読み飛ばす
- `IdentitiesOnly yes` で、この接続先には `IdentityFile` の鍵だけを使う（ほかの鍵を順に試さない）。`IdentityFile` は `~/.ssh/…` と `/` で書く。どちらの ssh も `~` を展開する
- 書く文字コードは `-Encoding ascii`（BOM の無い ASCII。値は ASCII の英数字と記号だけに限っている）。PowerShell 7 の `-Encoding UTF8` は BOM を付けない。Windows PowerShell 5.1 の `-Encoding UTF8` は BOM を付け、`>`・`>>`・`Out-File` は UTF-16 で書く
  - Windows の ssh は UTF-8 の BOM を読み飛ばすが（Win32-OpenSSH のソース）、Git の ssh は読み飛ばさず、`Bad configuration option` で止まる。そのため、BOM のある config には足さずに止める
  - 改行は CR LF になる。ssh は行の末尾の CR を空白として捨てる
- 同じ `Host` がもうあるかは、`Host <別名>` と `Host=<別名>` の両方の書き方で探す（ssh_config は `=` でも区切れる）。2 つ目の `Host` のブロックを足しても、ssh は最初のものを使い、足した値は効かない
- `Add-Content` は、末尾に改行の無いファイルに、改行を入れずに続けて書く。実測は検証記録（`docs/verification/windows-setup.md`）。そのため、末尾に改行が無ければ、先に空の 1 行（改行）を書く
- 確かめは、2 つの ssh の `-G`（config を読んだ結果の表示）で行う。Git の ssh のほうが BOM に厳しく、Windows の ssh（9.5p2）は新しい設定を知らないので、両方を必ず確かめる
- ssh は最初に見つけた値を使うので、config の前の方の `Host *` などにある値が、足した値より先に効く

**[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 8**

- 指紋の表示の例は `256 SHA256:<指紋> no comment (ED25519)`

**[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 8: ホスト鍵の指紋**

- 最初の接続で出る指紋を、別の経路（ホストの画面か、すでに信頼している接続）で見た指紋と照合する。照合した後は known_hosts に入り、以後は聞かれない
- AlmaLinux 10 の sshd は、最初の起動のときに ED25519・ECDSA・RSA のホスト鍵を作る。公開鍵は 0644 なので、`sudo` 無しで読める。コメントは空なので `no comment` と出る（AlmaLinux 10.2 の `sshd-keygen`）
- 初回の接続の表示は、ssh の版で少し違う（Git の 10.5p1 は `ED25519 key fingerprint is: SHA256:…`、AlmaLinux 10.2 の 9.9p1 は `ED25519 key fingerprint is SHA256:….`）。照合するのは `SHA256:` の後ろ
- 同じ LAN から `ssh-keyscan` で取った指紋を照合に使えないのは、途中で別の相手に入れ替わっていても分からないため

**[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 9**

- 初回の問いの文は `Are you sure you want to continue connecting (yes/no/[fingerprint])?`

**[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 9: 公開鍵の足し方**

- `ssh-copy-id` は使わない。Git for Windows の Git Bash には入っているはずだが（MinGit 以外）、PowerShell のブロックにそろえるため、同じことをするコマンドを 1 回の ssh で送る
  - `umask 077` で、新しく作る `~/.ssh` を 0700、`authorized_keys` を 0600 にする。sshd の `StrictModes` は、group・other に書き込みのあるものを断る（前からある `authorized_keys` のモードは変えない）
  - `authorized_keys` の末尾に改行が無ければ、先に改行を足す（`ssh-copy-id` と同じ）
  - Windows の PowerShell 7 も、文字列のパイプには CR LF を付けるので、`tr -d '\r'` で CR を捨てる。Windows PowerShell 5.1 のパイプも CR LF になる
  - 1 行目の先頭の UTF-8 の BOM は、`sed` で捨てる。プロファイルで `$OutputEncoding` を UTF-8 にした 5.1 は、BOM を付けて送るかもしれない（Windows では確かめていない）
    - BOM の付いた行は、`ssh-keygen -lf` が公開鍵と認めなかった。模擬の結果は検証記録（`docs/verification/windows-ssh-client.md` の「模擬」）にある。sshd もその行の鍵を使わないはず（sshd では確かめていない）
  - `restorecon` は、あるときだけ動かし、無くても `added` の判定に入れない（`ssh-copy-id` と同じ）。ラベルは `ssh_home_t` になる
- ホストに渡すコマンドは、単一引用符を使う今の形のまま PowerShell 7 に貼る。Windows PowerShell 5.1 はネイティブのコマンドの引数の中の二重引用符を逃がさないため、二重引用符を使わない形にしてある。PowerShell の単一引用符の文字列の中では、単一引用符を `''` と重ねて書く
- `-o PubkeyAuthentication=no` は、鍵を試さず（パスフレーズも聞かず）にパスワードへ進むため
- Windows の ssh は、ホスト鍵の問いへの答えとパスワードを、標準入力ではなくコンソールから読む（Win32-OpenSSH のソース）。そのため、標準入力で渡す公開鍵は、問いに食われない（Windows では確かめていない）
- AlmaLinux 10 の既定では、一般のユーザーはパスワードで SSH に入れ、root はパスワードでは入れない（`PermitRootLogin prohibit-password`）。ホストを固くして `PasswordAuthentication no` にしているときは、この手順は使えない（この折りたたみの「注意点」）
- 貼り直すと、同じ行がもう 1 行足される（害は無い）

**[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 9: 鍵でのログインの確かめ方**

- `-o PreferredAuthentications=publickey` は、鍵が通らなかったときにパスワードへ移らず、そこで失敗させるため
- 2 つの ssh で確かめるのは、Git の ssh が同じ鍵・config・known_hosts を使っていること（ホスト鍵を聞かれないこと）も見るため
- 鍵にパスフレーズを付けたなら 2 回聞かれるのは、`ssh` が 2 つあるため

**[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 10: WezTerm の起動メニュー**

- 自分用の設定（ryo-aoki-pc/wezterm）は、`~/.ssh/config` の `Host`（ワイルドカードを含むものと、github.com などの git のホストは除く）を、起動メニューに `ssh <Host>` として並べる。起動するのは `ssh.exe` で、パスは決めていない
- WezTerm の設定の読み直し（Ctrl+Shift+R）で、config に足した `Host` が並ぶ
- config の読み取りに失敗しても、設定の全体は落ちず、ssh の項目だけが出ない。WezTerm が BOM 付きの config を読めるかは確かめていない
- 起動メニューの ssh は、`PATH` で最初に見つかる `ssh.exe` で動く。新しい PowerShell で `(Get-Command ssh.exe).Source` が `C:\Windows\System32\OpenSSH\ssh.exe` なら、Windows のもの

**[Windows の OpenSSH クライアント: 更新](#windows-の-openssh-クライアント-更新)の手順 2**

- 最後に値を読み戻して確かめる

**選択した方針**

- **Windows だけを対象にする**（利用者の選択）。AlmaLinux 10 の SSH クライアントの手順は、この手順書には入れない
- **ssh-agent は使わない**（利用者の選択）
  - Windows の ssh-agent のサービスは既定で無効で、有効にするには管理者の権限が要る（Microsoft の文書）
  - 鍵にパスフレーズを付けたら、使うたびに聞かれる。付けなければ聞かれないが、秘密鍵のファイルを持つ人は誰でも入れる（Microsoft は空のパスフレーズを勧めていない）
- **Windows の ssh と Git の ssh をそろえる設定（`core.sshCommand` を Windows の ssh にする）はしない**
  - 初期設定の「Git」の、両 OS に同じ bash のブロックを貼る形を崩すことになり、ssh-agent を使わない限り得るものが無い
  - 代わりに、config は両方の ssh が読める書き方に限り、[Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 7 と更新で両方の `-G` を確かめる
- **winget や scoop の OpenSSH（新しい版の Win32-OpenSSH）は入れない**: 3 つ目の `ssh.exe` が `PATH` に加わり、`PATH` の順によっては PowerShell と WezTerm が使う ssh が変わる（どれが動くかが分かりにくくなる）。得るのは新しい版だけ
- **鍵交換の方式は、確かめてから書く**: Windows の 9.5p2 も `sntrup761x25519-sha512@openssh.com`（耐量子のハイブリッド）を扱う。AlmaLinux 10 の既定の暗号ポリシーとの組み合わせで実際に選ばれる方式は、`ssh -v` の `kex: algorithm:` の行で測る。未確認事項は検証記録（`docs/verification/windows-ssh-client.md` の「残っている未確認事項」）
- **WSL の AlmaLinux 10 の ssh は、別のものとして扱う**: WSL のホームの `~/.ssh` は別にあり、Windows の `%USERPROFILE%\.ssh` を共有しない。WSL から入るなら、WSL の中で鍵を作る

**参照**

- [Get started with OpenSSH for Windows (Microsoft Learn)](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse)（クライアントの機能、オプション機能の画面）
- [OpenSSH key management for Windows (Microsoft Learn)](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement)（Ed25519 の既定、ssh-agent のサービス、空のパスフレーズ）
- [about_Parsing (Microsoft Learn)](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parsing)（ネイティブのコマンドへの空の文字列の引数。7.3 からの変更）
- [about_Character_Encoding (PowerShell 5.1, Microsoft Learn)](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_character_encoding?view=powershell-5.1)
- [PowerShell/openssh-portable の v9.5.0.0](https://github.com/PowerShell/openssh-portable/tree/v9.5.0.0)（`contrib/win32/win32compat/misc.c` の `w32_fopen_utf8`、`w32-sshfileperm.c`、`readconf.c`、`authfile.c`）
- [Using secure communications between two systems with OpenSSH — Securing networks (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/securing_networks/using-secure-communications-between-two-systems-with-openssh)（`PermitRootLogin` の既定の `prohibit-password`、FIPS モードと Ed25519）
- `man ssh_config`（`Host`、`IdentitiesOnly`、`-G`）/ `man ssh-keygen`（`-l`、`-R`、`-p`）/ `contrib/ssh-copy-id`（OpenSSH）
- [ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm)（`lua/shells.lua` の `ssh_entries()` と README の「SSH ホスト」）

- 検証記録（`docs/verification/windows-ssh-client.md`）

</details>

---

## Git と開発の道具

- git-delta・GitHub CLI・lazygit・yazi。Neovim（LazyVim）は、[Neovim のセットアップの「Windows 11 で使う」](neovim.md#windows-11-で使う)で入れる
- excel-diff・mdtable・md-format（mdfmt）・md-preview（mdpreview）・md-table-sticky は、それぞれのリポジトリの手順（[excel-diff](https://github.com/ryo-aoki-pc/excel-diff/blob/main/docs/install.md#windows-11-で-excel-diff-を導入更新する)・[mdtable](https://github.com/ryo-aoki-pc/md-tools/blob/main/mdtable/docs/install.md#windows-11-で-mdtable-を導入更新する)・[md-format](https://github.com/ryo-aoki-pc/md-format/blob/main/docs/install.md#windows-11-で-md-format-を導入更新する)・[md-preview](https://github.com/ryo-aoki-pc/md-tools/blob/main/docs/install.md#windows-11-で-md-preview-を導入更新する)・[md-table-sticky](https://github.com/ryo-aoki-pc/md-tools/blob/main/sticky/docs/install.md#md-table-sticky-のブックマークレットを登録する)）で入れる。使い方は、各リポジトリの `docs/usage.md` にある

### git-delta

- scoop で delta を入れ、Git の差分表示を設定する
- 前提: [scoop の導入](https://scoop.sh/)と[Git Bash と WezTerm の設定](shell-terminal.md#git-bash-と-wezterm-の設定)を通してある。Visual C++ ランタイムも[WezTerm](shell-terminal.md#windows-11-で-wezterm-を入れる)で入れてある
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く。この項の手順 4・5 は WezTerm の新しい Git Bash のタブ

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. 管理者ではないことと、scoop・git・VC++ ランタイム・ほかの delta を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     PowerShell = $PSVersionTable.PSVersion.ToString()
     Admin      = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Scoop      = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git        = (Get-Command git -ErrorAction SilentlyContinue).Source
     VCRuntime  = Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
     Delta      = (Get-Command delta -All -ErrorAction SilentlyContinue).Source -join ', '
   } | Format-List
   ```

   - `PowerShell : 7.…` と `Admin : False` が出ればよい。`Admin : True` なら、窓を閉じて、この項の手順 1 のとおりに開き直す
   - `Scoop` に `C:\Users\<WIN_USER>\scoop\shims\scoop.ps1` が出ればよい。空なら、先に[scoop の公式の導入案内](https://scoop.sh/)に従って入れる
   - `Git` が `C:\Program Files\Git\cmd\git.exe` でなければ、先に [Git for Windows](https://gitforwindows.org/)
   - `VCRuntime : True` ならよい。`False` なら、先に [WezTerm](shell-terminal.md#windows-11-で-wezterm-を入れる)の手順 3 を管理者の PowerShell 7 で行い、この窓でこのブロックを貼り直す
   - ほかの場所（winget の `…\WinGet\Links\delta.exe` など）が出たら、ほかの方法で入れた delta がある。中断し、既存の導入元と設定を確かめる

1. scoop で delta を入れ、版と場所を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop install delta
   delta --version
   (Get-Command delta -All).Source
   ```

   - `delta` が `was installed successfully!` になればよい
   - 導入済みなら `is already installed.` と更新の案内が出て、何も変えない
   - `delta` と入れた版が出ればよい。版が出なければ、この項の手順 2 の `VCRuntime` を確かめる
   - 最後のコマンドは、`C:\Users\<WIN_USER>\scoop\shims\delta.exe` の 1 行だけを出せばよい

1. WezTerm の新しいタブ（Git Bash）で、[AlmaLinux 10 の初期設定の「git-delta」](almalinux-setup.md#git-delta)の手順 1・3 を貼る。

   - WezTerm を起動するか、新しいタブ（既定のキーは Ctrl+Shift+T）を開く（自分用の WezTerm の設定では Git Bash が開く）
   - 同書の「git-delta」の手順 1 の 3 つの変数は、AlmaLinux 10 と同じ既定のままでよい。同じ項の手順 3 も同じタブに貼る
   - 同書の「git-delta」の手順 3 は、AlmaLinux 10 と同じく、設定した 6 項目が出ればよい（`interactive.difffilter` は小文字）
   - 同書の「git-delta」の手順 2・4 は行わない

1. 同じ Git Bash のタブで `git diff` を打ち、delta の表示になることを確かめる。

   - 変更のあるリポジトリに `cd` してから打つ。変更のあるリポジトリが無ければ、代わりに `git -C ~/.config/bash show` を打つ
   - ファイル名のヘッダと、行番号・行ごとに背景色の付いた差分が出ればよい（同書の「git-delta」の手順 4 と同じ見え方）
   - 1 画面に収まらないときは、less で止まる。`q` で閉じる
   - 素の差分（背景色の無い `+` / `-` の行）が出たら、この項の手順 4 で貼った同書の「git-delta」の手順 3 の読み戻しに `core.pager delta` があるかを確かめる
   - `git diff | head` のようにパイプに繋ぐと、AlmaLinux 10 と同じく delta を通らない
   - **ほかのブロックは、less を `q` で閉じてから貼る**（less を開いたまま貼ると、less への入力になる）

<details id="git-delta-の補足と注意点">
  <summary>git-delta の補足と注意点</summary>

**注意点**

- **git-delta: Windows 11 の PowerShell と cmd で打つ git も、delta を通る**: `~/.gitconfig` は Git Bash と同じファイル
  - PowerShell の `git`（`C:\Program Files\Git\cmd\git.exe`）は、Git の `usr\bin` を PATH の先頭に足してから git を動かすので、delta は Git Bash と同じ Git for Windows の less をページャに使う（ソースを読んだだけ。この折りたたみの「git-delta の手順 5: ページャの less と PowerShell の git」）
  - そのため、scoop の less は入れていない。PowerShell で delta を直に動かす（`git diff | delta` など）ときは、PATH に less が無いので、ページャを使わずに出る

**[git-delta](#git-delta)の手順 2: VC++ ランタイム**

- scoop の delta は、上流の `x86_64-pc-windows-msvc` のビルドで、`delta.exe` のインポート表に `VCRUNTIME140.dll` がある（検証記録の付録（`docs/verification/windows-setup.md` の「git-delta: 付録: Windows 11 の配布物と資料の調査（2026-10-08）」））。無い PC では起動しない
- scoop の `delta.json` は VC++ ランタイムを入れない（`depends` も `suggest` も無い）。winget の `dandavison.delta` は、依存として `Microsoft.VCRedist.2015+.x64` を持つ
- 入れ方は新しく書かず、[Windows 11 で WezTerm を入れる](shell-terminal.md#windows-11-で-wezterm-を入れる)の手順 3（管理者の窓の winget。PC 全体）を指す。手順書の並びでは WezTerm を先に入れるので、ふつうはもう入っている
  - 設定の「インストールされているアプリ」では「Microsoft Visual C++ v14 Redistributable (x64)」と出る（前の版で入れた PC では「… 2015-2022 …」）
  - extras のバケットの `vcredist2022`（scoop）でも入るが、extras を足すことになり、入れるときに UAC の確認も出るので採らない
- 同じ前提は bat・Neovim・yazi にもある。eza（windows-gnu のビルド）と starship・zoxide・fd（CRT を静的にリンク）、gh（Go）には無い

**[git-delta](#git-delta)の手順 2: 確かめる値の意味**

- `Delta` が空なら、delta は入っていない。`C:\Users\<WIN_USER>\scoop\shims\delta.exe` だけなら、もう scoop で入っている（[git-delta](#git-delta)の手順 3 の `scoop install` は何も変えない）
- ほかの方法で入れた delta を外すのは、混ざらないようにするため

**[git-delta](#git-delta)の手順 3**

- 導入時の行は `'delta' (0.20.1) was installed successfully!` の形

- 版の表示は `delta 0.20.1` の形

**[git-delta](#git-delta)の手順 3: scoop の名前と版**

- scoop の名前は `delta`（Homebrew の formula の `git-delta` ではない）
- `'delta' (<版>) was installed successfully!` の版は、実行した日の最新

**[git-delta](#git-delta)の手順 4: 実施手順の手順 1・3 を Git Bash で貼る**

- [git-delta](almalinux-setup.md#git-delta)の手順 1・3 のブロックは bash と git だけを使うので、Git Bash にそのまま貼れる。PowerShell 向けに書き分けない（[Git](almalinux-setup.md#git) と同じ考え方）
- `git config --global` が書くのは `C:\Users\<WIN_USER>\.gitconfig`（Git Bash の `HOME`）。Git Bash・PowerShell 7・cmd の `git config --global --list --show-origin` が同じファイルを示すことは、Git の検証記録（`docs/verification/windows-setup.md` の「Git: 付録: Windows 11 の Git Bash での検証記録（2026-09-30）」）で確かめてある
- [git-delta](almalinux-setup.md#git-delta)の手順 2（`brew install`）と[git-delta](almalinux-setup.md#git-delta)の手順 4（`brew list` を含む）は指さない。入れることと版・場所は、[git-delta](#git-delta)の手順 3 で PowerShell から確かめる
- [git-delta](almalinux-setup.md#git-delta)の手順 3 は `merge.conflictstyle zdiff3` も書く。[Git](almalinux-setup.md#git) の手順 5 と同じ値なので、どちらを先に通してもよい（AlmaLinux 10 と同じ）
- [git-delta](almalinux-setup.md#git-delta)の手順 1 の変数はそのタブの中だけで有効なので、[git-delta](almalinux-setup.md#git-delta)の手順 3 も同じタブに貼る

**[git-delta](#git-delta)の手順 5: 変更のあるリポジトリが無いとき**

- `git -C ~/.config/bash show` が出すのは、[共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)の clone の、最後のコミットの差分

**[git-delta](#git-delta)の手順 5: ページャの less と PowerShell の git**

- git は `core.pager` の `delta` を PATH から探して起動する（scoop の shim の `~\scoop\shims\delta.exe`）
- delta 0.20.1 のページャは、`delta.pager`（`--pager`）・`DELTA_PAGER`・`BAT_PAGER`・`PAGER` の順に決まり、どれも無ければ `less`。そのコマンドを PATH から探し、見つからなければ、ページャを使わずに標準出力へ書く（ソースの `src/utils/bat/output.rs` と `src/env.rs`）
- **Git Bash** では、PATH の先頭が Git の `/usr/bin` なので、delta は Git for Windows の `usr\bin\less.exe` を使う
- **PowerShell・cmd** の PATH には Git の `cmd` しか無い（Git for Windows の既定の `Path Option=Cmd`）。それでも、そこの `git.exe`（Git for Windows の git-wrapper）は、`ucrt64\bin`・`usr\bin`・`%HOME%\bin` を PATH の先頭に足してから本体の `ucrt64\bin\git.exe` を動かす（2.55 までは `mingw64\bin`。git-wrapper のソースの `setup_environment`。`cmd\git.exe` は `git.res` の版の情報だけを持ち、PATH を絞る `MINIMAL_PATH=1` の文字列のリソースが無い）。その PATH を受け継ぐ delta も、Git for Windows の less を使う
- 上流の文書は、Windows では新しい less が要り、古い `less.exe` を使うと色が崩れたり変な文字が出たりすると書いている。Git for Windows の less は MSYS2 の今の版なので、これに当たらないはず（版は確かめていない）
- **scoop の less は入れなかった**: 設計の段階では、PowerShell から git を使うときだけ scoop の less（main の `less.json`。上流の文書が勧める `jftuga/less-Windows` の配布物）を入れる任意の手順を考えた。上のとおり、git が起動する delta には、Git Bash でも PowerShell でも Git の `usr\bin` が scoop の shims より前に来るので、入れても使われない（`DELTA_PAGER` か `delta.pager` で場所を指したときと、PowerShell で delta を直に動かしたときだけ使われる）
- PowerShell で delta を直に動かす（`git diff | delta` など）と、PATH に less が無いので、delta はページャを使わずに出す（上の `output.rs` の動き）
- `delta.navigate`（[git-delta](almalinux-setup.md#git-delta)の手順 1 の `DELTA_NAVIGATE`）が `true` だと、delta は less の検索履歴の写しを `%LOCALAPPDATA%\delta\delta.lesshst` に作り、`LESSHISTFILE` で less に渡す（ソースの `src/features/navigate.rs`。Linux では `~/.local/share/delta/lesshst`）。Windows で `n` / `N` が効くかは確かめていない
- PowerShell・cmd で打つ `git diff` も、同じ `~/.gitconfig` を読んで delta を通る（[git-delta の補足と注意点](almalinux-setup.md#git-delta-の補足と注意点)の「注意点」）
- どれも、ソースを読んだだけで、Windows では確かめていない（検証記録（`docs/verification/windows-setup.md` の「git-delta: Windows 11 で使う: 検証状況の記録」））

**選択した方針**

[git-delta](#git-delta)の理由。**Windows の実機では未検証**（検証記録（`docs/verification/windows-setup.md` の「git-delta: Windows 11 で使う: 検証状況の記録」））。

- **scoop の main のバケットで入れた**（winget は採らない）
  - [README の導入の基盤](../README.md#導入の基盤)の「CLI ツールは scoop」と同じ。管理者が要らず、[更新](#更新)の `scoop update *` と UniGet UI で上がる
  - winget の `dandavison.delta` 0.20.1 も、同じ上流の zip（portable）を同じ sha256 で入れる。違うのは入れ方と上げ方と、VC++ ランタイムを依存として入れるかだけ
  - 上流の zip を手で置く形や `cargo install git-delta`（Rust が要る）は、更新が手作業になる
  - scoop の定義は x64 だけ。arm64 の Windows 11 では、scoop はこの x64 の版を入れる（Scoop のソースの `Get-SupportedArchitecture`。確かめていない）
  - 版は固定しない（`scoop hold` しない）。scoop で止めるのは、Git Bash で移動先を記録しない 0.10.0 を避ける zoxide だけ（[シェルのツールを入れる](shell-terminal.md#シェルのツールを入れる)）
- **設定は git の `~/.gitconfig` だけ**: delta は自分の設定ファイルを持たず、`[delta]` セクションを読む。`XDG_CONFIG_HOME` は関係しないので設定しない。Git Bash・PowerShell・cmd の git が同じファイルを読む（この折りたたみの「git-delta の手順 4: 実施手順の手順 1・3 を Git Bash で貼る」）
- **シェルとの組み込み方**
  - delta はどのシェルにも初期化の行が要らない。git が `core.pager` と `interactive.diffFilter` で呼ぶので、`~/.gitconfig` を書けば、どのシェルの git にも効く
  - **Git Bash が主**: WezTerm の自分用の設定の `default_prog` は Git Bash（`bash.exe -i -l`）。git の設定は Git Bash で[git-delta](almalinux-setup.md#git-delta)の手順 1・3 を貼って書く（AlmaLinux 10 と同じブロック）。共通の bash 設定（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)）は delta を扱わず、`PAGER` なども設定しない
  - **PowerShell 7 には補完を足す**。[PowerShell 7 のプロファイルに開発の設定を足す](shell-terminal.md#powershell-7-のプロファイルに開発の設定を足す)で、`delta --generate-completion powershell` の出力を控えたファイルから読む。delta を上げた後は、[PowerShell の開発の設定を更新する](shell-terminal.md#powershell-の開発の設定を更新する)で控えを作り直す
  - **Windows PowerShell 5.1 には delta の補完を足さない**。git が読む `~/.gitconfig` の設定は、5.1 から使う git にも効く
  - **WSL の AlmaLinux 10 は Linux のホストとして扱う**。WSL の git は WSL の中の `~/.gitconfig` を読むので、[git-delta](almalinux-setup.md#git-delta)を WSL の中で通す
- **VC++ ランタイムは前提にした**: この折りたたみの「git-delta の手順 2: VC++ ランタイム」
- **scoop の less は入れない**: この折りたたみの「git-delta の手順 5: ページャの less と PowerShell の git」
- **lazygit**: 自分用の lazygit の設定（[ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit)）は、`git.diffRenderers` で `delta --no-gitconfig …` を呼ぶ。`~/.gitconfig` の `[delta]` を読まないので、この文書の変数は lazygit の表示に効かない。Windows の lazygit は描画のコマンドを cmd.exe で動かすので、単一引用符を使わない（その README の「Windows で使う場合」）。この文書の任意節の yaml は引用符を使わない
- **Git Bash は WezTerm のタブで確かめる**: 自分用の設定で Git Bash が開く。スタートメニューの「Git Bash」（mintty）でも同じ `~/.gitconfig` を読むはずだが、確かめていない

**参照**

- 検証記録（`docs/verification/windows-setup.md`）

</details>

---

### GitHub CLI

- scoop で GitHub CLI を入れ、GitHub にログインする
- 前提: [scoop の導入](https://scoop.sh/)と[Git Bash と WezTerm の設定](shell-terminal.md#git-bash-と-wezterm-の設定)を通してある。GitHub のアカウントがある
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. 管理者ではないことと、scoop・git・Git の資格情報のヘルパー・ほかの gh を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     PowerShell = $PSVersionTable.PSVersion.ToString()
     Admin      = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Scoop      = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git        = (Get-Command git -ErrorAction SilentlyContinue).Source
     GitCred    = $(if (Get-Command git -ErrorAction SilentlyContinue) { (git config --get-regexp '^credential\..*helper$') -join ', ' })
     Gh         = (Get-Command gh -All -ErrorAction SilentlyContinue).Source -join ', '
   } | Format-List
   ```

   - `PowerShell : 7.…` と `Admin : False` が出ればよい。`Admin : True` なら、窓を閉じて、この項の手順 1 のとおりに開き直す
   - `Scoop` に `C:\Users\<WIN_USER>\scoop\shims\scoop.ps1` が出ればよい。空なら、先に[scoop の公式の導入案内](https://scoop.sh/)に従って入れる
   - `Git` が `C:\Program Files\Git\cmd\git.exe` でなければ、先に [Git for Windows](https://gitforwindows.org/)
   - `GitCred` が `credential.helper manager` ならよい
   - `GitCred` が空なら、この項の手順 4 の Git の認証には `Y` と答えてよい
   - ほかの場所（winget の MSI の `C:\Program Files\GitHub CLI\gh.exe` など）が出たら、ほかの方法で入れた gh がある。中断し、既存の導入元と設定を確かめる

1. scoop で gh を入れ、版と場所を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop install gh
   gh --version
   (Get-Command gh -All).Source
   ```

   - `gh` が `was installed successfully!` になればよい
   - 導入済みなら `is already installed.` と更新の案内が出て、何も変えない
   - `gh version <版> (<日付>)` の形で、入れた版が出ればよい
   - 最後のコマンドは、`C:\Users\<WIN_USER>\scoop\shims\gh.exe` の 1 行だけを出せばよい

1. GitHub へのログインを始める。

   ```powershell
   gh auth login
   ```

   - 問いには、矢印キーで選んで Enter で答える
     - `Where do you use GitHub?` は `GitHub.com`
     - `What is your preferred protocol for Git operations on this host?` は `HTTPS`
     - `Authenticate Git with your GitHub credentials?` は、**`n` と打って Enter**（既定は `Y`）
     - `How would you like to authenticate GitHub CLI?` は `Login with a web browser`
   - Git の認証の問いが出なければ、gh がもう Git の資格情報のヘルパーになっている（この項の手順 2 の `GitCred`）
   - `One-time code (<コード>) copied to clipboard` の行のワンタイムコードを、この項の手順 5 のブラウザで使う
   - クリップボードに入れられなかったときは、`First copy your one-time code:` の後にコードが出る
   - `Press Enter to open https://github.com/login/device in your browser...` で Enter を押すと、既定のブラウザが開く
   - **トークン（`gh auth token` の出力）や、認証中に表示されるワンタイムコードはこの文書に載せない**

1. ブラウザで、GitHub の認証を済ませる。

   - `https://github.com/login/device` にこの項の手順 4 のワンタイムコードを入れ、画面の案内に従う
   - ブラウザが開かなければ（`Failed opening a web browser at …`）、`https://github.com/login/device` を自分でブラウザで開く
   - PowerShell に `Logged in as <GITHUB_USER>` が出れば、`gh auth login` は終わっている
   - `Authentication credentials saved in plain text` なら、トークンは `%APPDATA%\GitHub CLI\hosts.yml` に平文で入った（[GitHub CLI の補足と注意点](#github-cli-の補足と注意点)の「注意点」）
   - **次の手順は、`gh auth login` が終わってから貼る**（ブラウザで認証を済ませ、PowerShell にログイン完了が出たことを確かめる）

1. ログインできたことと、Git の資格情報のヘルパーが変わっていないことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # GitHub CLI の認証を確認する
   gh auth status
   # Git の資格情報ヘルパーを確認する
   git config --get-regexp '^credential\..*helper$'
   ```

   - `Logged in to github.com account <GITHUB_USER> (keyring)` の行と、`Git operations protocol: https` の行が出ればよい
   - `(keyring)` の代わりに `(C:\Users\<WIN_USER>\AppData\Roaming\GitHub CLI\hosts.yml)` が出たら、トークンは平文のファイルにある
   - `You are not logged into any GitHub hosts.` なら、ログインしていない。この項の手順 4 からやり直す
   - 最後のコマンドが、この項の手順 2 の `GitCred` と同じ行（ふつうは `credential.helper manager`）を出せばよい
   - `GitCred` が空で、Git の認証に `Y` と答えたときは、代わりに `auth git-credential` で終わる行が出る

<details id="github-cli-の補足と注意点">
  <summary>GitHub CLI の補足と注意点</summary>

**注意点**

- **GitHub CLI: Windows 11 のトークンの置き場所**: 資格情報マネージャー（Windows 資格情報の汎用資格情報）を優先し、使えない場合は `%APPDATA%\GitHub CLI\hosts.yml` に平文で保存する

- **GitHub CLI: Windows 11 では、gh と git が別々に GitHub にログインする**: git の HTTPS は、Git for Windows の Git Credential Manager が自分のサインインで行う
  - [GitHub CLI](#github-cli)の手順 4 で、Git の認証に `n` と答えるため
  - `gh auth logout`・GitHub CLI の認可の取り消し・gh を消すことは、git の HTTPS の認証に影響しない

**[GitHub CLI](#github-cli)の手順 2: 確かめる値の意味**

- `GitCred` の `credential.helper manager` は、Git for Windows のインストーラの既定の Git Credential Manager
- `GitCred` に `auth git-credential` で終わる行があれば、前に gh を Git の資格情報のヘルパーにしてある（`gh auth setup-git` など）。[GitHub CLI](#github-cli)の手順 4 で Git の認証は聞かれない
- `GitCred` が空なのは、Git の資格情報のヘルパーが無いこと。[GitHub CLI](#github-cli)の手順 4 で `Y` と答えると、gh が `~/.gitconfig` に自分をヘルパーとして書く
- `Gh` が空なら、gh は入っていない。`C:\Users\<WIN_USER>\scoop\shims\gh.exe` だけなら、もう scoop で入っている（[GitHub CLI](#github-cli)の手順 3 の `scoop install` は何も変えない）
- ほかの方法で入れた gh を外すのは、混ざらないようにするため。外してもログインと設定は残り、scoop の gh も同じ場所を読む

**[GitHub CLI](#github-cli)の手順 3**

- 導入時の行は `'gh' (2.102.0) was installed successfully!` の形

**[GitHub CLI](#github-cli)の手順 3: 版**

- `'gh' (<版>) was installed successfully!` の版は、実行した日の最新

**[GitHub CLI](#github-cli)の手順 4: Git の認証に n と答える理由**

gh 2.102.0 のソースを読んで決めた（検証記録の付録（`docs/verification/windows-setup.md` の「GitHub CLI: 付録: Windows 11 の節の資料と Linux での確認（2026-10-08）」））。**Windows では確かめていない**。

- **問いが出る条件**: `gh auth login` で HTTPS を選ぶと、github.com の Git の資格情報のヘルパーが gh でなければ、`Authenticate Git with your GitHub credentials?`（既定は Yes）を聞く
  - ヘルパーは `credential.https://github.com.helper`、無ければ `credential.helper` を、スコープを問わずに読む
  - Git for Windows は、インストーラの既定の選択で `system`（`C:\Program Files\Git\etc\gitconfig`）に `credential.helper=manager`（Git Credential Manager）を書く（Git の検証記録（`docs/verification/almalinux-setup.md` の「Git: 実施手順 / 手順 3: 補足: 設定の 3 つの場所」））。そのため、[Windows 11 のセットアップ](#windows-11-のセットアップ)の順に通した PC では、この問いが出る
- **Yes と答えたとき**（ソースからの推論）
  - ヘルパーがある（Git for Windows の既定）: `~/.gitconfig` は変えない。`git credential reject` で github.com の資格情報を消してから、`git credential approve` で gh のトークンを Git Credential Manager に入れる。以後、git の HTTPS も gh のトークン（GitHub CLI の OAuth アプリ。`workflow` の権限も付く）で GitHub につなぐ
  - ヘルパーが無い: `~/.gitconfig` の `credential.https://github.com.helper` と `credential.https://gist.github.com.helper` に、空の値（ほかのヘルパーを切る）と `!<gh の場所> auth git-credential` を書く。`gh auth setup-git` と同じ
- **No を選んだ理由**
  - git の HTTPS の認証は、Git for Windows の Git Credential Manager が自分のサインイン（Git Credential Manager の OAuth アプリ）で行う。gh と git のトークンが別になるので、`gh auth logout`・GitHub CLI の認可の取り消し・gh を消すことが、git の push に効かない
  - Yes にすると、gh のトークンが Git Credential Manager にも残る。`gh auth logout` は gh 自身の置き場所しか消さない
  - `~/.gitconfig` に gh の場所を書かない。書くと、scoop を外した後も git がその場所の gh を呼ぶ
- **Git の資格情報のヘルパーが無い PC**（[GitHub CLI](#github-cli)の手順 2 の `GitCred` が空）では、Yes でよい。git の HTTPS の認証を gh に任せることになる
- **gh が書く自分の場所**: 環境変数 `GH_PATH` が無ければ、`PATH` の上の同じ名前のファイルが自分自身（かそのシンボリックリンク）ならそれ、違えば自分の実行ファイルの場所を書く（`internal/ghcmd/cmd.go`）
  - scoop の shim（`~\scoop\shims\gh.exe`）は別の実行ファイルなので、`C:\Users\<WIN_USER>\scoop\apps\gh\current\bin\gh.exe` になるはず（推論）。`current` は scoop の更新の後も同じ場所を指す

**[GitHub CLI](#github-cli)の手順 4: ワンタイムコード**

- gh の既定では、ワンタイムコードはクリップボードにも入る

**[GitHub CLI](#github-cli)の手順 6: トークンと設定の置き場所**

ソースから（gh 2.102.0、go-gh 2.16.1、go-keyring 0.2.8）。**Windows では確かめていない**。

| もの | Windows 11 の場所 | AlmaLinux 10 の場所 |
|---|---|---|
| トークン | 資格情報マネージャーの汎用資格情報 `gh:github.com:<GITHUB_USER>` と、今のアカウントの写しの `gh:github.com:`（名前はソースからの推論） | OS の資格情報ストア |
| トークン（ストアを使えないとき） | `%APPDATA%\GitHub CLI\hosts.yml`（平文） | `~/.config/gh/hosts.yml`（平文） |
| 設定（`config.yml`・`hosts.yml`） | `%APPDATA%\GitHub CLI` | `~/.config/gh` |
| 状態・拡張機能・キャッシュ | `%LOCALAPPDATA%\GitHub CLI` | `~/.local/state/gh`・`~/.local/share/gh`・`~/.cache/gh` |

- 設定の場所は、環境変数 `GH_CONFIG_DIR`、次に `XDG_CONFIG_HOME`（`%XDG_CONFIG_HOME%\gh`）があれば、そちらが先になる（go-gh の `ConfigDir`）
- `gh auth status` の `(keyring)` は、トークンが資格情報マネージャーにあること。平文のときは `hosts.yml` の場所が出る
- Git Credential Manager が git のために置く資格情報（`git:https://github.com` の名前になるはず）は、gh の項目とは別

**選択した方針**

[GitHub CLI](#github-cli)の理由。**Windows の実機では未検証**（検証記録（`docs/verification/windows-setup.md` の「GitHub CLI: Windows 11 で使う: 検証状況の記録」））。

- **scoop の main のバケットの `gh`**: [README の導入の基盤](../README.md#導入の基盤)の「CLI ツールは scoop」に合わせた
  - 管理者の権限が要らない。[更新](#更新)の `scoop update *` でほかのツールとまとめて上がり、UniGet UI にも出る
  - winget の `GitHub.cli` は、先に並ぶのが MSI（`Scope: machine`。`C:\Program Files\GitHub CLI` に入り、UAC が出る）。同じ zip の portable もあるが、採らない
  - 上流の MSI や zip を手で入れる形は、更新が手作業になる
  - scoop は、定義の sha256（上流の `gh_<版>_checksums.txt` と同じ値）で zip を確かめる。`gh.exe` には `GitHub, Inc.` の Authenticode の署名があるが、手順では確かめない
  - 版は固定しない（`scoop hold` しない）。scoop で止めるのは、Git Bash で移動先を記録しない 0.10.0 を避ける zoxide だけ（[シェルのツールを入れる](shell-terminal.md#シェルのツールを入れる)）
- **`XDG_CONFIG_HOME` は設定しない**: 設定すると、gh の設定の場所が `%XDG_CONFIG_HOME%\gh` に変わり、設定した窓と設定していない窓で、gh が別のログインの一覧を読む
  - Git for Windows の起動スクリプト、自分用の bash 設定、WezTerm の設定は、どれも `XDG_CONFIG_HOME` を設定しない。そのため、Git Bash・PowerShell・cmd の gh は、同じ `%APPDATA%\GitHub CLI` を読む（ソースと設定を読んだだけ）
  - トークンは資格情報マネージャー（ユーザーごと）にあるので、どのシェルからも同じ
- **git の HTTPS の認証は Git Credential Manager のまま**: この折りたたみの「GitHub CLI の手順 4: Git の認証に n と答える理由」
- **シェルとの組み込み方**
  - gh はシェルの初期化が要らない。scoop の shims（ユーザーの `PATH`）にあるので、Git Bash・PowerShell・cmd のどれからでも動く
  - **Git Bash が主**: WezTerm の自分用の設定の `default_prog` は Git Bash（`bash.exe -i -l`）。共通の bash 設定（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)）は gh を扱わない。bash の補完も入れない（足すなら bash リポジトリの変更になる）
  - **PowerShell 7 には補完を足す**: [PowerShell 7 のプロファイルに開発の設定を足す](shell-terminal.md#powershell-7-のプロファイルに開発の設定を足す)で、`gh completion -s powershell` の出力を控えたファイルから読む。gh を上げた後は、[PowerShell の開発の設定を更新する](shell-terminal.md#powershell-の開発の設定を更新する)で控えを作り直す
  - **Windows PowerShell 5.1 には gh の補完を足さない**。gh の設定とログインは、5.1 からも共通のものを使う
  - **WSL の AlmaLinux 10 は Linux のホストとして扱う**: WSL の中で[GitHub CLI](almalinux-setup.md#github-cli)を通す。設定とトークンは WSL の中にあり、Windows の gh とは別
- **Visual C++ のランタイムは要らない**: `gh.exe`（Go）のインポートは `kernel32.dll` だけ。bat・delta と違い、[Windows 11 で WezTerm を入れる](shell-terminal.md#windows-11-で-wezterm-を入れる)の手順 3 を前提にしない

**参照**

- 検証記録（`docs/verification/windows-setup.md`）

</details>

---

### lazygit

- scoop で lazygit を入れ、自分用の設定と起動を確かめる
- 前提: [scoop の導入](https://scoop.sh/)・[Git Bash と WezTerm の設定](shell-terminal.md#git-bash-と-wezterm-の設定)・[git-delta](#git-delta)・[HackGen Console NF](shell-terminal.md#windows-11-で-hackgen-console-nf-を入れる)を通してある
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. 管理者ではないことと、scoop・git・extras のバケット・ほかの lazygit を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     PowerShell = $PSVersionTable.PSVersion.ToString()
     Admin      = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Scoop      = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git        = (Get-Command git -ErrorAction SilentlyContinue).Source
     Extras     = if (Get-Command scoop -ErrorAction SilentlyContinue) { [bool](scoop bucket list | Where-Object Name -eq 'extras') } else { $false }
     Lazygit    = (Get-Command lazygit -All -ErrorAction SilentlyContinue).Source -join ', '
   } | Format-List
   ```

   - `PowerShell : 7.…` と `Admin : False` が出ればよい。`True` なら、窓を閉じて、この項の手順 1 のとおりに開き直す
   - `Scoop` に `…\scoop\shims\scoop.ps1` の場所が出ればよい。空なら、先に[scoop の公式の導入案内](https://scoop.sh/)に従って入れる
   - `Git` は `C:\Program Files\Git\cmd\git.exe` ならよい。空か違う場所なら、先に [Git for Windows](https://gitforwindows.org/)
   - ほかの場所（winget の `JesseDuffield.lazygit` など）が出たら、中断し、既存の導入元と設定を確かめる
   - `Extras : True` なら、extras のバケットはもうある（[Neovim](neovim.md#windows-11-で-neovim-を入れる)の手順 4 で足した）。この項の手順 3 は飛ばす

1. extras のバケットが無いときだけ、scoop に足す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop bucket add extras
   scoop bucket list
   ```

   - `The extras bucket was added successfully.` が出て、一覧に `main` と `extras` の行が出ればよい

1. scoop で lazygit を入れる。

   ```powershell
   scoop install lazygit
   ```

   - `lazygit` が `was installed successfully!` になればよい
   - `is already installed.` なら導入済みで、何も変えない

1. 自分用の設定（[ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit)）を入れる。

   - [lazygit の設定を導入する](#lazygit-の設定を導入する)の全項を通す
   - `custom` と `C:\Users\<WIN_USER>\AppData\Local\lazygit` が出れば、入っている
   - lazygit を起動する（この項の手順 7）前に入れる。先に起動すると、できた状態ファイルごと `lazygit.bak` に退避される

1. 版と、設定の置き場所を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # lazygit の版を確認する
   lazygit --version
   # 設定と実行ファイルの場所を確認する
   lazygit --print-config-dir
   (Get-Command lazygit -All).Source
   ```

   - 1 行目に `version=` と版、`os=windows, arch=amd64` を含む行が出ればよい
   - 2 行目は `C:\Users\<WIN_USER>\AppData\Local\lazygit`（[AlmaLinux 10 の初期設定の「lazygit の設定ファイル」](almalinux-setup.md#lazygit-の設定ファイル)）
   - 最後は `C:\Users\<WIN_USER>\scoop\shims\lazygit.exe` の 1 行だけならよい

1. 確かめ用の git のリポジトリで、lazygit を起動して確かめる。

   ```powershell
   # 確認用のリポジトリを作成する
   git init --quiet "$env:TEMP\lazygit-check"
   if (-not (Test-Path -LiteralPath "$env:TEMP\lazygit-check\.git")) { Write-Error '中断: 確かめ用のリポジトリ（%TEMP%\lazygit-check）を作れない' } else {
     # 確認用のリポジトリで lazygit を起動する
     Set-Location -LiteralPath "$env:TEMP\lazygit-check"
     lazygit
   }
   ```

   - `中断:` と出たら、lazygit は起動していない（git が呼べるかを、この項の手順 2 で確かめ直す）
   - 初回に `Thanks for using lazygit...` の案内が出たら Enter で閉じる
   - Status・Files・Branches・Commits などの欄が出ればよい
   - ほかのリポジトリで確かめるなら、そのフォルダーに `Set-Location` してから `lazygit` を打つ（git 管理外のフォルダーで起動すると、リポジトリを作るか聞かれる）
   - **注意**: PowerShell 7 から起動した lazygit の `e` キーは、git の `core.editor` と環境変数 `VISUAL`・`EDITOR` などが無いと `vim` で開こうとして失敗する
     - [Neovim を既定のエディタにする](neovim.md#neovim-を既定のエディタにする)で `nvim` にし、新しい窓で lazygit を起動し直す
     - Git Bash から起動したときは、共通の bash 設定が `nvim` にしてある
   - `q` で閉じる
   - `%TEMP%\lazygit-check` は、要らなければ手で消す
     - 消す前に `Set-Location ~` で出る
   - **ほかのブロックは、`q` で閉じてから貼る**（lazygit を開いたまま貼ると、lazygit への入力になる）

#### lazygit の設定を導入する

- Windows の lazygit の既存設定を退避し、自分用の設定を入れる
- 前提: [lazygit](#lazygit)の手順 1〜4 までを通し、本体を入れてある。[git-delta](#git-delta)・[HackGen Console NF](shell-terminal.md#windows-11-で-hackgen-console-nf-を入れる)も通し、Visual C++ ランタイムも[WezTerm](shell-terminal.md#windows-11-で-wezterm-を入れる)で入れてある
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く
- lazygit をすべて閉じてから始める。既存設定の確認と、この項の手順 2 の退避を省かない

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. 既存設定を退避して、設定ディレクトリへ clone する。

   ```powershell
   # lazygit の設定を退避して取得する
   $d = "$env:LOCALAPPDATA\lazygit"
   if (Test-Path -LiteralPath "$d.bak") {
     Write-Warning "$d.bak がすでにあるため中止しました。中身を確かめて片付けてから、貼り直してください"
   } else {
     if (Test-Path -LiteralPath $d) { Move-Item -LiteralPath $d -Destination "$d.bak" -ErrorAction Stop; "moved: $d -> $d.bak" }
     git clone https://github.com/ryo-aoki-pc/lazygit.git $d
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     git -C $d branch --show-current
     lazygit --print-config-dir
   }
   ```

   - `.bak` が既にあるときは退避・clone をせず中断する
   - `custom` と `%LOCALAPPDATA%\lazygit` が出ればよい

#### lazygit の設定を更新する

- 自分用の lazygit の設定の clone を GitHub の `custom` に合わせる。持ち主が上流の新しい版に合わせて `custom` を載せ替えた（force push した）後も、この項で合わせる
- 前提: [lazygit の設定を導入する](#lazygit-の設定を導入する)を通してある
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く。この項の手順 2 の手元の変更の確認を省かない
- lazygit 本体は[scoop・winget・WSL を上げる](#scoopwingetwsl-を上げる)の手順 2・3 で上げる

> [!WARNING]
> この項の手順 4 では、この clone でコミットしたものは新しい `custom` に載らない（前の位置は `git -C "$env:LOCALAPPDATA\lazygit" reflog` で見られる）。

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. 手元の変更を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   git -C "$env:LOCALAPPDATA\lazygit" status --short --branch
   ```

   - 1 行目が `## custom...origin/custom` で始まればよい（`[ahead …, behind …]` が続いてもよい）
   - 2 行目から出る行（` M config.yml` など）は手元の変更。この項の手順 3 で残したまま合わせる
   - 1 行目が `## HEAD (no branch)` で、前にこの項の手順 3 を貼って止まったままなら、この項の手順 3 は飛ばし、手順 4 から貼る
   - そのほかに、1 行目が `## custom` で始まらなければ、中断する

1. GitHub の `custom` に合わせる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   git -C "$env:LOCALAPPDATA\lazygit" pull --rebase --autostash
   git -C "$env:LOCALAPPDATA\lazygit" status --short --branch
   ```

   - `Successfully rebased and updated refs/heads/custom.`・`Fast-forward`・`Already up to date.` のどれかが出て、`status` の 1 行目が `## custom...origin/custom`（`[ahead`・`[behind` が付かない）で、2 行目から `UU` の行が無ければよい
   - 書き換わった `custom` を取り込んだときは、`(forced update)` の行が出る
   - 手元の変更を退避して戻したときは、`status` の 2 行目から同じ形で残ればよい
   - `[ahead 1]` などが残ったら、この clone でコミットしたものが新しい `custom` の上に載っている
   - 1 行目が `## HEAD (no branch)` なら（`Could not apply` と出て止まった。`UU` の行も出る）、この項の手順 4 を貼る。手順 5 へ進むかは、手順 4 の `status` で決める
   - 1 行目が `## HEAD (no branch)` でなければ、この項の手順 4 は飛ばす
   - 1 行目が `## custom...origin/custom` で始まり、2 行目から `UU` で始まる行があれば（`resulted in conflicts` と出た）、この項の手順 5 を貼る。無ければ、この項の手順 5 は飛ばす

1. この項の手順 3 の `status` の 1 行目が `## HEAD (no branch)` のときだけ、手元の変更を残して rebase を取り消し、新しい `custom` に移る。

   ```powershell
   # 進行中のリベースを中止する
   git -C "$env:LOCALAPPDATA\lazygit" rebase --abort
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   git -C "$env:LOCALAPPDATA\lazygit" rebase --autostash --onto origin/custom HEAD
   git -C "$env:LOCALAPPDATA\lazygit" status --short --branch
   ```

   - `Successfully rebased and updated refs/heads/custom.` と出て、`status` の 1 行目が `## custom...origin/custom`（`[ahead`・`[behind` が付かない）で、2 行目から `UU` の行が無ければよい
   - 手元の未コミットの変更は残る
   - 2 行目から `UU` で始まる行があれば、この項の手順 5 を貼る。無ければ、この項の手順 5 は飛ばす

1. この項の手順 3・4 の `status` が `## custom` で始まり `UU` の行を出したときだけ、作業ツリーを新しい設定に戻す。

   ```powershell
   # 作業ツリーの変更を破棄する
   git -C "$env:LOCALAPPDATA\lazygit" reset -q --hard
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # 設定リポジトリの状態を確認する
   git -C "$env:LOCALAPPDATA\lazygit" status --short --branch
   # 退避した変更を確認する
   git --no-pager -C "$env:LOCALAPPDATA\lazygit" stash show -p
   ```

   - `status` が `## custom...origin/custom` の 1 行だけになり、その後ろに手元の変更の差分が出ればよい
   - 手元の変更は、ぶつからなかったファイルの分も作業ツリーから消え、stash にだけ残っている。要るものをエディタで書き直す
   - 書き直したら、`git -C "$env:LOCALAPPDATA\lazygit" stash drop` で stash を消す

1. 設定の元にした上流の版と、入っている本体の版を比べる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # 上流の基準の版を確認する
   git --no-pager -C "$env:LOCALAPPDATA\lazygit" log -1 --format=%s origin/main
   # lazygit の版を確認する
   lazygit --version
   ```

   - 上流のデフォルト設定の版と、その次の `version=` の版が同じならよい
   - 本体の方が古ければ、[scoop・winget・WSL を上げる](#scoopwingetwsl-を上げる)の手順 2・3 で上げる

<details id="lazygit-の補足と注意点">
  <summary>lazygit の補足と注意点</summary>

**注意点**

- **lazygit: Windows 11 では、winget の lazygit（`JesseDuffield.lazygit`）と両方入れない**: どちらが使われるかが `PATH` の順で決まり、分かりにくくなる。どちらか一方にする

**[lazygit](#lazygit)の手順 2: 確かめる値の意味**

- `Lazygit` が空なら、lazygit は入っていない。`C:\Users\<WIN_USER>\scoop\shims\lazygit.exe` だけなら、もう scoop で入っている（自分用の Neovim の設定の導入でも入る）

**[lazygit](#lazygit)の手順 4**

- 導入時の行は `'lazygit' (0.66.0) was installed successfully!` の形

**[lazygit](#lazygit)の手順 4・6: 版**

- [lazygit](#lazygit)の手順 4 の `'lazygit' (<版>) was installed successfully!` と、[lazygit](#lazygit)の手順 6 の `version=` の版は、実行した日の最新

**[lazygit](#lazygit)の手順 6**

- 版の表示は `version=0.66.0, os=windows, arch=amd64` の形

**[lazygit](#lazygit)の手順 7**

- 確かめ用は空のリポジトリなので、一覧は空

**[lazygit](#lazygit)の手順 7: 新しい窓と確かめ用のリポジトリ**

- `EDITOR` を `nvim` にした後、新しい窓で lazygit を起動し直すのは、今の窓には入らないため
- `%TEMP%\lazygit-check` を消す前に `Set-Location ~` で出るのは、この窓の今のフォルダーがそこにあり、今のフォルダーのままでは使用中で消せないため

**[lazygit の設定を導入する](#lazygit-の設定を導入する)の手順 2**

- 状態ファイルも同じ場所に置くが Git の追跡対象からは除外する

**[lazygit の設定を更新する](#lazygit-の設定を更新する)の手順 3**

- 手元の変更を退避して戻したときは、`Created autostash:`・`Applied autostash.` が出る

**[lazygit の設定を更新する](#lazygit-の設定を更新する)の手順 3: force push と分岐点**

- `--ff-only` を使わない理由、fork point と reflog、`--rebase --autostash` を明示する理由は、[lazygit の補足と注意点](almalinux-setup.md#lazygit-の補足と注意点)の「lazygit の設定を更新するの手順 2: force push と分岐点」を参照する

**[lazygit の設定を更新する](#lazygit-の設定を更新する)の手順 4: 分岐点が分からないときの載せ直し**

- rebase が止まる条件と、`--onto origin/custom HEAD` でこの clone だけのコミットを載せない理由は、[lazygit の補足と注意点](almalinux-setup.md#lazygit-の補足と注意点)の「lazygit の設定を更新するの手順 3: 分岐点が分からないときの載せ直し」を参照する

**[lazygit の設定を更新する](#lazygit-の設定を更新する)の手順 5: autostash の衝突と reset の範囲**

- 終了コードと `UU` の行による判定、reset の範囲は、[lazygit の補足と注意点](almalinux-setup.md#lazygit-の補足と注意点)の「lazygit の設定を更新するの手順 4: autostash の衝突と reset の範囲」を参照する
- git 2.55.0.windows.5 は、autostash の衝突を `Your local changes are stashed, however applying them` に続く `resulted in conflicts` で知らせる
- git 2.52.0 の文言とは違うので、手順書では `status` の `UU` の行で見分ける

**[lazygit の設定を更新する](#lazygit-の設定を更新する)の手順 6**

- 比べる表示の例は、`lazygit v0.66.0 のデフォルト設定に更新` と `version=0.66.0`

**[lazygit の設定を更新する](#lazygit-の設定を更新する)の手順 6: Windows PowerShell 5.1 のコンソールの表示**

- 版の読み方と `--no-pager` の理由は、[lazygit の補足と注意点](almalinux-setup.md#lazygit-の補足と注意点)の「lazygit の設定を更新するの手順 5: 版の表示と pager」を参照する
- Windows PowerShell 5.1 のコンソール（コードページ shift_jis）でも、日本語のコミットの題は正しく表示された。Git for Windows がコンソールへ直接書くため

**選択した方針**

[lazygit](#lazygit)の理由。**Windows 実機では未検証**（検証記録（`docs/verification/windows-setup.md` の「lazygit: Windows 11 で使う: 検証状況の記録」））。

- **scoop の extras の `lazygit`**（main のバケットには無い）
  - extras のバケットを足すのに git が要る（Git for Windows）。extras は、ほかのアプリ（`vcredist2022`・`neovide` など）も使う
  - lazygit は Go の 1 つの実行ファイルなので、VC++ のランタイムは要らない（自分用の設定が使う delta は要る。[git-delta](#git-delta)の手順 2 で確かめる）
  - winget の `JesseDuffield.lazygit` と両方あると、`PATH` の順でどちらかが使われ、分かりにくい。[lazygit](#lazygit)の手順 2 で見つけたら、外してから始める
- **設定の置き場所は `%LOCALAPPDATA%\lazygit`**
  - lazygit 0.66.0 の Config.md の Windows の既定の場所。`%APPDATA%\lazygit\config.yml` も探す（adrg/xdg の Windows の `XDG_CONFIG_DIRS` は `%ProgramData%` と `%APPDATA%`）
  - `XDG_CONFIG_HOME` は設定しない（[Windows 11 で Neovim を入れる の補足と注意点](neovim.md#windows-11-で-neovim-を入れる-の補足と注意点)の「選択した方針」）
- **自分用の設定**: `%LOCALAPPDATA%\lazygit` に直接 clone する（シンボリックリンクには、開発者モードか管理者の権限が要るため）。状態ファイル `state.yml` は、そのリポジトリの `.gitignore` で除いてある
- **確かめの起動は `%TEMP%\lazygit-check` の空のリポジトリで行う**
  - 読者のリポジトリの場所を決め打ちできないため。git 管理外で起動すると、リポジトリを作るか聞かれる
  - `git init` が失敗したまま起動すると、元のフォルダーでリポジトリを作るか聞かれるので、`.git` ができたことを確かめてから起動する
- **`e` キーのエディタ**: PowerShell 7 から起動したときは、ユーザーの環境変数 `EDITOR` で決まる（[Windows 11 で Neovim を入れる の補足と注意点](neovim.md#windows-11-で-neovim-を入れる-の補足と注意点)の「選択した方針」）。自分用の設定は `os.editInTerminal` を `true` にした（`false` を明示すると、lazygit 0.66.0 ではプリセットより優先され、端末のエディタに端末が渡らない。ryo-aoki-pc/lazygit#10）

**参照**

- 検証記録（`docs/verification/windows-setup.md`）

</details>

---

### yazi

- scoop で yazi と依存ツールを入れ、自分用の設定とプレビュー・移動を確かめる
- 前提: [scoop の導入](https://scoop.sh/)と[Git Bash と WezTerm の設定](shell-terminal.md#git-bash-と-wezterm-の設定)を通してある。Visual C++ ランタイムも[WezTerm](shell-terminal.md#windows-11-で-wezterm-を入れる)で入れてある
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く。この項の手順 8・9 は WezTerm の新しい Git Bash のタブ

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. 変数を設定する。

   ```powershell
   $YAZI_EXTRAS = @('ffmpeg', '7zip', 'jq', 'poppler', 'fd', 'ripgrep', 'fzf', 'resvg', 'imagemagick')   # プレビューと検索に使う。@() にすると yazi 本体だけ
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'YAZI_EXTRAS = {0}' -f ($YAZI_EXTRAS -join ' ')
   ```

   - **編集が必須の変数は無い**
   - 最小構成にするなら、`$YAZI_EXTRAS = @()` にする
   - 減らして 1 つだけにするときも、`@('fd')` の形のままにする
   - 最後の行で値を読み戻して確かめる
   - **新しい PowerShell を開いたら**、先にこのブロックを貼り直す

1. 管理者ではないことと、scoop・`file.exe`・VC++ のランタイム・ほかの yazi・設定を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     PowerShell  = $PSVersionTable.PSVersion.ToString()
     Admin       = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Scoop       = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git         = (Get-Command git -ErrorAction SilentlyContinue).Source
     FileExe     = Test-Path -LiteralPath 'C:\Program Files\Git\usr\bin\file.exe'
     VCRuntime   = Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
     Yazi        = (Get-Command yazi -All -ErrorAction SilentlyContinue).Source -join ', '
     YaziFileOne = [Environment]::GetEnvironmentVariable('YAZI_FILE_ONE', 'User')
     Config      = Test-Path -LiteralPath "$env:APPDATA\yazi\config"
   } | Format-List
   ```

   - `PowerShell : 7.…`・`Admin : False`・`FileExe : True` が出ればよい。`Admin : True` なら、窓を閉じて、この項の手順 1 のとおりに開き直す（この項の手順 2 も貼り直す）
   - `Scoop` に `…\scoop\shims\scoop.ps1` の場所が出ればよい。空なら、先に[scoop の公式の導入案内](https://scoop.sh/)に従って入れる
   - `Git` が `C:\Program Files\Git\cmd\git.exe` でないか、`FileExe : False` なら、先に [Git for Windows](https://gitforwindows.org/)
   - `VCRuntime : False` なら、[WezTerm](shell-terminal.md#windows-11-で-wezterm-を入れる)の手順 3 を管理者の PowerShell 7 で行ってから、この手順を貼り直す
   - `Yazi` は空か `C:\Users\<WIN_USER>\scoop\shims\yazi.exe` ならよい。ほかの場所なら、中断し、既存の導入元と設定を確かめる
   - `YaziFileOne` の元の値を控える。この項の手順 5 で Git for Windows の `file.exe` に上書きする

1. scoop で yazi と、プレビュー・検索に使うツールを入れる。

   ```powershell
   if ($null -eq $YAZI_EXTRAS) { Write-Error '中断: この項の手順 2 の $YAZI_EXTRAS が無い。この項の手順 2 を貼り直す' } else { scoop install yazi @YAZI_EXTRAS }
   ```

   - アプリごとに `was installed successfully!` が出ればよい。導入済みのものは `is already installed.` が出て、飛ばされる
   - `'ripgrep' suggests installing 'extras/vcredist2022'.` などの `suggests installing` の行は、入れなくてよい
   - `中断:` と出たら、何も入れていない（新しい窓では、この項の手順 2 を貼り直す。yazi 本体だけにするなら `$YAZI_EXTRAS = @()`）

1. ユーザーの環境変数 `YAZI_FILE_ONE` を Git for Windows の `file.exe` にする。

   ```powershell
   # yazi が使う file の場所を設定する
   if (-not (Test-Path -LiteralPath 'C:\Program Files\Git\usr\bin\file.exe')) { Write-Error '中断: C:\Program Files\Git\usr\bin\file.exe が無い（「Git for Windows」で入れる）' } else {
     [Environment]::SetEnvironmentVariable('YAZI_FILE_ONE', 'C:\Program Files\Git\usr\bin\file.exe', 'User')
     $env:YAZI_FILE_ONE = [Environment]::GetEnvironmentVariable('YAZI_FILE_ONE', 'User')
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'YAZI_FILE_ONE = {0}' -f $env:YAZI_FILE_ONE
   }
   ```

   - `YAZI_FILE_ONE = C:\Program Files\Git\usr\bin\file.exe` が出ればよい
   - ほかの窓は開き直してから効く（WezTerm は新しいタブから）
   - `中断:` と出たら、何も変えていない

1. 自分用の設定（[ryo-aoki-pc/yazi](https://github.com/ryo-aoki-pc/yazi)）を入れる。

   - [yazi の設定を導入する](#yazi-の設定を導入する)の全項を通す
   - `custom` が出れば、入っている
   - 本体の依存と `YAZI_FILE_ONE` はこの項で設定済み。参照先は設定リポジトリの導入・確認を行う

1. 版と、yazi から見た環境を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # yazi と ya の版を確認する
   yazi --version
   ya --version
   # yazi の実行環境を確認する
   ya env
   ```

   - `yazi --version` と `ya --version` に同じ `Version:` が出て、yazi の `Triple` が `windows-x86_64` ならよい
   - 無出力で終わるか `VCRUNTIME140.dll` のエラーなら、VC++ ランタイムをこの項の手順 3 で確かめる
     - 窓が出たら、OK で閉じる
   - `ya env` の `Config` の各行に `C:\Users\<WIN_USER>\AppData\Roaming\yazi\config\…` が出る
     - 設定のフォルダーが無ければ、パスが見つからない旨と `os error 3` が出る
     - フォルダーはあってファイルが無い行は、ファイルが見つからない旨と `os error 2`
   - `Variables` の `YAZI_FILE_ONE` が `Some("C:\\Program Files\\Git\\usr\\bin\\file.exe")` ならよい
   - `Dependencies` の `file` に版が出て、最後の `Routine` の `` `file -bL --mime-type` `` が `text/plain` ならよい
   - `Dependencies` に、`$YAZI_EXTRAS` で入れたもの（ffmpeg・pdftoppm・magick・fzf・fd・rg・7z・resvg・jq）の版が出る

1. WezTerm で新しいタブを開く。

   - 自分用の WezTerm の設定では、新しいタブで Git Bash が開く
   - **次の手順は、開いた Git Bash のタブに貼る**（bash の構文なので、PowerShell には貼らない）

1. そのタブで `y` を確かめ、yazi を開く。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   type -t y
   y
   ```

   - `function` が出ればよい
   - 最後の `y` で yazi が開く。別のフォルダーへ移って `q` で閉じると、Git Bash もそのフォルダーへ移る（`Q` なら移らない）
   - **次の手順は、yazi を閉じて、この項の手順 1 の PowerShell に戻ってから貼る**（続けて貼ると、後ろの行も Git Bash で動き、PowerShell での確認にならない）

1. yazi を起動して確かめる。

   ```powershell
   yazi
   ```

   - プレビューを確かめるには、PDF・動画・画像・書庫のあるフォルダーで右のペインを見る
   - 画像のプレビューは、WezTerm（nightly）か Windows Terminal（1.22.10352.0 以降）の中で出る。conhost の窓では出ない
   - `q` で閉じる
   - **ほかのブロックは、`q` で閉じてから貼る**（yazi を開いたまま貼ると、yazi への入力になる）

#### yazi の設定を導入する

- Windows の yazi の既存設定を退避し、自分用の設定を入れる
- 前提: [yazi](#yazi)の手順 1〜5 までを通し、本体と依存ツールを入れ、`YAZI_FILE_ONE` を設定してある。Git も[Git for Windows](https://gitforwindows.org/)で入れてある
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く
- yazi をすべて閉じてから始める。既存設定の確認と、この項の手順 2 の退避を省かない

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. yazi を終了し、自分用の設定を clone する。

   ```powershell
   # yazi の設定を退避して取得する
   $dst = "$env:APPDATA\yazi\config"
   if ((Test-Path -LiteralPath $dst) -and (Test-Path -LiteralPath "$dst.bak")) {
     Write-Error "中断: $dst.bak が既にある。中身を確かめて片付けてから貼り直す"
   } else {
     if (Test-Path -LiteralPath $dst) { Move-Item -LiteralPath $dst -Destination "$dst.bak" -ErrorAction Stop }
     git clone -b custom https://github.com/ryo-aoki-pc/yazi.git $dst
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     git -C $dst branch --show-current
   }
   ```

   - `custom` ブランチを使う。導入先は `%APPDATA%\yazi\config`
   - 既存設定と `.bak` が両方ある場合は何も変更せず中断する
   - `ya env` の Config で読み込む場所を確かめる

#### yazi で複数ファイルをまとめて開く

- yazi で選択した複数ファイルを、`l` / `<Enter>` でまとめて開く設定を足す
- 前提: [yazi](#yazi)と[Neovim](neovim.md#windows-11-で-neovim-を入れる)を通してある
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く。この項の手順 2・3 は Neovim、手順 4 は yazi の画面
- 既存の `init.lua` の変更を確かめ、yazi をすべて閉じてから始める
- `l` / `<Enter>` は既定でホバー中の 1 ファイルだけを開く。選択した複数ファイルをまとめて開くときだけ行う

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. yazi の `init.lua` を Neovim で開く。

   ```powershell
   nvim "$env:APPDATA\yazi\config\init.lua"
   ```

   - 既存の `init.lua` の本文が開けばよい
   - **次の手順は、Esc → `G` → `o` で末尾に行を足し、挿入モードの本文に貼る**（PowerShell には貼らない）

1. Neovim で開いた `init.lua` に、複数ファイルを開く行を足す。

   ```lua
   require("smart-enter"):setup { open_multi = true }
   ```

   - 貼り終えたら Esc を押し、`:wq` を打って Enter で保存して閉じる
   - **次の手順は、Neovim を閉じてから、この項の手順 1 の PowerShell に貼る**（Neovim を開いたまま貼ると、Neovim への入力になる）

1. yazi を起動し、選択した複数ファイルをまとめて開けるか確かめる。

   ```powershell
   yazi
   ```

   - 選択した複数ファイルが `l` / `<Enter>` でまとめて開けばよい
   - `q` で yazi を閉じる
   - **ほかのブロックは、yazi を閉じてから貼る**（yazi を開いたまま貼ると、yazi への入力になる）

#### yazi の設定を更新する

- 自分用の yazi の設定の clone を GitHub の `custom` に合わせる。持ち主が上流の新しい版に合わせて `custom` を載せ替えた（force push した）後も、この項で合わせる
- 前提: [yazi の設定を導入する](#yazi-の設定を導入する)を通してある
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く。この項の手順 2 の手元の変更の確認を省かない
- yazi 本体は[scoop・winget・WSL を上げる](#scoopwingetwsl-を上げる)の手順 2・3 で上げる

> [!WARNING]
> この項の手順 4 では、この clone でコミットしたものは新しい `custom` に載らない（前の位置は `git -C "$env:APPDATA\yazi\config" reflog` で見られる）。

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. 手元の変更を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   git -C "$env:APPDATA\yazi\config" status --short --branch
   ```

   - 1 行目が `## custom...origin/custom` で始まればよい（`[ahead …, behind …]` が続いてもよい）
   - 2 行目から出る行（` M init.lua` など）は手元の変更。この項の手順 3 で残したまま合わせる
   - 1 行目が `## HEAD (no branch)` で、前にこの項の手順 3 を貼って止まったままなら、この項の手順 3 は飛ばし、手順 4 から貼る
   - そのほかに、1 行目が `## custom` で始まらなければ、中断する

1. GitHub の `custom` に合わせる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   git -C "$env:APPDATA\yazi\config" pull --rebase --autostash
   git -C "$env:APPDATA\yazi\config" status --short --branch
   ```

   - `Successfully rebased and updated refs/heads/custom.`・`Fast-forward`・`Already up to date.` のどれかが出て、`status` の 1 行目が `## custom...origin/custom`（`[ahead`・`[behind` が付かない）で、2 行目から `UU` の行が無ければよい
   - 書き換わった `custom` を取り込んだときは、`(forced update)` の行が出る
   - 手元の変更を退避して戻したときは、`status` の 2 行目から同じ形で残ればよい
   - `[ahead 1]` などが残ったら、この clone でコミットしたものが新しい `custom` の上に載っている
   - 1 行目が `## HEAD (no branch)` なら（`Could not apply` と出て止まった。`UU` の行も出る）、この項の手順 4 を貼る。手順 5 へ進むかは、手順 4 の `status` で決める
   - 1 行目が `## HEAD (no branch)` でなければ、この項の手順 4 は飛ばす
   - 1 行目が `## custom...origin/custom` で始まり、2 行目から `UU` で始まる行があれば（`resulted in conflicts` と出た）、この項の手順 5 を貼る。無ければ、この項の手順 5 は飛ばす

1. この項の手順 3 の `status` の 1 行目が `## HEAD (no branch)` のときだけ、手元の変更を残して rebase を取り消し、新しい `custom` に移る。

   ```powershell
   # 進行中のリベースを中止する
   git -C "$env:APPDATA\yazi\config" rebase --abort
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   git -C "$env:APPDATA\yazi\config" rebase --autostash --onto origin/custom HEAD
   git -C "$env:APPDATA\yazi\config" status --short --branch
   ```

   - `Successfully rebased and updated refs/heads/custom.` と出て、`status` の 1 行目が `## custom...origin/custom`（`[ahead`・`[behind` が付かない）で、2 行目から `UU` の行が無ければよい
   - 手元の未コミットの変更は残る
   - 2 行目から `UU` で始まる行があれば、この項の手順 5 を貼る。無ければ、この項の手順 5 は飛ばす

1. この項の手順 3・4 の `status` が `## custom` で始まり `UU` の行を出したときだけ、作業ツリーを新しい設定に戻す。

   ```powershell
   # 作業ツリーの変更を破棄する
   git -C "$env:APPDATA\yazi\config" reset -q --hard
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # 設定リポジトリの状態を確認する
   git -C "$env:APPDATA\yazi\config" status --short --branch
   # 退避した変更を確認する
   git --no-pager -C "$env:APPDATA\yazi\config" stash show -p
   ```

   - `status` が `## custom...origin/custom` の 1 行だけになり、その後ろに手元の変更の差分が出ればよい
   - 手元の変更は、ぶつからなかったファイルの分も作業ツリーから消え、stash にだけ残っている
   - `init.lua` の `open_multi` の行は、[yazi で複数ファイルをまとめて開く](#yazi-で複数ファイルをまとめて開く)を通し直して足す。新しい `init.lua` に同じ行が既にあれば、足さない
   - ほかの変更は、要るものをエディタで書き直す
   - 書き直したら、`git -C "$env:APPDATA\yazi\config" stash drop` で stash を消す

1. 設定の元にした上流の版と、入っている本体の版を比べる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # 設定の基準の版を確認する
   git -C "$env:APPDATA\yazi\config" describe --tags --abbrev=0
   # yazi の版を確認する
   yazi --version
   ```

   - `upstream/v…` の版と、その後ろの `Version:` の版が同じならよい
   - 本体の方が古ければ、[scoop・winget・WSL を上げる](#scoopwingetwsl-を上げる)の手順 2・3 で上げる

<details id="yazi-の補足と注意点">
  <summary>yazi の補足と注意点</summary>

**注意点**

- **yazi: Windows 11 では、`file` を `YAZI_FILE_ONE` で渡す**: 無いと PowerShell から起動した yazi はファイルの種類が分からず、開く・プレビューの規則が効かない（[yazi](#yazi)の手順 5）。Git for Windows を外すと、同じことになる
  - PowerShell の `PATH` には `file` が無い（Git Bash には `/usr/bin/file` がある）

- **yazi: Windows 11 の画像プレビューは、端末と ConPTY に依存する**: WezTerm（nightly）か Windows Terminal（1.22.10352.0 以降）で出る。ConPTY の制約で、Linux と同じには出ないことがある

**[yazi](#yazi)の手順 2: 変数について**

- 既定は、プレビュー・検索用のツールを一緒に入れる想定になっている（どれも scoop の main のバケットにある）
- 1 つだけにするときも `@('fd')` の形のままにするのは、`'fd'` だけにすると、1 文字ずつ別の名前として scoop に渡るため

**[yazi](#yazi)の手順 3: 確かめる値の意味**

- ほかの場所の yazi を外すのは、混ざらないようにするため
- `Config : True` なら、設定がもうある（[yazi の設定ファイル](almalinux-setup.md#yazi-の設定ファイル)）

**[yazi](#yazi)の手順 4**

- scoop の `file` は入れない

- 導入時の行は `'yazi' (26.9.1) was installed successfully!` などの形

**[yazi](#yazi)の手順 4: 版と、出る行・環境変数**

- [yazi](#yazi)の手順 4 の `'yazi' (<版>) was installed successfully!` と、[yazi](#yazi)の手順 7 の `Version:` の版は、実行した日の最新
- `suggests installing` の行のものを入れなくてよいのは、VC++ のランタイムを[yazi](#yazi)の手順 3 で確かめてあるため
- imagemagick が足すユーザーの環境変数（`MAGICK_HOME` など）と `PATH` は、今の窓にも入る。ほかの開いている窓は、開き直してから効く

**[yazi](#yazi)の手順 5**

- 何度貼ってもよい

- ユーザーの環境変数は、今の窓にも入れる

**[yazi](#yazi)の手順 7**

- 版の表示は、yazi と ya が `Version: 26.9.1 (…)` の形

**[yazi](#yazi)の手順 9**

- Git Bash の `y` の確かめは、[yazi](almalinux-setup.md#yazi)の手順 4 と同じ

**[yazi](#yazi)の手順 10**

- 既定の端末が Windows Terminal の PC では、この窓も Windows Terminal で開く

**[yazi の設定を更新する](#yazi-の設定を更新する)の手順 3**

- 手元の変更を退避して戻したときは、`Created autostash:`・`Applied autostash.` が出る

**[yazi の設定を更新する](#yazi-の設定を更新する)の手順 3: force push と分岐点**

- `--ff-only` を使わない理由、fork point と reflog、pull による上流のタグの取得は、[yazi の補足と注意点](almalinux-setup.md#yazi-の補足と注意点)の「yazi の設定を更新するの手順 2: force push と分岐点」を参照する

**[yazi の設定を更新する](#yazi-の設定を更新する)の手順 4: 分岐点が分からないときの載せ直し**

- rebase が止まる条件と、`--onto origin/custom HEAD` でこの clone だけのコミットを載せない理由は、[yazi の補足と注意点](almalinux-setup.md#yazi-の補足と注意点)の「yazi の設定を更新するの手順 3: 分岐点が分からないときの載せ直し」を参照する

**[yazi の設定を更新する](#yazi-の設定を更新する)の手順 5: autostash の衝突と reset の範囲**

- reset の範囲は、[yazi の補足と注意点](almalinux-setup.md#yazi-の補足と注意点)の「yazi の設定を更新するの手順 4: autostash の衝突と reset の範囲」を参照する
- Windows の git 2.55.0.windows.5 の文言は、[lazygit の補足と注意点](#lazygit-の補足と注意点)の「lazygit の設定を更新するの手順 5: autostash の衝突と reset の範囲」と同じ

**[yazi の設定を更新する](#yazi-の設定を更新する)の手順 6**

- 比べる表示の例は、`upstream/v26.9.1` と `Version: 26.9.1`

**選択した方針**

[yazi](#yazi)の理由。**Windows 実機では未検証**（検証記録（`docs/verification/windows-setup.md` の「yazi: Windows 11 で使う: 検証状況の記録」））。

- **scoop の main の `yazi`**: yazi の公式の文書が Windows で案内する経路の 1 つ。依存のツールも main にある
- **`$YAZI_EXTRAS` は、AlmaLinux 10 の `YAZI_EXTRAS` に合わせた**
  - 公式の文書の scoop の一覧（ffmpeg・7zip・jq・poppler・fd・ripgrep・fzf・zoxide・resvg・imagemagick）から zoxide を外した。AlmaLinux 10 の一覧にも無く、AlmaLinux 10 は [シェルのツール](shell-terminal.md#シェルのツール)の手順 1、Windows 11 は [シェルのツールを入れる](shell-terminal.md#シェルのツールを入れる)で入れる（Windows の zoxide は、Git Bash での記録の問題があるので、その節で 0.9.9 に止めてある）
  - Homebrew の `font-symbols-only-nerd-font` の代わりは、[Windows 11 で HackGen Console NF を入れる](shell-terminal.md#windows-11-で-hackgen-console-nf-を入れる)の HackGen Console NF
  - 変数が無いまま `scoop install yazi @YAZI_EXTRAS` を流すと、空の引数が 1 つ scoop に渡った（Linux の PowerShell 7.5.3 での模擬。検証記録の付録（`docs/verification/windows-setup.md` の「yazi: 付録: Windows 11 の節の資料と Linux での確認（2026-10-08）」））
    - そのため、[yazi](#yazi)の手順 4 は、[yazi](#yazi)の手順 2 を貼っていない窓では止める
- **`file` は、Git for Windows の `usr\bin\file.exe` を `YAZI_FILE_ONE` で渡す**
  - yazi の文書が勧める唯一の形。scoop・Chocolatey の `file` は Unicode のファイル名を扱えない
  - yazi は `YAZI_FILE_ONE` をシェルを通さずに起動するので、`Program Files` の空白は問題にならない
    - yazi 26.9.1 の `yazi-plugin/preset/plugins/mime-local.lua`・`file.lua` は、`Command(<YAZI_FILE_ONE の値>)` で起動する
    - Lua の `Command` は、`yazi-binding/src/process/command.rs` の `tokio::process::Command::new`（シェルを挟まない）。`ya env` も `Command::new` で動かす（`yazi-cli/src/env/env.rs`）
  - PowerShell の `PATH` には `file` が無い。Git Bash には `/usr/bin/file` があるが、PowerShell や Windows Terminal から起動したときにも同じに動くよう、ユーザーの環境変数にする
  - [yazi](#yazi)の手順 5 は、前の値を確かめずに上書きする。元の値は[yazi](#yazi)の手順 3 で控える
- **VC++ のランタイムは、Neovim と同じく「Windows 11 で WezTerm を入れる」の手順 3 を前提にする**: yazi 26.9.1 の Windows 版（msvc）の `yazi.exe`・`ya.exe` は `VCRUNTIME140.dll` を使い、scoop の `yazi` はランタイムを入れない（リリースの zip のインポート表。検証記録の付録（`docs/verification/windows-setup.md` の「yazi: 付録: Windows 11 の節の資料と Linux での確認（2026-10-08）」））
- **設定は `%APPDATA%\yazi\config`**: Windows の yazi は `XDG_CONFIG_HOME` を見ない（yazi 26.9.1 の `yazi-fs/src/xdg.rs`）。状態は `%APPDATA%\yazi\state`、キャッシュは `%LOCALAPPDATA%\yazi`。自分用の設定は、[yazi の設定を導入する](#yazi-の設定を導入する)で入れる
- **`y` は Git Bash の共通の設定だけで使う**: 手順書の PowerShell のブロックは PowerShell 7 に貼る。Windows PowerShell 5.1 に貼る項は、その項のリードに書く。PowerShell 版の `y` は足さず、WezTerm の自分用の設定は、Windows の新しいタブで Git Bash を開く
  - PowerShell 7 のプロファイル（[PowerShell 7 のプロファイルを設定する](shell-terminal.md#powershell-7-のプロファイルを設定する)）にも、`y` は足していない。その節が足すのは貼り付け・履歴の検索と zoxide・starship の行だけで、PowerShell 版の `y` はこの文書の範囲の外にした
- **ファイルを開くエディタは、自分用の設定の Neovim を前提にした**（Windows 11 で使うのリードで、先に Neovim を通すよう案内する）
  - 上流の既定（yazi 26.9.1 の `yazi-config/preset/yazi-default.toml`）の `[opener]` の `edit` は、Windows では `code %s` と `code -w %s`（VS Code）
  - `${EDITOR:-vi}` は `for = "unix"` の行だけで、Windows の yazi は `EDITOR` を見ない
  - テキスト（`text/*`）は `edit` が最初の候補なので、自分用の設定が無いと、Git Bash の `y` から開いても Enter で `code` が動く
  - 自分用の設定（`ryo-aoki-pc/yazi` の `yazi.toml`）は、Windows の `edit` を `nvim %s`（`block = true`）にしてある
- **確かめは `ya env`**: 26.9.1 には `yazi --debug` が無く、`ya env` が設定の場所・変数・依存の版・`file -bL --mime-type` の結果を出す
- **TUI の手順を節の最後にした**: Git Bash の `y` の確かめを先にし、PowerShell の `yazi` の起動を最後に置いた
  - Git Bash のタブを開くところ（コマンドの無い[yazi](#yazi)の手順 8）と、そこに貼る `type -t y` と `y`（`bash` のブロックの手順 9。Git と同じく、Git Bash には bash の構文で貼る）を分けた
  - [yazi](#yazi)の手順 9 の `y` も TUI を開くので、[yazi](#yazi)の手順 9 の最後で閉じてから PowerShell に戻る

**参照**

- 検証記録（`docs/verification/windows-setup.md`）

</details>

---

## 更新

- OS の更新は[Windows Update の公式の案内](https://support.microsoft.com/en-us/windows/install-windows-updates-3c5ae7fc-9fb6-9af1-1984-b5e0412c556a)に従う。Microsoft Store のアプリの更新を済ませ、必要なら再起動する
- scoop・winget で入れたアプリは、入れた方法で上げる
  - zoxide は 0.9.9 に固定中。[scoop・winget・WSL を上げる](#scoopwingetwsl-を上げる)の手順 6 で修正版を確かめ、同じ項の手順 7 で上げる
- Firefox は、自分で新しい版に上がる。待たずに上げるときだけ、その手順を行う
- WezTerm は自分では更新しない
  - [Git for Windows・Firefox・WezTerm を上げる](#git-for-windowsfirefoxwezterm-を上げる)の手順 5・6 で、設定を残して `C:\Program Files\WezTerm` に上書きする
- フォントは[シェルと端末のセットアップの「HackGen Console NF を上げる」](shell-terminal.md#hackgen-console-nf-を上げる)に従い、その文書の版と sha256 を確かめて直してから入れ直す
- 共通の bash 設定は、[シェルと端末のセットアップの「Windows 11 で共通の bash 設定を更新する」](shell-terminal.md#windows-11-で共通の-bash-設定を更新する)を通して上げる
- PowerShell の開発の設定は、[シェルと端末のセットアップの「PowerShell の開発の設定を更新する」](shell-terminal.md#powershell-の開発の設定を更新する)で上げる。scoop で gh・rg・fd・delta・bat・starship を上げた後は、同じ項で補完の控えを作り直す
- 自分用の設定のうち、WezTerm・Neovim はそれぞれのリポジトリの更新で上げ、lazygit・yazi は[lazygit の設定を更新する](#lazygit-の設定を更新する)・[yazi の設定を更新する](#yazi-の設定を更新する)で合わせる
  - yazi の [README の「上流の新しい版に追従する」](https://github.com/ryo-aoki-pc/yazi#上流の新しい版に追従する)は、持ち主が 1 台で行う作業。ほかの PC の clone は[yazi の設定を更新する](#yazi-の設定を更新する)で合わせる
- excel-diff・mdtable・md-format・md-preview は、それぞれのリポジトリの導入の項（[Windows 11 で excel-diff を導入・更新する](https://github.com/ryo-aoki-pc/excel-diff/blob/main/docs/install.md#windows-11-で-excel-diff-を導入更新する)・[Windows 11 で mdtable を導入・更新する](https://github.com/ryo-aoki-pc/md-tools/blob/main/mdtable/docs/install.md#windows-11-で-mdtable-を導入更新する)・[Windows 11 で md-format を導入・更新する](https://github.com/ryo-aoki-pc/md-format/blob/main/docs/install.md#windows-11-で-md-format-を導入更新する)・[Windows 11 で md-preview を導入・更新する](https://github.com/ryo-aoki-pc/md-tools/blob/main/docs/install.md#windows-11-で-md-preview-を導入更新する)）の更新の箇条書きで上げる
- md-table-sticky は、[md-table-sticky のブックマークレットを登録する](https://github.com/ryo-aoki-pc/md-tools/blob/main/sticky/docs/install.md#md-table-sticky-のブックマークレットを登録する)で、お気に入りを作り直す
- UniGet UI の画面からも、scoop と winget のパッケージをまとめて上げられる（UniGet UI と PowerToys は、自分でも新しい版を確かめる）
- VirtualBox は[仮想マシンのセットアップの「VirtualBox: Windows 11 の更新」](virtual-machines.md#virtualbox-windows-11-の更新)
  - [SSH クライアント（Windows）](#windows-の-openssh-クライアント-更新)は「更新」、[Samba の共有のネットワーク ドライブ](samba.md#samba-クライアント-windows-11-の更新)は Samba のセットアップの「Samba クライアント: Windows 11 の更新」（どちらも、上げるものは無い）

### scoop・winget・WSL を上げる

- scoop・winget のアプリと WSL・AlmaLinux 10 を上げる
- 前提: [scoop](https://scoop.sh/)・[winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/)・[Git for Windows](https://gitforwindows.org/)・[WSL](https://learn.microsoft.com/en-us/windows/wsl/install)・[WSL の AlmaLinux 10](https://wiki.almalinux.org/documentation/wsl.html)を導入してある。zoxide を上げるときは、[シェルのツールを入れる](shell-terminal.md#シェルのツールを入れる)と[Git Bash と WezTerm の設定](shell-terminal.md#git-bash-と-wezterm-の設定)を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。zoxide のリリースはブラウザ、上げた後の確認は WezTerm の Git Bash のタブ

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. scoop とバケットを上げ、古くなったものを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop update
   scoop status
   ```

   - `scoop update` は `Scoop was updated successfully!` を出す
   - git が無いと `Scoop uses Git to update itself. Run 'scoop install git' and try again.` で止まる。先に [Git for Windows](https://gitforwindows.org/)で Git for Windows を入れる
   - `scoop status` は、古いものがあれば名前と版を並べる。`Everything is ok!` なら、この項の手順 3 は飛ばす

1. 古いものがあるときだけ、scoop で入れたものを上げる。

   ```powershell
   scoop update *
   ```

   - アプリごとに `was installed successfully!` が出ればよい
   - 動いているアプリは `Running process detected, skip updating.` で飛ばされる。閉じてから貼り直す
   - **Neovim の設定やプラグインは更新に追従しない**ので、メジャー更新の後は `:checkhealth` で壊れていないか見る（自分用の設定のプラグインと外部コマンドは、[LazyVim の更新](neovim.md#windows-11-で-lazyvim-の本体外部コマンドプラグインを更新する)の全項）

1. winget で入れたものを上げる。

   ```powershell
   foreach ($id in 'Devolutions.UniGetUI', 'Microsoft.PowerToys', 'Microsoft.PowerShell', 'WinMerge.WinMerge') { winget upgrade --exact --id $id --source winget --accept-source-agreements --accept-package-agreements }
   ```

   - それぞれ、新しい版が無ければ更新が見つからない旨の行を出して何もしない
   - 動いている UniGet UI・PowerToys は、インストーラが閉じる
   - 入れていないものは、入っていない旨の行を出すだけ

1. WSL と AlmaLinux 10 を上げる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # WSL を更新する
   wsl.exe --update
   # AlmaLinux 10 のパッケージを更新する
   wsl.exe --distribution AlmaLinux-10 --user root -- dnf -y upgrade
   ```

   - `wsl.exe --update` は、新しい版が無ければ、最新である旨を出す
   - `dnf -y upgrade` の最後に `Complete!` か `Nothing to do.` が出ればよい

1. zoxide を上げるときは、ブラウザで、Git Bash の記録を直した版が出たかを確かめる。

   - `https://github.com/ajeetdsouza/zoxide/releases` を開く
   - 0.10.0 より新しい版の変更点に、「Bash/Zsh: fix `z` failing on Cygwin/MSYS2」で始まる行があれば、直った版が出ている
   - 無ければ、この項の手順 7 は飛ばす（0.9.9 のまま使う）
   - **次の手順は、管理者ではない Windows PowerShell（5.1）に貼る**

1. Git Bash の記録を直した版が出ているときだけ、zoxide を止めるのをやめて上げる。

   ```powershell
   & {
     # バケットを更新して zoxide の版を取得する
     scoop update
     $v = (Get-Content -LiteralPath "$env:USERPROFILE\scoop\buckets\main\bucket\zoxide.json" -Raw | ConvertFrom-Json).version
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     # zoxide の版を確認する
     if ($v -notmatch '^\d+\.\d+\.\d+$' -or [version]$v -le [version]'0.10.0') { Write-Error "中断: scoop の main のバケットの zoxide はまだ $v。日を置いて、この項の手順 6 から"; return }
     # zoxide の固定を解除して更新する
     scoop unhold zoxide
     scoop update zoxide --force
     zoxide --version
   }
   ```

   - `zoxide is no longer held and can be updated again.` と、`'zoxide' (<版>) was installed successfully!` が出て、最後に新しい版が出ればよい
   - `中断:` が出たら、Releases に出た版が、まだ scoop の main のバケットに入っていない。zoxide は何も変えていない（0.9.9 に止めたまま）
   - `Running process detected, skip updating.` が出たら、上がっていない。Git Bash で開いている `zi` の一覧などを閉じてから、このブロックを貼り直す
   - WezTerm の新しいタブで、[シェルと端末のセットアップの「シェルのツール」](shell-terminal.md#シェルのツール)の手順 9・10 を貼って確かめ直す（Windows との違いは、同じ文書の[「シェルのツールを入れる」](shell-terminal.md#シェルのツールを入れる)の手順 7 の箇条書き）

<details id="scoopwingetwsl-を上げる-の補足と注意点">
  <summary>scoop・winget・WSL を上げる の補足と注意点</summary>

**[scoop・winget・WSL を上げる](#scoopwingetwsl-を上げる)のリード**

- 上げても、git の設定（`~/.gitconfig`）と gh のログイン（資格情報マネージャーと `%APPDATA%\GitHub CLI`）は変わらない

**[scoop・winget・WSL を上げる](#scoopwingetwsl-を上げる)の手順 1: 5.1 にする理由**

- [scoop・winget・WSL を上げる](#scoopwingetwsl-を上げる)の手順 4 の更新の対象に PowerShell 7 自身（`Microsoft.PowerShell`）があるので、更新される 7 の窓からは動かさない

**[scoop・winget・WSL を上げる](#scoopwingetwsl-を上げる)の手順 3**

- アプリごとに `'<名前>' (<版>) was installed successfully!` の形で出る

**[scoop・winget・WSL を上げる](#scoopwingetwsl-を上げる)の手順 5: wsl.exe --update**

- `wsl.exe --update` は WSL のパッケージ（とカーネル）を上げる

**[scoop・winget・WSL を上げる](#scoopwingetwsl-を上げる)の手順 7: zoxide を上げた後の更新**

- これより後は、[scoop・winget・WSL を上げる](#scoopwingetwsl-を上げる)の手順 2・3 で、ほかのツールと一緒に上がる

**参照**

- 検証記録（`docs/verification/windows-setup.md`）

</details>

---

### Git for Windows・Firefox・WezTerm を上げる

- Git for Windows・Firefox・WezTerm を、設定を残して上げる
- 前提: [Git for Windows](https://gitforwindows.org/)を導入し、[Firefox](https://www.firefox.com/ja/)の日本語版を PC 全体の `C:\Program Files\Mozilla Firefox` に入れてある。[WezTerm](shell-terminal.md#windows-11-で-wezterm-を入れる)・[Git Bash と WezTerm の設定](shell-terminal.md#git-bash-と-wezterm-の設定)を通してある
- 実行場所: この PC のデスクトップの管理者の PowerShell 7。この項の手順 1 で開く。Git の設定の確認は、WezTerm の新しい Git Bash のタブ

1. 管理者の PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、右クリックして「管理者として実行」を選ぶ（「Windows PowerShell」ではない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる
   - UAC の確認で「はい」を押す

1. Git Bash と WezTerm を閉じてから、winget で Git for Windows を上げる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget upgrade --exact --id Git.Git --source winget --accept-source-agreements --accept-package-agreements
   winget list --exact --id Git.Git --source winget
   ```

   - 上がったら `インストールが完了しました` と出て、`winget list` の `Git.Git` の版が新しくなる
   - 新しい版が無ければ、`利用可能なアップグレードが見つかりませんでした。`（英語の Windows では `No available upgrade found.`）と出る
   - 上げた後は、WezTerm の新しい Git Bash のタブを開き、[AlmaLinux 10 の初期設定の「Git」](almalinux-setup.md#git)の手順 6 を貼り直す（`pull.ff` が `only` なら同じ項の手順 7 も）

1. Firefox の今の版と、winget に新しい版があるかを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-Item -LiteralPath "$env:ProgramFiles\Mozilla Firefox\firefox.exe").VersionInfo.ProductVersion
   winget list --exact --id Mozilla.Firefox.ja --source winget --upgrade-available
   ```

   - 1 行目が今の版
   - winget に新しい版があれば、`Mozilla.Firefox.ja` の行に今の版と新しい版が並ぶ
   - 行が出ずに、見つからない旨が出たら、新しい版は無い。この項の手順 4 は飛ばす

1. Firefox の新しい版があるときだけ、Firefox をすべて閉じてから winget で上げる。

   ```powershell
   # Firefox を更新する
   winget upgrade --exact --id Mozilla.Firefox.ja --source winget --accept-source-agreements --accept-package-agreements
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-Item -LiteralPath "$env:ProgramFiles\Mozilla Firefox\firefox.exe").VersionInfo.ProductVersion
   ```

   - 最後の行が新しい版になればよい

1. WezTerm の今の版を確かめ、WezTerm が動いていないことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # WezTerm の版を確認する
   (Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{BCF6F0DA-5B9A-408D-8562-F680AE6E1EAF}_is1').DisplayVersion
   # WezTerm の実行中のプロセスを確認する
   Get-Process -Name wezterm, wezterm-gui, wezterm-mux-server -ErrorAction SilentlyContinue | Format-Table Id, ProcessName
   ```

   - 1 行目に今の版が出る
   - プロセスが出たら、その WezTerm の窓をすべて閉じる

1. [WezTerm](shell-terminal.md#windows-11-で-wezterm-を入れる)の手順 4 のブロックを貼る。

   - 最後に出る `wezterm <版>` が、この項の手順 5 の版より新しければ上がった
   - 同じ版なら、main に新しいコミットが無かった（同じ版を入れ直しただけ）

<details id="git-for-windowsfirefoxwezterm-を上げる-の補足と注意点">
  <summary>Git for Windows・Firefox・WezTerm を上げる の補足と注意点</summary>

**注意点**

- **Git: Git for Windows を上げるときは、Git の bash を使うものを閉じる**
  - Git Bash の窓、WezTerm のタブ（自分用の設定では Git Bash）など（この折りたたみの「Git for Windows・Firefox・WezTerm を上げるの手順 2: Git を上げるときに閉じる理由」）

- **Firefox: Firefox を開いたまま `winget upgrade` しない**: 入れ替えが途中で終わることがある（[Git for Windows・Firefox・WezTerm を上げる](#git-for-windowsfirefoxwezterm-を上げる)の手順 4 の補足）

**[Git for Windows・Firefox・WezTerm を上げる](#git-for-windowsfirefoxwezterm-を上げる)のリード**

- WezTerm は自分では更新しない。nightly の新しい版が出ても知らせない（WezTerm の更新の確認が見るのは stable のリリースだけで、nightly の版の方が新しいので何も出ない）

- nightly は毎日ビルドし直される。版は main の最後のコミットで決まり、コミットの無い日は同じ版になる

**[Git for Windows・Firefox・WezTerm を上げる](#git-for-windowsfirefoxwezterm-を上げる)の手順 2: Git を上げるときに閉じる理由**

- Git の bash を使うものが動いていると、winget で上げてもインストーラが入れ替えずに終わるはず

**[Git for Windows・Firefox・WezTerm を上げる](#git-for-windowsfirefoxwezterm-を上げる)の手順 3: 新しい版が無いとき**

- winget に新しい版が無いのは、Firefox が自分で先に上げているからのこともある

**[Git for Windows・Firefox・WezTerm を上げる](#git-for-windowsfirefoxwezterm-を上げる)の手順 4: winget での更新**

この方針の検証記録（`docs/verification/windows-setup.md` の「Firefox: Windows 11 の更新 / 手順 2: 補足: winget での更新」）

- winget の定義の `UpgradeBehavior` は `install`。今の Firefox を消さずに、同じ場所へ新しい版のインストーラを重ねて入れる。プロファイルと既定のブラウザーの設定はそのまま
- winget が渡す `/PreventRebootRequired=true` は、使用中のファイルがあっても再起動が要る処理をしないスイッチ。Mozilla の文書は、動いている Firefox に重ねて入れるときにこれを付けると、入れ替えが途中で終わることがあると書いている
- winget の定義は、Mozilla が新しい版を出してから、winget-pkgs に定義が足されたときに上がる。Firefox 自身の更新の方が先に上がることもある

**参照**

- 検証記録（`docs/verification/windows-setup.md`）

</details>

---
