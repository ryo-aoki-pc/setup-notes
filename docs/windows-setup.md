# Windows 11 のセットアップ

- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-setup.md)・[参考資料](reference/windows-setup.md)・[ロールバックと注意点](extra/windows-setup.md)

> [!IMPORTANT]
> - **この PC のデスクトップで、Administrators のユーザーが行う**。別の PC や SSH・RDP で行う操作は、各項の実行場所に従う
> - PowerShell のブロックは **Windows PowerShell 5.1** に貼る。管理者・通常（管理者ではない）の窓は、各項の窓を開く手順に従う
> - [貼り付けの設定](#貼り付けの設定)より前は **Ctrl+V で貼る**。設定後は GitHub のコピーボタンでコピーし、右クリックで貼れる

- 新しく入れた PC では、カテゴリを上から順に、要る項を選んで通す
- どの項も単独で通せる。リードの前提を先に満たす
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- GitHub のコピーボタンでコピーしたブロックは末尾に改行が無いので、貼った後に Enter を押す
- 設定を更新するときは[更新](#更新)、戻すときは[ロールバック](extra/windows-setup.md#ロールバック)を使う
- AI コーディングエージェント（Claude Code・Codex CLI・Grok Build）は、[AI コーディングエージェントのセットアップの「Windows 11 で使う」](ai-agents.md#windows-11-で使う)で入れる
- 仮想マシン（Hyper-V・VirtualBox・VMware Workstation Pro・Windows Sandbox）は、[仮想マシンのセットアップの「Windows 11 で使う」](virtual-machines.md#windows-11-で使う)で入れる

> [!WARNING]
> - ロックを止め、自動サインイン・インラインの sudo を有効にすると、**PC に触れる人が管理者として操作できる**
> - Hello 以外のサインインと SSH・RDP も有効にすると、**パスワードを知る人も管理者として操作できる**（SSH は LAN から）
> - 人が触れる場所では、[PC 全体の設定](#pc-全体の設定)の手順 7 と[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 5 は行わない

## Windows の導入

- Windows 11 を新しく入れ、AlmaLinux 10 とのデュアルブートで使う

### Windows と AlmaLinux のデュアルブート

- Windows 11 を新しく入れ、AlmaLinux 10 用の未割り当て領域を残す
- 前提: Rufus で Windows 11 のインストールメディアを作成済み。カスタムの指定は次の箇条書きで確かめる
- 実行場所: この PC の画面・機器、セットアップのコマンド プロンプト、導入後の管理者の Windows PowerShell（5.1）。窓はこの項の中で開く

- **インストールメディアは、Rufus で作成済みとする**。「インストーラーをカスタムしますか?」でオンにした項目は次の 7 つ（[選択した方針](reference/windows-dual-boot.md#選択した方針)）
  - 「4GB以上のRAM、セキュアブート及びTPM 2.0の要件を削除」「オンラインアカウントの要件を削除」「ローカルアカウントを次の名前で作成:」
  - 「地域設定をこのユーザーと同じものに設定」「データ収集を無効化」「BitLocker 自動デバイス暗号化を無効化します。」「利便性向上パッチ(Microsoftの各種ソフトウェアの無効化)」
  - **「⚠サイレント⚠ ディスクの削除とインストール:」はオフにしてある**こと（オンだと、最初に見つかったディスクを確かめずに消して入れる）
  - ビルド 26200 以降の ISO で出る「Windows CA 2023署名のブートローダーを使用する」「インストール時にSkuSiPolicy.p7bを適応する」もオフのまま（既定でオフ）

- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-dual-boot.md)・[参考資料](reference/windows-dual-boot.md)・[ロールバックと注意点](extra/windows-dual-boot.md)

- この項の手順 1〜3・6〜8 は、PC の画面と機器で行う。**この項の手順 4・5 は、セットアップのコマンド プロンプトに手で 1 行ずつ打つ**（貼り付けられない）
- この項の手順 9〜13 は、入れた Windows の管理者の Windows PowerShell 5.1 に **Ctrl+V で貼る**。[貼り付けの設定](#貼り付けの設定)より前に右クリックで貼ると、行が逆順になる

- この項の手順 10・12・13 は、条件に当たるときだけ行う
- やり直すときは、この項の手順 3 から始める（ロールバックの節は無い）。この項の手順 5 のパーティションが残っていれば、この項の手順 4・5 は飛ばしてよい

- 両方の OS を入れた後、Windows から次回だけ AlmaLinux を起動したいときは、[QEFI Entry Manager を使う節](#windows-と-almalinux-のデュアルブート-次回だけ-almalinux-で起動する)へ進む

> [!CAUTION]
> **この項の手順 5 の `clean` で、選んだディスクのパーティションとデータをすべて消す（取り戻せない）。** ディスクの番号は、この項の手順 4 で大きさを見て確かめる。

1. PC の UEFI（BIOS）の設定画面で、起動の設定を確かめる。

   - 起動のモードは UEFI にする（CSM・Legacy の起動は切る）
   - Secure Boot と TPM は有効のままにする
   - Secure Boot の項目に「Microsoft 3rd Party UEFI CA」を許可する設定があれば、許可にする
   - USB からの起動を許可する
   - 設定画面の開き方（電源を入れた直後に押すキー）と項目の名前は、PC のメーカーごとに違う

1. LAN ケーブルを抜き、Wi-Fi にもつながない状態にする。

   - つなぐのは、この項の手順 7 でデスクトップが出てから

1. Rufus の USB を挿し、PC の起動メニューから UEFI で起動して、セットアップの最初の画面まで進める。

   - 起動メニューを出すキー（F12・F11・Esc など）は PC ごとに違う。USB が 2 つ出るなら、名前が「UEFI:」で始まる方を選ぶ
   - 黒い画面に `UEFI:NTFS` の文字と `Secure Boot status: Enabled` が出てから、Windows のセットアップが始まる
   - 「言語設定を選択」の画面が出たら、まだ「次へ」を押さずにこの項の手順 4 へ進む
   - Secure Boot の違反で止まるなら、この項の手順 1 の 3rd Party UEFI CA を見直す
   - やり直しのときに「アップグレードを開始し、インストール メディアから起動したようです。」の窓が出たら、「いいえ」（クリーン インストール）を押す

1. Shift+F10 でコマンド プロンプトを開き、UEFI で起動したことと、入れる先のディスクの番号を確かめる。

   ```text
   wpeutil UpdateBootInfo
   reg query HKLM\System\CurrentControlSet\Control /v PEFirmwareType
   diskpart
   list disk
   ```

   - 1 行ずつ打って Enter を押す（3 行目から `DISKPART>` のプロンプトになる）
   - コマンド プロンプトのキー配列は日本語（106/109）。`\` は画面では `¥` と表示される（同じ文字）
   - Enter の前に、打った文字が画面に正しく出ているかを見る
   - ノート PC で Shift+F10 が効かなければ、Shift+Fn+F10 を押す
   - 2 行目の結果が `PEFirmwareType    REG_DWORD    0x2` なら UEFI で起動している。`0x1` なら BIOS（Legacy）の起動なので、この項の手順 1・3 からやり直す
   - `list disk` に、ディスクの番号・大きさ・空き・GPT の印が並ぶ。**Windows を入れるディスクの番号を、大きさで見分けて控える**
   - Rufus の USB も 1 台のディスクとして並ぶ（USB メモリの大きさのもの）。選ばない

1. ディスクを消して GPT にし、ESP 2 GiB・MSR・Windows・回復のパーティションを作る（取り戻せない）。

   ```text
   select disk 0
   clean
   convert gpt
   create partition efi size=2048
   format quick fs=fat32 label="System"
   create partition msr size=16
   create partition primary size=204800
   format quick fs=ntfs label="Windows"
   create partition primary size=1024
   format quick fs=ntfs label="Recovery"
   set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"
   gpt attributes=0x8000000000000001
   list partition
   exit
   exit
   ```

   - `DISKPART>` のプロンプトに 1 行ずつ打つ。**1 行目の `0` は、この項の手順 4 で控えたディスクの番号に直す**
   - **7 行目の `204800` は Windows のパーティションの大きさ**（単位は MB。204800 = 200 GiB）。Windows に割り当てたい大きさに直す。ディスクの残りは、AlmaLinux 用の未割り当て領域になる
   - `list partition` に 4 つのパーティション（`システム` 2048 MB・`予約済み` 16 MB・`プライマリ` Windows の大きさ・`回復` 1024 MB）が並べばよい
   - 途中で打ち間違えたら、`select disk 0`（控えた番号）から打ち直す

1. セットアップに戻り、この項の手順 5 の「Windows」のパーティションを選んでインストールする。

   - 「言語設定を選択」→「キーボード設定を選択」→「セットアップ オプションの選択」→「プロダクト キーを入力してください」→「イメージの選択」→「適用される通知とライセンス条項」の順に進む
   - 「キーボード設定を選択」の「キーボードの種類」は、日本語のキーボードなら「日本語キーボード (106/109 キー)」にする
   - 「セットアップ オプションの選択」では「Windows 11 のインストール」を選び、「ファイル、アプリ、設定など、すべてが削除されることに同意します」に印を付ける
   - プロダクト キーが無ければ「プロダクト キーがありません」を押し、「イメージの選択」でエディション（Windows 11 Pro など）を選ぶ
   - **「Windows 11 をインストールする場所の選択」では、この項の手順 5 で作った Windows の大きさのパーティション（`ディスク 0 パーティション 3: Windows` のように、この項の手順 4 で控えたディスクのパーティション 3）を選び、「次へ」を押す**
   - この画面では「パーティションの削除」を押さず、「未割り当て領域」も選ばない
   - 「インストール準備完了」の画面で「インストール」を押す。途中で何度か再起動する
   - 最初の再起動のときに USB を抜く
   - **注意**: 「適用される通知とライセンス条項」の画面には「戻る」が無い。Esc を押すと「本当に終了しますか?」が出て、「はい」で PC が再起動する（この項の手順 3 からやり直す）

1. 初回の起動を待ち、Rufus で作ったローカル アカウントでデスクトップまで進む。

   - 「ネットワークに接続しましょう」の画面が出たら、「インターネットに接続していません」を押す
   - 地域・キーボード・ライセンス・プライバシー・アカウントの質問は出ない。ロック画面が出たら、キーを押すとそのままサインインする
   - デスクトップが出たら、LAN ケーブルや Wi-Fi につないでよい
   - ローカル アカウントのパスワードは空。**次にサインインするときに「サインインする前にユーザーのパスワードを変更する必要があります。」が出る**ので、「OK」を押して新しいパスワードを決める（「パスワード」の欄は空のまま）

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、右側の「管理者として実行する」を押す（Ctrl+Shift+Enter でも同じ）
   - 「ユーザー アカウント制御」で「はい」を押す。窓の名前が「管理者: Windows PowerShell」になる

1. パーティションの並び・ESP の大きさ・未割り当て領域・WinRE の場所を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   $d = (Get-Partition -DriveLetter C).DiskNumber
   Get-Partition -DiskNumber $d | Format-Table PartitionNumber, DriveLetter, Size, Type -AutoSize
   Get-Disk -Number $d | Format-List Number, PartitionStyle, Size, LargestFreeExtent
   reagentc /info
   ```

   - パーティションが `System`（`2147483648`）・`Reserved`（`16777216`）・`Basic`（C:）・`Recovery`（`1073741824`）の順に 4 つ並べばよい
   - `PartitionStyle` が `GPT` で、`LargestFreeExtent` が AlmaLinux 用に残した大きさ（バイト）になっていればよい
   - `reagentc /info` の Windows RE の状態が `Enabled` で、場所が `…\partition4\Recovery\WindowsRE`（回復パーティション）なら、この項の手順 10 は飛ばす
   - 場所が `partition3`（C:）か空なら、この項の手順 10 で回復パーティションへ移す

1. WinRE が回復パーティションに無いときだけ、回復パーティションへ移す。

   ```powershell
   reagentc /disable
   reagentc /enable
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   reagentc /info
   ```

   - 最後の `reagentc /info` で、場所が `…\partition4\Recovery\WindowsRE` になればよい

1. 高速スタートアップ・BitLocker・タイムゾーンの状態を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' | Format-List HiberbootEnabled
   Get-BitLockerVolume -MountPoint C: | Format-List VolumeStatus, ProtectionStatus
   Get-TimeZone | Format-List Id
   ```

   - `HiberbootEnabled : 0` なら高速スタートアップは切れている。`1` なら、この項の手順 12 で切る。`0` ならこの項の手順 12 は飛ばす
   - `VolumeStatus : FullyDecrypted` と `ProtectionStatus : Off` なら、BitLocker は使われていない。暗号化されていたら[注意点](extra/windows-dual-boot.md#注意点)
   - `Id : Tokyo Standard Time` なら、この項の手順 13 は飛ばす。違えば、この項の手順 13 で直す
   - Home エディションで `Get-BitLockerVolume` が無いと出たら、代わりに `manage-bde -status C:` で見る

1. 高速スタートアップが有効なときだけ、切る。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name HiberbootEnabled -Value 0 -Type DWord
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' | Format-List HiberbootEnabled
   ```

   - `HiberbootEnabled : 0` が出ればよい

1. タイムゾーンが東京でないときだけ、直す。

   ```powershell
   Set-TimeZone -Id 'Tokyo Standard Time'
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-TimeZone | Format-List Id
   ```

   - `Id : Tokyo Standard Time` が出ればよい
   - 設定アプリの「時刻と言語」→「日付と時刻」でも同じ

#### Windows と AlmaLinux のデュアルブート: 次回だけ AlmaLinux で起動する

- Windows から、次回だけ AlmaLinux で起動するように指定する
- 前提: [Windows と AlmaLinux のデュアルブート](#windows-と-almalinux-のデュアルブート)を通し、AlmaLinux 10 を導入済み。PC の起動メニューから AlmaLinux を起動できる
- 実行場所: Windows のブラウザ・エクスプローラー、管理者の Windows PowerShell（5.1）。PowerShell はこの項の手順 2 で開く

- QEFI Entry Manager と PowerShell は管理者として起動する。PowerShell のブロックは Ctrl+V で貼る

- 通常の起動順（`BootOrder`）や GRUB の既定の選択は変更しない
- 初回はこの項の手順 1 から行う。展開済みなら、この項の手順 2 で管理者の Windows PowerShell を開き、同じ項の手順 5 へ進む
- 同梱 CLI に表示の不具合があるため、Windows 標準の BCDEdit も使って確認する（この項の[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-dual-boot.md)・[参考資料](reference/windows-dual-boot.md)）
- 再起動前に取り消すときは、[次回起動の指定を取り消す](#windows-と-almalinux-のデュアルブート-次回起動の指定を取り消す)へ進む。QEFI Entry Manager を閉じるだけでは取り消せない

1. Windows のブラウザで、公式の Windows 向け ZIP をダウンロードする。

   - [公式リリース v0.5.0](https://github.com/Inokinoki/QEFIEntryManager/releases/tag/v0.5.0) の Assets から `QEFI.Entry.Manager.for.Windows.Qt6.8.3.zip` を選ぶ
   - 「ダウンロード」フォルダーに、この名前で保存する（末尾に `(1)` などが付いたら、既存のファイルと区別してからこの名前にする）

1. 管理者の Windows PowerShell（5.1）を開く。

   - [Windows と AlmaLinux のデュアルブート](#windows-と-almalinux-のデュアルブート)の手順 8と同じように、スタートメニューから「管理者として実行する」で開く
   - この窓は、GUI で指定した後の確認にも使うので残しておく
   - **次の手順は、管理者の窓が開いてから貼る**

1. ダウンロードした ZIP の SHA256 を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if ((Get-FileHash -LiteralPath "$env:USERPROFILE\Downloads\QEFI.Entry.Manager.for.Windows.Qt6.8.3.zip" -Algorithm SHA256 -ErrorAction Stop).Hash -ne 'FC2D83F1369AF02A48072644B08CA7D3D4B2547B955A2088918E7C1179051A10') {
       throw '中断: ZIP の SHA256 が確認した配布物と一致しません。展開せず、取得元とファイル名を確かめてください。'
   } else {
       'SHA256 は確認した配布物と一致しました。'
   }
   ```

   - 一致したと出れば、この項の手順 4 へ進む。エラーなら中断する
   - 「ダウンロード」を別の場所へ移している場合は、この項の手順 1 で `%USERPROFILE%\Downloads` に保存する

1. エクスプローラーで、ZIP の中身をすべて展開する。

   - ZIP を右クリックして「すべて展開」を選び、展開先を `%LOCALAPPDATA%\Programs\QEFIEntryManager` にする
   - 展開先が既にある場合は上書きせず中断する
   - 展開先の直下に `QEFIEntryManager.exe`・`qefibootmgr.exe`・`Qt6Core.dll` があり、`platforms` フォルダーもあることを確かめる
   - ZIP の中から直接起動せず、exe だけを別のフォルダーに移さない

1. 管理者の PowerShell で、現在の起動順と AlmaLinux のエントリを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & "$env:LOCALAPPDATA\Programs\QEFIEntryManager\qefibootmgr.exe" -v
   if ($LASTEXITCODE -ne 0) { throw '中断: QEFI の一覧を取得できませんでした。' }
   & "$env:SystemRoot\System32\bcdedit.exe" /enum firmware
   if ($LASTEXITCODE -ne 0) { throw '中断: BCDEdit の一覧を取得できませんでした。' }
   ```

   - CLI の `BootOrder` の並びと、AlmaLinux の `Boot` の後ろの 4 桁の番号を控える。AlmaLinux の行は `*` 付き（有効）であることを確かめる
   - BCDEdit の AlmaLinux の項目の `identifier`（識別子）と `path` を控える。名前だけでなく、CLI の EFI パスと同じブートローダーを指すことを確かめる（通常は `\EFI\almalinux\shimx64.efi`）
   - BCDEdit の `{fwbootmgr}`（ファームウェアのブート マネージャー）の `displayorder` も控える
   - `{fwbootmgr}` に `bootsequence` が既にあれば中断する
   - エラー・空の起動順・AlmaLinux が無い・無効・同名の候補を区別できない場合も中断する。番号を推測せず、エントリの追加・削除はしない
   - **次の手順は、両方の一覧と AlmaLinux の対応を確かめてから行う**

1. エクスプローラーで、QEFI Entry Manager を管理者として起動する。

   - 展開先の `QEFIEntryManager.exe` を右クリックして「管理者として実行」を選ぶ
   - UAC は、展開した実行ファイルであることを確かめてから「はい」を押す（配布物は署名無し）
   - `Boot Entries` タブに、この項の手順 5 と同じエントリが並ぶことを確かめる
   - 起動できない・一覧が出ない場合は中断する。Windows の保護を無効にして進めない

1. GUI で AlmaLinux を選び、次回の起動先に指定する。

   - この項の手順 5 で控えた番号と名前の行を選び、`Set reboot` を押す
   - `Reboot to …` の対象が AlmaLinux であることを確かめ、`Do you want to reboot now?` には `No` を選ぶ
   - **`No` は「今は再起動しない」で、予約の取り消しではない**
   - `Make default`・`Move up`・`Move down`・`Save` は使わない
   - **次の手順は、`No` を選んでから管理者の PowerShell に貼る**

1. 管理者の PowerShell で、次回の起動先と通常の起動順を読み戻す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & "$env:LOCALAPPDATA\Programs\QEFIEntryManager\qefibootmgr.exe" -v
   if ($LASTEXITCODE -ne 0) { throw '中断: QEFI の一覧を取得できませんでした。再起動しないでください。' }
   & "$env:SystemRoot\System32\bcdedit.exe" /enum firmware
   if ($LASTEXITCODE -ne 0) { throw '中断: BCDEdit の一覧を取得できませんでした。再起動しないでください。' }
   ```

   - `BootNext` が、この項の手順 5 で控えた AlmaLinux の 4 桁の番号と一致することを確かめる
   - BCDEdit の `{fwbootmgr}` に `bootsequence` があり、その識別子が AlmaLinux の項目と一致することも確かめる（`BootNext: 0000` だけでは成功とみなさない）
   - `BootOrder` と `{fwbootmgr}` の `displayorder` が、どちらもこの項の手順 5 と同じ並びであることを確かめる
   - どれかが一致しない・予約が出ない・エラーが出た場合は、再起動せず中断する。自分が設定した予約だけを[取り消す節](#windows-と-almalinux-のデュアルブート-次回起動の指定を取り消す)で解除する

1. Windows で作業を保存して、再起動する。

   - 未保存の作業を保存し、スタートメニューの電源から「再起動」を選ぶ
   - AlmaLinux の GRUB のメニューが出たら、AlmaLinux の項目を選ぶ

1. AlmaLinux の画面で、起動できたことを確かめる。

   - AlmaLinux のログイン画面からログインし、デスクトップが出ることを確かめる

#### Windows と AlmaLinux のデュアルブート: 次回起動の指定を取り消す

- 再起動前に、自分が指定した次回だけの起動先を取り消す
- 前提: [次回だけ AlmaLinux で起動する](#windows-と-almalinux-のデュアルブート-次回だけ-almalinux-で起動する)で予約し、まだ再起動していない。QEFI Entry Manager は同じ場所へ展開済み
- 実行場所: 管理者の Windows PowerShell（5.1）。この項の手順 1 で開く

- 解除するのは次回だけの予約。AlmaLinux のエントリ自体は消さず、通常の起動順も変えない

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、右クリック →「管理者として実行」を選ぶ
   - UAC の確認で「はい」を押す。窓の名前が「管理者: Windows PowerShell」になる

1. BCDEdit で、取り消す予約を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & "$env:SystemRoot\System32\bcdedit.exe" /enum firmware
   if ($LASTEXITCODE -ne 0) { throw '中断: BCDEdit の一覧を取得できませんでした。' }
   ```

   - `{fwbootmgr}` の `bootsequence` が自分の指定したエントリの識別子であることを確かめる。別の対象や不明な対象なら中断する
   - `{fwbootmgr}` に `bootsequence` が無ければ、この項の手順 3 は飛ばす

1. 自分が指定した予約が残っているときだけ、解除する。

   ```powershell
   & "$env:LOCALAPPDATA\Programs\QEFIEntryManager\qefibootmgr.exe" -N
   if ($LASTEXITCODE -ne 0) { throw '中断: 次回起動の指定を解除できませんでした。' }
   ```

   - オプションは大文字の `-N`。`-B`（エントリ削除）や `-O`（起動順削除）は使わない
   - `BootNext deleted` が出ても成功と決めず、この項の手順 4 で確認する

1. 予約が消え、通常の起動順が変わっていないことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & "$env:LOCALAPPDATA\Programs\QEFIEntryManager\qefibootmgr.exe" -v
   if ($LASTEXITCODE -ne 0) { throw '中断: QEFI の一覧を取得できませんでした。' }
   & "$env:SystemRoot\System32\bcdedit.exe" /enum firmware
   if ($LASTEXITCODE -ne 0) { throw '中断: BCDEdit の一覧を取得できませんでした。' }
   ```

   - BCDEdit の `{fwbootmgr}` に `bootsequence` が無く、`BootOrder` と `displayorder` が指定前の並びならよい
   - CLI の `BootNext: 0000` は、予約が消えた根拠にも、エントリ `0000` の予約が残っている根拠にもならない
   - BCDEdit に予約が残る・一覧の取得に失敗する・起動順が違う場合は、解除できたとみなさず中断する

---

## 基本の設定

- 更新・貼り付け・アプリの導入・PC 全体の設定・サインイン・WSL と、プライバシー・Edge

### Windows Update

- Windows Update の更新を検索・適用し、必要なら再起動する
- 前提: 無し
- 実行場所: 管理者の Windows PowerShell（5.1）。この項の手順 1 で開く

1. Windows のデスクトップで、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、右クリック →「管理者として実行」。UAC の確認で「はい」
   - PowerShell 7（`pwsh`）ではなく、Windows PowerShell 5.1 にする
   - この項の手順 2〜8 はこの窓に貼る

1. 管理者であることを確かめ、今の窓だけモジュールを使えるようにする。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     if ($PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -ne 1) {
       throw '中断: Windows PowerShell 5.1 で実行する'
     }
     if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
       throw '中断: この項の手順 1 で管理者の Windows PowerShell を開く'
     }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-Module -ListAvailable -Name PSWindowsUpdate | Select-Object Name, Version, ModuleBase
     if ((Get-ExecutionPolicy) -notin 'RemoteSigned', 'Unrestricted', 'Bypass') {
       Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
     }
     if ((Get-ExecutionPolicy) -notin 'RemoteSigned', 'Unrestricted', 'Bypass') {
       throw '中断: 実行ポリシーによりモジュールを読み込めない'
     }
     [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
     'この窓の実行ポリシー: {0}' -f (Get-ExecutionPolicy)
   }
   ```

   - PSWindowsUpdate の一覧が出たら、版と場所を控える。何も並ばなければ、この項の手順 3 で初めて入れる
   - 最後に `RemoteSigned`・`Unrestricted`・`Bypass` のいずれかが出ればよい
   - エラーが出たら進まない

1. PSWindowsUpdate が無ければ自分のユーザーに入れ、読み込む。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
       $gallery = Get-PSRepository -Name PSGallery
       if ($gallery.SourceLocation.TrimEnd('/') -ne 'https://www.powershellgallery.com/api/v2') {
         throw '中断: PSGallery の取得先が PowerShell Gallery ではない'
       }
       $nuget = Get-PackageProvider -ListAvailable | Where-Object { $_.Name -eq 'NuGet' -and $_.Version -ge [version]'2.8.5.201' }
       if (-not $nuget) {
         Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
       }
       Install-Module -Name PSWindowsUpdate -Repository PSGallery -Scope CurrentUser -Force
     }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Import-Module -Name PSWindowsUpdate -Global -PassThru | Select-Object Name, Version, ModuleBase
   }
   ```

   - `PSWindowsUpdate` の版と場所が出ればよい
   - この項の手順 2 で入っていなかった場合は、そのことを控える（[ロールバックの「再起動と PSWindowsUpdate」](extra/windows-setup.md#再起動と-pswindowsupdate)の手順 4 で使う）
   - ダウンロードや読み込みのエラーが出たら進まない
   - **次の手順は、モジュールの読み込みが終わってから貼る**

1. 再起動待ちでないことを確かめ、通常の Windows Update を検索する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $rebootRequired = Get-WURebootStatus -Silent
     if ($rebootRequired -isnot [bool]) { throw '中断: 再起動待ちかを確認できない' }
     if ($rebootRequired) {
       throw '中断: 再起動が必要。この項の手順 8 を行ってから検索し直す'
     }
     $updates = @(Get-WindowsUpdate -Criteria 'IsInstalled=0 and IsHidden=0 and IsAssigned=1 and BrowseOnly=0' | ForEach-Object { $_ })
     '対象の更新: {0} 件' -f $updates.Count
     $updates | Format-Table KB, Size, Title -AutoSize
   }
   ```

   - 更新の件数と一覧を確かめる
   - `対象の更新: 0 件` なら、この項の手順 5 は飛ばす（この項の手順 6・7 で最終確認する）
   - 再起動が必要と出たら、この項の手順 5〜7 は飛ばしてこの項の手順 8 へ。検索のエラーなら進まない
   - **次の手順は、検索が終わり、更新の一覧を確かめてから貼る**

1. 対象の更新があるときだけ、ダウンロードしてインストールする。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $rebootRequired = Get-WURebootStatus -Silent
     if ($rebootRequired -isnot [bool]) { throw '中断: 再起動待ちかを確認できない' }
     if ($rebootRequired) {
       throw '中断: 再起動が必要。この項の手順 8 を行ってから検索し直す'
     }
     Install-WindowsUpdate -Criteria 'IsInstalled=0 and IsHidden=0 and IsAssigned=1 and BrowseOnly=0' -AcceptAll -IgnoreReboot |
       ForEach-Object {
         $_
         if ($_.Result -notin 'Accepted', 'Downloaded', 'Installed') {
           throw "中断: 更新が成功しなかった（$($_.Result)）: $($_.Title)"
         }
       }
   }
   ```

   - `Accepted`・`Downloaded` だけではインストール完了ではない
   - `Installed` になったことを確かめる。エラーや `中断:` が出たら、理由を解決するまで次へ進まない
   - **次の手順は、インストールが終わり、プロンプトが戻ってから貼る**

1. Windows Update が再起動を必要としているか確かめる。

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $rebootRequired = Get-WURebootStatus -Silent -ErrorAction Stop
     if ($rebootRequired -isnot [bool]) { throw '中断: 再起動待ちかを確認できない' }
     $rebootRequired
   }
   ```

   - `True` なら、この項の手順 7 は飛ばしてこの項の手順 8 へ
   - `False` なら、この項の手順 7 へ。何も出ない場合やエラーの場合は、再起動不要とはみなさず進まない

1. 再起動が不要なときだけ、同じ条件で更新が残っていないか確かめる。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     $updates = @(Get-WindowsUpdate -Criteria 'IsInstalled=0 and IsHidden=0 and IsAssigned=1 and BrowseOnly=0' | ForEach-Object { $_ })
     $rebootRequired = Get-WURebootStatus -Silent
     if ($rebootRequired -isnot [bool]) { throw '中断: 再起動待ちかを確認できない' }
     if ($rebootRequired) {
       throw '中断: 再起動が必要。この項の手順 8 を行ってから検索し直す'
     }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     '残っている対象の更新: {0} 件' -f $updates.Count
     $updates | Format-Table KB, Size, Title -AutoSize
     if ($updates.Count -gt 0) {
       Write-Warning '更新が残っている。この項の手順 5 から繰り返す'
     } else {
       'Windows Update の確認完了（対象の更新なし・再起動待ちなし）'
     }
   }
   ```

   - 完了の行が出たら、この項の手順 8 は飛ばして[Microsoft Store の更新](#microsoft-store-の更新)の手順 1 へ
   - 更新が残っていたら、この項の手順 5〜7 を繰り返す。同じ更新が失敗し続ける場合は止め、エラーを調べる
   - **次の手順は、対象の更新が無くなり、再起動待ちも無くなってから行う**

1. 再起動が必要なときだけ、作業を保存して再起動する。

   ```powershell
   Restart-Computer
   ```

   - 自分で保存してから貼る。`-Force` は付けない
   - **次の手順は、起動してサインインし、この項の手順 1〜7 をもう一度通してから行う**（新しい窓ではこの項の手順 2・3 の準備と読み込みも必要）

---

### Microsoft Store の更新

- Store CLI を用意し、Microsoft Store のアプリを更新する
- 前提: 無し
- 実行場所: 管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. Windows のデスクトップで、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）
   - PowerShell 7（`pwsh`）ではなく、Windows PowerShell 5.1 にする
   - Windows Terminal の中に開いた窓に複数行のブロックを貼ると、「複数の行を含むテキストを貼り付けようとしています」の警告が出る。「強制的に貼り付け」を押す

1. 管理者ではないことと、Store CLI・winget の有無を確かめる。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     if ($PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -ne 1) {
       throw '中断: Windows PowerShell 5.1 で実行する'
     }
     if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
       throw '中断: この項の手順 1 で管理者ではない窓を開く'
     }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-AppxPackage -Name Microsoft.WindowsStore | Select-Object Name, Version
     foreach ($name in 'store.exe', 'winget.exe') {
       $command = Get-Command -Name $name -ErrorAction SilentlyContinue
       if ($command) { $command | Select-Object Name, Source } else { Write-Warning "見つからない: $name" }
     }
   }
   ```

   - `winget.exe` に場所が出れば、この項の手順 3 は飛ばす
   - `store.exe` があれば、この項の手順 4 はいったん飛ばしてこの項の手順 5 で一括更新に対応しているか確かめる
   - `store.exe` が無ければ、この項の手順 3（winget が無い場合だけ）・4 で準備する

1. winget が無いときだけ、このユーザーにアプリ インストーラーを登録する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-Command -Name winget.exe | Select-Object Name, Source
     winget.exe --version
     if ($LASTEXITCODE -ne 0) { throw "中断: winget の確認に失敗（終了コード $LASTEXITCODE）" }
   }
   ```

   - `winget.exe` の場所と版が出ればよい
   - アプリ インストーラー自体が無い場合や、登録が失敗した場合は止める

1. Store CLI が無いか一括更新に非対応のときだけ、Store 本体を更新する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($id in '9NBLGGH4NNS1', '9WZDNCRFJBMP') {
       winget.exe upgrade --exact --id $id --source msstore --include-unknown --accept-source-agreements --accept-package-agreements --disable-interactivity
       if ($LASTEXITCODE -notin 0, -1978335189) {
         throw "中断: $id の更新に失敗（終了コード $LASTEXITCODE）"
       }
     }
   }
   ```

   - 更新が無い旨の表示なら、そのアプリは何も変えない
   - 終わったらこの項の手順 5 へ。まだ CLI が使えない場合は止める
   - **次の手順は、両方の更新が終わり、プロンプトが戻ってから貼る**

1. Store CLI が一括更新に対応していることを確かめ、更新を検索する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     if (-not (Get-Command -Name store.exe -ErrorAction SilentlyContinue)) {
       throw '中断: Store CLI が無い。この項の手順 4 で準備してから再確認する'
     }
     $help = store.exe updates --help
     if ($LASTEXITCODE -ne 0 -or ($help -join "`n") -notmatch '--apply\b') {
       throw '中断: Store CLI の一括更新を確認できない。この項の手順 4 の後も同じなら進まない'
     }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     store.exe updates
     if ($LASTEXITCODE -ne 0) { throw "中断: Store の検索に失敗（終了コード $LASTEXITCODE）" }
   }
   ```

   - CLI が出す更新の一覧を確かめる。エラーが出たら進まない
   - 更新が無いと明示された場合だけ、この項の手順 6 は飛ばす
   - **次の手順は、検索が終わり、更新の一覧を確かめてから貼る**

1. Store の更新があるときだけ、すべての更新を適用する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     store.exe updates --apply
     if ($LASTEXITCODE -ne 0) { throw "中断: Store の更新に失敗（終了コード $LASTEXITCODE）" }
   }
   ```

   - エラーや適用できないアプリが出たら進まない。使用中のアプリが原因なら、作業を保存してそのアプリを閉じてから、この手順を貼り直す
   - **次の手順は、更新処理が終わり、プロンプトが戻ってから貼る**（コマンドの終了だけで更新完了とはみなさない）

1. Store の更新が残っていないかと、必要なアプリの状態を確かめる。

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $ErrorActionPreference = 'Stop'
     store.exe updates
     if ($LASTEXITCODE -ne 0) { throw "中断: Store の再検索に失敗（終了コード $LASTEXITCODE）" }
     foreach ($name in 'Microsoft.DesktopAppInstaller', 'Microsoft.WindowsTerminal') {
       $package = Get-AppxPackage -Name $name
       if (-not $package) { throw "中断: 必要なアプリが無い: $name" }
       $package | Select-Object Name, Version, Status
       if ($package.Status -ne 'Ok') { throw "中断: アプリの状態を確認する: $name" }
     }
     winget.exe --version
     if ($LASTEXITCODE -ne 0) { throw "中断: winget の確認に失敗（終了コード $LASTEXITCODE）" }
   }
   ```

   - Store CLI が更新なしを明示し、2 つのアプリの `Status` が `Ok` で、winget の版が出ることを確かめる
   - 更新が残っていたらこの項の手順 6・7 を繰り返す。進行中・失敗の表示や、結果を判定できない場合は次へ進まない
   - 更新で窓が閉じた場合は、この項の手順 1 で通常の PowerShell を開き直してからこの項の手順 5〜7 で確認する
   - **次の手順は、Store の更新がすべて終わってから貼る**

---

### 貼り付けの設定

- 複数行を元の順に貼れるように、Ctrl+Enter とプロファイルを設定する
- 前提: [Microsoft Store の更新](#microsoft-store-の更新)でアプリ インストーラーと winget を用意してある
- 実行場所: 管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）
   - 窓の名前に「管理者:」が付いていないことを確かめる

1. 今の窓だけ、Ctrl+Enter を「行を足す」にする。

   ```powershell
   Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine
   ```

   - 何も出なければよい
   - この窓を閉じるまで効く

1. 管理者ではないことと、今の状態を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   $sm = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout' -ErrorAction SilentlyContinue).'Scancode Map'
   [pscustomobject]@{
     PowerShell    = $PSVersionTable.PSVersion.ToString()
     Admin         = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Winget        = (Get-Command winget -ErrorAction SilentlyContinue).Source
     Scoop         = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git           = (Get-Command git -ErrorAction SilentlyContinue).Source
     ClassicMenu   = Test-Path -LiteralPath 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
     ScancodeMap   = if ($sm) { ($sm | ForEach-Object { '{0:X2}' -f $_ }) -join ' ' } else { '' }
     Profile       = $PROFILE
     ProfileExists = Test-Path -LiteralPath $PROFILE
   } | Format-List
   Get-ExecutionPolicy -List | Format-Table -AutoSize
   '実行ポリシー: {0}' -f (Get-ExecutionPolicy)
   ```

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`7.…` か `True` なら、窓を閉じてこの項の手順 1 から
   - `Winget` に `…\WindowsApps\winget.exe` の場所が出ればよい。空なら、[Microsoft Store の更新](#microsoft-store-の更新)の手順 2〜7 でアプリ インストーラーの登録と更新を確かめてから
   - `ScancodeMap` が空でなければ控える。[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 5 は、別の割り当てがあれば止まる
   - `CurrentUser` の値（未設定なら `Undefined`）を控え、[ロールバック](extra/windows-setup.md#アプリと貼り付けの設定を外す)の手順 7 で使う
   - `Scoop` に場所が出たら、scoop はもう入っている

1. スクリプトの実行ポリシーを RemoteSigned にする。

   ```powershell
   if ((Get-ExecutionPolicy) -notin 'RemoteSigned', 'Unrestricted', 'Bypass') { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ExecutionPolicy
   ```

   - `RemoteSigned`（もとから `Unrestricted` か `Bypass` だった PC では、その値）が出ればよい
   - 上書きのエラーが出て別の値になる PC では、scoop とこの項の手順 5 のプロファイルは使えない。ほかの手順書は Ctrl+V で貼る

1. プロファイルに、この項の手順 2 と同じ 1 行を足す。

   ```powershell
   & {
     $line = 'Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine  # windows-setup.md'
     $old = 'Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine  # windows-powershell-paste.md'
     if (-not (Test-Path -LiteralPath $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
     $text = Get-Content -LiteralPath $PROFILE -Raw
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($text -and ($text.Contains($line) -or $text.Contains($old))) { "すでにある: $PROFILE" } else {
       if ($text -and -not $text.EndsWith("`n")) { $line = "`r`n" + $line }
       Add-Content -LiteralPath $PROFILE -Value $line
       "足した: $PROFILE"
     }
     Get-Content -LiteralPath $PROFILE
   }
   ```

   - `足した:` とプロファイルのパス、足した行が出ればよい。OneDrive のバックアップ対象なら、パスは OneDrive の下
   - プロファイルにほかの行があれば、それも出る
   - 追加済みなら `すでにある:` と出て、重複しない。旧 `windows-powershell-paste.md` で足した行も含む

---

### アプリを入れる

- scoop・UniGet UI・PowerToys・PowerShell 7 を入れる
- 前提: [Microsoft Store の更新](#microsoft-store-の更新)と[貼り付けの設定](#貼り付けの設定)を通してある
- 実行場所: 管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）
   - 窓の名前に「管理者:」が付いていないことを確かめる

1. scoop を入れる。

   ```powershell
   Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
   ```

   - 最後に `Scoop was installed successfully!` が出ればよい
   - `Running the installer as administrator is disabled by default` が出たら、管理者の PowerShell に貼っている。閉じてこの項の手順 1 から
   - `Scoop is already installed` が出たら、もう入っている（何も変えずに終わる）。この項の手順 3 へ進む
   - `'C:\Users\<WIN_USER>\scoop' exists and is not empty` が出たら、前に入れた scoop の残り（`persist` など）がある。要らなければ[ロールバックの「アプリと貼り付けの設定を外す」](extra/windows-setup.md#アプリと貼り付けの設定を外す)の手順 5 で消してから貼り直す

1. scoop が入ったことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop --version
   scoop bucket list
   [Environment]::GetEnvironmentVariable('Path', 'User') -split ';' | Where-Object { $_ -like '*\scoop\shims' }
   ```

   - `Current Scoop version:` の次に版と公開日が出ればよい
   - `scoop bucket list` に `main` の行が出る
   - 最後に `C:\Users\<WIN_USER>\scoop\shims` が出る

1. UniGet UI（winget）と、その scoop の検索に使う scoop-search を入れる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop install scoop-search
   winget install --exact --id Devolutions.UniGetUI --source winget --scope user --accept-source-agreements --accept-package-agreements
   winget list --exact --id Devolutions.UniGetUI --source winget
   ```

   - `scoop install scoop-search` の最後に `'scoop-search' (2.1.0) was installed successfully!` の形の行が出る
   - UAC が出たら製品名と発行元を確かめて許可する。Visual C++ ランタイムの発行元は Microsoft Corporation
   - 最後の表に `UniGetUI` と `Devolutions.UniGetUI` の行が出ればよい

1. PowerToys を、自分のユーザーに入れる。

   ```powershell
   winget install --exact --id Microsoft.PowerToys --source winget --scope user --accept-source-agreements --accept-package-agreements
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget list --exact --id Microsoft.PowerToys --source winget
   ```

   - 最後の表に `PowerToys` と `Microsoft.PowerToys` の行が出ればよい
   - 管理者の確認（UAC）は出ないはず

1. PowerShell 7 を、自分のユーザーに入れる。

   ```powershell
   winget install --exact --id Microsoft.PowerShell --source winget --accept-source-agreements --accept-package-agreements
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget list --exact --id Microsoft.PowerShell --source winget
   ```

   - 最後の表に `PowerShell` と `Microsoft.PowerShell` の行が出ればよい
   - 管理者の確認（UAC）は出ないはず
   - この文書とほかの手順書のブロックは、引き続き Windows PowerShell 5.1 に貼る

---

### PC 全体の設定

- PC の名前・長いパス・電源・ロック・LAN の省電力を設定する
- 前提: [貼り付けの設定](#貼り付けの設定)を通してある。設定する LAN が接続されている
- 実行場所: 管理者の Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く。UAC の確認が出たら「はい」
   - 開いたときに、プロファイルを読めないという赤い字のエラーが出たら、実行ポリシーが `Restricted` のまま。[貼り付けの設定](#貼り付けの設定)の手順 4 を、この窓で貼り直す

1. 変数を設定する（PC の名前を変えるなら、`PC_NAME` に値を入れる）。

   ```powershell
   $PC_NAME = ''   # この PC の新しい名前（15 文字まで。英字・数字・ハイフン）。<HOSTNAME>
   ```

   ```powershell
   $LAN_IF = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).InterfaceAlias   # ほかの PC とつながる LAN の接続（自動）。<LAN_IF>
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'PC_NAME = {0}' -f $PC_NAME
   'LAN_IF  = {0}' -f $LAN_IF
   ```

   - 最後に値を読み戻して確かめる
   - 名前を変えないなら、空のままにしてこの項の手順 5 を飛ばす
   - `LAN_IF` は、インターネットにつながっている接続の名前（`イーサネット`、`Wi-Fi` など）。ほかの PC とつながる接続と違えば、`$LAN_IF = 'Wi-Fi'` のように直す
   - 変数はその PowerShell の中だけで有効。**新しい PowerShell を開いたら**、この項の手順 2 のブロックを貼り直してから先へ進む

1. 管理者であることと、プロファイルの行が効いていることと、今の値を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   $cv = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
   [pscustomobject]@{
     Admin            = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     CtrlEnter        = (Get-PSReadLineKeyHandler -Bound | Where-Object Key -eq 'Ctrl+Enter').Function
     Edition          = $cv.EditionID
     Version          = '{0}（{1}.{2}）' -f $cv.DisplayVersion, $cv.CurrentBuild, $cv.UBR
     ComputerName     = $env:COMPUTERNAME
     LanCategory      = if ($LAN_IF) { (Get-NetConnectionProfile -InterfaceAlias $LAN_IF).NetworkCategory } else { '' }
     RemoteDesktop    = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server').fDenyTSConnections
     RemoteAssistance = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance' -ErrorAction SilentlyContinue).fAllowToGetHelp
     HelloOnly        = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device' -ErrorAction SilentlyContinue).DevicePasswordLessBuildVersion
     Keyboard         = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters' -ErrorAction SilentlyContinue).'LayerDriver JPN'
     Sudo             = (Get-Command sudo -ErrorAction SilentlyContinue).Source
     Hypervisor       = (Get-CimInstance -ClassName Win32_ComputerSystem).HypervisorPresent
   } | Format-List
   Get-DODownloadMode
   ```

   - `Admin : True` と `CtrlEnter : AddLine` が出ればよい
   - `Admin` が `False` なら、管理者ではない窓に貼っている。この項の手順 1 から
   - `CtrlEnter : InsertLineAbove` なら、[貼り付けの設定](#貼り付けの設定)の手順 2・4・5 をこの順で貼り直し、窓を開き直してこの項の手順 2 から
   - 次の値を控える（[ロールバック](extra/windows-setup.md#ロールバック)で、元に戻すかを決めるのに使う）
     - `ComputerName`（PC の名前。ロールバックの「ネットワークと PC 全体の設定を戻す」の手順 9）と `LanCategory`（LAN の種類。ロールバックの「ネットワークと PC 全体の設定を戻す」の手順 5）
     - `RemoteDesktop`（1 なら無効、0 ならもう有効。ロールバックの「ネットワークと PC 全体の設定を戻す」の手順 4）と `RemoteAssistance`（1 なら有効、0 なら無効。ロールバックの「ネットワークと PC 全体の設定を戻す」の手順 3）
     - `HelloOnly`（2 ならオン、0 ならオフ。ロールバックの「サインイン・検索・キーボードを戻す」の手順 5）と `Keyboard`（`kbd106.dll` なら JIS 配列。ロールバックの「サインイン・検索・キーボードを戻す」の手順 9）
     - 最後の行の配信の最適化のモード（`Lan` が Windows の既定。ロールバックの「ネットワークと PC 全体の設定を戻す」の手順 1）
   - `Edition` が `Core` で始まる（Home）なら、[ネットワークとリモート](#ネットワークとリモート)の手順 4 は飛ばす

1. 複数行のブロックをコピーボタンでコピーして右クリックで貼り、元の順に動くことを確かめる。

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     '1 行目'
     '2 行目'
     '3 行目'
   }
   ```

   - このブロックを GitHub のコピーボタンでコピーし、この項の手順 1 の窓の中で右クリックして貼る
   - 最後の `}` の行で止まるので、Enter を押す
   - `1 行目`・`2 行目`・`3 行目` の順に出ればよい

1. PC の名前を変えるときだけ、名前を変える（効くのは再起動の後）。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not $PC_NAME) {
     Write-Error '中断: この項の手順 2 の $PC_NAME が空'
   } elseif ($PC_NAME -notmatch '^[A-Za-z0-9]([A-Za-z0-9-]{0,13}[A-Za-z0-9])?$' -or $PC_NAME -match '^[0-9]+$') {
     Write-Error "中断: 使えない名前（15 文字まで。英字・数字・ハイフンで、先頭と末尾は英数字。数字だけは不可）: $PC_NAME"
   } elseif ($PC_NAME -eq $env:COMPUTERNAME) {
     "すでにこの名前: $PC_NAME"
   } else {
     Rename-Computer -NewName $PC_NAME
     "再起動の後に $PC_NAME になる"
   }
   ```

   - 再起動を求める旨の警告と、`再起動の後に <HOSTNAME> になる` が出ればよい
   - 何度貼ってもよい（2 回目からは `すでにこの名前:`。再起動の前は、まだ古い名前と比べる）
   - 効くのは、[WSL と再起動](#wsl-と再起動)の手順 3 の再起動の後
   - 名前を変えないなら（この項の手順 2 の `PC_NAME` が空なら）、この手順は飛ばす

1. 長いパス・開発者モード・sudo（今の窓で動く形）を有効にする。

   ```powershell
   $dev = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name LongPathsEnabled -Type DWord -Value 1
   if (-not (Test-Path -LiteralPath $dev)) { New-Item -Path $dev | Out-Null }
   Set-ItemProperty -Path $dev -Name AllowDevelopmentWithoutDevLicense -Type DWord -Value 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (Get-Command sudo -ErrorAction SilentlyContinue) { sudo config --enable normal } else { 'sudo が無い（24H2 より前の Windows）' }
   Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' | Format-List LongPathsEnabled
   Get-ItemProperty -Path $dev | Format-List AllowDevelopmentWithoutDevLicense
   ```

   - `LongPathsEnabled : 1` と `AllowDevelopmentWithoutDevLicense : 1` が出ればよい
   - sudo は、今の窓で動く形（インライン）になった旨を表示する（表示言語は環境による）
   - **注意**: インラインの sudo は、同じ窓の管理者ではないプロセスからも管理者のコマンドに入力を送れる

1. 電源接続中の眠りと蓋の動作を止め、電源に関係なく休止状態と放置後のロックを切る。

   ```powershell
   powercfg /change standby-timeout-ac 0
   powercfg /hibernate off
   powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
   powercfg /setacvalueindex SCHEME_CURRENT SUB_NONE CONSOLELOCK 0
   powercfg /setactive SCHEME_CURRENT
   Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name DelayLockInterval -Type DWord -Value 0xFFFFFFFF
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   foreach ($s in 'SUB_SLEEP STANDBYIDLE', 'SUB_BUTTONS LIDACTION', 'SUB_NONE CONSOLELOCK') { '{0}: {1}' -f $s, ((powercfg /qh SCHEME_CURRENT $s.Split(' ')) | Select-String -Pattern 'AC' | Select-Object -Last 1) }
   'HibernateEnabled: {0}' -f (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power').HibernateEnabled
   ```

   - 3 つの行の AC の値が `0x00000000` で、`HibernateEnabled: 0` が出ればよい（`powercfg` の表示は日本語）
   - **注意**: PC の前にいる人は、このユーザーとしてそのまま使える（リードの `[!WARNING]`）

1. LAN のアダプターを、電力の節約のために止めないようにする。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error 'この項の手順 2 の $LAN_IF が空'
   } else {
     $pm = Get-NetAdapterPowerManagement -Name $LAN_IF
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($pm.AllowComputerToTurnOffDevice -eq 'Unsupported') { "このアダプターは対象外: $LAN_IF" } else {
       $pm.AllowComputerToTurnOffDevice = 'Disabled'
       $pm | Set-NetAdapterPowerManagement -NoRestart
     }
     Get-NetAdapterPowerManagement -Name $LAN_IF | Format-List Name, AllowComputerToTurnOffDevice, WakeOnMagicPacket
   }
   ```

   - `AllowComputerToTurnOffDevice : Disabled` が出ればよい
   - `このアダプターは対象外:` なら、このアダプターには設定が無い（何もしない）
   - 効くのは、[WSL と再起動](#wsl-と再起動)の手順 3 の再起動の後

---

### サインイン・検索・キーボード

- サインイン・検索・ショートカット・キー配列を設定する
- 前提: 無し。デュアルブートの時計を変えるときは、AlmaLinux の時計が UTC になっている
- 実行場所: 管理者の Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、右クリック →「管理者として実行」を選ぶ
   - UAC の確認で「はい」を押す。窓の名前が「管理者: Windows PowerShell」になる

1. 「Windows Hello サインインのみを許可する」を切る。

   ```powershell
   $k = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device'
   if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
   Set-ItemProperty -Path $k -Name DevicePasswordLessBuildVersion -Type DWord -Value 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $k | Format-List DevicePasswordLessBuildVersion
   ```

   - `DevicePasswordLessBuildVersion : 0` が出ればよい
   - サインインの画面で、PIN のほかにパスワードも選べるようになる

1. スタートの検索で、Web（Bing）の結果を出さないようにする。

   ```powershell
   $k = 'HKCU:\Software\Policies\Microsoft\Windows\Explorer'
   if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
   Set-ItemProperty -Path $k -Name DisableSearchBoxSuggestions -Type DWord -Value 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $k | Format-List DisableSearchBoxSuggestions
   ```

   - `DisableSearchBoxSuggestions : 1` が出ればよい
   - 効くのは、[WSL と再起動](#wsl-と再起動)の手順 3 の再起動の後

1. デスクトップの Edge と UniGet UI のショートカットを消し、Edge が作り直したら消すようにする。

   ```powershell
   $k = 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate'
   if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
   Set-ItemProperty -Path $k -Name RemoveDesktopShortcutDefault -Type DWord -Value 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   foreach ($f in (Join-Path ([Environment]::GetFolderPath('CommonDesktopDirectory')) 'Microsoft Edge.lnk'), (Join-Path ([Environment]::GetFolderPath('Desktop')) 'UniGetUI.lnk')) {
     if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f; "消した: $f" } else { "無い: $f" }
   }
   Get-ItemProperty -Path $k | Format-List RemoveDesktopShortcutDefault
   ```

   - 2 つのファイルについて `消した:` か `無い:` と、`RemoveDesktopShortcutDefault : 1` が出ればよい
   - ほかのショートカットは消さない。要らなければ手で消す

1. Caps Lock を左 Ctrl にする Scancode Map を書く。

   ```powershell
   & {
     $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
     $want = '00 00 00 00 00 00 00 00 02 00 00 00 1D 00 3A 00 00 00 00 00'
     $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     if (-not $admin) { Write-Error '中断: 管理者の PowerShell ではない（「PC 全体の設定」の手順 1 から）'; return }
     $now = (Get-ItemProperty -Path $key -ErrorAction SilentlyContinue).'Scancode Map'
     $nowHex = if ($now) { ($now | ForEach-Object { '{0:X2}' -f $_ }) -join ' ' } else { '' }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($nowHex -and $nowHex -ne $want) { Write-Error "中断: 別の Scancode Map がある（$nowHex）"; return }
     if (-not $nowHex) { New-ItemProperty -Path $key -Name 'Scancode Map' -PropertyType Binary -Value ([byte[]]($want -split ' ' | ForEach-Object { [Convert]::ToByte($_, 16) })) | Out-Null }
     'Scancode Map = {0}' -f ((((Get-ItemProperty -Path $key).'Scancode Map') | ForEach-Object { '{0:X2}' -f $_ }) -join ' ')
   }
   ```

   - `Scancode Map = 00 00 00 00 00 00 00 00 02 00 00 00 1D 00 3A 00 00 00 00 00` が出ればよい
   - 同じ値がもうあれば、何も書かずに同じ行を出す（何度貼ってもよい）
   - `中断: 別の Scancode Map がある` が出たら、ほかのキーの割り当てがある（両方を使うなら、その値を手で直す。数を 1 つ増やし、終わりの印の前に `1D 00 3A 00` を足す）
   - 効くのは、[WSL と再起動](#wsl-と再起動)の手順 3 の再起動の後

1. AlmaLinux とデュアル ブートし、AlmaLinux の時計を UTC にしているときだけ、Windows も UTC にする。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -Name RealTimeIsUniversal -Type DWord -Value 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' | Format-List RealTimeIsUniversal
   ```

   - `RealTimeIsUniversal : 1` が出ればよい
   - 効くのは、[WSL と再起動](#wsl-と再起動)の手順 3 の再起動の後。時刻がずれていたら、設定の「時刻と言語」→「日付と時刻」の「今すぐ同期」で合わせ直す
   - AlmaLinux の `timedatectl` の `RTC in local TZ:` が `yes`（`/etc/adjtime` の 3 行目が `LOCAL`）なら、この手順は飛ばす
   - デュアル ブートしない PC でも、この手順は飛ばす

1. US 配列（101/102 キー）のキーボードを使うときだけ、キーボードの種類を変える。

   ```powershell
   $k = 'HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters'
   Set-ItemProperty -Path $k -Name 'LayerDriver JPN' -Type String -Value 'kbd101.dll'
   Set-ItemProperty -Path $k -Name OverrideKeyboardIdentifier -Type String -Value 'PCAT_101KEY'
   Set-ItemProperty -Path $k -Name OverrideKeyboardType -Type DWord -Value 7
   Set-ItemProperty -Path $k -Name OverrideKeyboardSubtype -Type DWord -Value 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $k | Format-List 'LayerDriver JPN', OverrideKeyboardIdentifier, OverrideKeyboardType, OverrideKeyboardSubtype
   ```

   - `LayerDriver JPN : kbd101.dll`・`OverrideKeyboardIdentifier : PCAT_101KEY`・`OverrideKeyboardType : 7`・`OverrideKeyboardSubtype : 0` が出ればよい
   - JIS 配列（日本語の 106/109 キー）のキーボードなら、この手順は飛ばす
   - 効くのは、[WSL と再起動](#wsl-と再起動)の手順 3 の再起動の後。日本語の入力の切り替えは、[表示と入力](#表示と入力)の手順 8 の Ctrl+Space（または Alt+`）で行う

---

### WSL と再起動

- WSL の機能を有効にして、この PC を再起動する
- 前提: 無し
- 実行場所: 管理者の Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、右クリック →「管理者として実行」を選ぶ
   - UAC の確認で「はい」を押す。窓の名前が「管理者: Windows PowerShell」になる

1. WSL を使えるように、Windows の機能を入れる（ディストリビューションは再起動の後に入れる）。

   ```powershell
   wsl.exe --install --no-distribution
   ```

   - 必要な機能（仮想マシン プラットフォーム）を入れた旨と、再起動を求める旨の行が出ればよい
   - もう入っていれば、何もしない
   - **注意**: この後、VirtualBox の VM は Hyper-V の上で動く。遅ければ[VirtualBox の注意点](extra/virtualbox.md#注意点)を読む

1. 再起動する。

   ```powershell
   Restart-Computer
   ```

   - 保存していない作業があれば、先に保存する（すぐに再起動が始まる）
   - ほかのユーザーがサインインしていると、エラーで止まる。そのときは、スタートメニューの電源から再起動する
   - **次の手順は、起動してサインインしてから行う**

---

### WSL の AlmaLinux 10 と自動サインイン

- WSL に AlmaLinux 10 を入れ、必要なら Windows の自動サインインを有効にする
- 前提: [WSL と再起動](#wsl-と再起動)で機能を入れて再起動し、[Microsoft Store の更新](#microsoft-store-の更新)で winget を用意してある。状態確認は、通した項の値だけを確かめる
- 実行場所: 管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）
   - 複数行のブロックを貼ると出る警告では、「強制的に貼り付け」を押す

1. 再起動の後の状態を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   $sm = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout' -ErrorAction SilentlyContinue).'Scancode Map'
   [pscustomobject]@{
     ComputerName  = $env:COMPUTERNAME
     CtrlEnter     = (Get-PSReadLineKeyHandler -Bound | Where-Object Key -eq 'Ctrl+Enter').Function
     ScancodeMap   = if ($sm) { ($sm | ForEach-Object { '{0:X2}' -f $_ }) -join ' ' } else { '' }
     Keyboard      = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters' -ErrorAction SilentlyContinue).'LayerDriver JPN'
     LongPaths     = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem').LongPathsEnabled
     DeveloperMode = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
     Sudo          = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo' -ErrorAction SilentlyContinue).Enabled
     Hibernate     = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power').HibernateEnabled
     RemoteDesktop = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server').fDenyTSConnections
     LanCategory   = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).NetworkCategory
     Hypervisor    = (Get-CimInstance -ClassName Win32_ComputerSystem).HypervisorPresent
   } | Format-List
   ```

   - 次の値が出ればよい（行わなかった手順の値は、元のまま）
     - `ComputerName` が設定した名前（大文字）、`LongPaths : 1`・`DeveloperMode : 1`・`Sudo : 3`・`Hibernate : 0`（[PC 全体の設定](#pc-全体の設定)を通したとき）
     - `CtrlEnter : AddLine`（[貼り付けの設定](#貼り付けの設定)を通したとき）
     - `ScancodeMap : 00 00 00 00 00 00 00 00 02 00 00 00 1D 00 3A 00 00 00 00 00`（[サインイン・検索・キーボード](#サインイン検索キーボード)を通したとき）
     - `Keyboard` は、[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 7 を行ったなら `kbd101.dll`
     - `RemoteDesktop : 0`・`LanCategory : Private`（[ネットワークとリモート](#ネットワークとリモート)を通したとき。Home の `RemoteDesktop` は確かめない）
     - `Hypervisor : True`（[WSL と再起動](#wsl-と再起動)を通したとき）

1. WSL に AlmaLinux 10 を入れ、ユーザーを作る。

   ```powershell
   $env:WSL_UTF8 = '1'
   [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
   wsl.exe --install AlmaLinux-10
   ```

   - ダウンロードの後に `Enter new UNIX username:` と聞かれるので、Linux のユーザー名を入れる。続けてパスワードを 2 回入れる
   - AlmaLinux 10 のシェル（`[<ユーザー>@<HOSTNAME> ~]$`）になったら、`exit` で PowerShell に戻る
   - **次の手順は、`exit` で PowerShell に戻ってから貼る**（続けて貼ると、AlmaLinux 10 のシェルへの入力として食われる）

1. AlmaLinux 10 が WSL 2 で動くことを確かめる。

   ```powershell
   $env:WSL_UTF8 = '1'
   [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   wsl.exe --list --verbose
   wsl.exe --distribution AlmaLinux-10 -- head -n 2 /etc/os-release
   ```

   - `AlmaLinux-10` の行の `VERSION` が `2` で、`NAME="AlmaLinux"` と `VERSION="10.2 …"` の形の行が出ればよい

1. 自動サインイン（Sysinternals の Autologon）を入れて起動し、パスワードを入れて有効にする。

   ```powershell
   winget install --exact --id Microsoft.Sysinternals.Autologon --source winget --scope user --accept-source-agreements --accept-package-agreements
   $exe = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter Autologon64.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
   if (-not $exe) { Write-Error '中断: Autologon64.exe が見つからない' } else { Start-Process -FilePath $exe -ArgumentList '-accepteula' }
   ```

   - UAC の確認が出たら「はい」。Autologon の窓が開く
   - `Username` にこの PC のユーザー名、`Domain` に PC の名前（入っている値のまま）、`Password` にこのユーザーのパスワードを入れ、`Enable` を押す
   - 効くのは、次に起動したときから（起動のときに Shift を押していると、その回は飛ばす）
   - 人が触れる場所にある PC では、この手順は行わない（リードの `[!WARNING]`）

---

### プライバシーと広告の表示を切る

- 自分のユーザーの広告・プライバシー・検索の設定を変える
- 前提: 無し
- 実行場所: 管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

- **この項の手順 3 でサインアウトしてサインインし直し、この項の手順 4・6 は設定の画面で行う**
- **ポリシー（`HKLM` や `HKCU\Software\Policies`）には書かない**。ポリシーを置くと、設定の画面の切り替えが灰色になり、「組織によって管理」の表示が出るため
- 値の多くは Microsoft の文書に無く、広く使われているもの（[参考資料](reference/windows-setup.md)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-setup.md)）
- 戻すときは、この項の手順 5・6（行った手順のものだけ）

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）

1. 自分のユーザーで、プライバシーと広告の設定を切る（元の値はファイルに控える）。

   ```powershell
   & {
     $rec = Join-Path $env:LOCALAPPDATA 'setup-notes\privacy-before.csv'
     $set = @(
       @('HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo', 'Enabled', 0),
       @('HKCU:\Control Panel\International\User Profile', 'HttpAcceptLanguageOptOut', 1),
       @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy', 'TailoredExperiencesWithDiagnosticDataEnabled', 0),
       @('HKCU:\Software\Microsoft\Input\TIPC', 'Enabled', 0),
       @('HKCU:\Software\Microsoft\Siuf\Rules', 'NumberOfSIUFInPeriod', 0),
       @('HKCU:\Software\Microsoft\Siuf\Rules', 'PeriodInNanoSeconds', 0),
       @('HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy', 'HasAccepted', 0),
       @('HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings', 'IsMSACloudSearchEnabled', 0),
       @('HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings', 'IsAADCloudSearchEnabled', 0),
       @('HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings', 'IsDeviceSearchHistoryEnabled', 0),
       @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced', 'ShowSyncProviderNotifications', 0)
     )
     $old = foreach ($s in $set) { $key = Get-Item -LiteralPath $s[0] -ErrorAction SilentlyContinue; [pscustomobject]@{ Path = $s[0]; Name = $s[1]; Value = [string](Get-ItemProperty -LiteralPath $s[0] -ErrorAction SilentlyContinue).($s[1]); Kind = $(if ($key -and ($key.GetValueNames() -contains $s[1])) { [string]$key.GetValueKind($s[1]) } else { '' }) } }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (Test-Path -LiteralPath $rec) { "控えはもうある（書き換えない）: $rec" } else {
       New-Item -ItemType Directory -Path (Split-Path -Path $rec) -Force | Out-Null
       $old | Export-Csv -LiteralPath $rec -NoTypeInformation -Encoding UTF8
       "控えた: $rec"
     }
     for ($i = 0; $i -lt $set.Count; $i++) {
       $p, $n, $v = $set[$i]
       if (-not (Test-Path -LiteralPath $p)) { New-Item -Path $p -Force | Out-Null }
       Set-ItemProperty -LiteralPath $p -Name $n -Type DWord -Value $v
       '{0}\{1}: {2} -> {3}' -f (Split-Path -Path $p -Leaf), $n, $old[$i].Value, (Get-ItemProperty -LiteralPath $p).$n
     }
   }
   ```

   - `控えた:` か `控えはもうある` の行と、`AdvertisingInfo\Enabled: 1 -> 0` の形の 11 行が出て、`->` の右がすべて `0`（`HttpAcceptLanguageOptOut` だけ `1`）ならよい
   - `->` の左は元の値（空なら値が無かった）。初めて貼ったときに `%LOCALAPPDATA%\setup-notes\privacy-before.csv` に控え、2 回目からは書き換えない（この項の手順 5 で使う）
   - `IsDeviceSearchHistoryEnabled` は、0 と 1 のどちらがオフかで資料が食い違う。この項の手順 4 の画面で確かめる
   - 多くは、この項の手順 3 でサインインし直した後に効く

1. サインアウトして、同じユーザーでサインインし直す。

   - スタートメニューのユーザーのアイコンから「サインアウト」を選ぶ（スタートメニューの電源から再起動してもよい）
   - **次の手順は、サインインし、この項の手順 1 と同じ方法で管理者ではない窓を開いてから貼る**

1. 設定の「プライバシーとセキュリティ」を開き、切り替えを確かめ、残りを画面で切る。

   ```powershell
   Start-Process 'ms-settings:privacy'
   ```

   - 「全般」（新しいビルドでは「おすすめとオファー」）で、広告 ID と言語リストの切り替えがオフ。「設定アプリで通知を表示する」があれば、オフにする
   - 「音声認識」で、「オンライン音声認識」がオフ
   - 「手書き入力と入力の個人用設定」で、「カスタム手書き入力と入力の辞書」をオフにする（覚えた単語の一覧が消える）
   - 「診断とフィードバック」で、「オプションの診断データを送信する」がオンなら、オフにする。「手書き入力と入力の改善」と「カスタマイズされたエクスペリエンス」がオフ、「フィードバックの頻度」が「しない」
   - 新しいビルドでは、「カスタマイズされたエクスペリエンス」は「パーソナライズされたオファー」の名前で別のページにある
   - 「検索のアクセス許可」で、「クラウドのコンテンツ検索」の 2 つと「このデバイスの検索履歴」がオフ。「検索のハイライトを表示する」は、[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 3 の値で灰色になっている
   - この項の手順 2 で書いた項目がオンのまま出ていたら、その画面でオフにする
   - **次の手順は、設定を閉じてから貼る**

1. 元に戻すときは（この項の手順 2 を行ったとき）、控えた元の値に戻す。

   ```powershell
   & {
     $rec = Join-Path $env:LOCALAPPDATA 'setup-notes\privacy-before.csv'
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (-not (Test-Path -LiteralPath $rec)) { Write-Error "中断: 控えが無い: $rec"; return }
     foreach ($r in Import-Csv -LiteralPath $rec) {
       if ($r.Value -match '^-?[0-9]+$') { Set-ItemProperty -LiteralPath $r.Path -Name $r.Name -Type $(if ($r.Kind -eq 'QWord') { 'QWord' } else { 'DWord' }) -Value ([long]$r.Value) } else { Remove-ItemProperty -LiteralPath $r.Path -Name $r.Name -ErrorAction SilentlyContinue }
       '{0}\{1}: {2}' -f (Split-Path -Path $r.Path -Leaf), $r.Name, (Get-ItemProperty -LiteralPath $r.Path -ErrorAction SilentlyContinue).($r.Name)
     }
   }
   ```

   - 11 行が出て、`:` の右が控えた元の値（元が空なら空）ならよい。元の値が無かったものは消す
   - `中断: 控えが無い` が出たら、この項の手順 6 の画面で戻す
   - 控えのファイルは残る。要らなければ手で消す
   - 効くのは、サインインし直した後

1. 元に戻すときは（この項の手順 4 で切ったものを使うときか、この項の手順 5 で控えが無かったとき）、設定の画面でオンに戻す。

   ```powershell
   Start-Process 'ms-settings:privacy'
   ```

   - この項の手順 4 でオフにした「設定アプリで通知を表示する」・「カスタム手書き入力と入力の辞書」・「オプションの診断データを送信する」のうち、使うものをオンにする
   - この項の手順 5 で `中断: 控えが無い` が出たときは、この項の手順 2 で切った項目（「全般」の広告 ID と言語リスト・「オンライン音声認識」・「手書き入力と入力の改善」・「カスタマイズされたエクスペリエンス」・「フィードバックの頻度」・「検索のアクセス許可」の 3 つ）も、使うものを戻す
   - 同じときに、エクスプローラーの同期プロバイダーの通知も使うなら、フォルダー オプションの「表示」で戻す
   - 消えた辞書（覚えた単語の一覧）は戻らない

---

### Edge の常駐をポリシーで止める

- Edge のスタートアップ ブーストとバックグラウンドの実行を切る
- 前提: 無し
- 実行場所: 管理者の Windows PowerShell（5.1）。この項の手順 1 で開く

- **この項の手順 2 のポリシーを置くと、Edge に「組織によって管理されている」旨が出て、Edge の設定の 2 つの切り替えが灰色になる**。出したくないなら、この項の手順 2 の代わりにこの項の手順 3（画面だけで切る）を行う
- [サインイン・検索・キーボード](#サインイン検索キーボード)の手順 4 の Edge Update のポリシー（`EdgeUpdate` のキー）とは別のキー（`Edge`）に書く
- **この項の手順 3・4 は Edge の画面で行う**
- 戻すときは、この項の手順 5・6（行った手順のものだけ）

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く。UAC の確認が出たら「はい」

1. Edge のスタートアップ ブーストとバックグラウンドの実行を、ポリシーで切る。

   ```powershell
   $k = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
   if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
   Set-ItemProperty -Path $k -Name StartupBoostEnabled -Type DWord -Value 0
   Set-ItemProperty -Path $k -Name BackgroundModeEnabled -Type DWord -Value 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $k | Format-List StartupBoostEnabled, BackgroundModeEnabled
   ```

   - `StartupBoostEnabled : 0` と `BackgroundModeEnabled : 0` が出ればよい
   - 開いている Edge には、開き直すか、`edge://policy` の「ポリシーの再読み込み」で効く
   - [自動起動と標準アプリ](#自動起動と標準アプリ)の手順 2 で止めた `MicrosoftEdgeAutoLaunch_*` の行は、無くなることがある（同じ項の手順 2 と[ロールバックの「表示と入力を戻す」](extra/windows-setup.md#表示と入力を戻す)の手順 8 は、無いものを飛ばす）

1. （この項の手順 2 の代わりに）管理の表示を出したくないときは、Edge の設定の画面で 2 つを切る。

   - Edge のアドレス バーに `edge://settings/system` を入れて開く（「設定」→「システムとパフォーマンス」→「システム」）
   - 「スタートアップ ブースト」をオフにする
   - 「Microsoft Edge が終了してもバックグラウンドの拡張機能およびアプリの実行を続行する」をオフにする

1. Edge で、2 つが切れていることを確かめる。

   - `edge://settings/system` で、2 つがオフになっている（この項の手順 2 を行ったなら、灰色で変えられない）
   - この項の手順 2 を行ったなら、`edge://policy` に `StartupBoostEnabled` と `BackgroundModeEnabled` が、値 `false`・状態 `OK` で出る
   - Edge の窓をすべて閉じると、通知領域に Edge のアイコンが残らない
   - サインインし直した後も `msedge.exe` が見えることがある

1. 元に戻すときは（この項の手順 2 を行ったとき）、管理者の PowerShell で、2 つのポリシーを消す。

   ```powershell
   $k = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
   foreach ($n in 'StartupBoostEnabled', 'BackgroundModeEnabled') { Remove-ItemProperty -Path $k -Name $n -ErrorAction SilentlyContinue }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $k -ErrorAction SilentlyContinue | Format-List StartupBoostEnabled, BackgroundModeEnabled
   ```

   - 2 つが空ならよい
   - Edge を開き直すと、2 つの切り替えをまた変えられる

1. 元に戻すときは（この項の手順 3 を行ったとき）、Edge の設定の画面で 2 つをオンに戻す。

   - `edge://settings/system` で、この項の手順 3 でオフにした 2 つをオンにする

---

## デスクトップ

- エクスプローラー・表示・入力・音・ストレージ、自動起動と標準アプリ、フォント、クリップボード、PowerToys、ホットキー、Windows Terminal と、再起動の後の確認

### 表示と入力

- エクスプローラー・タスクバー・テーマ・既定の端末・IME を設定する
- 前提: Windows Terminal が入っている（[Microsoft Store の更新](#microsoft-store-の更新)で更新する）
- 実行場所: 管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）
   - 窓の名前に「管理者:」が付いていないことを確かめる

1. エクスプローラーで、拡張子と隠しファイルを表示し、「PC」で開き、最近使ったものを出さないようにする。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   $exp = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
   Set-ItemProperty -Path $adv -Name HideFileExt -Type DWord -Value 0
   Set-ItemProperty -Path $adv -Name Hidden -Type DWord -Value 1
   Set-ItemProperty -Path $adv -Name LaunchTo -Type DWord -Value 1
   Set-ItemProperty -Path $adv -Name Start_TrackDocs -Type DWord -Value 0
   Set-ItemProperty -Path $exp -Name ShowRecent -Type DWord -Value 0
   Set-ItemProperty -Path $exp -Name ShowFrequent -Type DWord -Value 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $adv | Format-List HideFileExt, Hidden, LaunchTo, Start_TrackDocs
   Get-ItemProperty -Path $exp | Format-List ShowRecent, ShowFrequent
   ```

   - `HideFileExt : 0`・`Hidden : 1`・`LaunchTo : 1`・`Start_TrackDocs : 0`・`ShowRecent : 0`・`ShowFrequent : 0` が出ればよい
   - 開いているエクスプローラーの窓には、開き直すか[WSL と再起動](#wsl-と再起動)の手順 3 の再起動の後に効く

1. 自分のユーザーで、旧形式のコンテキストメニューを出すようにする。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   reg.exe add 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' /f /ve
   reg.exe query 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' /ve
   ```

   - `reg.exe add` が成功の 1 行を出し、`reg.exe query` に `(既定)`（英語の表示では `(Default)`）と `REG_SZ` の行が出ればよい（値は空）
   - エクスプローラーに効くのは、[WSL と再起動](#wsl-と再起動)の手順 3 の再起動の後

1. スタートと設定の、おすすめ・提案・ヒントを切る。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   $cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
   $upe = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement'
   Set-ItemProperty -Path $adv -Name Start_IrisRecommendations -Type DWord -Value 0
   Set-ItemProperty -Path $adv -Name Start_AccountNotifications -Type DWord -Value 0
   foreach ($n in 'SubscribedContent-338393Enabled', 'SubscribedContent-353694Enabled', 'SubscribedContent-353696Enabled', 'SubscribedContent-338389Enabled', 'SubscribedContent-310093Enabled', 'SubscribedContent-338388Enabled', 'SystemPaneSuggestionsEnabled', 'SilentInstalledAppsEnabled') { Set-ItemProperty -Path $cdm -Name $n -Type DWord -Value 0 }
   if (-not (Test-Path -LiteralPath $upe)) { New-Item -Path $upe | Out-Null }
   Set-ItemProperty -Path $upe -Name ScoobeSystemSettingEnabled -Type DWord -Value 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $adv | Format-List Start_IrisRecommendations, Start_AccountNotifications
   Get-ItemProperty -Path $cdm | Format-List SubscribedContent-338393Enabled, SubscribedContent-353694Enabled, SubscribedContent-353696Enabled, SubscribedContent-338389Enabled, SubscribedContent-310093Enabled, SubscribedContent-338388Enabled, SystemPaneSuggestionsEnabled, SilentInstalledAppsEnabled
   Get-ItemProperty -Path $upe | Format-List ScoobeSystemSettingEnabled
   ```

   - 並んだ値がすべて `0` ならよい
   - [自動起動と標準アプリ](#自動起動と標準アプリ)の手順 3 より前に貼る

1. タスクバーを左に寄せ、タスク ビューと検索のボタンを消し、時計に秒を出す。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   Set-ItemProperty -Path $adv -Name TaskbarAl -Type DWord -Value 0
   Set-ItemProperty -Path $adv -Name ShowTaskViewButton -Type DWord -Value 0
   Set-ItemProperty -Path $adv -Name ShowSecondsInSystemClock -Type DWord -Value 1
   Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name SearchboxTaskbarMode -Type DWord -Value 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $adv | Format-List TaskbarAl, ShowTaskViewButton, ShowSecondsInSystemClock
   Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' | Format-List SearchboxTaskbarMode
   ```

   - `TaskbarAl : 0`・`ShowTaskViewButton : 0`・`ShowSecondsInSystemClock : 1`・`SearchboxTaskbarMode : 0` が出ればよい
   - タスクバーには、すぐか、[WSL と再起動](#wsl-と再起動)の手順 3 の再起動の後に効く

1. ダークモードにする。

   ```powershell
   $p = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
   Set-ItemProperty -Path $p -Name AppsUseLightTheme -Type DWord -Value 0
   Set-ItemProperty -Path $p -Name SystemUsesLightTheme -Type DWord -Value 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $p | Format-List AppsUseLightTheme, SystemUsesLightTheme
   ```

   - `AppsUseLightTheme : 0` と `SystemUsesLightTheme : 0` が出ればよい
   - 動いているアプリとタスクバーには、[WSL と再起動](#wsl-と再起動)の手順 3 の再起動の後に効く

1. 既定の端末を Windows Terminal にする。

   ```powershell
   $p = 'HKCU:\Console\%%Startup'
   if (-not (Test-Path -LiteralPath $p)) { New-Item -Path $p | Out-Null }
   Set-ItemProperty -LiteralPath $p -Name DelegationConsole -Type String -Value '{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}'
   Set-ItemProperty -LiteralPath $p -Name DelegationTerminal -Type String -Value '{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}'
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -LiteralPath $p | Format-List DelegationConsole, DelegationTerminal
   ```

   - `DelegationConsole : {2EACA947-…}` と `DelegationTerminal : {E12CFF52-…}` が出ればよい
   - 次に起動したコンソールのアプリから効く
   - **注意**: 管理者の PowerShell は conhost で開く。右クリックで貼るには[貼り付けの設定](#貼り付けの設定)の手順 1〜5 が必要

1. Microsoft IME の設定を開き、Ctrl+Space で IME をオン・オフするようにする。

   ```powershell
   Start-Process 'ms-settings:regionlanguage-jpnime'
   ```

   - 設定の Microsoft IME の画面が開く。「キーとタッチのカスタマイズ」を開き、「キーの割り当て」をオンにして、「Ctrl + Space」を「IME-オン/オフ」にする
   - 「以前のバージョンの Microsoft IME を使う」がオンだと、この項目は出ない
   - 効くのは、次に IME を使う窓から（確かめるのは[再起動の後に確かめる](#再起動の後に確かめる)の手順 1）
   - 割り当てたら、設定を閉じる

---

### 表示・入力・音・ストレージを変える

- 自分のユーザーの設定で、次のものを変える
  - 誤って押しやすいキー: 固定キー・フィルター キー・切り替えキーのショートカット、入力言語とキー配列の切り替え（Alt+Shift・Ctrl+Shift）
  - 窓とエクスプローラー: Alt+Tab の Edge のタブ、タイトル バーのシェイク、左の一覧のギャラリーとホーム、タスクバーの「タスクの終了」
  - アニメーション効果、効果音と起動音、ストレージ センサー
- 項目は独立しているので、要らない手順は飛ばしてよい（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 1・2・13・14 は飛ばさない）
- [表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 10・12・14 は**画面で行い**、同じ項の手順 13 で**サインアウトしてサインインし直す**
- **ストレージ センサーは、一時ファイルとごみ箱に 30 日を超えて置いたファイルを毎月消す（取り戻せない）**
  - ごみ箱を置き場に使うなら、[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 11・12 を飛ばすか、同じ項の手順 12 でごみ箱を「許可しない」にする
- 入力言語の切り替えのキーを切っても、Win+Space で切り替えられる
- 戻すときは、[表示・入力・音・ストレージを元に戻す](#表示入力音ストレージを元に戻す)の手順 1〜10（行った手順のものだけ）。[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 2 で控えた値を使う

#### 表示・入力・音・ストレージを控えて変える

- キーの切り替え・表示・効果音・ストレージ センサーの値を控えて変える
- 前提: 無し
- 実行場所: 管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。「Windows PowerShell (x86)」は使わない）

1. 今の値を表示し、ファイルに控える。

   ```powershell
   & {
     $rec = Join-Path $env:LOCALAPPDATA 'setup-notes\display-before.csv'
     $acc = 'HKCU:\Control Panel\Accessibility'
     $tog = 'HKCU:\Keyboard Layout\Toggle'
     $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
     $cls = 'HKCU:\Software\Classes\CLSID'
     $now = [ordered]@{
       'StickyKeys'                             = (Get-ItemProperty -LiteralPath "$acc\StickyKeys" -ErrorAction SilentlyContinue).Flags
       'Keyboard Response'                      = (Get-ItemProperty -LiteralPath "$acc\Keyboard Response" -ErrorAction SilentlyContinue).Flags
       'ToggleKeys'                             = (Get-ItemProperty -LiteralPath "$acc\ToggleKeys" -ErrorAction SilentlyContinue).Flags
       'Hotkey'                                 = (Get-ItemProperty -LiteralPath $tog -ErrorAction SilentlyContinue).'Hotkey'
       'Language Hotkey'                        = (Get-ItemProperty -LiteralPath $tog -ErrorAction SilentlyContinue).'Language Hotkey'
       'Layout Hotkey'                          = (Get-ItemProperty -LiteralPath $tog -ErrorAction SilentlyContinue).'Layout Hotkey'
       'MultiTaskingAltTabFilter'               = (Get-ItemProperty -LiteralPath $adv).MultiTaskingAltTabFilter
       'DisallowShaking'                        = (Get-ItemProperty -LiteralPath $adv).DisallowShaking
       '{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}' = Test-Path -LiteralPath "$cls\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
       '{f874310e-b6b7-47dc-bc84-b9e6b38f5903}' = Test-Path -LiteralPath "$cls\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}"
       'TaskbarEndTask'                         = (Get-ItemProperty -LiteralPath "$adv\TaskbarDeveloperSettings" -ErrorAction SilentlyContinue).TaskbarEndTask
       'MinAnimate'                             = (Get-ItemProperty -LiteralPath 'HKCU:\Control Panel\Desktop\WindowMetrics' -ErrorAction SilentlyContinue).MinAnimate
       'SoundScheme'                            = (Get-ItemProperty -LiteralPath 'HKCU:\AppEvents\Schemes' -ErrorAction SilentlyContinue).'(default)'
     }
     $rows = foreach ($n in $now.Keys) { [pscustomobject]@{ Name = $n; Value = [string]$now[$n] } }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (Test-Path -LiteralPath $rec) { "控えはもうある（書き換えない）: $rec" } else {
       New-Item -ItemType Directory -Path (Split-Path -Path $rec) -Force | Out-Null
       $rows | Export-Csv -LiteralPath $rec -NoTypeInformation -Encoding UTF8
       "控えた: $rec"
     }
     $rows | Format-Table -AutoSize
   }
   ```

   - `控えた:` か `控えはもうある` の行と、13 行の表（`Name` と `Value`）が出ればよい。値が無いものは空
   - 控えは `%LOCALAPPDATA%\setup-notes\display-before.csv`。初めて貼ったときだけ作り、2 回目からは書き換えない（[表示・入力・音・ストレージを元に戻す](#表示入力音ストレージを元に戻す)の手順 3〜6 で使う）

1. 固定キー・フィルター キー・切り替えキーのショートカットを切る。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   foreach ($k in 'StickyKeys', 'Keyboard Response', 'ToggleKeys') {
     $p = "HKCU:\Control Panel\Accessibility\$k"
     $v = (Get-ItemProperty -LiteralPath $p -ErrorAction SilentlyContinue).Flags
     if ($null -eq $v -or $v -notmatch '^[0-9]+$') { "無い: $k" } else {
       Set-ItemProperty -LiteralPath $p -Name Flags -Type String -Value ([string]([int]$v -band (-bnot 4)))
       '{0}: {1} -> {2}' -f $k, $v, (Get-ItemProperty -LiteralPath $p).Flags
     }
   }
   ```

   - `StickyKeys: 510 -> 506`・`Keyboard Response: 126 -> 122`・`ToggleKeys: 62 -> 58` の形で出ればよい（左の数は PC で違うことがある）
   - `無い:` が出たキーには、何も書かない
   - 効くのは、この項の手順 13 でサインインし直した後
   - **注意**: サインインし直すまで、設定の「アクセシビリティ」→「キーボード」を開かない（今の値で書き戻されることがある）

1. 入力言語とキー配列を切り替えるキー（Alt+Shift・Ctrl+Shift）を切る。

   ```powershell
   & {
     $t = 'HKCU:\Keyboard Layout\Toggle'
     if (-not (Test-Path -LiteralPath $t)) { New-Item -Path $t -Force | Out-Null }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($n in 'Hotkey', 'Language Hotkey', 'Layout Hotkey') {
       $old = (Get-ItemProperty -LiteralPath $t).$n
       Set-ItemProperty -LiteralPath $t -Name $n -Type String -Value '3'
       '{0}: {1} -> {2}' -f $n, $old, (Get-ItemProperty -LiteralPath $t).$n
     }
   }
   ```

   - 3 行とも `->` の右が `3`（割り当てなし）ならよい
   - 効くのは、この項の手順 13 でサインインし直した後

1. Alt+Tab に Edge のタブを出さず、タイトル バーのシェイクを切る。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   Set-ItemProperty -Path $adv -Name MultiTaskingAltTabFilter -Type DWord -Value 3
   Set-ItemProperty -Path $adv -Name DisallowShaking -Type DWord -Value 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $adv | Format-List MultiTaskingAltTabFilter, DisallowShaking
   ```

   - `MultiTaskingAltTabFilter : 3` と `DisallowShaking : 1` が出ればよい
   - 効くのは、この項の手順 13 でサインインし直した後

1. エクスプローラーの左の一覧から、ギャラリーとホームを消す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   foreach ($g in '{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}', '{f874310e-b6b7-47dc-bc84-b9e6b38f5903}') {
     '既にあった {0}: {1}' -f $g, (Test-Path -LiteralPath "HKCU:\Software\Classes\CLSID\$g")
     reg.exe add "HKCU\Software\Classes\CLSID\$g" /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d 0 /f
     reg.exe query "HKCU\Software\Classes\CLSID\$g" /v System.IsPinnedToNameSpaceTree
   }
   ```

   - キーごと（`{e88865ea-…}` がギャラリー、`{f874310e-…}` がホーム）に、`既にあった` の行と、成功の 1 行と、`System.IsPinnedToNameSpaceTree    REG_DWORD    0x0` が出ればよい
   - 効くのは、エクスプローラーの窓をすべて閉じて開き直した後
   - 左の一覧を右クリックして「すべてのフォルダーを表示」をオンにすると、どちらも出る
   - 「Windows PowerShell (x86)」で貼ると、別の場所に書かれて効かない

1. タスクバーのアプリの右クリックに「タスクの終了」を出す。

   ```powershell
   $k = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings'
   if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
   Set-ItemProperty -LiteralPath $k -Name TaskbarEndTask -Type DWord -Value 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -LiteralPath $k | Format-List TaskbarEndTask
   ```

   - `TaskbarEndTask : 1` が出ればよい
   - **注意**: 「タスクの終了」はアプリのプロセスを終わらせるので、保存していない内容は失われる

1. アニメーション効果（最小化・最大化のアニメーションも）を切る。

   ```powershell
   & {
     Add-Type -Namespace SetupNotes -Name Spi -MemberDefinition @'
   [StructLayout(LayoutKind.Sequential)] public struct ANIMATIONINFO { public uint cbSize; public int iMinAnimate; }
   [DllImport("user32.dll", SetLastError = true)] public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
   [DllImport("user32.dll", SetLastError = true)] public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, ref int pvParam, uint fWinIni);
   [DllImport("user32.dll", SetLastError = true)] public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, ref ANIMATIONINFO pvParam, uint fWinIni);
   '@
     $f = 3   # SPIF_UPDATEINIFILE (1) + SPIF_SENDCHANGE (2)
     [void][SetupNotes.Spi]::SystemParametersInfo(0x1043, 0, [IntPtr]::Zero, $f)   # SPI_SETCLIENTAREAANIMATION: FALSE
     $ai = New-Object 'SetupNotes.Spi+ANIMATIONINFO'
     $ai.cbSize = 8
     $ai.iMinAnimate = 0
     [void][SetupNotes.Spi]::SystemParametersInfo(0x0049, 8, [ref]$ai, $f)   # SPI_SETANIMATION
     $on = 1
     [void][SetupNotes.Spi]::SystemParametersInfo(0x1042, 0, [ref]$on, 0)   # SPI_GETCLIENTAREAANIMATION
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'ClientAreaAnimation : {0}' -f $on
     'MinAnimate          : {0}' -f (Get-ItemProperty -LiteralPath 'HKCU:\Control Panel\Desktop\WindowMetrics').MinAnimate
   }
   ```

   - `ClientAreaAnimation : 0` と `MinAnimate : 0` が出ればよい
   - すぐに効く（開いているアプリの一部は、起動し直した後）

1. 効果音を「サウンドなし」にする（今の設定はファイルに控える）。

   ```powershell
   & {
     $bak = Join-Path $env:LOCALAPPDATA 'setup-notes\appevents.reg'
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (Test-Path -LiteralPath $bak) { "控えはもうある（書き換えない）: $bak" } else {
       New-Item -ItemType Directory -Path (Split-Path -Path $bak) -Force | Out-Null
       reg.exe export 'HKCU\AppEvents' $bak /y
     }
     if (-not (Test-Path -LiteralPath $bak)) { Write-Error "中断: 控えを作れなかった: $bak"; return }
     $n = 0
     Get-ChildItem -Path 'HKCU:\AppEvents\Schemes\Apps\*\*' | ForEach-Object {
       $cur = Join-Path $_.PSPath '.Current'
       if (Test-Path -LiteralPath $cur) { Set-ItemProperty -LiteralPath $cur -Name '(default)' -Type String -Value ''; $n++ }
     }
     Set-ItemProperty -Path 'HKCU:\AppEvents\Schemes' -Name '(default)' -Type String -Value '.None'
     'Scheme : {0}' -f (Get-ItemProperty -Path 'HKCU:\AppEvents\Schemes').'(default)'
     '空にしたイベント : {0}' -f $n
   }
   ```

   - 控えを作った成功の 1 行（2 回目からは `控えはもうある`）と、`Scheme : .None` と、空にしたイベントの数（1 以上）が出ればよい
   - 控えは `%LOCALAPPDATA%\setup-notes\appevents.reg`。初めて貼ったときだけ作り、2 回目からは書き換えない（[表示・入力・音・ストレージを元に戻す](#表示入力音ストレージを元に戻す)の手順 8 で戻す）
   - 次に鳴る音から効く
   - 後から入れたアプリが足したイベントには、音が入る。気になれば、この手順を貼り直す

1. 起動音も消すときだけ、サウンドの画面を開き、起動音を切る。

   ```powershell
   control.exe 'mmsys.cpl,,2'
   ```

   - 「サウンド」のタブが開く。「Windows スタートアップのサウンドを再生する」のチェックを外し、「OK」を押す
   - 管理者の確認（UAC）が出ることがある
   - 同じタブの「サウンド設定」が「サウンドなし」になっていれば、この項の手順 9 が効いている
   - **次の手順は、サウンドの画面を閉じてから貼る**

1. ストレージ センサーをオンにし、一時ファイルと古いごみ箱を毎月消すようにする（取り戻せない）。

   ```powershell
   & {
     $k = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'
     $set = [ordered]@{ '01' = 1; '04' = 1; '08' = 1; '256' = 30; '32' = 0; '512' = 0; '2048' = 30 }
     if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($n in $set.Keys) {
       $old = (Get-ItemProperty -LiteralPath $k).$n
       Set-ItemProperty -LiteralPath $k -Name $n -Type DWord -Value $set[$n]
       '{0}: {1} -> {2}' -f $n, $old, (Get-ItemProperty -LiteralPath $k).$n
     }
   }
   ```

   - 7 行が出て、`->` の右が `01`・`04`・`08` は `1`、`256` と `2048` は `30`、`32` と `512` は `0` ならよい
   - `->` の左（元の値）を控える。空なら値が無かった。数があったなら、[表示・入力・音・ストレージを元に戻す](#表示入力音ストレージを元に戻す)の手順 10 で戻した後に、画面で同じにし直す
   - 毎月、一時ファイルと、ごみ箱に 30 日を超えて置いたファイルを消す。ダウンロード フォルダーは消さない
   - **注意**: OneDrive にサインインしているなら、30 日開かないファイルがオンラインだけになりうる。この項の手順 12 で外す

1. この項の手順 11 を行ったときだけ、ストレージ センサーの画面で値を確かめ、OneDrive を外す。

   ```powershell
   Start-Process 'ms-settings:storagepolicies'
   ```

   - 「ユーザー コンテンツの自動クリーンアップ」がオン、「ストレージ センサーを実行するタイミング」が「毎月」、ごみ箱が「30 日」、ダウンロード フォルダーが「許可しない」ならよい
   - 「ローカルで利用可能なクラウド コンテンツ」に OneDrive があれば、「許可しない」にする
   - ごみ箱を置き場に使っているなら、ごみ箱を「許可しない」にする
   - 値が出ていなければ、この項の手順 13 でサインインし直した後に、もう一度開いて確かめる
   - **次の手順は、設定を閉じてから行う**

1. サインアウトして、同じユーザーでサインインし直す。

   - スタートメニューのユーザーのアイコンから「サインアウト」を選ぶ（スタートメニューの電源から再起動してもよい）
   - **次の手順は、サインインし、この項の手順 1 と同じ方法で管理者ではない窓を開いてから貼る**

1. 設定の視覚効果の画面を開き、変わったことを確かめる。

   ```powershell
   Start-Process 'ms-settings:easeofaccess-visualeffects'
   ```

   - 「アニメーション効果」がオフ。オンと出たら、この画面でオフにする
   - Shift を 5 回押しても、固定キー機能をオンにするかを聞く窓が出ない
   - Alt+Shift・Ctrl+Shift を押して離しても、タスクバーの言語の表示が変わらない
   - Edge でタブを 2 つ以上開いて Alt+Tab を押すと、Edge は窓ごとに 1 つだけ並ぶ
   - エクスプローラーの左の一覧に「ギャラリー」と「ホーム」が無い（「すべてのフォルダーを表示」がオフのとき）
   - タスクバーのアプリを右クリックすると「タスクの終了」がある
   - エラーや通知の効果音が鳴らない
   - 行わなかった手順のものは、元のまま
   - **次の手順は、設定を閉じてから貼る**

#### 表示・入力・音・ストレージを元に戻す

- 変更した表示・入力・音・ストレージの設定を元に戻す
- 前提: [表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)で戻す設定を変更済み。控えのファイルを同じユーザーのまま残してある
- 実行場所: 管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）
   - 窓の名前に「管理者:」が付いていないことを確かめる

1. 元に戻すときは（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 3 を行ったとき）、固定キーなどのショートカットを有効に戻す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   foreach ($k in 'StickyKeys', 'Keyboard Response', 'ToggleKeys') {
     $p = "HKCU:\Control Panel\Accessibility\$k"
     $v = (Get-ItemProperty -LiteralPath $p -ErrorAction SilentlyContinue).Flags
     if ($null -eq $v -or $v -notmatch '^[0-9]+$') { "無い: $k" } else {
       Set-ItemProperty -LiteralPath $p -Name Flags -Type String -Value ([string]([int]$v -bor 4))
       '{0}: {1} -> {2}' -f $k, $v, (Get-ItemProperty -LiteralPath $p).Flags
     }
   }
   ```

   - `StickyKeys: 506 -> 510` の形で出ればよい
   - 効くのは、サインインし直した後

1. 元に戻すときは（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 4 を行ったとき）、切り替えのキーを控えた値に戻す。

   ```powershell
   & {
     $t = 'HKCU:\Keyboard Layout\Toggle'
     $rec = Join-Path $env:LOCALAPPDATA 'setup-notes\display-before.csv'
     $before = @{}
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (Test-Path -LiteralPath $rec) { Import-Csv -LiteralPath $rec | ForEach-Object { $before[$_.Name] = $_.Value } } else { "控えが無い（既定の値にする）: $rec" }
     $def = [ordered]@{ 'Hotkey' = '1'; 'Language Hotkey' = '1'; 'Layout Hotkey' = '2' }
     if (-not (Test-Path -LiteralPath $t)) { New-Item -Path $t -Force | Out-Null }
     foreach ($n in $def.Keys) {
       $v = if ($before[$n] -match '^[1-4]$') { $before[$n] } else { $def[$n] }
       Set-ItemProperty -LiteralPath $t -Name $n -Type String -Value $v
       '{0}: {1}' -f $n, (Get-ItemProperty -LiteralPath $t).$n
     }
   }
   ```

   - 3 行に、[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 2 で控えた値が出ればよい（控えが無いか空なら、既定とされる `1`・`1`・`2`）
   - 効くのは、サインインし直した後
   - 画面で戻すなら、設定の「時刻と言語」→「入力」→「キーボードの詳細設定」の「入力言語のホットキー」

1. 元に戻すときは（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 5 を行ったとき）、Alt+Tab とシェイクの値を控えた値に戻す。

   ```powershell
   & {
     $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
     $rec = Join-Path $env:LOCALAPPDATA 'setup-notes\display-before.csv'
     $before = @{}
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (Test-Path -LiteralPath $rec) { Import-Csv -LiteralPath $rec | ForEach-Object { $before[$_.Name] = $_.Value } } else { "控えが無い（値を消す）: $rec" }
     foreach ($n in 'MultiTaskingAltTabFilter', 'DisallowShaking') {
       if ($before[$n] -match '^[0-9]+$') { Set-ItemProperty -Path $adv -Name $n -Type DWord -Value ([int]$before[$n]) } else { Remove-ItemProperty -Path $adv -Name $n -ErrorAction SilentlyContinue }
     }
     Get-ItemProperty -Path $adv | Format-List MultiTaskingAltTabFilter, DisallowShaking
   }
   ```

   - 2 つに控えた値が出るか、控えで空だったものが空（既定）になればよい
   - 効くのは、サインインし直した後

1. 元に戻すときは（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 6 を行ったとき）、ギャラリーとホームを戻す。

   ```powershell
   & {
     $rec = Join-Path $env:LOCALAPPDATA 'setup-notes\display-before.csv'
     $before = @{}
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (Test-Path -LiteralPath $rec) { Import-Csv -LiteralPath $rec | ForEach-Object { $before[$_.Name] = $_.Value } } else { "控えが無い（値だけ消す）: $rec" }
     foreach ($g in '{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}', '{f874310e-b6b7-47dc-bc84-b9e6b38f5903}') {
       if ($before[$g] -eq 'False') { reg.exe delete "HKCU\Software\Classes\CLSID\$g" /f } else { reg.exe delete "HKCU\Software\Classes\CLSID\$g" /v System.IsPinnedToNameSpaceTree /f }
       '残っている {0}: {1}' -f $g, (Test-Path -LiteralPath "HKCU:\Software\Classes\CLSID\$g")
     }
   }
   ```

   - キーごとに、成功の 1 行と `残っている` の行が出ればよい
   - 効くのは、エクスプローラーの窓をすべて閉じて開き直した後

1. 元に戻すときは（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 7 を行ったとき）、「タスクの終了」の値を控えた値に戻す。

   ```powershell
   & {
     $k = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings'
     $rec = Join-Path $env:LOCALAPPDATA 'setup-notes\display-before.csv'
     $before = @{}
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (Test-Path -LiteralPath $rec) { Import-Csv -LiteralPath $rec | ForEach-Object { $before[$_.Name] = $_.Value } } else { "控えが無い（値を消す）: $rec" }
     if ($before['TaskbarEndTask'] -match '^[0-9]+$') { Set-ItemProperty -LiteralPath $k -Name TaskbarEndTask -Type DWord -Value ([int]$before['TaskbarEndTask']) } else { Remove-ItemProperty -LiteralPath $k -Name TaskbarEndTask -ErrorAction SilentlyContinue }
     Get-ItemProperty -LiteralPath $k -ErrorAction SilentlyContinue | Format-List TaskbarEndTask
   }
   ```

   - 控えた値が出るか、控えで空なら何も出なければよい（値が無いとオフ）

1. 元に戻すときは（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 8 を行ったとき）、アニメーション効果を戻す。

   ```powershell
   & {
     Add-Type -Namespace SetupNotes -Name Spi -MemberDefinition @'
   [StructLayout(LayoutKind.Sequential)] public struct ANIMATIONINFO { public uint cbSize; public int iMinAnimate; }
   [DllImport("user32.dll", SetLastError = true)] public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
   [DllImport("user32.dll", SetLastError = true)] public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, ref int pvParam, uint fWinIni);
   [DllImport("user32.dll", SetLastError = true)] public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, ref ANIMATIONINFO pvParam, uint fWinIni);
   '@
     $f = 3   # SPIF_UPDATEINIFILE (1) + SPIF_SENDCHANGE (2)
     [void][SetupNotes.Spi]::SystemParametersInfo(0x1043, 0, [IntPtr]1, $f)   # SPI_SETCLIENTAREAANIMATION: TRUE
     $ai = New-Object 'SetupNotes.Spi+ANIMATIONINFO'
     $ai.cbSize = 8
     $ai.iMinAnimate = 1
     [void][SetupNotes.Spi]::SystemParametersInfo(0x0049, 8, [ref]$ai, $f)   # SPI_SETANIMATION
     $on = 0
     [void][SetupNotes.Spi]::SystemParametersInfo(0x1042, 0, [ref]$on, 0)   # SPI_GETCLIENTAREAANIMATION
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'ClientAreaAnimation : {0}' -f $on
     'MinAnimate          : {0}' -f (Get-ItemProperty -LiteralPath 'HKCU:\Control Panel\Desktop\WindowMetrics').MinAnimate
   }
   ```

   - `ClientAreaAnimation : 1` と `MinAnimate : 1` が出ればよい（すぐに効く）
   - 設定の「アクセシビリティ」→「視覚効果」の「アニメーション効果」をオンにしてもよい

1. 元に戻すときは（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 9 を行ったとき）、控えた効果音の設定を書き戻す。

   ```powershell
   & {
     $bak = Join-Path $env:LOCALAPPDATA 'setup-notes\appevents.reg'
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (-not (Test-Path -LiteralPath $bak)) { Write-Error "中断: 控えが無い: $bak"; return }
     reg.exe import $bak
     'Scheme : {0}' -f (Get-ItemProperty -Path 'HKCU:\AppEvents\Schemes').'(default)'
   }
   ```

   - 成功の 1 行と、控えたときのスキーム（ふつうは `.Default`）が出ればよい
   - `中断: 控えが無い` が出たら、サウンドの画面（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 10 と同じ）の「サウンド設定」を「Windows 標準」にする
   - 控えのファイルは残る。要らなければ手で消す

1. 元に戻すときは（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 10 を行ったとき）、サウンドの画面で起動音を戻す。

   ```powershell
   control.exe 'mmsys.cpl,,2'
   ```

   - 「Windows スタートアップのサウンドを再生する」にチェックを入れ、「OK」を押す
   - **次の手順は、サウンドの画面を閉じてから貼る**

1. 元に戻すときは（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 11 を行ったとき）、ストレージ センサーの値を消す。

   ```powershell
   $k = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'
   foreach ($n in '01', '04', '08', '256', '32', '512', '2048') { Remove-ItemProperty -LiteralPath $k -Name $n -ErrorAction SilentlyContinue }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -LiteralPath $k -ErrorAction SilentlyContinue | Format-List '01', '04', '08', '256', '32', '512', '2048'
   ```

   - 7 つが空ならよい。ストレージ センサーはオフに戻る
   - [表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 11 の `->` の左に数があったなら、設定の「ストレージ センサー」で同じにし直す
   - [表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 12 で OneDrive やごみ箱を変えたなら、同じ画面で戻す

---

### 自動起動と標準アプリ

- 不要な自動起動・標準アプリ・ウィジェットを外す
- 前提: [表示と入力](#表示と入力)を通してある
- 実行場所: 管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）
   - 窓の名前に「管理者:」が付いていないことを確かめる

1. 自動で起動するアプリのうち、OneDrive・Edge・Teams を止める。

   ```powershell
   & {
     $run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
     $ok = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
     if (-not (Test-Path -LiteralPath $ok)) { New-Item -Path $ok -Force | Out-Null }
     $names = (Get-Item -LiteralPath $run).Property | Where-Object { $_ -eq 'OneDrive' -or $_ -eq 'OneDriveSetup' -or $_ -like 'MicrosoftEdgeAutoLaunch_*' }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($n in $names) {
       Set-ItemProperty -LiteralPath $ok -Name $n -Type Binary -Value ([byte[]](3, 0, 0, 0) + [BitConverter]::GetBytes((Get-Date).ToFileTime()))
       "止めた: $n"
     }
     $teams = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData\MSTeams_8wekyb3d8bbwe\TeamsTfwStartupTask'
     if (Test-Path -LiteralPath $teams) { Set-ItemProperty -LiteralPath $teams -Name State -Type DWord -Value 1; '止めた: Teams' }
     (Get-Item -LiteralPath $run).Property | ForEach-Object { $b = (Get-ItemProperty -LiteralPath $ok -ErrorAction SilentlyContinue).$_; '{0}: {1}' -f $_, $(if ($b -and $b[0] -ne 2) { '止めている' } else { '起動する' }) }
   }
   ```

   - `止めた: OneDrive` などと、`Run` にあるアプリごとに `止めている` か `起動する` が出ればよい
   - 無いものは何もしない（Edge の行は、Edge の設定によっては無い）
   - `WingetUI: 起動する` は UniGet UI。止めるなら、タスク マネージャーの「スタートアップ アプリ」で無効にする
   - 効くのは、次のサインインから

1. 要らない標準アプリを、自分のユーザーから外す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   foreach ($n in 'Clipchamp.Clipchamp', 'Microsoft.BingNews', 'Microsoft.BingWeather', 'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.MicrosoftOfficeHub', 'Microsoft.Todos', 'Microsoft.WindowsFeedbackHub', 'Microsoft.GetHelp', 'Microsoft.OutlookForWindows', 'MSTeams', 'Microsoft.PowerAutomateDesktop') {
     $p = Get-AppxPackage -Name $n
     if ($p) { $p | Remove-AppxPackage; "外した: $n" } else { "無い: $n" }
   }
   ```

   - 11 個のアプリごとに `外した:` か `無い:` が出ればよい
   - 赤い字のエラーが出たアプリは、外せなかった（動いていれば閉じて貼り直す）
   - 機能の更新（Windows の大きな更新）の後に、戻ってくることがある。そのときはこの手順を貼り直す

1. ウィジェット（Windows Web Experience Pack）を外す。

   ```powershell
   $p = Get-AppxPackage -Name MicrosoftWindows.Client.WebExperience
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if ($p) { $p | Remove-AppxPackage; '外した: MicrosoftWindows.Client.WebExperience' } else { '無い: MicrosoftWindows.Client.WebExperience' }
   ```

   - `外した:` か `無い:` が出ればよい
   - タスクバーのウィジェットのボタンと、設定のウィジェットの切り替えが消える（[WSL と再起動](#wsl-と再起動)の手順 3 の再起動の後に確かめる）

---

### HackGen Console NF

- HackGen Console NF を自分のユーザーのフォントに入れる
- 前提: 無し
- 実行場所: 管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）
   - 窓の名前に「管理者:」が付いていないことを確かめる

1. HackGen がまだ入っていないことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Item -LiteralPath 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' -ErrorAction SilentlyContinue | ForEach-Object { $_.Property -like 'HackGen*' }
   Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts", "$env:WINDIR\Fonts" -Filter 'HackGen*' -ErrorAction SilentlyContinue | Format-Table Name, DirectoryName
   ```

   - どちらも何も出なければ、入っていない
   - `C:\Windows\Fonts` のファイルが出たら、PC 全体に入っている（ほかの方法で入れたもの）。この項は要らない

1. HackGen Console NF の zip を取り、sha256 を確かめて自分のユーザーのフォントに入れる。

   ```powershell
   & {
     $ver = '2.10.0'
     $sha256 = 'F8ABD483D5EDFAD88A78ED511978F43C83B43C48E364AA29EBE4A68217474428'
     $fonts = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
     $key = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
     $tmp = "$env:TEMP\hackgen-setup"
     $zip = "$tmp\HackGen_NF_v$ver.zip"
     Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
     New-Item -ItemType Directory -Path $tmp | Out-Null
     & "$env:WINDIR\System32\curl.exe" -fsSL -o $zip "https://github.com/yuru7/HackGen/releases/download/v$ver/HackGen_NF_v$ver.zip"
     if ($LASTEXITCODE -ne 0) { Write-Error "中断: HackGen_NF_v$ver.zip を取れない"; return }
     if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -ne $sha256) { Write-Error "中断: HackGen_NF_v$ver.zip の sha256 が一致しない"; return }
     Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force
     $ttf = @(Get-ChildItem -LiteralPath "$tmp\HackGen_NF_v$ver" -Filter '*.ttf')
     if ($ttf.Count -ne 4) { Write-Error "中断: zip の中の ttf が 4 つではない（$($ttf.Count)）"; return }
     New-Item -ItemType Directory -Force -Path $fonts | Out-Null
     icacls.exe $fonts /grant '*S-1-15-2-1:(OI)(CI)(RX)' '*S-1-15-2-2:(OI)(CI)(RX)' | Out-Null
     if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key | Out-Null }
     foreach ($f in $ttf) {
       $dst = Join-Path $fonts $f.Name
       if (-not (Test-Path -LiteralPath $dst) -or (Get-FileHash -LiteralPath $dst).Hash -ne (Get-FileHash -LiteralPath $f.FullName).Hash) {
         try { Copy-Item -LiteralPath $f.FullName -Destination $dst -Force -ErrorAction Stop } catch { Write-Error "中断: $($f.Name) を置けない（$($_.Exception.Message)）"; return }
       }
       New-ItemProperty -Path $key -Name "$($f.BaseName) (TrueType)" -Value $dst -PropertyType String -Force | Out-Null
     }
     Remove-Item -LiteralPath $tmp -Recurse -Force
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-ItemProperty -LiteralPath $key | Select-Object -Property 'HackGen*' | Format-List
   }
   ```

   - `HackGen35ConsoleNF-Bold (TrueType) : C:\Users\<WIN_USER>\AppData\Local\Microsoft\Windows\Fonts\HackGen35ConsoleNF-Bold.ttf` の形の行が 4 つ出ればよい
   - `中断:` で始まるエラーが出たら、そこで止まっている
   - 何度貼ってもよい
   - アプリで使えるのは、[WSL と再起動](#wsl-と再起動)の手順 3 の再起動の後（確かめるのは[再起動の後に確かめる](#再起動の後に確かめる)の手順 5）

---

### CopyQ を使う

- Windows のクリップボードの履歴を CopyQ に持たせる
- 前提: [Microsoft Store の更新](#microsoft-store-の更新)で winget を用意してある
- 実行場所: 管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

- **この項の手順 3 で CopyQ を起動し、この項の手順 5・6 は画面で行う**
- CopyQ は窓を持つアプリなので、`copyq.exe` のコマンドの結果は、`| Write-Output` を付けないと出ない
- **CopyQ の履歴は、暗号化されずにディスクに残る**。パスワードなどをコピーするときは、[注意点](extra/windows-setup.md#注意点)を読む
- 戻すときは、この項の手順 7・8

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）

1. CopyQ を、自分のユーザーに入れる。

   ```powershell
   winget install --exact --id hluk.CopyQ --source winget --scope user --accept-source-agreements --accept-package-agreements
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget list --exact --id hluk.CopyQ
   ```

   - 最後の表に `CopyQ` と `hluk.CopyQ` の行が出ればよい
   - 管理者の確認（UAC）は出ないはず。winget が、出るかもしれない旨の行を出すことはある

1. CopyQ を起動する。

   ```powershell
   Start-Process -FilePath "$env:LOCALAPPDATA\Programs\CopyQ\copyq.exe"
   ```

   - 窓を待たずに PowerShell に戻り、通知領域（「^」の中のことがある）に CopyQ のアイコンが出る
   - 見つからない旨のエラーが出たら、前に別の場所へ入れた CopyQ がある。この項の手順 7・8 で外してから始め直す
   - **次の手順は、アイコンが出てから貼る**（起動の前に貼ると、サーバーにつながらない旨が出る）

1. サインインのときに CopyQ が起動するようにし、Windows の履歴（Win+V）がオフかを確かめる。

   ```powershell
   & {
     $copyq = "$env:LOCALAPPDATA\Programs\CopyQ\copyq.exe"
     & $copyq config autostart false | Out-Null
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     & $copyq config autostart true | Write-Output
     Test-Path -LiteralPath (Join-Path ([Environment]::GetFolderPath('Startup')) 'copyq.lnk')
     'EnableClipboardHistory: {0}' -f (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Clipboard' -ErrorAction SilentlyContinue).EnableClipboardHistory
   }
   ```

   - `true`・`True`・`EnableClipboardHistory:` の 3 行が出て、最後の右が空か `0` ならよい
   - 最後の右が `1` なら、Windows の履歴もオン。この項の手順 5 で切る。空か `0` なら、この項の手順 5 は飛ばす

1. Windows の履歴がオンだったときだけ、設定の画面で切る。

   ```powershell
   Start-Process 'ms-settings:clipboard'
   ```

   - 「クリップボードの履歴」をオフにする
   - オフでも、Win+V は Windows のパネルを開く。そこで「有効にする」は押さない
   - **次の手順は、設定を閉じてから行う**

1. CopyQ の設定の画面で、窓を開くグローバル ショートカットを割り当てる。

   - 通知領域の CopyQ のアイコンをクリックして窓を開き、「ファイル」→「設定...」（Ctrl+P）→「ショートカット」→「グローバル」で、「メインウィンドウの表示切り替え」にキーを足して「OK」を押す
   - 次のキーは避ける
     - Win+V（Windows の履歴のパネル）
     - Win+Shift+V と Ctrl+Win+Alt+V（[アプリを入れる](#アプリを入れる)の手順 5 の PowerToys の高度な貼り付け）
     - Ctrl+Shift+V（多くのアプリの、書式なしの貼り付け）
     - Ctrl+Space（[表示と入力](#表示と入力)の手順 8 の IME）
   - Windows キーを含むキーは、OS が予約していて効かないことがある。効かなくても、画面には何も出ない
   - 管理者の窓には、CopyQ から自動では貼れない。クリップボードには入るので、右クリックで貼る

1. 元に戻すときは、サインインのときの起動を外し、CopyQ を止める。

   ```powershell
   & {
     $copyq = "$env:LOCALAPPDATA\Programs\CopyQ\copyq.exe"
     $lnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'copyq.lnk'
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     & $copyq config autostart false | Write-Output
     Remove-Item -LiteralPath $lnk -ErrorAction SilentlyContinue
     & $copyq exit | Write-Output
     Test-Path -LiteralPath $lnk
   }
   ```

   - `false` と、最後に `False` が出て、通知領域から CopyQ のアイコンが消えればよい
   - CopyQ が動いていなければ、サーバーにつながらない旨が出る。それでも `copyq.lnk` は消える

1. 元に戻すときは、CopyQ を外す。

   ```powershell
   winget uninstall --exact --id hluk.CopyQ --source winget
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget list --exact --id hluk.CopyQ
   ```

   - 最後に、入っているパッケージが見つからない旨が出ればよい
   - 設定と履歴は残る（`%APPDATA%\copyq`。17.0.0 からは `%LOCALAPPDATA%\copyq` も）。要らなければ手で消す（取り戻せない）
   - この項の手順 5 で Windows の履歴を切ったなら、使うときは設定の「システム」→「クリップボード」でオンに戻す

---

### PowerToys のユーティリティを絞る

- PowerToys の使わないユーティリティを、設定ファイルで切る
- 前提: [アプリを入れる](#アプリを入れる)で PowerToys を入れてある
- 実行場所: 管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

- **この項の手順 4・7 は通知領域で PowerToys を終了し、この項の手順 6 は PowerToys の設定の画面で行う**
- PowerToys は起動のときにだけ設定ファイルを読むので、終了してから書き、起動し直す
- 切るユーティリティは好みで選ぶ。この項の手順 2 の `$PT_OFF` は案で、Always On Top・コマンド パレット・PowerRename・File Locksmith・Peek・エクスプローラーのプレビュー・Image Resizer は残す（[参考資料](reference/windows-setup.md)）
- 「起動時に実行」はオン、「常に管理者として実行」はオフのまま変えない。自動の更新の取得も変えない
- Keyboard Manager は使わない（既定でオフ。Caps Lock は[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 5 で変える）
- 戻すときは、この項の手順 7・8

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）

1. 変数を設定する。

   ```powershell
   $PT_OFF = 'FindMyMouse', 'MouseHighlighter', 'FancyZones', 'ColorPicker', 'Measure Tool', 'Awake'   # 切るユーティリティ（設定ファイルの名前）
   $PT_EXE = @((Get-Process -Name PowerToys -ErrorAction SilentlyContinue).Path) + "$env:LOCALAPPDATA\PowerToys\PowerToys.exe", "$env:LOCALAPPDATA\Programs\PowerToys\PowerToys.exe" | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1   # PowerToys.exe の場所（自動）
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'PT_OFF = {0}' -f ($PT_OFF -join ', ')
   'PT_EXE = {0}' -f $PT_EXE
   ```

   - `PT_OFF = FindMyMouse, …` と、`PT_EXE = C:\Users\<WIN_USER>\AppData\Local\PowerToys\PowerToys.exe` の形の 2 行が出ればよい
   - `PT_EXE` が空なら、PowerToys が見つからない。[アプリを入れる](#アプリを入れる)の手順 5 を確かめる
   - `$PT_OFF` の名前は、設定ファイルの名前（空白を含むものがある）。変えるなら、この項の手順 3 の表の `Name` から選ぶ
   - 新しい窓を開いたら、このブロックを貼り直す

1. 今のユーティリティの有効・無効と、自動の起動を確かめる。

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $path = Join-Path $env:LOCALAPPDATA 'Microsoft\PowerToys\settings.json'
     if (-not (Test-Path -LiteralPath $path)) { Write-Error "中断: 設定ファイルが無い: $path"; return }
     $s = [IO.File]::ReadAllText($path) | ConvertFrom-Json
     $s.enabled.PSObject.Properties | ForEach-Object { [pscustomobject]@{ Name = $_.Name; Enabled = $_.Value; Off = $PT_OFF -contains $_.Name } } | Format-Table -AutoSize
     foreach ($n in $PT_OFF) { if (-not $s.enabled.PSObject.Properties[$n]) { "無い名前: $n" } }
     'startup: {0} / run_elevated: {1}' -f $s.startup, $s.run_elevated
     Get-ScheduledTask -TaskPath '\PowerToys\' -ErrorAction SilentlyContinue | Format-Table TaskName, State
   }
   ```

   - ユーティリティごとの `Name`・`Enabled`・`Off`（`$PT_OFF` にあるか）の表と、`startup: True / run_elevated: False` と、`Autorun for <WIN_USER>` の行が出ればよい
   - `無い名前:` が出たら、その名前は今の版の設定ファイルに無い（版で名前が変わる）。この項の手順 2 の `$PT_OFF` を表の名前に直して貼り直す
   - `startup: False`、Autorun の行が無い、または `run_elevated: True` なら、PowerToys の「全般」で自動起動をオン・管理者起動をオフに戻す
   - `中断: 設定ファイルが無い` が出たら、PowerToys を 1 度起動してから貼り直す

1. 通知領域の PowerToys を右クリックし、「終了」で閉じる。

   - 通知領域（「^」の中のことがある）の PowerToys のアイコンを右クリックし、「終了」を選ぶ。PowerToys の設定の窓も閉じる
   - **次の手順は、アイコンが消えてから貼る**

1. 設定ファイルで `$PT_OFF` のユーティリティを切り、PowerToys を起動し直す。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Microsoft\PowerToys\settings.json'
     $bak = "$path.windows-setup.bak"
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (Get-Process -Name PowerToys, PowerToys.Settings -ErrorAction SilentlyContinue) { Write-Error '中断: PowerToys が動いている。この項の手順 4 で終了してから貼り直す'; return }
     if (-not $PT_EXE) { Write-Error '中断: $PT_EXE が空。スタートメニューから PowerToys を起動し、この項の手順 2 を貼り直してから、この項の手順 4 に戻る'; return }
     try { $s = [IO.File]::ReadAllText($path) | ConvertFrom-Json -ErrorAction Stop } catch { Write-Error "中断: 設定ファイルを読めない: $path"; return }
     if (-not $s.PSObject.Properties['enabled']) { Write-Error "中断: 設定ファイルに enabled が無い: $path"; return }
     $miss = @($PT_OFF | Where-Object { -not $s.enabled.PSObject.Properties[$_] })
     if ($miss.Count) { Write-Error "中断: 設定ファイルに無い名前: $($miss -join ', ')"; return }
     if (Test-Path -LiteralPath $bak) { "控えはもうある（書き換えない）: $bak" } else { Copy-Item -LiteralPath $path -Destination $bak -ErrorAction Stop; "控えた: $bak" }
     foreach ($n in $PT_OFF) { $s.enabled.PSObject.Properties[$n].Value = $false }
     [IO.File]::WriteAllText($path, ($s | ConvertTo-Json -Depth 100), (New-Object System.Text.UTF8Encoding $false))
     $r = [IO.File]::ReadAllText($path) | ConvertFrom-Json
     foreach ($n in $PT_OFF) { '{0}: {1}' -f $n, $r.enabled.$n }
     Start-Process -FilePath $PT_EXE
   }
   ```

   - `控えた:`（2 回目からは `控えはもうある`）の行と、`FindMyMouse: False` の形の行が `$PT_OFF` の数だけ出て、通知領域に PowerToys のアイコンが戻ればよい
   - 控えは `%LOCALAPPDATA%\Microsoft\PowerToys\settings.json.windows-setup.bak`。控えが無いときだけ作る（この項の手順 8 で使い、書き戻すと消える）
   - `中断: PowerToys が動いている` が出たら、この項の手順 4 に戻る（設定の窓が残っていても止まる）

1. PowerToys の設定の画面で、切ったユーティリティがオフになっていることを確かめる。

   - 通知領域の PowerToys のアイコンを右クリックし、「設定」で設定の窓を開く（ダブルクリックでも開く。1 回のクリックで開くのはクイック アクセス）
   - 「ダッシュボード」で、`$PT_OFF` のユーティリティがオフ、残したものがオンになっている
   - 同じことは、ユーティリティごとのスイッチでもできる（すぐに効く）
   - Peek は「Space で開く」をオンのままにする
   - Find My Mouse を使うなら、起動の方法を「マウスを振る」にする
   - Command Not Found の「インストール」を押すと、PowerShell 7 のプロファイルに行が足される（[PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)の印は付かない）
   - 見終わったら、設定の窓を閉じる

1. 元に戻すときは、通知領域の PowerToys を右クリックし、「終了」で閉じる。

   - PowerToys の設定の窓も閉じる
   - **次の手順は、アイコンが消えてから貼る**

1. 元に戻すときは、控えた設定ファイルを書き戻し、PowerToys を起動する。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Microsoft\PowerToys\settings.json'
     $bak = "$path.windows-setup.bak"
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (Get-Process -Name PowerToys, PowerToys.Settings -ErrorAction SilentlyContinue) { Write-Error '中断: PowerToys が動いている。この項の手順 7 で終了してから貼り直す'; return }
     if (-not (Test-Path -LiteralPath $bak)) { Write-Error "中断: 控えが無い: $bak"; return }
     if (-not $PT_EXE) { Write-Error '中断: $PT_EXE が空。スタートメニューから PowerToys を起動し、この項の手順 2 を貼り直してから、この項の手順 7 に戻る'; return }
     Copy-Item -LiteralPath $bak -Destination $path -Force -ErrorAction Stop
     Remove-Item -LiteralPath $bak
     $r = [IO.File]::ReadAllText($path) | ConvertFrom-Json
     foreach ($n in $PT_OFF) { '{0}: {1}' -f $n, $r.enabled.$n }
     Start-Process -FilePath $PT_EXE
   }
   ```

   - `FindMyMouse: True` の形の行（控えたときの値）が出て、通知領域に PowerToys のアイコンが戻ればよい
   - 新しい窓では、先にこの項の手順 2 を貼る
   - 控えた後に画面で変えた PowerToys の設定も、控えたときの値に戻る
   - `中断: 控えが無い` が出たら、スタートメニューから PowerToys を起動し、設定の画面で、切ったユーティリティのスイッチをオンにする
   - 控えのファイルは消える（もう一度この項を通すと、そのときの設定を控え直す）

---

### Windows Terminal のフォントと貼り付けの警告を変える

- Windows Terminal のフォントを HackGen にし、必要なら複数行の貼り付けの警告を切る
- 前提: [HackGen Console NF](#hackgen-console-nf)を通し、サインインし直してある。Windows Terminal が入っている（[Microsoft Store の更新](#microsoft-store-の更新)で更新する）
- 実行場所: 管理者ではない Windows Terminal の Windows PowerShell（5.1）のタブ。この項の手順 1 で開く

- **この項の手順 5 は Windows Terminal の設定の画面で行う**
- 効くのは Windows Terminal で開く窓（管理者ではない窓と、Win+X の「ターミナル」・「ターミナル (管理者)」）だけ。スタートメニューから管理者として開いた PowerShell（conhost の窓）には効かない
- 管理者ではない窓に複数行のブロックを貼ると、「警告」の窓が出ることがある（Windows PowerShell 5.1 は、角かっこで囲む貼り付けを使わないため）。「強制的に貼り付け」を押す（出さないなら、この項の手順 4）
- コマンドで書くのは `settings.json` だけ。既定のプロファイル（Windows PowerShell）と、選んだらコピーする設定（`copyOnSelect`）は変えない
- 戻すときは、この項の手順 6

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows Terminal」を開き、タブのメニューから「Windows PowerShell」を選ぶ（Windows PowerShell 5.1 のタブ）

1. Windows Terminal の設定ファイルを控え、今のフォントと警告の値を確かめる。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     $bak = "$path.windows-setup.bak"
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (-not (Test-Path -LiteralPath $path)) { Write-Error "中断: 設定ファイルが無い。Windows Terminal を 1 度開いてから貼り直す: $path"; return }
     $text = [IO.File]::ReadAllText($path)
     if (($text -replace '"(?:[^"\\]|\\.)*"', '""') -match '/[/*]|,\s*[}\]]') { Write-Error "中断: コメントか末尾のカンマがある。この項の手順 5 の画面で変える: $path"; return }
     try { $s = $text | ConvertFrom-Json -ErrorAction Stop } catch { Write-Error "中断: 読めない。この項の手順 5 の画面で変える: $path"; return }
     if (-not $s.profiles -or $s.profiles -is [array]) { Write-Error '中断: profiles が無いか古い形式（配列）。この項の手順 5 の画面で変える'; return }
     if (Test-Path -LiteralPath $bak) { "控えはもうある（書き換えない）: $bak" } else { Copy-Item -LiteralPath $path -Destination $bak -ErrorAction Stop; "控えた: $bak" }
     [pscustomobject]@{
       Version          = (Get-AppxPackage -Name Microsoft.WindowsTerminal | Select-Object -First 1).Version
       DefaultsFontFace = $s.profiles.defaults.font.face
       MultiLinePaste   = $s.'warning.multiLinePaste'
       DefaultProfile   = $s.defaultProfile
       CopyOnSelect     = $s.copyOnSelect
     } | Format-List
     $s.profiles.list | Where-Object { $_.font.face } | Format-Table name, @{ Name = 'face'; Expression = { $_.font.face } }
   }
   ```

   - `控えた:`（2 回目からは `控えはもうある`）の行と、`Version : 1.25.…` の形の 5 行が出ればよい。`DefaultsFontFace` が空なら、既定のフォント（Cascadia Mono）
   - 控えは `…\LocalState\settings.json.windows-setup.bak`。控えが無いときだけ作る（この項の手順 6 で使い、書き戻すと消える）
   - 最後に表が出たら、そのプロファイルは自分のフォントを持つので、この項の手順 3 の値は効かない（この項の手順 5 の画面で、そのプロファイルを変える）
   - `中断:` が出たら、何も書いていない。この項の手順 5 の画面で変える
   - `Version` が 1.24 より前なら、この項の手順 4 は飛ばす

1. 全プロファイルのフォントを HackGen Console NF にする。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     if (-not (Test-Path -LiteralPath "$path.windows-setup.bak")) { Write-Error '中断: 控えが無い。この項の手順 2 を先に貼る'; return }
     $text = [IO.File]::ReadAllText($path)
     if (($text -replace '"(?:[^"\\]|\\.)*"', '""') -match '/[/*]|,\s*[}\]]') { Write-Error "中断: コメントか末尾のカンマがある: $path"; return }
     try { $s = $text | ConvertFrom-Json -ErrorAction Stop } catch { Write-Error "中断: 読めない: $path"; return }
     if (-not $s.profiles -or $s.profiles -is [array]) { Write-Error '中断: profiles が無いか古い形式（配列）'; return }
     if (-not $s.profiles.PSObject.Properties['defaults']) { $s.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{}) }
     if (-not $s.profiles.defaults.PSObject.Properties['font']) { $s.profiles.defaults | Add-Member -NotePropertyName font -NotePropertyValue ([pscustomobject]@{}) }
     $s.profiles.defaults.font | Add-Member -NotePropertyName face -NotePropertyValue 'HackGen Console NF' -Force
     [IO.File]::WriteAllText($path, ($s | ConvertTo-Json -Depth 100), (New-Object System.Text.UTF8Encoding $false))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'face: {0}' -f ([IO.File]::ReadAllText($path) | ConvertFrom-Json).profiles.defaults.font.face
   }
   ```

   - `face: HackGen Console NF` が出ればよい
   - 保存した直後に、開いているタブにも効く
   - フォントが見つからないと、端末に、フォントが見つからない旨が出て、別のフォントで出る（この項の手順 5 で確かめる）

1. Windows Terminal が 1.24 以降で、複数行を貼るたびに出る警告を出さないときだけ、警告を切る。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     $ver = (Get-AppxPackage -Name Microsoft.WindowsTerminal | Select-Object -First 1).Version
     if (-not $ver -or [version]$ver -lt [version]'1.24') { Write-Error "中断: Windows Terminal の版が 1.24 より前: $ver"; return }
     if (-not (Test-Path -LiteralPath "$path.windows-setup.bak")) { Write-Error '中断: 控えが無い。この項の手順 2 を先に貼る'; return }
     $text = [IO.File]::ReadAllText($path)
     if (($text -replace '"(?:[^"\\]|\\.)*"', '""') -match '/[/*]|,\s*[}\]]') { Write-Error "中断: コメントか末尾のカンマがある: $path"; return }
     try { $s = $text | ConvertFrom-Json -ErrorAction Stop } catch { Write-Error "中断: 読めない: $path"; return }
     $s | Add-Member -NotePropertyName 'warning.multiLinePaste' -NotePropertyValue 'never' -Force
     [IO.File]::WriteAllText($path, ($s | ConvertTo-Json -Depth 100), (New-Object System.Text.UTF8Encoding $false))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'warning.multiLinePaste: {0}' -f ([IO.File]::ReadAllText($path) | ConvertFrom-Json).'warning.multiLinePaste'
   }
   ```

   - `warning.multiLinePaste: never` が出ればよい
   - **注意**: 信用できない複数行の文字も、確かめずにそのまま貼られて動く
   - 5 KiB を超える文字を貼るときは、別の警告が出ることがある

1. Windows Terminal の設定の画面で、フォントが見つかっていることを確かめる。

   - Windows Terminal の窓で Ctrl+, を押し、「既定値」→「外観」の「フォント スタイル」が `HackGen Console NF` で、「見つからないフォント:」が出ていない
   - 新しいタブを開くと、文字が HackGen になっている
   - この項の手順 2〜4 が `中断:` で止まったときは、この画面でフォント スタイルを選んで「保存」を押す（一覧に無ければ「すべてのフォントの表示」をオン）。警告は「操作」の「改行を貼り付ける際に警告する」を「なし」にする
   - **次の手順は、設定の画面を閉じてから貼る**

1. 元に戻すときは、控えた設定ファイルを書き戻す。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     $bak = "$path.windows-setup.bak"
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (-not (Test-Path -LiteralPath $bak)) { Write-Error "中断: 控えが無い: $bak"; return }
     Copy-Item -LiteralPath $bak -Destination $path -Force -ErrorAction Stop
     Remove-Item -LiteralPath $bak
     $s = [IO.File]::ReadAllText($path) | ConvertFrom-Json
     'face: {0} / warning.multiLinePaste: {1}' -f $s.profiles.defaults.font.face, $s.'warning.multiLinePaste'
   }
   ```

   - 控えたときの値（ふつうは 2 つとも空）が出ればよい。開いているタブにもすぐ効く
   - 控えた後に画面で変えた Windows Terminal の設定も、控えたときに戻る。残すなら、このブロックは貼らず、この項の手順 5 の画面でフォント スタイルと警告を戻す
   - `中断: 控えが無い` が出たら、この項の手順 5 の画面で戻す
   - 控えのファイルは消える（もう一度この項を通すと、そのときの設定を控え直す）

---

### Windows のホットキー競合

- 問題が起きるキーを使っているアプリを調べる
- 前提: [初回準備](#windows-のホットキー競合-初回準備)で Hotkey Screener を展開してある
- 実行場所: 問題が起きるユーザー・ログインセッションのデスクトップ（Hotkey Screener）

- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-hotkey-conflict.md)・[参考資料](reference/windows-hotkey-conflict.md)・[ロールバックと注意点](extra/windows-hotkey-conflict.md)

- 問題が起きる Windows 11 のユーザー・ログインセッションで実施する
- 検出時には対象キーが実際に入力され、対応する操作が実行されることもある。先に作業を保存する

- 調べるキーだけ検出する。複数の操作を実行する `Detect All` は使わない

1. Hotkey Screener を起動する。

   - 展開先または配置先の `hkscr64.exe` を開く
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
   - 権限要求が頻発する場合は、[Program Files への配置](#windows-のホットキー競合-権限要求を減らすために-program-files-へ配置する)を行う

1. 表示された使用アプリを確認する。

   - 対象行の `Application` 列に出た実行ファイル名と PID を控える
   - 名前だけで分からなければ、[切り分けの手順 4](#windows-のホットキー競合-使用アプリが分からない場合の切り分け)で PID と実行パスを照合する
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
   - 書き方は[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-hotkey-conflict.md)を参照する

#### Windows のホットキー競合: 初回準備

- Hotkey Screener の ZIP を取得・展開し、署名を確かめる
- 前提: 無し
- 実行場所: Windows のブラウザ・エクスプローラー

- ZIP の取得と展開は初回だけ行う。更新する場合はツールを終了してから行う

- 検証した版とファイル構成は[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-hotkey-conflict.md)を参照する
- 権限要求が頻発する場合は、[Program Files への配置](#windows-のホットキー競合-権限要求を減らすために-program-files-へ配置する)も行う

1. 公式サイトから Hotkey Screener の ZIP をダウンロードする。

   - [Hotkey Screener の公式ページ](https://www.ntwind.com/freeware/hotkey-screener.html)を開き、ダウンロードリンクから `HotkeyScreener.zip` を保存する
   - 保存先はダウンロードフォルダーなど、自分で書き込める場所にする

1. ZIP の全ファイルを同じフォルダーへ展開する。

   - ZIP を右クリックして「すべて展開」を選ぶ
   - EXE と DLL を一緒に残す。ZIP 内から直接 EXE を開かない
   - 検証版には `hkscr.exe`・`hkscr64.exe`・`hkscr.dll`・`hkscr64.dll`・`ReadMe.txt` が含まれる

1. 実行ファイルのデジタル署名を確認する。

   - EXE の「プロパティ → デジタル署名」で NTWIND LLC の署名を確認する
   - Windows 11 では 64 ビット版の `hkscr64.exe` を使う
   - [Windows のホットキー競合](#windows-のホットキー競合)の手順 1へ進む

#### Windows のホットキー競合: 権限要求を減らすために Program Files へ配置する

- 展開した Hotkey Screener を Program Files に配置する
- 前提: [初回準備](#windows-のホットキー競合-初回準備)で展開し、署名を確かめてある
- 実行場所: Windows のエクスプローラー。コピー時に権限確認が出たら承認する

- 検出時の権限要求が頻発する場合だけ行う
- フォルダー作成・コピーで Windows の権限確認が出たら、自分で内容を確認して承認する
- 管理された PC で配置権限がない場合は管理者へ相談する。Windows の保護設定は変更しない

1. 起動中の Hotkey Screener を終了する。

   - `Command → Exit` または閉じるボタンで終了する

1. Program Files の下に配置先フォルダーを作成する。

   - エクスプローラーで `C:\Program Files` を開き、`Hotkey Screener` フォルダーを作る
   - Windows が別ドライブにある場合は、その環境の `%ProgramFiles%` を使う

1. 展開した EXE と DLL を配置先へコピーする。

   - `hkscr.exe`・`hkscr64.exe`・`hkscr.dll`・`hkscr64.dll` をすべて同じフォルダーへコピーする
   - コピー先は `C:\Program Files\Hotkey Screener`。元の展開先にあるファイルも残せる

1. 配置先の実行ファイルから起動し直す。

   - `C:\Program Files\Hotkey Screener\hkscr64.exe` を開く
   - [Windows のホットキー競合](#windows-のホットキー競合)の手順 2へ戻り、対象キーだけ検出する

#### Windows のホットキー競合: 使用アプリが分からない場合の切り分け

- 入力条件と候補アプリを一つずつ変えて、ホットキーの問題を切り分ける
- 前提: [Windows のホットキー競合](#windows-のホットキー競合)で検出を試してある
- 実行場所: 問題が起きるユーザー・ログインセッションのデスクトップと、通常権限の Windows PowerShell（5.1）。この項の手順 1 で開く

- 対象キーが一覧にない場合、検出でアプリが表示されない場合、設定変更で解消しない場合に行う
- 表示がない理由と、入力フック・アプリ内ショートカットの検出範囲は[参考資料](reference/windows-hotkey-conflict.md)を参照する

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）
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

   - 解消しなければ候補の設定を元に戻し、終了した候補を通常起動してから、この項の手順 6で次の候補を調べる
   - 解消した場合は[Windows のホットキー競合](#windows-のホットキー競合)の手順 5 で必要な設定と保存状態を確認し、同じ項の手順 6 で結果を残して終了する
   - 特定できない場合は、[ホットキーの登録可否を確認する](#windows-のホットキー競合-ホットキーの登録可否を確認する)も使い、試した入力条件・候補・ログを追加調査用に残す

#### Windows のホットキー競合: ホットキーの登録可否を確認する

- 対象キーを一時登録して、登録できるかを確かめる
- 前提: [使用アプリが分からない場合の切り分け](#windows-のホットキー競合-使用アプリが分からない場合の切り分け)で対象キーを絞ってある
- 実行場所: 問題が起きるユーザー・ログインセッションの、新しい通常権限の Windows PowerShell（5.1）。この項の手順 1 で開く

- アプリ名を返す試験ではない。登録成功でも、IME や入力フックによる処理は除外できない

- 試験中だけ対象キーを一時登録し、直ちに解除する。コードの実行中は対象キーを押さない

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）
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

---

### 再起動の後に確かめる

- 通した項の設定が再起動後にも効いていることを画面で確かめる
- 前提: [サインイン・検索・キーボード](#サインイン検索キーボード)・[表示と入力](#表示と入力)・[自動起動と標準アプリ](#自動起動と標準アプリ)・[アプリを入れる](#アプリを入れる)・[HackGen Console NF](#hackgen-console-nf)のうち、確かめたい項を通し、再起動してサインインしてある
- 実行場所: この PC のデスクトップ（メモ帳・エクスプローラー・設定・UniGet UI）

1. キーボードで、Caps Lock・Ctrl+Space・配列を確かめる。

   - メモ帳を開いて何か打ち、Caps Lock を押したまま A を押すと、全部が選ばれる（Ctrl+A）（[サインイン・検索・キーボード](#サインイン検索キーボード)を通したとき）
   - Caps Lock だけを押しても、Caps Lock のランプは点かず、大文字にもならない（[サインイン・検索・キーボード](#サインイン検索キーボード)を通したとき）
   - 日本語の配列（JIS）のキーボードでは、「英数」（Caps Lock）のキーが Ctrl になる（[サインイン・検索・キーボード](#サインイン検索キーボード)を通したとき）
   - Ctrl+Space を押すたびに、IME のオンとオフが入れ替わる（タスクバーの「あ」と「A」）（[表示と入力](#表示と入力)を通したとき）
   - [サインイン・検索・キーボード](#サインイン検索キーボード)の手順 7 を行ったなら、記号が US 配列の位置で出る（Shift+2 で `@`）

1. エクスプローラー・タスクバー・スタートが変わったことを確かめる。

   - ファイルかデスクトップを右クリックすると、「その他のオプションを確認」を選ばなくても、「送る」「プロパティ」などの並ぶ旧形式のメニューが出る（[表示と入力](#表示と入力)を通したとき）
   - エクスプローラーを開くと「PC」が出て、ファイル名に拡張子が付き、隠しファイルも見える（[表示と入力](#表示と入力)を通したとき）
   - タスクバーのアイコンが左に寄り、タスク ビュー・検索のボタンが無く、時計に秒が出る。全体が濃い色になっている（[表示と入力](#表示と入力)を通したとき）
   - タスクバーにウィジェットのボタンが無い（[自動起動と標準アプリ](#自動起動と標準アプリ)を通したとき）
   - スタートを開いて文字を打っても、Web（Bing）の結果が出ない（[サインイン・検索・キーボード](#サインイン検索キーボード)を通したとき）
   - デスクトップに Edge と UniGet UI のショートカットが無い（[サインイン・検索・キーボード](#サインイン検索キーボード)を通したとき）

1. タスクバーとスタートの、要らないピン留めを外す。

   - タスクバーのアイコン（Microsoft Edge・Microsoft Store など）を右クリックし、「タスクバーからピン留めを外す」
   - スタートを開き、ピン留めされたアプリを右クリックし、「スタートからピン留めを外す」
   - Copilot は外さない。使うアプリは残す

1. [アプリを入れる](#アプリを入れる)を通したときだけ、UniGet UI を起動し、WinGet と Scoop が使えることを確かめる。

   - スタートメニューで「UniGetUI」を探して開く
   - 初回は、使い方の案内や設定の問いが出ることがある。読んで進める
   - 左の「パッケージマネージャー」で、WinGet と Scoop が有効で「利用可能」になっていることを確かめる（版は、それぞれの「バージョンを表示」で出る）（[アプリを入れる](#アプリを入れる)を通したとき）
   - 「インストール済みのパッケージ」に、[アプリを入れる](#アプリを入れる)の手順 4 で scoop で入れた `scoop-search` と、winget の `UniGetUI` などが出る（[アプリを入れる](#アプリを入れる)を通したとき）

1. [HackGen Console NF](#hackgen-console-nf)を通したときだけ、フォントの一覧で、HackGen Console NF が出ることを確かめる。

   - 設定 → 個人用設定 → フォント を開き、「HackGen」で探すと、`HackGen Console NF` と `HackGen35 Console NF` が出る（どちらも「2 フォント フェイス」）（[HackGen Console NF](#hackgen-console-nf)を通したとき）
   - ライセンス認証していない Windows では、フォントの画面の検索欄が使えないことがある。そのときは一覧をスクロールして探す
   - メモ帳のフォントの一覧に出ても同じ
   - 端末のフォントにするなら、アプリの設定にファミリー名 `HackGen Console NF` を書く（WezTerm は `config.font = wezterm.font 'HackGen Console NF'`。自分用の設定（`ryo-aoki-pc/wezterm`）は、もうこのフォントを使う）

---

## ネットワークとリモート操作

- LAN とリモート デスクトップ、WSL のネットワーク、Wake on LAN、リモートからの再起動、RDP の切断、WireGuard

### ネットワークとリモート

- LAN をプライベートにし、RDP・ping・配信の最適化を設定する
- 前提: 設定する LAN が接続されている
- 実行場所: 管理者の Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、右クリック →「管理者として実行」を選ぶ
   - UAC の確認で「はい」を押す。窓の名前が「管理者: Windows PowerShell」になる

1. 変数を設定する。

   ```powershell
   $LAN_IF = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).InterfaceAlias   # ほかの PC とつながる LAN の接続（自動）。<LAN_IF>
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'LAN_IF = {0}' -f $LAN_IF
   ```

   - `LAN_IF` が空か対象の LAN と違えば、`$LAN_IF = 'イーサネット'` のように接続名を入れる
   - **新しい PowerShell を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. LAN の接続をプライベートにする。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error '中断: この項の手順 2 の $LAN_IF が空'
   } else {
     Set-NetConnectionProfile -InterfaceAlias $LAN_IF -NetworkCategory Private
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-NetConnectionProfile -InterfaceAlias $LAN_IF | Format-Table InterfaceAlias, NetworkCategory
   }
   ```

   - `<LAN_IF>  Private` が出ればよい
   - **注意**: プライベート向けのほかの許可の規則（ネットワーク探索など）も、この LAN で効くようになる

1. Pro 以上のときだけ、リモート デスクトップを有効にし、受け付けるのをプライベートの LAN に絞る。

   ```powershell
   $ed = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').EditionID
   if ($ed -like 'Core*') { Write-Error "中断: Home（$ed）は、リモート デスクトップでつながれる側になれない" } else {
     Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Type DWord -Value 0
     Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Type DWord -Value 1
     Set-NetFirewallRule -Group '@FirewallAPI.dll,-28752' -Enabled True -Profile Private
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-NetFirewallRule -Group '@FirewallAPI.dll,-28752' | Format-Table Name, Enabled, Profile, Direction, Action
   }
   ```

   - `RemoteDesktop-UserMode-In-TCP` などの行が `True  Private  Inbound  Allow` で出ればよい
   - Home なら、この手順は飛ばす（ブロック自身もエディションを調べ、`中断:` で止まる）

1. リモート アシスタンスを切る。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance' -Name fAllowToGetHelp -Type DWord -Value 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Set-NetFirewallRule -Group '@FirewallAPI.dll,-33002' -Enabled False
   Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance' | Format-List fAllowToGetHelp
   Get-NetFirewallRule -Group '@FirewallAPI.dll,-33002' | Format-Table Name, Enabled, Profile
   ```

   - `fAllowToGetHelp : 0` と、リモート アシスタンスの規則が `False` で並べばよい
   - `Set-NetFirewallRule` が規則が見つからない旨のエラーを出したら、グループの ID が違う

1. プライベートの LAN からの ping（ICMP のエコー要求）に応える規則を作る。

   ```powershell
   $g = 'Ping (setup-notes)'
   Remove-NetFirewallRule -Group $g -ErrorAction SilentlyContinue
   New-NetFirewallRule -Name 'Ping-ICMPv4-In-setup-notes' -DisplayName 'Ping (ICMPv4 エコー要求)' -Group $g -Direction Inbound -Action Allow -Profile Private -Protocol ICMPv4 -IcmpType 8 | Out-Null
   New-NetFirewallRule -Name 'Ping-ICMPv6-In-setup-notes' -DisplayName 'Ping (ICMPv6 エコー要求)' -Group $g -Direction Inbound -Action Allow -Profile Private -Protocol ICMPv6 -IcmpType 128 | Out-Null
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-NetFirewallRule -Group $g | Format-Table Name, Enabled, Profile, Direction, Action
   ```

   - 2 つの規則が `True  Private  Inbound  Allow` で出ればよい
   - 何度貼ってもよい
   - LAN の別の PC から、この PC の IP アドレスへ ping が通るようになる

1. 配信の最適化を、LAN の PC とだけ共有するようにする。

   ```powershell
   Set-DODownloadMode -DownloadMode Lan
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-DODownloadMode
   ```

   - `Lan` が出ればよい

---

### WSL のネットワークをミラーにする

- WSL 2 のネットワークを、Windows と同じ IP を使うミラーに変える
- 前提: [WSL と再起動](#wsl-と再起動)と[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)で WSL 2 の AlmaLinux 10 を導入済み。Windows の SSH を確かめるときは[OpenSSH サーバー](#openssh-サーバー)を通してある
- 実行場所: 管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

- **この項の手順 4・7 の `wsl.exe --shutdown` は、動いているディストリビューションをすべて止める**（WezTerm の WSL のタブも切れる）。WSL の中の作業を保存してから貼る
- ミラーにして変わること
  - WSL からこの PC の Windows のサーバー（[OpenSSH サーバー](#openssh-サーバー)など）には、`127.0.0.1` でつなぐ（`::1` は使えない。LAN の IP あてはつながらないはず）
  - Windows が使っているポートは、WSL の中では使えない。Windows の sshd が 22 番で待っていると、WSL の中の sshd は 22 番を使えない
  - Docker のポートの公開と、一部の VPN には、既知の問題がある（[参考資料](reference/windows-setup.md)）
- 書くのは `networkingMode` だけ。DNS・ファイアウォール・プロキシ・メモリの値は既定のまま。LAN から WSL の中のサーバーに入るための Hyper-V のファイアウォールの規則は、この項では作らない
- 画面で変えるなら、スタートメニューの「Linux 用 Windows サブシステム設定」→「ネットワーク」→「ネットワーク モード」（同じファイルに書く）
- 戻すときは、この項の手順 6・7

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）

1. 今の `.wslconfig` と、WSL の版と、動いているディストリビューションを確かめる。

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $env:WSL_UTF8 = '1'
     $p = Join-Path $env:USERPROFILE '.wslconfig'
     if (Test-Path -LiteralPath $p) { "--- $p"; [IO.File]::ReadAllText($p) } else { "無い: $p" }
     wsl.exe --version
     wsl.exe --list --running
   }
   ```

   - `無い:` か、`.wslconfig` の中身が出る
   - `wsl.exe --version` が、WSL の版（`2.…` の形）を出せばよい
   - 最後に、動いているディストリビューションが出る（無ければ、無い旨の行）。この項の手順 4 で止まる
   - 中身の `[wsl2]` に `networkingMode=mirrored` があれば、もうミラー。この項の手順 3 は飛ばす

1. ミラーになっていないときだけ、`.wslconfig` に、ネットワークをミラーにする行を書く（ファイルがあれば控える）。

   ```powershell
   & {
     $path = Join-Path $env:USERPROFILE '.wslconfig'
     $bak = "$path.windows-setup.bak"
     $enc = New-Object System.Text.UTF8Encoding $false
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (-not (Test-Path -LiteralPath $path)) {
       [IO.File]::WriteAllText($path, "[wsl2]`r`nnetworkingMode=mirrored`r`n", $enc)
       "作った: $path"
     } else {
       $text = [IO.File]::ReadAllText($path)
       if ($text -match '(?im)^[ \t]*networkingMode[ \t]*=') { Write-Error "中断: networkingMode の行がもうある。手で直すか、設定の画面で変える: $path"; return }
       if (Test-Path -LiteralPath $bak) { "控えはもうある（書き換えない）: $bak" } else { Copy-Item -LiteralPath $path -Destination $bak -ErrorAction Stop; "控えた: $bak" }
       $nl = if ($text.Contains("`n") -and -not $text.Contains("`r`n")) { "`n" } else { "`r`n" }
       $re = [regex]'(?im)^([ \t]*\[wsl2\][ \t]*)(?=\r?$)'
       if ($re.IsMatch($text)) { $text = $re.Replace($text, '$1' + $nl + 'networkingMode=mirrored', 1) } else {
         if ($text -and -not $text.EndsWith("`n")) { $text += $nl }
         $text += '[wsl2]' + $nl + 'networkingMode=mirrored' + $nl
       }
       [IO.File]::WriteAllText($path, $text, $enc)
       "足した: $path"
     }
     [IO.File]::ReadAllText($path)
   }
   ```

   - `作った:` か `足した:` の行（ファイルがあったときは、その前に `控えた:`）と、`[wsl2]` の次の行が `networkingMode=mirrored` の中身が出ればよい
   - 控えは `%USERPROFILE%\.wslconfig.windows-setup.bak`。ファイルがあって、控えが無いときだけ作る（この項の手順 6 で使い、戻すと消える）
   - `中断: networkingMode の行がもうある` が出たら、何も書いていない。その行を手で `networkingMode=mirrored` にするか、設定の画面で変える
   - 効くのは、この項の手順 4 で WSL を止めた後

1. WSL を止めて、ミラーで動くことを確かめる。

   ```powershell
   wsl.exe --shutdown
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   wsl.exe --distribution AlmaLinux-10 -- wslinfo --networking-mode
   ```

   - `mirrored` が出ればよい
   - `ミラー化されたネットワーク モードはサポートされていません` の行が出て `nat` なら、この PC ではミラーを使えない（理由はその行に出る）。この項の手順 6・7 で戻す
   - その行が無く `nat` なら、`.wslconfig` が読まれていない（この項の手順 2 で中身を確かめる）
   - `wslinfo` が無い旨が出たら、`wsl.exe --distribution AlmaLinux-10 -- ip -4 -br addr` の IP が、Windows の LAN の IP（`ipconfig`）と同じならミラー
   - WezTerm の WSL のタブは切れているので、開き直す

1. Windows の OpenSSH サーバーを入れたときだけ、WSL から `127.0.0.1` の 22 番に届くことを確かめる。

   ```powershell
   wsl.exe --distribution AlmaLinux-10 -- bash -c 'exec 3<>/dev/tcp/127.0.0.1/22 && head -n 1 <&3'
   ```

   - `SSH-2.0-OpenSSH_for_Windows_` で始まる行が出ればよい
   - WSL から Windows に ssh でつなぐときは、`ssh <WIN_USER>@127.0.0.1` にする（[注意点](extra/windows-setup.md#注意点)の OpenSSH サーバー）
   - `Connection refused` が出たら、Windows の sshd が動いていない（[OpenSSH サーバー](#openssh-サーバー)の手順で確かめる）

1. 元に戻すときは、`.wslconfig` を元に戻す。

   ```powershell
   & {
     $path = Join-Path $env:USERPROFILE '.wslconfig'
     $bak = "$path.windows-setup.bak"
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (Test-Path -LiteralPath $bak) {
       Move-Item -LiteralPath $bak -Destination $path -Force -ErrorAction Stop
       "控えから戻した: $path"
     } elseif (-not (Test-Path -LiteralPath $path)) {
       "無い: $path"
     } elseif ([IO.File]::ReadAllText($path) -eq "[wsl2]`r`nnetworkingMode=mirrored`r`n") {
       Remove-Item -LiteralPath $path -ErrorAction Stop
       "消した: $path"
     } else {
       Write-Error "中断: この項で作った形ではない。networkingMode の行を手で消す: $path"
     }
   }
   ```

   - `控えから戻した:`（ファイルがあったとき）か `消した:`（この項で作ったとき）が出ればよい
   - 控えた後に設定の画面などで変えた値も、控えたときに戻る
   - `中断:` が出たら、`.wslconfig` をメモ帳で開き、`networkingMode=mirrored` の行を消して保存する
   - 効くのは、この項の手順 7 で WSL を止めた後

1. 元に戻すときは、WSL を止めて、NAT に戻ったことを確かめる。

   ```powershell
   wsl.exe --shutdown
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   wsl.exe --distribution AlmaLinux-10 -- wslinfo --networking-mode
   ```

   - `nat` が出ればよい
   - WSL から Windows のサーバーには、また LAN の IP あてにつなぐ

---

### Wake on LAN を使う

- 有線 LAN の別の PC から、この PC の電源を入れられるようにする
- 前提: [PC 全体の設定](#pc-全体の設定)で休止状態とアダプターの省電力を切ってある。有線 LAN が接続されている
- 実行場所: 管理者の Windows PowerShell（5.1）、この PC の UEFI の画面、LAN の別の PC。PowerShell はこの項の手順 1 で開く

- **この項の手順 4 で再起動して UEFI の画面に入り、この項の手順 5 は UEFI の画面、この項の手順 6 はこの PC、この項の手順 7 は LAN の別の PC で行う**
- Windows の側の値は Microsoft の文書の標準の名前（`*WakeOnMagicPacket`）だけを変える。アダプターに独自の項目があれば、この項の手順 3 の表で確かめる

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. 変数を設定する。

   ```powershell
   $LAN_IF = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).InterfaceAlias   # 有線 LAN の接続（自動）。<LAN_IF>
   'LAN_IF = {0}' -f $LAN_IF
   ```

   - Wi-Fi の名前が出たら、`$LAN_IF = 'イーサネット'` のように有線 LAN の名前に直す

1. アダプターのマジック パケットでの起動を有効にし、MAC アドレスを表示する。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error 'この項の手順 2 の $LAN_IF が空'
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Set-NetAdapterAdvancedProperty -Name $LAN_IF -RegistryKeyword '*WakeOnMagicPacket' -RegistryValue 1 -NoRestart
     Get-NetAdapterAdvancedProperty -Name $LAN_IF | Where-Object { $_.RegistryKeyword -like '*Wake*' -or $_.DisplayName -like '*Wake*' } | Format-Table DisplayName, DisplayValue, RegistryKeyword
     Get-NetAdapter -Name $LAN_IF | Format-List Name, InterfaceDescription, MacAddress
   }
   ```

   - 表に `*WakeOnMagicPacket` の行があり、`DisplayValue` が有効の旨（`Enabled` か「有効」）になればよい
   - `MacAddress` の値を控える（この項の手順 7 で使う）
   - `*WakeOnMagicPacket` が無ければ、デバイス マネージャーの「詳細設定」で、表のほかの `Wake` 項目（「Shutdown Wake-On-Lan」など）を有効にする

1. 再起動して、UEFI の設定の画面に入る。

   ```powershell
   shutdown.exe /r /fw /t 0
   ```

   - すぐに再起動し、UEFI（BIOS）の設定の画面が開く
   - `入力された環境オプションが見つかりませんでした。(203)` が出て再起動しないときは、スタートメニューの電源から再起動し、起動の直後に機種のキー（F2・Del など）を押して UEFI の設定の画面に入る
   - **次の手順は、UEFI の設定の画面が開いてから行う**

1. UEFI の設定の画面で、Wake on LAN を有効にして保存し、Windows を起動する。

   - 項目の名前と場所は機種ごとに違う（「Wake on LAN」「Power On By PCI-E」「Resume by LAN」など）。機種の説明書で確かめる
   - 保存して終える（Save & Exit）と、Windows が起動する
   - 「ErP」「Deep Sleep」などの、電源を切ったときの消費を減らす項目が有効だと、Wake on LAN が効かないことがある

1. この PC を、スタートメニューの電源の「シャットダウン」で切る。

   - 有線 LAN のケーブルはつないだままにする

1. LAN の別の PC から、この PC の MAC アドレスあてにマジック パケットを送り、この PC が起動することを確かめる。

   - AlmaLinux 10 などの Python があるマシンでは、`python3 -c "import socket; m = bytes.fromhex('<MAC>'.replace('-', '').replace(':', '')); s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1); s.sendto(b'\xff' * 6 + m * 16, ('255.255.255.255', 9))"` で送れる（`<MAC>` はこの項の手順 3 の値）
   - 起動しなければ、この項の手順 3 の表の項目と、UEFI の設定を見直す
   - 元に戻すときは、この項の手順 8

1. 元に戻すときは、管理者の PowerShell で、マジック パケットでの起動を切る。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error 'この項の手順 2 の $LAN_IF が空'
   } else {
     Set-NetAdapterAdvancedProperty -Name $LAN_IF -RegistryKeyword '*WakeOnMagicPacket' -RegistryValue 0 -NoRestart
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-NetAdapterAdvancedProperty -Name $LAN_IF -RegistryKeyword '*WakeOnMagicPacket' | Format-Table DisplayName, DisplayValue
   }
   ```

   - 新しい PowerShell なら、先にこの項の手順 2 を貼る
   - UEFI の Wake on LAN も、この項の手順 4・5 と同じように入って切る

---

### リモートから再起動する手段を増やす

- リモートから使える再起動の経路を増やす
- 前提: [ネットワークとリモート](#ネットワークとリモート)で LAN をプライベートにし、[PC 全体の設定](#pc-全体の設定)で電源・LAN の省電力を設定済み。自動サインインを使うなら[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)、Remote Control の自動起動を使うなら[Claude Code の Remote Control](ai-agents.md#claude-code-の-remote-control-実施手順)を通してある
- 実行場所: 管理者の Windows PowerShell（5.1）。この項の手順 1 で開く。トリガーのコマンドは別の PC で実行する

- 手段は独立しているので、要るものだけ行う（「〜したいときだけ」の手順は飛ばしてよい）。この項の手順 2〜7・撤去の手順は、この項の手順 1 で開く管理者の Windows PowerShell（5.1）に貼る
- **別の PC で動かすトリガーのコマンドは、その PC で実行する**（AlmaLinux のシェルか、別の Windows の PowerShell）

- リモートの操作ができなくなったときに備えて、再起動の経路を増やす。1 つが死んでも別の経路で立ち直せるようにする
- 既にある接続からの再起動（この項の手順にはしない）
  - SSH でつながるなら `Restart-Computer`。Administrators のユーザーは UAC 不要で、sshd は再起動後も自動で起動する
  - RDP でつながるなら、スタートメニューの電源の「再起動」か `Restart-Computer`（[ネットワークとリモート](#ネットワークとリモート)の手順 4 で有効。再起動の後はロック画面に戻るが、また入れる）
  - [Claude Code の Remote Control（Windows）](ai-agents.md#claude-code-の-remote-control-実施手順) のセッションからも再起動できるが、そのタスクはトリガーが無いので再起動の後は戻らない。戻すにはこの項の手順 7
- この項で足す手段: クラッシュ時の自動再起動（この項の手順 3）・別の PC からのネットワーク再起動（この項の手順 4・5）・ネットワークが切れたときの自動再起動（この項の手順 6）
- 戻すときは、この項の手順 8〜12（入れた手段のものだけ）

> [!WARNING]
> - この項の手順 4・5 は、LAN の別の PC から管理者の資格情報で再起動できる口を開ける
> - `LocalAccountTokenFilterPolicy=1` は、ローカル・Microsoft アカウントのネットワークログオンに完全な管理者権限を与える
> - **人が触れる場所や信用できない LAN の PC では、この項の手順 4・5 を行わない**
> - この項の手順 6 の見張りタスクは、相手（ルーターなど）がずっと落ちていると再起動を繰り返す（稼働 60 分未満は再起動しない歯止めがある）

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. 変数を設定する（どちらも自動。見張りタスクを使わないなら `WATCHDOG_HOST` は要らない）。

   ```powershell
   $LAN_IF = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).InterfaceAlias   # ほかの PC とつながる LAN の接続（自動）。<LAN_IF>
   $WATCHDOG_HOST = if ($LAN_IF) { (Get-NetIPConfiguration -InterfaceAlias $LAN_IF).IPv4DefaultGateway.NextHop | Select-Object -First 1 } else { '' }   # 見張りタスクが生死を見る相手（自動で既定ゲートウェイ）。<WATCHDOG_HOST>
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'LAN_IF = {0}' -f $LAN_IF
   'WATCHDOG_HOST = {0}' -f $WATCHDOG_HOST
   ```

   - `LAN_IF` に Wi-Fi の名前が出たら、`$LAN_IF = 'イーサネット'` のように有線 LAN の名前に直す
   - `WATCHDOG_HOST` は、LAN の中でいつも応答する相手に変えてもよい（既定ゲートウェイ以外にするとき）

1. クラッシュ（ブルースクリーン）で止まったときに自動で再起動する設定を確かめる（既定で有効）。

   ```powershell
   $k = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'
   if ((Get-ItemProperty -Path $k -ErrorAction SilentlyContinue).AutoReboot -ne 1) { Set-ItemProperty -Path $k -Name AutoReboot -Type DWord -Value 1 }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $k | Format-List AutoReboot
   ```

   - `AutoReboot : 1` が出ればよい

1. 別の PC から OS 越しに再起動したいときだけ、SMB のリモートシャットダウンを開ける。

   ```powershell
   Set-NetFirewallRule -Name FPS-SMB-In-TCP -Enabled True -Profile Private
   Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name LocalAccountTokenFilterPolicy -Type DWord -Value 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-NetFirewallRule -Name FPS-SMB-In-TCP | Format-Table Name, Enabled, Profile, Direction, Action
   Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' | Format-List LocalAccountTokenFilterPolicy
   ```

   - `FPS-SMB-In-TCP … True  Private  Inbound  Allow` と `LocalAccountTokenFilterPolicy : 1` が出ればよい
   - 別の PC で動かすトリガー（`<WIN_IP>`・`<WIN_HOST>` はこの PC、`<WIN_USER>` は管理者）
     - AlmaLinux 10 から: `net rpc shutdown -r -f -t 0 -I <WIN_IP> -U '<WIN_USER>%<PASS>'`（`net` が無ければ `sudo dnf install -y samba-common-tools`）
     - 別の Windows から: `net use \\<WIN_HOST>\IPC$ /user:<WIN_HOST>\<WIN_USER>`（パスワードを聞かれる）でこの PC の資格情報を渡してから、`shutdown /r /f /t 0 /m \\<WIN_HOST>` を打つ
     - 別の Windows から送り終わったら、`net use \\<WIN_HOST>\IPC$ /delete` を打つ
   - `net use` は、パスワードを聞く前に `\\<WIN_HOST>\IPC$ のパスワードまたはユーザー名が無効です。` を出すが、そのまま入れてよい（`コマンドは正常に終了しました。` になればよい）
   - `アクセスが拒否されました。(5)` なら、`net use` で相手の資格情報を渡してから送り直す
   - **注意**: この手順は、節のリードの `[!WARNING]` のとおり管理の口を LAN に開ける

1. 別の Windows から PowerShell で再起動したいときだけ、WinRM（PowerShell リモート処理）を有効にする。

   ```powershell
   Set-NetFirewallRule -Name WINRM-HTTP-In-TCP -Profile Public
   Enable-PSRemoting -Force -SkipNetworkProfileCheck
   Set-NetFirewallRule -Name WINRM-HTTP-In-TCP -Enabled True -Profile Private
   Disable-NetFirewallRule -Name WINRM-HTTP-In-TCP-NoScope -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-NetFirewallRule -Group '@FirewallAPI.dll,-30267' | Format-Table Name, Enabled, Profile, Direction, Action
   ```

   - `WINRM-HTTP-In-TCP` が `True  Private` で、`WINRM-HTTP-In-TCP-NoScope` が `False` になればよい
   - 別の Windows から送る前に、送る側の管理者の PowerShell で、この PC を `TrustedHosts` に足す。ドメイン外で未登録ならエラーで止まる
     - `WSMan:\localhost` は WinRM のサービスが動いていないと使えないので、止まっていれば先に `Start-Service WinRM` を行う
     - 足す前の値を `(Get-Item WSMan:\localhost\Client\TrustedHosts).Value` で控えてから、`Set-Item WSMan:\localhost\Client\TrustedHosts -Value <WIN_HOST> -Concatenate -Force` を行う
     - 戻し方は、この項の手順 9 の箇条書き
   - 別の Windows で動かすトリガー: `Invoke-Command -ComputerName <WIN_HOST> -Credential <WIN_USER> -ScriptBlock { Restart-Computer -Force }`
     - 管理者ではない PowerShell でよい
     - `<WIN_USER>` には、コンピューター名を付けなくてよい
     - `-ComputerName` には、`TrustedHosts` に足したのと同じ名前を書く
     - エラー無しに数秒で戻り、この PC が再起動すればよい

1. ネットワークが切れたときに自分で再起動させたいときだけ、見張りのタスクを登録する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     if (-not $admin) { Write-Error '中断: 管理者の PowerShell ではない（この項の手順 1 から）'; return }
     if (-not $WATCHDOG_HOST) { Write-Error '中断: この項の手順 2 の $WATCHDOG_HOST が空'; return }
     $dir = 'C:\ProgramData\setup-notes'
     New-Item -ItemType Directory -Path $dir -Force | Out-Null
     $body = @'
   $ErrorActionPreference = 'SilentlyContinue'
   $target = '__WATCHDOG_HOST__'
   $key = 'HKLM:\SOFTWARE\setup-notes\net-watchdog'
   $limit = 6
   if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
   if (((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime).TotalMinutes -lt 60) {
     Set-ItemProperty -Path $key -Name Fails -Value 0 -Type DWord
     return
   }
   if (Test-Connection -ComputerName $target -Count 3 -Quiet) {
     Set-ItemProperty -Path $key -Name Fails -Value 0 -Type DWord
     return
   }
   $fails = [int](Get-ItemProperty -Path $key -Name Fails -ErrorAction SilentlyContinue).Fails + 1
   if ($fails -ge $limit) {
     Set-ItemProperty -Path $key -Name Fails -Value 0 -Type DWord
     Restart-Computer -Force
   } else {
     Set-ItemProperty -Path $key -Name Fails -Value $fails -Type DWord
   }
   '@
     Set-Content -LiteralPath "$dir\net-watchdog.ps1" -Value ($body.Replace('__WATCHDOG_HOST__', $WATCHDOG_HOST)) -Encoding ASCII
     $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$dir\net-watchdog.ps1`""
     $trigger = New-ScheduledTaskTrigger -AtStartup
     $trigger.Repetition = (New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 3650)).Repetition
     $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest
     $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
     Register-ScheduledTask -TaskName 'net-watchdog' -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-ScheduledTask -TaskName 'net-watchdog' | Format-List TaskName, State
   }
   ```

   - `net-watchdog  Ready` が出ればよい
   - 登録しただけでは動かない。次に起動したときから動く
   - **注意**: 相手がずっと落ちていると再起動を繰り返す（節のリードの `[!WARNING]`）。`$limit` を増やすと、再起動までの猶予が延びる

1. Remote Control を再起動の後も使いたいときだけ、タスクをログオン時に自動で始まるようにする。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     if (-not (Get-ScheduledTask -TaskName 'claude-remote-control' -ErrorAction SilentlyContinue)) { Write-Error '中断: claude-remote-control のタスクが無い（先に Claude Code の Remote Control（Windows）を設定する）'; return }
     $me = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
     Set-ScheduledTask -TaskName 'claude-remote-control' -Trigger (New-ScheduledTaskTrigger -AtLogOn -User $me) | Out-Null
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     (Get-ScheduledTask -TaskName 'claude-remote-control').Triggers | Format-Table -AutoSize
   }
   ```

   - ログオンのトリガーが 1 つ表示されればよい。次にそのユーザーでサインインしたときから、タスクが自動で始まる

1. 元に戻すときは（この項の手順 4 を行ったとき）、SMB のリモートシャットダウンを閉じる。

   ```powershell
   Set-NetFirewallRule -Name FPS-SMB-In-TCP -Enabled False
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-NetFirewallRule -Name FPS-SMB-In-TCP | Format-Table Name, Enabled, Profile
   ```

   - `FPS-SMB-In-TCP … False` になればよい
   - `LocalAccountTokenFilterPolicy` は、この項の手順 5 の WinRM と共有している。戻すのはこの項の手順 10

1. 元に戻すときは（この項の手順 5 を行ったとき）、WinRM を無効にする。

   ```powershell
   Disable-PSRemoting -Force
   Stop-Service -Name WinRM -ErrorAction SilentlyContinue
   Set-Service -Name WinRM -StartupType Manual
   Get-NetFirewallRule -Group '@FirewallAPI.dll,-30267' | Disable-NetFirewallRule
   Set-NetFirewallRule -Name WINRM-HTTP-In-TCP -Profile Public
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-NetFirewallRule -Group '@FirewallAPI.dll,-30267' | Format-Table Name, Enabled, Profile
   ```

   - 最後の表の規則が、すべて `False` になればよい（WinRM のサービスも止まる）
   - `WINRM-HTTP-In-TCP` の `Profile` が、既定の `Public` に戻ればよい
   - `Disable-PSRemoting` はセッションの構成を無効にするだけなので、サービスの停止・規則の無効化はこの手順で行う
   - `Enable-PSRemoting` が作ったリスナーの設定は残る。サービスが止まり、規則も無効なので、待ち受けない
   - この項の手順 5 の注意で、送る側の `TrustedHosts` に足したときは、送る側の管理者の PowerShell で控えた値に戻す
     - 送る側の WinRM のサービスが止まっていれば（送る側を再起動した後など）、先に `Start-Service WinRM` を行う
     - `Set-Item WSMan:\localhost\Client\TrustedHosts -Value '<控えた値>' -Force` を行う（空だったなら `-Value ''`）
     - 足す前にサービスが止まっていたなら、続けて `Stop-Service WinRM` を行う
   - `LocalAccountTokenFilterPolicy` はこの手順では戻さない（この項の手順 10）

1. 元に戻すときは（この項の手順 4 もこの項の手順 5 も使わないとき）、UAC のリモート制限を元に戻す。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name LocalAccountTokenFilterPolicy -Type DWord -Value 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' | Format-List LocalAccountTokenFilterPolicy
   ```

   - `LocalAccountTokenFilterPolicy : 0` になればよい（管理者のリモートログオンが、既定の制限に戻る）
   - この項の手順 4・5 のどちらかを使い続けるなら、この手順は行わない

1. 元に戻すときは（この項の手順 6 を行ったとき）、見張りのタスクと記録を消す。

   ```powershell
   Unregister-ScheduledTask -TaskName 'net-watchdog' -Confirm:$false
   Remove-Item -Path 'HKLM:\SOFTWARE\setup-notes\net-watchdog' -Recurse -ErrorAction SilentlyContinue
   Remove-Item -LiteralPath 'C:\ProgramData\setup-notes\net-watchdog.ps1' -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ScheduledTask -TaskName 'net-watchdog' -ErrorAction SilentlyContinue
   ```

   - 何も出なければよい（タスクが消えた）
   - 空になったキー `HKLM:\SOFTWARE\setup-notes` とフォルダー `C:\ProgramData\setup-notes` は残る。ほかに使っていなければ、手で消してよい

1. 元に戻すときは（この項の手順 7 を行ったとき）、Remote Control のタスクのトリガーを外す。

   - [Claude Code の Remote Control（Windows）](extra/windows-claude-remote-control.md#ロールバック)のロールバックでタスクごと消す。トリガーの無い形で使い続けるなら、AI エージェントの手順書の[Claude Code の Remote Control](ai-agents.md#claude-code-の-remote-control-実施手順)の手順 5 で入れ直す

---

### RDP をロックせずに切断

- RDP のセッションをこの PC の画面へ移し、ロックせずに切断する
- 前提: [ネットワークとリモート](#ネットワークとリモート)で RDP を有効にした Windows 11 Pro 以上に、サインイン中の Administrators のユーザーで RDP 接続している。切断後に SSH で確かめるなら[OpenSSH サーバー](#openssh-サーバー)と[SSH でログインを確かめる](#ssh-でログインを確かめる)を通してある
- 実行場所: RDP 接続先の管理者の Windows PowerShell（5.1）。この項の手順 1 で開く。切断後はクライアントの PC の SSH または接続先の画面で確かめる

- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-rdp-disconnect.md)・[参考資料](reference/windows-rdp-disconnect.md)・[ロールバックと注意点](extra/windows-rdp-disconnect.md)

- この項の手順 1〜3 は RDP のセッションの中で行う。この項の手順 3 を貼ると、その場で RDP が切れる
- この項の手順 4・5 は、クライアントの PC から SSH で行う。SSH が無ければ、PC の前で画面を見る

- SSH でログインできなければ、PC の前で画面を見て確かめる

> [!WARNING]
> - **切断した後の PC の画面はロックされない**。PC の前にいる人が、このユーザー（Administrators の一員）としてそのまま操作できる。人が触れる場所にある PC では使わない

1. RDP でつないだセッションの中で、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」を選ぶ。UAC の確認で「はい」
   - ウィンドウのタイトルが「管理者: Windows PowerShell」になる
   - 「Windows PowerShell (x86)」（32 ビット）は使わない
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
   - **次の手順は、RDP が切れてから、クライアントの PC で行う**（この手順の後ろに行を続けて貼らない）

1. クライアントの PC から、Windows に SSH でログインする。

   - `ssh <WIN_USER>@<WIN_HOST>` でログインする（[Windows 11 の初期設定の「SSH でログインを確かめる」の手順 5](#ssh-でログインを確かめる)と同じ）
   - PC の前にいるなら、SSH の代わりに PC の画面を見る。ロック画面ではなく、RDP で開いていたままのデスクトップが出ていればよい。そのときはこの項の手順 5 は飛ばす
   - **次の手順は、ログインした先のプロンプトが出てから貼る**（続けて貼ると、ログインの途中の入力として食われる）

1. SSH でログインしたシェルで、セッションが PC の画面に戻ったことを確かめる。

   ```powershell
   quser
   ```

   - 自分の行のセッション名が `console` で、状態が `Active`。ID はこの項の手順 2 と同じ
   - ログインした先のシェルが Git Bash でも cmd でも、そのまま `quser` と打てばよい

#### RDP をロックせずに切断: ショートカットで切断する

- RDP をロックせずに切断するショートカットを作る
- 前提: [ネットワークとリモート](#ネットワークとリモート)で RDP を有効にした Windows 11 Pro 以上に、サインイン中の Administrators のユーザーで RDP 接続している。切断の注意は[RDP をロックせずに切断](#rdp-をロックせずに切断)を先に読む
- 実行場所: RDP 接続先の通常権限の Windows PowerShell（5.1）。この項の手順 1 で開く

- UAC の確認は毎回出る。ショートカットは、管理者として実行する Windows PowerShell で `tscon` を動かす
- **切断した後の画面はロックされない**。人が触れる場所にある PC では使わない

1. RDP でつないだセッションの中で、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）
   - 窓の名前に「管理者:」が付いていないことを確かめる

1. デスクトップに、管理者として実行するショートカットを作る。

   ```powershell
   & {
     $lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'RDP をロックせずに切断.lnk'
     $s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
     $s.TargetPath = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
     $s.Arguments = '-NoProfile -WindowStyle Hidden -Command "tscon.exe (Get-Process -Id $PID).SessionId /dest:console"'
     $s.IconLocation = "$env:WINDIR\System32\mstsc.exe,0"
     $s.Save()
     $b = [System.IO.File]::ReadAllBytes($lnk)
     if ($b[0] -ne 0x4C) { Write-Error "中断: $lnk がショートカットの形式でない"; return }
     $b[0x15] = $b[0x15] -bor 0x20
     [System.IO.File]::WriteAllBytes($lnk, $b)
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     '{0}（管理者として実行: {1}）' -f $lnk, [bool]([System.IO.File]::ReadAllBytes($lnk)[0x15] -band 0x20)
   }
   ```

   - `C:\Users\<WIN_USER>\Desktop\RDP をロックせずに切断.lnk（管理者として実行: True）` が出ればよい（OneDrive でデスクトップをバックアップしていると、`OneDrive` の下のパスになる）
   - デスクトップに「RDP をロックせずに切断」のアイコンが出る
   - 何度貼ってもよい
   - 同じ印は、画面でも付けられる: ショートカットのプロパティの「ショートカット」タブの「詳細設定」で、「管理者として実行」にチェックを入れる

1. 切断するときは、RDP でつないだセッションの中で、デスクトップのショートカットをダブルクリックする。

   - UAC の確認（Windows PowerShell）で「はい」を押すと、RDP が切れる（[RDP をロックせずに切断](#rdp-をロックせずに切断)の手順 3 と同じ）
   - 切れないときは、[RDP をロックせずに切断](#rdp-をロックせずに切断)の手順 1〜3 で切って、エラーを見る
   - PC の前（コンソール）では使わない
   - 切った後の確かめ方は、[RDP をロックせずに切断](#rdp-をロックせずに切断)の手順 4・5 と同じ

---

### WireGuard

- Windows のクライアントから、拠点の WireGuard に接続する
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/wireguard.md)・[参考資料](reference/wireguard.md)・[ロールバックと注意点](extra/wireguard.md)

- Windows の操作は管理者の Windows PowerShell（5.1）で行う。各項で窓を開く
- WG ホストで行う操作は、各項の説明に従って拠点の bash に貼る

- WireGuard は PC 全体に入り、トンネルは Windows のサービスとして動く
- [登録と取り込み](#wireguard-windows-11-で-wg-ホストに登録して取り込む)の手順 4 だけは、関数名を手入力する

#### WireGuard: Windows 11 で WireGuard と鍵を用意する

- 外出先からつなぐ Windows の PC に WireGuard を入れ、この PC の鍵を作る
- 前提: [Microsoft Store の更新](#microsoft-store-の更新)で winget を用意し、拠点の WG ホストで[状態と疎通を確かめる](almalinux-setup.md#wireguard-状態と疎通を確かめる)まで通してある
- 実行場所: この PC の管理者の Windows PowerShell（5.1）。この項の手順 1 で開く

1. Windows で、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. この PC の WireGuard の状態を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget list --exact --id WireGuard.WireGuard --accept-source-agreements --source winget
   Get-Service -Name 'WireGuard*' -ErrorAction SilentlyContinue | Format-Table Name, Status, StartType
   Get-ChildItem -LiteralPath "$env:ProgramFiles\WireGuard\Data\Configurations" -ErrorAction SilentlyContinue | Format-Table Name
   Test-Path -LiteralPath "$env:USERPROFILE\wg-client"
   ```

   - `入力条件に一致するインストール済みのパッケージが見つかりませんでした。`（英語の Windows では `No installed package found matching input criteria.`）と、`False` だけが出れば、まだ入っていない
   - `WireGuardTunnel$wg0` か `wg0.conf.dpapi` が出たら、同名のトンネルがある。[ロールバック](extra/wireguard.md#windows-11-のロールバック)の手順 1 で消してから始める（鍵は取り戻せない）
   - 最後が `True` なら、前に作った鍵が残っている（この項の手順 5 で止まる）。使わないなら、[Windows 11 のロールバック](extra/wireguard.md#windows-11-のロールバック)の手順 1 で消す
   - `winget` が見つからないというエラーになったら、Microsoft Store で「アプリ インストーラー」を更新してから始める

1. WireGuard を winget で入れる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget install --exact --id WireGuard.WireGuard --source winget --scope machine --accept-source-agreements --accept-package-agreements
   winget list --exact --id WireGuard.WireGuard --source winget
   Get-AuthenticodeSignature -FilePath "$env:ProgramFiles\WireGuard\wireguard.exe", "$env:ProgramFiles\WireGuard\wg.exe" | Format-Table Status, @{ Label = 'Signer'; Expression = { $_.SignerCertificate.Subject.Split(',')[0] } }, Path -AutoSize
   & "$env:ProgramFiles\WireGuard\wg.exe" --version
   ```

   - `インストールが完了しました`（英語の Windows では `Successfully installed`）と出て、`winget list` に `WireGuard.WireGuard` の行が出ればよい
   - 2 つのファイルの署名が `Valid` で、署名者が `CN=WireGuard LLC`
   - 最後に `wireguard-tools v1.0.20260223 - https://git.zx2c4.com/wireguard-tools/` の形の 1 行が出る
   - インストーラーの画面は出ず、入れた後に WireGuard の窓も開かない（窓は、この項の手順 4 で開く）

1. WireGuard の窓を開く（マネージャーを起動する）。

   ```powershell
   & "$env:ProgramFiles\WireGuard\wireguard.exe"
   ```

   - WireGuard の窓が開き、タスク バーの通知領域に WireGuard のアイコンが出る（トンネルの一覧はまだ空）
   - スタートメニューの「WireGuard」から開いても同じ
   - 窓は開いたままでよい
   - **次の手順は、WireGuard の窓が開いてから、PowerShell の窓をクリックして貼る**（窓が開く前に貼ると、開いた窓に入力が移ることがある）

1. 鍵ペアを作る。

   ```powershell
   & {
     $wg = "$env:ProgramFiles\WireGuard\wg.exe"
     $dir = "$env:USERPROFILE\wg-client"
     if (Test-Path -LiteralPath "$dir\wg0.key") { Write-Error '中断: wg0.key が既にある（作り直すなら先に消す。WG ホストに登録済みの公開鍵と対応しなくなる）'; return }
     New-Item -ItemType Directory -Force -Path $dir | Out-Null
     icacls.exe $dir /inheritance:r /grant '*S-1-5-32-544:(OI)(CI)F' /grant '*S-1-5-18:(OI)(CI)F' | Out-Null
     $priv = & $wg genkey
     if ($LASTEXITCODE -ne 0 -or $priv -cnotmatch '^[A-Za-z0-9+/]{43}=$') { Write-Error '中断: 鍵を作れない'; return }
     $pub = $priv | & $wg pubkey
     if ($LASTEXITCODE -ne 0 -or $pub -cnotmatch '^[A-Za-z0-9+/]{43}=$') { Write-Error '中断: 公開鍵を出せない'; return }
     [IO.File]::WriteAllText("$dir\wg0.key", "$priv`n", [Text.Encoding]::ASCII)
     [IO.File]::WriteAllText("$dir\wg0.pub", "$pub`n", [Text.Encoding]::ASCII)
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     icacls.exe $dir
     Get-ChildItem -LiteralPath $dir | Format-Table Name, Length
     $pub
   }
   ```

   - `icacls` に `NT AUTHORITY\SYSTEM:(OI)(CI)(F)` と `BUILTIN\Administrators:(OI)(CI)(F)` の 2 行だけが出る
   - `wg0.key` と `wg0.pub` がどちらも 45 バイト
   - 最後の 1 行（公開鍵、44 文字）だけを、[Windows 11 で WG ホストに登録して取り込む](#wireguard-windows-11-で-wg-ホストに登録して取り込む)の手順 3 で WG ホストに渡す。秘密鍵（`wg0.key`）は渡さない
   - **注意**: `%USERPROFILE%\wg-client` は、管理者の PowerShell からしか読めない（管理者ではない PowerShell やエクスプローラーでは開けない）

#### WireGuard: Windows 11 で WG ホストに登録して取り込む

- この PC の公開鍵を拠点の WG ホストに登録し、Windows に conf を取り込む
- 前提: [WireGuard と鍵を用意する](#wireguard-windows-11-で-wireguard-と鍵を用意する)を通し、鍵と公開鍵が残っている。WireGuard のマネージャーが動いている
- 実行場所: この PC の管理者の Windows PowerShell（5.1）と、拠点の WG ホストの bash。PowerShell はこの項の手順 1 で開く

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、右クリック →「管理者として実行」を選ぶ
   - UAC の確認で「はい」を押す。窓の名前が「管理者: Windows PowerShell」になる

1. Windows の PowerShell で、conf を取り込む関数を定義する。

   ```powershell
   function Import-WgClientConf {
     $dir = "$env:USERPROFILE\wg-client"
     $text = Get-Clipboard -Raw
     if (-not $text) { Write-Error '中断: クリップボードが空（この項の手順 3 の client show の出力をコピーし直す）'; return }
     $lines = @($text.Trim() -split '\r?\n' | ForEach-Object { $_.TrimEnd() })
     if ($lines[0] -cne '[Interface]') { Write-Error '中断: クリップボードの先頭が [Interface] ではない（client show の出力だけをコピーし直す）'; return }
     if (@($lines -cnotmatch '^[\t\x20-\x7e]*$').Count -ne 0) { Write-Error '中断: クリップボードに ASCII でない文字がある'; return }
     if (@($lines -cmatch '^PrivateKey *=').Count -ne 1 -or -not (Test-Path -LiteralPath "$dir\wg0.key")) { Write-Error '中断: PrivateKey の行が 1 行ちょうどでないか、wg0.key が無い'; return }
     $key = (Get-Content -LiteralPath "$dir\wg0.key" -Raw).Trim()
     $conf = $lines -creplace '^PrivateKey *=.*', "PrivateKey = $key"
     [IO.File]::WriteAllText("$dir\wg0.conf", ($conf -join "`r`n") + "`r`n", [Text.Encoding]::ASCII)
     @(Get-Content -LiteralPath "$dir\wg0.conf" | Where-Object { $_ -cmatch '^PrivateKey = [A-Za-z0-9+/]{43}=$' }).Count
     Get-Content -LiteralPath "$dir\wg0.conf" | Where-Object { $_ -cnotmatch '^PrivateKey' }
   }
   ```

   - この手順は関数を定義するだけで、何も表示せず、conf もまだ書かない
   - PowerShell を開き直した場合は、この項の手順 1 で管理者の窓を開き、この項の手順 2 の関数の定義を貼り直す

1. WG ホストで、[クライアントを登録する](almalinux-setup.md#wireguard-クライアントを登録する)の手順 1・2・4〜6 を行い、この PC の公開鍵を登録して conf を表示する。

   - ホスト側の手順 1 の `CLIENT_PUBKEY` に、[鍵の用意](#wireguard-windows-11-で-wireguard-と鍵を用意する)の手順 5 の公開鍵を貼る
   - `CLIENT_NAME` はこの PC だけの名前（例 `win-laptop`）にする。同名の端末は、ホスト側の手順 2 で登録を消してしまう
   - ホスト側の手順 6 の `client show` から、`[Interface]`〜`PersistentKeepalive` をこの PC のクリップボードにコピーする
   - `PrivateKey` はプレースホルダのままなので、**秘密情報を含まない**。どの経路で運んでもよい
   - **次の手順は、`client show` の出力をこの PC でコピーしてから行う**。コピー後は、コードブロックなど別の文字列をコピーしない

1. Windows の PowerShell で、`Import-WgClientConf` と手入力して Enter を押す。

   - 関数名はコピーせず手で打つ。クリップボードには、この項の手順 3 の conf を残しておく
   - `1`（置き換わった）と、`PrivateKey` 以外の行（`Address`・`PublicKey`・`Endpoint`・`AllowedIPs` など）が出ればよい
   - 残りの行が `client show` の出力のとおりで、途中で折り返されていないことを目で確かめる
   - `中断:` で始まるエラーが出たら、何も書いていない
   - conf をコピーし直し、この関数をもう一度呼んでもよい（`wg0.conf` を書き直す）

1. `wg0.conf` を WireGuard に取り込む。

   ```powershell
   & {
     $dir = "$env:USERPROFILE\wg-client"
     $store = "$env:ProgramFiles\WireGuard\Data\Configurations"
     if ((Get-Service -Name WireGuardManager -ErrorAction SilentlyContinue).Status -ne 'Running' -or -not (Test-Path -LiteralPath $store)) { Write-Error '中断: WireGuard のマネージャーが動いていない（「Windows 11 で WireGuard と鍵を用意する」の手順 4 からやり直す）'; return }
     if (-not (Test-Path -LiteralPath "$dir\wg0.conf")) { Write-Error '中断: wg0.conf が無い（この項の手順 4）'; return }
     if (Test-Path -LiteralPath "$store\wg0.conf.dpapi") { Write-Error '中断: wg0 というトンネルが既にある'; return }
     Copy-Item -LiteralPath "$dir\wg0.conf" -Destination "$store\wg0.conf"
     for ($i = 0; $i -lt 30 -and (Test-Path -LiteralPath "$store\wg0.conf"); $i++) { Start-Sleep -Seconds 1 }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-ChildItem -LiteralPath $store | Format-Table Name, Length, LastWriteTime
   }
   ```

   - `wg0.conf.dpapi` の 1 行だけが出ればよい
   - WireGuard の窓のトンネルの一覧に `wg0` が出る（無効のまま）
   - この手順は LAN の中で貼ってよい
   - `wg0.conf` が残ったら取り込み失敗。理由を確かめ、`Remove-Item -LiteralPath "$env:ProgramFiles\WireGuard\Data\Configurations\wg0.conf"` で消す
   - この項の手順 3・4 からやり直す
   - （この手順の代わりに）窓の「トンネルをファイルからインポート…」で `%USERPROFILE%\wg-client\wg0.conf` を選んでも、同じ `wg0.conf.dpapi` ができるはず

#### WireGuard: Windows 11 でトンネルを確かめる

- 外出先からつなぐ Windows の PC でトンネルを張り、拠点への疎通を確かめる
- 前提: [WG ホストに登録して取り込む](#wireguard-windows-11-で-wg-ホストに登録して取り込む)を通し、wg0 を取り込んである
- 実行場所: この PC の管理者の Windows PowerShell（5.1）と、拠点の WG ホストの bash。PowerShell はこの項の手順 1 で開く

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、右クリック →「管理者として実行」を選ぶ
   - UAC の確認で「はい」を押す。窓の名前が「管理者: Windows PowerShell」になる

1. 変数を設定する（4 つの IP は必ず値を入れる）。

   ```powershell
   $WG_HOST_TUN_IP = '10.99.0.1'         # 接続先拠点の WG ホストの wg0 アドレス（site.env の WG_A_TUN_IP）。<WG_HOST_TUN_IP>
   ```

   ```powershell
   $WG_HOST_LAN_IP = '192.168.110.2'     # 同じホストの LAN 側 IP（WG_A_LAN_IP）。<WG_HOST_LAN_IP>
   ```

   ```powershell
   $ROUTER_LAN_IP = '192.168.110.1'      # 接続先拠点のルーターの LAN 側 IP（ROUTER_A_LAN_IP）。<ROUTER_LAN_IP>
   ```

   ```powershell
   $PEER_WG_LAN_IP = '192.168.120.2'     # 相手拠点の WG ホストの LAN 側 IP（WG_B_LAN_IP）。<PEER_WG_LAN_IP>
   ```

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   foreach ($v in 'WG_HOST_TUN_IP', 'WG_HOST_LAN_IP', 'ROUTER_LAN_IP', 'PEER_WG_LAN_IP') {
     '{0,-15} = {1}' -f $v, (Get-Variable -Name $v -ValueOnly -ErrorAction SilentlyContinue)
   }
   ```

   - 編集が必須なのは、1 行ずつの 4 ブロック。接続先拠点と相手拠点の IP を入れる
   - 最後に値を読み戻して確かめる
   - **例の値のままでもエラーにならない**ので、4 つの IP を書き換えたか必ずここで確かめる
   - 変数はその PowerShell の中だけで有効。**新しい PowerShell を開いたら**、この項の手順 2 の 5 つのブロックを貼り直してから先へ進む

1. PC を、拠点の LAN の外のネットワークにつなぐ（スマートフォンのテザリングなど）。

   - LAN 内でこの項の手順 4 を貼ると、そこで LAN の通信が切れる
   - **次の手順は、LAN の外につないでから貼る**

1. 拠点の LAN の外で、トンネルを張る。

   ```powershell
   & {
     $conf = "$env:ProgramFiles\WireGuard\Data\Configurations\wg0.conf.dpapi"
     if (-not (Test-Path -LiteralPath $conf)) { Write-Error '中断: wg0.conf.dpapi が無い（「Windows 11 で WG ホストに登録して取り込む」の手順 5）'; return }
     & "$env:ProgramFiles\WireGuard\wireguard.exe" /installtunnelservice $conf 2>&1 | ForEach-Object { "$_" }
     for ($i = 0; $i -lt 30 -and -not (Get-NetIPAddress -InterfaceAlias wg0 -AddressFamily IPv4 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-Service -Name 'WireGuardTunnel$wg0' | Format-Table Name, Status, StartType
     Get-NetIPAddress -InterfaceAlias wg0 -AddressFamily IPv4 | Format-Table InterfaceAlias, IPAddress, PrefixLength
     Get-NetRoute -InterfaceAlias wg0 -AddressFamily IPv4 | Format-Table DestinationPrefix, NextHop, RouteMetric
     Get-NetIPInterface -InterfaceAlias wg0 -AddressFamily IPv4 | Format-Table InterfaceAlias, NlMtu, InterfaceMetric
     Get-NetConnectionProfile -InterfaceAlias wg0 -ErrorAction SilentlyContinue | Format-Table InterfaceAlias, NetworkCategory
     Get-DnsClientServerAddress -InterfaceAlias wg0 -AddressFamily IPv4 | Format-Table InterfaceAlias, ServerAddresses
     & "$env:ProgramFiles\WireGuard\wg.exe" show wg0
   }
   ```

   - `WireGuardTunnel$wg0  Running  Automatic` と、`wg0` に `<CLIENT_TUN_IP>` / `32` が出ればよい
   - 経路に、`AllowedIPs` の 3 つ（`RouteMetric` が `0`）がある
   - `NlMtu` は、conf に `MTU =` があればその値、無ければ `1420`（今の回線の MTU が 1500 のとき）
   - `NetworkCategory` は `Public` のはず（変えない。行が出なければ、Windows がまだネットワークを識別している）
   - `ServerAddresses` が空（`{}`）
   - `wg show` の `latest handshake` が数秒前で、`transfer` の received が 0 でない。まだ出ていなければ、この項の手順 5 の通信で出る
   - 窓で `wg0` を選び「有効化」を押しても同じ
   - **注意**: LAN 内で貼ってしまったら、そこで LAN の通信が切れる。PC の画面の WireGuard の窓で「無効化」を押す

1. PC で、トンネル IP → WG ホストの LAN 側 → ルーター → 相手拠点の順に疎通を試す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not ($WG_HOST_TUN_IP -and $WG_HOST_LAN_IP -and $ROUTER_LAN_IP -and $PEER_WG_LAN_IP)) {
     Write-Error '中断: この項の手順 2 の変数が空のまま'
   } else {
     foreach ($h in $WG_HOST_TUN_IP, $WG_HOST_LAN_IP, $ROUTER_LAN_IP, $PEER_WG_LAN_IP) {
       "== $h"
       ping.exe -n 3 -w 2000 $h | Select-Object -Last 3
     }
     tracert.exe -d -h 5 -w 2000 $PEER_WG_LAN_IP
   }
   ```

   - 4 つとも、損失が 0%（`0% の損失`）ならよい
   - `tracert` は `<WG_HOST_TUN_IP>` → `<PEER_WG_LAN_IP>` の順に出る
   - 相手拠点の LAN 上の別のホストへの `ping`、トンネル越しの `ssh <ユーザー>@<WG_HOST_LAN_IP>`（Windows 11 の OpenSSH クライアント）も試しておくとよい
   - どこで止まるかで、疑う場所が変わる（[トンネルを確かめる](almalinux-setup.md#wireguard-トンネルを確かめる)の手順 3 と同じ）

1. WG ホストで変数を設定し、ハンドシェイクを確かめる。

   - [クライアントを登録する](almalinux-setup.md#wireguard-クライアントを登録する)の手順 1 で、`SITE`・`CLIENT_NAME`・`REPO` をこの PC を登録したときと同じ値に設定する
   - その WG ホストの bash に、[トンネルを確かめる](almalinux-setup.md#wireguard-トンネルを確かめる)の手順 5 を貼る

   - `client list` の、この PC の名前の `LAST_HANDSHAKE` が「N 秒前」なら届いている
   - 最後の `ping`（拠点 → PC）は、応答が無くてよい
   - 片方向だけ失敗する、`latest handshake` が出ない、といった場合は [症状と原因の対応](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/wireguard.md#症状と原因の対応実測)
   - **次の手順は、WG ホストで確かめてから、この PC で貼る**

1. PC で、トンネルを切る。

   ```powershell
   & "$env:ProgramFiles\WireGuard\wireguard.exe" /uninstalltunnelservice wg0 2>&1 | ForEach-Object { "$_" }
   for ($i = 0; $i -lt 30 -and (Get-Service -Name 'WireGuardTunnel$wg0' -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Service -Name 'WireGuardTunnel$wg0' -ErrorAction SilentlyContinue
   Get-NetAdapter -Name wg0 -ErrorAction SilentlyContinue
   ```

   - 最後の 2 つが何も出さなければよい
   - 窓で `wg0` を選び「無効化」を押しても同じ
   - 日常は、外出先で窓（か、通知領域の WireGuard のアイコン）から `wg0` を有効化し、拠点に戻る前に無効化する（この項の手順 4・7 のコマンドでも同じ）
   - **張ったまま再起動すると、起動したときにまた張られる**。拠点の LAN に戻る前に切る

1. 平文の鍵と conf を消す。

   ```powershell
   Remove-Item -LiteralPath "$env:USERPROFILE\wg-client\wg0.key", "$env:USERPROFILE\wg-client\wg0.conf"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ChildItem -LiteralPath "$env:USERPROFILE\wg-client" | Format-Table Name, Length
   ```

   - `wg0.pub` だけが残る
   - 取り込みをやり直すときは、後片付けの前に[登録と取り込み](#wireguard-windows-11-で-wg-ホストに登録して取り込む)の手順 5 を行う（`wg0.conf` が必要）

#### WireGuard: Windows 11 の更新

- この PC の WireGuard を winget で更新する
- 前提: [WireGuard と鍵を用意する](#wireguard-windows-11-で-wireguard-と鍵を用意する)で本体を入れ、[Microsoft Store の更新](#microsoft-store-の更新)で winget を用意してある
- 実行場所: この PC の管理者の Windows PowerShell（5.1）。この項の手順 1 で開く

- WireGuard のマネージャーは、1 時間ごとに新しい版を確かめる（起動した直後は数分待ってから）。新しい版があると、窓に「更新が利用できます！」のタブが出て、そこの「今すぐ更新」で上がる（Administrators の一員だけ）
- 窓からの更新は、公式の署名付きの一覧（`latest.sig`）で MSI を確かめてから入れる。winget で上げても、入るのは同じ公式の MSI
- 更新の間、マネージャーと、張っているトンネルのサービスは止まり、入れ終えると起動し直す（張っていれば数秒切れる）

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、右クリック →「管理者として実行」を選ぶ
   - UAC の確認で「はい」を押す。窓の名前が「管理者: Windows PowerShell」になる

1. WireGuard を winget で上げる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget upgrade --exact --id WireGuard.WireGuard --source winget --accept-source-agreements --accept-package-agreements
   winget list --exact --id WireGuard.WireGuard --source winget
   Get-Service -Name 'WireGuard*' | Format-Table Name, Status, StartType
   ```

   - 上がったら `インストールが完了しました` と出て、`winget list` の `WireGuard.WireGuard` の版が新しくなる
   - 新しい版が無ければ、`利用可能なアップグレードが見つかりませんでした。`（英語の Windows では `No available upgrade found.`）と出る
   - 最後に `WireGuardManager` が `Running` で出る（張っていれば `WireGuardTunnel$wg0` も）
   - 窓が更新を知らせているのに winget で上がらないときは、窓の「今すぐ更新」で上げる

---

## シェルと端末

- Git for Windows（Git Bash）・WezTerm・共通の bash 設定・シェルのツール・PowerShell 7

### Git for Windows

- Git for Windows を PC 全体に入れる
- 前提: [Microsoft Store の更新](#microsoft-store-の更新)を通し、winget が使える
- 実行場所: この PC のデスクトップの管理者の Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、右クリックして「管理者として実行」を選ぶ（PowerShell 7 の「PowerShell」ではない）
   - ユーザーアカウント制御（UAC）の確認は「はい」

1. Git for Windows がまだ入っていないことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Command git -All -ErrorAction SilentlyContinue | Format-Table Source
   Test-Path 'C:\Program Files\Git\bin\bash.exe'
   winget list --exact --id Git.Git --accept-source-agreements --source winget
   ```

   - 1 行目は何も出さず、`False` と、`入力条件に一致するインストール済みのパッケージが見つかりませんでした。`（英語の Windows では `No installed package found matching input criteria.`）が出ればよい
   - `False` で、1 行目に `…\AppData\Local\Programs\Git\cmd\git.exe` が出たら、管理者の権限無しで入れた Git for Windows がある。それを外してから始める
   - 1 行目に scoop の `…\scoop\shims\git.exe` だけが出たら、そのまま進めてよい
   - `winget` が見つからないというエラーになったら、Microsoft Store で「アプリ インストーラー」を更新してから始める
   - `True` なら、Git for Windows はもう `C:\Program Files\Git` に入っている。この項の手順 3 は飛ばす（新しい版にするなら[Git for Windows・Firefox・WezTerm を上げる](#git-for-windowsfirefoxwezterm-を上げる)の手順 3）

1. まだ入っていなければ、winget で Git for Windows を PC 全体（`C:\Program Files\Git`）に入れる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget install --exact --id Git.Git --source winget --scope machine --accept-source-agreements --accept-package-agreements
   winget list --exact --id Git.Git --source winget
   ```

   - `インストールが完了しました`（英語の Windows では `Successfully installed`）と出て、`winget list` に `Git.Git` の行が出ればよい
   - インストーラの画面は出ない（進み具合の小さな窓が出て、終わると消える）
   - この窓では `git` は見つからない。再起動後、[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 2 で確かめる

---

### WezTerm

- WezTerm nightly と、必要な Visual C++ ランタイムを PC 全体に入れる
- 前提: [Microsoft Store の更新](#microsoft-store-の更新)を通し、winget が使える
- 実行場所: この PC のデスクトップの管理者の Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、右クリックして「管理者として実行」を選ぶ（PowerShell 7 の「PowerShell」ではない）
   - ユーザーアカウント制御（UAC）の確認は「はい」

1. 管理者であることと、今の WezTerm と `VCRUNTIME140.dll` があるかを確かめる。

   ```powershell
   $u = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{BCF6F0DA-5B9A-408D-8562-F680AE6E1EAF}_is1' -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     Admin     = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Version   = $u.DisplayVersion
     Location  = $u.InstallLocation
     OnPath    = (Get-Command wezterm.exe -All -ErrorAction SilentlyContinue).Source -join ' '
     Running   = (Get-Process -Name wezterm, wezterm-gui, wezterm-mux-server -ErrorAction SilentlyContinue).ProcessName -join ' '
     VCRuntime = Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
   } | Format-List
   ```

   - `Admin : True` であること（`False` なら、この項の手順 1 で管理者の窓を開き直してから、このブロックを貼る）
   - 初めて入れる PC では、`Version`・`Location`・`OnPath`・`Running` が空
   - `Version` に版が出たら、もう入っている（`20260905-153129-092dcf70` など）。この項の手順 4 で今の nightly に上書きする
     - `Location` は `C:\Program Files\WezTerm\` のはず。違う場所なら、インストーラはそこに上書きするので、先に[ロールバックの「OpenSSH・Git for Windows・Firefox・WezTerm を外す」](extra/windows-setup.md#opensshgit-for-windowsfirefoxwezterm-を外す)の手順 8 で外す
   - `OnPath` に `C:\Program Files\WezTerm\wezterm.exe` 以外（scoop の `shims` など）が出たら、ほかの方法で入れた WezTerm がある。外してから始める
   - `Running` に名前が出たら、その WezTerm の窓を閉じる（[Claude Code の Remote Control（Windows）](ai-agents.md#claude-code-の-remote-control-実施手順)のタスクは、AI エージェントの手順書の[Claude Code の Remote Control: 止める・もう一度始める](ai-agents.md#claude-code-の-remote-control-止めるもう一度始める)の手順 1 で止める）
   - `VCRuntime : True` なら、この項の手順 3 は飛ばす。`False` なら、この項の手順 3 で入れる

1. `VCRUNTIME140.dll` が無いときだけ、Visual C++ の再頒布可能パッケージを入れる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget install --exact --id Microsoft.VCRedist.2015+.x64 --source winget --scope machine --accept-source-agreements --accept-package-agreements
   Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
   ```

   - `インストールが完了しました`（英語の Windows では `Successfully installed`）と、`True` が出ればよい
   - 最後が `True` ならこの項の手順 4へ進む
   - 最後の行が `False` なら、Windows を再起動してデスクトップにサインインし、この項の手順 1 から行う
   - `winget` が見つからないというエラーになったら、Microsoft Store で「アプリ インストーラー」を更新してから始める

1. nightly のインストーラを取り、sha256 を確かめて、黙って入れる。

   ```powershell
   & {
     $dir = 'C:\Program Files\WezTerm'
     $curl = "$env:WINDIR\System32\curl.exe"
     $url = 'https://github.com/wezterm/wezterm/releases/download/nightly/WezTerm-nightly-setup.exe'
     $tmp = "$env:TEMP\wezterm-setup"
     $setup = "$tmp\WezTerm-nightly-setup.exe"
     $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     if (-not $admin) { Write-Error '中断: 管理者の PowerShell ではない'; return }
     if (-not (Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll")) { Write-Error '中断: VCRUNTIME140.dll が無い（この項の手順 3）'; return }
     if (Get-Process -Name wezterm, wezterm-gui, wezterm-mux-server -ErrorAction SilentlyContinue) { Write-Error '中断: WezTerm が動いている（窓をすべて閉じる）'; return }
     Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
     New-Item -ItemType Directory -Path $tmp | Out-Null
     & $curl -fsSL -o "$setup.sha256" "$url.sha256"
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: WezTerm-nightly-setup.exe.sha256 を取れない'; return }
     & $curl -fsSL -o $setup $url
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: WezTerm-nightly-setup.exe を取れない'; return }
     $m = Select-String -LiteralPath "$setup.sha256" -Pattern '^([0-9a-f]{64})  WezTerm-nightly-setup\.exe$' | Select-Object -First 1
     if (-not $m) { Write-Error '中断: WezTerm-nightly-setup.exe.sha256 に sha256 の行が無い'; return }
     if ((Get-FileHash -LiteralPath $setup -Algorithm SHA256).Hash -ne $m.Matches[0].Groups[1].Value) { Write-Error '中断: WezTerm-nightly-setup.exe の sha256 が一致しない'; return }
     $p = Start-Process -FilePath $setup -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCLOSEAPPLICATIONS /LOG=`"$tmp\setup.log`"" -Wait -PassThru
     if ($p.ExitCode -ne 0) { Write-Error "中断: インストーラが終了コード $($p.ExitCode) で終わった（ログは $tmp\setup.log）"; return }
     Remove-Item -LiteralPath $tmp -Recurse -Force
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'WezTerm-nightly-setup.exe: sha256 一致、インストーラの終了コード 0'
     & "$dir\wezterm.exe" --version
   }
   ```

   - `WezTerm-nightly-setup.exe: sha256 一致、インストーラの終了コード 0` と、`wezterm 20260929-043349-cab25161` の形の 1 行が出ればよい
   - インストーラの画面は出ない。終わるまでプロンプトが戻らない
   - `中断:` で始まるエラーが出たら、そこで止まっている
   - `取れない` と `sha256 が一致しない` は、nightly が入れ替わる最中に取ったときにも出る。少し待って貼り直す
   - 何度貼ってもよい

1. 入ったものと、`PATH`・スタートメニューを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{BCF6F0DA-5B9A-408D-8562-F680AE6E1EAF}_is1' | Format-List DisplayName, DisplayVersion, InstallLocation, UninstallString
   & 'C:\Program Files\WezTerm\wezterm.exe' --version
   [Environment]::GetEnvironmentVariable('Path', 'Machine') -split ';' | Where-Object { $_ -like '*\WezTerm*' }
   Test-Path -LiteralPath "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\WezTerm.lnk"
   Get-ChildItem -LiteralPath 'C:\Program Files\WezTerm' -Name
   ```

   - `DisplayVersion` と `wezterm --version` の版が同じ（`20260929-043349-cab25161` の形）
   - `UninstallString` は `"C:\Program Files\WezTerm\unins000.exe"`
   - PC 全体の `PATH` に `C:\Program Files\WezTerm` が 1 行と、スタートメニューの `True` が出る
   - 最後に `wezterm.exe`・`wezterm-gui.exe`・`unins000.exe` などのファイルの名前が並ぶ
   - 開いていた PowerShell の `PATH` には入らない。新しく開いた窓（WezTerm の中も）では、`wezterm` を名前で呼べる

1. スタートメニューから WezTerm を起動し、窓が開くことを確かめる。

   - スタートメニューで「WezTerm」を探し、クリックして開く
   - 窓が開き、中でシェルが動けばよい。設定ファイルが無ければ `cmd.exe` が開く（自分用の設定では Git Bash。[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 7 で入れる）
   - 窓の中で `wezterm --version` を打つと、この項の手順 5 と同じ版が出る
   - キー操作だけ動かない場合は、[ホットキーを使用しているアプリの調査](#windows-のホットキー競合)で対象キーを調べる
   - 窓が開かずに終わったら、`%USERPROFILE%\.local\share\wezterm\wezterm-gui.exe-log-<番号>.txt` を見る
     - `The OpenGL implementation is too old to work with glium` なら、3D の描画の無い VM などで OpenGL が使えない
     - その場で開くなら、Win+R の「ファイル名を指定して実行」に `"C:\Program Files\WezTerm\wezterm-gui.exe" --config prefer_egl=true` を入れて開く（管理者の窓からは起動しない）
     - いつも開くようにするなら、設定の `config` に `config.prefer_egl = true` を足す。設定ファイルが無ければ、`%USERPROFILE%\.wezterm.lua` に `local wezterm = require 'wezterm'`・`local config = wezterm.config_builder()`・`config.prefer_egl = true`・`return config` の 4 行を書く
     - 自分用の設定（`~/.config/wezterm`）を使うなら、`~/.wezterm.lua` は作らない（[AlmaLinux 10 の初期設定の「WezTerm の設定ファイル」](almalinux-setup.md#wezterm-の設定ファイル)のとおり、clone した設定が読まれなくなる）
   - **注意**: 管理者の PowerShell から `wezterm-gui.exe` を起動しない（WezTerm と中のシェルが管理者で動く）

---

### Git Bash と WezTerm の設定

- Git の共通設定・共通の bash 設定と、自分用の WezTerm の設定を入れる
- 前提: [Git for Windows](#git-for-windows)・[WezTerm](#wezterm)を通してある。導入後に Windows を再起動するか、サインアウトしてサインインし直し、PATH を読み直してある。GitHub のアカウントがある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。この項の手順 3 からは Git Bash の窓、最後は WezTerm の Git Bash のタブ

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. Git for Windows の git の場所と版と、Git Bash があることを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Command git -All | Format-Table Source
   git --version
   Test-Path 'C:\Program Files\Git\bin\bash.exe', 'C:\Program Files\Git\git-bash.exe'
   ```

   - 1 行目の一番上に `C:\Program Files\Git\cmd\git.exe` が出ればよい
   - `git version 2.55.0.windows.5` の形の行と、`True` が 2 行出ればよい

1. スタートメニューから Git Bash を開く。

   - スタートメニューで「Git Bash」を探して開く（管理者でなくてよい）
   - `<WIN_USER>@<HOSTNAME> MINGW64 ~` のような行と、`$` のプロンプトの窓が開く
   - Git Bash の窓に貼るときは、窓の中を右クリックして出るメニューの「Paste」を選ぶ。最後の行は、貼った後に Enter を押す
   - **次の手順は、この Git Bash に貼る**

1. Git Bash に、[AlmaLinux 10 の初期設定の「Git」](almalinux-setup.md#git)の手順 1〜10 を上から順に貼る。

   - `~/.gitconfig`（`C:\Users\<WIN_USER>\.gitconfig`）に、AlmaLinux 10 と同じ基本の設定を書く。成功の条件は、同書のそれぞれの手順と同じ
   - 同書の「Git」の手順 2 では、インストーラが書いた `system` の行（`core.autocrlf=true` など）も出る
   - **この手順は、この項の手順 6・7 の clone より前に行う**（`global` の `core.autocrlf=false` が無いと、clone したファイルの改行が `system` の `core.autocrlf=true` で CRLF になる）
   - Git Bash・PowerShell・cmd の git は、同じ `~/.gitconfig` を読む
   - 戻すときは、[Git Bash の設定を戻す](extra/windows-setup.md#git-bash-の設定を戻す)で行う。共通設定に加え、この項の手順 5 で変更した Windows 専用 `core.longpaths` も記録に合わせて戻す

1. 同じ Git Bash で、元の設定を表示し、Git for Windows の長いパス対応を有効にする。

   ```bash
   printf '変更前の core.longpaths（スコープ・ファイル・値）:\n'
   git config --show-scope --show-origin --get-all core.longpaths
   if [ "$(git config --global --includes --type=bool --get core.longpaths)" != true ]; then
     git config --global core.longpaths true
   fi
   printf '\n\033[7m 確認 \033[0m\n'
   git config --global --includes --type=bool --get core.longpaths
   git config --type=bool --show-scope --show-origin --get core.longpaths
   ```

   - 「変更前」の値・スコープ・ファイルを控える。include 先も `global` の行に出る。`global` が無ければ「未設定」と控える
   - 最後の `global` の値が `true`（`yes`・`on`・`1` も同じ）なら「変更なし」、それ以外は今回変更したことも控える。変更しなかったキーは復元で触らない
   - 「確認」の後に `true` と、`global` の `true` の行が出ればよい。違う値やエラーが出たら、ここで止めて設定を確かめる
   - 対象のリポジトリで `git config --show-scope --show-origin --get core.longpaths` を確かめ、`local` の `false` が出たら、そのリポジトリの設定を見直す
   - **注意**: エクスプローラー・IDE・スクリプトなどで長いパスを扱えない場合は、リポジトリを短いパスに置く
   - 戻すときは、[ロールバックの「Git Bash の設定を戻す」](extra/windows-setup.md#git-bash-の設定を戻す)の手順 2・5・6 で行う

1. 同じ Git Bash で、共通の bash 設定を入れる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   git clone https://github.com/ryo-aoki-pc/bash.git ~/.config/bash &&
     bash ~/.config/bash/install.sh
   ```

   - [README の「共通の bash 設定を先に入れる」](../README.md#共通の-bash-設定を先に入れる)と、[AlmaLinux 10 の初期設定の「共通の bash 設定」](almalinux-setup.md#共通の-bash-設定)の手順 1 と同じブロック
   - `~/.bashrc: 設定済み（元の内容: ~/.bashrc.before-bash）` と `完了: 端末を開き直す。…` が出ればよい
   - すでに clone してあるなら `fatal: destination path … already exists` で止まる。そのときは `git -C ~/.config/bash pull --ff-only` で更新し、`bash ~/.config/bash/install.sh` を貼る

1. 自分用の WezTerm の設定（[ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm)）を入れ、WezTerm を起動し直す。

   - [WezTerm の設定を導入する](#wezterm-の設定を導入する)を通す。前提の共通の bash 設定は、この項の手順 6 で導入済み
   - その項の手順 5 で WezTerm を起動し、同じ項の手順 6 を新しい Git Bash のタブに貼って確かめる
   - Git Bash の窓は閉じてよい
   - CRLF に変換して clone 済みのリポジトリは、WezTerm の Git Bash のタブで[改行を変換して clone したリポジトリを直す](almalinux-setup.md#改行を変換して-clone-したリポジトリを直す)を通す

#### 共通の bash 設定を更新する

- 共通の bash 設定のリポジトリを更新し、端末を開き直して反映する
- 前提: [Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)を通してある
- 実行場所: この PC のデスクトップの、自分のユーザーの WezTerm の Git Bash のタブ。この項の手順 1 で開く
- 手元の変更は `git -C ~/.config/bash status` で確認してから進む

1. スタートメニューから WezTerm を開き、Git Bash の新しいタブを用意する。

   - スタートメニューで「WezTerm」を探して開く（管理者として実行しない）。開いていれば Ctrl+Shift+T で新しいタブを開く
   - `MINGW64` と `$` のプロンプトが出ればよい
   - **次の手順は、この Git Bash のタブに貼る**

1. origin を HTTPS にそろえて、設定のリポジトリを pull する。

   ```bash
   git -C ~/.config/bash remote set-url origin https://github.com/ryo-aoki-pc/bash.git
   git -C ~/.config/bash pull --ff-only
   printf '\n\033[7m 確認 \033[0m\n'
   git -C ~/.config/bash log -1 --oneline
   ```

   - 新しいコミットが無ければ `Already up to date.` と出て、最後にいちばん新しいコミットが 1 行出る
   - `set-url` は、HTTPS で clone したホストでは何も変えない。SSH で clone したホストを HTTPS にそろえる
   - インターネットに出られないホストは、[SSH の SOCKS トンネル](almalinux-setup.md#ssh-の-socks-トンネル)を張ったシェルで貼る
   - 手元で変えたファイルがあって pull が止まったら、`git -C ~/.config/bash status` で見る
   - 開いている端末には効かない。端末を開き直す

#### 共通の bash 設定を手動で移行する

- 通常の共通 bash 設定の導入が中断したときに、設定を手動で移行する
- 前提: [Git for Windows](#git-for-windows)を通してある
- 実行場所: この PC のデスクトップの、自分のユーザーの Git Bash の窓
- [AlmaLinux 10 の共通の bash 設定を手動で移行する](almalinux-setup.md#共通の-bash-設定を手動で移行する)の全手順を Git Bash で行う。WSL は WSL 側で別に行う

#### WezTerm の設定を導入する

- 自分用の WezTerm の設定を入れ、シェル統合を確かめる
- 前提: [WezTerm](#wezterm)と[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 1〜6 を通し、Git と共通の bash 設定を入れてある。HackGen Console NF は任意
- 実行場所: この項の手順 1〜5 は、WezTerm の外の、自分のユーザーの Git Bash の窓。この項の手順 6・7 は、起動し直した WezTerm の Git Bash のタブ
- この項の手順 1 で WezTerm の窓をすべて閉じる。既存設定の確認と、この項の手順 3 の退避を省かない
- [背景説明](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/reference/install.md)・[検証記録](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/verification/install.md)

1. WezTerm の窓をすべて閉じ、スタートメニューから Git Bash を開く。

   - スタートメニューで「Git Bash」を探して開く（管理者として実行しない）
   - `MINGW64` と `$` のプロンプトが出ればよい
   - **次の手順は、この Git Bash の窓に貼る**

1. 既存の WezTerm の設定があるか確かめる。

   ```bash
   ls -ld ~/.wezterm.lua ~/.config/wezterm
   ```

   - どちらかが出たら、この項の手順 3 で退避する
   - 2 行とも `No such file or directory` なら、設定は無い。この項の手順 3 は飛ばす
   - `~/.wezterm.lua` が残っていると、この設定は読まれない

1. 既存の設定があるときだけ、名前の後ろに `.bak` を付けて退避する。

   ```bash
   (
     for f in ~/.wezterm.lua ~/.config/wezterm; do
       if [ -e "$f.bak" ] || [ -L "$f.bak" ]; then
         echo "中断: $f.bak が既にある。何も退避していない" >&2
         exit 1
       fi
     done
     for f in ~/.wezterm.lua ~/.config/wezterm; do
       if [ -e "$f" ] || [ -L "$f" ]; then mv -v "$f" "$f.bak" || exit 1; fi
     done
     ls -ld ~/.wezterm.lua ~/.config/wezterm
   )
   ```

   - あったものだけ、`renamed '/home/<USER>/.config/wezterm' -> '/home/<USER>/.config/wezterm.bak'` のように出る
   - 最後の `ls` が 2 行とも `No such file or directory` ならよい
   - `.bak` が 1 つでもあれば、どちらも動かさず `中断:` で止まる。この項の手順 4 へ進まず、中身を確かめて片付けてからこの項の手順 3 を貼り直す
   - 退避したものは、[WezTerm 設定のロールバック](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/extra/install.md#ロールバック)の手順 4 で戻せる

1. この設定を `~/.config/wezterm` に clone する。

   ```bash
   git clone https://github.com/ryo-aoki-pc/wezterm.git ~/.config/wezterm
   printf '\n\033[7m 確認 \033[0m\n'
   git -C ~/.config/wezterm log -1 --oneline
   ```

   - `Cloning into '/home/<USER>/.config/wezterm'...` の後に、最新のコミットが 1 行出る
   - `fatal: destination path '/home/<USER>/.config/wezterm' already exists and is not an empty directory.` と出たら、この項の手順 2 から見直す

1. WezTerm がこの設定を読めるか確かめる。

   ```bash
   wezterm ls-fonts --text 'aあ'
   ```

   - `ERROR  wezterm_gui >` が無ければ設定を読めている。終了コードは誤りがあっても `0` なので使わない
   - `show-keys` は読み込み確認に使わず、`| head` も付けない
   - HackGen Console NF があればそのフォントで描く。無ければフォント警告が出て代替フォントを使う。画面なしでは通知の dbus エラーが出る場合もある
   - Windows でコマンドが無ければ `"/c/Program Files/WezTerm/wezterm.exe" ls-fonts --text 'aあ'` を使う

1. WezTerm のウィンドウをすべて閉じてから、起動し直す。

   - WezTerm を開いていなければ、起動するだけでよい
   - AlmaLinux 10 はアプリ一覧の「WezTerm」から、Windows 11 はスタートメニューの「WezTerm」から起動する
   - シェル統合とウィンドウ装飾は起動し直して反映する
   - **次の手順は、起動し直した WezTerm のタブで貼る**（開いていたタブで貼ると、この項の手順 7 の確かめが外れる）

1. 起動し直した WezTerm のタブで、シェル統合が読まれたか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   echo "$TERM_PROGRAM"
   echo "$WEZTERM_SHELL_INTEGRATION"
   declare -F __wezterm_set_user_var __wezterm_notify_done __wz_mouse_off
   ```

   - 1 行目は `WezTerm`、2 行目は `.config/wezterm/shell/wezterm.sh` で終わるパス
   - 3 つ目は、WezTerm のパッケージの公式のシェル統合があるかどうかで変わる
     - AlmaLinux 10（COPR の公式統合）: `__wezterm_set_user_var`・`__wezterm_notify_done`・`__wz_mouse_off` の 3 行
     - 公式の統合が無いとき（Windows の Git Bash など）: `__wezterm_notify_done` と `__wz_mouse_off` の 2 行
   - 1 行目が空なら、WezTerm の外で貼っている。2 行目が空なら、この項の手順 6 の前から開いていたタブで貼っている
   - `__wz_mouse_off` が出なければ、`~/.bashrc` の行が読まれていない。共通の bash 設定を見直す

#### WezTerm のシェル統合を WSL で使う

- WSL の bash で Windows 側の WezTerm のシェル統合を読む
- 前提: [WezTerm の設定を導入する](#wezterm-の設定を導入する)・[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)と、WSL 側の[共通の bash 設定](almalinux-setup.md#共通の-bash-設定)を通してある
- 実行場所: この PC のデスクトップの WezTerm の WSL の bash のタブ。この項の手順 1 で開く
- WSL の `~/.bashrc` の既存の変更を確かめ、Windows 側の統合を共通の bash 設定の読み込み行より後ろで読む

1. スタートメニューから WezTerm を開き、WSL のタブを用意する。

   - WezTerm の Ctrl+Shift+M の起動メニューで「AlmaLinux-10」を選ぶ
   - WSL の自分のユーザーの bash のプロンプトが出ればよい
   - **次の手順は、この WSL のタブに貼る**

1. WSL のシェルで、Windows のホームを調べ、シェル統合のスクリプトが見えるか確かめる。

   ```bash
   WIN_HOME=$(wslpath "$(cd /mnt/c && cmd.exe /c 'echo %USERPROFILE%' | tr -d '\r')")
   printf '\n\033[7m 確認 \033[0m\n'
   ls -l "$WIN_HOME/.config/wezterm/shell/wezterm.sh"
   ```

   - `/mnt/c/Users/<WIN_USER>/.config/wezterm/shell/wezterm.sh` の 1 行が出ればよい
   - `No such file or directory` なら、Windows 側の[WezTerm 設定の導入](#wezterm-の設定を導入する)を先に済ませる

1. この項の手順 2 と同じシェルで、WSL の `~/.bashrc` に読み込む行を足す。

   ```bash
   if [ -z "${WIN_HOME}" ]; then echo '中断: この項の手順 2 の WIN_HOME が空のまま' >&2; else
     echo "[ -r '$WIN_HOME/.config/wezterm/shell/wezterm.sh' ] && . '$WIN_HOME/.config/wezterm/shell/wezterm.sh'" >> ~/.bashrc
     printf '\n\033[7m 確認 \033[0m\n'
     tail -1 ~/.bashrc
   fi
   ```

   - `/mnt/c/Users/<WIN_USER>/.config/wezterm/shell/wezterm.sh` を 2 回含む 1 行が出る
   - WSL の `$HOME` は Linux 側なので、Windows 側の統合をこのパスで読む

1. WezTerm の起動メニューから、WSL のタブを開き直す。

   - `Ctrl+Shift+M` の起動メニューで、WSL のディストリビューションを選ぶ
   - **次の手順は、開き直した WSL のタブで貼る**

1. 開き直した WSL のタブで、シェル統合が読まれたか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   echo "$TERM_PROGRAM"
   declare -F __wezterm_set_user_var __wezterm_notify_done __wz_mouse_off
   ```

   - `TERM_PROGRAM` が `WezTerm`、`__wezterm_notify_done` と `__wz_mouse_off` が出ればよい。WSL に COPR の公式統合があれば `__wezterm_set_user_var` も出る

#### WezTerm の設定を更新する

- WezTerm の設定のリポジトリを更新する
- 前提: [Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)を通してある
- 実行場所: この PC のデスクトップの、自分のユーザーの WezTerm の Git Bash のタブ。この項の手順 1 で開く
- 手元の変更は `git -C ~/.config/wezterm status` で確認してから進む
- WezTerm 本体は[Git for Windows・Firefox・WezTerm を上げる](#git-for-windowsfirefoxwezterm-を上げる)で更新する

1. スタートメニューから WezTerm を開き、Git Bash の新しいタブを用意する。

   - スタートメニューで「WezTerm」を探して開く（管理者として実行しない）。開いていれば Ctrl+Shift+T で新しいタブを開く
   - `MINGW64` と `$` のプロンプトが出ればよい
   - **次の手順は、この Git Bash のタブに貼る**

1. 設定のリポジトリを pull する。

   ```bash
   git -C ~/.config/wezterm pull
   printf '\n\033[7m 確認 \033[0m\n'
   git -C ~/.config/wezterm log -1 --oneline
   ```

   - 新しいコミットが無ければ、`Already up to date.` と出る
   - 起動中の WezTerm は、ファイルが変わると設定を読み直す（効かなければ `Ctrl+Shift+R`）
   - シェル統合（`shell/`）とウィンドウの装飾の変更は、WezTerm を起動し直すまで効かない
   - 手元で変えたファイルがあって pull が止まったら、`git -C ~/.config/wezterm status` で見る

---

### シェルのツールを入れる

- scoop で fzf・zoxide・starship・eza・bat を入れ、Git Bash で確かめる
- 前提: [アプリを入れる](#アプリを入れる)の手順 2・3 と[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)を通し、scoop と Git・共通の bash 設定を入れてある。Visual C++ ランタイムも[WezTerm](#wezterm)で入れてある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。この項の手順 7・8 は WezTerm の新しい Git Bash のタブ

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. 管理者ではないことと、前提と、ほかの方法で入れた同じツールが無いかを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     PowerShell = $PSVersionTable.PSVersion.ToString()
     Admin      = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Scoop      = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git        = (Get-Command git -ErrorAction SilentlyContinue).Source
     BashConfig = Test-Path -LiteralPath "$env:USERPROFILE\.config\bash\bashrc"
     VCRuntime  = Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
     Tools      = (Get-Command fzf, zoxide, starship, eza, bat -All -ErrorAction SilentlyContinue).Source -join ', '
     Zoxide     = if (Get-Command zoxide -CommandType Application -ErrorAction SilentlyContinue) { zoxide --version } else { '' }
   } | Format-List
   ```

   - `PowerShell : 5.1.…`・`Admin : False`・`BashConfig : True`・`VCRuntime : True` ならよい。`Admin : True` なら、窓を閉じて、この項の手順 1 のとおりに開き直す
   - `Scoop` が空なら、先に[アプリを入れる](#アプリを入れる)の手順 2・3 を通す
   - `Git` が `C:\Program Files\Git\cmd\git.exe` でなければ、先に [Git for Windows](#git-for-windows)を通す
   - `BashConfig : False` なら、先に[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 6 を通す
   - `VCRuntime : False` なら、[WezTerm](#wezterm)の手順 3 を管理者の窓で行ってから、このブロックを貼り直す
   - `C:\Users\<WIN_USER>\scoop\` の下の `shims\<名前>.exe` と `apps\starship\current\starship.exe` だけなら、scoop で入れたもの（この項の手順 4 は、入っているものを飛ばす）
   - ほかの場所（winget の `…\WinGet\Links\` など）が出たら、ほかの方法で入れたものがある。その方法で外してから始める
   - `Zoxide` が空か `zoxide 0.9.9` なら、この項の手順 3 は飛ばす

1. scoop の zoxide が 0.9.9 でないときだけ、外す。

   ```powershell
   scoop uninstall zoxide
   ```

   - `'zoxide' was uninstalled.` が出ればよい

1. scoop を上げてから 5 つを入れ、zoxide を 0.9.9 に止める。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop update
   scoop install fzf starship eza bat
   scoop install zoxide@0.9.9
   scoop hold zoxide
   ```

   - `scoop update` は `Scoop was updated successfully!` を出す（Git for Windows より前に scoop を入れた PC では、初めてのときに `Converting 'main' bucket to git repo...` も出る）
   - それぞれ `'<名前>' (<版>) was installed successfully!` の形の行が出て、最後に `zoxide is now held and can not be updated anymore.` が出ればよい（zoxide は `0.9.9`）
   - zoxide の 0.9.9 は、scoop が main のバケットの git の履歴から定義を取り出して入れる（`Resolving historical manifest for 'zoxide' (0.9.9)` の行が出る）
   - 2 行目は、もう入っているものを、何も出さずに飛ばす
   - zoxide の 0.9.9 がもう入っていれば、3 行目は `'zoxide' (0.9.9) is already installed.` の警告だけを出す
   - もう止めてあれば、`'zoxide' is already held.` が出る
   - starship は shim を作らず、`Adding ~\scoop\apps\starship\current to your path.` で自分のユーザーの `Path` に足す（この窓にも入る）
   - bat は `Setting user environment variable: BAT_CONFIG_DIR = …` で環境変数を足す（この窓にも入る）
   - `Notes` の starship のプロファイル追記と、`suggests installing` の VC++ ランタイム・less の導入は行わない
   - **zoxide は 0.9.9 に固定する**。0.10.0 は Git Bash の移動を記録しない。修正版は[更新](#scoopwingetwsl-を上げる)の手順 7・8、ほかのツールは同じ項の手順 2・3 で上げる

1. 版と場所と、zoxide を止めたことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   fzf --version
   zoxide --version
   starship --version
   eza --version
   bat --version
   (Get-Command fzf, zoxide, starship, eza, bat -All).Source
   scoop list zoxide
   ```

   - それぞれの版が出ればよい（`zoxide 0.9.9`・`starship 1.26.0`・`v0.23.5 [+git]`・`bat 0.26.1` の形）
   - `bat --version` が何も出さないか、DLL が見つからない旨のエラーになったら、VC++ ランタイムが無い（この項の手順 2 の `VCRuntime`）
   - 場所は、`C:\Users\<WIN_USER>\scoop\shims\` の下の `fzf.exe`・`zoxide.exe`・`eza.exe`・`bat.exe` と、`C:\Users\<WIN_USER>\scoop\apps\starship\current\starship.exe` の 5 行だけ
   - `scoop list` の `zoxide` の行は、`Version` が `0.9.9`、`Source` が `<auto-generated>`（前から main のバケットで入れた 0.9.9 なら `main`）、`Info` が `Held package`

1. bat の設定ファイル（`BAT_CONFIG_DIR` の下の `config`）に、3 行の設定を書く（中身があれば書き換えない）。

   ```powershell
   $BAT_THEME_NAME = 'ansi'   # 使うテーマ。ansi は端末の 16 色にそのまま従う（一覧は bat --list-themes）。<BAT_THEME_NAME>
   ```

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (-not $BAT_THEME_NAME) { Write-Error '中断: BAT_THEME_NAME が空のまま。値を入れて貼り直す'; return }
     $f = if ($env:BAT_CONFIG_PATH) { $env:BAT_CONFIG_PATH } elseif ($env:BAT_CONFIG_DIR) { Join-Path $env:BAT_CONFIG_DIR 'config' } else { '' }
     if (-not $f) { Write-Error '中断: BAT_CONFIG_DIR が無い。この項の手順 4 で bat を入れたかを確かめる'; return }
     if ((Test-Path -LiteralPath $f) -and [IO.File]::ReadAllText($f).Trim()) { "中身がある（書き換えない）: $f" } else {
       Set-Content -LiteralPath $f -Encoding ASCII -Value "--theme=`"$BAT_THEME_NAME`"", '--style="numbers,changes,header"', '--paging=never' -ErrorAction Stop
       "書いた: $f"
     }
     Get-Content -LiteralPath $f
   }
   ```

   - `書いた: C:\Users\<WIN_USER>\scoop\apps\bat\current\config` と、`--theme="ansi"`・`--style="numbers,changes,header"`・`--paging=never` の 3 行が出ればよい
   - 書いた中身は、scoop の控え（`~\scoop\persist\bat\config`）に残り、bat を上げても消えない
   - `中身がある（書き換えない）:` が出たら、前からの設定（`%APPDATA%\bat\config` から scoop が写したものなど）がある。何も変えていない
   - `中断:` が出たら、何も書いていない

1. WezTerm の新しいタブ（Git Bash）で、[AlmaLinux 10 の初期設定の「シェルのツール」の手順 4〜7・9・10](almalinux-setup.md#シェルのツール)のブロックを貼る。

   - WezTerm を起動するか、新しいタブ（Ctrl+Shift+T）を開く。前から開いているタブで `. ~/.bashrc` を読み直さない（[同書の「シェルのツール」の手順 2](almalinux-setup.md#シェルのツール)の補足と同じ）
   - 新しいタブのプロンプトが starship の形にならなければ、WezTerm の窓をすべて閉じて起動し直す
   - 成功の条件は、同書のそれぞれの手順と同じ。違うのは次のところ
     - `command -v` は `/c/Users/<WIN_USER>/scoop/shims/<名前>`（starship は `/c/Users/<WIN_USER>/scoop/apps/starship/current/starship`）。版は、この項の手順 5 と同じ
     - 同書の「シェルのツール」の手順 5 の `bind -X` は、`"\C-r" "__fzf_history__"` のようにコロンの無い形で出る（Git Bash の bash 5.3）。WezTerm のシェル統合を読んでいれば、マウス報告よけの行も出る（そのままでよい）
     - 同書の「シェルのツール」の手順 6 の見出しは、`Permissions` が `Mode` になり、`User` の列が無い。`Git` の列が出ればよい。`ll` は、Git for Windows の `ls -l` ではなく eza になる
     - 同書の「シェルのツール」の手順 7 で `/etc/os-release` が無い旨のエラーが出たら、そのコマンドを `~/.bashrc` に変えて打つ。`MANPAGER` は `bat -plman` と出るが、Git Bash に `man` は無い
     - 同書の「シェルのツール」の手順 9 の `cd /usr/share` は、Git for Windows の `C:\Program Files\Git\usr\share` に移る。同書の「シェルのツール」の手順 10 の一覧には、その形（`C:\…`）で出る
   - 同書の「シェルのツール」の手順 8（tmux）は行わない
   - `~/.bashrc` には追記しない。Windows PowerShell 5.1 には読み込まない

1. 同じタブで、[同書の「キー操作を試す」の手順 2〜5](almalinux-setup.md#キー操作を試す)のキーを押して、fzf を確かめる。

   - 同書の「キー操作を試す」の手順 2 の `fzf --version` は、この項の手順 7 で Git Bash の履歴に入っている
   - 同書の「キー操作を試す」の手順 3 をホーム（`C:\Users\<WIN_USER>`）で行うと、`AppData` の下のファイルも一覧に入る
   - 同書の「キー操作を試す」の手順 4 の `doc/bash` が一覧に無ければ、一覧にある別の語で絞る（`/usr/share` は Git for Windows のもの）
   - 日本語など ASCII 以外の文字では、絞り込めないことがある（Windows の fzf は、画面の一部に開いた一覧では ASCII 以外の文字を読めない）
   - [fzf で fd と bat を候補とプレビューに使う](almalinux-setup.md#fzf-で-fd-と-bat-を候補とプレビューに使う)も通せる。そちらの `brew install fd`・`brew uninstall fd` は、通常の PowerShell で `scoop install fd`・`scoop uninstall fd` にする。導入済みなら省く
   - bat の設定にはこの項の手順 6を使う

---

### PowerShell 7 のプロファイルを設定する

- PowerShell 7 に貼り付け・↑/↓ の履歴検索と、導入済みの zoxide・starship を読む設定を足す
- 前提: [貼り付けの設定](#貼り付けの設定)の手順 1〜5 と[アプリを入れる](#アプリを入れる)の手順 6 を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。この項の手順 6 は PowerShell 7 の窓
- 対象は `Documents\PowerShell\Microsoft.PowerShell_profile.ps1`。Windows PowerShell 5.1 のプロファイルとは別
- 足す行は ASCII の文字だけで、行末に印 `# windows-setup.md` を付ける
- zoxide と starship は、入れていなければ読まない。入れた後に PowerShell 7 を開き直せば読む
- Windows Terminal の既定のプロファイルは Windows PowerShell のまま変えない
- 戻すときは、この項の手順 7・8（行った手順のものだけ）

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. PowerShell 7 のプロファイルに、貼り付けと履歴の検索のキーと、zoxide・starship を読む行を足す。

   ```powershell
   & {
     $p = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
     $lines = @(
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine }  # windows-setup.md'
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward }  # windows-setup.md'
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward }  # windows-setup.md'
       'if (Get-Command -Name zoxide -CommandType Application -ErrorAction Ignore) { Invoke-Expression (& { (zoxide init powershell | Out-String) }) }  # windows-setup.md'
       'if (Get-Command -Name starship -CommandType Application -ErrorAction Ignore) { function global:Invoke-Starship-PreCommand { if (Test-Path -Path Function:\__zoxide_hook) { $null = __zoxide_hook } }; Invoke-Expression (& starship init powershell) }  # windows-setup.md'
     )
     if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType File -Path $p -Force -ErrorAction Stop | Out-Null }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($line in $lines) {
       $text = Get-Content -LiteralPath $p -Raw
       if ($text -and $text.Contains($line)) { "すでにある: $line" } else {
         $add = $line
         if ($text -and -not $text.EndsWith("`n")) { $add = "`r`n" + $line }
         Add-Content -LiteralPath $p -Value $add -ErrorAction Stop
         "足した: $line"
       }
     }
     "--- $p"
     Get-Content -LiteralPath $p
   }
   ```

   - 5 行それぞれに `足した:` か `すでにある:` が出て、最後にプロファイルの中身が出ればよい
   - プロファイルは `C:\Users\<WIN_USER>\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`（OneDrive でドキュメントをバックアップしていると、`OneDrive` の下）
   - 何度貼ってもよい
   - 開いている PowerShell 7 の窓には、開き直すまで効かない

1. Tab で補完の候補の一覧を出すときだけ、Tab の行を足す。

   ```powershell
   & {
     $p = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
     $line = 'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete }  # windows-setup.md'
     if (-not (Test-Path -LiteralPath $p)) { Write-Error "中断: プロファイルが無い。この項の手順 2 を先に貼る: $p"; return }
     $text = Get-Content -LiteralPath $p -Raw
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($text -and $text.Contains($line)) { "すでにある: $line" } else {
       $add = $line
       if ($text -and -not $text.EndsWith("`n")) { $add = "`r`n" + $line }
       Add-Content -LiteralPath $p -Value $add -ErrorAction Stop
       "足した: $line"
     }
   }
   ```

   - `足した:` か `すでにある:` が出ればよい
   - Tab で、候補が一覧で出る（矢印で選んで Enter、Esc で取り消す）

1. PowerShell 7 で、実行ポリシーとキーの割り当てを確かめる。

   ```powershell
   pwsh.exe -NoLogo -NoProfile -Command { Get-ExecutionPolicy -List | Out-String -Width 120; Import-Module PSReadLine; . $PROFILE; Get-PSReadLineKeyHandler -Bound | Where-Object Key -in 'Ctrl+Enter', 'UpArrow', 'DownArrow', 'Tab' | Format-Table Key, Function -AutoSize | Out-String -Width 120 }
   ```

   - 次のとおりならよい
     - 実行ポリシーの表の `LocalMachine` か `CurrentUser` が `RemoteSigned`
     - キーの表の `Ctrl+Enter` が `AddLine`、`UpArrow` が `HistorySearchBackward`、`DownArrow` が `HistorySearchForward`（この項の手順 3 を行ったなら、`Tab` が `MenuComplete`）
   - `pwsh.exe` が見つからない旨が出たら、[アプリを入れる](#アプリを入れる)の手順 6 を確かめる
   - 実行ポリシーがどれも `Undefined` なら、プロファイルは読まれず、キーは既定のまま（`Ctrl+Enter` が `InsertLineAbove`）。そうでなければ、この項の手順 5 は飛ばす

1. 実行ポリシーがどれも `Undefined` のときだけ、PowerShell 7 の CurrentUser を RemoteSigned にする。

   ```powershell
   pwsh.exe -NoLogo -NoProfile -Command { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; Get-ExecutionPolicy -List }
   ```

   - 表の `CurrentUser` が `RemoteSigned` になればよい
   - この項の手順 4 をもう一度貼って、キーの割り当てを確かめる

1. スタートメニューから PowerShell 7 を開き、キーとプロンプトを確かめる。

   - スタートメニューで「PowerShell」を探し、「Windows PowerShell」ではない「PowerShell」（PowerShell 7）をクリックして開く（一覧の名前に 7 は付かないことがある）
   - 何か打ってから ↑ を押すと、打った文字で始まる履歴だけが出る
   - 打っている途中に、履歴からの候補が薄い文字で出る（PowerShell 7 の既定の予測。→ で受け入れ、F2 で一覧の表示に切り替わる）
   - starship を入れていればプロンプトが starship の形になり、zoxide を入れていれば `z` が使える
   - Ctrl+Alt+? で、キーの割り当ての一覧が出る
   - **次の手順は、PowerShell 7 の窓を `exit` で閉じてから、この項の手順 1 の窓に貼る**

1. 元に戻すときは、PowerShell 7 のプロファイルから、この項で足した行を消す。

   ```powershell
   & {
     $p = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
     if (-not (Test-Path -LiteralPath $p)) { "プロファイルが無い: $p"; return }
     $bytes = [System.IO.File]::ReadAllBytes($p)
     $enc = if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { [System.Text.Encoding]::Unicode } else { [System.Text.Encoding]::GetEncoding(28591) }
     $text = $enc.GetString($bytes)
     $rest = [regex]::Replace($text, '(?m)^(\uFEFF|\u00EF\u00BB\u00BF)?[^\r\n]*  # windows-setup\.md\r?(\n|$)', '$1')
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($rest -eq $text) { "その行は無い: $p" } elseif ($rest -match '^(\uFEFF|\u00EF\u00BB\u00BF)?\s*$') { Remove-Item -LiteralPath $p; "消した: $p" } else { [System.IO.File]::WriteAllBytes($p, $enc.GetBytes($rest)); "その行だけ消した: $p" }
   }
   ```

   - プロファイルにほかの行が無ければ `消した:`、あれば `その行だけ消した:` が出る
   - 開いている PowerShell 7 の窓には、閉じるまで設定が残る

1. 元に戻すときは（この項の手順 5 を行ったとき）、PowerShell 7 の CurrentUser の実行ポリシーを戻す。

   ```powershell
   pwsh.exe -NoLogo -NoProfile -Command { Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope CurrentUser -Force; Get-ExecutionPolicy -List }
   ```

   - 表の `CurrentUser` が `Undefined` ならよい

---

## SSH

- OpenSSH のサーバーとクライアント、SSH の認証とログインのシェル

### OpenSSH サーバー

- LAN からこの PC に SSH でログインできるように、OpenSSH サーバーを入れる
- 前提: [ネットワークとリモート](#ネットワークとリモート)の手順 3 を通し、LAN の接続をプライベートにしてある
- 実行場所: この PC のデスクトップの管理者の Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、右クリックして「管理者として実行」を選ぶ（PowerShell 7 の「PowerShell」ではない）
   - ユーザーアカウント制御（UAC）の確認は「はい」

1. LAN の接続の変数を設定する。

   ```powershell
   $LAN_IF = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).InterfaceAlias   # ほかの PC とつながる LAN の接続（自動）。<LAN_IF>
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'LAN_IF = {0}' -f $LAN_IF
   ```

   - インターネットにつながっている接続の名前が入る。ほかの PC とつながる接続と違うか空なら、`$LAN_IF = 'Wi-Fi'` のように直す
   - 最後に値を読み戻して確かめる
   - **新しい PowerShell を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. OpenSSH サーバーの機能を入れる。

   ```powershell
   if ($PSVersionTable.PSEdition -ne 'Desktop') {
     Write-Error 'Windows PowerShell（5.1）で貼る。PowerShell 7 では Add-WindowsCapability が失敗する'
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
     Get-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Format-List Name, State
   }
   ```

   - 数分かかる
   - `RestartNeeded : False` と `State : Installed` が出ればよい
   - 既に入っていれば、すぐに `State : Installed` が出る

1. sshd を自動で起動するようにして起動し、待ち受けを確かめる。

   ```powershell
   Set-Service -Name sshd -StartupType Automatic
   Start-Service -Name sshd
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Service -Name sshd | Format-Table Name, Status, StartType
   Get-NetTCPConnection -State Listen -LocalPort 22 | Format-Table LocalAddress, LocalPort, OwningProcess
   ```

   - `sshd  Running  Automatic` が出る
   - 22 番で `0.0.0.0` と `::` の 2 行が出ればよい

1. LAN の接続がプライベートなことと、sshd の受信の規則を確かめる。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error '中断: この項の手順 2 の $LAN_IF が空'
   } elseif ((Get-NetConnectionProfile -InterfaceAlias $LAN_IF).NetworkCategory -ne 'Private') {
     Write-Error '中断: LAN の接続がプライベートではない（「ネットワークとリモート」の手順 3 でプライベートにする）'
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-NetConnectionProfile -InterfaceAlias $LAN_IF | Format-Table InterfaceAlias, NetworkCategory
     Get-NetFirewallRule -Name OpenSSH-Server-In-TCP | Format-Table Name, Enabled, Profile, Direction, Action
   }
   ```

   - `<LAN_IF>  Private` と、`OpenSSH-Server-In-TCP  True  Private  Inbound  Allow` が出ればよい
   - `中断:` が出たら、[ネットワークとリモート](#ネットワークとリモート)の手順 3 でプライベートにして貼り直す。この項の手順 2 の変数を貼り直す
   - **注意**: プライベートの LAN では、ネットワーク探索など、ほかのプライベート向けの許可も効く

1. パスワード認証を有効にし、設定を検査してから sshd を再起動する。

   ```powershell
   $c = "$env:ProgramData\ssh\sshd_config"
   (Get-Content $c) -replace '^#?PasswordAuthentication .*', 'PasswordAuthentication yes' | Set-Content $c -Encoding ascii
   & "$env:WINDIR\System32\OpenSSH\sshd.exe" -t
   if ($LASTEXITCODE -eq 0) { Restart-Service -Name sshd } else { Write-Error 'sshd_config に誤りがある（sshd は再起動していない）' }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Select-String -Path $c -Pattern '^PasswordAuthentication', '^Match'
   ```

   - `…sshd_config:51:PasswordAuthentication yes` と `…sshd_config:87:Match Group administrators` が出ればよい

1. 接続先と、ホスト鍵の指紋を表示する。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error '中断: この項の手順 2 の $LAN_IF が空'
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     '{0}@{1}' -f $env:USERNAME, (Get-NetIPAddress -InterfaceAlias $LAN_IF -AddressFamily IPv4).IPAddress
     & "$env:WINDIR\System32\OpenSSH\ssh-keygen.exe" -lf "$env:ProgramData\ssh\ssh_host_ed25519_key.pub"
   }
   ```

   - 1 行目の `<WIN_USER>@<WIN_HOST>` を控える（[SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 4 で使う）
   - 2 行目の `256 SHA256:<指紋> system@<HOSTNAME> (ED25519)` も控え、[SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 5 の初回の接続で照合する

---

### SSH でログインを確かめる

- Linux または WSL のクライアントから、この Windows の PC にパスワードでログインして確かめる
- 前提: [OpenSSH サーバー](#openssh-サーバー)を通し、接続先とホスト鍵の指紋を控えてある。この PC の WSL をクライアントにするなら、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)も通してある
- 実行場所: Linux のクライアントの、自分のユーザーの端末（bash）。この PC の WSL を使う場合は、この項の手順 1 の通常の Windows PowerShell（5.1）から開く

1. クライアントの端末を用意する。

   - Linux のクライアントでは、自分のユーザーの端末（bash）を開く
   - この PC の WSL を使うなら、スタートメニューで「Windows PowerShell」を探してクリックし、管理者ではない Windows PowerShell（5.1）を開く

1. この PC の WSL をクライアントに使うときだけ、AlmaLinux 10 のシェルに入る。

   ```powershell
   wsl.exe --distribution AlmaLinux-10 --cd ~
   ```

   - この項の手順 1 で開いた PowerShell に貼る。`[<ユーザー>@<HOSTNAME> ~]$` のプロンプトになればよい
   - ほかの PC（AlmaLinux 10 など）をクライアントにするなら、この項の手順 1 で開いた端末を使い、このブロックは貼らない
   - WSL のネットワークが既定（NAT）なら、この PC の LAN の IP（`<WIN_HOST>`）あてにつなぐ（[注意点](extra/windows-setup.md#注意点)の WSL からつなぐとき）
   - **次の手順は、クライアントのシェルに貼る**

1. クライアントに `ssh` が無いときだけ、入れる。

   ```bash
   command -v ssh || sudo dnf install -y openssh-clients
   ```

   - `/usr/bin/ssh` が出れば、入っている（何も入れない）
   - 入れるときは、`sudo` のパスワード（WSL では[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 3 で決めたもの）を聞かれる
   - **次の手順は、`Complete!` が出てプロンプトに戻ってから貼る**（続けて貼るとパスワードとして食われる）

1. クライアントのシェルで、変数を設定する（`WIN_HOST` は必ず値を入れる）。

   ```bash
   WIN_HOST=                             # ← 「OpenSSH サーバー」の手順 7 で控えた @ の後ろ（Windows の IP アドレス）を書く。<WIN_HOST>
   ```

   ```bash
   WIN_USER=${USER}                      # Windows のユーザー名。「OpenSSH サーバー」の手順 7 の @ の前と違えば直す。<WIN_USER>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in WIN_HOST WIN_USER; do
     printf '%-8s = %s\n' "$v" "${!v}"
   done
   ```

   - 最後に値を読み戻して確かめる
   - **新しいシェルを開いたら**、この項の手順 4 の 2 つのブロックを貼り直してから先へ進む

1. クライアントのシェルで、ホスト鍵を照合し、パスワードでログインする。

   ```bash
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: この項の手順 4 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh -o PubkeyAuthentication=no "${WIN_USER}@${WIN_HOST}"
   fi
   ```

   - 初回は `ED25519 key fingerprint is SHA256:…` と `Are you sure you want to continue connecting (yes/no/[fingerprint])?` が出る。[OpenSSH サーバー](#openssh-サーバー)の手順 7 で控えた指紋と同じなら `yes`
   - `<WIN_USER>@<WIN_HOST>'s password:` で、Windows のユーザーのパスワードを入れる（Microsoft アカウントなら、そのアカウントのパスワード。PIN ではない）
   - `<WIN_USER>@<HOSTNAME> C:\Users\<WIN_USER>>` の cmd のプロンプトが出ればよい。`whoami` で `<hostname>\<win_user>`（小文字）が出る
     - [SSH の既定のシェルを Git Bash にする](#ssh-の既定のシェルを-git-bash-にする)の後は、`<WIN_USER>@<HOSTNAME> MINGW64 ~` のプロンプトになり、`whoami`（Git のもの）は `<WIN_USER>` だけを出す
   - `exit` でクライアントのシェルに戻る
   - Git Bash を既定にした後、PowerShell の操作をするなら、[SSH で管理者・非管理者の PowerShell を使う](#ssh-で管理者非管理者の-powershell-を使う)を行う
   - **注意**: パスワードを続けて間違えると、Windows のロックアウトのポリシーでアカウントがロックされる（[注意点](extra/windows-setup.md#注意点)）
   - WSL の AlmaLinux 10 をクライアントにしたときは、続けてもう一度 `exit` を打ち、PowerShell に戻る
   - **ほかのブロックは、SSH を `exit` で閉じてから貼る**（続けて貼ると Windows 側への入力として食われる）

---

### OpenSSH サーバーに公開鍵でもログインする

- クライアントで作った鍵で、パスワードを入れずにこの Windows の PC に入れるようにする
- 前提: [SSH でログインを確かめる](#ssh-でログインを確かめる)を通し、クライアントからログインできる。この PC の WSL をクライアントにするなら、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)も通してある
- 実行場所: この項の手順 1 で開く、Windows の管理者の Windows PowerShell（5.1）とクライアントの bash。この項の手順 2〜4・7 はクライアント、手順 5・6 は Windows
- パスワード認証は有効のまま
- 登録できるのは、Administrators の一員のユーザーの鍵だけ（この項の手順 6 で確かめる。標準ユーザーは[注意点](extra/windows-setup.md#注意点)）
- 登録した鍵を持つ人も、パスワードを知る人と同じく、この PC の管理者として操作できる（[注意点](extra/windows-setup.md#注意点)）

1. Windows の管理者の Windows PowerShell（5.1）と、クライアントの bash を開く。

   - Windows のスタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く。UAC の確認が出たら「はい」
   - Linux のクライアントでは、自分のユーザーの端末（bash）を開く
   - この PC の WSL をクライアントにするなら、Win+R で `wsl.exe --distribution AlmaLinux-10 --cd ~` を開く
   - **次の手順は、クライアントの bash に貼る**

1. クライアントの bash で、変数を設定する（`WIN_HOST` は必ず値を入れる）。

   ```bash
   WIN_HOST=                             # ← 「OpenSSH サーバー」の手順 7 で控えた @ の後ろ（Windows の IP アドレス）を書く。<WIN_HOST>
   ```

   ```bash
   WIN_USER=${USER}                      # Windows のユーザー名。「OpenSSH サーバー」の手順 7 の @ の前と違えば直す。<WIN_USER>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in WIN_HOST WIN_USER; do
     printf '%-8s = %s\n' "$v" "${!v}"
   done
   ```

   - [SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 4 と同じ値を入れる
   - 最後に値を読み戻して確かめる
   - **新しいクライアントのシェルを開いたら**、この項の手順 2 のブロックを貼り直してから先へ進む

1. クライアントの PC で、鍵ペアが無ければ作る。

   ```bash
   ls ~/.ssh/id_ed25519.pub 2>/dev/null || ssh-keygen -t ed25519
   ```

   - 鍵があれば、`/home/<USER>/.ssh/id_ed25519.pub` と出て何もしない（その鍵を使う）
   - 無ければ、保存先（Enter で既定の `~/.ssh/id_ed25519`）とパスフレーズ（2 回）を聞かれる
   - **次の手順は、パスフレーズを入力し終えてから貼る**（続けて貼るとパスフレーズとして食われる）

1. クライアントの PC で、公開鍵を表示する。

   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

   - `ssh-ed25519 AAAA… <USER>@<HOSTNAME>` の 1 行が出る。この 1 行をコピーし、この項の手順 5 で Windows に貼る
   - 公開鍵は秘密ではない。チャットやメールで Windows 側へ渡してもよい

1. Windows の管理者の PowerShell で、変数を設定する（`$PUBKEY` は必ず値を入れる）。

   ```powershell
   $PUBKEY = ''                          # ← この項の手順 4 の 1 行を '' の中に貼る。<PUBKEY>
   ```

   ```powershell
   'PUBKEY = {0}' -f $PUBKEY
   ```

   - 改行を入れずに 1 行のまま貼る
   - 最後に値を読み戻して確かめる
   - **新しい PowerShell を開いたら**、この手順の 2 つのブロックを貼り直してから先へ進む

1. 公開鍵を `administrators_authorized_keys` に登録する。

   ```powershell
   if ($PUBKEY -notmatch '^(ssh-|ecdsa-|sk-)') {
     Write-Error 'この項の手順 5 の $PUBKEY が空か、公開鍵の形でない'
   } elseif (-not (Get-LocalGroupMember -SID S-1-5-32-544 | Where-Object Name -like "*\$env:USERNAME")) {
     Write-Error "$env:USERNAME は Administrators の一員ではない（注意点を見る）"
   } else {
     $f = "$env:ProgramData\ssh\administrators_authorized_keys"
     Add-Content -Path $f -Value $PUBKEY -Encoding ascii
     icacls.exe $f /inheritance:r /grant '*S-1-5-32-544:F' /grant '*S-1-5-18:F'
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     icacls.exe $f
   }
   ```

   - 最後の `icacls` に、`NT AUTHORITY\SYSTEM:(F)` と `BUILTIN\Administrators:(F)` の 2 行だけが出ればよい
   - クライアントを足すときは、そのクライアントでこの項の手順 3・4 を行い、この項の手順 5 の `$PUBKEY` を貼り直してから、この項の手順 6 を貼る

1. クライアントの PC で、鍵で入れることを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: この項の手順 2 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh -o PasswordAuthentication=no "${WIN_USER}@${WIN_HOST}" whoami
   fi
   ```

   - パスワードを聞かれずに、`<hostname>\<win_user>` が出ればよい（パスフレーズを付けたなら、それを聞かれる）
   - 既定のシェルを Git Bash にした PC では、Git の `whoami` が動き、`<WIN_USER>` だけが出る

---

### OpenSSH サーバーのパスワード認証を切る

- 鍵を持たない相手からのパスワード認証を受け付けないようにする
- 前提: [OpenSSH サーバーに公開鍵でもログインする](#openssh-サーバーに公開鍵でもログインする)を通し、使うクライアントが鍵で入れる。この PC の WSL をクライアントにするなら、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)も通してある
- 実行場所: この項の手順 1 で開く、Windows の管理者の Windows PowerShell（5.1）とクライアントの bash。この項の手順 2・4 はクライアント、手順 3 は Windows
- 切った後は、鍵を登録していないクライアント（スマートフォンのアプリなど）からは入れない
- パスワード認証に戻すときは、[OpenSSH サーバー](#openssh-サーバー)の手順 6 を貼り直す

1. Windows の管理者の Windows PowerShell（5.1）と、クライアントの bash を開く。

   - Windows のスタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く。UAC の確認が出たら「はい」
   - Linux のクライアントでは、自分のユーザーの端末（bash）を開く
   - この PC の WSL をクライアントにするなら、Win+R で `wsl.exe --distribution AlmaLinux-10 --cd ~` を開く
   - **次の手順は、クライアントの bash に貼る**

1. クライアントの bash で、変数を設定する（`WIN_HOST` は必ず値を入れる）。

   ```bash
   WIN_HOST=                             # ← 「OpenSSH サーバー」の手順 7 で控えた @ の後ろ（Windows の IP アドレス）を書く。<WIN_HOST>
   ```

   ```bash
   WIN_USER=${USER}                      # Windows のユーザー名。「OpenSSH サーバー」の手順 7 の @ の前と違えば直す。<WIN_USER>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in WIN_HOST WIN_USER; do
     printf '%-8s = %s\n' "$v" "${!v}"
   done
   ```

   - [SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 4 と同じ値を入れる
   - 最後に値を読み戻して確かめる
   - **新しいクライアントのシェルを開いたら**、この項の手順 2 のブロックを貼り直してから先へ進む

1. Windows で、パスワード認証を切り、設定を検査してから sshd を再起動する。

   ```powershell
   $c = "$env:ProgramData\ssh\sshd_config"
   (Get-Content $c) -replace '^#?PasswordAuthentication .*', 'PasswordAuthentication no' | Set-Content $c -Encoding ascii
   & "$env:WINDIR\System32\OpenSSH\sshd.exe" -t
   if ($LASTEXITCODE -eq 0) { Restart-Service -Name sshd } else { Write-Error 'sshd_config に誤りがある（sshd は再起動していない）' }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Select-String -Path $c -Pattern '^PasswordAuthentication', '^Match', 'administrators_authorized_keys'
   ```

   - `…sshd_config:51:PasswordAuthentication no` と、`Match Group administrators` とその次の `AuthorizedKeysFile` の行が出ればよい

1. クライアントの PC で、鍵が無いと入れず、鍵ではコマンドが通ることを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: この項の手順 2 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh -o PubkeyAuthentication=no "${WIN_USER}@${WIN_HOST}" true
     ssh "${WIN_USER}@${WIN_HOST}" whoami
   fi
   ```

   - 1 つ目は、パスワードを聞かずに `<WIN_USER>@<WIN_HOST>: Permission denied (publickey,keyboard-interactive).` で失敗すればよい
   - 2 つ目は、`<hostname>\<win_user>` が出ればよい（パスフレーズを付けたなら、それを聞かれる）
     - 既定のシェルを Git Bash にした PC では、Git の `whoami` が動き、`<WIN_USER>` だけが出る

---

### SSH の既定のシェルを Git Bash にする

- SSH でログインしたときとコマンドを実行するときのシェルを、cmd.exe から Git Bash に変える
- 前提: [SSH でログインを確かめる](#ssh-でログインを確かめる)と[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)を通してある。この PC の WSL をクライアントにするなら、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)も通してある
- 実行場所: この項の手順 1 で開く、Windows の管理者の Windows PowerShell（5.1）とクライアントの bash。この項の手順 2・4 はクライアント、手順 3・5 は Windows

1. Windows の管理者の Windows PowerShell（5.1）と、クライアントの bash を開く。

   - Windows のスタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く。UAC の確認が出たら「はい」
   - Linux のクライアントでは、自分のユーザーの端末（bash）を開く
   - この PC の WSL をクライアントにするなら、Win+R で `wsl.exe --distribution AlmaLinux-10 --cd ~` を開く
   - **次の手順は、クライアントの bash に貼る**

1. クライアントの bash で、変数を設定する（`WIN_HOST` は必ず値を入れる）。

   ```bash
   WIN_HOST=                             # ← 「OpenSSH サーバー」の手順 7 で控えた @ の後ろ（Windows の IP アドレス）を書く。<WIN_HOST>
   ```

   ```bash
   WIN_USER=${USER}                      # Windows のユーザー名。「OpenSSH サーバー」の手順 7 の @ の前と違えば直す。<WIN_USER>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in WIN_HOST WIN_USER; do
     printf '%-8s = %s\n' "$v" "${!v}"
   done
   ```

   - [SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 4 と同じ値を入れる
   - 最後に値を読み戻して確かめる
   - **新しいクライアントのシェルを開いたら**、この項の手順 2 のブロックを貼り直してから先へ進む

1. Windows で、既定のシェルを Git Bash にする。

   ```powershell
   if (-not (Test-Path 'C:\Program Files\Git\bin\bash.exe')) {
     Write-Error 'C:\Program Files\Git\bin\bash.exe が無い（Git for Windows が入っていない）'
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     New-ItemProperty -Path HKLM:\SOFTWARE\OpenSSH -Name DefaultShell -Value 'C:\Program Files\Git\bin\bash.exe' -PropertyType String -Force | Format-List DefaultShell
   }
   ```

   - `DefaultShell : C:\Program Files\Git\bin\bash.exe` が出ればよい

1. クライアントの PC で、bash になったことを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: この項の手順 2 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh "${WIN_USER}@${WIN_HOST}" 'echo "$BASH_VERSION $MSYSTEM"; git --version'
     ssh "${WIN_USER}@${WIN_HOST}"
   fi
   ```

   - 鍵を登録していなければ、パスワードを 2 回聞かれる
   - 1 つ目で `5.3.15(1)-release MINGW64` と `git version 2.55.0.windows.3` のような 2 行が出ればよい
   - 2 つ目は、`<WIN_USER>@<HOSTNAME> MINGW64 ~` と `$` のプロンプトになる。`exit` で戻る
   - **注意**: コマンドを実行するときも、Windows 側の `~/.bashrc` が読まれる
   - `Shim: Could not create process …` が出るなら、[scoop のツールを SSH のセッションで使う](#scoop-のツールを-ssh-のセッションで使う)を行う
   - **次の手順は、`exit` でクライアントの bash に戻ってから Windows の管理者の PowerShell に貼る**（続けて貼ると SSH 先への入力として食われる）

1. 元に戻すときは、`DefaultShell` を消す。

   ```powershell
   Remove-ItemProperty -Path HKLM:\SOFTWARE\OpenSSH -Name DefaultShell
   ```

   - 何も出ずに終わればよい

---

### scoop のツールを SSH のセッションで使う

- SSH で起動できない scoop のツールのジャンクションを、管理者で同じ向き先に作り直す
- 前提: [アプリを入れる](#アプリを入れる)の手順 2・3・[SSH の既定のシェルを Git Bash にする](#ssh-の既定のシェルを-git-bash-にする)・[シェルのツールを入れる](#シェルのツールを入れる)を通してある。この PC の WSL をクライアントにするなら、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)も通してある
- 実行場所: この項の手順 1 で開く、Windows の管理者の Windows PowerShell（5.1）とクライアントの bash。この項の手順 2・4 はクライアント、手順 3 は Windows
- 症状は、scoop の shim の `Could not create process with command …`、Git Bash の `Is a directory`、Windows のエラー 448
- `scoop install`・`scoop update` の後は、この項の手順 3 を貼り直す

1. Windows の管理者の Windows PowerShell（5.1）と、クライアントの bash を開く。

   - Windows のスタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く。UAC の確認が出たら「はい」
   - Linux のクライアントでは、自分のユーザーの端末（bash）を開く
   - この PC の WSL をクライアントにするなら、Win+R で `wsl.exe --distribution AlmaLinux-10 --cd ~` を開く
   - **次の手順は、クライアントの bash に貼る**

1. クライアントの bash で、変数を設定する（`WIN_HOST` は必ず値を入れる）。

   ```bash
   WIN_HOST=                             # ← 「OpenSSH サーバー」の手順 7 で控えた @ の後ろ（Windows の IP アドレス）を書く。<WIN_HOST>
   ```

   ```bash
   WIN_USER=${USER}                      # Windows のユーザー名。「OpenSSH サーバー」の手順 7 の @ の前と違えば直す。<WIN_USER>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in WIN_HOST WIN_USER; do
     printf '%-8s = %s\n' "$v" "${!v}"
   done
   ```

   - [SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 4 と同じ値を入れる
   - 最後に値を読み戻して確かめる
   - **新しいクライアントのシェルを開いたら**、この項の手順 2 のブロックを貼り直してから先へ進む

1. Windows で、scoop のジャンクションを管理者で作り直す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ChildItem "$env:USERPROFILE\scoop\apps" -Recurse -Depth 4 -Force -Attributes ReparsePoint -ErrorAction SilentlyContinue |
     Where-Object { $_.LinkType -eq 'Junction' -and (Get-Acl $_.FullName).Owner -notlike '*\Administrators' } |
     ForEach-Object {
       $link = $_.FullName; $target = @($_.Target)[0]; $ro = $_.Attributes -band [IO.FileAttributes]::ReadOnly
       if (Test-Path -LiteralPath $target) {
         attrib.exe -R "$link" /L
         cmd.exe /c rmdir "$link"
         New-Item -ItemType Junction -Path $link -Target $target | Out-Null
         if ($ro) { attrib.exe +R "$link" /L }
         '{0} -> {1}' -f $link, $target
       }
     }
   ```

   - 作り直したジャンクションごとに、`…\scoop\apps\<アプリ>\current -> …\scoop\apps\<アプリ>\<版>` の形の行が出る
   - 作り直すものが無ければ、何も出ない

1. クライアントの PC で、scoop のツールが動くことを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: この項の手順 2 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh "${WIN_USER}@${WIN_HOST}" 'zoxide --version'
   fi
   ```

   - 鍵を登録していなければ、パスワードを聞かれる
   - `zoxide 0.9.9` のような版が出て、`Shim:` で始まる行が出なければよい（`zoxide` の代わりに、scoop で入れたほかのツールでもよい）

---

### SSH で管理者・非管理者の PowerShell を使う

- WezTerm からこの Windows の PC に SSH で入り、管理者と同じユーザーの非管理者の PowerShell を切り替える
- 前提: [SSH でログインを確かめる](#ssh-でログインを確かめる)・[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)・[SSH の既定のシェルを Git Bash にする](#ssh-の既定のシェルを-git-bash-にする)を通してある。接続元も WezTerm の設定を入れてある（Windows は[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)、Linux は[WezTerm の設定の導入](almalinux-setup.md#wezterm-の設定を導入する)）
- 実行場所: 接続元の WezTerm の bash のタブ。この項の手順 1 で開く。接続後は各手順に書いた SSH 先の Git Bash・PowerShell
- 基本は Windows PowerShell 5.1。7 を使うなら、[アプリを入れる](#アプリを入れる)の手順 6 も通してあること
- **この項の手順 7 が終わるまでは、PowerShell に確認用以外の複数行ブロックを貼らない**
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-setup.md#付録-ssh-の-powershell-操作と貼り付けの検証2026-10-12-jst)・[参考資料](reference/windows-setup.md#ssh-で管理者非管理者の-powershell-を使う-選択した方針)・[専用の実行ファイルを外す](extra/windows-setup.md#ssh-の降格用の実行ファイルを外す)

> [!WARNING]
> **この項の手順 11 で子を閉じると、管理者の親 PowerShell へ戻る**。この項の手順 12 で権限を確認してから操作する。

1. 接続元と Windows の WezTerm の設定を更新し、接続元の bash のタブを開く。

   - [SSH 貼り付け修正の PR #41](https://github.com/ryo-aoki-pc/wezterm/pull/41) が WezTerm の `main` に取り込まれてから、この手順を行う
   - Windows では[WezTerm の設定を更新する](#wezterm-の設定を更新する)、Linux では[同書の WezTerm の設定の更新](almalinux-setup.md#wezterm-の設定を更新する)を行う。接続元の WezTerm をすべて閉じ、起動し直す
   - 貼り付けの前提と停止条件は[WezTerm の SSH 貼り付け](almalinux-setup.md#wezterm-windows-の-ssh-先で-powershell-に貼り付ける)を先に確認する
   - Linux の Wayland は `wl-paste`、X11 は `xclip` が必要。導入は同じ項の手順 2 に従う
   - 接続元の Windows では、標準の Windows PowerShell がクリップボードを読む
   - Windows の接続元はスタートメニューから「WezTerm」、Linux の接続元は GUI セッションのアプリ一覧から「WezTerm」を開く。新しい bash のタブのプロンプトが出ればよい
   - **次の手順は、接続元の WezTerm の bash に貼る**

1. クライアントの bash で、変数を設定する（`WIN_HOST` は必ず値を入れる）。

   ```bash
   WIN_HOST=                             # ← 「OpenSSH サーバー」の手順 7 で控えた @ の後ろ（Windows の IP アドレス）を書く。<WIN_HOST>
   ```

   ```bash
   WIN_USER=${USER}                      # Windows のユーザー名。「OpenSSH サーバー」の手順 7 の @ の前と違えば直す。<WIN_USER>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in WIN_HOST WIN_USER; do
     printf '%-8s = %s\n' "$v" "${!v}"
   done
   ```

   - [SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 4 と同じ値を入れる
   - 最後に値を読み戻して確かめる
   - **新しいクライアントのシェルを開いたら**、この項の手順 2 のブロックを貼り直してから先へ進む

1. 接続元の Bash で、Windows にログインする。

   ```bash
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: この項の手順 2 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh "${WIN_USER}@${WIN_HOST}"
   fi
   ```

   - Windows の Git Bash の `$` のプロンプトが出ればよい。cmd のプロンプトなら、前提の既定シェルの設定を確かめる
   - 5.1 ならこの項の手順 4、7 ならこの項の手順 4 を飛ばしてこの項の手順 5 へ進む
   - **次の手順は、ログインした Windows の Git Bash に貼る**（続けて貼ると、パスワードなどの入力として食われる）

1. 5.1 を使うときは、SSH 先の Git Bash で統合を読み、PowerShell を開く。

   ```bash
   if [ ! -r ~/.config/wezterm/shell/wezterm.sh ] || [ ! -r ~/.config/wezterm/shell/wezterm.ps1 ]; then
     echo '中断: Windows の WezTerm の設定を導入・更新する' >&2
   else
     export TERM_PROGRAM=WezTerm
     . ~/.config/wezterm/shell/wezterm.sh
     powershell.exe -NoLogo -NoExit -Command '. "$env:USERPROFILE\.config\wezterm\shell\wezterm.ps1"'
   fi
   ```

   - `PS C:\Users\…>` のプロンプトが出ればよい。読み込みエラーが出たら、そこで止めて設定の更新と実行ポリシーを確かめる
   - この項の手順 5 は飛ばす
   - **この項の手順 6 は、開いた SSH 先の PowerShell に貼る**（続けて貼ると、起動途中のシェルへの入力として食われる）

1. 7 を使うときは、この項の手順 4 の代わりに Git Bash から PowerShell を開く。

   ```bash
   if [ ! -r ~/.config/wezterm/shell/wezterm.sh ] || [ ! -r ~/.config/wezterm/shell/wezterm.ps1 ]; then
     echo '中断: Windows の WezTerm の設定を導入・更新する' >&2
   else
     export TERM_PROGRAM=WezTerm
     . ~/.config/wezterm/shell/wezterm.sh
     pwsh.exe -NoLogo -NoExit -Command '. "$env:USERPROFILE\.config\wezterm\shell\wezterm.ps1"'
   fi
   ```

   - `PS C:\Users\…>` のプロンプトが出ればよい。`pwsh.exe: command not found` なら、PowerShell 7 の導入と PATH を確かめる
   - **次の手順は、開いた SSH 先の PowerShell に貼る**（続けて貼ると、起動途中のシェルへの入力として食われる）

1. SSH 先の PowerShell で、版・ユーザー・管理者の権限を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"; [pscustomobject]@{ Version = $PSVersionTable.PSVersion.ToString(); User = [Security.Principal.WindowsIdentity]::GetCurrent().Name; Admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) } | Format-List; Get-PSReadLineKeyHandler -Bound | Where-Object Function -eq 'WezTermSshPaste'; & "$env:WINDIR\System32\whoami.exe" /groups
   ```

   - `Version` が 5.1 または 7 の版、`User` がこの Windows のユーザー、`Admin : True` が出ればよい。`User` の値を控える
   - Ctrl+Shift+F12 の `Function` が `WezTermSshPaste` ならよい。配送用なので手動では押さない。出ないなら設定を更新し、この項の手順 3 からやり直す
   - `whoami.exe /groups` の `S-1-16-12288` は High、`S-1-5-32-544` は Administrators で、有効なグループとして出る
   - `Admin : False` なら管理者の操作とこの項の手順 8・9 は行わず、ログインユーザーを確かめる
   - **この項の手順 7 は、右クリックか Ctrl+Shift+V で貼り、入力内容を確かめてから Enter を押す**
   - 貼れる本文は UTF-8 で 64 KiB（65,536 バイト）まで。超えると貼り付けず通知が出るので、ブロックを分ける
   - 大きなブロックの受信は数十秒〜1分以上かかることがある。受信中は次を貼らず、入力欄に入った内容を確かめてから Enter を押す
   - 受信中の Ctrl+C は、終端まで受信して本文を捨てる
   - 配送が止まったら本文を追加で貼らず、接続元の SSH ペインを閉じて接続し直す

1. 管理者の PowerShell で、無害な複数行を右クリックか Ctrl+Shift+V で貼る。

   ```powershell
   "ssh-paste: first"

   "ssh-paste: 日本語"
   ```

   - Enter を押す前は、2 行の式と間の空行 1 行が入力欄にあり、結果はまだ出ない
   - Enter を 1 回押すと、`ssh-paste: first` と `ssh-paste: 日本語` が順に 1 回ずつ出る
   - 空行が増える、途中で実行される、通知が出て貼れない場合は進まない。失敗時は通常貼り付けへ自動で切り替わらない。両側の設定と Linux のクリップボード取得コマンドを確かめる
   - この項の手順 8 は x64 用。ARM64 の Windows では行わない

1. x64 の Windows の管理者 PowerShell で、降格用の固定版を照合して配置する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw '中断: 管理者の親 PowerShell で行う' }
     if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') { throw '中断: この手順は x64 の Windows 用' }
     $exe = Join-Path $env:LOCALAPPDATA 'setup-notes\bin\busybox.exe'
     $expected = '07bb1e5b095b00d68a695481f9240879f33c5724b40aa2308f999d54ed78f075'
     if (Test-Path -LiteralPath $exe) {
       if ((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -ne $expected) { throw '中断: 専用の場所に別のファイルがある。上書きしない' }
     } else {
       $temp = [IO.Path]::GetTempFileName()
       try {
         Invoke-WebRequest -UseBasicParsing -Uri 'https://frippery.org/files/busybox/busybox-w64-FRP-6075-g169694ebd.exe' -OutFile $temp
         if ((Get-FileHash -LiteralPath $temp -Algorithm SHA256).Hash -ne $expected) { throw '中断: ダウンロードしたファイルの SHA-256 が違う' }
         New-Item -ItemType Directory -Path (Split-Path -Parent $exe) -Force | Out-Null
         Move-Item -LiteralPath $temp -Destination $exe
       } finally {
         if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp }
       }
     }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-FileHash -LiteralPath $exe -Algorithm SHA256 | Format-List
     & $exe --help | Select-Object -First 1
   }
   ```

   - `Hash` が `07BB1E5B…78F075`、`Path` が `%LOCALAPPDATA%\setup-notes\bin\busybox.exe`、版の行に `FRP-6075-g169694ebd` が出ればよい
   - SHA-256 が違う、取得できない、別のファイルがある場合は、配置せず止まる
   - 普段の PATH や PowerShell のプロファイルは変えない

1. 管理者の親 PowerShell で、非管理者の子 PowerShell を開く。

   ```powershell
   if ((Get-FileHash -LiteralPath "$env:LOCALAPPDATA\setup-notes\bin\busybox.exe" -Algorithm SHA256).Hash -ne '07bb1e5b095b00d68a695481f9240879f33c5724b40aa2308f999d54ed78f075') { throw '中断: 降格用実行ファイルの SHA-256 が違う' }
   & "$env:LOCALAPPDATA\setup-notes\bin\busybox.exe" drop -- powershell.exe -NoLogo -NoExit -Command '. "$env:USERPROFILE\.config\wezterm\shell\wezterm.ps1"'
   ```

   - 7 を使っているなら、起動コマンドの `powershell.exe` を `pwsh.exe` にして貼る
   - `--` は必ず付ける
   - 新しい PowerShell のプロンプトが出ればよい。`drop` や統合のエラーが出たら、そのまま非管理者の操作を始めない
   - **次の手順は、新しく開いた非管理者の子 PowerShell に貼る**（続けて貼ると、起動途中のシェルへの入力として食われる）

1. 非管理者の子 PowerShell で、ユーザーと実効権限を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"; [pscustomobject]@{ Version = $PSVersionTable.PSVersion.ToString(); User = [Security.Principal.WindowsIdentity]::GetCurrent().Name; Admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) } | Format-List; & "$env:WINDIR\System32\whoami.exe" /groups
   ```

   - `User` がこの項の手順 6 と同じで、`Admin : False` ならよい
   - `S-1-16-8192` は Medium、`S-1-5-32-544` は Administrators で「拒否のみに使用するグループ」（英語では `Group used for deny only`）として出る
   - どれかが違う場合は非管理者の操作を始めず、`exit` で親へ戻る
   - この項の手順 7 のブロックも貼り、Enter の前には実行されず、Enter の後に 1 回だけ出ることを確かめてから、通常の権限で行う操作を貼る

1. 非管理者の操作を終えたら、子 PowerShell を閉じる。

   ```powershell
   exit
   ```

   - 管理者の親 PowerShell のプロンプトに戻る
   - **次の手順は、親 PowerShell のプロンプトに戻ってから貼る**（続けて貼ると、子への入力として食われる）

1. 親 PowerShell で、管理者の権限に戻ったことを確かめて閉じる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"; [pscustomobject]@{ User = [Security.Principal.WindowsIdentity]::GetCurrent().Name; Admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) } | Format-List
   ```

   - `User` がこの項の手順 6 と同じで、`Admin : True` なら管理者の操作を再開できる
   - 今回の操作を終えるなら `exit` を打ち、SSH 先の Git Bash へ戻る
   - **次の手順は、SSH 先の Git Bash に戻ってから貼る**（続けて貼ると、PowerShell の入力として食われる）

1. SSH 先の Git Bash で、SSH の接続を閉じる。

   ```bash
   exit
   ```

   - 接続元のプロンプトに戻ればよい

---

### Windows の OpenSSH クライアント

- Windows と Git の ssh で同じ接続設定と鍵を使い、AlmaLinux 10 のホストにログインする
- 前提: [Git for Windows](#git-for-windows)を通してある。つなぐ先の AlmaLinux 10 のホストでは sshd が動き、そのユーザーのパスワードで SSH に入れる（[AlmaLinux 10 のセットアップ](almalinux-setup.md)の標準の Workstation）。WezTerm の起動メニューを試すときは[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)も通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。この項の手順 8 は AlmaLinux 10 のホストの自分のユーザーの端末（bash）
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-ssh-client.md)・[参考資料](reference/windows-ssh-client.md)・[ロールバックと注意点](extra/windows-ssh-client.md)
- Windows で変えるのは、自分のユーザーの `%USERPROFILE%\.ssh` だけ。ホストでは、この項の手順 9 で自分のユーザーの `~/.ssh/authorized_keys` に足す
- 鍵・config・known_hosts は `%USERPROFILE%\.ssh` に置き、Windows と Git の両方の ssh で使う
- ssh-agent は使わない。鍵にパスフレーズを付けたら、その鍵を使うたびに聞かれる
- 逆向き（AlmaLinux 10 などから Windows 11 に入る）は、[OpenSSH サーバー](#openssh-サーバー)で設定する

1. Windows で、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にしない）

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

   - 最後に値を読み戻して確かめる
   - `SSH_USER` は、AlmaLinux 10 のホストのユーザー名にする。Windows のユーザー名（`C:\Users\` の下のフォルダーの名前）と、大文字・小文字やつづりが違えば直す
   - `SSH_USER` に `root` は使わない
   - **新しい PowerShell を開いたら**、この項の手順 2 の 3 つのブロックを貼り直してから先へ進む

1. 2 つの ssh の版と `PATH` の順、鍵・config・Git の ssh の設定を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & "$env:WINDIR\System32\OpenSSH\ssh.exe" -V
   & 'C:\Program Files\Git\usr\bin\ssh.exe' -V
   Get-Command ssh, ssh-keygen -All -ErrorAction SilentlyContinue | Format-Table Source
   Test-Path "$env:USERPROFILE\.ssh\id_ed25519", "$env:USERPROFILE\.ssh\id_ed25519.pub", "$env:USERPROFILE\.ssh\config"
   git config --show-origin --get-all core.sshCommand
   'GIT_SSH={0} GIT_SSH_COMMAND={1} HOME={2}' -f $env:GIT_SSH, $env:GIT_SSH_COMMAND, $env:HOME
   ```

   - 1 行目に Windows の ssh の版（`OpenSSH_for_Windows_9.5p2, LibreSSL 3.8.2` か、それより新しい版）、2 行目に Git の ssh の版（`OpenSSH_10.5p1` など）が出ればよい
   - 1 行目が「認識されません」のエラーなら、Windows の OpenSSH クライアントが無い。設定の「オプション機能」（`ms-settings:optionalfeatures`）で「OpenSSH クライアント」を追加してから始める（追加には管理者の承認が要る）
   - `core.sshCommand` の行は出ず、最後の行は `GIT_SSH= GIT_SSH_COMMAND= HOME=` であればよい
   - どれかに値があれば、git が別の ssh か別の `.ssh` を使う。その設定を外すまで、この項の手順 7・10 の Git の ssh の確かめは、git の動きと一致しない

1. 鍵ペアが無いときだけ、ed25519 で作る（公開鍵だけが無ければ作り直す）。

   ```powershell
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
   - **次の手順は、パスフレーズを入力し終えてから貼る**（続けて貼るとパスフレーズとして食われる）

1. 秘密鍵のアクセス権を確かめる。

   ```powershell
   icacls.exe "$env:USERPROFILE\.ssh\id_ed25519"
   ```

   - 出てくる主体が `NT AUTHORITY\SYSTEM`・`BUILTIN\Administrators`・自分のユーザー（`<HOSTNAME>\<WIN_USER>`）の 3 つだけならよい（`(I)` の付いた、受け継いだものでもよい）
   - ほかの主体（`Everyone`・`BUILTIN\Users`・`NT AUTHORITY\Authenticated Users` など）があれば、この項の手順 6 で直す。無ければこの項の手順 6 は飛ばす

1. ほかの主体に許可があるときだけ、秘密鍵のアクセス権を直す。

   ```powershell
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
   - `Bad configuration option` が出たら、前からある config に、片方の ssh が知らない設定がある（[注意点](extra/windows-ssh-client.md#注意点)）
   - `Bad owner or permissions on …config` が出たら、config にほかの主体の書き込みの許可がある（[注意点](extra/windows-ssh-client.md#注意点)）
   - `中断: … BOM がある` ときは、メモ帳で config を開き、「名前を付けて保存」の文字コードを「UTF-8」（BOM なし）にして保存し直す

1. AlmaLinux 10 のホストで、ホスト鍵の指紋を表示する。

   ```bash
   ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
   ```

   - ホストの画面の端末か、すでにホストに入れている別の端末に貼る（`sudo` は要らない）
   - `256 SHA256:<指紋> no comment (ED25519)` の 1 行が出る。この指紋を、この項の手順 9 の初回の接続で照合する
   - 同じ LAN から `ssh-keyscan` で取った指紋は、照合に使えない
   - **次の手順は、指紋を控えてから、この項の手順 2 の変数を設定した PowerShell に貼る**

1. 公開鍵をホストの authorized_keys に足す（パスワードで 1 回ログインする）。

   ```powershell
   $pub = "$env:USERPROFILE\.ssh\id_ed25519.pub"
   if (-not $SSH_ALIAS) {
     Write-Error '中断: この項の手順 2 の SSH_ALIAS が空のまま。値を入れて貼り直す'
   } elseif (-not (Test-Path -LiteralPath $pub) -or [string](Get-Content -LiteralPath $pub -TotalCount 1) -notmatch '^ssh-ed25519 AAAA[0-9A-Za-z+/=]+( |$)') {
     Write-Error "中断: $pub が無いか、ed25519 の公開鍵の形でない"
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-Content -LiteralPath $pub -TotalCount 1 | & "$env:WINDIR\System32\OpenSSH\ssh.exe" -o PubkeyAuthentication=no $SSH_ALIAS 'umask 077; mkdir -p ~/.ssh && if [ -s ~/.ssh/authorized_keys ] && [ $(tail -c1 ~/.ssh/authorized_keys | wc -l) -eq 0 ]; then echo >> ~/.ssh/authorized_keys; fi && tr -d ''\r'' | sed ''1s/^\xEF\xBB\xBF//'' >> ~/.ssh/authorized_keys && echo added; if type restorecon >/dev/null 2>&1; then restorecon -F ~/.ssh ~/.ssh/authorized_keys; fi'
   }
   ```

   - 初回は `ED25519 key fingerprint is` の後ろに `SHA256:…` が出て、`Are you sure you want to continue connecting (yes/no/[fingerprint])?` と聞かれる
   - その指紋がこの項の手順 8 の指紋と同じなら `yes`、違えば `no` で止める
   - `<SSH_USER>@<SSH_HOST>'s password:` で、ホストのユーザーのパスワードを入れる
   - `added` と出ればよい
   - パスワードを聞かれずに `Permission denied` で終わるときは、ホストがパスワードでのログインを受け付けていない（[注意点](extra/windows-ssh-client.md#注意点)）
   - **次の手順は、パスワードを入力し終えて `added` が出てから貼る**（続けて貼るとパスワードとして食われる）

1. Windows の ssh と Git の ssh で、鍵でログインできることを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not $SSH_ALIAS) {
     Write-Error '中断: この項の手順 2 の SSH_ALIAS が空のまま。値を入れて貼り直す'
   } else {
     & "$env:WINDIR\System32\OpenSSH\ssh.exe" -o PreferredAuthentications=publickey $SSH_ALIAS 'whoami; ls -lZ ~/.ssh/authorized_keys'
     & 'C:\Program Files\Git\usr\bin\ssh.exe' -o PreferredAuthentications=publickey $SSH_ALIAS whoami
   }
   ```

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
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く
- Windows の ssh は[Windows Update](#windows-update)、Git の ssh は[Git for Windows の更新](#git-for-windowsfirefoxwezterm-を上げる)の手順 3 で上がる。この項で別に上げるものは無い

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. 変数を設定する（`SSH_ALIAS` は必ず値を入れる）。

   ```powershell
   $SSH_ALIAS = ''                       # ← ssh で打つ短い名前（英数字と - _ だけ）。<SSH_ALIAS>
   ```

   ```powershell
   'SSH_ALIAS = {0}' -f $SSH_ALIAS
   ```

   - [Windows の OpenSSH クライアント](#windows-の-openssh-クライアント)の手順 2 と同じ値を入れる
   - 最後に値を読み戻して確かめる
   - **新しい PowerShell を開いたら**、この項の手順 2 のブロックを貼り直してから先へ進む

1. 2 つの ssh の版と、両方が config を読めることを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not $SSH_ALIAS) {
     Write-Error '中断: この項の手順 2 の SSH_ALIAS が空のまま。値を入れて貼り直す'
   } else {
     & "$env:WINDIR\System32\OpenSSH\ssh.exe" -V
     & 'C:\Program Files\Git\usr\bin\ssh.exe' -V
     & "$env:WINDIR\System32\OpenSSH\ssh.exe" -G $SSH_ALIAS | Select-String -Pattern '^(hostname|user) '
     & 'C:\Program Files\Git\usr\bin\ssh.exe' -G $SSH_ALIAS | Select-String -Pattern '^(hostname|user) '
   }
   ```

   - 版が 2 行と、`user <SSH_USER>`・`hostname <SSH_HOST>` が 2 組出ればよい
   - `Bad configuration option` が出たら、片方の ssh が知らない設定が config にある（[注意点](extra/windows-ssh-client.md#注意点)）

---

## Git と開発の道具

- git-delta・GitHub CLI・Neovim（LazyVim）・lazygit・yazi・mdtable

### git-delta

- scoop で delta を入れ、Git の差分表示を設定する
- 前提: [アプリを入れる](#アプリを入れる)の手順 2・3 と[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)を通してある。Visual C++ ランタイムも[WezTerm](#wezterm)で入れてある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。この項の手順 4・5 は WezTerm の新しい Git Bash のタブ

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

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

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`Admin : True` なら、窓を閉じて、この項の手順 1 のとおりに開き直す
   - `Scoop` に `C:\Users\<WIN_USER>\scoop\shims\scoop.ps1` が出ればよい。空なら、先に[アプリを入れる](#アプリを入れる)の手順 2・3 で入れる
   - `Git` が `C:\Program Files\Git\cmd\git.exe` でなければ、先に [Git for Windows](#git-for-windows)
   - `VCRuntime : True` ならよい。`False` なら、先に [WezTerm](#wezterm)の手順 3 を管理者の Windows PowerShell で行い、この窓でこのブロックを貼り直す
   - ほかの場所（winget の `…\WinGet\Links\delta.exe` など）が出たら、ほかの方法で入れた delta がある。外してから始める

1. scoop で delta を入れ、版と場所を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop install delta
   delta --version
   (Get-Command delta -All).Source
   ```

   - `'delta' (0.20.1) was installed successfully!` の形の行が出ればよい
   - 導入済みなら `is already installed.` と更新の案内が出て、何も変えない
   - `delta 0.20.1` の形で、入れた版が出ればよい。版が出なければ、この項の手順 2 の `VCRuntime` を確かめる
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
   - **ほかのブロックは、less を `q` で閉じてから貼る**（続けて貼ると less への入力として食われる）

---

### GitHub CLI

- scoop で GitHub CLI を入れ、GitHub にログインする
- 前提: [アプリを入れる](#アプリを入れる)の手順 2・3 と[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)を通してある。GitHub のアカウントがある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

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

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`Admin : True` なら、窓を閉じて、この項の手順 1 のとおりに開き直す
   - `Scoop` に `C:\Users\<WIN_USER>\scoop\shims\scoop.ps1` が出ればよい。空なら、先に[アプリを入れる](#アプリを入れる)の手順 2・3 で入れる
   - `Git` が `C:\Program Files\Git\cmd\git.exe` でなければ、先に [Git for Windows](#git-for-windows)
   - `GitCred` が `credential.helper manager` ならよい
   - `GitCred` が空なら、この項の手順 4 の Git の認証には `Y` と答えてよい
   - ほかの場所（winget の MSI の `C:\Program Files\GitHub CLI\gh.exe` など）が出たら、ほかの方法で入れた gh がある。外してから始める

1. scoop で gh を入れ、版と場所を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop install gh
   gh --version
   (Get-Command gh -All).Source
   ```

   - `'gh' (2.102.0) was installed successfully!` の形の行が出ればよい
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
   - `Authentication credentials saved in plain text` なら、トークンは `%APPDATA%\GitHub CLI\hosts.yml` に平文で入った（[注意点](extra/windows-setup.md#注意点)）
   - **次の手順は、`gh auth login` が終わってから貼る**（続けて貼ると対話の答えとして食われる）

1. ログインできたことと、Git の資格情報のヘルパーが変わっていないことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   gh auth status
   git config --get-regexp '^credential\..*helper$'
   ```

   - `Logged in to github.com account <GITHUB_USER> (keyring)` の行と、`Git operations protocol: https` の行が出ればよい
   - `(keyring)` の代わりに `(C:\Users\<WIN_USER>\AppData\Roaming\GitHub CLI\hosts.yml)` が出たら、トークンは平文のファイルにある
   - `You are not logged into any GitHub hosts.` なら、ログインしていない。この項の手順 4 からやり直す
   - 最後のコマンドが、この項の手順 2 の `GitCred` と同じ行（ふつうは `credential.helper manager`）を出せばよい
   - `GitCred` が空で、Git の認証に `Y` と答えたときは、代わりに `auth git-credential` で終わる行が出る

---

### Neovim

- scoop で Neovim を入れ、自分用の LazyVim の設定を導入する
- 前提: [アプリを入れる](#アプリを入れる)の手順 2・3・[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)・[HackGen Console NF](#hackgen-console-nf)を通してある。Visual C++ ランタイムも[WezTerm](#wezterm)で入れてある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. 管理者ではないことと、scoop・git・VC++ のランタイム・ほかの Neovim を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     PowerShell = $PSVersionTable.PSVersion.ToString()
     Admin      = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Scoop      = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git        = (Get-Command git -ErrorAction SilentlyContinue).Source
     VCRuntime  = Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
     Nvim       = (Get-Command nvim -All -ErrorAction SilentlyContinue).Source -join ', '
   } | Format-List
   ```

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`True` なら、窓を閉じて、この項の手順 1 のとおりに開き直す
   - `Scoop` に `…\scoop\shims\scoop.ps1` の場所が出ればよい。空なら、先に[アプリを入れる](#アプリを入れる)の手順 2・3 で入れる
   - `Git` は `C:\Program Files\Git\cmd\git.exe` ならよい。空か違う場所なら、先に [Git for Windows](#git-for-windows)
   - `VCRuntime : False` なら、[WezTerm](#wezterm)の手順 3 を管理者の Windows PowerShell で行ってから、この手順を貼り直す
   - `C:\Program Files\Neovim\bin\nvim.exe` など、ほかの場所が出たら、winget などで入れた Neovim がある。外してから始める

1. scoop で Neovim を入れる。

   ```powershell
   scoop install neovim
   ```

   - `'neovim' (0.12.5) was installed successfully!` の形の行が出ればよい
   - `'neovim' suggests installing 'extras/vcredist2022'.` も出るが、この項の手順 2 が `VCRuntime : True` なら入れなくてよい
   - `'neovim' (0.12.5) is already installed.` の形なら、もう入っている（何も変えない）
   - まだ `nvim` は起動しない（この項の手順 4 の退避より前に起動すると、`nvim-data` などができて、それも退避される）

1. 自分用の LazyVim の設定を導入する。

   - [LazyVim の設定を導入する](#lazyvim-の設定を導入する)を通す。scoop・Git for Windows・Neovim 本体とフォントは、この項の前提と本体導入で用意済み
   - 参照先の既存設定の確認と退避を省かない
   - Neovim の画面を開く手順では、指定された `:qa` または `:qa!` で閉じてから先へ進む

1. 版と場所と、設定・データの置き場所を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   nvim --version | Select-Object -First 3
   (Get-Command nvim -All).Source
   nvim --clean --headless "+lua io.stdout:write(vim.fn.stdpath('config'), '\n', vim.fn.stdpath('data'), '\n')" +qa
   ```

   - `NVIM v0.12.5`・`Build type: Release`・`LuaJIT 2.1.…` の 3 行が出ればよい
   - 無出力で終わるか `VCRUNTIME140.dll` のエラーなら、VC++ ランタイムをこの項の手順 2 で確かめる
     - 窓が出たら、OK で閉じる
   - 2 つ目は `C:\Users\<WIN_USER>\scoop\shims\nvim.exe` の 1 行だけならよい
   - 最後に、設定の置き場所（`C:\Users\<WIN_USER>\AppData\Local\nvim`）とデータの置き場所（`…\AppData\Local\nvim-data`）の 2 行が出る（[AlmaLinux 10 の初期設定の「Neovim の設定ファイル」](almalinux-setup.md#neovim-の設定ファイル)）

#### Neovim を既定のエディタにする

- Windows PowerShell や Windows Terminal から起動するツールにも Neovim を使わせる
- 前提: [Neovim](#neovim)を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く
- Git Bash では、[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)で入れた共通の bash 設定が `EDITOR`・`VISUAL` を `nvim` にするので、この項は要らない
- Git Bash の値は WezTerm の新しいタブで、[AlmaLinux 10 の「Neovim」](almalinux-setup.md#neovim)の手順 4 のブロックを貼って確かめる（`. ~/.bashrc` は読み直さない）

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. Windows の PowerShell でも使うように、`EDITOR`・`VISUAL` を `nvim` にする。

   ```powershell
   & {
     $other = @(foreach ($n in 'EDITOR', 'VISUAL') { [Environment]::GetEnvironmentVariable($n, 'User') }) | Where-Object { $_ -and $_ -ne 'nvim' }
     if ($other) { Write-Error "中断: ユーザーの環境変数 EDITOR か VISUAL に、nvim ではない値がある（$($other -join ', ')）" } else {
       foreach ($n in 'EDITOR', 'VISUAL') { [Environment]::SetEnvironmentVariable($n, 'nvim', 'User') }
       "`n$([char]27)[7m 確認 $([char]27)[0m"
       foreach ($n in 'EDITOR', 'VISUAL') { '{0} = {1}' -f $n, [Environment]::GetEnvironmentVariable($n, 'User') }
     }
   }
   ```

   - `EDITOR = nvim` と `VISUAL = nvim` が出ればよい（何度貼ってもよい）
   - `中断:` と出たら、何も変えていない。ほかのエディタを使っているなら、この手順は行わない
   - 効くのは、この後に開いた窓とアプリから（開いている窓には入らない。WezTerm は新しいタブから）

1. 元に戻すときは、ユーザーの環境変数 `EDITOR`・`VISUAL` を消す。

   ```powershell
   foreach ($n in 'EDITOR', 'VISUAL') { if ([Environment]::GetEnvironmentVariable($n, 'User') -eq 'nvim') { [Environment]::SetEnvironmentVariable($n, $null, 'User') } }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   foreach ($n in 'EDITOR', 'VISUAL') { '{0} = {1}' -f $n, [Environment]::GetEnvironmentVariable($n, 'User') }
   ```

   - `EDITOR = ` と `VISUAL = `（どちらも値が空）が出ればよい
   - 値が `nvim` のときだけ消す（ほかの値は残る）

#### LazyVim の設定を導入する

- Windows の Neovim に自分用の LazyVim の設定と外部コマンド・プラグインを入れる
- 前提: [Git for Windows](#git-for-windows)・[アプリを入れる](#アプリを入れる)の手順 2・3・[HackGen Console NF](#hackgen-console-nf)と、[Neovim](#neovim)で本体を先に入れてある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く
- この項の手順 3 の退避前に Neovim をすべて閉じる。既存設定とデータの確認・退避を省かない
- Visual C++ ランタイムの導入時だけインストーラーの UAC を許可する
- [背景説明](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/reference/setup.md)・[検証記録](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/verification/setup.md)

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. git が無ければ入れ、scoop に `extras` のバケットを足す。

   ```powershell
   if (-not (Get-Command git -ErrorAction SilentlyContinue)) { scoop install git }
   scoop bucket add extras
   ```

   - Git for Windows などで git がすでにあれば、`scoop install git` は飛ばされる
   - バケットの追加に git が要る。lazygit は `extras` にある

1. 既存の Neovim の設定とデータがあれば、`.bak` を付けて退避する。

   ```powershell
   & {
     $nvimPaths = @("$env:LOCALAPPDATA\nvim", "$env:LOCALAPPDATA\nvim-data")
     foreach ($d in $nvimPaths) {
       if (Test-Path -LiteralPath "${d}.bak") { throw "中断: ${d}.bak がすでにある。何も退避していない" }
     }
     foreach ($d in $nvimPaths) {
       if (Test-Path -LiteralPath $d) {
         Move-Item -LiteralPath $d -Destination "${d}.bak" -ErrorAction Stop
         "moved: $d"
       }
     }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $nvimPaths | ForEach-Object { '{0}: {1}' -f $_, (Test-Path -LiteralPath $_) }
   }
   ```

   - 退避したものは `moved: …` と出る。最後の 2 行がどちらも `False` なら、元の設定とデータは残っていない
   - `.bak` が 1 つでもあれば、どちらも動かさず `中断:` で止まる。中身を確かめて片付けてから、この項の手順 3 を貼り直す
   - `nvim` は設定、`nvim-data` はプラグイン・Mason のツール・undo など

1. この設定を `%LOCALAPPDATA%\nvim` に clone する。

   ```powershell
   if (-not (Test-Path "$env:LOCALAPPDATA\nvim\init.lua")) { git clone https://github.com/ryo-aoki-pc/LazyVimStarter.git "$env:LOCALAPPDATA\nvim" }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   git -C "$env:LOCALAPPDATA\nvim" branch --show-current
   ```

   - `custom` と出ればよい
   - すでに clone してあれば、`git clone` は飛ばされる

1. Visual C++ のランタイムが無いときだけ入れ、外部コマンド・zenhan・lazygit を scoop で入れる。

   ```powershell
   if (-not (Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll")) { scoop install vcredist2022 }
   scoop install ripgrep fd gcc nodejs zenhan lazygit
   ```

   - 1 行目は、ランタイム (`System32\vcruntime140.dll`) がすでにあれば何もしない (ほかのアプリや winget で入れてある PC では、UAC も出ない)
   - ランタイムが無ければ `vcredist2022` を入れる。PowerShell は非管理者のまま、Visual C++ のインストーラーの UAC を許可する (x64・x86 の両方を入れる。標準ユーザーなら管理者の認証情報が要る)
   - `zenhan` は IME 連携に使う。無ければ IME 連携だけが静かに無効になる
   - `lazygit` は任意 (無ければ `<leader>gg` が定義されないだけ)
   - 2 行目のパッケージは、導入済みなら何も出さずに飛ばされる (scoop は複数を並べると `already installed` を出さない)

1. 入ったか確かめ、フォントを入れる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   nvim --version | Select-Object -First 1
   Get-Command rg, fd, gcc, node, npm, zenhan, lazygit | Format-Table Name, Source
   ```

   - `NVIM v0.12.…` と出ればよい (0.12 以上が要る)
   - 7 つのコマンドの場所が並ぶ
   - 端末のフォントは[HackGen Console NF](#hackgen-console-nf)にする

1. プラグインを入れ、`lazy-lock.json` の版に揃える。

   ```powershell
   nvim --headless +qa
   git -C "$env:LOCALAPPDATA\nvim" checkout -- lazy-lock.json
   nvim --headless "+Lazy! restore" +qa
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   git -C "$env:LOCALAPPDATA\nvim" status --short
   ```

   - 数分かかる。Mason と treesitter の中断のメッセージは出てよい
   - 最後の `git status --short` が何も出さなければ、`lazy-lock.json` の版に揃っている
   - 理由は [lock 復元の説明](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/reference/setup.md#lazy-lockjson-を戻してから-restore-する理由)を参照する
   - **次の手順は、プロンプトが戻ってから貼る**

1. 試験用の Markdown を開いて、treesitter と Mason の導入を待つ。

   ```powershell
   Set-Content -Path "$env:TEMP\lazyvim-check.md" -Value '#動作確認', '', '日本語の検索を試す。' -Encoding UTF8
   nvim "$env:TEMP\lazyvim-check.md"
   ```

   - `:Mason` を開き、Installed が 11 個になり、導入中のものが無くなるまで待つ (`q` で閉じる)
   - 待ったら `:qa` で閉じる
   - **次の手順は、`:qa` で閉じてから貼る** (続けて貼ると Neovim への入力として食われる)

1. 外部コマンドと Mason のツールが揃ったかを、`checkhealth` で確かめる。

   ```powershell
   nvim --headless "+Lazy! load mason.nvim luamigemo" "+checkhealth lazyvim luamigemo" "+w! $env:TEMP\lazyvim-health.txt" +qa
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Select-String -Path "$env:TEMP\lazyvim-health.txt" -Pattern 'ERROR|WARNING'
   ```

   - `` WARNING `fzf` is not installed `` の 1 行だけならよい (無視してよい)
   - `ERROR` が出たら[注意点](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/extra/setup.md#注意点)

1. 試験用の Markdown を開き、日本語検索・整形・IME 連携を確かめる。

   ```powershell
   nvim "$env:TEMP\lazyvim-check.md"
   ```

   - `/kensaku` で「検索」に移り、検索欄の `<Tab>` で「検索」に置き換わることを確かめる。`:w` で見出しが `# 動作確認` に直り、`<C-j>` で `A` / `あ` が切り替わり、ファイルピッカーのアイコンが表示されればよい
   - 初めてなら [安全な整形の導入](#lazyvim-の安全な-markdown-整形を導入する) を済ませる
   - `:lua =vim.fn.executable("zenhan")` が `1` なら IME 連携が有効 (`0` でもほかは動く)
   - OS 側で IME を切り替えると、lualine の `あ` / `A` がずれることがある（[README](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/README.md#日本語入力検索)）
   - `:qa!` で閉じる。これで導入は終わり

#### LazyVim の設定とプラグインの版を揃える

- 設定と lazy-lock.json を取り込み、プラグインをその版に揃える
- 前提: [LazyVim の設定を導入する](#lazyvim-の設定を導入する)を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く
- 手元の変更は `git -C "$env:LOCALAPPDATA\nvim" status` で確認してから進む
- 初回と整形用 lock の変更後は[LazyVim の安全な Markdown 整形を導入する](#lazyvim-の安全な-markdown-整形を導入する)を通す
- 外したプラグインは `:Lazy clean`、外した Mason ツールは `:MasonUninstall <名前>` で消す

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. Windows 11 では、設定を最新にしてプラグインを揃える。

   ```powershell
   git -C "$env:LOCALAPPDATA\nvim" pull --ff-only; if ($?) { nvim --headless "+Lazy! restore" +qa }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   git -C "$env:LOCALAPPDATA\nvim" status --short
   ```

   - `git status --short` が何も出さなければ、`lazy-lock.json` の版に揃っている
   - `M lazy-lock.json` なら、導入時に lock が古い版で書き直されている。`git -C "$env:LOCALAPPDATA\nvim" checkout -- lazy-lock.json` で戻す
   - 続いて `nvim --headless "+Lazy! restore" +qa` をもう一度貼る。2 回目は導入も lock の書き直しも無い
   - `Not possible to fast-forward` なら、`restore` も状態表示も走らない。push していないコミットを先に push するか、`git -C "$env:LOCALAPPDATA\nvim" log --oneline '@{u}..'` で見る
   - `Your local changes to the following files would be overwritten by merge:` が `lazy-lock.json` を挙げたら、手元で lock が変わっている
   - `:Lazy update` の結果として残すのでなければ、`git -C "$env:LOCALAPPDATA\nvim" checkout -- lazy-lock.json` で戻してから、この手順を貼り直す

#### LazyVim の安全な Markdown 整形を導入する

- Neovim に安全な Markdown 整形の依存を入れ、保存と手動整形を確かめる
- 前提: [LazyVim の設定を導入する](#lazyvim-の設定を導入する)を通し、Node.js 22 以上と npm が使える
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。この項の手順 2 からは、その窓で起動する Neovim
- 初回と `tools/glfm-format/package-lock.json` の変更後に行う
- 整形用依存は Neovim のデータディレクトリの `glfm-format` に入る

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. 試験用の Markdown を Neovim で開く。

   ```powershell
   nvim "$env:TEMP\lazyvim-format-check.md"
   ```

   - Neovim の編集画面が開けばよい
   - **次の手順は、Esc を押し、Neovim の `:` のコマンドラインに入力する**（PowerShell には貼らない）

1. Neovim で整形用の依存を導入する。

   ```vim
   :GlfmFormatInstall
   ```

   - 完了の通知が出るまで待つ
   - 取得するのは lock ファイルで固定した markdownlint-cli2 と Comrak (WASM 版)。整形時は通信しない
   - 失敗したら Node.js と npm が PATH にあるか確かめ、同じコマンドを入力し直す
   - lint の診断用は `:MasonInstall markdownlint-cli2` で導入する
   - **次の手順は、完了の通知が出てから `i` を押し、挿入モードの本文に貼る**

1. Neovim の試験用 Markdown に本文を貼り、保存と手動整形を確かめる。

   ```markdown
   #動作確認

   用語
   : 説明

     - 内部の項目
   ```

   - 貼り終えたら Esc を押し、ノーマルモードに戻る
   - `:w` または `<leader>cf` で `#動作確認` が `# 動作確認` に直る
   - `内部の項目` の行頭の 2 スペースが保たれる
   - `<leader>cf` はビジュアル選択した範囲にも使える
   - 説明の対応や本文を変える修正は除外するため、一部の lint 診断は残ることがある
   - `:ConformInfo` に `glfm_markdownlint` が出る。依存不足・設定不正・時間切れのときは原文を保持し、エラーを知らせる
   - 確かめ終えたら `:qa!` で閉じる。試験用の `%TEMP%\lazyvim-format-check.md` は、要らなければ手で消す
   - **ほかのブロックは、Neovim を閉じてから貼る**（続けて貼ると Neovim への入力として食われる）

#### LazyVim の GitLab プレビューを設定する

- GitLab プレビュー用のトークンと、送り先の GitLab を自分のユーザーの環境変数に設定する
- 前提: [LazyVim の設定を導入する](#lazyvim-の設定を導入する)を通してある。GitLab でスコープ `read_api` の個人アクセストークンを用意してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。この項の手順 4 で通常の窓を開き直し、手順 5 で Neovim を起動する
- 編集中の内容とトークンは設定した GitLab（空なら gitlab.com）に送る
- 設定しなくても近似プレビューは使える
- 削除は[LazyVim のロールバック](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/extra/setup.md#gitlab-プレビューの設定を消す)で行う

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. Windows 11 では、トークンを入力して、ユーザーの環境変数にする。

   ```powershell
   [Environment]::SetEnvironmentVariable('GITLAB_TOKEN', [pscredential]::new('gitlab', (Read-Host -AsSecureString 'GitLab のトークン')).GetNetworkCredential().Password, 'User')
   ```

   - `GitLab のトークン: ` と出るので、トークンを貼って Enter を押す (画面には `*` で出る)
   - Enter の後、プロンプトが戻るまで 2 秒ほどかかる
   - 前に設定した値があれば、置き換わる
   - **次の手順は、トークンを入力し、プロンプトが戻ってから貼る**

1. Windows 11 で、gitlab.com 以外の GitLab を使うときは、その URL を入力して、ユーザーの環境変数にする。

   ```powershell
   $h = Read-Host 'GitLab の URL (gitlab.com なら空のまま Enter)'; if ($h) { [Environment]::SetEnvironmentVariable('GITLAB_HOST', $h, 'User') } else { [Environment]::SetEnvironmentVariable('GITLAB_HOST', $null, 'User') }
   ```

   - `https://gitlab.example.com` のように入力する (ホスト名だけでもよい)
   - 空のまま Enter を押すと、`GITLAB_HOST` を消す。送り先は gitlab.com になる
   - Enter の後、プロンプトが戻るまで 2 秒ほどかかる
   - **次の手順は、URL を入力し、プロンプトが戻ってから貼る**

1. 管理者ではない Windows PowerShell（5.1）を開き直す。

   - この項の手順 1 の窓を閉じ、スタートメニューで「Windows PowerShell」をクリックして開く（管理者として実行しない）
   - **次の手順は、開き直した PowerShell に貼る**

1. Windows 11 では、新しい端末でこの設定の README を開き、プレビューで確かめる。

   ```powershell
   nvim "$env:LOCALAPPDATA\nvim\README.md"
   ```

   - `<leader>cp` の右上に `GitLab: <ホスト名>` が出ればよい。近似表示ならバナーの理由を確認する。もう一度 `<leader>cp` で止め、`:qa` で閉じる
   - Neovide で使うなら、Neovide も起動し直す

#### LazyVim の本体・外部コマンド・プラグインを更新する

- scoop で入れた本体と外部コマンド・LazyVim のプラグインを更新する
- 前提: [LazyVim の設定を導入する](#lazyvim-の設定を導入する)を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く
- 手元の変更は `git -C "$env:LOCALAPPDATA\nvim" status` で確認してから進む
- 設定の取り込みは[LazyVim の設定とプラグインの版を揃える](#lazyvim-の設定とプラグインの版を揃える)で行う
- 更新後は動作を確認し、`lazy-lock.json` の差分をコミット・push する

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. Windows 11 では、scoop で入れたものを上げる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop update
   scoop update neovim ripgrep fd gcc nodejs zenhan lazygit
   nvim --version | Select-Object -First 1
   ```

   - 最新なら `latest version` と出る

1. Windows 11 では、プラグインを上げて差分を見る。

   ```powershell
   nvim --headless "+Lazy! update" +qa
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   git -C "$env:LOCALAPPDATA\nvim" diff --stat
   ```

   - `lazy-lock.json` だけが変わっていればよい

---

### lazygit

- scoop で lazygit を入れ、自分用の設定と起動を確かめる
- 前提: [アプリを入れる](#アプリを入れる)の手順 2・3・[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)・[git-delta](#git-delta)・[HackGen Console NF](#hackgen-console-nf)を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

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

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`True` なら、窓を閉じて、この項の手順 1 のとおりに開き直す
   - `Scoop` に `…\scoop\shims\scoop.ps1` の場所が出ればよい。空なら、先に[アプリを入れる](#アプリを入れる)の手順 2・3 で入れる
   - `Git` は `C:\Program Files\Git\cmd\git.exe` ならよい。空か違う場所なら、先に [Git for Windows](#git-for-windows)
   - ほかの場所（winget の `JesseDuffield.lazygit` など）が出たら、外してから始める
   - `Extras : True` なら、extras のバケットはもうある（[Neovim](#neovim)の手順 4 で足した）。この項の手順 3 は飛ばす

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

   - `'lazygit' (0.66.0) was installed successfully!` の形の行が出ればよい
   - `is already installed.` なら導入済みで、何も変えない

1. 自分用の設定（[ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit)）を入れる。

   - [lazygit の設定を導入する](#lazygit-の設定を導入する)の全項を通す
   - `custom` と `C:\Users\<WIN_USER>\AppData\Local\lazygit` が出れば、入っている
   - lazygit を起動する（この項の手順 7）前に入れる。先に起動すると、できた状態ファイルごと `lazygit.bak` に退避される

1. 版と、設定の置き場所を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   lazygit --version
   lazygit --print-config-dir
   (Get-Command lazygit -All).Source
   ```

   - 1 行目に `version=0.66.0, os=windows, arch=amd64` を含む行が出ればよい
   - 2 行目は `C:\Users\<WIN_USER>\AppData\Local\lazygit`（[AlmaLinux 10 の初期設定の「lazygit の設定ファイル」](almalinux-setup.md#lazygit-の設定ファイル)）
   - 最後は `C:\Users\<WIN_USER>\scoop\shims\lazygit.exe` の 1 行だけならよい

1. 確かめ用の git のリポジトリで、lazygit を起動して確かめる。

   ```powershell
   git init --quiet "$env:TEMP\lazygit-check"
   if (-not (Test-Path -LiteralPath "$env:TEMP\lazygit-check\.git")) { Write-Error '中断: 確かめ用のリポジトリ（%TEMP%\lazygit-check）を作れない' } else {
     Set-Location -LiteralPath "$env:TEMP\lazygit-check"
     lazygit
   }
   ```

   - `中断:` と出たら、lazygit は起動していない（git が呼べるかを、この項の手順 2 で確かめ直す）
   - 初回に `Thanks for using lazygit...` の案内が出たら Enter で閉じる
   - Status・Files・Branches・Commits などの欄が出ればよい（空のリポジトリなので、一覧は空）
   - ほかのリポジトリで確かめるなら、そのフォルダーに `Set-Location` してから `lazygit` を打つ（git 管理外のフォルダーで起動すると、リポジトリを作るか聞かれる）
   - **注意**: Windows PowerShell から起動した lazygit の `e` キーは、git の `core.editor` と環境変数 `VISUAL`・`EDITOR` などが無いと `vim` で開こうとして失敗する
     - [Neovim を既定のエディタにする](#neovim-を既定のエディタにする)で `nvim` にし、新しい窓で lazygit を起動し直す
     - Git Bash から起動したときは、共通の bash 設定が `nvim` にしてある
   - `q` で閉じる
   - `%TEMP%\lazygit-check` は、要らなければ手で消す
     - 消す前に `Set-Location ~` で出る
   - **ほかのブロックは、`q` で閉じてから貼る**（続けて貼ると lazygit への操作として食われる）

#### lazygit の設定を導入する

- Windows の lazygit の既存設定を退避し、自分用の設定を入れる
- 前提: [lazygit](#lazygit)の手順 1〜4 までを通し、本体を入れてある。[git-delta](#git-delta)・[HackGen Console NF](#hackgen-console-nf)も通し、Visual C++ ランタイムも[WezTerm](#wezterm)で入れてある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く
- lazygit をすべて閉じてから始める。既存設定の確認と、この項の手順 2 の退避を省かない

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. 既存設定を退避して、設定ディレクトリへ clone する。

   ```powershell
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
   - 状態ファイルも同じ場所に置くが Git の追跡対象からは除外する
   - 戻すときは [lazygit のロールバック](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/extra/readme.md)を行う

#### lazygit の Excel 差分表示を導入する

- lazygit の設定リポジトリから、Excel 差分表示と部分ステージ用のコマンドを入れる
- 前提: [lazygit の設定を導入する](#lazygit-の設定を導入する)を通してある。部分ステージには lazygit 0.66.0 以上・delta 0.20.1 以上が要る
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く
- Python 3.9 以上が要る。この項の手順 2 で、無ければ scoop で入れる
- 既存の変更は `git -C "$env:LOCALAPPDATA\lazygit" status` で確認してから進む

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. Python が無ければ scoop で入れ、版を確かめる。

   ```powershell
   if (-not (Get-Command python -ErrorAction SilentlyContinue)) { scoop install python }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   python --version
   ```

   - `Python 3.9` 以上の版が出ればよい
   - 3.9 より古い版やエラーが出たら、その Python を更新してから貼り直す

1. 設定リポジトリへ移り、Excel の差分表示を導入して確かめる。

   ```powershell
   & {
     Push-Location -LiteralPath "$env:LOCALAPPDATA\lazygit" -ErrorAction Stop
     try {
       python --version
       python scripts/setup-excel-diff.py
       "`n$([char]27)[7m 確認 $([char]27)[0m"
       python scripts/setup-excel-diff.py --check
     } finally {
       Pop-Location
     }
   }
   ```

   - Git 全体の textconv・alias・属性を設定し、依存はリポジトリ外の仮想環境へ入れる
   - 同期したリポジトリでも端末ごとに一度実施し、スクリプトを更新したら再実行する
   - `--check` は読み取りだけの確認
   - 終わると元の作業ディレクトリへ戻る

#### lazygit で Excel の差分を確かめる

- 対象の Git リポジトリの Excel の属性と差分を確かめる
- 前提: [lazygit の Excel 差分表示を導入する](#lazygit-の-excel-差分表示を導入する)を通してある。対象の Excel が Git のリポジトリにある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く
- 例の `売上表.xlsx` は実際のファイル名に置き換える
- 属性の仕様は[Excel 差分の説明](https://github.com/ryo-aoki-pc/lazygit/blob/custom/README.md#excel-の差分表示)を参照する

> [!CAUTION]
> - **通常の Excel 差分は閲覧用。`Enter` から行・ハンクをステージ・破棄しない**。既存の Excel にテキストのパッチは適用できず、新規ファイルでは Excel の代わりに変換後のテキストをステージする場合がある
> - `diff.excel.binary=true` はバイナリ扱いを保つだけで、これらの操作を禁止しない
> - 全体をステージするならファイル一覧で `Space`、部分ステージは[lazygit で Excel のセル変更を部分ステージする](#lazygit-で-excel-のセル変更を部分ステージする)の `E` を使う

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. 作業場所の変数を設定する（`EXCEL_REPO` は必ず値を入れる）。

   ```powershell
   $EXCEL_REPO = ''                     # ← 対象の Excel がある Git のリポジトリの絶対パス。<EXCEL_REPO>
   ```

   ```powershell
   'EXCEL_REPO = {0}' -f $EXCEL_REPO
   ```

   - 最後に値を読み戻して確かめる
   - **新しい PowerShell を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. 対象のリポジトリへ移る。

   ```powershell
   & {
     if (-not $EXCEL_REPO) { Write-Error '中断: この項の手順 2 の EXCEL_REPO が空のまま'; return }
     Set-Location -LiteralPath $EXCEL_REPO -ErrorAction Stop
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     git rev-parse --show-toplevel
   }
   ```

   - 対象のリポジトリの場所が出ればよい。エラーが出たら先へ進まず、この項の手順 2 の場所を確かめる

1. Excel の属性と、作業中・ステージ済みの差分を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   git check-attr diff -- "売上表.xlsx"
   git diff -- "売上表.xlsx"
   git diff --cached -- "売上表.xlsx"
   ```

   - `売上表.xlsx: diff: excel` と、差分に `Sheet:`・セル番地が出ればよい
   - lazygit を開き直してファイルを選ぶと、同じ差分を delta で表示する。`|` で内蔵表示にしても同じテキスト差分になる
   - `unset` や別のドライバーなら、そのリポジトリの `.gitattributes`・`.git/info/attributes` の Excel 用の属性を確かめる
   - そのリポジトリだけに適用するなら、`.git/info/attributes` に `*.[xX][lL][sS][xX] diff=excel` を足す

#### lazygit で Excel のセル変更を部分ステージする

- 対象の Git リポジトリで、Excel の値・通常の数式の変更を専用画面から部分ステージする
- 前提: [lazygit の Excel 差分表示を導入する](#lazygit-の-excel-差分表示を導入する)を通してある。対象は HEAD と index の両方にある既存 `.xlsx` / `.xlsm` / `.xltx` / `.xltm`。新規ファイルは全体をコミットしてある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。その窓から起動する lazygit の画面も使う
- 例の `売上表.xlsx` は実際のファイル名に置き換える

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. 作業場所の変数を設定する（`EXCEL_REPO` は必ず値を入れる）。

   ```powershell
   $EXCEL_REPO = ''                     # ← 対象の Excel がある Git のリポジトリの絶対パス。<EXCEL_REPO>
   ```

   ```powershell
   'EXCEL_REPO = {0}' -f $EXCEL_REPO
   ```

   - 最後に値を読み戻して確かめる
   - **新しい PowerShell を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. 対象のリポジトリへ移り、lazygit を起動する。

   ```powershell
   & {
     if (-not $EXCEL_REPO) { Write-Error '中断: この項の手順 2 の EXCEL_REPO が空のまま'; return }
     Set-Location -LiteralPath $EXCEL_REPO -ErrorAction Stop
     lazygit
   }
   ```

   - lazygit のファイル一覧が開けばよい
   - **次の手順は、lazygit の画面で行う**

1. lazygit のファイル一覧で対象を選び、`E` を押す。

   - 端末から開くなら `git excel-stage -- "売上表.xlsx"`。実際のファイル名に置き換える
   - 専用画面が開くまで待つ。大きいブックでは「Excel を読み込んでいます」と出る

1. 専用画面で `Enter` → `Space` を押してハンクを選ぶ。

   - 左右の矢印で移動し、ステージ済み差分を確認する
   - 値・通常の数式の変更だけを選べる。置換は削除・追加の両方を選ぶ
   - 書式・画像・マクロ・行列の挿入や移動を反映する場合は、元のファイル一覧で全体をステージする
   - 対応できない変更は index を変更せず中断する。[対応条件と制限](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/extra/excel-diff.md)を確認する

1. 選択を確認して専用画面の `X` で適用し、`q` で戻る。

   - `X` の前に `q` で閉じれば選択を取り消す
   - 作業中の Excel は変えず、index 側の書式・画像・マクロを保持する
   - 開いた後に対象の index・作業ファイルが変わった場合は中断する。閉じて `E` から開き直す
   - 選んだ文字列セルのふりがなは引き継がない。未選択のセルは保持する
   - 次に Excel で開いたときに再計算する。スクリプトはマクロ・外部リンク更新・数式再計算を実行しない
   - 専用画面から戻ったら、lazygit でも `q` を押して閉じる
   - **ほかのブロックは、lazygit を閉じて PowerShell に戻ってから貼る**（続けて貼ると lazygit への操作として食われる）

#### lazygit で大きな Excel の変換を待つ

- 大きい Excel の全セルの変換を待ち、差分を表示する
- 前提: [lazygit の Excel 差分表示を導入する](#lazygit-の-excel-差分表示を導入する)を通してある。対象の Excel が Git のリポジトリにある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く
- 例の `売上表.xlsx` は実際のファイル名に置き換える
- lazygit で変換中のブックは、完了後にファイルを選び直すか `R` で表示する

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. 作業場所の変数を設定する（`EXCEL_REPO` は必ず値を入れる）。

   ```powershell
   $EXCEL_REPO = ''                     # ← 対象の Excel がある Git のリポジトリの絶対パス。<EXCEL_REPO>
   ```

   ```powershell
   'EXCEL_REPO = {0}' -f $EXCEL_REPO
   ```

   - 最後に値を読み戻して確かめる
   - **新しい PowerShell を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. 対象のリポジトリへ移る。

   ```powershell
   & {
     if (-not $EXCEL_REPO) { Write-Error '中断: この項の手順 2 の EXCEL_REPO が空のまま'; return }
     Set-Location -LiteralPath $EXCEL_REPO -ErrorAction Stop
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     git rev-parse --show-toplevel
   }
   ```

   - 対象のリポジトリの場所が出ればよい。エラーが出たら先へ進まず、この項の手順 2 の場所を確かめる

1. 全セルの変換を待って差分を表示する。

   ```powershell
   $env:EXCEL_TEXTCONV_TIMEOUT = "0"; git diff -- "売上表.xlsx"
   ```

   - 環境変数は同じ窓に残る。戻すときは `Remove-Item Env:EXCEL_TEXTCONV_TIMEOUT` を実行する

---

### yazi

- scoop で yazi と依存ツールを入れ、自分用の設定とプレビュー・移動を確かめる
- 前提: [アプリを入れる](#アプリを入れる)の手順 2・3 と[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)を通してある。Visual C++ ランタイムも[WezTerm](#wezterm)で入れてある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。この項の手順 8・9 は WezTerm の新しい Git Bash のタブ

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

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

   - `PowerShell : 5.1.…`・`Admin : False`・`FileExe : True` が出ればよい。`Admin : True` なら、窓を閉じて、この項の手順 1 のとおりに開き直す（この項の手順 2 も貼り直す）
   - `Scoop` に `…\scoop\shims\scoop.ps1` の場所が出ればよい。空なら、先に[アプリを入れる](#アプリを入れる)の手順 2・3 で入れる
   - `Git` が `C:\Program Files\Git\cmd\git.exe` でないか、`FileExe : False` なら、先に [Git for Windows](#git-for-windows)
   - `VCRuntime : False` なら、[WezTerm](#wezterm)の手順 3 を管理者の Windows PowerShell で行ってから、この手順を貼り直す
   - `Yazi` は空か `C:\Users\<WIN_USER>\scoop\shims\yazi.exe` ならよい。ほかの場所なら、外してから始める
   - `YaziFileOne` の元の値を控える。この項の手順 5 で Git for Windows の `file.exe` に上書きし、ロールバックで戻す

1. scoop で yazi と、プレビュー・検索に使うツールを入れる。

   ```powershell
   if ($null -eq $YAZI_EXTRAS) { Write-Error '中断: この項の手順 2 の $YAZI_EXTRAS が無い。この項の手順 2 を貼り直す' } else { scoop install yazi @YAZI_EXTRAS }
   ```

   - アプリごとに `'yazi' (26.9.1) was installed successfully!` の形の行が出ればよい。入っていたものは `is already installed.` の形の行を出して飛ばす
   - `'ripgrep' suggests installing 'extras/vcredist2022'.` などの `suggests installing` の行は、入れなくてよい
   - `中断:` と出たら、何も入れていない（新しい窓では、この項の手順 2 を貼り直す。yazi 本体だけにするなら `$YAZI_EXTRAS = @()`）
   - scoop の `file` は入れない

1. ユーザーの環境変数 `YAZI_FILE_ONE` を Git for Windows の `file.exe` にする。

   ```powershell
   if (-not (Test-Path -LiteralPath 'C:\Program Files\Git\usr\bin\file.exe')) { Write-Error '中断: C:\Program Files\Git\usr\bin\file.exe が無い（「Git for Windows」で入れる）' } else {
     [Environment]::SetEnvironmentVariable('YAZI_FILE_ONE', 'C:\Program Files\Git\usr\bin\file.exe', 'User')
     $env:YAZI_FILE_ONE = [Environment]::GetEnvironmentVariable('YAZI_FILE_ONE', 'User')
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'YAZI_FILE_ONE = {0}' -f $env:YAZI_FILE_ONE
   }
   ```

   - `YAZI_FILE_ONE = C:\Program Files\Git\usr\bin\file.exe` が出ればよい（何度貼ってもよい）
   - 今の窓にも入れる。ほかの窓は開き直してから効く（WezTerm は新しいタブから）
   - `中断:` と出たら、何も変えていない

1. 自分用の設定（[ryo-aoki-pc/yazi](https://github.com/ryo-aoki-pc/yazi)）を入れる。

   - [yazi の設定を導入する](#yazi-の設定を導入する)の全項を通す
   - `custom` が出れば、入っている
   - 本体の依存と `YAZI_FILE_ONE` はこの項で設定済み。参照先は設定リポジトリの導入・確認を行う

1. 版と、yazi から見た環境を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   yazi --version
   ya --version
   ya env
   ```

   - `yazi --version` は `Version: 26.9.1 (…)` と、括弧の中が `windows-x86_64` の `Triple` の行、`ya --version` は `Version: 26.9.1 (…)` の行が出ればよい
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

   - `function` が出ればよい（[AlmaLinux 10 の初期設定の「yazi」](almalinux-setup.md#yazi)の手順 4 と同じ）
   - 最後の `y` で yazi が開く。別のフォルダーへ移って `q` で閉じると、Git Bash もそのフォルダーへ移る（`Q` なら移らない）
   - **次の手順は、yazi を閉じて、この項の手順 1 の PowerShell に戻ってから貼る**（続けて貼ると yazi への操作として食われる）

1. yazi を起動して確かめる。

   ```powershell
   yazi
   ```

   - プレビューを確かめるには、PDF・動画・画像・書庫のあるフォルダーで右のペインを見る
   - 画像のプレビューは、WezTerm（nightly）か Windows Terminal（1.22.10352.0 以降）の中で出る。conhost の窓では出ない
   - [表示と入力](#表示と入力)の手順 7 で既定の端末を Windows Terminal にした PC では、この窓も Windows Terminal で開く
   - `q` で閉じる
   - **ほかのブロックは、`q` で閉じてから貼る**（続けて貼ると yazi への操作として食われる）

#### yazi の設定を導入する

- Windows の yazi の既存設定を退避し、自分用の設定を入れる
- 前提: [yazi](#yazi)の手順 1〜5 までを通し、本体と依存ツールを入れ、`YAZI_FILE_ONE` を設定してある。Git も[Git for Windows](#git-for-windows)で入れてある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く
- yazi をすべて閉じてから始める。既存設定の確認と、この項の手順 2 の退避を省かない

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. yazi を終了し、自分用の設定を clone する。

   ```powershell
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
- 前提: [yazi](#yazi)と[Neovim](#neovim)を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。この項の手順 2・3 は Neovim、手順 4 は yazi の画面
- 既存の `init.lua` の変更を確かめ、yazi をすべて閉じてから始める
- `l` / `<Enter>` は既定でホバー中の 1 ファイルだけを開く。選択した複数ファイルをまとめて開くときだけ行う

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

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
   - **次の手順は、Neovim を閉じてから、この項の手順 1 の PowerShell に貼る**（続けて貼ると Neovim への入力として食われる）

1. yazi を起動し、選択した複数ファイルをまとめて開けるか確かめる。

   ```powershell
   yazi
   ```

   - 選択した複数ファイルが `l` / `<Enter>` でまとめて開けばよい
   - `q` で yazi を閉じる
   - **ほかのブロックは、yazi を閉じてから貼る**（続けて貼ると yazi への操作として食われる）

---

### mdtable

- GLFM の Markdown の表を、Excel のブックにして編集し、Markdown へ戻す（[md-table-excel](https://github.com/ryo-aoki-pc/md-table-excel)）

#### mdtable を導入・更新する

- Markdown と Excel を往復する mdtable を入れ、導入状態を確かめる
- 前提: [アプリを入れる](#アプリを入れる)の手順 2・3 と[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く
- Python 3.9 以上が要る。この項の手順 2 で、無ければ scoop で入れる
- 更新時は `git -C "$env:USERPROFILE\md-table-excel" status` で既存の変更を確かめてから進む

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. Python が無ければ scoop で入れ、版を確かめる。

   ```powershell
   if (-not (Get-Command python -ErrorAction SilentlyContinue)) { scoop install python }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   python --version
   ```

   - `Python 3.9` 以上の版が出ればよい
   - 3.9 より古い版やエラーが出たら、その Python を更新してから貼り直す

1. リポジトリを clone し、導入して確かめる。

   ```powershell
   git clone https://github.com/ryo-aoki-pc/md-table-excel.git "$env:USERPROFILE\md-table-excel"
   & {
     Push-Location -LiteralPath "$env:USERPROFILE\md-table-excel" -ErrorAction Stop
     try {
       python scripts/setup-mdtable.py
       "`n$([char]27)[7m 確認 $([char]27)[0m"
       python scripts/setup-mdtable.py --check
     } finally {
       Pop-Location
     }
   }
   ```

   - 依存はリポジトリ外の専用仮想環境へ入る
   - 起動コマンドは `%USERPROFILE%\.local\bin`。PATH に無いときは案内に従って加える
   - `--check` は何も変更せず状態を確かめる
   - 更新時は `git -C "$env:USERPROFILE\md-table-excel" pull --ff-only` を実行し、この項の手順 3 の `& { ... }` 部分（導入・確認）を貼り直す。`git clone` は再実行しない
   - 終わると元の作業ディレクトリへ戻る

#### mdtable のブックを Excel で編集するときの注意

- セルは文字列書式（`@`）。書式を消したり「すべて貼り付け」したりすると、`1/2` が日付・`3.10` が 3.1 などに変わることがある。日付のセルがあると取り込みは止まる
- 貼り付けは「値のみ」か、セルの編集中（F2・数式バー）に行う
- オートコレクト（`(c)` → `©` など）は入力を変える。コードを書くなら Excel の [ファイル] → [オプション] で切る
- 見出し行の直下に行を挿入すると、見出しの書式が写る（HTML の表では `<th>` になる）。[挿入オプション] で「下と同じ書式を適用」を選ぶ
- [セルを結合して中央揃え] は中央揃えも付く。結合だけなら [セルを結合]
- 「テーブルとして書式設定」（Ctrl+T）は使わない
- セルの一部だけの書式（文字の色・斜体など）は書き戻さない。強調は `**` などで書く
- シート名の変更・並べ替えはよい。シートを消した表は変更なしとして扱う。足したシートは読まない
- 表から離れたセルに書いた値は無視する（警告を出す）
- フォントは、書き出す PC に HackGen Console NF が入っていればそれ、無ければ BIZ UDゴシック（`\` が `¥` に見える）。環境変数 `MDTABLE_FONT` にフォント名を入れると、そのフォントにする

#### mdtable で Markdown の表を Excel と往復する

- 自分の Markdown の表を Excel で編集し、Markdown に書き戻す
- 前提: [mdtable を導入・更新する](#mdtable-を導入更新する)を通してある。Excel が入っている。対象の Markdown を編集できる
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。Excel の編集は、この PC のデスクトップで行う
- 例の `README.md` と `README.tables.xlsx` は、対象の文書名と対応するブック名に置き換える

> [!CAUTION]
> この項の手順 4・6 で Excel を編集する前に、[mdtable のブックを Excel で編集するときの注意](#mdtable-のブックを-excel-で編集するときの注意)を必ず読む。日付化・小数の桁落ちなどで、元の文字列を失うことがある。

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. 作業場所の変数を設定する（`MDTABLE_DIR` は必ず値を入れる）。

   ```powershell
   $MDTABLE_DIR = ''                     # ← 編集する自分の Markdown があるディレクトリの絶対パス。<MDTABLE_DIR>
   ```

   ```powershell
   'MDTABLE_DIR = {0}' -f $MDTABLE_DIR
   ```

   - 最後に値を読み戻して確かめる
   - **新しい PowerShell を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. 対象の Markdown があるディレクトリへ移る。

   ```powershell
   & {
     if (-not $MDTABLE_DIR) { Write-Error '中断: この項の手順 2 の MDTABLE_DIR が空のまま'; return }
     Set-Location -LiteralPath $MDTABLE_DIR -ErrorAction Stop
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-Location
   }
   ```

   - 対象の Markdown がある場所が出ればよい。エラーが出たら先へ進まず、この項の手順 2 の場所を確かめる

1. 表を一覧にし、Excel で開いて編集する。

   ```powershell
   mdtable list README.md
   mdtable edit README.md
   ```

   - `list` は表の番号・行・種類・大きさ・場所・直前の見出しを出す
   - `edit` は一時ブックを Excel で開く。保存して Excel を閉じてから Enter を押すと書き戻す
   - `--table 3` は 3 番目の表、`--table L120` は 120 行目を含む表を選ぶ
   - 書き戻せないときや Ctrl+C で止めたときはブックを残し、取り込み直すコマンドを表示する
   - **次の手順は、Excel を閉じて Enter を押し、プロンプトに戻ってから貼る**

1. ブックをファイルとして残すときだけ、Markdown から書き出す。

   ```powershell
   mdtable export README.md
   ```

   - Markdown と同じフォルダーに `README.tables.xlsx` ができる（`-o` で変更）。既存のブックは `--force` 無しでは上書きしない

1. ブックをファイルとして残すときだけ、Excel で開いて編集する。

   - エクスプローラーで `README.tables.xlsx` を開き、表を編集する
   - この項のリードから案内した、Excel で編集するときの注意に従う
   - **次の手順は、保存して Excel を閉じてから、この項の手順 1 の PowerShell に貼る**

1. ブックをファイルとして残すときだけ、取り込む前に差分を確かめる。

   ```powershell
   mdtable import README.tables.xlsx --dry-run
   ```

   - Markdown に書き戻す差分だけが出る
   - 差分が意図した内容と違えば、この項の手順 8 は貼らず、Markdown とブックを見直す
   - **次の手順は、差分を確かめてから貼る**

1. ブックをファイルとして残すときだけ、確かめた差分を Markdown に取り込む。

   ```powershell
   mdtable import README.tables.xlsx
   ```

   - ブックに記録した Markdown に書き戻す（`--md` で変更）
   - 書き出した後に Markdown の表を変えていたら、衝突として書き戻さない。`--force` を付けるとブックの内容で上書きする
   - 同じブックを再度取り込むと「適用済み」になる。取り込み後はブックを消してよい

---

## アプリ

- Firefox

### Firefox

- 日本語版の Firefox を PC 全体に入れ、既定のブラウザーにする
- 前提: [Microsoft Store の更新](#microsoft-store-の更新)を通し、winget が使える
- 実行場所: この PC のデスクトップの管理者の Windows PowerShell（5.1）。この項の手順 1 で開く。Firefox の起動と設定は、この PC のデスクトップ

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、右クリックして「管理者として実行」を選ぶ（PowerShell 7 の「PowerShell」ではない）
   - ユーザーアカウント制御（UAC）の確認は「はい」

1. Firefox がまだ入っていないことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   $arp = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
   Get-ItemProperty -Path $arp -ErrorAction SilentlyContinue | Where-Object DisplayName -like 'Mozilla Firefox*' | Format-Table DisplayName, DisplayVersion, InstallLocation
   Get-AppxPackage -Name 'Mozilla.MozillaFirefox' | Format-Table Name, Version
   ```

   - どちらも何も出なければ、入っていない
   - `Mozilla Firefox (x64 ja)` が `C:\Program Files\Mozilla Firefox` にあれば、この項の手順 3 をそのまま貼ってよい
   - ほかのもの（`(x64 en-US)` などのほかの言語・`(x86 ja)`・ESR・`%LOCALAPPDATA%` の下・Microsoft Store 版の `Mozilla.MozillaFirefox`）が出たら、設定 →「アプリ」→「インストールされているアプリ」で外してから始める（プロファイルは残る）

1. winget で日本語版の Firefox を PC 全体に入れ、入ったか確かめる。

   ```powershell
   winget install --exact --id Mozilla.Firefox.ja --source winget --scope machine --accept-source-agreements --accept-package-agreements
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget list --exact --id Mozilla.Firefox.ja --source winget
   (Get-Item -LiteralPath "$env:ProgramFiles\Mozilla Firefox\firefox.exe").VersionInfo | Format-List FileName, ProductVersion
   Get-Service -Name MozillaMaintenance | Format-Table Name, Status, StartType
   Get-ScheduledTask -TaskPath '\Mozilla\' -ErrorAction SilentlyContinue | Format-Table TaskName, State
   ```

   - `winget list` に `Mozilla Firefox (x64 ja)  Mozilla.Firefox.ja  157.0` の形の行が出ればよい
   - `FileName` が `C:\Program Files\Mozilla Firefox\firefox.exe` で、`ProductVersion` が同じ版
   - `MozillaMaintenance`（Mozilla Maintenance Service）の行が出る。ふだんは止まっていて、更新のときだけ動く
   - タスクの一覧に `Firefox Default Browser Agent <番号>` が出る
   - `winget` が見つからないと出たら、Microsoft Store で「アプリ インストーラー」を更新してから貼り直す

1. スタートメニューから Firefox を起動し、`about:support` で日本語版の公式のビルドかを確かめる。

   - スタートメニューの「Firefox」から起動する（管理者の PowerShell からは起動しない。Firefox が管理者の権限で動いてしまう）
   - 最初の起動で、Firefox を既定のブラウザーにするかを聞かれることがある。選ぶと Windows の設定が開くので、この項の手順 5 の操作をそこで行ってよい
   - アドレスバーに `about:support` を入れ、「アプリケーション基本情報」を見る
     - 「更新チャンネル」が `release`
     - 「プログラムの実行ファイル」が `C:\Program Files\Mozilla Firefox\firefox.exe`
   - 同じページの「コーデックサポート情報」で、`H264` と `AAC` の「ソフトウェアデコーディング」が「対応」になる
     - 情報が利用できないと出たら、動画を 1 本再生してから開き直す
   - メニューやボタンが日本語で出る

1. Windows の設定で、Firefox を既定のブラウザーにする。

   - 設定（Win+I）→「アプリ」→「既定のアプリ」を開き、「アプリケーションの既定値を設定する」の一覧で「Firefox」を選ぶ（2 つ並んだときは上のもの）
   - 「Firefox を既定のブラウザーに設定する」の横の「既定値に設定」を押す（押すと横にチェックの印が出る）
   - 押した後は、同じ画面の `.htm`・`.html`・`HTTP`・`HTTPS` などの既定が Firefox になる
   - Win+R の「ファイル名を指定して実行」に `https://www.mozilla.org/ja/` を入れて Enter を押し、Firefox で開けばよい
   - Firefox の `about:preferences` →「既定のブラウザーにする」からでもよい
   - 画面の名前が異なる場合は、Windows の既定のアプリの設定から Firefox を選ぶ

---

## ファイルの共有と同期

- Samba のクライアント、Syncthing

### Samba クライアント

- Samba の共有をドライブ文字に割り当て、サインインのたびにつなぎ直す
- 前提: サーバーで [Samba サーバー](almalinux-setup.md#samba-サーバー)を通してある。外出先では、[WireGuard: Windows 11 でトンネルを確かめる](#wireguard-windows-11-でトンネルを確かめる)に従ってトンネルを張り、サーバーにつながる状態にしてある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。手順 7 はサーバーの bash、手順 8 はこの PC のデスクトップ
- パスワードは Windows の資格情報マネージャーに置く
- Samba サーバーの `[root]`・`[home]` も割り当てるなら、この項を通した後に、この項の手順 2 の 3 つ目のブロックの `SHARE` と `DRIVE` を書き換えて貼り、この項の手順 3・5・6 を貼り直す（資格情報は同じなので、手順 4 は要らない）
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/samba-client.md)・[参考資料](reference/samba-client.md)・[ロールバックと注意点](extra/samba-client.md)

> [!IMPORTANT]
> **管理者の窓で割り当てたドライブは、エクスプローラーに出ない**。管理者ではない窓で行う。

1. Windows で、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にしない）
   - Windows Terminal の管理者のタブや、`sudo` で開いた窓も使わない

1. 変数を設定する（`SERVER` と `SMB_USER` は必ず値を入れる）。

   ```powershell
   $SERVER = ''                          # ← サーバーの IP アドレスか DNS 名（Samba サーバーの SERVER_IP）。<SERVER>
   ```

   ```powershell
   $SMB_USER = ''                        # ← サーバーの Samba ユーザー（AlmaLinux の「Samba サーバー」の設定なら、サーバーの OS のユーザー名）。<SMB_USER>
   ```

   ```powershell
   $SHARE = $SMB_USER                    # 共有名。Samba サーバーの [homes] では、ユーザー名と同じ名前の共有になる。<SHARE>
   $DRIVE = 'Z:'                         # 割り当てるドライブ文字（コロンまで書く）。<DRIVE>
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'SERVER   = {0}' -f $SERVER
   'SMB_USER = {0}' -f $SMB_USER
   'SHARE    = {0}' -f $SHARE
   'DRIVE    = {0}' -f $DRIVE
   ```

   - 最後に値を読み戻して確かめる
   - `SMB_USER` は、Windows のユーザー名ではなく、サーバーの Samba ユーザーにする
   - [root のホーム](almalinux-setup.md#samba-サーバー-root-のホームも公開する)なら `SHARE=root`、[/home](almalinux-setup.md#samba-サーバー-home-も公開する)なら `SHARE=home` にする
   - `SMB_USER` は自分のまま。`DRIVE` はほかの割り当てと違う文字にする
   - `SERVER` は、エクスプローラーで `\\<SERVER>\…` を開くときと同じ書き方にする
   - **新しい PowerShell を開いたら**、この項の手順 2 の 3 つのブロックを貼り直してから先へ進む

1. 管理者ではないことと、サーバーの 445 番・ドライブ文字・保存済みの資格情報を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not $SERVER -or -not $SMB_USER -or -not $SHARE -or -not $DRIVE) {
     Write-Error '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す'
   } elseif (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
     Write-Error '中断: 管理者の窓で開いている。この項の手順 1 で、管理者ではない窓を開き直す'
   } elseif ($DRIVE -notmatch '^[A-Za-z]:$') {
     Write-Error '中断: この項の手順 2 の DRIVE は、Z: のようにドライブ文字とコロンにする'
   } elseif (-not (Test-NetConnection -ComputerName $SERVER -Port 445 -WarningAction SilentlyContinue).TcpTestSucceeded) {
     Write-Error "中断: $SERVER の 445/tcp に届かない"
   } elseif ((Test-Path -LiteralPath "$DRIVE\") -or (Get-SmbMapping -LocalPath $DRIVE -ErrorAction SilentlyContinue)) {
     Write-Error "中断: $DRIVE はもう使われている（切れたまま覚えている割り当ても含む）"
   } else {
     "$SERVER の 445/tcp に届く。$DRIVE は空いている"
     cmdkey "/list:$SERVER"
   }
   ```

   - `<SERVER> の 445/tcp に届く。<DRIVE> は空いている` と、`<SERVER>` の資格情報の一覧が出ればよい
   - 一覧にある `<SERVER>` の保存済み資格情報は、この項の手順 4 で置き換わり、[ロールバック](extra/samba-client.md#windows-11-のロールバック)の手順 2 で消える
   - `445/tcp に届かない` ときは、`SERVER` の値と、サーバーの firewalld と smbd（[Samba サーバー 手順 5・8](almalinux-setup.md#samba-サーバー)）を確かめる。外出先なら、先に WireGuard のトンネルを張る
   - `もう使われている` ときは、`DRIVE` を別の文字にして、この項の手順 2 の 3 つ目のブロックを貼り直す。前にこの項で同じ共有を割り当てたなら、この項は済んでいる

1. 資格情報マネージャーに、共有のユーザー名とパスワードを登録する。

   ```powershell
   if (-not $SERVER -or -not $SMB_USER) {
     Write-Error '中断: この項の手順 2 の SERVER か SMB_USER が空のまま。値を入れて貼り直す'
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     cmdkey "/add:$SERVER" "/user:$SMB_USER" /pass
   }
   ```

   - パスワードを聞かれる。AlmaLinux の「Samba サーバー」の設定なら、[Samba サーバー 手順 6](almalinux-setup.md#samba-サーバー) で `smbpasswd -a` に入れたパスワード
   - 資格情報を追加した旨の 1 行が出ればよい
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. 共有をドライブ文字に割り当て、サインインのたびにつなぎ直すようにする。

   ```powershell
   if (-not $SERVER -or -not $SHARE -or -not $DRIVE) {
     Write-Error '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す'
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     New-SmbMapping -LocalPath $DRIVE -RemotePath "\\$SERVER\$SHARE" -Persistent $true | Out-Null
     Get-SmbMapping -LocalPath $DRIVE | Format-Table Status, LocalPath, RemotePath
   }
   ```

   - `OK`・`<DRIVE>`・`\\<SERVER>\<SHARE>` の 1 行が出ればよい
   - ユーザー名かパスワードが違うと断られたら、この項の手順 4 を貼り直してから、この手順を貼り直す
   - エラー 1219 が出たら、[注意点](extra/samba-client.md#注意点)の Windows 11 のエラー 1219 を見る
   - エクスプローラーには、この項の手順 8 でサインインし直すまで出ないことがある

1. 割り当てたドライブで読み書きできることを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not $DRIVE) {
     Write-Error '中断: この項の手順 2 の DRIVE が空のまま。値を入れて貼り直す'
   } else {
     Get-ChildItem -LiteralPath "$DRIVE\" | Select-Object -First 5 -ExpandProperty Name
     Set-Content -LiteralPath "$DRIVE\smb-win-test.txt" -Value 'smb write' -Encoding ascii
     Get-Content -LiteralPath "$DRIVE\smb-win-test.txt"
     Remove-Item -LiteralPath "$DRIVE\smb-win-test.txt"
     Test-Path -LiteralPath "$DRIVE\smb-win-test.txt"
   }
   ```

   - 共有の中の名前（5 つまで。隠しファイルは出ない）、`smb write`、`False` の順に出ればよい
   - `SHARE=home`（Samba サーバーの `[home]`）では、書き込みが拒否される。名前の一覧が出ていればよい

1. サーバーで、署名付きの SMB3_11 でつながっていることを確かめる。

   ```bash
   sudo smbstatus
   ```

   - サーバーのシェルに貼る
   - この PC の IP アドレスの行の `Protocol Version` が `SMB3_11` で、`Signing` が `AES-128-GMAC` などの方式の名前だけ（`partial(…)` でも `-` でもない）ならよい
   - `Encryption` は `-`（LAN の上の通信は暗号化されない。[Samba サーバーの注意点](extra/samba.md#注意点)）
   - Windows 11 Home の PC では、`Signing` が `partial(…)` か `-` になりうる（[注意点](extra/samba-client.md#注意点)）
   - この PC の行が無ければ、エクスプローラーかこの PC の PowerShell で `<DRIVE>` を開いてから、貼り直す

1. サインアウトしてサインインし直し、ドライブがパスワード無しで開くことを確かめる。

   - スタートメニューの自分のアイコンから「サインアウト」を選び、もう一度サインインする
   - エクスプローラーの「PC」の「ネットワークの場所」に、`<SHARE> (\\<SERVER>) (<DRIVE>)` のような名前でドライブが出ればよい
   - 開いたときにパスワードを聞かれなければよい
   - 赤い × が付いているときは、サインインのときにサーバーに届かなかった（[注意点](extra/samba-client.md#注意点)）

#### Samba クライアント: Windows 11 の更新

- Samba サーバーで変えたパスワードを、Windows の資格情報マネージャーにも入れ直す
- 前提: [Samba クライアント](#samba-クライアント)を通し、サーバーで Samba のパスワードを変えてある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。手順 4 はこの PC のデスクトップ
- SMB のクライアントは Windows Update で上がる。この項で上げるものは無い

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. 変数を設定する（`SERVER`・`SMB_USER` は必ず値を入れる）。

   ```powershell
   $SERVER = ''
   ```

   ```powershell
   $SMB_USER = ''
   ```

   ```powershell

   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{ SERVER = $SERVER; SMB_USER = $SMB_USER } | Format-List
   ```

   - `SERVER` と `SMB_USER` は、[Samba クライアント](#samba-クライアント)の手順 2 と同じ値を入れる
   - **新しい窓を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. Samba のパスワードを変えたときだけ、資格情報を登録し直す。

   ```powershell
   if (-not $SERVER -or -not $SMB_USER) {
     Write-Error '中断: この項の手順 2 の SERVER か SMB_USER が空のまま。値を入れて貼り直す'
   } else {
     cmdkey "/add:$SERVER" "/user:$SMB_USER" /pass
   }
   ```

   - サーバーで変えた後の新しいパスワードを入れる
   - パスワードを入力し終えてから、この項の手順 4 を行う

1. サインアウトしてサインインし直し、ドライブがパスワード無しで開くことを確かめる。

   - [Windows 11 で使う](#samba-クライアント)の手順 8 と同じ

---

### Syncthing

- この PC に Syncthing を入れ、サインイン中の自動起動と GUI を設定する
- 前提: [ネットワークとリモート](#ネットワークとリモート)を通し、相手とつながる LAN の接続をプライベートにしてある
- 実行場所: この PC のデスクトップの管理者の Windows PowerShell（5.1）。この項の手順 1 で開く。手順 12 は LAN の別の端末のブラウザ、手順 13 はこの PC のデスクトップ
- フォルダー追加は[同期フォルダとデバイスを追加する](almalinux-setup.md#syncthing-同期フォルダとデバイスを追加する)を通す
- この PC は、[AlmaLinux 10 の Syncthing](almalinux-setup.md#syncthing)の相手にもなる
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/syncthing.md)・[参考資料](reference/syncthing.md)・[ロールバックと注意点](extra/syncthing.md)

> [!IMPORTANT]
> - **ホーム全体は同期しない**。同期するフォルダーだけを追加する
> - Syncthing は、管理者ではない自分のユーザーとして、サインインしている間だけ動く（この項の手順 8 のタスク）

1. Windows で、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く
   - PowerShell 7（`pwsh`）ではなく、Windows PowerShell 5.1 にする

1. 変数を設定する。

   ```powershell
   $ST_GUI_USER = $env:USERNAME          # GUI のログイン名。Windows のアカウントとは別物（自動で同じ名前が入る）。<WIN_USER>
   $LAN_IF = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).InterfaceAlias   # 相手とつながる LAN の接続（自動）。<LAN_IF>
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'ST_GUI_USER = {0}' -f $ST_GUI_USER
   'LAN_IF      = {0}' -f $LAN_IF
   ```

   - **編集が必須の変数は無い**
   - 最後に値を読み戻して確かめる
   - `LAN_IF` は、インターネットにつながっている接続の名前（`イーサネット`、`Wi-Fi` など）。相手とつながる接続と違えば、`$LAN_IF = 'Wi-Fi'` のように直す
   - **新しい PowerShell を開いたら**、この項の手順 2 のブロックを貼り直してから先へ進む

1. この PC に Syncthing が無いことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Process -Name syncthing -ErrorAction SilentlyContinue | Format-Table Id, Path
   Get-ScheduledTask -TaskName 'Syncthing' -ErrorAction SilentlyContinue | Format-Table TaskName, State
   Get-NetTCPConnection -State Listen -LocalPort 8384, 22000 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess
   Test-Path "$env:LOCALAPPDATA\Syncthing\config.xml", "$env:LOCALAPPDATA\Programs\Syncthing"
   ```

   - 最初の 3 つは何も出さず、最後に `False` が 2 行出ればよい
   - 何か出たら、ほかの方法で入れた Syncthing（SyncTrayzor、Syncthing Windows Setup など）がある。それを止めて外してから始める
   - [Windows 11 のロールバック](extra/syncthing.md#windows-11-のロールバック)の手順 1〜4 の後に入れ直すときは、1 行目の `True`（`config.xml`。前の鍵と設定）はそのままでよい

1. 公式の zip を取って sha256 と署名を確かめ、`syncthing.exe` を置く。

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
     $curl = "$env:WINDIR\System32\curl.exe"
     $arch = @{ AMD64 = 'amd64'; ARM64 = 'arm64' }[$env:PROCESSOR_ARCHITECTURE]
     $tmp = "$env:TEMP\syncthing-setup"
     if (Get-Process -Name syncthing -ErrorAction SilentlyContinue) { Write-Error '中断: Syncthing が動いている'; return }
     if (-not $arch) { Write-Error "中断: この手順は $env:PROCESSOR_ARCHITECTURE の Windows を扱わない"; return }
     Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
     New-Item -ItemType Directory -Path $tmp | Out-Null
     & $curl -fsSL -o "$tmp\sha256sum.txt.asc" https://github.com/syncthing/syncthing/releases/latest/download/sha256sum.txt.asc
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: sha256sum.txt.asc を取れない'; return }
     $m = Select-String -LiteralPath "$tmp\sha256sum.txt.asc" -CaseSensitive -Pattern "^([0-9a-f]{64})  (syncthing-windows-$arch-(v\d+\.\d+\.\d+)\.zip)$" | Select-Object -First 1
     if (-not $m) { Write-Error '中断: sha256sum.txt.asc に Windows 版の行が無い'; return }
     $hash = $m.Matches[0].Groups[1].Value
     $zip = $m.Matches[0].Groups[2].Value
     $ver = $m.Matches[0].Groups[3].Value
     & $curl -fsSL -o "$tmp\$zip" "https://github.com/syncthing/syncthing/releases/download/$ver/$zip"
     if ($LASTEXITCODE -ne 0) { Write-Error "中断: $zip を取れない"; return }
     if ((Get-FileHash -LiteralPath "$tmp\$zip" -Algorithm SHA256).Hash -ne $hash) { Write-Error "中断: $zip の sha256 が一致しない"; return }
     Expand-Archive -LiteralPath "$tmp\$zip" -DestinationPath $tmp -Force
     $new = Join-Path $tmp (($zip -replace '\.zip$', '') + '\syncthing.exe')
     $sig = Get-AuthenticodeSignature -LiteralPath $new
     if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notlike 'CN=Kastelo AB,*' -or -not $sig.TimeStamperCertificate) { Write-Error "中断: syncthing.exe の署名を確かめられない（$($sig.Status)）"; return }
     New-Item -ItemType Directory -Force -Path (Split-Path $exe) | Out-Null
     Copy-Item -LiteralPath $new -Destination $exe -Force
     Remove-Item -LiteralPath $tmp -Recurse -Force
     '{0}: sha256 一致、署名 {1}' -f $zip, $sig.Status
     & $exe --version
     icacls.exe (Split-Path $exe)
   }
   ```

   - `syncthing-windows-amd64-v2.1.5.zip: sha256 一致、署名 Valid` と、`syncthing v2.1.5 "Hafnium Hornet" (go1.27.1 windows-amd64) …` の 1 行が出ればよい
   - `icacls` の一覧に、自分のユーザーの `(F)`（フル コントロール）の行がある
   - `中断:` で始まるエラーが出たら、何も置いていない
   - 何度貼ってもよい（Syncthing が動いているときは止まる）

1. GUI のパスワードを読み取る。

   ```powershell
   $ST_GUI_PASS = Read-Host -AsSecureString 'Syncthing GUI のパスワード'
   ```

   - **入力は `*` で表示される**
   - ASCII の英数字と記号だけにする
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. 最初に起動する前に、鍵と設定を作り、GUI のログイン名とパスワードを入れる。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not $ST_GUI_USER) {
     Write-Error 'この項の手順 2 の $ST_GUI_USER が空'
   } elseif (-not $ST_GUI_PASS -or $ST_GUI_PASS.Length -eq 0) {
     Write-Error '手順 5 のパスワードが空'
   } else {
     $p = ([Net.NetworkCredential]::new('', $ST_GUI_PASS)).Password
     if ($p -cnotmatch '^[\x20-\x7e]+$') {
       Write-Error 'パスワードに ASCII でない文字がある（この項の手順 5 からやり直す）'
     } else {
       $p | & $exe generate "--gui-user=$ST_GUI_USER" --gui-password=-
       if ($LASTEXITCODE -eq 0) { & $exe device-id }
     }
     Remove-Variable p
   }
   Remove-Variable ST_GUI_PASS -ErrorAction SilentlyContinue
   ```

   - `Calculated device ID`・`Updated GUI authentication user`・`Updated GUI authentication password` の行と、最後に 7 文字 x 8 の文字列が出ればよい
   - 最後の文字列が、**この PC のデバイス ID**。相手のデバイスに教える値で、秘密ではない
   - 前の鍵が残っている PC では、先頭が `Key exists; will not overwrite` になり、デバイス ID は前と同じ
   - エラーで止まったら、この項の手順 5 からやり直す

1. LAN の接続がプライベートなことを確かめ、Syncthing の受信の規則を作る。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   $g = 'Syncthing (setup-notes)'
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not $LAN_IF) {
     Write-Error 'この項の手順 2 の $LAN_IF が空'
   } elseif ((Get-NetConnectionProfile -InterfaceAlias $LAN_IF).NetworkCategory -ne 'Private') {
     Write-Error '中断: LAN の接続がプライベートではない（Windows 11 の初期設定の「ネットワークとリモート」の手順 3 でプライベートにする）'
   } else {
     Remove-NetFirewallRule -Group $g -ErrorAction SilentlyContinue
     New-NetFirewallRule -Name 'Syncthing-In-TCP' -DisplayName 'Syncthing (TCP 22000)' -Group $g -Direction Inbound -Action Allow -Profile Private -Program $exe -Protocol TCP -LocalPort 22000 | Out-Null
     New-NetFirewallRule -Name 'Syncthing-In-UDP' -DisplayName 'Syncthing (UDP 22000, 21027)' -Group $g -Direction Inbound -Action Allow -Profile Private -Program $exe -Protocol UDP -LocalPort 22000, 21027 | Out-Null
     New-NetFirewallRule -Name 'Syncthing-GUI-In-TCP' -DisplayName 'Syncthing GUI (TCP 8384)' -Group $g -Direction Inbound -Action Allow -Profile Private -Program $exe -Protocol TCP -LocalPort 8384 | Out-Null
     Get-NetConnectionProfile -InterfaceAlias $LAN_IF | Format-Table InterfaceAlias, NetworkCategory
     Get-NetFirewallRule -Group $g | Format-Table Name, Enabled, Profile, Direction, Action
   }
   ```

   - `<LAN_IF>  Private` と、3 つの規則が `True  Private  Inbound  Allow` で出ればよい
   - `中断:` が出たら、[Windows 11 の初期設定の「ネットワークとリモート」の手順 3](#ネットワークとリモート) でプライベートにしてから、この手順を貼り直す
   - 何度貼ってもよい
   - **注意**: プライベートの LAN では、プライベート向けのほかの許可の規則（ネットワーク探索など）も効く（[Windows 11 の初期設定の「OpenSSH サーバー」の手順 5](#openssh-サーバー)の補足）

1. サインインしたときに Syncthing を起動するタスクを登録する。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   $me = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
   $action = New-ScheduledTaskAction -Execute $exe -Argument '--no-console --no-browser' -WorkingDirectory (Split-Path $exe)
   $trigger = New-ScheduledTaskTrigger -AtLogOn -User $me
   $principal = New-ScheduledTaskPrincipal -UserId $me -LogonType Interactive
   $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Register-ScheduledTask -TaskName 'Syncthing' -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Format-List TaskName, State
   ```

   - `TaskName : Syncthing` と `State : Ready` が出ればよい

1. タスクを開始し、Syncthing が起動したことを確かめる。

   ```powershell
   if (Get-Process -Name syncthing -ErrorAction SilentlyContinue) {
     Write-Error 'Syncthing はもう動いている'
   } else {
     Start-ScheduledTask -TaskName 'Syncthing'
     for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     (Get-ScheduledTask -TaskName 'Syncthing').State
     Get-CimInstance Win32_Process -Filter "Name='syncthing.exe'" | Format-Table ProcessId, ParentProcessId -AutoSize
     Get-NetTCPConnection -State Listen -LocalPort 8384, 22000 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess
   }
   ```

   - `Running` と、`syncthing.exe` が 2 つ（片方の `ParentProcessId` がもう片方の `ProcessId`）出ればよい
   - 新規導入では 8384 は `127.0.0.1`。設定を残した再導入では元の待ち受けでよい。22000 の行も出る
   - 最初の起動は、数秒かかる
   - **注意**: 「Windows セキュリティの重要な警告」の窓が出たら、**キャンセルを押さない**（拒否の規則ができる）。「プライベート ネットワーク」だけにチェックして「アクセスを許可する」を押す

1. GUI の待ち受けを LAN に広げて HTTPS にする。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   & $exe cli config gui raw-address set 0.0.0.0:8384
   & $exe cli config gui raw-use-tls set true
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & $exe cli config gui raw-address get
   & $exe cli config gui raw-use-tls get
   for ($i = 0; $i -lt 30 -and (Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue).LocalAddress -contains '127.0.0.1'; $i++) { Start-Sleep -Seconds 1 }
   Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess
   ```

   - `0.0.0.0:8384` と `true` が出て、8384 の `LocalAddress` が `127.0.0.1` でなくなればよい（`::` か `0.0.0.0`）
   - `127.0.0.1` のままなら、[Windows 11 で止める・もう一度始める](#syncthing-windows-11-で止めるもう一度始める)の手順 2・3 で起動し直す

1. 待ち受け・規則・デバイス ID を確かめ、GUI の URL を出す。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   $proc = @{ Label = 'Process'; Expression = { (Get-Process -Id $_.OwningProcess).ProcessName } }
   if (-not $LAN_IF) {
     Write-Error 'この項の手順 2 の $LAN_IF が空'
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-NetTCPConnection -State Listen -LocalPort 8384, 22000 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, $proc
     Get-NetUDPEndpoint -LocalPort 22000, 21027 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, $proc
     Get-NetFirewallApplicationFilter | Where-Object Program -like '*\Programs\Syncthing\syncthing.exe' | Get-NetFirewallRule | Format-Table DisplayName, Enabled, Profile, Action
     Get-NetConnectionProfile -InterfaceAlias $LAN_IF | Format-Table InterfaceAlias, NetworkCategory
     & $exe device-id
     Get-Content -LiteralPath "$env:LOCALAPPDATA\Syncthing\syncthing.log" -Tail 5 -Encoding UTF8 -ErrorAction SilentlyContinue
     'GUI: https://{0}:8384/  （ログイン名 {1}）' -f (Get-NetIPAddress -InterfaceAlias $LAN_IF -AddressFamily IPv4).IPAddress, $ST_GUI_USER
   }
   ```

   - 8384/tcp・22000/tcp・22000/udp・21027/udp が、どれも `syncthing` で出ればよい
   - 規則はこの項の手順 7 の 3 つだけが `Allow` で出る（規則の一覧は数秒かかる）
   - **`Block` の行があれば**、警告の窓でキャンセルを押した跡。[Windows 11 のロールバック](extra/syncthing.md#windows-11-のロールバック)の手順 2 で規則をすべて消し、この項の手順 7 を貼り直す
   - 最後の行の URL を、この項の手順 12 で使う

1. LAN の別の端末のブラウザで GUI に入り、デバイス ID を確かめる。

   - この項の手順 11 の URL を開き、自己署名の証明書の警告を受け入れ、この項の手順 2 のログイン名とこの項の手順 5 のパスワードで入る
   - 最初に、利用状況の報告（Usage Reporting）を許可するかを聞かれる。どちらでもよい
   - Actions → Show ID のデバイス ID が、この項の手順 11 の `device-id` と同じであることを確かめる
   - 新規導入では同期するフォルダは 1 つも無い。設定を残した再導入では、前のフォルダが並んでよい

1. この PC でサインアウトし、サインインし直す。

   - スタートメニューのユーザーのアイコン → 「サインアウト」
   - **次の手順は、サインインし直して管理者の Windows PowerShell を開いてから貼る**

1. サインインで Syncthing が起動したことを確かめる。

   ```powershell
   for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-ScheduledTask -TaskName 'Syncthing').State
   Get-CimInstance Win32_Process -Filter "Name='syncthing.exe'" | Format-Table ProcessId, ParentProcessId -AutoSize
   Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess
   ```

   - `Running` と、`syncthing.exe` が 2 つ、8384 が `127.0.0.1` 以外で出ればよい
   - この項の手順 2 の変数は要らない

#### Syncthing: Windows 11 で止める・もう一度始める

- Syncthing を止め、必要なときにもう一度始める
- 前提: [Syncthing](#syncthing)を通してある
- 実行場所: この PC のデスクトップの管理者の Windows PowerShell（5.1）。この項の手順 1 で開く
- 動いているかは、タスクの状態ではなくプロセスで見る。止めるのはこの項の手順 2

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開き、UAC の確認に答える

1. Syncthing を止める。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   if (-not (Get-Process -Name syncthing -ErrorAction SilentlyContinue)) {
     'Syncthing は動いていない'
   } else {
     & $exe cli operations shutdown
     for ($i = 0; $i -lt 30 -and (Get-Process -Name syncthing -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-Process -Name syncthing -ErrorAction SilentlyContinue | Format-Table Id
     (Get-ScheduledTask -TaskName 'Syncthing').State
   }
   ```

   - プロセスの一覧は何も出ず、タスクは `Ready` になればよい

1. もう一度始めるときは、タスクを開始する。

   ```powershell
   if (Get-Process -Name syncthing -ErrorAction SilentlyContinue) {
     Write-Error 'Syncthing はもう動いている'
   } else {
     Start-ScheduledTask -TaskName 'Syncthing'
     for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     (Get-ScheduledTask -TaskName 'Syncthing').State
     Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess
   }
   ```

   - `Running` と、8384 の待ち受けが出ればよい

#### Syncthing: Windows 11 の更新

- 自動更新を待たずに、Syncthing を上げる
- 前提: [Syncthing](#syncthing)を通し、Syncthing が動いている
- 実行場所: この PC のデスクトップの管理者の Windows PowerShell（5.1）。この項の手順 1 で開く
- Syncthing は稼働中、既定で 12 時間ごとに新しい版を確かめ、あれば自分で入れ替えて起動し直す。サインアウト中・スリープ中・通信できない間は更新されない
- **自動で入れ替えた後の Syncthing は、タスクの外で動く**（タスクは `Ready` になる）。次のサインインからは、またタスクで起動する

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開き、UAC の確認に答える

1. 今の版と、新しい版があるかを確かめる。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & $exe --version
   & $exe upgrade --check-only
   ```

   - 新しい版があれば、`Upgrade available` の行に今の版（`current`）と新しい版（`latest`）が出る
   - 新しい版が無ければ、`no upgrade available (current "v2.1.5" >= latest "v2.1.5")` のエラーが出る。そのときは、この項の手順 3 は飛ばす

1. 新しい版があるときだけ、今すぐ上げる。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   $before = & $exe --version
   & $exe cli operations upgrade
   for ($i = 0; $i -lt 60 -and (& $exe --version) -eq $before; $i++) { Start-Sleep -Seconds 1 }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & $exe --version
   Start-Sleep -Seconds 5
   Get-CimInstance Win32_Process -Filter "Name='syncthing.exe'" | Format-Table ProcessId, ParentProcessId -AutoSize
   ```

   - `--version` が新しい版になり、`syncthing.exe` が 2 つ出ればよい

---

## 更新

- OS・Store の更新は[Windows Update](#windows-update)（管理者）・[Microsoft Store の更新](#microsoft-store-の更新)（通常）を通す。再起動は手動で行う
- scoop・winget で入れたアプリは、入れた方法で上げる
  - zoxide は 0.9.9 に固定中。[scoop・winget・WSL を上げる](#scoopwingetwsl-を上げる)の手順 7 で修正版を確かめ、手順 7 で上げる
  - 上げても、git の設定（`~/.gitconfig`）と gh のログイン（資格情報マネージャーと `%APPDATA%\GitHub CLI`）は変わらない
- Firefox は、自分で新しい版に上がる。待たずに上げるときだけ、その手順を行う
  - Firefox は起動中に取得し、次の起動時に更新する。起動後に作られる `\Mozilla\Firefox Background Update <番号>` のタスクも、7 時間ごとに更新する
  - Firefox の更新は Mozilla Maintenance Service が書き込み、UAC は出ない。日本語版に言語パックを足すと、閉じている間の更新が止まるので使わない
- Claude Code・Codex CLI・Grok Build とプラグインは、[AI コーディングエージェントのセットアップの「Windows 11 の更新」](ai-agents.md#windows-11-の更新)で上げる
- WezTerm は自分では更新しない。nightly の新しい版が出ても知らせない（WezTerm の更新の確認が見るのは stable のリリースだけで、nightly の版の方が新しいので何も出ない）
  - [Git for Windows・Firefox・WezTerm を上げる](#git-for-windowsfirefoxwezterm-を上げる)の手順 2・6〜8 で、設定を残して `C:\Program Files\WezTerm` に上書きする
  - nightly は毎日ビルドし直される。版は main の最後のコミットで決まり、コミットの無い日は同じ版になる
- フォントは[HackGen Console NF を上げる](#hackgen-console-nf-を上げる)に従い、この文書の版と sha256 を確かめて直してから入れ直す
- 共通の bash 設定は、[共通の bash 設定を更新する](#共通の-bash-設定を更新する)を通して上げる
- 自分用の設定（WezTerm・Neovim・lazygit・yazi）は、それぞれのリポジトリの更新で上げる
  - yazi の自分用の設定は上流の版に合わせてある。yazi の版が上がったら、その [README の「上流の新しい版に追従する」](https://github.com/ryo-aoki-pc/yazi#上流の新しい版に追従する)で設定も追う
- SSH で scoop のツールを使うなら、更新後に[scoop のツールを SSH のセッションで使う](#scoop-のツールを-ssh-のセッションで使う)の手順 3 を管理者の窓に貼り直す
- UniGet UI の画面からも、scoop と winget のパッケージをまとめて上げられる（UniGet UI と PowerToys は、自分でも新しい版を確かめる）
- CopyQ は、更新のインストーラが閉じた後に起動し直さないことがある。通知領域にアイコンが無ければ、スタートメニューの「CopyQ」から起動する
- Windows の大きな更新（機能の更新）の後は、外したアプリと切った提案が戻ることがある。[表示と入力](#表示と入力)の手順 4 と[自動起動と標準アプリ](#自動起動と標準アプリ)の手順 1〜4 を貼り直す
- 機能更新後は、プライバシー・表示／入力／音／ストレージ・Edge の任意設定も確認する。戻っていれば、その節の「元に戻すときは、」より前を貼り直す（控えは書き換えない）
- VirtualBox は[仮想マシンのセットアップの「VirtualBox: Windows 11 の更新」](virtual-machines.md#virtualbox-windows-11-の更新)、WireGuard は手順書の「Windows 11 の更新」
  - [SSH クライアント（Windows）](#windows-の-openssh-クライアント-更新)は「更新」、[Samba の共有のネットワーク ドライブ](#samba-クライアント-windows-11-の更新)は「Windows 11 の更新」（どちらも、上げるものは無い）

### scoop・winget・WSL を上げる

- scoop・winget のアプリと WSL・AlmaLinux 10 を上げる
- 前提: [アプリを入れる](#アプリを入れる)・[Git for Windows](#git-for-windows)・[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)を通してある。zoxide を上げるときは、[シェルのツールを入れる](#シェルのツールを入れる)と[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。zoxide のリリースはブラウザ、上げた後の確認は WezTerm の Git Bash のタブ
- PSWindowsUpdate は、[Windows Update](#windows-update)を通してこの文書で入れたときだけ上げる

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. scoop とバケットを上げ、古くなったものを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop update
   scoop status
   ```

   - `scoop update` は `Scoop was updated successfully!` を出す
   - git が無いと `Scoop uses Git to update itself. Run 'scoop install git' and try again.` で止まる。先に [Git for Windows](#git-for-windows)で Git for Windows を入れる
   - `scoop status` は、古いものがあれば名前と版を並べる。`Everything is ok!` なら、この項の手順 3 は飛ばす

1. 古いものがあるときだけ、scoop で入れたものを上げる。

   ```powershell
   scoop update *
   ```

   - アプリごとに `'<名前>' (<版>) was installed successfully!` の形の行が出る
   - 動いているアプリは `Running process detected, skip updating.` で飛ばされる。閉じてから貼り直す
   - SSH のセッションで scoop のツールを使っているなら、[scoop のツールを SSH のセッションで使う](#scoop-のツールを-ssh-のセッションで使う)の手順 3 を、管理者の PowerShell で貼り直す
   - **Neovim の設定やプラグインは更新に追従しない**ので、メジャー更新の後は `:checkhealth` で壊れていないか見る（自分用の設定のプラグインと外部コマンドは、[LazyVim の更新](#lazyvim-の本体外部コマンドプラグインを更新する)の全項）

1. winget で入れたものを上げる。

   ```powershell
   foreach ($id in 'Devolutions.UniGetUI', 'Microsoft.PowerToys', 'Microsoft.PowerShell', 'Microsoft.Sysinternals.Autologon', 'hluk.CopyQ') { winget upgrade --exact --id $id --source winget --accept-source-agreements --accept-package-agreements }
   ```

   - それぞれ、新しい版が無ければ更新が見つからない旨の行を出して何もしない
   - 動いている UniGet UI・PowerToys は、インストーラが閉じる
   - 入れていないものは、入っていない旨の行を出すだけ

1. WSL と AlmaLinux 10 を上げる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   wsl.exe --update
   wsl.exe --distribution AlmaLinux-10 --user root -- dnf -y upgrade
   ```

   - `wsl.exe --update` は、新しい版が無ければ、最新である旨を出す
   - `dnf -y upgrade` の最後に `Complete!` か `Nothing to do.` が出ればよい

1. この文書で PSWindowsUpdate を入れたときだけ、モジュールを更新する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     if ((Get-ExecutionPolicy) -notin 'RemoteSigned', 'Unrestricted', 'Bypass') {
       Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
     }
     [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
     Update-Module -Name PSWindowsUpdate -Force
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-InstalledModule -Name PSWindowsUpdate | Select-Object Name, Version, InstalledLocation
   }
   ```

   - モジュールの版と場所が出ればよい
   - 次の Windows Update は[Windows Update](#windows-update)の手順 1 で新しく開いた管理者の窓で行う
   - この文書の前から入っていた PSWindowsUpdate は、元の導入方法で管理する

1. zoxide を上げるときは、ブラウザで、Git Bash の記録を直した版が出たかを確かめる。

   - `https://github.com/ajeetdsouza/zoxide/releases` を開く
   - 0.10.0 より新しい版の変更点に、「Bash/Zsh: fix `z` failing on Cygwin/MSYS2」で始まる行があれば、直った版が出ている
   - 無ければ、この項の手順 8 は飛ばす（0.9.9 のまま使う）
   - **次の手順は、管理者ではない Windows PowerShell（5.1）に貼る**

1. Git Bash の記録を直した版が出ているときだけ、zoxide を止めるのをやめて上げる。

   ```powershell
   & {
     scoop update
     $v = (Get-Content -LiteralPath "$env:USERPROFILE\scoop\buckets\main\bucket\zoxide.json" -Raw | ConvertFrom-Json).version
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($v -notmatch '^\d+\.\d+\.\d+$' -or [version]$v -le [version]'0.10.0') { Write-Error "中断: scoop の main のバケットの zoxide はまだ $v。日を置いて、この項の手順 7 から"; return }
     scoop unhold zoxide
     scoop update zoxide --force
     zoxide --version
   }
   ```

   - `zoxide is no longer held and can be updated again.` と、`'zoxide' (<版>) was installed successfully!` が出て、最後に新しい版が出ればよい
   - `中断:` が出たら、Releases に出た版が、まだ scoop の main のバケットに入っていない。zoxide は何も変えていない（0.9.9 に止めたまま）
   - `Running process detected, skip updating.` が出たら、上がっていない。Git Bash で開いている `zi` の一覧などを閉じてから、このブロックを貼り直す
   - WezTerm の新しいタブで、[AlmaLinux 10 の初期設定の「シェルのツール」](almalinux-setup.md#シェルのツール)の手順 9・10 を貼って確かめ直す（Windows との違いは、[シェルのツールを入れる](#シェルのツールを入れる)の手順 7 の箇条書き）

---

### HackGen Console NF を上げる

- HackGen Console NF の新しい版を確かめ、必要なときに入れ直す
- 前提: [HackGen Console NF](#hackgen-console-nf)を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。削除・再導入・確認は、リンク先の項に指定した窓で行う

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. HackGen の新しい版が出ているかを確かめる。

   ```powershell
   (Invoke-RestMethod -Uri https://api.github.com/repos/yuru7/HackGen/releases/latest).tag_name
   ```

   - `v2.10.0` なら、新しい版は無い。この項の手順 3 は行わない
   - 違う版なら、[HackGen Console NF](#hackgen-console-nf)の手順 3 の `$ver` と `$sha256` を、その版の zip と、その zip から計算して確認したハッシュ値に合わせて直してから貼る

1. 新しい版にするときだけ、今の版を外してから入れ直す。

   - [ロールバックの「HackGen Console NF を消す」](extra/windows-setup.md#hackgen-console-nf-を消す)の手順 1〜3（登録を消し、サインインし直してから、ファイルを消す）を行う
   - 続けて、直した[HackGen Console NF](#hackgen-console-nf)の手順 3 を貼り、サインアウトしてサインインし直してから、[再起動の後に確かめる](#再起動の後に確かめる)の手順 5 で確かめる

---

### Git for Windows・Firefox・WezTerm を上げる

- Git for Windows・Firefox・WezTerm を、設定を残して上げる
- 前提: [Git for Windows](#git-for-windows)・[Firefox](#firefox)・[WezTerm](#wezterm)・[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)を通してある
- 実行場所: この PC のデスクトップの管理者の Windows PowerShell（5.1）。この項の手順 1 で開く。Git の設定の確認は、WezTerm の新しい Git Bash のタブ
- Claude Code の Remote Control のタスクを動かしているときは、この項で止めてから、更新後に始め直す

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開き、UAC の確認に答える

1. Remote Control のタスクを動かしているときだけ、先にタスクを止める。

   - [Claude Code の Remote Control の止める・もう一度始める](ai-agents.md#claude-code-の-remote-control-止めるもう一度始める)の手順 1 を行う
   - タスクの Claude Code と WezTerm（中のシェルは Git Bash）は、Git for Windows と WezTerm を上げる間は止めておく。上げた後に、この項の手順 8 で始め直す

1. Git Bash と WezTerm を閉じてから、winget で Git for Windows を上げる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget upgrade --exact --id Git.Git --source winget --accept-source-agreements --accept-package-agreements
   winget list --exact --id Git.Git --source winget
   ```

   - 上がったら `インストールが完了しました` と出て、`winget list` の `Git.Git` の版が新しくなる
   - 新しい版が無ければ、`利用可能なアップグレードが見つかりませんでした。`（英語の Windows では `No available upgrade found.`）と出る
   - **注意**: Git Bash・WezTerm のタブ（自分用の設定では Git Bash）や、Git の bash を使う SSH のセッション・Claude Code が動いていると、インストーラは入れ替えずに終わるはず
   - 上げた後は、WezTerm の新しい Git Bash のタブを開き、[AlmaLinux 10 の初期設定の「Git」](almalinux-setup.md#git)の手順 6 を貼り直す（`pull.ff` が `only` なら同じ項の手順 7 も）

1. Firefox の今の版と、winget に新しい版があるかを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-Item -LiteralPath "$env:ProgramFiles\Mozilla Firefox\firefox.exe").VersionInfo.ProductVersion
   winget list --exact --id Mozilla.Firefox.ja --source winget --upgrade-available
   ```

   - 1 行目が今の版
   - winget に新しい版があれば、`Mozilla.Firefox.ja` の行に今の版と新しい版が並ぶ
   - 行が出ずに、見つからない旨が出たら、新しい版は無い。この項の手順 5 は飛ばす

1. Firefox の新しい版があるときだけ、Firefox をすべて閉じてから winget で上げる。

   ```powershell
   winget upgrade --exact --id Mozilla.Firefox.ja --source winget --accept-source-agreements --accept-package-agreements
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-Item -LiteralPath "$env:ProgramFiles\Mozilla Firefox\firefox.exe").VersionInfo.ProductVersion
   ```

   - 最後の行が新しい版になればよい
   - **注意**: Firefox を開いたままだと、入れ替えが途中で終わることがある（参考資料を参照）

1. WezTerm の今の版を確かめ、WezTerm が動いていないことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{BCF6F0DA-5B9A-408D-8562-F680AE6E1EAF}_is1').DisplayVersion
   Get-Process -Name wezterm, wezterm-gui, wezterm-mux-server -ErrorAction SilentlyContinue | Format-Table Id, ProcessName
   ```

   - 1 行目に今の版が出る
   - プロセスが出たら、その WezTerm の窓をすべて閉じる

1. [WezTerm](#wezterm)の手順 4 のブロックを貼る。

   - 最後に出る `wezterm <版>` が、この項の手順 6 の版より新しければ上がった
   - 同じ版なら、main に新しいコミットが無かった（同じ版を入れ直しただけ）

1. この項の手順 2 でタスクを止めたときだけ、タスクを始め直す。

   - [Claude Code の Remote Control の止める・もう一度始める](ai-agents.md#claude-code-の-remote-control-止めるもう一度始める)の手順 2 を行う

---
