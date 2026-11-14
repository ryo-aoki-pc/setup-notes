# Windows 11 のセットアップ

- 補足・注意点と検証記録は、冒頭と用途末尾の「補足と注意点」から開く

> [!IMPORTANT]
> - **この PC のデスクトップで、Administrators のユーザーが行う**。別の PC や SSH・RDP で行う操作は、各項の実行場所に従う
> - PowerShell のブロックは **PowerShell 7** に貼る（[公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)）。複数行は、貼った全体が 1 つの入力になり、Enter で実行する設定の窓に貼る。Windows PowerShell 5.1 に貼る項は、その項のリードに書く。管理者・通常の窓は、各項のリードに従う
> - conhost の窓で複数行を右クリックで貼るときは、使う版の PSReadLine の Ctrl+Enter が `AddLine` に割り当てられ、貼った行が順番どおりに 1 つの入力になることを前提にする。未設定の窓では Ctrl+V で貼る

- 新しく入れた PC では、カテゴリを上から順に、要る項を選んで通す
- どの項も単独で通せる。リードの前提を先に満たす
- bash のブロックは、ブラケットペーストの効く端末（GNOME の端末・WezTerm・SSH の先）に貼り、貼った後に Enter を押す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- GitHub のコピーボタンでコピーしたブロックは末尾に改行が無いので、貼った後に Enter を押す
- 設定を更新するときは[更新](#更新)を使う
- 仮想マシン（Hyper-V・VirtualBox・VMware Workstation Pro・Windows Sandbox）は、[仮想マシンのセットアップの「Windows 11 で使う」](virtual-machines.md#windows-11-で使う)で作って使う
- フォント・共通の bash 設定・WezTerm の設定・PowerShell の開発の設定の更新は、[シェルと端末のセットアップの「Windows 11 で使う」](shell-terminal.md#windows-11-で使う)を参照する
- Neovim の設定とプラグインの更新は、[Neovim のセットアップの「Windows 11 で使う」](neovim.md#windows-11-で使う)を参照する。Samba のクライアントは、[Samba のセットアップの「Windows 11 で使う」](samba.md#windows-11-で使う)で入れる

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

- アプリと Windows のホットキーの競合を調べる

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

## Git と開発の道具

- lazygit・yazi の自分用の設定の更新と、yazi の使い方。Neovim（LazyVim）の設定とプラグインの更新は、[Neovim のセットアップの「Windows 11 で使う」](neovim.md#windows-11-で使う)を参照する
- excel-diff・mdtable・md-format（mdfmt）・md-preview（mdpreview）・md-table-sticky は、それぞれのリポジトリの手順（[excel-diff](https://github.com/ryo-aoki-pc/excel-diff/blob/main/docs/install.md#windows-11-で-excel-diff-を導入更新する)・[mdtable](https://github.com/ryo-aoki-pc/md-tools/blob/main/mdtable/docs/install.md#windows-11-で-mdtable-を導入更新する)・[md-format](https://github.com/ryo-aoki-pc/md-format/blob/main/docs/install.md#windows-11-で-md-format-を導入更新する)・[md-preview](https://github.com/ryo-aoki-pc/md-tools/blob/main/docs/install.md#windows-11-で-md-preview-を導入更新する)・[md-table-sticky](https://github.com/ryo-aoki-pc/md-tools/blob/main/sticky/docs/install.md#md-table-sticky-のブックマークレットを登録する)）で入れる。使い方は、各リポジトリの `docs/usage.md` にある

### lazygit の設定を更新する

- 自分用の lazygit の設定の clone を GitHub の `custom` に合わせる。持ち主が上流の新しい版に合わせて `custom` を載せ替えた（force push した）後も、この項で合わせる
- 前提: lazygit と自分用の設定が入り、`%LOCALAPPDATA%\lazygit` が `custom` ブランチの clone になっている
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

<details id="lazygit-の設定を更新する-の補足と注意点">
  <summary>lazygit の設定を更新する の補足と注意点</summary>

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

**参照**

- 検証記録（`docs/verification/windows-setup.md`）

</details>

---

### yazi で複数ファイルをまとめて開く

- yazi で選択した複数ファイルを、`l` / Enter でまとめて開く
- 前提: yazi・Neovim と自分用の設定が入り、smart-enter の `open_multi` が `true` になっている
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く。手順 2 は yazi の画面

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. yazi を起動し、複数ファイルを選んでまとめて開く。

   ```powershell
   yazi
   ```

   - Space で複数ファイルを選び、`l` / Enter でまとめて開く
   - `q` で yazi を閉じる
   - **ほかのブロックは、yazi を閉じてから貼る**（yazi を開いたまま貼ると、yazi への入力になる）

<details id="yazi-で複数ファイルをまとめて開く-の補足と注意点">
  <summary>yazi で複数ファイルをまとめて開く の補足と注意点</summary>

**注意点**

- `l` / Enter で選択したファイルをまとめて開くには、smart-enter の `open_multi` が有効な設定を使う

**参照**

- 検証記録（`docs/verification/windows-setup.md`）

</details>

---

### yazi の設定を更新する

- 自分用の yazi の設定の clone を GitHub の `custom` に合わせる。持ち主が上流の新しい版に合わせて `custom` を載せ替えた（force push した）後も、この項で合わせる
- 前提: yazi と自分用の設定が入り、`%APPDATA%\yazi\config` が `custom` ブランチの clone になっている
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
   - 複数ファイルをまとめて開く設定を含め、要る変更をエディタで書き直す。新しい設定に同じ内容が既にあれば、足さない
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

<details id="yazi-の設定を更新する-の補足と注意点">
  <summary>yazi の設定を更新する の補足と注意点</summary>

**[yazi の設定を更新する](#yazi-の設定を更新する)の手順 3**

- 手元の変更を退避して戻したときは、`Created autostash:`・`Applied autostash.` が出る

**[yazi の設定を更新する](#yazi-の設定を更新する)の手順 3: force push と分岐点**

- `--ff-only` を使わない理由、fork point と reflog、pull による上流のタグの取得は、[yazi の補足と注意点](almalinux-setup.md#yazi-の補足と注意点)の「yazi の設定を更新するの手順 2: force push と分岐点」を参照する

**[yazi の設定を更新する](#yazi-の設定を更新する)の手順 4: 分岐点が分からないときの載せ直し**

- rebase が止まる条件と、`--onto origin/custom HEAD` でこの clone だけのコミットを載せない理由は、[yazi の補足と注意点](almalinux-setup.md#yazi-の補足と注意点)の「yazi の設定を更新するの手順 3: 分岐点が分からないときの載せ直し」を参照する

**[yazi の設定を更新する](#yazi-の設定を更新する)の手順 5: autostash の衝突と reset の範囲**

- reset の範囲は、[yazi の補足と注意点](almalinux-setup.md#yazi-の補足と注意点)の「yazi の設定を更新するの手順 4: autostash の衝突と reset の範囲」を参照する
- Windows の git 2.55.0.windows.5 の文言は、[lazygit の補足と注意点](#lazygit-の設定を更新する-の補足と注意点)の「lazygit の設定を更新するの手順 5: autostash の衝突と reset の範囲」と同じ

**[yazi の設定を更新する](#yazi-の設定を更新する)の手順 6**

- 比べる表示の例は、`upstream/v26.9.1` と `Version: 26.9.1`

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
- フォントは[シェルと端末のセットアップの「HackGen Console NF を上げる」](shell-terminal.md#hackgen-console-nf-を上げる)に従い、更新する版と sha256 を確かめてから入れ直す
- 共通の bash 設定は、[シェルと端末のセットアップの「Windows 11 で共通の bash 設定を更新する」](shell-terminal.md#windows-11-で共通の-bash-設定を更新する)を通して上げる
- PowerShell の開発の設定は、[シェルと端末のセットアップの「PowerShell の開発の設定を更新する」](shell-terminal.md#powershell-の開発の設定を更新する)で上げる。scoop で gh・rg・fd・delta・bat・starship を上げた後は、同じ項で補完の控えを作り直す
- 自分用の設定のうち、WezTerm・Neovim はそれぞれのリポジトリの更新で上げ、lazygit・yazi は[lazygit の設定を更新する](#lazygit-の設定を更新する)・[yazi の設定を更新する](#yazi-の設定を更新する)で合わせる
  - yazi の [README の「上流の新しい版に追従する」](https://github.com/ryo-aoki-pc/yazi#上流の新しい版に追従する)は、持ち主が 1 台で行う作業。ほかの PC の clone は[yazi の設定を更新する](#yazi-の設定を更新する)で合わせる
- excel-diff・mdtable・md-format・md-preview は、それぞれのリポジトリの導入の項（[Windows 11 で excel-diff を導入・更新する](https://github.com/ryo-aoki-pc/excel-diff/blob/main/docs/install.md#windows-11-で-excel-diff-を導入更新する)・[Windows 11 で mdtable を導入・更新する](https://github.com/ryo-aoki-pc/md-tools/blob/main/mdtable/docs/install.md#windows-11-で-mdtable-を導入更新する)・[Windows 11 で md-format を導入・更新する](https://github.com/ryo-aoki-pc/md-format/blob/main/docs/install.md#windows-11-で-md-format-を導入更新する)・[Windows 11 で md-preview を導入・更新する](https://github.com/ryo-aoki-pc/md-tools/blob/main/docs/install.md#windows-11-で-md-preview-を導入更新する)）の更新の箇条書きで上げる
- md-table-sticky は、[md-table-sticky のブックマークレットを登録する](https://github.com/ryo-aoki-pc/md-tools/blob/main/sticky/docs/install.md#md-table-sticky-のブックマークレットを登録する)で、お気に入りを作り直す
- UniGet UI の画面からも、scoop と winget のパッケージをまとめて上げられる（UniGet UI と PowerToys は、自分でも新しい版を確かめる）
- VirtualBox は[仮想マシンのセットアップの「VirtualBox: Windows 11 の更新」](virtual-machines.md#virtualbox-windows-11-の更新)
  - [SSH クライアント（Windows）](#windows-の-openssh-クライアント-更新)は「更新」、[Samba の共有のネットワーク ドライブ](samba.md#samba-クライアント-windows-11-の更新)は Samba のセットアップの「Samba クライアント: Windows 11 の更新」（どちらも、上げるものは無い）

### Windows の OpenSSH クライアント: 更新

- 更新後や config の変更後に、Windows と Git の ssh の版と設定を確かめる
- 前提: Windows の OpenSSH クライアントと Git for Windows が入り、`%USERPROFILE%\.ssh\config` に接続先の別名（`Host`）が設定されている
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

   - `%USERPROFILE%\.ssh\config` に設定した接続先の `Host` と同じ値を入れる
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
   - `Bad configuration option` が出たら、片方の ssh が知らない設定が config にある（[Windows の OpenSSH クライアント: 更新 の補足と注意点](#windows-の-openssh-クライアント-更新-の補足と注意点)の「注意点」）

<details id="windows-の-openssh-クライアント-更新-の補足と注意点">
  <summary>Windows の OpenSSH クライアント: 更新 の補足と注意点</summary>

**注意点**

- **2 つの ssh が、同じ `%USERPROFILE%\.ssh` を使う**: Windows の ssh（PowerShell・WezTerm の起動メニュー）と Git の ssh（Git Bash・git）は、鍵・config・known_hosts を共有する
  - WSL の AlmaLinux 10 の ssh は、WSL のホームの `~/.ssh` を使う（別のもの）。WSL から入るなら、WSL の中で鍵を作る
- **config を BOM 付きや UTF-16 で保存しない**: Windows PowerShell 5.1 の `-Encoding UTF8`・`>`・`>>`・`Out-File` は、BOM 付きの UTF-8 か UTF-16 で書く
  - Windows の ssh は UTF-8 の BOM を読み飛ばすが、Git の ssh は `Bad configuration option` で止まり、ssh を使う git（GitHub への push など）も失敗する。UTF-16 は両方が読めない
  - メモ帳で書くなら、文字コードを「UTF-8」（BOM なし）にする
- **config には、両方の ssh が知っている設定だけを書く**: Windows の ssh（9.5p2）が知らない新しい設定を書くと、Windows の ssh が止まる。書いた後は、[Windows の OpenSSH クライアント: 更新](#windows-の-openssh-クライアント-更新)の手順 3 で両方を確かめる
- **ssh の設定は、最初に見つけた値が効く**: config の前の方の `Host *` などにある `User`・`IdentityFile` は、接続先ごとの設定より先に効く
- **Git の `usr\bin` が `PATH` の先にある PC**: PowerShell と WezTerm の起動メニューの `ssh` が、Git のものになる。この手順書のブロックは、どちらもフルパスで呼ぶ

**[Windows の OpenSSH クライアント: 更新](#windows-の-openssh-クライアント-更新)の手順 2**

- 最後に値を読み戻して確かめる

**参照**

- [OpenSSH for Windows の公式の導入案内](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse)
- [OpenSSH の鍵管理の公式の案内](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement)
- `man ssh_config`（`Host`、`-G`）
- 検証記録（`docs/verification/windows-ssh-client.md`）

</details>

---

### scoop・winget・WSL を上げる

- scoop・winget のアプリと WSL・AlmaLinux 10 を上げる
- 前提: [scoop](https://scoop.sh/)・[winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/)・[Git for Windows](https://gitforwindows.org/)・[WSL](https://learn.microsoft.com/en-us/windows/wsl/install)・[WSL の AlmaLinux 10](https://wiki.almalinux.org/documentation/wsl.html)を導入してある。zoxide を上げるときは、共通の bash 設定が入り、WezTerm の Git Bash で zoxide 0.9.9 が使える
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
   - WezTerm の新しい Git Bash のタブで、`z` が使え、移動先を `zoxide query -l` で確認できることを確かめる

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
- 前提: [Git for Windows](https://gitforwindows.org/)を導入し、[Firefox](https://www.firefox.com/ja/)の日本語版を PC 全体の `C:\Program Files\Mozilla Firefox` に入れてある。[WezTerm nightly](https://wezterm.org/install/windows.html) が入り、共通の bash 設定と自分用の WezTerm の設定が使える。Visual C++ ランタイムの x64 版も[公式の案内](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist)に従って入れてある
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
   - 上げた後は、WezTerm の新しい Git Bash のタブで `git config --show-scope --get pull.ff` を確かめる。`only` なら、`git config --global pull.ff true` で上書きして確かめ直す

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

1. nightly のインストーラを取り、sha256 を確かめて、黙って更新する。

   ```powershell
   & {
     # 導入先と取得先を設定し、実行条件を確かめる
     $dir = 'C:\Program Files\WezTerm'
     $curl = "$env:WINDIR\System32\curl.exe"
     $url = 'https://github.com/wezterm/wezterm/releases/download/nightly/WezTerm-nightly-setup.exe'
     $tmp = "$env:TEMP\wezterm-setup"
     $setup = "$tmp\WezTerm-nightly-setup.exe"
     $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     if (-not $admin) { Write-Error '中断: 管理者の PowerShell ではない'; return }
     if (-not (Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll")) { Write-Error '中断: VCRUNTIME140.dll が無い（公式の再頒布可能パッケージを先に入れる）'; return }
     if (Get-Process -Name wezterm, wezterm-gui, wezterm-mux-server -ErrorAction SilentlyContinue) { Write-Error '中断: WezTerm が動いている（窓をすべて閉じる）'; return }
     # 配布物を取得し、ハッシュ値を照合する
     Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
     New-Item -ItemType Directory -Path $tmp | Out-Null
     & $curl -fsSL -o "$setup.sha256" "$url.sha256"
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: WezTerm-nightly-setup.exe.sha256 を取れない'; return }
     & $curl -fsSL -o $setup $url
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: WezTerm-nightly-setup.exe を取れない'; return }
     $m = Select-String -LiteralPath "$setup.sha256" -Pattern '^([0-9a-f]{64})  WezTerm-nightly-setup\.exe$' | Select-Object -First 1
     if (-not $m) { Write-Error '中断: WezTerm-nightly-setup.exe.sha256 に sha256 の行が無い'; return }
     if ((Get-FileHash -LiteralPath $setup -Algorithm SHA256).Hash -ne $m.Matches[0].Groups[1].Value) { Write-Error '中断: WezTerm-nightly-setup.exe の sha256 が一致しない'; return }
     # WezTerm を更新し、一時ファイルを削除する
     $p = Start-Process -FilePath $setup -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCLOSEAPPLICATIONS /LOG=`"$tmp\setup.log`"" -Wait -PassThru
     if ($p.ExitCode -ne 0) { Write-Error "中断: インストーラが終了コード $($p.ExitCode) で終わった（ログは $tmp\setup.log）"; return }
     Remove-Item -LiteralPath $tmp -Recurse -Force
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'WezTerm-nightly-setup.exe: sha256 一致、インストーラの終了コード 0'
     & "$dir\wezterm.exe" --version
   }
   ```

   - `sha256 一致、インストーラの終了コード 0` と、wezterm の版が出ればよい
   - `中断:` が出たら止まる。nightly の入れ替わり中で取得や照合に失敗したときは、少し待って貼り直す
   - 最後に出る `wezterm <版>` が、この項の手順 5 の版より新しければ上がった。同じ版なら新しいコミットは無かった

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
