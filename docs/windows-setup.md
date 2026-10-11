# Windows 11 のセットアップ

## Windows と AlmaLinux のデュアルブート（導入前・任意）

- この節だけを実施するときは、各項の前提・実行場所・権限を先に確認する
- [検証記録](verification/windows-dual-boot.md)・[参考資料](reference/windows-dual-boot.md)・[ロールバックと注意点](extra/windows-dual-boot.md)

### Windows と AlmaLinux のデュアルブート: 実施手順

> [!IMPORTANT]
> - **入れる先のディスクの中身は、手順 5 ですべて消える**。そのディスクに Windows 11 を新しく入れ、後ろに AlmaLinux 10 用の未割り当て領域を残す
> - **インストールメディアは、Rufus で作成済みとする**。「インストーラーをカスタムしますか?」でオンにした項目は次の 7 つ（[選択した方針](reference/windows-dual-boot.md#選択した方針)）
>   - 「4GB以上のRAM、セキュアブート及びTPM 2.0の要件を削除」「オンラインアカウントの要件を削除」「ローカルアカウントを次の名前で作成:」
>   - 「地域設定をこのユーザーと同じものに設定」「データ収集を無効化」「BitLocker 自動デバイス暗号化を無効化します。」「利便性向上パッチ(Microsoftの各種ソフトウェアの無効化)」
>   - **「⚠サイレント⚠ ディスクの削除とインストール:」はオフにしてある**こと（オンだと、最初に見つかったディスクを確かめずに消して入れる）
>   - ビルド 26200 以降の ISO で出る「Windows CA 2023署名のブートローダーを使用する」「インストール時にSkuSiPolicy.p7bを適応する」もオフのまま（既定でオフ）
> - 手順 1〜3・6〜8 は、PC の画面と機器で行う。**手順 4・5 は、セットアップのコマンド プロンプトに手で 1 行ずつ打つ**（貼り付けられない）
> - 手順 9〜13 は、入れた Windows の管理者の Windows PowerShell 5.1 に **Ctrl+V で貼る**。[貼り付けの設定](#貼り付けの設定)より前に右クリックで貼ると、行が逆順になる

- 上から順に進める。手順 10・12・13 は、条件に当たるときだけ行う
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- やり直すときは、手順 3 から始める（ロールバックの節は無い）。手順 5 のパーティションが残っていれば、手順 4・5 は飛ばしてよい

- 両方の OS を入れた後、Windows から次回だけ AlmaLinux を起動したいときは、[QEFI Entry Manager を使う節](#windows-と-almalinux-のデュアルブート-次回だけ-almalinux-で起動する任意)へ進む

> [!CAUTION]
> **手順 5 の `clean` で、選んだディスクのパーティションとデータをすべて消す（取り戻せない）。** ディスクの番号は、手順 4 で大きさを見て確かめる。

1. PC の UEFI（BIOS）の設定画面で、起動の設定を確かめる。

   - 起動のモードは UEFI にする（CSM・Legacy の起動は切る）
   - Secure Boot と TPM は有効のままにする
   - Secure Boot の項目に「Microsoft 3rd Party UEFI CA」を許可する設定があれば、許可にする
   - USB からの起動を許可する
   - 設定画面の開き方（電源を入れた直後に押すキー）と項目の名前は、PC のメーカーごとに違う

1. LAN ケーブルを抜き、Wi-Fi にもつながない状態にする。

   - つなぐのは、手順 7 でデスクトップが出てから

1. Rufus の USB を挿し、PC の起動メニューから UEFI で起動して、セットアップの最初の画面まで進める。

   - 起動メニューを出すキー（F12・F11・Esc など）は PC ごとに違う。USB が 2 つ出るなら、名前が「UEFI:」で始まる方を選ぶ
   - 黒い画面に `UEFI:NTFS` の文字と `Secure Boot status: Enabled` が出てから、Windows のセットアップが始まる
   - 「言語設定を選択」の画面が出たら、まだ「次へ」を押さずに手順 4 へ進む
   - Secure Boot の違反で止まるなら、手順 1 の 3rd Party UEFI CA を見直す
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
   - 2 行目の結果が `PEFirmwareType    REG_DWORD    0x2` なら UEFI で起動している。`0x1` なら BIOS（Legacy）の起動なので、手順 1・3 からやり直す
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

   - `DISKPART>` のプロンプトに 1 行ずつ打つ。**1 行目の `0` は、手順 4 で控えたディスクの番号に直す**
   - **7 行目の `204800` は Windows のパーティションの大きさ**（単位は MB。204800 = 200 GiB）。Windows に割り当てたい大きさに直す。ディスクの残りは、AlmaLinux 用の未割り当て領域になる
   - `list partition` に 4 つのパーティション（`システム` 2048 MB・`予約済み` 16 MB・`プライマリ` Windows の大きさ・`回復` 1024 MB）が並べばよい
   - 途中で打ち間違えたら、`select disk 0`（控えた番号）から打ち直す

1. セットアップに戻り、手順 5 の「Windows」のパーティションを選んでインストールする。

   - 「言語設定を選択」→「キーボード設定を選択」→「セットアップ オプションの選択」→「プロダクト キーを入力してください」→「イメージの選択」→「適用される通知とライセンス条項」の順に進む
   - 「キーボード設定を選択」の「キーボードの種類」は、日本語のキーボードなら「日本語キーボード (106/109 キー)」にする
   - 「セットアップ オプションの選択」では「Windows 11 のインストール」を選び、「ファイル、アプリ、設定など、すべてが削除されることに同意します」に印を付ける
   - プロダクト キーが無ければ「プロダクト キーがありません」を押し、「イメージの選択」でエディション（Windows 11 Pro など）を選ぶ
   - **「Windows 11 をインストールする場所の選択」では、手順 5 で作った Windows の大きさのパーティション（`ディスク 0 パーティション 3: Windows` のように、手順 4 で控えたディスクのパーティション 3）を選び、「次へ」を押す**
   - この画面では「パーティションの削除」を押さず、「未割り当て領域」も選ばない
   - 「インストール準備完了」の画面で「インストール」を押す。途中で何度か再起動する
   - 最初の再起動のときに USB を抜く
   - **注意**: 「適用される通知とライセンス条項」の画面には「戻る」が無い。Esc を押すと「本当に終了しますか?」が出て、「はい」で PC が再起動する（手順 3 からやり直す）

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
   - `reagentc /info` の Windows RE の状態が `Enabled` で、場所が `…\partition4\Recovery\WindowsRE`（回復パーティション）なら、手順 10 は飛ばす
   - 場所が `partition3`（C:）か空なら、手順 10 で回復パーティションへ移す

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

   - `HiberbootEnabled : 0` なら高速スタートアップは切れている。`1` なら、手順 12 で切る。`0` なら手順 12 は飛ばす
   - `VolumeStatus : FullyDecrypted` と `ProtectionStatus : Off` なら、BitLocker は使われていない。暗号化されていたら[注意点](extra/windows-dual-boot.md#注意点)
   - `Id : Tokyo Standard Time` なら、手順 13 は飛ばす。違えば、手順 13 で直す
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

---

### Windows と AlmaLinux のデュアルブート: 次回だけ AlmaLinux で起動する（任意）

> [!IMPORTANT]
> - Windows 11 から操作する。AlmaLinux を導入済みで、PC の起動メニューから AlmaLinux のエントリを選んで起動できることが前提
> - QEFI Entry Manager と PowerShell は管理者として起動する。PowerShell のブロックは Ctrl+V で貼る
> - この節では、次回だけの起動先（`BootNext`）を指定する。通常の起動順（`BootOrder`）や GRUB の既定の選択は変更しない

- 初回はこの項の手順 1 から行う。展開済みなら、この項の手順 5 から行う（管理者の Windows PowerShell を開いておく）
- 同梱 CLI に表示の不具合があるため、Windows 標準の BCDEdit も使って確認する（この節の[検証記録](verification/windows-dual-boot.md)・[参考資料](reference/windows-dual-boot.md)）
- 再起動前に取り消すときは、[次回起動の指定を取り消す](#windows-と-almalinux-のデュアルブート-次回起動の指定を取り消す任意)へ進む。QEFI Entry Manager を閉じるだけでは取り消せない

1. Windows のブラウザで、公式の Windows 向け ZIP をダウンロードする。

   - [公式リリース v0.5.0](https://github.com/Inokinoki/QEFIEntryManager/releases/tag/v0.5.0) の Assets から `QEFI.Entry.Manager.for.Windows.Qt6.8.3.zip` を選ぶ
   - 「ダウンロード」フォルダーに、この名前で保存する（末尾に `(1)` などが付いたら、既存のファイルと区別してからこの名前にする）

1. 管理者の Windows PowerShell（5.1）を開く。

   - [手順 8](#windows-と-almalinux-のデュアルブート-実施手順)と同じように、スタートメニューから「管理者として実行する」で開く
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
   - どれかが一致しない・予約が出ない・エラーが出た場合は、再起動せず中断する。自分が設定した予約だけを[取り消す節](#windows-と-almalinux-のデュアルブート-次回起動の指定を取り消す任意)で解除する

1. Windows で作業を保存して、再起動する。

   - 未保存の作業を保存し、スタートメニューの電源から「再起動」を選ぶ
   - AlmaLinux の GRUB のメニューが出たら、AlmaLinux の項目を選ぶ

1. AlmaLinux の画面で、起動できたことを確かめる。

   - AlmaLinux のログイン画面からログインし、デスクトップが出ることを確かめる

---

### Windows と AlmaLinux のデュアルブート: 次回起動の指定を取り消す（任意）

- QEFI Entry Manager で指定した後、まだ再起動していないときに行う。展開先は[次回だけ起動する節](#windows-と-almalinux-のデュアルブート-次回だけ-almalinux-で起動する任意)と同じで、管理者の Windows PowerShell（5.1）に貼る
- 解除するのは次回だけの予約。AlmaLinux のエントリ自体は消さず、通常の起動順も変えない

1. BCDEdit で、取り消す予約を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & "$env:SystemRoot\System32\bcdedit.exe" /enum firmware
   if ($LASTEXITCODE -ne 0) { throw '中断: BCDEdit の一覧を取得できませんでした。' }
   ```

   - `{fwbootmgr}` の `bootsequence` が自分の指定したエントリの識別子であることを確かめる。別の対象や不明な対象なら中断する
   - `{fwbootmgr}` に `bootsequence` が無ければ、この項の手順 2 は飛ばす

1. 自分が指定した予約が残っているときだけ、解除する。

   ```powershell
   & "$env:LOCALAPPDATA\Programs\QEFIEntryManager\qefibootmgr.exe" -N
   if ($LASTEXITCODE -ne 0) { throw '中断: 次回起動の指定を解除できませんでした。' }
   ```

   - オプションは大文字の `-N`。`-B`（エントリ削除）や `-O`（起動順削除）は使わない
   - `BootNext deleted` が出ても成功と決めず、この項の手順 3 で確認する

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

## 実施手順

- [検証記録](verification/windows-setup.md)・[参考資料](reference/windows-setup.md)・[ロールバックと注意点](extra/windows-setup.md)

> [!IMPORTANT]
> - **この PC のデスクトップで、Administrators のユーザーが行う**。SSH のセッションには貼らない
> - PowerShell のブロックは **Windows PowerShell 5.1** に貼る。管理者・通常（管理者ではない）の窓は、窓を開く手順に従って切り替える
>   - 管理者: [Windows Update](#windows-update)、[PC 全体の設定](#pc-全体の設定)から[WSL と再起動](#wsl-と再起動)まで
>   - 通常: [Microsoft Store の更新](#microsoft-store-の更新)から[HackGen Console NF](#hackgen-console-nf)まで、再起動後の PowerShell の手順
> - bash の貼り先は次の 3 段階
>   - [SSH でログインを確かめる](#ssh-でログインを確かめる): クライアントの bash（この PC の WSL の AlmaLinux 10 など）
>   - [Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定): 同じ項の手順 2 で開く Git Bash の窓
>   - それより後: 設定を入れた WezTerm の新しい Git Bash のタブ
> - 前提: AI エージェントと GitHub のアカウント（[AlmaLinux 10 の初期設定](almalinux-setup.md#実施手順)のリードと同じ）
> - [貼り付けの設定](#貼り付けの設定)より前は **Ctrl+V で貼る**。設定後は GitHub のコピーボタンでコピーし、右クリックで貼れる
> - [WSL と再起動](#wsl-と再起動)の手順 2 で **再起動する**。Windows Update の再起動は[Windows Update](#windows-update)に従う

- 上から順にコードブロックを貼る。[PC 全体の設定](#pc-全体の設定)の手順 2 の変数は、管理者の PowerShell を開き直したら貼り直す（[OpenSSH サーバー](#openssh-サーバー)の手順 3・5 も使う）
  - [SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 3・[yazi](#yazi)の手順 1・[Claude Code](#claude-code)の手順 1 の変数も、その項の中で新しいシェルや窓を開いたら貼り直す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- GitHub のコピーボタンでコピーしたブロックは末尾に改行が無いので、貼った後に Enter を押す
- 使わない項目は飛ばしてよい。ただし、次の準備は省かない
  - [Microsoft Store の更新](#microsoft-store-の更新)の手順 1、[貼り付けの設定](#貼り付けの設定)の手順 1〜4、[PC 全体の設定](#pc-全体の設定)の手順 1〜3
  - [Git for Windows](#git-for-windows)・[Firefox](#firefox)・[WezTerm](#wezterm)・[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)、[WSL と再起動](#wsl-と再起動)の手順 2、[シェルのツールを入れる](#シェルのツールを入れる)の手順 1・3・4
- デュアルブート向けに入れるなら、先に[Windows 11 の導入](#windows-と-almalinux-のデュアルブート-実施手順)を通す
- 初期設定後は、必要な任意節を選び、以後は[更新](#更新)・[ロールバック](extra/windows-setup.md#ロールバック)を使う
- 後続の手順: [VirtualBox](#virtualbox-windows-11-で使う) → [WireGuard](#wireguard-windows-11-で使う)。その他のツールは [README](../README.md) から選ぶ
- 両 OS 共通の使い方・設定は[AlmaLinux 10 の初期設定](almalinux-setup.md)の後ろの節を参照し、Git Bash に貼る
  - [fzf の任意節](almalinux-setup.md#fzf-で-fd-と-bat-を候補とプレビューに使う任意)の `brew install fd`・`brew uninstall fd` は、通常の PowerShell で `scoop install fd`・`scoop uninstall fd` にする。導入済みなら省く
  - bat の設定は[シェルのツールを入れる](#シェルのツールを入れる)の手順 5 を使う
- CRLF に変換して clone 済みのリポジトリは、Git Bash で[改行を変換して clone したリポジトリを直す](almalinux-setup.md#改行を変換して-clone-したリポジトリを直す)を通す
- SSH で scoop のツールを使うなら、導入・更新後に[scoop のツールを SSH のセッションで使う](#scoop-のツールを-ssh-のセッションで使う任意)の手順 1 を管理者の窓に貼る

> [!WARNING]
> - ロックを止め、自動サインイン・インラインの sudo を有効にすると、**PC に触れる人が管理者として操作できる**
> - Hello 以外のサインインと SSH・RDP も有効にすると、**パスワードを知る人も管理者として操作できる**（SSH は LAN から）
> - 人が触れる場所では、[PC 全体の設定](#pc-全体の設定)の手順 7 と[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 5 は行わない

### Windows Update

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
       throw '中断: 「Windows Update」の手順 1 で管理者の Windows PowerShell を開く'
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
       throw '中断: 再起動が必要。「Windows Update」の手順 8 を行ってから検索し直す'
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
       throw '中断: 再起動が必要。「Windows Update」の手順 8 を行ってから検索し直す'
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
       throw '中断: 再起動が必要。「Windows Update」の手順 8 を行ってから検索し直す'
     }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     '残っている対象の更新: {0} 件' -f $updates.Count
     $updates | Format-Table KB, Size, Title -AutoSize
     if ($updates.Count -gt 0) {
       Write-Warning '更新が残っている。「Windows Update」の手順 5 から繰り返す'
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

### Microsoft Store の更新

1. Windows のデスクトップで、管理者ではない Windows PowerShell（5.1）を開く。

   - [Windows Update](#windows-update)の手順 1 の管理者の窓を閉じる
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
       throw '中断: 「Microsoft Store の更新」の手順 1 で管理者ではない窓を開く'
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
       throw '中断: Store CLI が無い。「Microsoft Store の更新」の手順 4 で準備してから再確認する'
     }
     $help = store.exe updates --help
     if ($LASTEXITCODE -ne 0 -or ($help -join "`n") -notmatch '--apply\b') {
       throw '中断: Store CLI の一括更新を確認できない。「Microsoft Store の更新」の手順 4 の後も同じなら進まない'
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

### 貼り付けの設定

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

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`7.…` か `True` なら、窓を閉じて[Microsoft Store の更新](#microsoft-store-の更新)の手順 1 から
   - `Winget` に `…\WindowsApps\winget.exe` の場所が出ればよい。空なら、[Microsoft Store の更新](#microsoft-store-の更新)の手順 2〜7 でアプリ インストーラーの登録と更新を確かめてから
   - `ScancodeMap` が空でなければ控える。[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 4 は、別の割り当てがあれば止まる
   - `CurrentUser` の値（未設定なら `Undefined`）を控え、[ロールバック](extra/windows-setup.md#アプリと貼り付けの設定を外す)の手順 7 で使う
   - `Scoop` に場所が出たら、scoop はもう入っている。[アプリを入れる](#アプリを入れる)の手順 1・2 は飛ばす

1. スクリプトの実行ポリシーを RemoteSigned にする。

   ```powershell
   if ((Get-ExecutionPolicy) -notin 'RemoteSigned', 'Unrestricted', 'Bypass') { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ExecutionPolicy
   ```

   - `RemoteSigned`（もとから `Unrestricted` か `Bypass` だった PC では、その値）が出ればよい
   - 上書きのエラーが出て別の値になる PC では、scoop とこの項の手順 4 のプロファイルは使えない。ほかの手順書は Ctrl+V で貼る

1. プロファイルに、この項の手順 1 と同じ 1 行を足す。

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

### アプリを入れる

1. scoop を入れる。

   ```powershell
   Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
   ```

   - 最後に `Scoop was installed successfully!` が出ればよい
   - `Running the installer as administrator is disabled by default` が出たら、管理者の PowerShell に貼っている。閉じて[Microsoft Store の更新](#microsoft-store-の更新)の手順 1 から
   - `Scoop is already installed` が出たら、もう入っている（何も変えずに終わる）。この項の手順 2 へ進む
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

### 表示と入力

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
   - 開いているエクスプローラーの窓には、開き直すか[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後に効く

1. 自分のユーザーで、旧形式のコンテキストメニューを出すようにする。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   reg.exe add 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' /f /ve
   reg.exe query 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' /ve
   ```

   - `reg.exe add` が成功の 1 行を出し、`reg.exe query` に `(既定)`（英語の表示では `(Default)`）と `REG_SZ` の行が出ればよい（値は空）
   - エクスプローラーに効くのは、[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後

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
   - [自動起動と標準アプリ](#自動起動と標準アプリ)の手順 2 より前に貼る

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
   - タスクバーには、すぐか、[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後に効く

1. ダークモードにする。

   ```powershell
   $p = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
   Set-ItemProperty -Path $p -Name AppsUseLightTheme -Type DWord -Value 0
   Set-ItemProperty -Path $p -Name SystemUsesLightTheme -Type DWord -Value 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $p | Format-List AppsUseLightTheme, SystemUsesLightTheme
   ```

   - `AppsUseLightTheme : 0` と `SystemUsesLightTheme : 0` が出ればよい
   - 動いているアプリとタスクバーには、[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後に効く

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
   - **注意**: 管理者の PowerShell は conhost で開く。右クリックで貼るには[貼り付けの設定](#貼り付けの設定)の手順 1〜4 が必要

1. Microsoft IME の設定を開き、Ctrl+Space で IME をオン・オフするようにする。

   ```powershell
   Start-Process 'ms-settings:regionlanguage-jpnime'
   ```

   - 設定の Microsoft IME の画面が開く。「キーとタッチのカスタマイズ」を開き、「キーの割り当て」をオンにして、「Ctrl + Space」を「IME-オン/オフ」にする
   - 「以前のバージョンの Microsoft IME を使う」がオンだと、この項目は出ない
   - 効くのは、次に IME を使う窓から（確かめるのは[再起動の後に確かめる](#再起動の後に確かめる)の手順 1）
   - **次の手順は、設定を閉じてから PowerShell に貼る**

### 自動起動と標準アプリ

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
   - タスクバーのウィジェットのボタンと、設定のウィジェットの切り替えが消える（[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後に確かめる）

### HackGen Console NF

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
   - アプリで使えるのは、[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後（確かめるのは[再起動の後に確かめる](#再起動の後に確かめる)の手順 5）

### PC 全体の設定

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く。UAC の確認が出たら「はい」
   - [Microsoft Store の更新](#microsoft-store-の更新)の手順 1 の PowerShell は閉じてよい（再起動の後は、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1 で開き直す）
   - 開いたときに、プロファイルを読めないという赤い字のエラーが出たら、実行ポリシーが `Restricted` のまま。[貼り付けの設定](#貼り付けの設定)の手順 3 を、この窓で貼り直す

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
   - `CtrlEnter : InsertLineAbove` なら、[貼り付けの設定](#貼り付けの設定)の手順 1・3・4 をこの順で貼り直し、窓を開き直してこの項の手順 2 から
   - 次の値を控える（[ロールバック](extra/windows-setup.md#ロールバック)で、元に戻すかを決めるのに使う）
     - `ComputerName`（PC の名前。ロールバックの「ネットワークと PC 全体の設定を戻す」の手順 9）と `LanCategory`（LAN の種類。ロールバックの「ネットワークと PC 全体の設定を戻す」の手順 5）
     - `RemoteDesktop`（1 なら無効、0 ならもう有効。ロールバックの「ネットワークと PC 全体の設定を戻す」の手順 4）と `RemoteAssistance`（1 なら有効、0 なら無効。ロールバックの「ネットワークと PC 全体の設定を戻す」の手順 3）
     - `HelloOnly`（2 ならオン、0 ならオフ。ロールバックの「サインイン・検索・キーボードを戻す」の手順 5）と `Keyboard`（`kbd106.dll` なら JIS 配列。ロールバックの「サインイン・検索・キーボードを戻す」の手順 9）
     - 最後の行の配信の最適化のモード（`Lan` が Windows の既定。ロールバックの「ネットワークと PC 全体の設定を戻す」の手順 1）
   - `Edition` が `Core` で始まる（Home）なら、[ネットワークとリモート](#ネットワークとリモート)の手順 2 は飛ばす

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
     Write-Error '中断: 「PC 全体の設定」の手順 2 の $PC_NAME が空'
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
   - 効くのは、[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後
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
     Write-Error '「PC 全体の設定」の手順 2 の $LAN_IF が空'
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
   - 効くのは、[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後

### ネットワークとリモート

1. LAN の接続をプライベートにする。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error '「PC 全体の設定」の手順 2 の $LAN_IF が空'
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
   - [PC 全体の設定](#pc-全体の設定)の手順 3 の `Edition` が `Core` で始まる（Home）なら、この手順は飛ばす（貼っても `中断:` で止まる）

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

### OpenSSH サーバー

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
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not $LAN_IF) {
     Write-Error '「PC 全体の設定」の手順 2 の $LAN_IF が空'
   } elseif ((Get-NetConnectionProfile -InterfaceAlias $LAN_IF).NetworkCategory -ne 'Private') {
     Write-Error '中断: LAN の接続がプライベートではない（「ネットワークとリモート」の手順 1 でプライベートにする）'
   } else {
     Get-NetConnectionProfile -InterfaceAlias $LAN_IF | Format-Table InterfaceAlias, NetworkCategory
     Get-NetFirewallRule -Name OpenSSH-Server-In-TCP | Format-Table Name, Enabled, Profile, Direction, Action
   }
   ```

   - `<LAN_IF>  Private` と、`OpenSSH-Server-In-TCP  True  Private  Inbound  Allow` が出ればよい
   - `中断:` が出たら、[ネットワークとリモート](#ネットワークとリモート)の手順 1 でプライベートにして貼り直す。変数はそのまま使える
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
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   '{0}@{1}' -f $env:USERNAME, (Get-NetIPAddress -InterfaceAlias $LAN_IF -AddressFamily IPv4).IPAddress
   & "$env:WINDIR\System32\OpenSSH\ssh-keygen.exe" -lf "$env:ProgramData\ssh\ssh_host_ed25519_key.pub"
   ```

   - 1 行目の `<WIN_USER>@<WIN_HOST>` を控える（再起動の後の[SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 3 で使う）
   - 2 行目の `256 SHA256:<指紋> system@<HOSTNAME> (ED25519)` も控え、[SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 4 の初回の接続で照合する

### サインイン・検索・キーボード

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
   - 効くのは、[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後

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
   - 効くのは、[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後

1. AlmaLinux とデュアル ブートし、AlmaLinux の時計を UTC にしているときだけ、Windows も UTC にする。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -Name RealTimeIsUniversal -Type DWord -Value 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' | Format-List RealTimeIsUniversal
   ```

   - `RealTimeIsUniversal : 1` が出ればよい
   - 効くのは、[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後。時刻がずれていたら、設定の「時刻と言語」→「日付と時刻」の「今すぐ同期」で合わせ直す
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
   - 効くのは、[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後。日本語の入力の切り替えは、[表示と入力](#表示と入力)の手順 7 の Ctrl+Space（または Alt+`）で行う

### Git for Windows

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
   - `True` なら、Git for Windows はもう `C:\Program Files\Git` に入っている。この項の手順 2 は飛ばす（新しい版にするなら[Git for Windows・Firefox・WezTerm を上げる](#git-for-windowsfirefoxwezterm-を上げる)の手順 2）

1. まだ入っていなければ、winget で Git for Windows を PC 全体（`C:\Program Files\Git`）に入れる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget install --exact --id Git.Git --source winget --scope machine --accept-source-agreements --accept-package-agreements
   winget list --exact --id Git.Git --source winget
   ```

   - `インストールが完了しました`（英語の Windows では `Successfully installed`）と出て、`winget list` に `Git.Git` の行が出ればよい
   - インストーラの画面は出ない（進み具合の小さな窓が出て、終わると消える）
   - この窓では `git` は見つからない。再起動後、[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 1 で確かめる

### Firefox

1. Firefox がまだ入っていないことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   $arp = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
   Get-ItemProperty -Path $arp -ErrorAction SilentlyContinue | Where-Object DisplayName -like 'Mozilla Firefox*' | Format-Table DisplayName, DisplayVersion, InstallLocation
   Get-AppxPackage -Name 'Mozilla.MozillaFirefox' | Format-Table Name, Version
   ```

   - どちらも何も出なければ、入っていない
   - `Mozilla Firefox (x64 ja)` が `C:\Program Files\Mozilla Firefox` にあれば、この項の手順 2 をそのまま貼ってよい
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
   - 最初の起動で、Firefox を既定のブラウザーにするかを聞かれることがある。選ぶと Windows の設定が開くので、この項の手順 4 の操作をそこで行ってよい
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

### WezTerm

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

   - `Admin : True` であること（`False` なら、[PC 全体の設定](#pc-全体の設定)の手順 1 で管理者の窓を開き直し、同じ項の手順 2 を貼り直してから、このブロックを貼る）
   - 初めて入れる PC では、`Version`・`Location`・`OnPath`・`Running` が空
   - `Version` に版が出たら、もう入っている（`20260905-153129-092dcf70` など）。この項の手順 3 で今の nightly に上書きする
     - `Location` は `C:\Program Files\WezTerm\` のはず。違う場所なら、インストーラはそこに上書きするので、先に[ロールバックの「OpenSSH・Git for Windows・Firefox・WezTerm を外す」](extra/windows-setup.md#opensshgit-for-windowsfirefoxwezterm-を外す)の手順 8 で外す
   - `OnPath` に `C:\Program Files\WezTerm\wezterm.exe` 以外（scoop の `shims` など）が出たら、ほかの方法で入れた WezTerm がある。外してから始める
   - `Running` に名前が出たら、その WezTerm の窓を閉じる（[Claude Code の Remote Control（Windows）](#claude-code-の-remote-control-実施手順)のタスクは、同書の[止める・もう一度始める](#claude-code-の-remote-control-止めるもう一度始める)の手順 1 で止める）
   - `VCRuntime : True` なら、この項の手順 2 は飛ばす。`False` なら、この項の手順 2 で入れる

1. `VCRUNTIME140.dll` が無いときだけ、Visual C++ の再頒布可能パッケージを入れる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget install --exact --id Microsoft.VCRedist.2015+.x64 --source winget --scope machine --accept-source-agreements --accept-package-agreements
   Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
   ```

   - `インストールが完了しました`（英語の Windows では `Successfully installed`）と、`True` が出ればよい
   - ここでは再起動しない。最後が `True` ならこの項の手順 3 へ進み、[WSL と再起動](#wsl-と再起動)の手順 2 で再起動する
   - 最後の行が `False` なら、この項の残りは、再起動の後（[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)より前）に管理者の窓（[PC 全体の設定](#pc-全体の設定)の手順 1 と同じ）を開いて、この項の手順 1 から行う
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
     if (-not (Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll")) { Write-Error '中断: VCRUNTIME140.dll が無い（「WezTerm」の手順 2）'; return }
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
   - 窓が開き、中でシェルが動けばよい。設定ファイルが無ければ `cmd.exe` が開く（自分用の設定では Git Bash。[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 5 で入れる）
   - 窓の中で `wezterm --version` を打つと、この項の手順 4 と同じ版が出る
   - キー操作だけ動かない場合は、[ホットキーを使用しているアプリの調査](#windows-のホットキー競合-実施手順)で対象キーを調べる
   - 窓が開かずに終わったら、`%USERPROFILE%\.local\share\wezterm\wezterm-gui.exe-log-<番号>.txt` を見る
     - `The OpenGL implementation is too old to work with glium` なら、3D の描画の無い VM などで OpenGL が使えない
     - その場で開くなら、Win+R の「ファイル名を指定して実行」に `"C:\Program Files\WezTerm\wezterm-gui.exe" --config prefer_egl=true` を入れて開く（管理者の窓からは起動しない）
     - いつも開くようにするなら、設定の `config` に `config.prefer_egl = true` を足す。設定ファイルが無ければ、`%USERPROFILE%\.wezterm.lua` に `local wezterm = require 'wezterm'`・`local config = wezterm.config_builder()`・`config.prefer_egl = true`・`return config` の 4 行を書く
     - 自分用の設定（`~/.config/wezterm`）を使うなら、`~/.wezterm.lua` は作らない（[AlmaLinux 10 の初期設定の「WezTerm の設定ファイル」](almalinux-setup.md#wezterm-の設定ファイル)のとおり、clone した設定が読まれなくなる）
   - **注意**: 管理者の PowerShell から `wezterm-gui.exe` を起動しない（WezTerm と中のシェルが管理者で動く）

### WSL と再起動

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

### 再起動の後に確かめる

1. キーボードで、Caps Lock・Ctrl+Space・配列を確かめる。

   - メモ帳を開いて何か打ち、Caps Lock を押したまま A を押すと、全部が選ばれる（Ctrl+A）
   - Caps Lock だけを押しても、Caps Lock のランプは点かず、大文字にもならない
   - 日本語の配列（JIS）のキーボードでは、「英数」（Caps Lock）のキーが Ctrl になる
   - Ctrl+Space を押すたびに、IME のオンとオフが入れ替わる（タスクバーの「あ」と「A」）
   - [サインイン・検索・キーボード](#サインイン検索キーボード)の手順 6 を行ったなら、記号が US 配列の位置で出る（Shift+2 で `@`）

1. エクスプローラー・タスクバー・スタートが変わったことを確かめる。

   - ファイルかデスクトップを右クリックすると、「その他のオプションを確認」を選ばなくても、「送る」「プロパティ」などの並ぶ旧形式のメニューが出る
   - エクスプローラーを開くと「PC」が出て、ファイル名に拡張子が付き、隠しファイルも見える
   - タスクバーのアイコンが左に寄り、タスク ビュー・検索・ウィジェットのボタンが無く、時計に秒が出る。全体が濃い色になっている
   - スタートを開いて文字を打っても、Web（Bing）の結果が出ない（[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 2）
   - デスクトップに Edge と UniGet UI のショートカットが無い

1. タスクバーとスタートの、要らないピン留めを外す。

   - タスクバーのアイコン（Microsoft Edge・Microsoft Store など）を右クリックし、「タスクバーからピン留めを外す」
   - スタートを開き、ピン留めされたアプリを右クリックし、「スタートからピン留めを外す」
   - Copilot は外さない。使うアプリは残す

1. スタートメニューから UniGet UI を起動し、WinGet と Scoop が使えることを確かめる。

   - スタートメニューで「UniGetUI」を探して開く
   - 初回は、使い方の案内や設定の問いが出ることがある。読んで進める
   - 左の「パッケージマネージャー」で、WinGet と Scoop が有効で「利用可能」になっていることを確かめる（版は、それぞれの「バージョンを表示」で出る）
   - 「インストール済みのパッケージ」に、[アプリを入れる](#アプリを入れる)の手順 3 で scoop で入れた `scoop-search` と、winget の `UniGetUI` などが出る

1. 設定のフォントの一覧で、HackGen Console NF が出ることを確かめる。

   - 設定 → 個人用設定 → フォント を開き、「HackGen」で探すと、`HackGen Console NF` と `HackGen35 Console NF` が出る（どちらも「2 フォント フェイス」）
   - ライセンス認証していない Windows では、フォントの画面の検索欄が使えないことがある。そのときは一覧をスクロールして探す
   - メモ帳のフォントの一覧に出ても同じ
   - 端末のフォントにするなら、アプリの設定にファミリー名 `HackGen Console NF` を書く（WezTerm は `config.font = wezterm.font 'HackGen Console NF'`。自分用の設定（`ryo-aoki-pc/wezterm`）は、もうこのフォントを使う）

### WSL の AlmaLinux 10 と自動サインイン

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
     - `ComputerName` が[PC 全体の設定](#pc-全体の設定)の手順 2 の `PC_NAME`（大文字）、`CtrlEnter : AddLine`、`ScancodeMap : 00 00 00 00 00 00 00 00 02 00 00 00 1D 00 3A 00 00 00 00 00`
     - `Keyboard` は、[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 6 を行ったなら `kbd101.dll`
     - `LongPaths : 1`・`DeveloperMode : 1`・`Sudo : 3`・`Hibernate : 0`
     - `RemoteDesktop : 0`（[ネットワークとリモート](#ネットワークとリモート)の手順 2 を行ったとき）・`LanCategory : Private`
     - `Hypervisor : True`

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

### SSH でログインを確かめる

1. クライアントのシェルを開く（この PC の WSL の AlmaLinux 10 を使うなら、そのシェルに入る）。

   ```powershell
   wsl.exe --distribution AlmaLinux-10 --cd ~
   ```

   - [WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1 の PowerShell に貼る。`[<ユーザー>@<HOSTNAME> ~]$` のプロンプトになればよい
   - ほかの PC（AlmaLinux 10 など）をクライアントにするなら、その PC の自分のユーザーの端末を開き、このブロックは貼らない
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
   WIN_HOST=                             # ← 「OpenSSH サーバー」の手順 5 で控えた @ の後ろ（Windows の IP アドレス）を書く。<WIN_HOST>
   ```

   ```bash
   WIN_USER=${USER}                      # Windows のユーザー名。「OpenSSH サーバー」の手順 5 の @ の前と違えば直す。<WIN_USER>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in WIN_HOST WIN_USER; do
     printf '%-8s = %s\n' "$v" "${!v}"
   done
   ```

   - 最後に値を読み戻して確かめる
   - **新しいシェルを開いたら**、この項の手順 3 の 2 つのブロックを貼り直してから先へ進む（任意節の[OpenSSH サーバーに公開鍵でもログインする（任意）](#openssh-サーバーに公開鍵でもログインする任意)などでも使う）

1. クライアントのシェルで、ホスト鍵を照合し、パスワードでログインする。

   ```bash
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: 「SSH でログインを確かめる」の手順 3 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh -o PubkeyAuthentication=no "${WIN_USER}@${WIN_HOST}"
   fi
   ```

   - 初回は `ED25519 key fingerprint is SHA256:…` と `Are you sure you want to continue connecting (yes/no/[fingerprint])?` が出る。[OpenSSH サーバー](#openssh-サーバー)の手順 5 で控えた指紋と同じなら `yes`
   - `<WIN_USER>@<WIN_HOST>'s password:` で、Windows のユーザーのパスワードを入れる（Microsoft アカウントなら、そのアカウントのパスワード。PIN ではない）
   - `<WIN_USER>@<HOSTNAME> C:\Users\<WIN_USER>>` の cmd のプロンプトが出ればよい。`whoami` で `<hostname>\<win_user>`（小文字）が出る
     - [SSH の既定のシェルを Git Bash にする（任意）](#ssh-の既定のシェルを-git-bash-にする任意)の後は、`<WIN_USER>@<HOSTNAME> MINGW64 ~` のプロンプトになり、`whoami`（Git のもの）は `<WIN_USER>` だけを出す
   - `exit` でクライアントのシェルに戻る
   - **注意**: パスワードを続けて間違えると、Windows のロックアウトのポリシーでアカウントがロックされる（[注意点](extra/windows-setup.md#注意点)）
   - WSL の AlmaLinux 10 をクライアントにしたときは、続けてもう一度 `exit` を打ち、PowerShell に戻る
   - **次の手順は、`exit` で PowerShell に戻ってから貼る**（続けて貼ると Windows の cmd への入力として食われる）

### Git Bash と WezTerm の設定

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
   - **この手順は、この項の手順 4・5 の clone より前に行う**（`global` の `core.autocrlf=false` が無いと、clone したファイルの改行が `system` の `core.autocrlf=true` で CRLF になる）
   - Git Bash・PowerShell・cmd の git は、同じ `~/.gitconfig` を読む
   - 戻すときは、[ロールバックの「Git Bash の設定を戻す」](extra/windows-setup.md#git-bash-の設定を戻す)で行う（同書の「Git」の手順 2 の箇条書きが案内する AlmaLinux 10 のロールバックと同じ内容を、Git Bash で行う）

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

   - [WezTerm の設定を導入する](#wezterm-の設定を導入する)を通す。前提の共通の bash 設定は、この項の手順 4 で導入済み
   - その項の手順 5 で WezTerm を起動し、手順 6 を新しい Git Bash のタブに貼って確かめる
   - Git Bash の窓は閉じてよい。この後の bash のブロックは、WezTerm のタブに貼る
   - **次の手順は、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1で開いた PowerShell に貼る**

### シェルのツールを入れる

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

   - `PowerShell : 5.1.…`・`Admin : False`・`BashConfig : True`・`VCRuntime : True` ならよい。`Admin : True` なら、窓を閉じて、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1 のとおりに開き直す
   - `Scoop` が空なら、先に[アプリを入れる](#アプリを入れる)の手順 1・2 を通す
   - `Git` が `C:\Program Files\Git\cmd\git.exe` でなければ、先に [Git for Windows](#git-for-windows)を通す
   - `BashConfig : False` なら、先に[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 4 を通す
   - `VCRuntime : False` なら、[WezTerm](#wezterm)の手順 2 を管理者の窓で行ってから、このブロックを貼り直す
   - `C:\Users\<WIN_USER>\scoop\` の下の `shims\<名前>.exe` と `apps\starship\current\starship.exe` だけなら、scoop で入れたもの（この項の手順 3 は、入っているものを飛ばす）
   - ほかの場所（winget の `…\WinGet\Links\` など）が出たら、ほかの方法で入れたものがある。その方法で外してから始める
   - `Zoxide` が空か `zoxide 0.9.9` なら、この項の手順 2 は飛ばす

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
   - **zoxide は 0.9.9 に固定する**。0.10.0 は Git Bash の移動を記録しない。修正版は[更新](#scoopwingetwsl-を上げる)の手順 6・7、ほかのツールは同じ項の手順 1・2 で上げる

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
   - `bat --version` が何も出さないか、DLL が見つからない旨のエラーになったら、VC++ ランタイムが無い（この項の手順 1 の `VCRuntime`）
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
     if (-not $f) { Write-Error '中断: BAT_CONFIG_DIR が無い。「シェルのツールを入れる」の手順 3 で bat を入れたかを確かめる'; return }
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
     - `command -v` は `/c/Users/<WIN_USER>/scoop/shims/<名前>`（starship は `/c/Users/<WIN_USER>/scoop/apps/starship/current/starship`）。版は、この項の手順 4 と同じ
     - 同書の「シェルのツール」の手順 5 の `bind -X` は、`"\C-r" "__fzf_history__"` のようにコロンの無い形で出る（Git Bash の bash 5.3）。WezTerm のシェル統合を読んでいれば、マウス報告よけの行も出る（そのままでよい）
     - 同書の「シェルのツール」の手順 6 の見出しは、`Permissions` が `Mode` になり、`User` の列が無い。`Git` の列が出ればよい。`ll` は、Git for Windows の `ls -l` ではなく eza になる
     - 同書の「シェルのツール」の手順 7 で `/etc/os-release` が無い旨のエラーが出たら、そのコマンドを `~/.bashrc` に変えて打つ。`MANPAGER` は `bat -plman` と出るが、Git Bash に `man` は無い
     - 同書の「シェルのツール」の手順 9 の `cd /usr/share` は、Git for Windows の `C:\Program Files\Git\usr\share` に移る。同書の「シェルのツール」の手順 10 の一覧には、その形（`C:\…`）で出る
   - 同書の「シェルのツール」の手順 8（tmux）は行わない
   - `~/.bashrc` には追記しない。Windows PowerShell 5.1 には読み込まない

1. 同じタブで、[同書の「キー操作を試す」の手順 2〜5](almalinux-setup.md#キー操作を試す)のキーを押して、fzf を確かめる。

   - 同書の「キー操作を試す」の手順 2 の `fzf --version` は、この項の手順 6 で Git Bash の履歴に入っている
   - 同書の「キー操作を試す」の手順 3 をホーム（`C:\Users\<WIN_USER>`）で行うと、`AppData` の下のファイルも一覧に入る
   - 同書の「キー操作を試す」の手順 4 の `doc/bash` が一覧に無ければ、一覧にある別の語で絞る（`/usr/share` は Git for Windows のもの）
   - 日本語など ASCII 以外の文字では、絞り込めないことがある（Windows の fzf は、画面の一部に開いた一覧では ASCII 以外の文字を読めない）
   - **次の手順は、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1で開いた PowerShell に貼る**

### git-delta

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

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`Admin : True` なら、窓を閉じて、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1 のとおりに開き直す
   - `Scoop` に `C:\Users\<WIN_USER>\scoop\shims\scoop.ps1` が出ればよい。空なら、先に[アプリを入れる](#アプリを入れる)の手順 1・2 で入れる
   - `Git` が `C:\Program Files\Git\cmd\git.exe` でなければ、先に [Git for Windows](#git-for-windows)
   - `VCRuntime : True` ならよい。`False` なら、先に [WezTerm](#wezterm)の手順 2 を管理者の Windows PowerShell で行い、この窓でこのブロックを貼り直す
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
   - `delta 0.20.1` の形で、入れた版が出ればよい。版が出なければ、この項の手順 1 の `VCRuntime` を確かめる
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
   - 素の差分（背景色の無い `+` / `-` の行）が出たら、この項の手順 3 で貼った同書の「git-delta」の手順 3 の読み戻しに `core.pager delta` があるかを確かめる
   - `git diff | head` のようにパイプに繋ぐと、AlmaLinux 10 と同じく delta を通らない
   - **次の手順は、less を `q` で閉じ、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1で開いた PowerShell に貼る**

### GitHub CLI

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

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`Admin : True` なら、窓を閉じて、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1 のとおりに開き直す
   - `Scoop` に `C:\Users\<WIN_USER>\scoop\shims\scoop.ps1` が出ればよい。空なら、先に[アプリを入れる](#アプリを入れる)の手順 1・2 で入れる
   - `Git` が `C:\Program Files\Git\cmd\git.exe` でなければ、先に [Git for Windows](#git-for-windows)
   - `GitCred` が `credential.helper manager` ならよい
   - `GitCred` が空なら、この項の手順 3 の Git の認証には `Y` と答えてよい
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
   - Git の認証の問いが出なければ、gh がもう Git の資格情報のヘルパーになっている（この項の手順 1 の `GitCred`）
   - `One-time code (<コード>) copied to clipboard` の行のワンタイムコードを、この項の手順 4 のブラウザで使う
   - クリップボードに入れられなかったときは、`First copy your one-time code:` の後にコードが出る
   - `Press Enter to open https://github.com/login/device in your browser...` で Enter を押すと、既定のブラウザが開く
   - **トークン（`gh auth token` の出力）や、認証中に表示されるワンタイムコードはこの文書に載せない**

1. ブラウザで、GitHub の認証を済ませる。

   - `https://github.com/login/device` にこの項の手順 3 のワンタイムコードを入れ、画面の案内に従う
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
   - `You are not logged into any GitHub hosts.` なら、ログインしていない。この項の手順 3 からやり直す
   - 最後のコマンドが、この項の手順 1 の `GitCred` と同じ行（ふつうは `credential.helper manager`）を出せばよい
   - `GitCred` が空で、Git の認証に `Y` と答えたときは、代わりに `auth git-credential` で終わる行が出る

### Neovim

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

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`True` なら、窓を閉じて、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1 のとおりに開き直す
   - `Scoop` に `…\scoop\shims\scoop.ps1` の場所が出ればよい。空なら、先に[アプリを入れる](#アプリを入れる)の手順 1・2 で入れる
   - `Git` は `C:\Program Files\Git\cmd\git.exe` ならよい。空か違う場所なら、先に [Git for Windows](#git-for-windows)
   - `VCRuntime : False` なら、[WezTerm](#wezterm)の手順 2 を管理者の Windows PowerShell で行ってから、この手順を貼り直す
   - `C:\Program Files\Neovim\bin\nvim.exe` など、ほかの場所が出たら、winget などで入れた Neovim がある。外してから始める

1. scoop で Neovim を入れる。

   ```powershell
   scoop install neovim
   ```

   - `'neovim' (0.12.5) was installed successfully!` の形の行が出ればよい
   - `'neovim' suggests installing 'extras/vcredist2022'.` も出るが、この項の手順 1 が `VCRuntime : True` なら入れなくてよい
   - `'neovim' (0.12.5) is already installed.` の形なら、もう入っている（何も変えない）
   - まだ `nvim` は起動しない（この項の手順 3 の退避より前に起動すると、`nvim-data` などができて、それも退避される）

1. 自分用の設定（[ryo-aoki-pc/LazyVimStarter](https://github.com/ryo-aoki-pc/LazyVimStarter)）を入れる。

   - [LazyVim の設定を導入する](#lazyvim-の設定を導入する)の全項を、この項で指定した端末で通す
   - 飛ばす手順: 2（scoop。[アプリを入れる](#アプリを入れる)の手順 1・2 で入れた）と、手順 7 のフォント（[HackGen Console NF](#hackgen-console-nf)で入れた。手順 7 の確かめは行う）
   - その手順 3 で `extras` のバケットを足し、手順 6 で ripgrep・fd・gcc・nodejs・zenhan・lazygit も scoop で入れる（Neovim は、この項の手順 2 で入っている）
   - その手順 9・11 で Neovim の画面が開く（その手順 10 は画面を開かない）。手順 9 は `:qa`、手順 11 は `:qa!` で閉じてから次を貼る

1. 版と場所と、設定・データの置き場所を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   nvim --version | Select-Object -First 3
   (Get-Command nvim -All).Source
   nvim --clean --headless "+lua io.stdout:write(vim.fn.stdpath('config'), '\n', vim.fn.stdpath('data'), '\n')" +qa
   ```

   - `NVIM v0.12.5`・`Build type: Release`・`LuaJIT 2.1.…` の 3 行が出ればよい
   - 無出力で終わるか `VCRUNTIME140.dll` のエラーなら、VC++ ランタイムをこの項の手順 1 で確かめる
     - 窓が出たら、OK で閉じる
   - 2 つ目は `C:\Users\<WIN_USER>\scoop\shims\nvim.exe` の 1 行だけならよい
   - 最後に、設定の置き場所（`C:\Users\<WIN_USER>\AppData\Local\nvim`）とデータの置き場所（`…\AppData\Local\nvim-data`）の 2 行が出る（[AlmaLinux 10 の初期設定の「Neovim の設定ファイル」](almalinux-setup.md#neovim-の設定ファイル)）

### lazygit

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

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`True` なら、窓を閉じて、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1 のとおりに開き直す
   - `Scoop` に `…\scoop\shims\scoop.ps1` の場所が出ればよい。空なら、先に[アプリを入れる](#アプリを入れる)の手順 1・2 で入れる
   - `Git` は `C:\Program Files\Git\cmd\git.exe` ならよい。空か違う場所なら、先に [Git for Windows](#git-for-windows)
   - ほかの場所（winget の `JesseDuffield.lazygit` など）が出たら、外してから始める
   - `Extras : True` なら、extras のバケットはもうある（[Neovim](#neovim)の手順 3 で足した）。この項の手順 2 は飛ばす

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
   - lazygit を起動する（この項の手順 6）前に入れる。先に起動すると、できた状態ファイルごと `lazygit.bak` に退避される

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

   - `中断:` と出たら、lazygit は起動していない（git が呼べるかを、この項の手順 1 で確かめ直す）
   - 初回に `Thanks for using lazygit...` の案内が出たら Enter で閉じる
   - Status・Files・Branches・Commits などの欄が出ればよい（空のリポジトリなので、一覧は空）
   - ほかのリポジトリで確かめるなら、そのフォルダーに `Set-Location` してから `lazygit` を打つ（git 管理外のフォルダーで起動すると、リポジトリを作るか聞かれる）
   - **注意**: Windows PowerShell から起動した lazygit の `e` キーは、git の `core.editor` と環境変数 `VISUAL`・`EDITOR` などが無いと `vim` で開こうとして失敗する
     - [Neovim を既定のエディタにする（任意）](#neovim-を既定のエディタにする任意)で `nvim` にし、新しい窓で lazygit を起動し直す
     - Git Bash から起動したときは、共通の bash 設定が `nvim` にしてある
   - `q` で閉じる
   - `%TEMP%\lazygit-check` は、要らなければ手で消す
     - 消す前に `Set-Location ~` で出る
   - **ほかのブロックは、`q` で閉じてから貼る**（続けて貼ると lazygit への操作として食われる）

### yazi

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

   - `PowerShell : 5.1.…`・`Admin : False`・`FileExe : True` が出ればよい。`Admin : True` なら、窓を閉じて、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1 のとおりに開き直す（この項の手順 1 も貼り直す）
   - `Scoop` に `…\scoop\shims\scoop.ps1` の場所が出ればよい。空なら、先に[アプリを入れる](#アプリを入れる)の手順 1・2 で入れる
   - `Git` が `C:\Program Files\Git\cmd\git.exe` でないか、`FileExe : False` なら、先に [Git for Windows](#git-for-windows)
   - `VCRuntime : False` なら、[WezTerm](#wezterm)の手順 2 を管理者の Windows PowerShell で行ってから、この手順を貼り直す
   - `Yazi` は空か `C:\Users\<WIN_USER>\scoop\shims\yazi.exe` ならよい。ほかの場所なら、外してから始める
   - `YaziFileOne` の元の値を控える。この項の手順 4 で Git for Windows の `file.exe` に上書きし、ロールバックで戻す

1. scoop で yazi と、プレビュー・検索に使うツールを入れる。

   ```powershell
   if ($null -eq $YAZI_EXTRAS) { Write-Error '中断: 「yazi」の手順 1 の $YAZI_EXTRAS が無い。手順 1 を貼り直す' } else { scoop install yazi @YAZI_EXTRAS }
   ```

   - アプリごとに `'yazi' (26.9.1) was installed successfully!` の形の行が出ればよい。入っていたものは `is already installed.` の形の行を出して飛ばす
   - `'ripgrep' suggests installing 'extras/vcredist2022'.` などの `suggests installing` の行は、入れなくてよい
   - `中断:` と出たら、何も入れていない（新しい窓では、この項の手順 1 を貼り直す。yazi 本体だけにするなら `$YAZI_EXTRAS = @()`）
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
   - 無出力で終わるか `VCRUNTIME140.dll` のエラーなら、VC++ ランタイムをこの項の手順 2 で確かめる
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
   - [表示と入力](#表示と入力)の手順 6 で既定の端末を Windows Terminal にした PC では、この窓も Windows Terminal で開く
   - `q` で閉じる
   - **ほかのブロックは、`q` で閉じてから貼る**（続けて貼ると yazi への操作として食われる）

### Claude Code

1. 変数を設定する。

   ```powershell
   $CC_CHANNEL = 'latest'                # 追従するチャンネル。latest（出た版をすぐ配る）か stable（約 1 週間遅れ）。<CC_CHANNEL>
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'CC_CHANNEL = {0}' -f $CC_CHANNEL
   ```

   - **編集が必須の変数は無い**。既定の `latest`（最新版）でよければ、そのまま貼る
   - 大きな不具合のある版を避けたいなら `stable` にする（[AlmaLinux 10 の初期設定の「Claude Code」](almalinux-setup.md#claude-code)の手順 1 の `CC_CHANNEL` と同じ意味）
   - 最後に値を読み戻して確かめる
   - 変数はその PowerShell の中だけで有効。使うのはこの項の手順 3 だけ

1. Claude Code と Git for Windows があるか、64 ビットの PowerShell かを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [Environment]::Is64BitProcess
   Get-Command claude -All -ErrorAction SilentlyContinue | Format-Table Source
   Test-Path "$env:USERPROFILE\.local\bin\claude.exe"
   Get-Command git -ErrorAction SilentlyContinue | Format-Table Source
   Test-Path 'C:\Program Files\Git\bin\bash.exe'
   ```

   - `True`、（claude は何も出ずに）`False`、`C:\Program Files\Git\cmd\git.exe`、`True` の順に出ればよい
   - 最初が `False` なら窓を閉じ、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1 で開き直す。x86 版は使わない
   - claude の場所が `C:\Users\<WIN_USER>\.local\bin\claude.exe` だけで、3 つ目が `True` なら導入済み。この項の手順 3 は設定・ログインを残して入れ直す
   - claude の行にほかの場所（WinGet・npm・scoop で入れたものなど）が出たら、そちらを先に外す（[注意点](extra/windows-setup.md#注意点)）
   - `WindowsApps` の `Claude.exe` が出たら、古い Claude Desktop が `claude` の名前を取っている。Claude Desktop を最新にする（公式の Troubleshoot installation）
   - git が出ず、最後が `False` なら、Git for Windows が無い。先に [Git for Windows](#git-for-windows)を通す

1. Claude Code を公式の native installer で入れる。

   ```powershell
   if (-not $CC_CHANNEL) {
     Write-Error '「Claude Code」の手順 1 の $CC_CHANNEL が空'
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     & ([scriptblock]::Create((Invoke-RestMethod -Uri https://claude.ai/install.ps1))) $CC_CHANNEL
   }
   ```

   - `Claude Code successfully installed!` と版（`Version: 2.1.288` など）の後に、最後に `Installation complete!`（前に絵文字の ✅ が付く）が出ればよい
   - `Setup notes:` に PATH 不足が出ても、この項の手順 4 で足す。ここでは何もしない
   - 赤いエラー（`Checksum verification failed`、`Failed to download binary` など）が出たら、そこで止まっている。[注意点](extra/windows-setup.md#注意点)と公式の [Troubleshoot installation](https://code.claude.com/docs/en/troubleshoot-install) を見る

1. 自分のユーザーの PATH に `%USERPROFILE%\.local\bin` が無ければ足す。

   ```powershell
   & {
     $bin = "$env:USERPROFILE\.local\bin"
     $entries = @([Environment]::GetEnvironmentVariable('Path', 'User') -split ';' | Where-Object { $_ })
     if (-not (Test-Path -LiteralPath "$bin\claude.exe")) { Write-Error "中断: $bin\claude.exe が無い（「Claude Code」の手順 3 で入っていない）"; return }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($entries | Where-Object { $_.TrimEnd('\') -eq $bin }) {
       "PATH に $bin はもうある"
     } else {
       [Environment]::SetEnvironmentVariable('Path', (($entries + $bin) -join ';'), 'User')
       "PATH に $bin を足した"
     }
     [Environment]::GetEnvironmentVariable('Path', 'User') -split ';'
   }
   ```

   - `足した` または `はもうある` と出て、PATH の一覧に `C:\Users\<WIN_USER>\.local\bin` があればよい
   - 何度貼ってもよい（あれば足さない）

1. 開いている Windows PowerShell を閉じ、新しく開き直す。

   - ウィンドウを閉じ（`exit` と打ってもよい）、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1 と同じように、管理者ではない Windows PowerShell を開く（「Windows PowerShell (x86)」は開かない）
   - この項の手順 1 の変数は、この後は使わない
   - **次の手順は、開き直した PowerShell に貼る**（前の PowerShell の `PATH` には、`.local\bin` が無いことがある）

1. Claude Code の場所・版・署名と、導入の状態を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Command claude -All | Format-Table Source
   claude --version
   $sig = Get-AuthenticodeSignature -LiteralPath "$env:USERPROFILE\.local\bin\claude.exe"
   '{0}  {1}' -f $sig.Status, $sig.SignerCertificate.Subject
   claude doctor
   ```

   - `claude` の場所は `C:\Users\<WIN_USER>\.local\bin\claude.exe` の 1 行だけ
   - `2.1.288 (Claude Code)` のように版が出る（`stable` を選んだら、`latest` より古い版）
   - 署名の行が `Valid  CN="Anthropic, PBC", O="Anthropic, PBC", ...` で始まればよい。`Valid` でなければ使わずに、ロールバックの Claude Code の手順で消す
   - `claude doctor` に `Running: native (...)`・`Auto-updates: enabled`・`Auto-update channel: latest`（`stable` を選んだら `stable`）・`No installation issues found.` が出ればよい

1. `claude` を起動し、最初の設定とブラウザでのログインを行う。

   ```powershell
   claude
   ```

   - 文字の色の組み合わせ（`Choose the text style that looks best with your terminal`）を選んで Enter
   - `Select login method:` で `Claude account with subscription`（Pro / Max / Team / Enterprise）を選ぶ。Console のアカウントなら `Anthropic Console account`
   - 既定のブラウザ（Firefox）が開くので、claude.ai にログインして承認する。ブラウザが開かなければ、`c` で URL をコピーしてブラウザに貼る
   - ブラウザにコードが出たら、端末の `Paste code here if prompted >` に貼る
   - 端末に `Login successful` が出たら Enter。続く案内とフォルダーの信頼の確認（↓ で `Yes, I trust this folder`）に答えると、セッションが始まる
   - ログイン済みなら質問は出ない。別のアカウントにするなら、セッション内で `/login`
   - `/exit` で終える
   - **認証情報（トークン・コード）はこの文書に載せない**
   - **次の手順は、`/exit` で Claude Code を終えてから貼る**（続けて貼ると Claude Code への入力として食われる）

1. ログインしたかを確かめる。

   ```powershell
   claude auth status --text
   ```

   - `Login method: Claude Max account` のように、プランの行が出ればよい（ほかにメールアドレスと組織の行も出る）
   - `Not logged in. Run claude auth login to authenticate.` なら、ログインしていない。この項の手順 7 をやり直す
   - このコマンドの後ろに、別のコマンドを続けて貼らない

### Codex CLI

1. 既存の Codex が入っていないか確かめる。

   ```powershell
   Get-Command codex -All -ErrorAction SilentlyContinue
   ```

   - 新規の PC なら何も出ない
   - パスが出たら、元の導入方法を確認してから進める
   - `CODEX_HOME`・`CODEX_INSTALL_DIR`・`CODEX_RELEASE` は変えない。導入・ロールバックは既定の場所を使う

1. 公式の standalone インストーラーで Codex CLI を入れる。

   ```powershell
   & ([scriptblock]::Create((Invoke-RestMethod -Uri 'https://chatgpt.com/codex/install.ps1')))
   ```

   - `Codex CLI … installed successfully.` を確認する
   - `Start Codex now?` と聞かれたら `n` で答える
   - **次の手順は、インストーラーが終わり、PowerShell のプロンプトに戻ってから貼る**

1. 実行ファイルと版を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Command codex -All
   codex --version
   ```

   - `Source` がこの項の手順 2 の場所で、`codex-cli …` が出ることを確認する

1. 開いている Windows PowerShell を閉じ、新しく開き直す。

   - [WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1と同じように、管理者ではない Windows PowerShell（5.1）を開く
   - 新しい窓でも `codex --version` が通ることを確認する
   - 見つからない場合は、Windows Terminal など親のアプリも閉じて開き直す

1. ChatGPT でのログインを始める。

   ```powershell
   codex login
   ```

   - ブラウザが開く。自動で開かなければ、端末に出た URL を同じ PC のブラウザで開く
   - ブラウザの無いホストでは、この項の手順 5・6 の代わりに[AlmaLinux 10 の初期設定の「Codex CLI をブラウザの無いホストでログインする」](almalinux-setup.md#codex-cli-をブラウザの無いホストでログインする)を通す（同じコマンドを PowerShell に貼る）

1. ブラウザで ChatGPT にログインし、Codex との接続を承認する。

   - 利用するアカウント・ワークスペースを選ぶ
   - **次の手順は、端末でログインの成功を確認し、PowerShell のプロンプトに戻ってから貼る**

1. ログイン状態を確かめる。

   ```powershell
   codex login status
   ```

   - ChatGPT でログイン済みであることを確認する

1. 確認用のディレクトリで Codex を起動する。

   ```powershell
   New-Item -ItemType Directory -Path "$env:USERPROFILE\codex-sandbox" -Force | Out-Null
   Set-Location "$env:USERPROFILE\codex-sandbox"
   git init
   codex
   ```

   - 作業場所の確認が出たら、`codex-sandbox` であることを確認する
   - Windows sandbox の設定を求められたら案内に従う。推奨の `elevated` sandbox の初回設定には管理者の承認が必要（普段の Codex は通常のユーザーで動かす）
   - 入力欄に「このディレクトリの状態を説明してください。ファイルは変更しないでください」と入力し、応答を確認する
   - 終了するときは `/quit` を入力する
   - **次の手順は、Codex を終了して PowerShell のプロンプトに戻ってから貼る**

### Grok Build

1. 既存の Grok が入っていないか確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Command grok, agent -All -ErrorAction SilentlyContinue
   Test-Path "$env:USERPROFILE\.grok"
   ```

   - 新規の PC なら、`False` だけが出る
   - パスか `True` が出たら、元の導入方法を確かめてから進める（WinGet の `xAI.GrokBuild` で入れた Grok なら、WinGet で更新する）

1. 公式のインストーラーで Grok Build を入れる。

   ```powershell
   & ([scriptblock]::Create((Invoke-RestMethod -Uri 'https://x.ai/cli/install.ps1')))
   ```

   - `Grok … installed to C:\Users\<WIN_USER>\.grok\bin\grok.exe` を確かめる
   - 初回は `Added C:\Users\<WIN_USER>\.grok\bin to your User PATH.` も出る
   - **次の手順は、インストーラーが終わり、PowerShell のプロンプトに戻ってから貼る**

1. 実行ファイルと版を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Command grok -All
   grok --version
   ```

   - `Source` がこの項の手順 2 の場所で、`grok …` の版が出ることを確かめる

1. 開いている Windows PowerShell を閉じ、新しく開き直す。

   - [WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1と同じように、管理者ではない Windows PowerShell（5.1）を開く
   - 新しい窓でも `grok --version` が通ることを確かめる
   - 見つからない場合は、Windows Terminal など親のアプリも閉じて開き直す

1. ブラウザでのログインを始める。

   ```powershell
   grok login
   ```

   - ブラウザが開く。開かなければ、端末に出た URL を同じ PC のブラウザで開く
   - ブラウザの無いホストでは、この項の手順 5・6 の代わりに[AlmaLinux 10 の初期設定の「Grok Build をブラウザの無いホストでログインする」](almalinux-setup.md#grok-build-をブラウザの無いホストでログインする)を通す（同じコマンドを PowerShell に貼る）

1. ブラウザで grok.com のアカウントにログインし、Grok Build との接続を承認する。

   - ブラウザに出たコードが、端末のコードと同じであることを確かめてから承認する
   - **次の手順は、端末でログインの成功を確かめ、PowerShell のプロンプトに戻ってから貼る**

1. ログインを確かめる。

   ```powershell
   grok models
   ```

   - `You are not authenticated.` が出なければ、ログインできている

1. 確認用のディレクトリで Grok を起動する。

   ```powershell
   New-Item -ItemType Directory -Path "$env:USERPROFILE\grok-sandbox" -Force | Out-Null
   Set-Location "$env:USERPROFILE\grok-sandbox"
   git init
   grok
   ```

   - フォルダーを信頼するか聞かれたら、`grok-sandbox` であることを確かめて信頼する
   - 入力欄に「このディレクトリの状態を説明してください。ファイルは変更しないでください」と入力し、応答を確かめる
   - 終了するときは `/quit` を入力する
   - **次の手順は、Grok を終了して PowerShell のプロンプトに戻ってから貼る**

### Codex・Grok のプラグイン

1. Node.js 18.18 以上があるか確かめ、無いときだけ scoop で入れる（プラグインが使う）。

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $node = Get-Command node -ErrorAction SilentlyContinue
     if ($node -and [version]((node --version) -replace '^v', '') -ge [version]'18.18') {
       'Node.js がある: {0}（{1}）' -f (node --version), $node.Source
     } else {
       scoop install nodejs-lts
     }
   }
   ```

   - `Node.js がある:` と版・場所が出たら導入済み。この項の手順 2 は飛ばす
   - 入れたときは、`'nodejs-lts' (…) was installed successfully!` が出ればよい

1. この項の手順 1 で nodejs-lts を入れたときだけ、PowerShell を閉じ、スタートメニューから開き直す。

   - 開き直した窓で `node --version` が通ることを確かめる
   - **次の手順は、開き直した PowerShell に貼る**

1. Claude Code に、OpenAI の Codex のプラグインと xAI の Grok Build のプラグインを入れる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   claude plugin marketplace add openai/codex-plugin-cc
   claude plugin marketplace add xai-org/grok-build-plugin-cc
   claude plugin install codex@openai-codex
   claude plugin install grok-build@xai-grok-build
   claude plugin list
   ```

   - 見方は、[AlmaLinux 10 の初期設定の「Codex・Grok のプラグイン」](almalinux-setup.md#codexgrok-のプラグイン)の手順 2 と同じ

---

## Wake on LAN を使う（任意）

- 電源を切った（シャットダウンした）この PC を、LAN の別の PC から起こせるようにする。有線 LAN だけ（Wi-Fi では使えない）
- 前提: [PC 全体の設定](#pc-全体の設定)の手順 7・8（休止状態・高速スタートアップ・アダプターの省電力を切る）
- この節の手順 2〜4・8 は、同じ節の手順 1 で開く管理者の Windows PowerShell 5.1 に貼る
- **この節の手順 4 で再起動して UEFI の画面に入り、この節の手順 5 は UEFI の画面、この節の手順 6 はこの PC、この節の手順 7 は LAN の別の PC で行う**
- Windows の側の値は Microsoft の文書の標準の名前（`*WakeOnMagicPacket`）だけを変える。アダプターに独自の項目があれば、この節の手順 3 の表で確かめる

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
     Write-Error 'この節の手順 2 の $LAN_IF が空'
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Set-NetAdapterAdvancedProperty -Name $LAN_IF -RegistryKeyword '*WakeOnMagicPacket' -RegistryValue 1 -NoRestart
     Get-NetAdapterAdvancedProperty -Name $LAN_IF | Where-Object { $_.RegistryKeyword -like '*Wake*' -or $_.DisplayName -like '*Wake*' } | Format-Table DisplayName, DisplayValue, RegistryKeyword
     Get-NetAdapter -Name $LAN_IF | Format-List Name, InterfaceDescription, MacAddress
   }
   ```

   - 表に `*WakeOnMagicPacket` の行があり、`DisplayValue` が有効の旨（`Enabled` か「有効」）になればよい
   - `MacAddress` の値を控える（この節の手順 7 で使う）
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

   - AlmaLinux 10 などの Python があるマシンでは、`python3 -c "import socket; m = bytes.fromhex('<MAC>'.replace('-', '').replace(':', '')); s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1); s.sendto(b'\xff' * 6 + m * 16, ('255.255.255.255', 9))"` で送れる（`<MAC>` はこの節の手順 3 の値）
   - 起動しなければ、この節の手順 3 の表の項目と、UEFI の設定を見直す
   - 元に戻すときは、この節の手順 8

1. 元に戻すときは、管理者の PowerShell で、マジック パケットでの起動を切る。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error 'この節の手順 2 の $LAN_IF が空'
   } else {
     Set-NetAdapterAdvancedProperty -Name $LAN_IF -RegistryKeyword '*WakeOnMagicPacket' -RegistryValue 0 -NoRestart
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-NetAdapterAdvancedProperty -Name $LAN_IF -RegistryKeyword '*WakeOnMagicPacket' | Format-Table DisplayName, DisplayValue
   }
   ```

   - 新しい PowerShell なら、先にこの節の手順 2 を貼る
   - UEFI の Wake on LAN も、この節の手順 4・5 と同じように入って切る

---

## リモートから再起動する手段を増やす（任意）

> [!IMPORTANT]
> - [実施手順](#実施手順)の後に行う。[ネットワークとリモート](#ネットワークとリモート)の手順 1 で LAN をプライベートにしておく
> - 再起動後に使えるよう、[PC 全体の設定](#pc-全体の設定)の手順 7・8 と[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 5 を通す
> - 手段は独立しているので、要るものだけ行う（「〜したいときだけ」の手順は飛ばしてよい）。この節の手順 2〜7・撤去の手順は、この節の手順 1 で開く管理者の Windows PowerShell（5.1）に貼る
> - **別の PC で動かすトリガーのコマンドは、その PC で実行する**（AlmaLinux のシェルか、別の Windows の PowerShell）

- リモートの操作ができなくなったときに備えて、再起動の経路を増やす。1 つが死んでも別の経路で立ち直せるようにする
- 既にある接続からの再起動（この節の手順にはしない）
  - SSH でつながるなら `Restart-Computer`。Administrators のユーザーは UAC 不要で、sshd は再起動後も自動で起動する
  - RDP でつながるなら、スタートメニューの電源の「再起動」か `Restart-Computer`（[ネットワークとリモート](#ネットワークとリモート)の手順 2 で有効。再起動の後はロック画面に戻るが、また入れる）
  - [Claude Code の Remote Control（Windows）](#claude-code-の-remote-control-実施手順) のセッションからも再起動できるが、そのタスクはトリガーが無いので再起動の後は戻らない。戻すにはこの節の手順 7
- この節で足す手段: クラッシュ時の自動再起動（この節の手順 3）・別の PC からのネットワーク再起動（この節の手順 4・5）・ネットワークが切れたときの自動再起動（この節の手順 6）
- 戻すときは、この節の手順 8〜12（入れた手段のものだけ）

> [!WARNING]
> - この節の手順 4・5 は、LAN の別の PC から管理者の資格情報で再起動できる口を開ける
> - `LocalAccountTokenFilterPolicy=1` は、ローカル・Microsoft アカウントのネットワークログオンに完全な管理者権限を与える
> - **人が触れる場所や信用できない LAN の PC では、この節の手順 4・5 を行わない**
> - この節の手順 6 の見張りタスクは、相手（ルーターなど）がずっと落ちていると再起動を繰り返す（稼働 60 分未満は再起動しない歯止めがある）

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
     - 戻し方は、この節の手順 9 の箇条書き
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
     if (-not $admin) { Write-Error '中断: 管理者の PowerShell ではない（この節の手順 1 から）'; return }
     if (-not $WATCHDOG_HOST) { Write-Error '中断: この節の手順 2 の $WATCHDOG_HOST が空'; return }
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

   - 前提: [Claude Code の Remote Control（Windows）](#claude-code-の-remote-control-実施手順) を設定済みで、この PC のデスクトップに同じユーザーでサインインする（[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 5 の自動サインイン）
   - ログオンのトリガーが 1 つ表示されればよい。次にそのユーザーでサインインしたときから、タスクが自動で始まる

1. 元に戻すときは（この節の手順 4 を行ったとき）、SMB のリモートシャットダウンを閉じる。

   ```powershell
   Set-NetFirewallRule -Name FPS-SMB-In-TCP -Enabled False
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-NetFirewallRule -Name FPS-SMB-In-TCP | Format-Table Name, Enabled, Profile
   ```

   - `FPS-SMB-In-TCP … False` になればよい
   - `LocalAccountTokenFilterPolicy` は、この節の手順 5 の WinRM と共有している。戻すのはこの節の手順 10

1. 元に戻すときは（この節の手順 5 を行ったとき）、WinRM を無効にする。

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
   - この節の手順 5 の注意で、送る側の `TrustedHosts` に足したときは、送る側の管理者の PowerShell で控えた値に戻す
     - 送る側の WinRM のサービスが止まっていれば（送る側を再起動した後など）、先に `Start-Service WinRM` を行う
     - `Set-Item WSMan:\localhost\Client\TrustedHosts -Value '<控えた値>' -Force` を行う（空だったなら `-Value ''`）
     - 足す前にサービスが止まっていたなら、続けて `Stop-Service WinRM` を行う
   - `LocalAccountTokenFilterPolicy` はこの手順では戻さない（この節の手順 10）

1. 元に戻すときは（この節の手順 4 もこの節の手順 5 も使わないとき）、UAC のリモート制限を元に戻す。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name LocalAccountTokenFilterPolicy -Type DWord -Value 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' | Format-List LocalAccountTokenFilterPolicy
   ```

   - `LocalAccountTokenFilterPolicy : 0` になればよい（管理者のリモートログオンが、既定の制限に戻る）
   - この節の手順 4・5 のどちらかを使い続けるなら、この手順は行わない

1. 元に戻すときは（この節の手順 6 を行ったとき）、見張りのタスクと記録を消す。

   ```powershell
   Unregister-ScheduledTask -TaskName 'net-watchdog' -Confirm:$false
   Remove-Item -Path 'HKLM:\SOFTWARE\setup-notes\net-watchdog' -Recurse -ErrorAction SilentlyContinue
   Remove-Item -LiteralPath 'C:\ProgramData\setup-notes\net-watchdog.ps1' -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ScheduledTask -TaskName 'net-watchdog' -ErrorAction SilentlyContinue
   ```

   - 何も出なければよい（タスクが消えた）
   - 空になったキー `HKLM:\SOFTWARE\setup-notes` とフォルダー `C:\ProgramData\setup-notes` は残る。ほかに使っていなければ、手で消してよい

1. 元に戻すときは（この節の手順 7 を行ったとき）、Remote Control のタスクのトリガーを外す。

   - [Claude Code の Remote Control（Windows）](extra/windows-claude-remote-control.md#ロールバック)のロールバックでタスクごと消す。トリガーの無い形で使い続けるなら、同書の[実施手順](#claude-code-の-remote-control-実施手順)の手順 5 で入れ直す

---

## プライバシーと広告の表示を切る（任意）

- 自分のユーザーの広告・プライバシー・検索の設定を変える
- 前提: [実施手順](#実施手順)を通した後に行う。この節のブロックは、この節の手順 1 で開く**管理者ではない** Windows PowerShell（5.1）に貼る（管理者の権限は要らない）
- **この節の手順 3 でサインアウトしてサインインし直し、この節の手順 4・6 は設定の画面で行う**
- **ポリシー（`HKLM` や `HKCU\Software\Policies`）には書かない**。ポリシーを置くと、設定の画面の切り替えが灰色になり、「組織によって管理」の表示が出るため
- 値の多くは Microsoft の文書に無く、広く使われているもの（[参考資料](reference/windows-setup.md)・[検証記録](verification/windows-setup.md)）
- 戻すときは、この節の手順 5・6（行った手順のものだけ）

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
   - `->` の左は元の値（空なら値が無かった）。初めて貼ったときに `%LOCALAPPDATA%\setup-notes\privacy-before.csv` に控え、2 回目からは書き換えない（この節の手順 5 で使う）
   - `IsDeviceSearchHistoryEnabled` は、0 と 1 のどちらがオフかで資料が食い違う。この節の手順 4 の画面で確かめる
   - 多くは、この節の手順 3 でサインインし直した後に効く

1. サインアウトして、同じユーザーでサインインし直す。

   - スタートメニューのユーザーのアイコンから「サインアウト」を選ぶ（スタートメニューの電源から再起動してもよい）
   - **次の手順は、サインインし、この節の手順 1 と同じ方法で管理者ではない窓を開いてから貼る**

1. 設定の「プライバシーとセキュリティ」を開き、切り替えを確かめ、残りを画面で切る。

   ```powershell
   Start-Process 'ms-settings:privacy'
   ```

   - 「全般」（新しいビルドでは「おすすめとオファー」）で、広告 ID と言語リストの切り替えがオフ。「設定アプリで通知を表示する」があれば、オフにする
   - 「音声認識」で、「オンライン音声認識」がオフ
   - 「手書き入力と入力の個人用設定」で、「カスタム手書き入力と入力の辞書」をオフにする（覚えた単語の一覧が消える）
   - 「診断とフィードバック」で、「オプションの診断データを送信する」がオンなら、オフにする。「手書き入力と入力の改善」と「カスタマイズされたエクスペリエンス」がオフ、「フィードバックの頻度」が「しない」
   - 新しいビルドでは、「カスタマイズされたエクスペリエンス」は「パーソナライズされたオファー」の名前で別のページにある
   - 「検索のアクセス許可」で、「クラウドのコンテンツ検索」の 2 つと「このデバイスの検索履歴」がオフ。「検索のハイライトを表示する」は、[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 2 の値で灰色になっている
   - この節の手順 2 で書いた項目がオンのまま出ていたら、その画面でオフにする
   - **次の手順は、設定を閉じてから貼る**

1. 元に戻すときは（この節の手順 2 を行ったとき）、控えた元の値に戻す。

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
   - `中断: 控えが無い` が出たら、この節の手順 6 の画面で戻す
   - 控えのファイルは残る。要らなければ手で消す
   - 効くのは、サインインし直した後

1. 元に戻すときは（この節の手順 4 で切ったものを使うときか、この節の手順 5 で控えが無かったとき）、設定の画面でオンに戻す。

   ```powershell
   Start-Process 'ms-settings:privacy'
   ```

   - この節の手順 4 でオフにした「設定アプリで通知を表示する」・「カスタム手書き入力と入力の辞書」・「オプションの診断データを送信する」のうち、使うものをオンにする
   - この節の手順 5 で `中断: 控えが無い` が出たときは、この節の手順 2 で切った項目（「全般」の広告 ID と言語リスト・「オンライン音声認識」・「手書き入力と入力の改善」・「カスタマイズされたエクスペリエンス」・「フィードバックの頻度」・「検索のアクセス許可」の 3 つ）も、使うものを戻す
   - 同じときに、エクスプローラーの同期プロバイダーの通知も使うなら、フォルダー オプションの「表示」で戻す
   - 消えた辞書（覚えた単語の一覧）は戻らない

---

## 表示・入力・音・ストレージを変える（任意）

- 自分のユーザーの設定で、次のものを変える（[表示と入力](#表示と入力)の手順 1・4・7 の続き）
  - 誤って押しやすいキー: 固定キー・フィルター キー・切り替えキーのショートカット、入力言語とキー配列の切り替え（Alt+Shift・Ctrl+Shift）
  - 窓とエクスプローラー: Alt+Tab の Edge のタブ、タイトル バーのシェイク、左の一覧のギャラリーとホーム、タスクバーの「タスクの終了」
  - アニメーション効果、効果音と起動音、ストレージ センサー
- [実施手順](#実施手順)の後、[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 1 で開く通常の Windows PowerShell 5.1 に貼る
- 項目は独立しているので、要らない手順は飛ばしてよい（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 1・2・13・14 は飛ばさない）
- [表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 10・12・14 は**画面で行い**、同じ項の手順 13 で**サインアウトしてサインインし直す**
- **ストレージ センサーは、一時ファイルとごみ箱に 30 日を超えて置いたファイルを毎月消す（取り戻せない）**
  - ごみ箱を置き場に使うなら、[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 11・12 を飛ばすか、同じ項の手順 12 でごみ箱を「許可しない」にする
- 入力言語の切り替えのキーを切っても、Win+Space で切り替えられる
- 戻すときは、[表示・入力・音・ストレージを元に戻す](#表示入力音ストレージを元に戻す)の手順 1〜9（行った手順のものだけ）。[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 2 で控えた値を使う

### 表示・入力・音・ストレージを控えて変える

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
   - 控えは `%LOCALAPPDATA%\setup-notes\display-before.csv`。初めて貼ったときだけ作り、2 回目からは書き換えない（[表示・入力・音・ストレージを元に戻す](#表示入力音ストレージを元に戻す)の手順 2〜5 で使う）

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
   - 控えは `%LOCALAPPDATA%\setup-notes\appevents.reg`。初めて貼ったときだけ作り、2 回目からは書き換えない（[表示・入力・音・ストレージを元に戻す](#表示入力音ストレージを元に戻す)の手順 7 で戻す）
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
   - `->` の左（元の値）を控える。空なら値が無かった。数があったなら、[表示・入力・音・ストレージを元に戻す](#表示入力音ストレージを元に戻す)の手順 9 で戻した後に、画面で同じにし直す
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

### 表示・入力・音・ストレージを元に戻す

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

## Edge の常駐をポリシーで止める（任意）

- Edge のスタートアップ ブースト（サインインのときに Edge を裏で起動しておく）と、閉じた後も拡張機能とアプリを動かし続けるバックグラウンドの実行を、PC 全体のポリシーで切る
- 前提: [実施手順](#実施手順)を通した後に行う。この節のブロックは、この節の手順 1 で開く**管理者の** Windows PowerShell（5.1）に貼る（PC 全体のポリシーなので、すべてのユーザーにかかる）
- **この節の手順 2 のポリシーを置くと、Edge に「組織によって管理されている」旨が出て、Edge の設定の 2 つの切り替えが灰色になる**。出したくないなら、この節の手順 2 の代わりにこの節の手順 3（画面だけで切る）を行う
- [サインイン・検索・キーボード](#サインイン検索キーボード)の手順 3 の Edge Update のポリシー（`EdgeUpdate` のキー）とは別のキー（`Edge`）に書く
- **この節の手順 3・4 は Edge の画面で行う**
- 戻すときは、この節の手順 5・6（行った手順のものだけ）

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
   - [自動起動と標準アプリ](#自動起動と標準アプリ)の手順 1 で止めた `MicrosoftEdgeAutoLaunch_*` の行は、無くなることがある（同じ項の手順 1 と[ロールバックの「表示と入力を戻す」](extra/windows-setup.md#表示と入力を戻す)の手順 8 は、無いものを飛ばす）

1. （この節の手順 2 の代わりに）管理の表示を出したくないときは、Edge の設定の画面で 2 つを切る。

   - Edge のアドレス バーに `edge://settings/system` を入れて開く（「設定」→「システムとパフォーマンス」→「システム」）
   - 「スタートアップ ブースト」をオフにする
   - 「Microsoft Edge が終了してもバックグラウンドの拡張機能およびアプリの実行を続行する」をオフにする

1. Edge で、2 つが切れていることを確かめる。

   - `edge://settings/system` で、2 つがオフになっている（この節の手順 2 を行ったなら、灰色で変えられない）
   - この節の手順 2 を行ったなら、`edge://policy` に `StartupBoostEnabled` と `BackgroundModeEnabled` が、値 `false`・状態 `OK` で出る
   - Edge の窓をすべて閉じると、通知領域に Edge のアイコンが残らない
   - サインインし直した後も `msedge.exe` が見えることがある

1. 元に戻すときは（この節の手順 2 を行ったとき）、管理者の PowerShell で、2 つのポリシーを消す。

   ```powershell
   $k = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
   foreach ($n in 'StartupBoostEnabled', 'BackgroundModeEnabled') { Remove-ItemProperty -Path $k -Name $n -ErrorAction SilentlyContinue }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $k -ErrorAction SilentlyContinue | Format-List StartupBoostEnabled, BackgroundModeEnabled
   ```

   - 2 つが空ならよい
   - Edge を開き直すと、2 つの切り替えをまた変えられる

1. 元に戻すときは（この節の手順 3 を行ったとき）、Edge の設定の画面で 2 つをオンに戻す。

   - `edge://settings/system` で、この節の手順 3 でオフにした 2 つをオンにする

---

## CopyQ を使う（任意）

- クリップボードの履歴は、Windows の履歴（Win+V）ではなく、CopyQ に持たせる
- 前提: [Microsoft Store の更新](#microsoft-store-の更新)の手順 1〜7。この節の手順 1 で開く通常の Windows PowerShell 5.1 に貼る
- **この節の手順 3 で CopyQ を起動し、この節の手順 5・6 は画面で行う**
- CopyQ は窓を持つアプリなので、`copyq.exe` のコマンドの結果は、`| Write-Output` を付けないと出ない
- **CopyQ の履歴は、暗号化されずにディスクに残る**。パスワードなどをコピーするときは、[注意点](extra/windows-setup.md#注意点)を読む
- 戻すときは、この節の手順 7・8

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
   - 見つからない旨のエラーが出たら、前に別の場所へ入れた CopyQ がある。この節の手順 7・8 で外してから始め直す
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
   - 最後の右が `1` なら、Windows の履歴もオン。この節の手順 5 で切る。空か `0` なら、この節の手順 5 は飛ばす

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
     - Win+Shift+V と Ctrl+Win+Alt+V（[アプリを入れる](#アプリを入れる)の手順 4 の PowerToys の高度な貼り付け）
     - Ctrl+Shift+V（多くのアプリの、書式なしの貼り付け）
     - Ctrl+Space（[表示と入力](#表示と入力)の手順 7 の IME）
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
   - この節の手順 5 で Windows の履歴を切ったなら、使うときは設定の「システム」→「クリップボード」でオンに戻す

---

## PowerToys のユーティリティを絞る（任意）

- [アプリを入れる](#アプリを入れる)の手順 4 で入れた PowerToys の、既定で有効なユーティリティのうち、使わないものを設定ファイルで切る（同じ項の手順 4 の続き）
- 前提: [アプリを入れる](#アプリを入れる)の手順 4。この節のブロックは、この節の手順 1 で開く**管理者ではない** Windows PowerShell（5.1）に貼る（管理者の権限は要らない）
- **この節の手順 4・7 は通知領域で PowerToys を終了し、この節の手順 6 は PowerToys の設定の画面で行う**
- PowerToys は起動のときにだけ設定ファイルを読むので、終了してから書き、起動し直す
- 切るユーティリティは好みで選ぶ。この節の手順 2 の `$PT_OFF` は案で、Always On Top・コマンド パレット・PowerRename・File Locksmith・Peek・エクスプローラーのプレビュー・Image Resizer は残す（[参考資料](reference/windows-setup.md)）
- 「起動時に実行」はオン、「常に管理者として実行」はオフのまま変えない。自動の更新の取得も変えない
- Keyboard Manager は使わない（既定でオフ。Caps Lock は[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 4 で変える）
- 戻すときは、この節の手順 7・8

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
   - `PT_EXE` が空なら、PowerToys が見つからない。[アプリを入れる](#アプリを入れる)の手順 4 を確かめる
   - `$PT_OFF` の名前は、設定ファイルの名前（空白を含むものがある）。変えるなら、この節の手順 3 の表の `Name` から選ぶ
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
   - `無い名前:` が出たら、その名前は今の版の設定ファイルに無い（版で名前が変わる）。この節の手順 2 の `$PT_OFF` を表の名前に直して貼り直す
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
     if (Get-Process -Name PowerToys, PowerToys.Settings -ErrorAction SilentlyContinue) { Write-Error '中断: PowerToys が動いている。この節の手順 4 で終了してから貼り直す'; return }
     if (-not $PT_EXE) { Write-Error '中断: $PT_EXE が空。スタートメニューから PowerToys を起動し、この節の手順 2 を貼り直してから、この節の手順 4 に戻る'; return }
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
   - 控えは `%LOCALAPPDATA%\Microsoft\PowerToys\settings.json.windows-setup.bak`。控えが無いときだけ作る（この節の手順 8 で使い、書き戻すと消える）
   - `中断: PowerToys が動いている` が出たら、この節の手順 4 に戻る（設定の窓が残っていても止まる）

1. PowerToys の設定の画面で、切ったユーティリティがオフになっていることを確かめる。

   - 通知領域の PowerToys のアイコンを右クリックし、「設定」で設定の窓を開く（ダブルクリックでも開く。1 回のクリックで開くのはクイック アクセス）
   - 「ダッシュボード」で、`$PT_OFF` のユーティリティがオフ、残したものがオンになっている
   - 同じことは、ユーティリティごとのスイッチでもできる（すぐに効く）
   - Peek は「Space で開く」をオンのままにする
   - Find My Mouse を使うなら、起動の方法を「マウスを振る」にする
   - Command Not Found の「インストール」を押すと、PowerShell 7 のプロファイルに行が足される（[PowerShell 7 のプロファイルを設定する（任意）](#powershell-7-のプロファイルを設定する任意)の印は付かない）
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
     if (Get-Process -Name PowerToys, PowerToys.Settings -ErrorAction SilentlyContinue) { Write-Error '中断: PowerToys が動いている。この節の手順 7 で終了してから貼り直す'; return }
     if (-not (Test-Path -LiteralPath $bak)) { Write-Error "中断: 控えが無い: $bak"; return }
     if (-not $PT_EXE) { Write-Error '中断: $PT_EXE が空。スタートメニューから PowerToys を起動し、この節の手順 2 を貼り直してから、この節の手順 7 に戻る'; return }
     Copy-Item -LiteralPath $bak -Destination $path -Force -ErrorAction Stop
     Remove-Item -LiteralPath $bak
     $r = [IO.File]::ReadAllText($path) | ConvertFrom-Json
     foreach ($n in $PT_OFF) { '{0}: {1}' -f $n, $r.enabled.$n }
     Start-Process -FilePath $PT_EXE
   }
   ```

   - `FindMyMouse: True` の形の行（控えたときの値）が出て、通知領域に PowerToys のアイコンが戻ればよい
   - 新しい窓では、先にこの節の手順 2 を貼る
   - 控えた後に画面で変えた PowerToys の設定も、控えたときの値に戻る
   - `中断: 控えが無い` が出たら、スタートメニューから PowerToys を起動し、設定の画面で、切ったユーティリティのスイッチをオンにする
   - 控えのファイルは消える（もう一度この節を通すと、そのときの設定を控え直す）

---

## PowerShell 7 のプロファイルを設定する（任意）

- PowerShell 7 に貼り付け・↑/↓ の履歴検索と、導入済みの zoxide・starship を読む設定を足す
- 前提: [貼り付けの設定](#貼り付けの設定)の手順 1〜4 と[アプリを入れる](#アプリを入れる)の手順 5
- この節の手順 1 で開く通常の Windows PowerShell 5.1 に貼る。PowerShell 7 には貼らない
- 対象は `Documents\PowerShell\Microsoft.PowerShell_profile.ps1`。Windows PowerShell 5.1 のプロファイルとは別
- 足す行は ASCII の文字だけで、行末に印 `# windows-setup.md` を付ける
- **この節の手順 6 は PowerShell 7 の窓で確かめる**
- zoxide と starship は、入れていなければ読まない。この節は、それらを入れる前に通してよい（入れた後に PowerShell 7 を開き直せば読む）
- Windows Terminal の既定のプロファイルは Windows PowerShell のまま変えない。この文書とほかの手順書のブロックは、引き続き Windows PowerShell 5.1 に貼る
- 戻すときは、この節の手順 7・8（行った手順のものだけ）

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
     if (-not (Test-Path -LiteralPath $p)) { Write-Error "中断: プロファイルが無い。この節の手順 2 を先に貼る: $p"; return }
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
     - キーの表の `Ctrl+Enter` が `AddLine`、`UpArrow` が `HistorySearchBackward`、`DownArrow` が `HistorySearchForward`（この節の手順 3 を行ったなら、`Tab` が `MenuComplete`）
   - `pwsh.exe` が見つからない旨が出たら、[アプリを入れる](#アプリを入れる)の手順 5 を確かめる
   - 実行ポリシーがどれも `Undefined` なら、プロファイルは読まれず、キーは既定のまま（`Ctrl+Enter` が `InsertLineAbove`）。そうでなければ、この節の手順 5 は飛ばす

1. 実行ポリシーがどれも `Undefined` のときだけ、PowerShell 7 の CurrentUser を RemoteSigned にする。

   ```powershell
   pwsh.exe -NoLogo -NoProfile -Command { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; Get-ExecutionPolicy -List }
   ```

   - 表の `CurrentUser` が `RemoteSigned` になればよい
   - この節の手順 4 をもう一度貼って、キーの割り当てを確かめる

1. スタートメニューから PowerShell 7 を開き、キーとプロンプトを確かめる。

   - スタートメニューで「PowerShell」を探し、「Windows PowerShell」ではない「PowerShell」（PowerShell 7）をクリックして開く（一覧の名前に 7 は付かないことがある）
   - 何か打ってから ↑ を押すと、打った文字で始まる履歴だけが出る
   - 打っている途中に、履歴からの候補が薄い文字で出る（PowerShell 7 の既定の予測。→ で受け入れ、F2 で一覧の表示に切り替わる）
   - starship を入れていればプロンプトが starship の形になり、zoxide を入れていれば `z` が使える
   - Ctrl+Alt+? で、キーの割り当ての一覧が出る
   - **次の手順は、PowerShell 7 の窓を `exit` で閉じてから、この節の手順 1 の窓に貼る**

1. 元に戻すときは、PowerShell 7 のプロファイルから、この節で足した行を消す。

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

1. 元に戻すときは（この節の手順 5 を行ったとき）、PowerShell 7 の CurrentUser の実行ポリシーを戻す。

   ```powershell
   pwsh.exe -NoLogo -NoProfile -Command { Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope CurrentUser -Force; Get-ExecutionPolicy -List }
   ```

   - 表の `CurrentUser` が `Undefined` ならよい

---

## Windows Terminal のフォントと貼り付けの警告を変える（任意）

- Windows Terminal（[表示と入力](#表示と入力)の手順 6 で既定の端末にした）の全プロファイルのフォントを HackGen Console NF にし、複数行を貼るときの警告を、要らなければ切る
- 前提: [HackGen Console NF](#hackgen-console-nf)を入れ、サインインし直すか、[WSL と再起動](#wsl-と再起動)の手順 2 を通した後
- この節の手順 1 で開く通常の Windows PowerShell 5.1 に貼る
- **この節の手順 5 は Windows Terminal の設定の画面で行う**
- 効くのは Windows Terminal で開く窓（管理者ではない窓と、Win+X の「ターミナル」・「ターミナル (管理者)」）だけ。スタートメニューから管理者として開いた PowerShell（conhost の窓）には効かない
- 管理者ではない窓に複数行のブロックを貼ると、「警告」の窓が出ることがある（Windows PowerShell 5.1 は、角かっこで囲む貼り付けを使わないため）。「強制的に貼り付け」を押す（出さないなら、この節の手順 4）
- コマンドで書くのは `settings.json` だけ。既定のプロファイル（Windows PowerShell）と、選んだらコピーする設定（`copyOnSelect`）は変えない
- 戻すときは、この節の手順 6

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（[表示と入力](#表示と入力)の手順 6 の設定で、Windows Terminal の窓で開く）

1. Windows Terminal の設定ファイルを控え、今のフォントと警告の値を確かめる。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     $bak = "$path.windows-setup.bak"
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (-not (Test-Path -LiteralPath $path)) { Write-Error "中断: 設定ファイルが無い。Windows Terminal を 1 度開いてから貼り直す: $path"; return }
     $text = [IO.File]::ReadAllText($path)
     if (($text -replace '"(?:[^"\\]|\\.)*"', '""') -match '/[/*]|,\s*[}\]]') { Write-Error "中断: コメントか末尾のカンマがある。この節の手順 5 の画面で変える: $path"; return }
     try { $s = $text | ConvertFrom-Json -ErrorAction Stop } catch { Write-Error "中断: 読めない。この節の手順 5 の画面で変える: $path"; return }
     if (-not $s.profiles -or $s.profiles -is [array]) { Write-Error '中断: profiles が無いか古い形式（配列）。この節の手順 5 の画面で変える'; return }
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
   - 控えは `…\LocalState\settings.json.windows-setup.bak`。控えが無いときだけ作る（この節の手順 6 で使い、書き戻すと消える）
   - 最後に表が出たら、そのプロファイルは自分のフォントを持つので、この節の手順 3 の値は効かない（この節の手順 5 の画面で、そのプロファイルを変える）
   - `中断:` が出たら、何も書いていない。この節の手順 5 の画面で変える
   - `Version` が 1.24 より前なら、この節の手順 4 は飛ばす

1. 全プロファイルのフォントを HackGen Console NF にする。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     if (-not (Test-Path -LiteralPath "$path.windows-setup.bak")) { Write-Error '中断: 控えが無い。この節の手順 2 を先に貼る'; return }
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
   - フォントが見つからないと、端末に、フォントが見つからない旨が出て、別のフォントで出る（この節の手順 5 で確かめる）

1. Windows Terminal が 1.24 以降で、複数行を貼るたびに出る警告を出さないときだけ、警告を切る。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     $ver = (Get-AppxPackage -Name Microsoft.WindowsTerminal | Select-Object -First 1).Version
     if (-not $ver -or [version]$ver -lt [version]'1.24') { Write-Error "中断: Windows Terminal の版が 1.24 より前: $ver"; return }
     if (-not (Test-Path -LiteralPath "$path.windows-setup.bak")) { Write-Error '中断: 控えが無い。この節の手順 2 を先に貼る'; return }
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
   - この節の手順 2〜4 が `中断:` で止まったときは、この画面でフォント スタイルを選んで「保存」を押す（一覧に無ければ「すべてのフォントの表示」をオン）。警告は「操作」の「改行を貼り付ける際に警告する」を「なし」にする
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
   - 控えた後に画面で変えた Windows Terminal の設定も、控えたときに戻る。残すなら、このブロックは貼らず、この節の手順 5 の画面でフォント スタイルと警告を戻す
   - `中断: 控えが無い` が出たら、この節の手順 5 の画面で戻す
   - 控えのファイルは消える（もう一度この節を通すと、そのときの設定を控え直す）

---

## WSL のネットワークをミラーにする（任意）

- WSL 2 のネットワークを、NAT から Windows と同じ IP を使うミラーに変える
- 前提: [WSL と再起動](#wsl-と再起動)の手順 1 と[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 3・4
- この節の手順 1 で開く通常の Windows PowerShell 5.1 に貼る。対象は自分の `%USERPROFILE%\.wslconfig`
- **この節の手順 4・7 の `wsl.exe --shutdown` は、動いているディストリビューションをすべて止める**（WezTerm の WSL のタブも切れる）。WSL の中の作業を保存してから貼る
- ミラーにして変わること
  - WSL からこの PC の Windows のサーバー（[OpenSSH サーバー](#openssh-サーバー)など）には、`127.0.0.1` でつなぐ（`::1` は使えない。LAN の IP あてはつながらないはず）
  - Windows が使っているポートは、WSL の中では使えない。Windows の sshd が 22 番で待っていると、WSL の中の sshd は 22 番を使えない
  - Docker のポートの公開と、一部の VPN には、既知の問題がある（[参考資料](reference/windows-setup.md)）
- 書くのは `networkingMode` だけ。DNS・ファイアウォール・プロキシ・メモリの値は既定のまま。LAN から WSL の中のサーバーに入るための Hyper-V のファイアウォールの規則は、この節では作らない
- 画面で変えるなら、スタートメニューの「Linux 用 Windows サブシステム設定」→「ネットワーク」→「ネットワーク モード」（同じファイルに書く）
- 戻すときは、この節の手順 6・7

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
   - 最後に、動いているディストリビューションが出る（無ければ、無い旨の行）。この節の手順 4 で止まる
   - 中身の `[wsl2]` に `networkingMode=mirrored` があれば、もうミラー。この節の手順 3 は飛ばす

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
   - 控えは `%USERPROFILE%\.wslconfig.windows-setup.bak`。ファイルがあって、控えが無いときだけ作る（この節の手順 6 で使い、戻すと消える）
   - `中断: networkingMode の行がもうある` が出たら、何も書いていない。その行を手で `networkingMode=mirrored` にするか、設定の画面で変える
   - 効くのは、この節の手順 4 で WSL を止めた後

1. WSL を止めて、ミラーで動くことを確かめる。

   ```powershell
   wsl.exe --shutdown
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   wsl.exe --distribution AlmaLinux-10 -- wslinfo --networking-mode
   ```

   - `mirrored` が出ればよい
   - `ミラー化されたネットワーク モードはサポートされていません` の行が出て `nat` なら、この PC ではミラーを使えない（理由はその行に出る）。この節の手順 6・7 で戻す
   - その行が無く `nat` なら、`.wslconfig` が読まれていない（この節の手順 2 で中身を確かめる）
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
       Write-Error "中断: この節で作った形ではない。networkingMode の行を手で消す: $path"
     }
   }
   ```

   - `控えから戻した:`（ファイルがあったとき）か `消した:`（この節で作ったとき）が出ればよい
   - 控えた後に設定の画面などで変えた値も、控えたときに戻る
   - `中断:` が出たら、`.wslconfig` をメモ帳で開き、`networkingMode=mirrored` の行を消して保存する
   - 効くのは、この節の手順 7 で WSL を止めた後

1. 元に戻すときは、WSL を止めて、NAT に戻ったことを確かめる。

   ```powershell
   wsl.exe --shutdown
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   wsl.exe --distribution AlmaLinux-10 -- wslinfo --networking-mode
   ```

   - `nat` が出ればよい
   - WSL から Windows のサーバーには、また LAN の IP あてにつなぐ

---

## OpenSSH サーバーに公開鍵でもログインする（任意）

- クライアントで作った鍵で、パスワードを入れずに入れるようにする。パスワード認証は有効のまま
- この節の手順 1・2・5 はクライアントの[SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 3 のシェルに、手順 3・4 は Windows の管理者の Windows PowerShell に貼る
- 登録できるのは、Administrators の一員のユーザーの鍵だけ（この節の手順 4 で確かめる。標準ユーザーは[注意点](extra/windows-setup.md#注意点)）
- 登録した鍵を持つ人も、パスワードを知る人と同じく、この PC の管理者として操作できる（[注意点](extra/windows-setup.md#注意点)）

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

   - `ssh-ed25519 AAAA… <USER>@<HOSTNAME>` の 1 行が出る。この 1 行をコピーし、この節の手順 3 で Windows に貼る
   - 公開鍵は秘密ではない。チャットやメールで Windows 側へ渡してもよい

1. Windows の管理者の PowerShell で、変数を設定する（`$PUBKEY` は必ず値を入れる）。

   ```powershell
   $PUBKEY = ''                          # ← この節の手順 2 の 1 行を '' の中に貼る。<PUBKEY>
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
     Write-Error 'この節の手順 3 の $PUBKEY が空か、公開鍵の形でない'
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
   - クライアントを足すときは、そのクライアントでこの節の手順 1・2 を行い、この節の手順 3 の `$PUBKEY` を貼り直してから、この節の手順 4 を貼る

1. クライアントの PC で、鍵で入れることを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: 「SSH でログインを確かめる」の手順 3 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh -o PasswordAuthentication=no "${WIN_USER}@${WIN_HOST}" whoami
   fi
   ```

   - パスワードを聞かれずに、`<hostname>\<win_user>` が出ればよい（パスフレーズを付けたなら、それを聞かれる）
   - 既定のシェルを Git Bash にした PC では、Git の `whoami` が動き、`<WIN_USER>` だけが出る

---

## OpenSSH サーバーのパスワード認証を切る（任意）

- 鍵を持たない相手からのパスワードを受け付けないようにする（パスワードの総当たりを受け付けない）
- 前提: [OpenSSH サーバーに公開鍵でもログインする（任意）](#openssh-サーバーに公開鍵でもログインする任意)を行い、使うクライアントが鍵で入れること。切った後は、鍵を登録していないクライアント（スマートフォンのアプリなど）からは入れない
- この節の手順 1 は Windows の管理者の Windows PowerShell に、手順 2 はクライアントの[SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 3 のシェルに貼る
- パスワード認証に戻すときは、[OpenSSH サーバー](#openssh-サーバー)の手順 4 を貼り直す

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
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: 「SSH でログインを確かめる」の手順 3 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh -o PubkeyAuthentication=no "${WIN_USER}@${WIN_HOST}" true
     ssh "${WIN_USER}@${WIN_HOST}" whoami
   fi
   ```

   - 1 つ目は、パスワードを聞かずに `<WIN_USER>@<WIN_HOST>: Permission denied (publickey,keyboard-interactive).` で失敗すればよい
   - 2 つ目は、`<hostname>\<win_user>` が出ればよい（パスフレーズを付けたなら、それを聞かれる）
     - 既定のシェルを Git Bash にした PC では、Git の `whoami` が動き、`<WIN_USER>` だけが出る

---

## SSH の既定のシェルを Git Bash にする（任意）

- SSH でログインしたとき・コマンドを実行するときのシェルを、cmd.exe から Git for Windows の bash に変える
- 前提: Git for Windows が `C:\Program Files\Git` に入っていること（[Git for Windows](#git-for-windows)）
- この節の手順 1・3 は Windows の管理者の Windows PowerShell に、手順 2 はクライアントの[SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 3 のシェルに貼る

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
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: 「SSH でログインを確かめる」の手順 3 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh "${WIN_USER}@${WIN_HOST}" 'echo "$BASH_VERSION $MSYSTEM"; git --version'
     ssh "${WIN_USER}@${WIN_HOST}"
   fi
   ```

   - 鍵を登録していなければ、パスワードを 2 回聞かれる
   - 1 つ目で `5.3.15(1)-release MINGW64` と `git version 2.55.0.windows.3` のような 2 行が出ればよい
   - 2 つ目は、`<WIN_USER>@<HOSTNAME> MINGW64 ~` と `$` のプロンプトになる。`exit` で戻る
   - **注意**: コマンドを実行するときも、Windows 側の `~/.bashrc` が読まれる
   - `Shim: Could not create process …` が出るなら、[scoop のツールを SSH のセッションで使う（任意）](#scoop-のツールを-ssh-のセッションで使う任意)を行う

1. 元に戻すときは、`DefaultShell` を消す。

   ```powershell
   Remove-ItemProperty -Path HKLM:\SOFTWARE\OpenSSH -Name DefaultShell
   ```

   - 何も出ずに終わればよい

---

## scoop のツールを SSH のセッションで使う（任意）

- scoop で入れたツール（`zoxide`・`rg`・`nvim` など）が、SSH のセッションでだけ起動しないときに行う
  - 症状は、scoop の shim の `Could not create process with command …`、Git Bash の `Is a directory`、Windows のエラー 448（信頼されていないマウントポイント）
- 原因は、sshd の緩和策 RedirectionGuard。管理者以外が作ったジャンクションを、SSH のセッションのプロセスはたどれない
  - scoop の `current` と persist のジャンクションは、一般ユーザーの scoop が作るので、この制限に当たる
- この節は、それらのジャンクションを、管理者の PowerShell で同じ向き先のまま作り直す（中身は変えない）
- 前提: scoop が `C:\Users\<WIN_USER>\scoop` に入っていること（[アプリを入れる](#アプリを入れる)の手順 1・2 で入れた形）
- この節の手順 1 は Windows の管理者の Windows PowerShell に、手順 2 はクライアントの[SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 3 のシェルに貼る
- `scoop install`・`scoop update` の後は、新しいジャンクションが一般ユーザーの作ったものになるので、この節の手順 1 を貼り直す

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
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: 「SSH でログインを確かめる」の手順 3 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh "${WIN_USER}@${WIN_HOST}" 'zoxide --version'
   fi
   ```

   - 鍵を登録していなければ、パスワードを聞かれる
   - `zoxide 0.9.9` のような版が出て、`Shim:` で始まる行が出なければよい（`zoxide` の代わりに、scoop で入れたほかのツールでもよい）

---

## Neovim を既定のエディタにする（任意）

- Windows PowerShell や Windows Terminal から起動するツール（lazygit の `e` キーなど）にも Neovim を使わせるなら、この節の手順 1 でユーザーの環境変数にする
- Git Bash（WezTerm の新しいタブ）では、共通の bash 設定が `EDITOR`・`VISUAL` を `nvim` にする（この節は要らない）
  - 確かめるときは、WezTerm の新しいタブで、[AlmaLinux 10 の初期設定の「Neovim」](almalinux-setup.md#neovim)の手順 4 のブロックを貼る（`. ~/.bashrc` は読み直さない）
- この節のブロックは、[Neovim](#neovim)と同じ管理者ではない Windows PowerShell（5.1）に貼る

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

---

## 更新

- OS・Store の更新は[Windows Update](#windows-update)（管理者）・[Microsoft Store の更新](#microsoft-store-の更新)（通常）を通す。再起動は手動で行う
- この節は通常の Windows PowerShell 5.1 に貼る。[Git for Windows・Firefox・WezTerm を上げる](#git-for-windowsfirefoxwezterm-を上げる)だけは管理者の窓に貼る
- scoop・winget で入れたアプリは、入れた方法で上げる
  - zoxide は 0.9.9 に固定中。[scoop・winget・WSL を上げる](#scoopwingetwsl-を上げる)の手順 6 で修正版を確かめ、手順 7 で上げる
  - 上げても、git の設定（`~/.gitconfig`）と gh のログイン（資格情報マネージャーと `%APPDATA%\GitHub CLI`）は変わらない
- Firefox・Claude Code・Codex・Grok Build は、自分で新しい版に上がる。待たずに上げるときだけ、それぞれの手順を行う
  - Firefox は起動中に取得し、次の起動時に更新する。起動後に作られる `\Mozilla\Firefox Background Update <番号>` のタスクも、7 時間ごとに更新する
  - Firefox の更新は Mozilla Maintenance Service が書き込み、UAC は出ない。日本語版に言語パックを足すと、閉じている間の更新が止まるので使わない
  - Claude Code は起動時・起動中に更新を取得し、次の起動から新しい版になる。追うチャンネルは[Claude Code](#claude-code)の手順 1 で選ぶ
  - Codex は、起動したときに `Update available!` と出たら、`1. Update now` のまま Enter を押すと上がる（Windows 用の公式インストーラーが動く）
  - Grok Build は、対話の画面（`grok`）を起動したときに新しい版を確かめ、自分で上がる
- WezTerm は自分では更新しない。nightly の新しい版が出ても知らせない（WezTerm の更新の確認が見るのは stable のリリースだけで、nightly の版の方が新しいので何も出ない）
  - [Git for Windows・Firefox・WezTerm を上げる](#git-for-windowsfirefoxwezterm-を上げる)の手順 1・5〜7 で、設定を残して `C:\Program Files\WezTerm` に上書きする
  - nightly は毎日ビルドし直される。版は main の最後のコミットで決まり、コミットの無い日は同じ版になる
- フォントは[HackGen Console NF を上げる](#hackgen-console-nf-を上げる)に従い、この文書の版と sha256 を確かめて直してから入れ直す
- 共通の bash 設定は、WezTerm のタブ（Git Bash）で[AlmaLinux 10 の初期設定の更新](almalinux-setup.md#更新)の手順 1 を貼って上げる
- 自分用の設定（WezTerm・Neovim・lazygit・yazi）は、それぞれのリポジトリの更新で上げる
  - yazi の自分用の設定は上流の版に合わせてある。yazi の版が上がったら、その [README の「上流の新しい版に追従する」](https://github.com/ryo-aoki-pc/yazi#上流の新しい版に追従する)で設定も追う
- SSH で scoop のツールを使うなら、更新後に[scoop のツールを SSH のセッションで使う](#scoop-のツールを-ssh-のセッションで使う任意)の手順 1 を管理者の窓に貼り直す
- UniGet UI の画面からも、scoop と winget のパッケージをまとめて上げられる（UniGet UI と PowerToys は、自分でも新しい版を確かめる）
- CopyQ は、更新のインストーラが閉じた後に起動し直さないことがある。通知領域にアイコンが無ければ、スタートメニューの「CopyQ」から起動する
- Windows の大きな更新（機能の更新）の後は、外したアプリと切った提案が戻ることがある。[表示と入力](#表示と入力)の手順 3 と[自動起動と標準アプリ](#自動起動と標準アプリ)の手順 1〜3 を貼り直す
- 機能更新後は、プライバシー・表示／入力／音／ストレージ・Edge の任意設定も確認する。戻っていれば、その節の「元に戻すときは、」より前を貼り直す（控えは書き換えない）
- VirtualBox・WireGuard は、それぞれの手順書の「Windows 11 の更新」
  - [SSH クライアント（Windows）](#windows-の-openssh-クライアント-更新)は「更新」、[Samba の共有のネットワーク ドライブ](#samba-クライアント-windows-11-の更新)は「Windows 11 の更新」（どちらも、上げるものは無い）

### scoop・winget・WSL を上げる

1. scoop とバケットを上げ、古くなったものを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop update
   scoop status
   ```

   - `scoop update` は `Scoop was updated successfully!` を出す
   - git が無いと `Scoop uses Git to update itself. Run 'scoop install git' and try again.` で止まる。先に [Git for Windows](#git-for-windows)で Git for Windows を入れる
   - `scoop status` は、古いものがあれば名前と版を並べる。`Everything is ok!` なら、この項の手順 2 は飛ばす

1. 古いものがあるときだけ、scoop で入れたものを上げる。

   ```powershell
   scoop update *
   ```

   - アプリごとに `'<名前>' (<版>) was installed successfully!` の形の行が出る
   - 動いているアプリは `Running process detected, skip updating.` で飛ばされる。閉じてから貼り直す
   - SSH のセッションで scoop のツールを使っているなら、[scoop のツールを SSH のセッションで使う（任意）](#scoop-のツールを-ssh-のセッションで使う任意)の手順 1 を、管理者の PowerShell で貼り直す
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
   - 無ければ、この項の手順 7 は飛ばす（0.9.9 のまま使う）
   - **次の手順は、管理者ではない Windows PowerShell（5.1）に貼る**

1. Git Bash の記録を直した版が出ているときだけ、zoxide を止めるのをやめて上げる。

   ```powershell
   & {
     scoop update
     $v = (Get-Content -LiteralPath "$env:USERPROFILE\scoop\buckets\main\bucket\zoxide.json" -Raw | ConvertFrom-Json).version
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($v -notmatch '^\d+\.\d+\.\d+$' -or [version]$v -le [version]'0.10.0') { Write-Error "中断: scoop の main のバケットの zoxide はまだ $v。日を置いて、「scoop・winget・WSL を上げる」の手順 6 から"; return }
     scoop unhold zoxide
     scoop update zoxide --force
     zoxide --version
   }
   ```

   - `zoxide is no longer held and can be updated again.` と、`'zoxide' (<版>) was installed successfully!` が出て、最後に新しい版が出ればよい
   - `中断:` が出たら、Releases に出た版が、まだ scoop の main のバケットに入っていない。zoxide は何も変えていない（0.9.9 に止めたまま）
   - `Running process detected, skip updating.` が出たら、上がっていない。Git Bash で開いている `zi` の一覧などを閉じてから、このブロックを貼り直す
   - WezTerm の新しいタブで、[AlmaLinux 10 の初期設定の「シェルのツール」](almalinux-setup.md#シェルのツール)の手順 9・10 を貼って確かめ直す（Windows との違いは、[シェルのツールを入れる](#シェルのツールを入れる)の手順 6 の箇条書き）

### AI エージェントとプラグインを上げる

1. Claude Code をすぐに上げる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   claude update
   claude --version
   ```

   - 新しい版があれば `Successfully updated from <古い版> to version <新しい版>`、無ければ `Claude Code is up to date (2.1.288)` のように出る
   - 更新の後に `claude` が見つからなくなったら、[注意点](extra/windows-setup.md#注意点)の `claude.exe.old.*` の項を見る

1. 起動中の Codex と Grok を終了する。

   - 端末の Codex と Grok は `/quit` で閉じる
   - 知らせを待たずに上げるときだけ、この項の手順 2〜4 を行う

1. 公式インストーラーをもう一度実行して、Codex CLI を上げる。

   ```powershell
   & ([scriptblock]::Create((Invoke-RestMethod -Uri 'https://chatgpt.com/codex/install.ps1')))
   ```

   - `Start Codex now?` は `n` で答える
   - **次の手順は、PowerShell のプロンプトに戻ってから貼る**
   - 上げた後の版は、`codex --version` で確かめる

1. Grok Build の新しい版を入れ、版を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   grok update
   grok --version
   ```

   - 新しい版が無ければ `Already up to date (…)` と出る

1. 2 つのプラグインのマーケットプレイスとプラグインを上げる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   claude plugin marketplace update openai-codex
   claude plugin marketplace update xai-grok-build
   claude plugin update codex@openai-codex
   claude plugin update grok-build@xai-grok-build
   claude plugin list
   ```

   - 見方は、[AlmaLinux 10 の初期設定の更新](almalinux-setup.md#更新)の手順 9 と同じ

### HackGen Console NF を上げる

1. HackGen の新しい版が出ているかを確かめる。

   ```powershell
   (Invoke-RestMethod -Uri https://api.github.com/repos/yuru7/HackGen/releases/latest).tag_name
   ```

   - `v2.10.0` なら、新しい版は無い。この項の手順 2 は行わない
   - 違う版なら、[HackGen Console NF](#hackgen-console-nf)の手順 2 の `$ver` と `$sha256` を、その版の zip と、その zip から計算して確認したハッシュ値に合わせて直してから貼る

1. 新しい版にするときだけ、今の版を外してから入れ直す。

   - [ロールバックの「HackGen Console NF を消す」](extra/windows-setup.md#hackgen-console-nf-を消す)の手順 1〜3（登録を消し、サインインし直してから、ファイルを消す）を行う
   - 続けて、直した[HackGen Console NF](#hackgen-console-nf)の手順 2 を貼り、サインアウトしてサインインし直してから、[再起動の後に確かめる](#再起動の後に確かめる)の手順 5 で確かめる

### Git for Windows・Firefox・WezTerm を上げる

1. Remote Control のタスクを動かしているときだけ、先にタスクを止める。

   - [Claude Code の Remote Control の止める・もう一度始める](#claude-code-の-remote-control-止めるもう一度始める)の手順 1 を行う
   - タスクの Claude Code と WezTerm（中のシェルは Git Bash）は、Git for Windows と WezTerm を上げる間は止めておく。上げた後に、この項の手順 7 で始め直す

1. Git Bash と WezTerm を閉じてから、winget で Git for Windows を上げる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget upgrade --exact --id Git.Git --source winget --accept-source-agreements --accept-package-agreements
   winget list --exact --id Git.Git --source winget
   ```

   - 上がったら `インストールが完了しました` と出て、`winget list` の `Git.Git` の版が新しくなる
   - 新しい版が無ければ、`利用可能なアップグレードが見つかりませんでした。`（英語の Windows では `No available upgrade found.`）と出る
   - **注意**: Git Bash・WezTerm のタブ（自分用の設定では Git Bash）や、Git の bash を使う SSH のセッション・Claude Code が動いていると、インストーラは入れ替えずに終わるはず
   - 上げた後は、Git Bash を開き直し、[AlmaLinux 10 の初期設定の「Git」](almalinux-setup.md#git)の手順 6 を貼り直す（`pull.ff` が `only` なら同じ項の手順 7 も）

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

1. [WezTerm](#wezterm)の手順 3 のブロックを貼る。

   - 最後に出る `wezterm <版>` が、この項の手順 5 の版より新しければ上がった
   - 同じ版なら、main に新しいコミットが無かった（同じ版を入れ直しただけ）

1. この項の手順 1 でタスクを止めたときだけ、タスクを始め直す。

   - [Claude Code の Remote Control の止める・もう一度始める](#claude-code-の-remote-control-止めるもう一度始める)の手順 2 を行う

---

## コーディングエージェントの共同作業（任意）

- この節だけを実施するときは、各項の前提・実行場所・権限を先に確認する
- [検証記録](verification/coding-agents.md)・[参考資料](reference/coding-agents.md)・[ロールバックと注意点](extra/coding-agents.md)

### コーディングエージェントの共同作業: Windows 11 で使う

> [!IMPORTANT]
> - 自分のユーザーの **管理者ではない Windows PowerShell 5.1** で行う
> - 前提: [Git for Windows](#git-for-windows)・[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)を通してある
> - [Claude Code](#claude-code)から[Codex・Grok のプラグイン](#codexgrok-のプラグイン)までも通してある
> - 3 つのエージェントにログイン済み。[貼り付けの設定](#貼り付けの設定)の手順 1〜4 と[アプリを入れる](#アプリを入れる)の手順 1・2（scoop）も必要
> - リモートがあるなら、push の認証と PR を作る道具も必要。GitHub は[GitHub CLI](#github-cli)でログインしておく
> - **この項の手順 9 には対話入力がある**（Claude Code の画面でのフォルダーの信頼と、2 つのプラグインの確かめ）

- 上から順に貼る。手順 1 で変数を設定した PowerShell に貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 手順の後は、両 OS 共通の[使い方の基本](almalinux-setup.md#コーディングエージェントの共同作業-使い方の基本)から、分担・レビュー・取り込み・スマートフォンでの操作へ進む
- 書くファイル（AGENTS.md・CLAUDE.md）は、BOM の無い UTF-8 と LF の改行にする（AlmaLinux 10 で書いたものと同じ形）

1. 変数を設定する（`PROJECT_DIR` は必ず値を入れる）。

   ```powershell
   $PROJECT_DIR = ''                     # ← 共同作業させるリポジトリ（git のルート）の絶対パスを書く。<PROJECT_DIR>
   ```

   ```powershell
   $WT_ROOT = if ($PROJECT_DIR) { $PROJECT_DIR.TrimEnd('\') + '.worktrees' }   # 3 つの worktree を置くディレクトリ（プロジェクトの隣）。<WT_ROOT>
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'PROJECT_DIR = {0}' -f $PROJECT_DIR
   'WT_ROOT     = {0}' -f $WT_ROOT
   ```

   - 最後に値を読み戻して確かめる
   - `PROJECT_DIR` は、`C:\Users\<WIN_USER>\src\myproject` のような、git のリポジトリのルートの絶対パス
   - **新しい PowerShell を開いたら**、この 2 つのブロックを貼り直してから先へ進む

1. 3 つの CLI の版とログインを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   claude --version
   codex --version
   grok --version
   codex login status
   grok models
   claude auth status --text
   ```

   - 確かめることは、[実施手順](almalinux-setup.md#コーディングエージェントの共同作業-実施手順)の手順 2 と同じ

1. プロジェクトの状態と、すでにある指示書を確かめる。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: 手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     git -C $PROJECT_DIR rev-parse --show-toplevel
     git -C $PROJECT_DIR status --short --branch
     Get-ChildItem -LiteralPath $PROJECT_DIR -Force -Name | Where-Object { $_ -in 'AGENTS.md', 'AGENTS.override.md', 'CLAUDE.md', 'CLAUDE.local.md' }
     Test-Path -LiteralPath $WT_ROOT
   }
   ```

   - 1 行目は `C:/Users/<WIN_USER>/src/myproject` のように `/` で出る（`PROJECT_DIR` と同じ場所ならよい）
   - 2 行目以降と指示書のファイルの名前の見方は、[実施手順](almalinux-setup.md#コーディングエージェントの共同作業-実施手順)の手順 3 と同じ
   - 最後に `False` が出ればよい

1. AGENTS.md に共同作業の規則を足す（無ければ作る）。

   ```powershell
   & {
     if (-not $PROJECT_DIR) { Write-Error '中断: 手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す'; return }
     $path = Join-Path $PROJECT_DIR 'AGENTS.md'
     $old = if (Test-Path -LiteralPath $path) { [IO.File]::ReadAllText($path) } else { '' }
     if ($old -match '(?m)^## 共同作業の規則\r?$') { Write-Error '中断: AGENTS.md に「## 共同作業の規則」がもうある。中身を確かめる'; return }
     $text = @'
   ## 共同作業の規則

   このリポジトリでは、Claude Code・Codex・Grok Build が同じ規則で作業する。分担と `main` への取り込みは人が決める。

   - 起動された worktree（作業ディレクトリ）の中だけでファイルを変える。ほかの worktree のファイルは変えない
   - 今のブランチにだけコミットする。`main` にはコミットも push もしない
   - 頼まれた範囲のファイルだけを変える。範囲の外を変えるときは、変える前に理由を書いて確かめる
   - 終わったら、テストとリンターを通してから、目的ごとにコミットする。通らなければコミットせずに、結果を報告する
   - コミットしたら、リモートがあれば今のブランチを push し、`main` への Pull Request を作る（既にあれば足す）。`main` への取り込み（マージ）とブランチの削除は人が行う。今のブランチに `main` を取り込むのは、頼まれたときと、Pull Request が競合したときだけ
   - 秘密情報（`.env`・鍵・トークン・パスワード）を読まない・書かない・出力しない
   - レビューを頼まれたら、ファイルを変えずに、指摘を「重大度・場所（ファイル:行）・理由・直し方」で挙げる
   - ほかの担当の変更は、`git diff main...agent/codex` のように git で読む（ほかの worktree へ移らない）
   '@
     $prefix = if ($old.Length -eq 0) { '' } elseif ($old.EndsWith("`n")) { "`n" } else { "`n`n" }
     [IO.File]::AppendAllText($path, $prefix + ($text -replace "`r`n", "`n") + "`n", (New-Object Text.UTF8Encoding $false))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-Content -LiteralPath $path -Encoding UTF8
   }
   ```

   - AGENTS.md の中身が出て、最後に「## 共同作業の規則」の節がある
   - `中断:` が出たら、何も書いていない

1. CLAUDE.md に `@AGENTS.md` の 1 行を足す（無ければ作る）。

   ```powershell
   & {
     if (-not $PROJECT_DIR) { Write-Error '中断: 手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す'; return }
     $path = Join-Path $PROJECT_DIR 'CLAUDE.md'
     $old = if (Test-Path -LiteralPath $path) { [IO.File]::ReadAllText($path) } else { '' }
     if ($old -match '(?m)^@AGENTS\.md\r?$') { 'CLAUDE.md に @AGENTS.md はもうある'; return }
     $prefix = if ($old.Length -eq 0 -or $old.EndsWith("`n")) { '' } else { "`n" }
     [IO.File]::AppendAllText($path, $prefix + "@AGENTS.md`n", (New-Object Text.UTF8Encoding $false))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-Content -LiteralPath $path -Encoding UTF8 | Select-Object -Last 3
   }
   ```

   - 最後の行に `@AGENTS.md` が出る

1. 2 つのファイルを `main` にコミットする。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: 手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     git -C $PROJECT_DIR add AGENTS.md CLAUDE.md
     git -C $PROJECT_DIR commit -m 'Claude Code・Codex・Grok Build の共同作業の規則を足す'
     git -C $PROJECT_DIR log --oneline -1
   }
   ```

   - 見方は、[実施手順](almalinux-setup.md#コーディングエージェントの共同作業-実施手順)の手順 6 と同じ

1. 3 つの worktree とブランチを作る。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: 手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($a in 'claude', 'codex', 'grok') { git -C $PROJECT_DIR worktree add -b "agent/$a" "$WT_ROOT\$a" main }
     git -C $PROJECT_DIR worktree list
   }
   ```

   - 見方は、[実施手順](almalinux-setup.md#コーディングエージェントの共同作業-実施手順)の手順 7 と同じ

1. 3 つが規則を読むことを確かめる。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: 手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Push-Location -LiteralPath "$WT_ROOT\claude"; claude -p --permission-mode plan 'ファイルやツールを使わずに、読み込まれている指示だけから答えて: 共同作業の規則で、ファイルを変えてよい場所はどこか。1 行で'; Pop-Location
     codex exec -C "$WT_ROOT\codex" 'ファイルやツールを使わずに、読み込まれている指示だけから答えて: 共同作業の規則で、ファイルを変えてよい場所はどこか。1 行で'
     Push-Location -LiteralPath "$WT_ROOT\grok"; grok --trust inspect | Select-String -SimpleMatch -Pattern 'Project trusted', 'AGENTS.md', 'CLAUDE.md'; Pop-Location
   }
   ```

   - 見方は、[実施手順](almalinux-setup.md#コーディングエージェントの共同作業-実施手順)の手順 8 と同じ
   - 日本語の答えが化けて読めなければ、`[Console]::OutputEncoding = [Text.Encoding]::UTF8` を貼ってから、このブロックを貼り直す

1. Claude の worktree で Claude Code を起動し、2 つのプラグインの準備を確かめる。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: 手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else { Set-Location -LiteralPath "$WT_ROOT\claude"; claude }
   ```

   - 確かめることは、[実施手順](almalinux-setup.md#コーディングエージェントの共同作業-実施手順)の手順 9 と同じ
   - `/codex:setup` が `node` を見つけられなければ、Git for Windows の入れ直しか、[Windows 11 の初期設定の「Codex・Grok のプラグイン」](#codexgrok-のプラグイン)の手順 1・2 を確かめる
   - **後ろの節のコマンドは、Claude Code を終えて PowerShell のプロンプトに戻ってから貼る**

---

### コーディングエージェントの共同作業: Windows 11 の更新

- CLI と 2 つのプラグインは[AI エージェントとプラグインを上げる](#ai-エージェントとプラグインを上げる)、Node.js は[scoop・winget・WSL を上げる](#scoopwingetwsl-を上げる)の手順 1・2 で上げる
- 規則を変えたときは、AlmaLinux 10 と同じく[main に取り込む](almalinux-setup.md#コーディングエージェントの共同作業-main-に取り込む)の手順 7 で各 worktree をそろえる


---

## Grok Build のブラウザ操作（任意）

- この節だけを実施するときは、各項の前提・実行場所・権限を先に確認する
- [検証記録](verification/grok-build-remote.md)・[参考資料](reference/grok-build-remote.md)・[ロールバックと注意点](extra/grok-build-remote.md)

### Grok Build のブラウザ操作: Windows 11 で使う

> [!IMPORTANT]
> - **Windows のデスクトップで行う**。[Codeg を入れる](#grok-build-のブラウザ操作-windows-11-で-codeg-のサーバーを入れて起動する)の手順 1 で開く **管理者ではない Windows PowerShell 5.1** に貼る
> - [HTTPS で公開する](#grok-build-のブラウザ操作-windows-11-で-https-で-lanvpn-に公開する)の手順 3 だけは、管理者の窓に貼る
> - **SSH でログインしたシェルには貼らない**。Administrators の一員の SSH のセッションは管理者の権限を持つので、そこから始めると Codeg と Grok Build が管理者の権限で動く
> - 前提: [貼り付けの設定](#貼り付けの設定)の手順 1〜4、[Grok Build](#grok-build)の導入・ログイン、[Codex・Grok のプラグイン](#codexgrok-のプラグイン)の Node.js
> - 拠点ごとに[ネットワークとリモート](#ネットワークとリモート)の手順 1 で LAN をプライベートにする
> - Codeg は、管理者ではない自分のユーザーとして、サインインしている間だけ動く（この節のタスク）
> - PC の IPv4 は、固定でなくてよい（ノート PC を、拠点ごとに違う有線 LAN につなぐ使い方を含む）。届くのは、プライベートにした有線 LAN からだけ
> - スマートフォンから使うときは、スマートフォンを [WireGuard VPN の「クライアントを登録する」](almalinux-setup.md#wireguard-クライアントを登録する)でクライアントにしておく
> - [Windows 11 で HTTPS で LAN・VPN に公開する](#grok-build-のブラウザ操作-windows-11-で-https-で-lanvpn-に公開する)の手順 5 は LAN の別の端末で、手順 6・8 はスマートフォンと PC で行う

- 上から順にコードブロックを貼る。[Windows 11 で Codeg のサーバーを入れて起動する](#grok-build-のブラウザ操作-windows-11-で-codeg-のサーバーを入れて起動する)の手順 2 で変数を設定した PowerShell に貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 通信は HTTPS。AlmaLinux 10 と同じく、Caddy を同じ PC に置いて、Codeg へ渡す
- Windows 11 では、Caddy が待ち受ける IP を決めない。届く範囲は、受信の規則（プライベートのネットワーク・有線・送信元）で絞る
- 手順後は[端末にルート証明書を入れる](almalinux-setup.md#grok-build-のブラウザ操作-端末にルート証明書を入れる)へ進む
- 画面の操作とセッションの取り込みは、AlmaLinux と共通の[使い方の基本](almalinux-setup.md#grok-build-のブラウザ操作-使い方の基本)から行う

> [!WARNING]
> **アクセストークンを知っている人は、ブラウザからこの PC で、このユーザーとして Grok Build を動かせる**（ファイルの読み書きとコマンドの実行）。Windows の Grok Build には sandbox が無い。受信の規則でネットワークと送信元を絞り、トークンは人に見せない。**Grok の権限モードが「常に許可」だと、送った指示は確認なしで実行される**（[注意点](extra/grok-build-remote.md#注意点)）。

#### Grok Build のブラウザ操作: Windows 11 で Codeg のサーバーを入れて起動する

1. Windows で、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」をそのまま開く（「管理者として実行」にしない）
   - PowerShell 7（`pwsh`）ではなく、Windows PowerShell 5.1 にする

1. 変数を設定する（`$ALLOW_FROM` は必ず値を入れる）。

   ```powershell
   $ALLOW_FROM = @()                     # 許可する送信元 IPv4 の CIDR（例: '10.0.2.0/24', '192.168.1.0/24'）。<ALLOW_FROM>
   ```

   ```powershell
   $CODEG_VERSION = 'v0.35.1'            # 入れる Codeg の版（GitHub のリリースのタグ）
   $CADDY_VERSION = '2.11.7'             # 入れる Caddy の版（v を付けない）
   $CODEG_DIR = "$env:LOCALAPPDATA\codeg-server"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'ALLOW_FROM    = {0}' -f ($ALLOW_FROM -join ', ')
   'CODEG_VERSION = {0}' -f $CODEG_VERSION
   'CADDY_VERSION = {0}' -f $CADDY_VERSION
   'CODEG_DIR     = {0}' -f $CODEG_DIR
   ```

   - `ALLOW_FROM` は、この PC から見えるクライアントの送信元に合わせる。VPN のクライアントの帯と LAN の帯を、`,` で区切って並べられる
   - PC を複数の拠点で使うなら、それぞれの拠点の LAN の帯を入れる
   - `CODEG_VERSION` は[Codeg のリリース](https://github.com/spacering-net/codeg/releases)で新しい版を確かめて変える
   - `CADDY_VERSION` は[Caddy のリリース](https://github.com/caddyserver/caddy/releases)で新しい版を確かめて変える
   - 空のままなら先へ進まない
   - **新しい PowerShell を開いたら**、この項の手順 2 のブロックを貼り直してから先へ進む

1. Grok Build・Node.js・LAN の接続と、Codeg がまだ無いことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   grok --version
   node --version
   ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
   Get-NetConnectionProfile | Format-Table InterfaceAlias, NetworkCategory -AutoSize
   Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -eq 3443 -or ($_.LocalPort -ge 3080 -and $_.LocalPort -le 3090) } | Format-Table LocalAddress, LocalPort, OwningProcess -AutoSize
   Test-Path $CODEG_DIR, "$env:APPDATA\codeg", "$env:LOCALAPPDATA\codeg-caddy"
   Get-ScheduledTask -TaskName 'codeg-server', 'codeg-caddy' -ErrorAction SilentlyContinue | Format-Table TaskName, State
   ```

   - `grok` と `node` の版、`False`（管理者ではない）、LAN の接続の `Private` が出ればよい
   - その後は、待ち受けの表が出ず、`False` が 3 行出て、タスクの表も出なければよい
   - 最初の `False` が `True` なら、管理者の窓で開いている。この項の手順 1 からやり直す
   - `Public` なら、[Windows 11 の初期設定の「ネットワークとリモート」の手順 1](#ネットワークとリモート)を通す
   - 待ち受け・`True`・タスクのどれかが出たら、既存の構築がある。[Windows 11 のロールバック](extra/grok-build-remote.md#windows-11-のロールバック)で消してからやり直す

1. 配布物を取得して SHA-256 を照合し、自分のユーザーの場所に置く。

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $curl = "$env:WINDIR\System32\curl.exe"
     $tmp = "$env:TEMP\codeg-server-setup"
     if (-not $CODEG_VERSION -or -not $CODEG_DIR) { Write-Error '中断: この項の手順 2 の変数を設定する'; return }
     if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') { Write-Error "中断: この手順は $env:PROCESSOR_ARCHITECTURE の Windows を扱わない"; return }
     if (Test-Path -LiteralPath $CODEG_DIR) { Write-Error "中断: $CODEG_DIR が既にある。上書きしない"; return }
     if (Test-Path -LiteralPath $tmp) { Write-Error "中断: $tmp が既にある。中を確かめて消してから貼り直す"; return }
     New-Item -ItemType Directory -Path $tmp | Out-Null
     $url = "https://github.com/spacering-net/codeg/releases/download/$CODEG_VERSION/codeg-server-windows-x64.zip"
     & $curl -fsSL -o "$tmp\codeg-server-windows-x64.zip" $url
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: zip を取れない'; return }
     & $curl -fsSL -o "$tmp\codeg-server-windows-x64.zip.sha256" "$url.sha256"
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: .sha256 を取れない'; return }
     $want = ((Get-Content -LiteralPath "$tmp\codeg-server-windows-x64.zip.sha256" -Raw) -split '\s+')[0]
     if ((Get-FileHash -LiteralPath "$tmp\codeg-server-windows-x64.zip" -Algorithm SHA256).Hash -ne $want) { Write-Error '中断: sha256 が一致しない'; return }
     Expand-Archive -LiteralPath "$tmp\codeg-server-windows-x64.zip" -DestinationPath $tmp
     New-Item -ItemType Directory -Path $CODEG_DIR | Out-Null
     Copy-Item -LiteralPath "$tmp\codeg-server-windows-x64\codeg-server.exe", "$tmp\codeg-server-windows-x64\codeg-mcp.exe" -Destination $CODEG_DIR
     Copy-Item -LiteralPath "$tmp\codeg-server-windows-x64\web" -Destination $CODEG_DIR -Recurse
     Remove-Item -LiteralPath $tmp -Recurse -Force
     'sha256 一致'
     & "$CODEG_DIR\codeg-server.exe" --version
     Get-ChildItem $CODEG_DIR | Format-Table Mode, Name, Length -AutoSize
   }
   ```

   - `sha256 一致`、`CODEG_VERSION` と同じ番号（先頭の `v` は付かない）、`web`・`codeg-mcp.exe`・`codeg-server.exe` が出ればよい
   - 実行ファイルに Authenticode の署名は無い。SHA-256 の照合だけで確かめる
   - 配布物の `codeg-computer-helper.exe` は置かない。PATH は変えない

1. アクセストークンを作る。

   ```powershell
   $f = Join-Path $env:LOCALAPPDATA 'codeg-server\token.txt'
   if (Test-Path -LiteralPath $f) { Write-Error '中断: token.txt が既にある。作り直さない' } else {
     $b = New-Object byte[] 32
     [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b)
     [IO.File]::WriteAllText($f, (-join ($b | ForEach-Object { $_.ToString('x2') })))
     $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
     icacls $f /inheritance:r /grant:r "*${sid}:(M)" | Out-Null
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'token.txt: {0} 文字' -f (Get-Content -LiteralPath $f -Raw).Length
     icacls $f
   }
   ```

   - `token.txt: 64 文字` と、自分のユーザーだけの行（`(M)`）が出ればよい
   - **トークンの値は表示しない**

1. 起動用のスクリプトを書く。

   ```powershell
   if (-not $CODEG_DIR) { Write-Error '中断: この項の手順 2 の変数を設定する' } elseif (Test-Path -LiteralPath "$CODEG_DIR\start-codeg-server.ps1") { Write-Error '中断: start-codeg-server.ps1 が既にある。上書きしない' } else {
     [IO.File]::WriteAllText("$CODEG_DIR\start-codeg-server.ps1", @'
   # start-codeg-server.ps1 (setup-notes: grok-build-remote)
   # Starts codeg-server with the settings below. Refuses to start without a token file,
   # so that the server never generates a token by itself.
   $dir = Join-Path $env:LOCALAPPDATA 'codeg-server'
   $tokenFile = Join-Path $dir 'token.txt'
   if (-not (Test-Path -LiteralPath $tokenFile -PathType Leaf)) {
     [Console]::Error.WriteLine("abort: token file not found: $tokenFile"); exit 1
   }
   $token = (Get-Content -LiteralPath $tokenFile -Raw).Trim()
   if ($token.Length -lt 32) {
     [Console]::Error.WriteLine('abort: token is shorter than 32 characters'); exit 1
   }
   $env:CODEG_TOKEN = $token
   Remove-Variable token
   $env:CODEG_HOST = '127.0.0.1'
   $env:CODEG_PORT = '3080'
   $env:CODEG_STATIC_DIR = Join-Path $dir 'web'
   $env:CODEG_BRIDGE_PORTS = 'off'
   $env:CODEG_BROWSER_TUNNEL = 'off'
   & (Join-Path $dir 'codeg-server.exe')
   exit $LASTEXITCODE
   '@, (New-Object Text.ASCIIEncoding))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Select-String -LiteralPath "$CODEG_DIR\start-codeg-server.ps1" -Pattern 'CODEG_HOST' | ForEach-Object { $_.Line }
   }
   ```

   - `$env:CODEG_HOST = '127.0.0.1'` の行が出ればよい
   - スクリプトは、トークンのファイルが無いと起動しない。Codeg にトークンを作らせない

1. ウィンドウを作らないランチャーのソースを書き、コンパイルする。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     $dir = Join-Path $env:LOCALAPPDATA 'codeg-server'
     $cs = Join-Path $dir 'HiddenLauncher.cs'
     $exe = Join-Path $dir 'codeg-hidden-launcher.exe'
     $csc = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
     if (-not (Test-Path -LiteralPath "$dir\start-codeg-server.ps1")) { Write-Error '中断: 起動用のスクリプトが無い'; return }
     if ((Test-Path -LiteralPath $cs) -or (Test-Path -LiteralPath $exe)) { Write-Error '中断: ランチャーのソースか実行ファイルが既にある。上書きしない'; return }
     if (-not (Test-Path -LiteralPath $csc)) { Write-Error '中断: .NET Framework の csc.exe が無い'; return }
     [IO.File]::WriteAllText($cs, @'
   using System;
   using System.Diagnostics;
   using System.IO;

   internal static class HiddenLauncher
   {
       [STAThread]
       private static int Main(string[] args)
       {
           if (args.Length != 1 || !File.Exists(args[0])) return 2;
           try
           {
               var info = new ProcessStartInfo();
               info.FileName = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), "WindowsPowerShell", "v1.0", "powershell.exe");
               info.Arguments = "-NoProfile -NonInteractive -WindowStyle Hidden -File \"" + args[0] + "\"";
               info.UseShellExecute = false;
               info.CreateNoWindow = true;
               info.RedirectStandardOutput = true;
               info.RedirectStandardError = true;
               using (var child = new Process())
               {
                   child.StartInfo = info;
                   child.OutputDataReceived += delegate(object sender, DataReceivedEventArgs e) { };
                   child.ErrorDataReceived += delegate(object sender, DataReceivedEventArgs e) { };
                   child.Start();
                   child.BeginOutputReadLine();
                   child.BeginErrorReadLine();
                   child.WaitForExit();
                   return child.ExitCode;
               }
           }
           catch { return 1; }
       }
   }
   '@, (New-Object Text.UTF8Encoding($true)))
     & $csc /nologo /target:winexe ("/out:" + $exe) $cs
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: コンパイルに失敗した'; return }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-Item -LiteralPath $cs, $exe | Select-Object Name, Length
   }
   ```

   - `HiddenLauncher.cs` と `codeg-hidden-launcher.exe` の 2 行が出ればよい
   - 失敗した場合は、この手順が作ったソースだけを消し、原因を直してから貼り直す

1. タスクを登録して開始し、localhost の待ち受けを確かめる。

   ```powershell
   if (-not $CODEG_DIR) { Write-Error '中断: この項の手順 2 の変数を設定する' } elseif (Get-ScheduledTask -TaskName 'codeg-server' -ErrorAction SilentlyContinue) { Write-Error '中断: codeg-server のタスクが既にある' } else {
     $me = [Security.Principal.WindowsIdentity]::GetCurrent().Name
     $launcher = Join-Path $CODEG_DIR 'codeg-hidden-launcher.exe'
     if (-not (Test-Path -LiteralPath $launcher)) { Write-Error '中断: この項の手順 7 のランチャーが無い'; return }
     $action = New-ScheduledTaskAction -Execute $launcher -Argument ('"{0}"' -f "$CODEG_DIR\start-codeg-server.ps1")
     $principal = New-ScheduledTaskPrincipal -UserId $me -LogonType Interactive -RunLevel Limited
     $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
     $trigger = New-ScheduledTaskTrigger -AtLogOn -User $me
     Register-ScheduledTask -TaskName 'codeg-server' -Action $action -Principal $principal -Settings $settings -Trigger $trigger | Out-Null
     Start-ScheduledTask -TaskName 'codeg-server'
     for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 3080 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     (Get-ScheduledTask -TaskName 'codeg-server').State
     Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -ge 3080 -and $_.LocalPort -le 3090 } | Format-Table LocalAddress, LocalPort, OwningProcess -AutoSize
   }
   ```

   - `Running` と、`127.0.0.1` の 3080 の 1 行だけが出ればよい
   - タスクは、サインインのたびに自動で始まる
   - タスクが新しい Terminal のウィンドウを開かないことも確かめる
   - `Ready` のままで待ち受けが出ないときは、`powershell.exe -NoProfile -File "$CODEG_DIR\start-codeg-server.ps1"` をこの窓で実行して、表示されたエラーを見る（止めるときは Ctrl+C）
   - **その画面を人に見せない**。Codeg は、起動のたびに標準エラーへトークンを出す

1. トークン無しが拒まれることを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & "$env:WINDIR\System32\curl.exe" -s -o NUL -w "%{http_code}`n" -X POST http://127.0.0.1:3080/api/health
   $t = (Get-Content -LiteralPath "$CODEG_DIR\token.txt" -Raw).Trim()
   (Invoke-WebRequest -Uri 'http://127.0.0.1:3080/api/health' -Method Post -Headers @{ Authorization = "Bearer $t" } -UseBasicParsing).Content
   ((Get-CimInstance Win32_Process | ForEach-Object { [string]$_.CommandLine }) -join "`n").Contains($t)
   Remove-Variable t
   ```

   - 順に、`401`、`{"status":"ok","version":"…"}`、`False`（どのプロセスのコマンドラインにもトークンが無い）が出ればよい

1. この PC のブラウザで開き、トークンを入れて、Grok を動かす。

   - `notepad "$env:LOCALAPPDATA\codeg-server\token.txt"` でトークンを開いてコピーし、保存せずに閉じる
   - ブラウザで `http://127.0.0.1:3080/` を開き、「アクセストークン」に貼って「接続」を押す
   - [ブラウザで開いて Grok を動かす](almalinux-setup.md#grok-build-のブラウザ操作-ブラウザで開いて-grok-を動かす)の手順 4〜6 と同じ操作で、権限モードを確かめ、フォルダを開いて、指示を送る
   - Windows では、ファイルの変更の確認の見出しが「Write `<パス>`」になる
   - **次の手順は、ブラウザで Grok が応答してから貼る**

#### Grok Build のブラウザ操作: Windows 11 で HTTPS で LAN・VPN に公開する

1. Caddy の配布物を取得してチェックサムを照合し、自分のユーザーの場所に置く。

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $dir = "$env:LOCALAPPDATA\codeg-caddy"
     $curl = "$env:WINDIR\System32\curl.exe"
     $tmp = "$env:TEMP\codeg-caddy-setup"
     if (-not $CADDY_VERSION) { Write-Error '中断: 「Windows 11 で Codeg のサーバーを入れて起動する」の手順 2 の変数を設定する'; return }
     if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') { Write-Error "中断: この手順は $env:PROCESSOR_ARCHITECTURE の Windows を扱わない"; return }
     if (Test-Path -LiteralPath $dir) { Write-Error "中断: $dir が既にある。上書きしない"; return }
     if (Test-Path -LiteralPath $tmp) { Write-Error "中断: $tmp が既にある。中を確かめて消してから貼り直す"; return }
     $zip = "caddy_${CADDY_VERSION}_windows_amd64.zip"
     New-Item -ItemType Directory -Path $tmp | Out-Null
     & $curl -fsSL -o "$tmp\$zip" "https://github.com/caddyserver/caddy/releases/download/v$CADDY_VERSION/$zip"
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: zip を取れない'; return }
     & $curl -fsSL -o "$tmp\checksums.txt" "https://github.com/caddyserver/caddy/releases/download/v$CADDY_VERSION/caddy_${CADDY_VERSION}_checksums.txt"
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: チェックサムの一覧を取れない'; return }
     $m = Select-String -LiteralPath "$tmp\checksums.txt" -CaseSensitive -Pattern "^([0-9a-f]{128})  $([regex]::Escape($zip))$" | Select-Object -First 1
     if (-not $m) { Write-Error '中断: チェックサムの一覧に zip の行が無い'; return }
     if ((Get-FileHash -LiteralPath "$tmp\$zip" -Algorithm SHA512).Hash -ne $m.Matches[0].Groups[1].Value) { Write-Error '中断: sha512 が一致しない'; return }
     Expand-Archive -LiteralPath "$tmp\$zip" -DestinationPath "$tmp\x"
     New-Item -ItemType Directory -Path $dir | Out-Null
     Copy-Item -LiteralPath "$tmp\x\caddy.exe" -Destination $dir
     Remove-Item -LiteralPath $tmp -Recurse -Force
     'sha512 一致'
     & "$dir\caddy.exe" version
   }
   ```

   - `sha512 一致` と、`v` で始まる `CADDY_VERSION` と同じ番号が出ればよい
   - 実行ファイルに Authenticode の署名は無い。SHA-512 の照合だけで確かめる

1. Caddy の設定を書いて、検査する。

   ```powershell
   $cf = "$env:LOCALAPPDATA\codeg-caddy\Caddyfile"
   if (-not (Test-Path -LiteralPath "$env:LOCALAPPDATA\codeg-caddy\caddy.exe")) { Write-Error '中断: この項の手順 1 を通す' } elseif (Test-Path -LiteralPath $cf) { Write-Error '中断: Caddyfile が既にある。上書きしない' } else {
     [IO.File]::WriteAllText($cf, @"
   # setup-notes: grok-build-remote
   {
       admin off
       auto_https disable_redirects
       skip_install_trust
       pki {
           ca local {
               name "Codeg $env:COMPUTERNAME"
           }
       }
   }

   https://:3443 {
       tls internal {
           on_demand
       }
       handle /caddy-root.crt {
           root * "{`$APPDATA}/Caddy/pki/authorities/local"
           rewrite * /root.crt
           file_server
       }
       handle {
           reverse_proxy 127.0.0.1:3080
       }
   }
   "@, (New-Object Text.UTF8Encoding($false)))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     & "$env:LOCALAPPDATA\codeg-caddy\caddy.exe" validate --config $cf --adapter caddyfile 2>&1 | ForEach-Object { [string]$_ } | Select-Object -Last 1
   }
   ```

   - `Valid configuration` が出ればよい
   - Caddy は、この PC のすべてのアドレスの 3443 番で受け、同じ PC の Codeg（`127.0.0.1:3080`）へ渡す。Codeg の待ち受けは `127.0.0.1` のまま変えない
   - 待ち受ける IP は書かない。証明書は、接続された IP アドレスごとに、Caddy がその場で作る（`on_demand`）。PC の IP が変わっても、設定を変えずに使える
   - 届く範囲は、この項の手順 3 の受信の規則で絞る
   - 認証局の名前は `Codeg <PC の名前>` になる

1. 管理者の Windows PowerShell で、受信の規則を 3 本追加する。

   ```powershell
   $ALLOW_FROM = @()                     # 許可する送信元 IPv4 の CIDR（例: '10.0.2.0/24', '192.168.1.0/24'）。<ALLOW_FROM>
   ```

   ```powershell
   $exe = Join-Path $env:LOCALAPPDATA 'codeg-caddy\caddy.exe'
   if (-not $ALLOW_FROM) { Write-Error '中断: この手順の変数を設定する' } elseif (-not (Test-Path -LiteralPath $exe)) { Write-Error '中断: caddy.exe が無い（Codeg を入れたユーザーの管理者の窓で開く）' } elseif (Get-NetFirewallRule -Name 'codeg-caddy-in', 'codeg-caddy-block-public', 'codeg-caddy-block-wifi' -ErrorAction SilentlyContinue) { Write-Error '中断: 同じ名前の規則が既にある' } else {
     New-NetFirewallRule -Name 'codeg-caddy-in' -DisplayName 'Codeg (HTTPS)' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3443 -RemoteAddress $ALLOW_FROM -Profile Private -InterfaceType Wired -Program $exe | Out-Null
     New-NetFirewallRule -Name 'codeg-caddy-block-public' -DisplayName 'Codeg (HTTPS) block: public' -Direction Inbound -Action Block -Profile Public, Domain -Program $exe | Out-Null
     New-NetFirewallRule -Name 'codeg-caddy-block-wifi' -DisplayName 'Codeg (HTTPS) block: wireless' -Direction Inbound -Action Block -Profile Private -InterfaceType Wireless -Program $exe | Out-Null
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-NetFirewallRule -Name 'codeg-caddy-in', 'codeg-caddy-block-public', 'codeg-caddy-block-wifi' | Format-Table Name, Action, Profile, Enabled -AutoSize
     Get-NetFirewallRule -Name 'codeg-caddy-in' | Get-NetFirewallAddressFilter | Format-List RemoteAddress
     Get-NetFirewallRule -Name 'codeg-caddy-in' | Get-NetFirewallInterfaceTypeFilter | Format-List InterfaceType
     Get-NetFirewallRule -Name 'codeg-caddy-in' | Get-NetFirewallPortFilter | Format-List Protocol, LocalPort
   }
   ```

   - スタートメニューの「Windows PowerShell」を右クリック →「管理者として実行」で開いた窓に貼る
   - 変数は[Codeg を入れる](#grok-build-のブラウザ操作-windows-11-で-codeg-のサーバーを入れて起動する)の手順 2 と同じ値にする
   - `Allow` が 1 行と `Block` が 2 行、指定した `RemoteAddress`、`InterfaceType : Wired`、`LocalPort : 3443` が出ればよい
   - 通すのは、プライベートのネットワークの有線 LAN に、指定した送信元から届く 3443/tcp だけ。パブリックのネットワークと Wi-Fi は、`Block` の 2 本で遮断する
   - **規則は、この項の手順 4 より先に足す**。規則が無いまま Caddy が待ち受けると、Windows が許可を尋ねる画面を出し、そこで別の規則が作られる
   - 3080 番の規則は作らない。Codeg へは、Caddy を通してだけ届く
   - 貼り終えたら、管理者の窓は閉じる
   - **次の手順は、管理者ではない窓（変数を設定した PowerShell）に貼る**

1. Caddy のタスクを登録して開始し、この PC 自身から HTTPS を確かめる。

   ```powershell
   $cdir = "$env:LOCALAPPDATA\codeg-caddy"
   $root = "$env:APPDATA\Caddy\pki\authorities\local\root.crt"
   if (-not (Get-NetFirewallRule -Name 'codeg-caddy-in' -ErrorAction SilentlyContinue)) { Write-Error '中断: この項の手順 3 の規則が無い' } elseif (Get-ScheduledTask -TaskName 'codeg-caddy' -ErrorAction SilentlyContinue) { Write-Error '中断: codeg-caddy のタスクが既にある' } else {
     $me = [Security.Principal.WindowsIdentity]::GetCurrent().Name
     $launcher = Join-Path $env:LOCALAPPDATA 'codeg-server\codeg-hidden-launcher.exe'
     if (-not (Test-Path -LiteralPath $launcher)) { Write-Error '中断: ランチャーが無い'; return }
     $script = Join-Path $cdir 'start-caddy-hidden.ps1'
     if (Test-Path -LiteralPath $script) { Write-Error '中断: start-caddy-hidden.ps1 が既にある。上書きしない'; return }
     [IO.File]::WriteAllText($script, @'
   $dir = Join-Path $env:LOCALAPPDATA 'codeg-caddy'
   & (Join-Path $dir 'caddy.exe') run --config (Join-Path $dir 'Caddyfile') --adapter caddyfile
   exit $LASTEXITCODE
   '@, (New-Object Text.UTF8Encoding($true)))
     $action = New-ScheduledTaskAction -Execute $launcher -Argument ('"{0}"' -f $script)
     $principal = New-ScheduledTaskPrincipal -UserId $me -LogonType Interactive -RunLevel Limited
     $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
     $trigger = New-ScheduledTaskTrigger -AtLogOn -User $me
     Register-ScheduledTask -TaskName 'codeg-caddy' -Action $action -Principal $principal -Settings $settings -Trigger $trigger | Out-Null
     Start-ScheduledTask -TaskName 'codeg-caddy'
     for ($i = 0; $i -lt 30 -and -not ((Test-Path -LiteralPath $root) -and (Get-NetTCPConnection -State Listen -LocalPort 3443 -ErrorAction SilentlyContinue)); $i++) { Start-Sleep -Seconds 1 }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     (Get-ScheduledTask -TaskName 'codeg-caddy').State
     Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -in 3080, 3443 } | Sort-Object LocalPort, LocalAddress | Format-Table LocalAddress, LocalPort -AutoSize
     & "$env:WINDIR\System32\curl.exe" -s --cacert $root --ssl-no-revoke -o NUL -w "%{http_code}`n" -X POST "https://127.0.0.1:3443/api/health"
     Get-NetFirewallApplicationFilter -Program "$cdir\caddy.exe" | Get-NetFirewallRule | Format-Table Name, Action, Profile -AutoSize
     Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' -and $_.PhysicalMediaType -eq '802.3' } | Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | ForEach-Object { "https://$($_.IPAddress):3443" }
   }
   ```

   - `Running`、待ち受けが `127.0.0.1` の 3080 と `::` の 3443 の 2 行、`401`、規則が 3 本、最後に `https://<有線 LAN の IPv4>:3443` が出ればよい
   - `::` は、この PC のすべてのアドレス（IPv4 を含む）で待ち受けていることを示す
   - 最後の行が、ほかの端末からつなぐ URL。有線 LAN につながっていなければ出ない
   - タスクが新しい Terminal のウィンドウを開かないことも確かめる
   - 規則が 3 本より多く出たら、Windows が自動で作った規則がある。名前を確かめて外す
   - 認証局の鍵と証明書は、Caddy が初回の起動で `%APPDATA%\Caddy\` に作る。**`root.key` を、読まない・写さない・人に渡さない**

1. LAN の別の端末で、HTTPS で届くことを確かめる。

   - `ALLOW_FROM` に入っている端末で `curl -sk -o /dev/null -w '%{http_code}\n' https://<PC の IP>:3443/` を実行し、`200` が出ればよい（`-k` は、ルート証明書を入れる前なので付ける）
   - `<PC の IP>` は、この項の手順 4 の最後に出た URL の IP
   - `ALLOW_FROM` に入っていない端末があれば、同じコマンドに `-m 6` を足して実行し、6 秒待って `000` が出ることも確かめる

1. スマートフォンと PC に、この PC のルート証明書を入れる。

   - [端末にルート証明書を入れる](almalinux-setup.md#grok-build-のブラウザ操作-端末にルート証明書を入れる)の手順 2〜6 を通す。この PC 自身のブラウザで開くなら、この PC にも入れる

1. トークンをスマートフォンに渡す。

   - `qrencode` のある AlmaLinux に SSH で入れるなら、この PC で `Get-Content "$env:LOCALAPPDATA\codeg-server\token.txt" | ssh <ホスト> 'qrencode -t ansiutf8'` を打つ
   - QR コードをスマートフォンのカメラで読み、出てきた 64 文字をコピーする
   - トークンは SSH の中を通って相手の `qrencode` に渡り、相手には保存されない
   - ほかの方法で渡すときは、`notepad "$env:LOCALAPPDATA\codeg-server\token.txt"` で開く
   - **画面を人に見せない。読み終えたら `Clear-Host` で消す**

1. スマートフォンで、ブラウザで開いてトークンを入れ、指示を送る。

   - ブラウザで、この項の手順 4 の最後に出た URL（`https://<PC の IP>:3443`）を開く。警告が出ずに、ログインの画面が出ればよい
   - 「アクセストークン」にコピーした 64 文字を貼り、「接続」を押す
   - [ブラウザで開いて Grok を動かす](almalinux-setup.md#grok-build-のブラウザ操作-ブラウザで開いて-grok-を動かす)の手順 5・6 と同じ操作で、会話を開いて指示を送る
   - この PC 自身のブラウザからも、同じ URL で開ける

1. PC の IP が変わったとき（別の拠点の有線 LAN につないだときなど）は、今の URL を表示して、その URL で開き直す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' -and $_.PhysicalMediaType -eq '802.3' } | Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | ForEach-Object { "https://$($_.IPAddress):3443" }
   Get-NetConnectionProfile | Format-Table InterfaceAlias, NetworkCategory -AutoSize
   ```

   - 有線 LAN の IPv4 ごとに URL が 1 行と、接続ごとのネットワークの種類が出る。URL が出なければ、有線 LAN につながっていない
   - 有線 LAN の接続が `Public` なら届かない。[Windows 11 の初期設定の「ネットワークとリモート」の手順 1](#ネットワークとリモート)でプライベートにする
   - Caddy の設定・タスク・受信の規則・端末のルート証明書は、変えなくてよい。新しい IP 宛ての証明書は、Caddy がその場で作る
   - その拠点の LAN の帯が `ALLOW_FROM` に無ければ届かない。規則の `RemoteAddress` に足す
   - ブラウザは、IP が違う URL を別のサイトとして扱う。はじめて開く IP では、トークンを入れ直す

---

### Grok Build のブラウザ操作: Windows 11 の既存のタスクを非表示起動に切り替える

- 以前の手順でタスクを作り、ログオン時に Terminal が開く場合に通す。管理者ではない Windows PowerShell（5.1）で行う
- この項の手順 3 で、Codeg と Caddy を短時間止める。実行中の会話は中断されるので、作業が終わってから通す

1. ランチャーを用意する。

   - `%LOCALAPPDATA%\codeg-server\codeg-hidden-launcher.exe` が無いときだけ、[Codeg を入れる](#grok-build-のブラウザ操作-windows-11-で-codeg-のサーバーを入れて起動する)の手順 7 を通す
   - その項の手順 8 は通さない。既存のタスクは、この項の手順 3 で切り替える

1. Caddy のタスクがあるときだけ、Caddy の起動用スクリプトを用意する。

   ```powershell
   $script = Join-Path $env:LOCALAPPDATA 'codeg-caddy\start-caddy-hidden.ps1'
   if (Test-Path -LiteralPath $script) {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-Item -LiteralPath $script | Select-Object Name, Length
   } else {
     [IO.File]::WriteAllText($script, @'
   $dir = Join-Path $env:LOCALAPPDATA 'codeg-caddy'
   & (Join-Path $dir 'caddy.exe') run --config (Join-Path $dir 'Caddyfile') --adapter caddyfile
   exit $LASTEXITCODE
   '@, (New-Object Text.UTF8Encoding($true)))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-Item -LiteralPath $script | Select-Object Name, Length
   }
   ```

   - `start-caddy-hidden.ps1` の行が出ればよい
   - 既にファイルがある場合は、Caddy の起動用であることを確かめてから進む。上書きはしない

1. タスクの控えを取り、起動するプログラムだけを切り替えて再開する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     $dir = Join-Path $env:LOCALAPPDATA 'codeg-server'
     $launcher = Join-Path $dir 'codeg-hidden-launcher.exe'
     $names = @('codeg-server')
     if (Get-ScheduledTask -TaskName 'codeg-caddy' -ErrorAction SilentlyContinue) { $names += 'codeg-caddy' }
     $scripts = @{ 'codeg-server' = (Join-Path $dir 'start-codeg-server.ps1'); 'codeg-caddy' = (Join-Path $env:LOCALAPPDATA 'codeg-caddy\start-caddy-hidden.ps1') }
     if (-not (Test-Path -LiteralPath $launcher)) { Write-Error '中断: ランチャーが無い'; return }
     $oldActions = @{}
     foreach ($name in $names) {
       $oldActions[$name] = (Get-ScheduledTask -TaskName $name).Actions
       if (-not (Test-Path -LiteralPath $scripts[$name])) { Write-Error "中断: 起動用のスクリプトが無い: $name"; return }
     }
     $backup = Join-Path $dir ('startup-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
     New-Item -ItemType Directory -Path $backup | Out-Null
     foreach ($name in $names) { Export-ScheduledTask -TaskName $name | Set-Content -LiteralPath (Join-Path $backup ($name + '.xml')) -Encoding Unicode }
     try {
       $targets = @(Get-CimInstance Win32_Process | Where-Object {
         ($_.Name -eq 'codeg-server.exe' -and $_.ExecutablePath -eq (Join-Path $dir 'codeg-server.exe')) -or
         ($names -contains 'codeg-caddy' -and $_.Name -eq 'caddy.exe' -and $_.ExecutablePath -eq (Join-Path $env:LOCALAPPDATA 'codeg-caddy\caddy.exe'))
       })
       foreach ($target in $targets) {
         & "$env:WINDIR\System32\taskkill.exe" /PID $target.ProcessId /T /F | Out-Null
         if ($LASTEXITCODE -ne 0) { throw "停止に失敗: $($target.Name)" }
       }
       foreach ($name in $names) { Stop-ScheduledTask -TaskName $name }
       foreach ($name in $names) {
         $action = New-ScheduledTaskAction -Execute $launcher -Argument ('"{0}"' -f $scripts[$name])
         Set-ScheduledTask -TaskName $name -Action $action | Out-Null
       }
       foreach ($name in $names) { Start-ScheduledTask -TaskName $name }
     } catch {
       foreach ($name in $names) {
         Stop-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
         Set-ScheduledTask -TaskName $name -Action $oldActions[$name] | Out-Null
         Start-ScheduledTask -TaskName $name
       }
       Write-Error "中断: 以前の起動方法へ戻した。$($_.Exception.Message)"
       return
     }
     for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 3080 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $backup
     Get-ScheduledTask -TaskName $names | Select-Object TaskName, State, @{ Name = 'Execute'; Expression = { $_.Actions.Execute } }
     Get-NetTCPConnection -State Listen -LocalPort 3080, 3443 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort
   }
   ```

   - 控えのフォルダー、`Running` とランチャーのパス、`127.0.0.1:3080` が出ればよい
   - Caddy のタスクもある場合は、`Running` が 2 行と `::` の 3443 の待ち受けも出ればよい
   - 新しい Terminal のウィンドウが開かないことを確かめ、いつもの URL でブラウザから開く
   - 控えの XML とランチャーは、ふだんの Codeg の更新では消さない

---

### Grok Build のブラウザ操作: Windows 11 で止める・もう一度始める

- 管理者ではない PowerShell に貼る。変数は要らない
- タスクを終了しただけでは、Codeg と Caddy の本体が残る。止めるのはこの項の手順 1

1. Caddy と Codeg を止める。

   ```powershell
   Stop-ScheduledTask -TaskName 'codeg-caddy' -ErrorAction SilentlyContinue
   Get-Process -Name caddy -ErrorAction SilentlyContinue | Stop-Process -Force
   Get-CimInstance Win32_Process -Filter "Name='codeg-server.exe'" |
     Where-Object { $_.ExecutablePath -eq (Join-Path $env:LOCALAPPDATA 'codeg-server\codeg-server.exe') } |
     ForEach-Object { & "$env:WINDIR\System32\taskkill.exe" /PID $_.ProcessId /T /F | Out-Null }
   Stop-ScheduledTask -TaskName 'codeg-server'
   Start-Sleep -Seconds 2
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Process -Name codeg-server, codeg-mcp, caddy -ErrorAction SilentlyContinue | Format-Table Id, ProcessName
   (Get-ScheduledTask -TaskName 'codeg-server', 'codeg-caddy' -ErrorAction SilentlyContinue).State
   Get-NetTCPConnection -State Listen -LocalPort 3080, 3443 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort
   ```

   - プロセスと待ち受けの表は出ず、`Ready` が 2 行出ればよい（公開の項を通していなければ 1 行）
   - ほかの用途の Caddy をこの PC で動かしているなら、2 行目は貼らない（名前が `caddy` のプロセスをすべて止める）
   - 止めるのは、この手順で置いた Codeg と、その子プロセスだけ。端末や、ほかの ACP クライアントで動かしている `grok` は止めない
   - 実行中の会話は中断される。会話の履歴は残る

1. もう一度始めるときは、タスクを開始する。

   ```powershell
   if (Get-Process -Name codeg-server -ErrorAction SilentlyContinue) {
     Write-Error 'Codeg はもう動いている'
   } else {
     Start-ScheduledTask -TaskName 'codeg-server'
     Start-ScheduledTask -TaskName 'codeg-caddy' -ErrorAction SilentlyContinue
     for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 3080 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     Start-Sleep -Seconds 2
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     (Get-ScheduledTask -TaskName 'codeg-server', 'codeg-caddy' -ErrorAction SilentlyContinue).State
     Get-NetTCPConnection -State Listen -LocalPort 3080, 3443 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess -AutoSize
   }
   ```

   - HTTPS で公開しているときは、`Running` が 2 行と、`127.0.0.1` の 3080 と `::` の 3443 の待ち受けが出ればよい
   - localhost でだけ使っているときは、`Running` が 1 行と、`127.0.0.1:3080` の待ち受けだけでよい

---

### Grok Build のブラウザ操作: Windows 11 の更新

- Windows 版の Codeg は、画面から自分を入れ替えない。この項の手順で、SHA-256 を照合してから置き換える
- 同じ場所（`%LOCALAPPDATA%\codeg-server`）に置き換えるので、タスクはそのまま使える。Caddy と受信の規則には触れない
- この節は Codeg の更新。Caddy の更新は、この手順書では確かめていない
- 管理者ではない PowerShell に貼る
- Grok Build は、Codeg からは上がらない。[Windows 11 で止める・もう一度始める](#grok-build-のブラウザ操作-windows-11-で止めるもう一度始める)の手順 1 で Codeg を止めてから、端末で `grok update` を実行して上げる

1. 上げる版を設定する。

   ```powershell
   $CODEG_VERSION = ''                   # 上げる版（GitHub のリリースのタグ。例: v0.35.1）
   ```

   - [リリースの一覧](https://github.com/spacering-net/codeg/releases)で確かめる

1. 配布物を取得して SHA-256 を照合し、Codeg を止めて置き換え、タスクを開始する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $dir = "$env:LOCALAPPDATA\codeg-server"
     $prev = "$env:LOCALAPPDATA\codeg-server.prev"
     $curl = "$env:WINDIR\System32\curl.exe"
     $tmp = "$env:TEMP\codeg-server-setup"
     if (-not $CODEG_VERSION) { Write-Error '中断: この節の手順 1 の変数を設定する'; return }
     if (-not (Test-Path -LiteralPath "$dir\codeg-server.exe")) { Write-Error '中断: Codeg が入っていない'; return }
     if (Test-Path -LiteralPath $prev) { Write-Error "中断: $prev が既にある。前の更新と復旧を終えるまで消さない"; return }
     if (Test-Path -LiteralPath $tmp) { Write-Error "中断: $tmp が既にある。中を確かめて消してから貼り直す"; return }
     New-Item -ItemType Directory -Path $tmp | Out-Null
     $url = "https://github.com/spacering-net/codeg/releases/download/$CODEG_VERSION/codeg-server-windows-x64.zip"
     & $curl -fsSL -o "$tmp\codeg-server-windows-x64.zip" $url
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: zip を取れない'; return }
     & $curl -fsSL -o "$tmp\codeg-server-windows-x64.zip.sha256" "$url.sha256"
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: .sha256 を取れない'; return }
     $want = ((Get-Content -LiteralPath "$tmp\codeg-server-windows-x64.zip.sha256" -Raw) -split '\s+')[0]
     if ((Get-FileHash -LiteralPath "$tmp\codeg-server-windows-x64.zip" -Algorithm SHA256).Hash -ne $want) { Write-Error '中断: sha256 が一致しない'; return }
     Expand-Archive -LiteralPath "$tmp\codeg-server-windows-x64.zip" -DestinationPath $tmp
     $payload = Join-Path $tmp 'codeg-server-windows-x64'
     if (-not (Test-Path -LiteralPath "$payload\codeg-server.exe" -PathType Leaf) -or -not (Test-Path -LiteralPath "$payload\codeg-mcp.exe" -PathType Leaf) -or -not (Test-Path -LiteralPath "$payload\web" -PathType Container)) { throw '中断: 配布物の本体と web が揃っていない' }
     Get-CimInstance Win32_Process -Filter "Name='codeg-server.exe'" |
       Where-Object { $_.ExecutablePath -eq (Join-Path $env:LOCALAPPDATA 'codeg-server\codeg-server.exe') } |
       ForEach-Object {
         & "$env:WINDIR\System32\taskkill.exe" /PID $_.ProcessId /T /F | Out-Null
         if ($LASTEXITCODE -ne 0) { throw '中断: Codeg と子プロセスを止められない' }
       }
     Stop-ScheduledTask -TaskName 'codeg-server'
     Start-Sleep -Seconds 2
     New-Item -ItemType Directory -Path $prev | Out-Null
     Move-Item -LiteralPath "$dir\codeg-server.exe", "$dir\codeg-mcp.exe", "$dir\web" -Destination $prev
     Copy-Item -LiteralPath "$tmp\codeg-server-windows-x64\codeg-server.exe", "$tmp\codeg-server-windows-x64\codeg-mcp.exe" -Destination $dir
     Copy-Item -LiteralPath "$tmp\codeg-server-windows-x64\web" -Destination $dir -Recurse
     Remove-Item -LiteralPath $tmp -Recurse -Force
     Start-ScheduledTask -TaskName 'codeg-server'
     for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 3080 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     'sha256 一致'
     & "$dir\codeg-server.exe" --version
     (Get-ScheduledTask -TaskName 'codeg-server').State
     Get-NetTCPConnection -State Listen -LocalPort 3080 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort -AutoSize
   }
   ```

   - `sha256 一致`、上げた版の番号、`Running`、今までと同じ待ち受けの 1 行が出ればよい
   - 起動用のスクリプトとトークンは、そのまま残る
   - 失敗時は現行の本体と `codeg-server.prev` を残す。退避先の `codeg-server.exe`・`codeg-mcp.exe`・`web` が揃っているか確かめる
   - 揃っていれば、[停止](#grok-build-のブラウザ操作-windows-11-で止めるもう一度始める)の手順 1 で止める
   - 3 つが揃っていれば、現行の `codeg-server` のその 3 つだけを消し、`codeg-server.prev` から同じ場所に戻す。起動用のスクリプトとトークンは消さない
   - 復旧後は[Windows 11 で止める・もう一度始める](#grok-build-のブラウザ操作-windows-11-で止めるもう一度始める)の手順 2 で始める
   - 退避先が揃っていなければ、どちらのディレクトリも消さず、移動やコピーが止まった原因を確かめる。前の版は一部が現行の場所、一部が退避先に残っていることがある

1. ブラウザで動くことを確かめてから、前の版を消す。

   ```powershell
   Remove-Item -LiteralPath "$env:LOCALAPPDATA\codeg-server.prev" -Recurse -Force
   ```

   - 会話の一覧が残っていて、画面の右下の「新バージョン」が消えていればよい


---

## Hyper-V（任意）

- この節だけを実施するときは、各項の前提・実行場所・権限を先に確認する
- [検証記録](verification/hyper-v.md)・[参考資料](reference/hyper-v.md)・[ロールバックと注意点](extra/hyper-v.md)

### Hyper-V: 実施手順

> [!IMPORTANT]
> - **Windows 11 Pro（x64）の PC のデスクトップで行う**。Home には Hyper-V が無い。SSH やリモート デスクトップのセッションからは行わない（途中で再起動する）
> - [対応の確認](#hyper-v-この-pc-で使えるかを確かめる)の手順 1 で開く **管理者の Windows PowerShell 5.1** に、有効化・再起動まで貼る
> - [再起動後の確認](#hyper-v-再起動の後に確かめる)から後ろは、**管理者ではない Windows PowerShell 5.1** に貼る
> - ログインするユーザーは Administrators の一員
> - 前提: [Windows 11 の初期設定の「貼り付けの設定」の手順 1〜4](#貼り付けの設定)。通していなければ、ブロックは Ctrl+V で貼る
> - **途中で再起動が 1 回入る**（[Hyper-V を有効にして再起動する](#hyper-v-hyper-v-を有効にして再起動する)の手順 4）。開いている作業を先に保存し、動いている VM を止める
> - **同じ PC の VirtualBox と VMware Workstation の VM は、再起動の後は Windows のハイパーバイザーの上で動く**。遅くなり、起動しない VM が出ることがある

- 上から順にコードブロックを貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

#### Hyper-V: この PC で使えるかを確かめる

1. Windows のデスクトップで、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. エディション・CPU の仮想化支援・機能の今の状態を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     Admin        = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     User         = "$env:USERDOMAIN\$env:USERNAME"
     Arch         = $env:PROCESSOR_ARCHITECTURE
     Edition      = (Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').EditionID
     Hypervisor   = (Get-CimInstance -ClassName Win32_ComputerSystem).HypervisorPresent
     VirtFirmware = (Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1).VirtualizationFirmwareEnabled
   } | Format-List
   Get-WindowsOptionalFeature -Online | Where-Object FeatureName -like 'Microsoft-Hyper-V*' | Format-Table FeatureName, State
   Get-WindowsOptionalFeature -Online | Where-Object FeatureName -in 'HypervisorPlatform', 'VirtualMachinePlatform' | Format-Table FeatureName, State
   Get-LocalGroupMember -SID 'S-1-5-32-578' | Format-Table Name, ObjectClass
   ```

   - `Admin : True`、`Arch : AMD64`、`Edition` が `Professional`（か `Enterprise`・`Education`）ならよい
   - `Admin` が `False` なら、管理者ではない窓に貼っている。閉じて、この項の手順 1 から
   - `Edition` が `Core`（Home）なら、Hyper-V は入らない。ここで止める
   - `Hypervisor` が `False` で `VirtFirmware` も `False` なら、PC の UEFI（BIOS）の設定で Intel VT-x / AMD-V（SVM）を有効にしてから始める
   - `Microsoft-Hyper-V-All` が `Enabled` なら、もう有効。[Hyper-V を有効にして再起動する](#hyper-v-hyper-v-を有効にして再起動する)の手順 1 は飛ばす
   - 最後の表（Hyper-V Administrators の一員）は、空でよい

#### Hyper-V: Hyper-V を有効にして再起動する

1. Hyper-V を有効にする。

   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -All -NoRestart
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-WindowsOptionalFeature -Online | Where-Object FeatureName -like 'Microsoft-Hyper-V*' | Format-Table FeatureName, State
   ```

   - `Microsoft-Hyper-V-All`・`Microsoft-Hyper-V-Hypervisor` が `Enabled` か `EnablePending` ならよい
   - `Microsoft-Hyper-V-Services`・`Microsoft-Hyper-V-Management-PowerShell` も `Enabled` か `EnablePending` ならよい
   - **まだ再起動しない**（この項の手順 4 でまとめて行う）

1. VirtualBox か VMware Workstation も同じ PC で使うときだけ、Windows ハイパーバイザー プラットフォームも有効にする。

   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All -NoRestart
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-WindowsOptionalFeature -Online | Where-Object FeatureName -in 'HypervisorPlatform', 'VirtualMachinePlatform' | Format-Table FeatureName, State
   ```

   - `HypervisorPlatform` が `Enabled` か `EnablePending` ならよい
   - **再起動の後、VirtualBox と VMware Workstation の VM は Windows のハイパーバイザーの上で動き、遅くなることがある**。再起動の後に、既存の VM が起動するかを確かめる

1. 自分のユーザーを Hyper-V Administrators に足す。

   ```powershell
   $HV_USER = "$env:USERDOMAIN\$env:USERNAME"
   if ((Get-LocalGroupMember -SID 'S-1-5-32-578' -ErrorAction SilentlyContinue).Name -contains $HV_USER) { "すでに一員: $HV_USER" } else { Add-LocalGroupMember -SID 'S-1-5-32-578' -Member $HV_USER }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-LocalGroupMember -SID 'S-1-5-32-578' | Format-Table Name, ObjectClass
   ```

   - 表に、ふだんログインするユーザーが出ればよい
   - 別の管理者のユーザーで昇格した窓では、`$HV_USER` がその管理者になる。表のユーザーが違ったら、`Add-LocalGroupMember -SID 'S-1-5-32-578' -Member '<PC 名>\<ふだんのユーザー>'` を打って足す

1. 再起動する。

   ```powershell
   Restart-Computer
   ```

   - **開いている作業を保存し、動いている VM（VirtualBox など）を止めてから貼る**（確認を聞かずに再起動が始まる）
   - VMware も入れるなら、先に[VMware の導入](#vmware-workstation-pro-インストールする)の手順 1 まで済ませると、再起動は 1 回で済む（同じ項の手順 2 を兼ねる）
   - **次の手順は、起動してサインインしてから行う**

#### Hyper-V: 再起動の後に確かめる

1. Windows のデスクトップで、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. Hyper-V の管理のコマンドが、昇格せずに使えるかを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   whoami /groups | Select-String -Pattern 'S-1-5-32-578'
   Get-Service -Name vmms, vmcompute | Format-Table Name, Status, StartType
   Get-VMHost | Format-List LogicalProcessorCount, VirtualMachinePath, VirtualHardDiskPath
   Get-VMSwitch | Format-Table Name, SwitchType
   ```

   - `S-1-5-32-578` の行が出て、`vmms` が `Running` ならよい
   - `Get-VMSwitch` に `Default Switch` が出る
   - `Get-VMHost` が権限のエラーになったら、ログインし直していない。サインアウトしてサインインし直す

#### Hyper-V: VM を作る

1. 変数を設定する（`HV_ISO` は必ず値を入れる）。

   ```powershell
   $HV_ISO = ''
   ```

   ```powershell
   $HV_VM = 'alma10'
   $HV_DIR = "$env:USERPROFILE\Hyper-V"
   $HV_CPU = 2
   $HV_MEM = 4GB
   $HV_DISK = 64GB
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{ HV_ISO = $HV_ISO; HV_VM = $HV_VM; HV_DIR = $HV_DIR; HV_CPU = $HV_CPU; HV_MEM_GB = $HV_MEM / 1GB; HV_DISK_GB = $HV_DISK / 1GB } | Format-List
   ```

   - `$HV_ISO` は、入れる OS のインストール用の ISO のパス
   - `$HV_VM` は VM の名前、`$HV_DIR` は VM を置くフォルダー（その下に VM の名前のフォルダーができる）
   - 新しい窓を開いたら、この手順を貼り直す

1. 第 2 世代の VM を作り、ISO を付ける。

   ```powershell
   if (-not $HV_ISO) { Write-Error '中断: この項の手順 1 の $HV_ISO が空のまま。値を入れて貼り直す' } elseif (-not (Test-Path -LiteralPath $HV_ISO)) { Write-Error "中断: ISO が無い: $HV_ISO" } elseif (Get-VM -Name $HV_VM -ErrorAction SilentlyContinue) { Write-Error "中断: 同じ名前の VM がすでにある: $HV_VM" } else {
     New-VM -Name $HV_VM -Generation 2 -MemoryStartupBytes $HV_MEM -Path $HV_DIR -NewVHDPath "$HV_DIR\$HV_VM\$HV_VM.vhdx" -NewVHDSizeBytes $HV_DISK -SwitchName 'Default Switch' | Out-Null
     Set-VM -Name $HV_VM -ProcessorCount $HV_CPU -StaticMemory -AutomaticCheckpointsEnabled $false -CheckpointType Standard
     Set-VMFirmware -VMName $HV_VM -FirstBootDevice (Add-VMDvdDrive -VMName $HV_VM -Path $HV_ISO -Passthru)
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-VM -Name $HV_VM | Format-List Name, State, Generation, Version, ProcessorCount, DynamicMemoryEnabled, AutomaticCheckpointsEnabled, Path
     Get-VMFirmware -VMName $HV_VM | Format-List SecureBoot, SecureBootTemplate
   }
   ```

   - `State : Off`、`Generation : 2`、`DynamicMemoryEnabled : False`、`AutomaticCheckpointsEnabled : False` が出ればよい
   - `SecureBoot : On`、`SecureBootTemplate : MicrosoftWindows` が出る

1. Linux を入れるときだけ、Secure Boot のテンプレートを Linux 用に変える。

   ```powershell
   Set-VMFirmware -VMName $HV_VM -SecureBootTemplate MicrosoftUEFICertificateAuthority
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-VMFirmware -VMName $HV_VM | Format-List SecureBoot, SecureBootTemplate
   ```

   - `SecureBootTemplate : MicrosoftUEFICertificateAuthority` が出ればよい
   - **変えないままだと、Linux の ISO からは起動しない**（VM の画面に `Start PXE over IPv4` が出る）
   - Secure Boot を切って入れるなら、代わりに `Set-VMFirmware -VMName $HV_VM -EnableSecureBoot Off` を打つ

1. Windows 11 を入れるときだけ、仮想 TPM を付ける。

   ```powershell
   Set-VMKeyProtector -VMName $HV_VM -NewLocalKeyProtector
   Enable-VMTPM -VMName $HV_VM
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-VMSecurity -VMName $HV_VM | Format-List TpmEnabled
   ```

   - `TpmEnabled : True` が出ればよい

#### Hyper-V: VM を起動して OS を入れる

1. VM を起動し、VM の画面を開く。

   ```powershell
   Start-VM -Name $HV_VM
   vmconnect.exe localhost $HV_VM
   ```

   - VM の画面のウィンドウが開く

1. VM の画面で、OS のインストーラーを最後まで進める。

   - Windows の ISO は、起動の直後に `Press any key to boot from CD or DVD` が出ているあいだに、VM の画面をクリックしてキーを押す
   - インストーラーが最後に再起動するか、電源を切るまで進める
   - **次の手順は、インストールが終わってから貼る**

1. ISO を付けた DVD ドライブを、VM から外す。

   ```powershell
   Get-VMDvdDrive -VMName $HV_VM | Remove-VMDvdDrive
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   "DVD ドライブの数: $(@(Get-VMDvdDrive -VMName $HV_VM).Count)"
   ```

   - `DVD ドライブの数: 0` が出ればよい

#### Hyper-V: 動作を確かめる

1. VM の状態と、ゲストの IP を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-VM -Name $HV_VM | Format-List Name, State, Uptime, Status
   Get-VMNetworkAdapter -VMName $HV_VM | Format-Table Name, SwitchName, MacAddress, IPAddresses
   ```

   - `State : Running` で、`IPAddresses` にゲストの IP が出ればよい
   - VM が止まっていたら、先に `Start-VM -Name $HV_VM` を打つ
   - `IPAddresses` が空のまま変わらないなら、ゲストに Hyper-V のデーモンが入っていない。VM の画面でログインして IP を見る（AlmaLinux 10 の Workstation には `hyperv-daemons` が入っている）

1. Linux のゲストなら、この PC から SSH で入れるかを確かめる。

   - この窓で `ssh <ゲストのユーザー>@<ゲストの IP>` を打つ（IP はこの項の手順 1 の `IPAddresses`）
   - ゲストのプロンプトが出ればよい。`exit` で戻る
   - ゲストの IP は固定ではない。つなぐ前に、この項の手順 1 で引き直す

---

### Hyper-V: 使い方の基本

- 管理者ではない Windows PowerShell（5.1）で打つ。`<VM 名>` は VM の名前

| すること | コマンド |
|---|---|
| VM の一覧 | `Get-VM` |
| 起動する | `Start-VM -Name <VM 名>` |
| ゲストに電源を切らせる | `Stop-VM -Name <VM 名>` |
| 電源を切る（ゲストに知らせない） | `Stop-VM -Name <VM 名> -TurnOff` |
| VM の画面を開く | `vmconnect.exe localhost <VM 名>` |
| ゲストの IP を見る | `(Get-VMNetworkAdapter -VMName <VM 名>).IPAddresses` |
| CPU の数を変える（止めてから） | `Set-VM -Name <VM 名> -ProcessorCount 4` |
| メモリを変える（止めてから） | `Set-VM -Name <VM 名> -MemoryStartupBytes 8GB` |

---

### Hyper-V: チェックポイントとクローン

- チェックポイントは、VM のその時点の状態。戻したり、そこから別の VM を作ったりできる
- 管理者ではない Windows PowerShell（5.1）に貼る。[VM を作る](#hyper-v-vm-を作る)の手順 1 の変数を使う

> [!WARNING]
> **この項の手順 3 で作った VM があるあいだは、元の VM のチェックポイントを消さない**。消すと元のディスクが書き換わり、そこから作った VM がすべて起動しなくなる。

1. VM を止めて、チェックポイントを取る。

   ```powershell
   $HV_CHECKPOINT = 'clean-install'
   Stop-VM -Name $HV_VM
   Checkpoint-VM -Name $HV_VM -SnapshotName $HV_CHECKPOINT
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-VMSnapshot -VMName $HV_VM | Format-Table VMName, Name, SnapshotType, CreationTime
   ```

   - 付けた名前のチェックポイントが出ればよい
   - VM がすでに止まっていれば、`Stop-VM` は警告を出して何もしない

1. VM をチェックポイントの時点に戻すときは、VM を止めてから戻す。

   ```powershell
   Stop-VM -Name $HV_VM -TurnOff
   Restore-VMSnapshot -VMName $HV_VM -Name $HV_CHECKPOINT -Confirm:$false
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-VM -Name $HV_VM | Format-List Name, State, ParentCheckpointName
   ```

   - **チェックポイントより後の変更は消える**
   - `ParentCheckpointName` に、戻した先の名前が出ればよい
   - VM がすでに止まっていれば、`Stop-VM` は警告を出して何もしない

1. チェックポイントの時点から、差分ディスクで別の VM を作る。

   ```powershell
   $HV_CLONE = "$HV_VM-clone"
   if (Get-VM -Name $HV_CLONE -ErrorAction SilentlyContinue) { Write-Error "中断: 同じ名前の VM がすでにある: $HV_CLONE" } else {
     $parent = (Get-VMHardDiskDrive -VMSnapshot (Get-VMSnapshot -VMName $HV_VM -Name $HV_CHECKPOINT) | Select-Object -First 1).Path
     New-Item -ItemType Directory -Path "$HV_DIR\$HV_CLONE" | Out-Null
     New-VHD -Path "$HV_DIR\$HV_CLONE\$HV_CLONE.vhdx" -ParentPath $parent -Differencing | Out-Null
     New-VM -Name $HV_CLONE -Generation 2 -MemoryStartupBytes (Get-VM -Name $HV_VM).MemoryStartup -Path $HV_DIR -VHDPath "$HV_DIR\$HV_CLONE\$HV_CLONE.vhdx" -SwitchName 'Default Switch' | Out-Null
     Set-VM -Name $HV_CLONE -ProcessorCount (Get-VM -Name $HV_VM).ProcessorCount -StaticMemory -AutomaticCheckpointsEnabled $false -CheckpointType Standard
     $firmware = Get-VMFirmware -VMName $HV_VM
     if ($firmware.SecureBoot -eq 'On') { Set-VMFirmware -VMName $HV_CLONE -EnableSecureBoot On -SecureBootTemplate $firmware.SecureBootTemplate } else { Set-VMFirmware -VMName $HV_CLONE -EnableSecureBoot Off }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-VHD -Path "$HV_DIR\$HV_CLONE\$HV_CLONE.vhdx" | Format-List VhdType, ParentPath
     Get-VM -Name $HV_CLONE | Format-List Name, State, ProcessorCount, MemoryStartup
   }
   ```

   - `VhdType : Differencing` と、元の VM のディスクを指す `ParentPath` が出ればよい
   - 新しい VM は、ホスト名もログインも元の VM と同じ。起動してから、ゲストの中でホスト名を変える
   - 仮想 TPM と、ファームウェアに登録した鍵（MOK など）は引き継がれない

---

### Hyper-V: VM どうしだけがつながるスイッチを作る（任意）

- Private のスイッチは、つないだ VM どうしだけが通信できる（この PC とも、インターネットともつながらない）
- 管理者ではない Windows PowerShell（5.1）に貼る。IP は配られないので、ゲストの中で固定の IP を付ける

1. スイッチを作り、止めてある VM に 2 枚目の NIC として付ける。

   ```powershell
   $HV_SWITCH = 'lab-lan'
   $switch = Get-VMSwitch -Name $HV_SWITCH -ErrorAction SilentlyContinue
   if ($switch -and $switch.SwitchType -ne 'Private') { Write-Error "中断: 同じ名前で、Private ではないスイッチがある: $HV_SWITCH" } else {
     if (-not $switch) { New-VMSwitch -Name $HV_SWITCH -SwitchType Private | Out-Null }
     Add-VMNetworkAdapter -VMName $HV_VM -SwitchName $HV_SWITCH
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-VMSwitch -Name $HV_SWITCH | Format-Table Name, SwitchType
     Get-VMNetworkAdapter -VMName $HV_VM | Format-Table Name, SwitchName, MacAddress
   }
   ```

   - `SwitchType` が `Private` のスイッチと、VM の 2 枚の NIC（`Default Switch` と、作ったスイッチ）が出ればよい
   - `中断: 同じ名前で、Private ではないスイッチがある` と出たら、`$HV_SWITCH` を別の名前にして貼り直す
   - つなぐ相手の VM にも、`$HV_VM` を相手の名前に変えて `Add-VMNetworkAdapter` の行を打つ

---

### Hyper-V: VM を消す

> [!CAUTION]
> **この項の手順 1 は、VM のディスクごと消す（取り戻せない）**。[チェックポイントとクローン](#hyper-v-チェックポイントとクローン)の手順 3 で、この VM から作った VM が残っているなら、先にそちらを消す。

1. VM を止めて、登録とファイルを消す（取り戻せない）。

   ```powershell
   $HV_REMOVE = ''
   ```

   ```powershell
   if (-not $HV_REMOVE) { Write-Error '中断: $HV_REMOVE が空のまま。消す VM の名前を入れて貼り直す' } elseif (-not (Get-VM -Name $HV_REMOVE -ErrorAction SilentlyContinue)) { Write-Error "中断: VM が無い: $HV_REMOVE" } else {
     $dir = (Get-VM -Name $HV_REMOVE).Path.TrimEnd('\')
     $others = @(Get-VM | Where-Object Name -ne $HV_REMOVE)
     $disks = @($others | Get-VMHardDiskDrive | ForEach-Object { $_.Path; (Get-VHD -Path $_.Path).ParentPath })
     if ((Split-Path -Leaf $dir) -ne $HV_REMOVE) { Write-Error "中断: VM のフォルダーが、VM の名前のフォルダーではない: $dir" } elseif (($others | Where-Object { $_.Path.TrimEnd('\') -eq $dir }) -or ($disks | Where-Object { $_ -like "$dir\*" })) { Write-Error "中断: ほかの VM が、このフォルダーのファイルを使っている: $dir" } else {
       Stop-VM -Name $HV_REMOVE -TurnOff -Force -WarningAction SilentlyContinue
       Remove-VM -Name $HV_REMOVE -Force -ErrorAction Stop
       Remove-Item -LiteralPath $dir -Recurse -Force
       "`n$([char]27)[7m 確認 $([char]27)[0m"
       Get-VM | Format-Table Name, State
       Test-Path -LiteralPath $dir
     }
   }
   ```

   - 一覧から VM が消え、最後に `False` が出ればよい
   - `中断: VM のフォルダーが、VM の名前のフォルダーではない` と出たら、本書の[VM を作る](#hyper-v-vm-を作る)で作った VM ではない。このブロックでは消さない（Hyper-V マネージャーで消す）
   - `中断: ほかの VM が、このフォルダーのファイルを使っている` と出たら、この VM から作った VM を先に消す

---


---

## Samba クライアント（任意）

- この節だけを実施するときは、各項の前提・実行場所・権限を先に確認する
- [検証記録](verification/samba-client.md)・[参考資料](reference/samba-client.md)・[ロールバックと注意点](extra/samba-client.md)

### Samba クライアント: Windows 11 で使う

> [!IMPORTANT]
> - **Windows の手順は、この項の手順 1 で開く管理者ではない Windows PowerShell 5.1 に貼る**。更新・ロールバックも同じ窓を使う
> - 管理者の窓で割り当てたドライブは、エクスプローラーに出ない
> - 前提: サーバーで [Samba サーバー](almalinux-setup.md#samba-サーバー-実施手順) の手順を終えていること
> - 前提: [Windows 11 の初期設定の「貼り付けの設定」の手順 1〜4](#貼り付けの設定)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ貼り付けの設定）。通していなければ、ブロックは Ctrl+V で貼る
> - **この項の手順 4 には対話入力がある**（共有のパスワード）。入力し終えてから手順 5 を貼る
> - **この項の手順 7 はサーバーのシェルで、手順 8 はこの PC で行う**（サインアウトしてサインインし直す）

- 上から順にコードブロックを貼る。Windows の手順は、この項の手順 2 で変数を設定した PowerShell に、この項の手順 7 はサーバーのシェルに貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 共有をドライブ文字（既定は `Z:`）に割り当て、サインインのたびにつなぎ直す。パスワードは、Windows の資格情報マネージャーに置く
- Samba サーバーの `[root]`・`[home]` も割り当てるなら、この節を通した後に、この項の手順 2 の 3 つ目のブロックの `SHARE` と `DRIVE` を書き換えて貼り、この項の手順 3・5・6 を貼り直す（資格情報は同じなので、手順 4 は要らない）

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
   - [root のホーム](almalinux-setup.md#samba-サーバー-root-のホームも公開する任意)なら `SHARE=root`、[/home](almalinux-setup.md#samba-サーバー-home-も公開する任意)なら `SHARE=home` にする
   - `SMB_USER` は自分のまま。`DRIVE` はほかの割り当てと違う文字にする
   - `SERVER` は、エクスプローラーで `\\<SERVER>\…` を開くときと同じ書き方にする
   - **新しい PowerShell を開いたら**、この項の手順 2 の 3 つのブロックを貼り直してから先へ進む

1. 管理者ではないことと、サーバーの 445 番・ドライブ文字・保存済みの資格情報を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not $SERVER -or -not $SMB_USER -or -not $SHARE -or -not $DRIVE) {
     Write-Error '中断: この節の手順 2 の変数が空のまま。値を入れて貼り直す'
   } elseif (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
     Write-Error '中断: 管理者の窓で開いている。この節の手順 1 で、管理者ではない窓を開き直す'
   } elseif ($DRIVE -notmatch '^[A-Za-z]:$') {
     Write-Error '中断: この節の手順 2 の DRIVE は、Z: のようにドライブ文字とコロンにする'
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
   - `445/tcp に届かない` ときは、`SERVER` の値と、サーバーの firewalld と smbd（[Samba サーバー 手順 5・8](almalinux-setup.md#samba-サーバー-実施手順)）を確かめる。外出先なら、先に WireGuard のトンネルを張る
   - `もう使われている` ときは、`DRIVE` を別の文字にして、この項の手順 2 の 3 つ目のブロックを貼り直す。前にこの節で同じ共有を割り当てたなら、この節は済んでいる

1. 資格情報マネージャーに、共有のユーザー名とパスワードを登録する。

   ```powershell
   if (-not $SERVER -or -not $SMB_USER) {
     Write-Error '中断: この節の手順 2 の SERVER か SMB_USER が空のまま。値を入れて貼り直す'
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     cmdkey "/add:$SERVER" "/user:$SMB_USER" /pass
   }
   ```

   - パスワードを聞かれる。AlmaLinux の「Samba サーバー」の設定なら、[Samba サーバー 手順 6](almalinux-setup.md#samba-サーバー-実施手順) で `smbpasswd -a` に入れたパスワード
   - 資格情報を追加した旨の 1 行が出ればよい
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. 共有をドライブ文字に割り当て、サインインのたびにつなぎ直すようにする。

   ```powershell
   if (-not $SERVER -or -not $SHARE -or -not $DRIVE) {
     Write-Error '中断: この節の手順 2 の変数が空のまま。値を入れて貼り直す'
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
     Write-Error '中断: この節の手順 2 の DRIVE が空のまま。値を入れて貼り直す'
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

---

### Samba クライアント: Windows 11 の更新

- SMB のクライアントは Windows に入っているもので、Windows Update で上がる。この節で上げるものは無い
- Samba のパスワードを変えたとき（Samba サーバー では `sudo smbpasswd <SMB_USER>`）だけ、この項の手順を行う
- この項の手順 1 は、[Windows 11 で使う](#samba-クライアント-windows-11-で使う)の手順 2 の変数を設定した、管理者ではない Windows PowerShell（5.1）に貼る。新しい窓なら、その手順 2 のブロックを貼り直してから貼る

1. Samba のパスワードを変えたときだけ、資格情報を登録し直す。

   ```powershell
   if (-not $SERVER -or -not $SMB_USER) {
     Write-Error '中断: Windows 11 で使うの手順 2 の SERVER か SMB_USER が空のまま。値を入れて貼り直す'
   } else {
     cmdkey "/add:$SERVER" "/user:$SMB_USER" /pass
   }
   ```

   - サーバーで変えた後の新しいパスワードを入れる
   - パスワードを入力し終えてから、この項の手順 2 を行う

1. サインアウトしてサインインし直し、ドライブがパスワード無しで開くことを確かめる。

   - [Windows 11 で使う](#samba-クライアント-windows-11-で使う)の手順 8 と同じ


---

## Syncthing（任意）

- この節だけを実施するときは、各項の前提・実行場所・権限を先に確認する
- [検証記録](verification/syncthing.md)・[参考資料](reference/syncthing.md)・[ロールバックと注意点](extra/syncthing.md)

### Syncthing: Windows 11 で使う

> [!IMPORTANT]
> - **Administrators のユーザーが Windows で行う**。この項の手順 1 で開く **管理者の Windows PowerShell 5.1** に、以後と停止・更新・ロールバックのブロックを貼る
> - フォルダー追加は[同期フォルダとデバイスを追加する](almalinux-setup.md#syncthing-同期フォルダとデバイスを追加する任意)に従い、**ホーム全体は同期しない**
> - 前提: [Windows 11 の初期設定の「貼り付けの設定」の手順 1〜4](#貼り付けの設定)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ貼り付けの設定）。通していなければ、ブロックは Ctrl+V で貼る
> - 前提: 相手とつながる LAN の接続がプライベートであること（[Windows 11 の初期設定の「ネットワークとリモート」の手順 1](#ネットワークとリモート)）。この項の手順 7 で確かめる
> - Syncthing そのものは、管理者ではない自分のユーザーとして、サインインしている間だけ動く（この項の手順 8 のタスク）
> - **この項の手順 5 には対話入力がある**（GUI のパスワード）。入力し終えてから手順 6 を貼る
> - **この項の手順 12 は LAN の別の端末のブラウザで、手順 13 はこの PC で行う**（サインアウトしてサインインし直す）

- 上から順にコードブロックを貼る。この項の手順 2 で変数を設定した PowerShell に貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- この節の PC は、[実施手順](almalinux-setup.md#syncthing-実施手順)の AlmaLinux 10 の Syncthing の相手にもなる

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
     Write-Error '手順 2 の $ST_GUI_USER が空'
   } elseif (-not $ST_GUI_PASS -or $ST_GUI_PASS.Length -eq 0) {
     Write-Error '手順 5 のパスワードが空'
   } else {
     $p = ([Net.NetworkCredential]::new('', $ST_GUI_PASS)).Password
     if ($p -cnotmatch '^[\x20-\x7e]+$') {
       Write-Error 'パスワードに ASCII でない文字がある（手順 5 からやり直す）'
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
     Write-Error '手順 2 の $LAN_IF が空'
   } elseif ((Get-NetConnectionProfile -InterfaceAlias $LAN_IF).NetworkCategory -ne 'Private') {
     Write-Error '中断: LAN の接続がプライベートではない（Windows 11 の初期設定の「ネットワークとリモート」の手順 1 でプライベートにする）'
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
   - `中断:` が出たら、[Windows 11 の初期設定の「ネットワークとリモート」の手順 1](#ネットワークとリモート) でプライベートにしてから、この手順を貼り直す
   - 何度貼ってもよい
   - **注意**: プライベートの LAN では、プライベート向けのほかの許可の規則（ネットワーク探索など）も効く（[Windows 11 の初期設定の「OpenSSH サーバー」の手順 3](#openssh-サーバー)の補足）

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
   - `127.0.0.1` のままなら、[Windows 11 で止める・もう一度始める](#syncthing-windows-11-で止めるもう一度始める)の手順 1・2 で起動し直す

1. 待ち受け・規則・デバイス ID を確かめ、GUI の URL を出す。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   $proc = @{ Label = 'Process'; Expression = { (Get-Process -Id $_.OwningProcess).ProcessName } }
   if (-not $LAN_IF) {
     Write-Error '手順 2 の $LAN_IF が空'
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

   - この項の手順 11 の URL を開き、自己署名の証明書の警告を受け入れ、手順 2 のログイン名と手順 5 のパスワードで入る
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

---

### Syncthing: Windows 11 で止める・もう一度始める

- タスク スケジューラでタスクを終了しても（`Stop-ScheduledTask` も）、親のプロセス（モニター）しか止まらず、本体は動き続ける（公式の説明）。止めるのはこの項の手順 1
- 自動の更新の後の Syncthing は、タスクの外で動く（[Windows 11 の更新](#syncthing-windows-11-の更新)）。動いているかは、タスクの状態ではなくプロセスで見る

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

---

### Syncthing: Windows 11 の更新

- Syncthing は稼働中、既定で 12 時間ごとに新しい版を確かめ、あれば自分で入れ替えて起動し直す（入れ替える前に、リリースの署名を確かめる）。サインアウト中・スリープ中・通信できない間は更新されない
- 入れ替えは同じ場所（`%LOCALAPPDATA%\Programs\Syncthing\syncthing.exe`）で行うので、タスクと受信の規則はそのまま使える。古い実行ファイルは、同じフォルダーに `syncthing.exe.old` として残る
- **自動で入れ替えた後の Syncthing は、タスクの外で動く**（タスクは `Ready` になる）。次のサインインからは、またタスクで起動する
- 待たずに上げるときは、この項の手順を貼る

1. 今の版と、新しい版があるかを確かめる。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & $exe --version
   & $exe upgrade --check-only
   ```

   - 新しい版があれば、`Upgrade available` の行に今の版（`current`）と新しい版（`latest`）が出る
   - 新しい版が無ければ、`no upgrade available (current "v2.1.5" >= latest "v2.1.5")` のエラーが出る。そのときは、この項の手順 2 は飛ばす

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

## VirtualBox（任意）

- この節だけを実施するときは、各項の前提・実行場所・権限を先に確認する
- [検証記録](verification/virtualbox.md)・[参考資料](reference/virtualbox.md)・[ロールバックと注意点](extra/virtualbox.md)

### VirtualBox: Windows 11 で使う

> [!IMPORTANT]
> - **すべて Windows 11 の PC のデスクトップで行う**。SSH やリモート デスクトップのセッションからは行わない（この項の手順 3 の途中でネットワークがいったん切れ、この項の手順 7 は画面で行う）
> - この項の手順 1 で開く **管理者の Windows PowerShell 5.1** に、手順 2〜4 と更新・ロールバックのブロックを貼る
> - この項の手順 5 で開く **管理者ではない Windows PowerShell 5.1** に、手順 6・8 を貼る
> - ログインするユーザーは Administrators の一員（VirtualBox は PC 全体に入り、ドライバーを入れる）
> - 前提: [Windows 11 の初期設定の「貼り付けの設定」の手順 1〜4](#貼り付けの設定)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ貼り付けの設定）。通していなければ、ブロックは Ctrl+V で貼る
> - **AlmaLinux 10 の前提（EPEL・Secure Boot の MOK の鍵）と KVM の設定は要らない**。Windows のドライバーは、Microsoft の署名付きでインストーラに入っている

- 上から順にコードブロックを貼る。変数は無い
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- Android の Windows App から VM に打つなら、[Android の RDP 設定](#virtualbox-windows-11-の-virtualbox-を-android-からリモート-デスクトップで使う任意)を通す
- Atomic Desktop のゲストに Guest Additions を入れるなら、[bootc ゲスト](almalinux-setup.md#virtualbox-の-bootc-ゲスト-実施手順)を通す

1. Windows のデスクトップで、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. この PC に入るか、今の状態を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     Admin        = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Arch         = $env:PROCESSOR_ARCHITECTURE
     Winget       = (Get-Command winget -ErrorAction SilentlyContinue).Source
     VirtualBox   = Test-Path -LiteralPath "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"
     Hypervisor   = (Get-CimInstance -ClassName Win32_ComputerSystem).HypervisorPresent
     VirtFirmware = (Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1).VirtualizationFirmwareEnabled
   } | Format-List
   Get-WindowsOptionalFeature -Online | Where-Object FeatureName -in 'Microsoft-Hyper-V-All', 'VirtualMachinePlatform', 'HypervisorPlatform' | Format-Table FeatureName, State
   ```

   - `Admin : True` と `Arch : AMD64` が出ればよい
   - `Admin` が `False` なら、管理者ではない窓に貼っている。閉じて、この項の手順 1 から
   - `Arch` が `ARM64` なら、この節は扱わない
   - `Winget` が空なら、Microsoft Store で「アプリ インストーラー」を更新してから始める
   - `Hypervisor` が `False` で `VirtFirmware` も `False` なら、PC の UEFI（BIOS）の設定で Intel VT-x / AMD-V（SVM）を有効にしてから始める
   - `VirtualBox` が `True` なら、もう入っている。この項の手順 3 は飛ばす（新しい版にするなら[Windows 11 の更新](#virtualbox-windows-11-の更新)）

1. VirtualBox が入っていないときだけ、winget で入れる。

   ```powershell
   winget install --exact --id Oracle.VirtualBox --source winget --accept-source-agreements --accept-package-agreements
   ```

   - **途中でネットワークがいったん切れる**
   - インストーラの画面は出ず、進み具合だけが出る。最後に、入れ終えた旨の行（英語の表示では `Successfully installed`）が出ればよい
   - **次の手順は、winget が終わってプロンプトに戻ってから貼る**（続けて貼ると、winget が何か聞いたときの答えとして食われる）

1. 入ったか、ドライバーとホストオンリーのアダプターができたかを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget list --exact --id Oracle.VirtualBox --source winget
   & "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" --version
   Get-CimInstance -ClassName Win32_SystemDriver -Filter "Name LIKE 'VBox%'" | Format-Table Name, State, StartMode
   Get-NetAdapter -InterfaceDescription 'VirtualBox Host-Only Ethernet Adapter*' | Format-Table Name, InterfaceDescription, Status
   ```

   - `Oracle.VirtualBox` の `7.2.20` の行と、`7.2.20r175154` が出ればよい
   - ドライバーは `VBoxSup`・`VBoxNetLwf`・`VBoxNetAdp`・`VBoxUSBMon` などが出て、`VBoxSup` が `Running` ならよい
   - ホストオンリーのアダプターが 1 つ出る（`Name` は `イーサネット 2` のように PC で違う）

1. Windows のデスクトップで、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）
   - この項の手順 1 の管理者の窓は、[Windows 11 の更新](#virtualbox-windows-11-の更新)・[Windows 11 のロールバック](extra/virtualbox.md#windows-11-のロールバック)で使う。閉じてもよい

1. 使い捨ての VM を画面無しで起動し、Hyper-V の上で動くかを見てから止めて消す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   $vbm = "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"
   if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
     Write-Error '管理者の PowerShell に貼っている（この節の手順 5 で開いた窓に貼る）'
   } else {
     & $vbm showvminfo vbox-selftest *> $null
     if ($LASTEXITCODE -eq 0) {
       Write-Error 'vbox-selftest はすでにある。変更せずに中断する'
     } else {
       & $vbm createvm --name vbox-selftest --ostype Other_64 --register
       if ($LASTEXITCODE -eq 0) {
         & $vbm modifyvm vbox-selftest --memory 64 --nic1 none --audio-enabled off
         if ($LASTEXITCODE -eq 0) {
           & $vbm startvm vbox-selftest --type headless
           if ($LASTEXITCODE -eq 0) {
             & $vbm showvminfo vbox-selftest --machinereadable | Select-String -Pattern '^VMState='
             & $vbm showvminfo vbox-selftest --log 0 | Select-String -Pattern 'fall back to NEM|Snail execution mode'
             & $vbm controlvm vbox-selftest poweroff
           }
         }
         & $vbm unregistervm vbox-selftest --delete
       } else {
         Write-Error 'VM を作れなかった。変更・起動・削除は行わない'
       }
     }
   }
   ```

   - `VM "vbox-selftest" has been successfully started.` と `VMState="running"` が出れば動いている
   - **`fall back to NEM` か `Snail execution mode` を含む行が出たら、VM は Hyper-V の上で動いている**（遅くなる。[注意点](extra/virtualbox.md#注意点)）
   - その行が出なければ、VirtualBox は VT-x / AMD-V を直接使っているはず
   - `poweroff` と `unregistervm` は `0%...100%` の行を出し、VM の登録と設定のファイルが消える
   - `%USERPROFILE%\VirtualBox VMs\vbox-selftest\Logs\VBoxHardening.log` が残ることがある。要らなければ `vbox-selftest` のフォルダーを手で消す
   - 既に `vbox-selftest` があれば、変更せず中断する。別の名前で試すなら、ブロック中の `vbox-selftest` をすべて同じ名前に変える

1. スタートメニューの「Oracle VirtualBox」で VirtualBox マネージャーを開き、閉じる。

   - デスクトップのショートカットでも、この項の手順 6 の窓で `& "$env:ProgramFiles\Oracle\VirtualBox\VirtualBox.exe"` を打っても同じ
   - VirtualBox マネージャーのウィンドウが開く（一覧は空）
   - 右クリックの「管理者として実行」では開かない
   - **次の手順は、ウィンドウを閉じてから貼る**

1. `%USERPROFILE%\.VirtualBox` に設定ができたか確かめる。

   ```powershell
   Get-ChildItem -LiteralPath "$env:USERPROFILE\.VirtualBox" | Format-Table Name, Length
   ```

   - `VirtualBox.xml`・`VBoxSVC.log` などが並べばよい

---

### VirtualBox: Windows 11 の VirtualBox を Android からリモート デスクトップで使う（任意）

> [!IMPORTANT]
> - **この節は Android の Windows App の画面で行う**。PC と VirtualBox の設定は変えない
> - 前提: この PC がリモート デスクトップを受け付けていること（[Windows 11 の初期設定の「ネットワークとリモート」の手順 2](#ネットワークとリモート)）と、[Windows 11 で使う](#virtualbox-windows-11-で使う)で入れた VirtualBox

- Windows App の既定の Unicode 送信では、VM に別のキーが入る（`1.,2` が `nczm`。[参考資料](reference/virtualbox.md)）
- この節で、Windows App がキーの位置（スキャンコード）を送るようにする。Windows App のすべての接続にかかる
- 日本語は Android の IME では打てなくなる。PC の IME は、物理キーボードの `` Alt+` `` で切り替える（Ctrl+Space は Android が受け取る）
- 実測は[検証記録](verification/virtualbox.md#付録-android-の-windows-app-からリモート-デスクトップでつないだときのキー入力2026-10-08)

1. Android の Windows App の設定で、「使用可能な場合にスキャンコード入力を使用する」をオンにする。

   - プロファイルのアイコンをタップして設定を開き、「全般」をタップする
   - 英語の表示では「Use scancode input when available」
   - 接続している間に変えても、セッションに戻るとすぐ効いた（つなぎ直さなくてよい）

1. Windows App でこの PC につなぎ、VM のウィンドウで文字を打って確かめる。

   - VM のウィンドウのタイトル バーをタップして前に出してから打つ
   - 打った英数字がそのまま VM に出ればよい（`1.,2` が `nczm` にならない）
   - 物理キーボード（US 配列）では、Shift で打つ記号（`@`・`:`）も出る
   - **画面のキーボード（Gboard）では、Shift で打つ記号に Shift が付かない**（`@` が `2`、`:` が `;`、`!` が `1`。PC のメモ帳でも同じ）
   - 英字の大文字は、画面のキーボードでも出る
   - 物理キーボードの右 Ctrl は、VirtualBox のホスト キー。右 Ctrl との組み合わせは、ゲストではなく VirtualBox が受け取る

1. 画面のキーボードで Shift の記号を打つときだけ、VirtualBox のソフトキーボードで打つ。

   - VM のウィンドウのメニューの「入力」→「キーボード」→「Soft Keyboard...」で開く（7.2.20 では、日本語の表示でもこの項目は英語）
   - 開いたキーボードの Shift をタップしてから `2` をタップすると、`@` が出る
   - メニュー バーが無いときは、VM のウィンドウがスケール モード（メニュー バーを出さない形）になっている
   - スケール モードは、PC で `& "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" setextradata <VM 名> GUI/Scale` を実行すると、VM を動かしたまま元の形に戻る

1. 元に戻すときは、この項の手順 1 の項目をオフにする。

   - Windows App は、打った文字を Unicode で送る既定に戻る

---

### VirtualBox: Windows 11 の更新

- この節は、[Windows 11 で使う](#virtualbox-windows-11-で使う)の手順 1 と同じ管理者の Windows PowerShell（5.1）に貼る
- 7.2 の中の更新も、系列が変わる更新（7.3 など。まだ出ていない）も、winget の同じ ID（`Oracle.VirtualBox`）で上がる。AlmaLinux 10 と違い、名前に系列が入らない
- VirtualBox マネージャーも、決まった間隔で新しい版を確かめる（環境設定の Update のタブ。マニュアル）。入れ替えは、この項の手順で行う
- **更新の途中でも、ネットワークがいったん切れるはず**（ドライバーを入れ直すため）
- VM の中の Guest Additions は、この節では上がらない（Atomic Desktop の VM は [VirtualBox の bootc ゲストの更新](almalinux-setup.md#virtualbox-の-bootc-ゲスト-更新)）

1. VirtualBox の VM と VirtualBox マネージャーをすべて閉じる。

   - VM は、それぞれのウィンドウを閉じるか、VirtualBox マネージャーから止める
   - **次の手順は、すべて閉じてから貼る**

1. VirtualBox が動いていないことと、新しい版があるかを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Process -Name VirtualBox, VirtualBoxVM, VBoxHeadless, VBoxSVC -ErrorAction SilentlyContinue | Format-Table Id, ProcessName
   winget list --exact --id Oracle.VirtualBox --source winget
   ```

   - プロセスは何も出なければよい
   - `VBoxSVC` だけが出たら、数秒待って貼り直す
   - `winget list` の版の列の右に、新しい版の列（英語の表示では `Available`）が出たら、新しい版がある
   - 新しい版の列が無ければ、この項の手順 3・4 は飛ばす

1. 新しい版があるときだけ、winget で上げる。

   ```powershell
   winget upgrade --exact --id Oracle.VirtualBox --source winget --accept-source-agreements --accept-package-agreements
   ```

   - 途中でネットワークがいったん切れるはず
   - **次の手順は、winget が終わってプロンプトに戻ってから貼る**（続けて貼ると、winget が何か聞いたときの答えとして食われる）

1. 新しい版にしたときだけ、新しい版になったか確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" --version
   winget list --exact --id Oracle.VirtualBox --source winget
   ```

   - 新しい版の番号が出て、`winget list` の新しい版の列が消えればよい


---

## VMware Workstation Pro（任意）

- この節だけを実施するときは、各項の前提・実行場所・権限を先に確認する
- [検証記録](verification/vmware.md)・[参考資料](reference/vmware.md)・[ロールバックと注意点](extra/vmware.md)

### VMware Workstation Pro: 実施手順

- [検証記録](verification/vmware.md)・[参考資料](reference/vmware.md)・[ロールバックと注意点](extra/vmware.md)

> [!IMPORTANT]
> - **Windows 11（x64）の PC のデスクトップで行う**（インストーラーはネットワークのドライバーを入れる。SSH やリモート デスクトップのセッションからは確かめていない）
> - [取得と確認](#vmware-workstation-pro-インストーラーを取得して確かめる)の手順 2 で開く **管理者の Windows PowerShell 5.1** に、インストールまで貼る
> - [導入後の確認](#vmware-workstation-pro-入ったかを確かめる)から後ろは、**管理者ではない Windows PowerShell 5.1** に貼る
> - ログインするユーザーは Administrators の一員（VMware Workstation は PC 全体に入り、ドライバーを入れる）
> - 前提: [Windows 11 の初期設定の「貼り付けの設定」の手順 1〜4](#貼り付けの設定)。通していなければ、ブロックは Ctrl+V で貼る
> - **インストーラーの取得には Broadcom のアカウントが要る**（個人利用は無償。winget には無い）
> - **Hyper-V や WSL 2 と併用するなら、先に Windows ハイパーバイザー プラットフォームを有効にする**（[Hyper-V](#hyper-v-hyper-v-を有効にして再起動する)の手順 2）
> - 有効化後に再起動待ちなら、[インストール](#vmware-workstation-pro-インストールする)の手順 2 で再起動する

- 上から順にコードブロックを貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

#### VMware Workstation Pro: インストーラーを取得して確かめる

1. ブラウザで Broadcom のサポート ポータルにログインし、VMware Workstation Pro の Windows 用のインストーラーを「ダウンロード」フォルダーに保存する。

   - ファイル名は `VMware-Workstation-Full-<版>-<ビルド番号>.exe` の形
   - **次の手順は、ダウンロードが終わってから行う**

1. Windows のデスクトップで、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. 変数を設定する（取得したインストーラーのパスが自動で入る。違えば直す）。

   ```powershell
   $VMW_SETUP = (Get-ChildItem -LiteralPath "$env:USERPROFILE\Downloads" -Filter 'VMware-Workstation-Full-*.exe' | Sort-Object LastWriteTime | Select-Object -Last 1).FullName
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   $VMW_SETUP
   ```

   - いま取得したファイルのパスが出ればよい
   - **ファイル名の版とビルド番号が、取得したものと同じことを確かめる**（古いインストーラーが同じフォルダーにあると、そちらが出ることがある）
   - 違うファイルが出たときと、何も出ないとき（別の場所に保存した）は、`$VMW_SETUP = '<インストーラーのパス>'` を打って入れ直す

1. インストーラーの署名と版を確かめる。

   ```powershell
   if (-not $VMW_SETUP) { Write-Error '中断: この項の手順 3 の $VMW_SETUP が空のまま。値を入れて貼り直す' } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-AuthenticodeSignature -LiteralPath $VMW_SETUP | Format-List Status, @{ n = 'Signer'; e = { $_.SignerCertificate.Subject } }
     (Get-Item -LiteralPath $VMW_SETUP).VersionInfo | Format-List ProductName, ProductVersion
   }
   ```

   - `Status : Valid` と、`Signer` に `Broadcom Inc` が出ればよい
   - **`Status` が `Valid` でなければ中断する**（ファイルを消して取得し直す）
   - `ProductVersion` が取得した版と違えば中断し、この項の手順 3 から直す

#### VMware Workstation Pro: インストールする

1. 使用許諾契約に同意して、画面無しでインストールする。

   ```powershell
   if (-not $VMW_SETUP) { Write-Error '中断: インストーラーを取得して確かめるの手順 3 の $VMW_SETUP が空のまま。その手順から貼り直す' } else {
     $p = Start-Process -FilePath $VMW_SETUP -ArgumentList '/s /v"/qn EULAS_AGREED=1 AUTOSOFTWAREUPDATE=0 DATACOLLECTION=0 REBOOT=ReallySuppress"' -Wait -PassThru
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     "ExitCode = $($p.ExitCode)"
   }
   ```

   - **注意**: `EULAS_AGREED=1` を付けて実行すると、VMware Workstation Pro の使用許諾契約に同意したことになる。契約を画面で読んでから進めるなら、このブロックは貼らずに、インストーラーをダブルクリックして画面で進める
   - `ExitCode = 0` なら入った。`ExitCode = 3010` は、入ったが再起動が要る
   - それ以外の値なら中断する（`%TEMP%` の `vminst.log` を見る）
   - `ExitCode = 0` で、Windows の機能の再起動待ちも無いなら、この項の手順 2 は飛ばす

1. `ExitCode = 3010` のときと、Windows の機能（Hyper-V など）が再起動待ちのときだけ、再起動する。

   ```powershell
   Restart-Computer
   ```

   - **開いている作業を保存し、動いている VM を止めてから貼る**（確認を聞かずに再起動が始まる）
   - Hyper-V の手順書の途中から来たなら、[Hyper-V の「Hyper-V を有効にして再起動する」の手順 4](#hyper-v-hyper-v-を有効にして再起動する)の再起動がこれに当たる（再起動は 1 回でよい）
   - **次の手順は、起動してサインインしてから行う**

#### VMware Workstation Pro: 入ったかを確かめる

1. Windows のデスクトップで、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. 入った版と、コマンドの場所、仮想ネットワークを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   $VMW_DIR = @("$env:ProgramFiles\VMware\VMware Workstation", "${env:ProgramFiles(x86)}\VMware\VMware Workstation") | Where-Object { Test-Path -LiteralPath "$_\vmrun.exe" } | Select-Object -First 1
   if (-not $VMW_DIR) { Write-Error 'vmrun.exe が見つからない。インストールできていない' } else {
     $VMW_DIR
     (Get-Item -LiteralPath "$VMW_DIR\vmware.exe").VersionInfo | Format-List ProductName, ProductVersion
     & "$VMW_DIR\vmrun.exe" -T ws list
     Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'VMware Network Adapter*' | Format-Table InterfaceAlias, IPAddress, PrefixLength
   }
   ```

   - インストール先のフォルダーと版が出て、`Total running VMs: 0` が出ればよい
   - `VMware Network Adapter VMnet1`（この PC と VM だけ）と `VMnet8`（NAT）の行が出る

#### VMware Workstation Pro: VM を作る

1. 変数を設定する（`VMW_ISO` は必ず値を入れる）。

   ```powershell
   $VMW_ISO = ''
   ```

   ```powershell
   $VMW_VM = 'alma10'
   $VMW_BASE = "$env:USERPROFILE\VMware"
   $VMW_GUEST = 'almalinux-64'
   $VMW_CPU = 2
   $VMW_MEM_MB = 4096
   $VMW_DISK = '64GB'
   $VMW_DIR = @("$env:ProgramFiles\VMware\VMware Workstation", "${env:ProgramFiles(x86)}\VMware\VMware Workstation") | Where-Object { Test-Path -LiteralPath "$_\vmrun.exe" } | Select-Object -First 1
   $VMW_VMX = "$VMW_BASE\$VMW_VM\$VMW_VM.vmx"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{ VMW_ISO = $VMW_ISO; VMW_VM = $VMW_VM; VMW_VMX = $VMW_VMX; VMW_GUEST = $VMW_GUEST; VMW_CPU = $VMW_CPU; VMW_MEM_MB = $VMW_MEM_MB; VMW_DISK = $VMW_DISK; VMW_DIR = $VMW_DIR } | Format-List
   ```

   - `$VMW_ISO` は、入れる OS のインストール用の ISO のパス
   - `$VMW_VM` は VM の名前、`$VMW_BASE` は VM を置くフォルダー（その下に VM の名前のフォルダーができる）
   - `$VMW_GUEST` は入れる OS の種類（既定は AlmaLinux）。本書は、Windows 11 を入れる VM（仮想 TPM が要る）を扱わない
   - `VMW_DIR` が空なら、VMware Workstation が入っていない。[インストールする](#vmware-workstation-pro-インストールする)から
   - 新しい窓を開いたら、この手順を貼り直す

1. VM の設定ファイルとディスクを作る。

   ```powershell
   if (-not $VMW_ISO) { Write-Error '中断: この項の手順 1 の $VMW_ISO が空のまま。値を入れて貼り直す' } elseif (-not (Test-Path -LiteralPath $VMW_ISO)) { Write-Error "中断: ISO が無い: $VMW_ISO" } elseif (Test-Path -LiteralPath "$VMW_BASE\$VMW_VM") { Write-Error "中断: 同じ名前のフォルダーがすでにある: $VMW_BASE\$VMW_VM" } else {
     & "$VMW_DIR\vmcli.exe" VM Create -n $VMW_VM -d "$VMW_BASE\$VMW_VM" -c $VMW_GUEST
     Remove-Item -LiteralPath "$VMW_BASE\$VMW_VM\$VMW_VM.vmdk"
     & "$VMW_DIR\vmcli.exe" $VMW_VMX Disk Create -f "$VMW_BASE\$VMW_VM\$VMW_VM.vmdk" -a lsilogic -s $VMW_DISK -t 0
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-ChildItem -LiteralPath "$VMW_BASE\$VMW_VM" | Format-Table Name, Length
   }
   ```

   - `VMX file is created` と `Virtual disk file creation is successful` が出て、一覧に `.vmx` と `.vmdk` が並べばよい

1. ファームウェア・CPU・メモリ・ディスク・ISO・NIC を設定する。

   ```powershell
   $vmcli = "$VMW_DIR\vmcli.exe"
   & $vmcli $VMW_VMX ConfigParams SetEntry displayName $VMW_VM
   & $vmcli $VMW_VMX ConfigParams SetEntry firmware efi
   & $vmcli $VMW_VMX ConfigParams SetEntry cpuid.coresPerSocket $VMW_CPU
   & $vmcli $VMW_VMX Chipset SetVCpuCount $VMW_CPU
   & $vmcli $VMW_VMX Chipset SetMemSize $VMW_MEM_MB
   & $vmcli $VMW_VMX MKS SetAccel3d false
   & $vmcli $VMW_VMX Nvme SetPresent nvme0 1
   & $vmcli $VMW_VMX Disk SetBackingInfo nvme0:0 disk "$VMW_BASE\$VMW_VM\$VMW_VM.vmdk" 0
   & $vmcli $VMW_VMX Disk SetPresent nvme0:0 1
   & $vmcli $VMW_VMX Sata SetPresent sata0 1
   & $vmcli $VMW_VMX Disk SetBackingInfo sata0:0 cdrom_image $VMW_ISO 0
   & $vmcli $VMW_VMX Disk SetPresent sata0:0 1
   & $vmcli $VMW_VMX Ethernet SetVirtualDevice ethernet0 vmxnet3
   & $vmcli $VMW_VMX Ethernet SetConnectionType ethernet0 nat
   & $vmcli $VMW_VMX Ethernet SetPresent ethernet0 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Content -LiteralPath $VMW_VMX | Select-String -Pattern '^(displayName|guestOS|firmware|numvcpus|memsize|mks\.enable3d|nvme0|sata0|ethernet0)'
   ```

   - `firmware = "efi"`、`numvcpus`、`memsize`、`nvme0:0.fileName`、`sata0:0.fileName`（ISO）、`ethernet0.connectionType = "nat"` の行が出ればよい
   - `mks.enable3d` の行は出ない（3D を切った）

#### VMware Workstation Pro: VM を起動して OS を入れる

1. VM を起動する。

   ```powershell
   & "$VMW_DIR\vmrun.exe" -T ws start $VMW_VMX
   ```

   - `PID: <番号>, log output: <ログのパス>` の 1 行が出て、VMware Workstation のウィンドウが開き、VM が起動する

1. VM の画面で、OS のインストーラーを最後まで進める。

   - VM の画面をクリックすると、キーとマウスが VM に入る。Ctrl+Alt でこの PC に戻る
   - インストーラーが最後に再起動するか、電源を切るまで進める
   - **次の手順は、インストールが終わり、VM の電源を切ってから貼る**

1. ISO を外す。

   ```powershell
   & "$VMW_DIR\vmcli.exe" $VMW_VMX Disk SetPresent sata0:0 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   "sata0:0.present の行の数: $(@(Select-String -LiteralPath $VMW_VMX -Pattern '^sata0:0\.present').Count)"
   ```

   - `sata0:0.present の行の数: 0` が出ればよい

#### VMware Workstation Pro: 動作を確かめる

1. VM を画面無しで起動し、Hyper-V の上で動いているかと、ゲストの IP を確かめる。

   ```powershell
   & "$VMW_DIR\vmrun.exe" -T ws start $VMW_VMX nogui
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & "$VMW_DIR\vmrun.exe" -T ws list
   Select-String -LiteralPath "$VMW_BASE\$VMW_VM\vmware.log" -Pattern 'Monitor Mode:' | Select-Object -Last 1 | ForEach-Object { ($_.Line -split '\] ')[-1] }
   & "$VMW_DIR\vmrun.exe" -T ws readVariable $VMW_VMX guestVar ip
   ```

   - `Total running VMs: 1` と、VM の `.vmx` のパスが出ればよい
   - **`Monitor Mode: ULM` なら、VM は Windows のハイパーバイザー（Hyper-V）の上で動いている**（遅くなる）
   - 最後の行にゲストの IP が出る。空なら、ゲストがまだ起動の途中。少し待って、最後の行だけを打ち直す
   - ゲストに VMware Tools（Linux は `open-vm-tools`）が入っていないと、IP は出ない（AlmaLinux 10 の Workstation には入っている）

1. Linux のゲストなら、この PC から SSH で入れるかを確かめる。

   - この窓で `ssh <ゲストのユーザー>@<ゲストの IP>` を打つ（IP はこの項の手順 1 の最後の行）
   - ゲストのプロンプトが出ればよい。`exit` で戻る

---

### VMware Workstation Pro: 使い方の基本

- 管理者ではない Windows PowerShell 5.1 で打つ。`<vmx>` は VM の `.vmx` のパス。`$VMW_DIR` は[VM を作る](#vmware-workstation-pro-vm-を作る)の手順 1 で設定する

| すること | コマンド |
|---|---|
| 動いている VM の一覧 | `vmrun.exe -T ws list` |
| 起動する（ウィンドウを開く） | `vmrun.exe -T ws start <vmx>` |
| 起動する（画面無し） | `vmrun.exe -T ws start <vmx> nogui` |
| ゲストに電源を切らせる | `vmrun.exe -T ws stop <vmx> soft` |
| 電源を切る（ゲストに知らせない） | `vmrun.exe -T ws stop <vmx> hard` |
| ゲストの IP を見る | `vmrun.exe -T ws readVariable <vmx> guestVar ip` |
| 画面を PNG に撮る | `vmcli.exe <vmx> MKS captureScreenshot <PNG のパス>` |
| 画面に文字を打つ | `vmcli.exe <vmx> MKS sendKeySequence <文字列>` |
| CPU の数を変える（止めてから） | `vmcli.exe <vmx> Chipset SetVCpuCount 4` |
| メモリを変える（止めてから） | `vmcli.exe <vmx> Chipset SetMemSize 8192` |

---

### VMware Workstation Pro: スナップショットとクローン

- スナップショットは、VM のその時点の状態。戻したり、そこから別の VM（リンククローン）を作ったりできる
- 管理者ではない Windows PowerShell（5.1）に貼る。[VM を作る](#vmware-workstation-pro-vm-を作る)の手順 1 の変数を使う

> [!WARNING]
> **この項の手順 3 で作った VM があるあいだは、元の VM とそのスナップショットを消さない**。リンククローンは元の VM のディスクを読むので、消すと起動しなくなる。

1. VM を止めて、スナップショットを取る。

   ```powershell
   $VMW_SNAPSHOT = 'clean-install'
   & "$VMW_DIR\vmrun.exe" -T ws stop $VMW_VMX soft
   & "$VMW_DIR\vmrun.exe" -T ws snapshot $VMW_VMX $VMW_SNAPSHOT
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & "$VMW_DIR\vmrun.exe" -T ws listSnapshots $VMW_VMX
   ```

   - `Total snapshots: 1` と、付けた名前が出ればよい
   - VM がすでに止まっていれば、`stop` は `Error: The virtual machine is not powered on` を出す（そのまま進んでよい）

1. VM をスナップショットの時点に戻すときは、VM を止めてから戻す。

   ```powershell
   & "$VMW_DIR\vmrun.exe" -T ws stop $VMW_VMX hard
   & "$VMW_DIR\vmrun.exe" -T ws revertToSnapshot $VMW_VMX $VMW_SNAPSHOT
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & "$VMW_DIR\vmrun.exe" -T ws listSnapshots $VMW_VMX
   ```

   - **スナップショットより後の変更は消える**
   - VM がすでに止まっていれば、`stop` は `Error: The virtual machine is not powered on` を出す（そのまま進んでよい）

1. スナップショットの時点から、リンククローンで別の VM を作る。

   ```powershell
   $VMW_CLONE = "$VMW_VM-clone"
   if (Test-Path -LiteralPath "$VMW_BASE\$VMW_CLONE") { Write-Error "中断: 同じ名前のフォルダーがすでにある: $VMW_BASE\$VMW_CLONE" } else {
     & "$VMW_DIR\vmrun.exe" -T ws clone $VMW_VMX "$VMW_BASE\$VMW_CLONE\$VMW_CLONE.vmx" linked "-snapshot=$VMW_SNAPSHOT" "-cloneName=$VMW_CLONE"
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-ChildItem -LiteralPath "$VMW_BASE\$VMW_CLONE" | Format-Table Name, Length
     Get-Content -LiteralPath "$VMW_BASE\$VMW_CLONE\$VMW_CLONE.vmx" | Select-String -Pattern '^(displayName|nvme0:0\.fileName)'
   }
   ```

   - 新しいフォルダーに `.vmx` と、小さい `.vmdk`（差分）ができればよい
   - 新しい VM は、ホスト名もログインも元の VM と同じ。起動してから、ゲストの中でホスト名を変える
   - 起動: `& "$VMW_DIR\vmrun.exe" -T ws start "$VMW_BASE\$VMW_CLONE\$VMW_CLONE.vmx" nogui`
   - IP の確認: `& "$VMW_DIR\vmrun.exe" -T ws readVariable "$VMW_BASE\$VMW_CLONE\$VMW_CLONE.vmx" guestVar ip`

---

### VMware Workstation Pro: VM を消す

> [!CAUTION]
> **この項の手順 1 は、VM のディスクごと消す（取り戻せない）**。[スナップショットとクローン](#vmware-workstation-pro-スナップショットとクローン)の手順 3 で、この VM から作った VM が残っているなら、先にそちらを消す。

- 管理者ではない Windows PowerShell（5.1）に貼る。[VM を作る](#vmware-workstation-pro-vm-を作る)の手順 1 の変数（`$VMW_DIR`）を使う

1. VM を止めて、登録とファイルを消す（取り戻せない）。

   ```powershell
   $VMW_REMOVE = ''
   ```

   ```powershell
   if (-not $VMW_REMOVE) { Write-Error '中断: $VMW_REMOVE が空のまま。消す VM の .vmx のパスを入れて貼り直す' } elseif (-not (Test-Path -LiteralPath $VMW_REMOVE)) { Write-Error "中断: .vmx が無い: $VMW_REMOVE" } else {
     & "$VMW_DIR\vmrun.exe" -T ws stop $VMW_REMOVE hard
     & "$VMW_DIR\vmrun.exe" -T ws deleteVM $VMW_REMOVE
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     & "$VMW_DIR\vmrun.exe" -T ws list
     Test-Path -LiteralPath $VMW_REMOVE
   }
   ```

   - 最後に `False` が出ればよい
   - VM が止まっていれば、`stop` は `Error: The virtual machine is not powered on` を出す（そのまま進んでよい）

---


---

## Claude Code の Remote Control（任意）

- この節だけを実施するときは、各項の前提・実行場所・権限を先に確認する
- [検証記録](verification/windows-claude-remote-control.md)・[参考資料](reference/windows-claude-remote-control.md)
- [ロールバックと注意点](extra/windows-claude-remote-control.md)

### Claude Code の Remote Control: 実施手順

> [!IMPORTANT]
> - **すべて、SSH でログインした Windows で行う**。この項の手順 1 で起動する Windows PowerShell 5.1 に貼る。停止・ロールバックも同じ窓を使い、デスクトップの PowerShell には貼らない
> - **Administrators のユーザーでログインする**。タスク登録に管理者の権限が要る。SSH のセッションは UAC 無しで管理者の権限を持つ
> - 前提: [OpenSSH サーバー](#openssh-サーバー)で SSH ログインでき、[Claude Code](#claude-code)を公式の native installer で入れてある
> - `claude` の `/login` で claude.ai（Pro / Max / Team / Enterprise）にログイン済み。API キーでは Remote Control を使えない
> - [WezTerm](#wezterm)は `C:\Program Files\WezTerm` に入れ、[貼り付けの設定](#貼り付けの設定)の手順 1〜4 を通す。SSH の PowerShell も同じプロファイルを読む
> - **デスクトップにログインしたままにする**。タスクはそのセッションで WezTerm を開くので、ログオフすると動かない（[注意点](extra/windows-claude-remote-control.md#注意点)）
> - 再起動後の自動サインインは[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 5 で設定する
> - **手順 4 には対話入力がある**（ディレクトリの信頼のダイアログと、初回の Remote Control の確認。URL が出たら Ctrl+C）

- 上から順にコードブロックを貼る。手順 2 で変数を設定した PowerShell に貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

> [!WARNING]
> **Remote Control をつなぐと、この claude.ai のアカウントで入れる人が、スマートフォンやブラウザからこの PC の `<PROJECT_DIR>` で、このユーザーとして Claude Code を動かせる**（ファイルの読み書きとコマンドの実行。SSH のセッションから登録するので、タスクは管理者の権限を持ちうる）。会話の転写（メッセージ・応答・ツールの動き）は Anthropic のサーバーに保存される（[注意点](extra/windows-claude-remote-control.md#注意点)）。タスクが開く WezTerm の窓はデスクトップに見える。窓を閉じる・中で Ctrl+C すると Claude Code が止まる。

1. クライアントの PC から Windows に SSH でログインし、Windows PowerShell を起動する。

   - `ssh <WIN_USER>@<WIN_HOST>` でログインする（[Windows 11 の初期設定の「SSH でログインを確かめる」の手順 4](#ssh-でログインを確かめる)と同じ。スマートフォンの SSH のアプリでもよい）
   - ログインした先のシェルが Git Bash でも cmd でも、`powershell` と打つ
   - プロンプトが `PS C:\Users\<WIN_USER>>` になる
   - **次の手順は、このプロンプトが出てから貼る**（続けて貼ると、ログインした先のシェルへの入力として食われる）

1. 変数を設定する（`PROJECT_DIR` は必ず値を入れる）。

   ```powershell
   $PROJECT_DIR = ''                     # ← Remote Control のセッションを動かすディレクトリ（プロジェクト）を書く。<PROJECT_DIR>
   ```

   ```powershell
   $RC_NAME = if ($PROJECT_DIR) { Split-Path $PROJECT_DIR -Leaf }   # claude.ai/code とアプリに出るセッション名（既定はディレクトリ名）。<RC_NAME>
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'PROJECT_DIR = {0}' -f $PROJECT_DIR
   'RC_NAME     = {0}' -f $RC_NAME
   ```

   - 最後に値を読み戻して確かめる
   - `PROJECT_DIR` は、`C:\Users\<WIN_USER>\src\myproject` のような、存在するプロジェクトのディレクトリの絶対パス。ホームそのもの（`C:\Users\<WIN_USER>`）は使えない
   - **新しい PowerShell を開いたら**、手順 2 のブロックを貼り直してから先へ進む

1. Claude Code・WezTerm・ログインと、デスクトップのセッションを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   claude --version
   claude auth status --text
   & 'C:\Program Files\WezTerm\wezterm.exe' --version
   quser
   ```

   - `claude` の版と、ログイン済みを示す行、`wezterm 2026…` が出ればよい
   - `quser` に、自分のユーザーの `console` の行が `Active` で出ること。出なければ、この PC にログインしてから続ける
   - RDP で使った後にふつうに切断していると、自分の行のセッション名が空で、状態が `Disc`（切断）になる。RDP でつなぎ直し、[RDP をロックせずに切断する手順](#rdp-をロックせずに切断-実施手順)で切ると `console` に戻る
   - `claude remote-control --help` は貼らない

1. 初回だけ、対話で起動して信頼と Remote Control の確認に答え、URL が出たら止める。

   ```powershell
   if (-not $PROJECT_DIR) {
     Write-Error '手順 2 の $PROJECT_DIR が空'
   } elseif (-not (Test-Path -LiteralPath $PROJECT_DIR -PathType Container)) {
     Write-Error '中断: $PROJECT_DIR は存在するディレクトリではない'
   } else {
     Set-Location -LiteralPath $PROJECT_DIR -ErrorAction Stop
     claude remote-control --name $RC_NAME --spawn same-dir
   }
   ```

   - ディレクトリが無い、ファイルを指定した、または移動できない場合は起動しない。手順 2 の値とディレクトリへのアクセスを確かめてから貼り直す
   - 信頼のダイアログ（`Is this a project you created or one you trust?`）が出たら、**↓ で `Yes, I trust this folder` を選び Enter**（既定は `No, exit`）
   - 初めて Remote Control を使うときは `Enable Remote Control? (y/n)` が出る。`y`
   - `https://claude.ai/code/<SESSION_ID>` の URL と `space to show QR code` が出れば、起動できている
   - **Ctrl+C** で止める
   - **次の手順は、Ctrl+C で止めてプロンプトに戻ってから貼る**（続けて貼ると Claude Code への入力として食われる）

1. タスクを登録する（WezTerm で `claude remote-control` を起動するタスク）。

   ```powershell
   if (-not $PROJECT_DIR) {
     Write-Error '手順 2 の $PROJECT_DIR が空'
   } elseif (-not (Test-Path -LiteralPath $PROJECT_DIR -PathType Container)) {
     Write-Error '中断: $PROJECT_DIR は存在するディレクトリではない'
   } else {
     $me = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
     $wt = 'C:\Program Files\WezTerm\wezterm.exe'
     $arg = 'start --cwd "{0}" -- claude remote-control --name "{1}" --spawn same-dir' -f $PROJECT_DIR, $RC_NAME
     $action = New-ScheduledTaskAction -Execute $wt -Argument $arg
     $principal = New-ScheduledTaskPrincipal -UserId $me -LogonType Interactive
     $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Register-ScheduledTask -TaskName 'claude-remote-control' -Action $action -Principal $principal -Settings $settings -Force | Format-List TaskName, State
   }
   ```

   - `State : Ready` が出ればよい

1. タスクを開始し、動いていることを確かめる。

   ```powershell
   Start-ScheduledTask -TaskName 'claude-remote-control'
   Start-Sleep -Seconds 8
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-ScheduledTask -TaskName 'claude-remote-control').State
   Get-CimInstance Win32_Process -Filter "Name='claude.exe'" | Where-Object CommandLine -like '*--spawn same-dir*' | Select-Object ProcessId, ParentProcessId | Format-Table -AutoSize
   ```

   - `Running` と、`claude.exe` のプロセスが出ればよい（親は WezTerm）
   - デスクトップには WezTerm の窓が開き、中で Claude Code が動く
   - 数十秒で claude.ai/code の一覧に `<RC_NAME>` が出る（手順 8 で確かめる）

1. SSH の接続を切る。

   ```powershell
   exit
   ```

   - ログインした先のシェルに戻る（Git Bash なら `<WIN_USER>@<HOSTNAME> MINGW64 ~`、cmd なら `C:\Users\<WIN_USER>>`）
   - そこでもう 1 度 `exit` と打つと、SSH が切れてクライアントのプロンプトに戻る。SSH のアプリで接続を閉じてもよい
   - タスクで起動した WezTerm と Claude Code は、デスクトップのセッションに残る

1. 切断した後も、スマートフォンかブラウザからセッションが使えることを確かめる。

   - claude.ai/code か、Claude のアプリの **Code** の一覧に `<RC_NAME>` が、コンピューターのアイコンと緑の点付きで出る
   - 開いてメッセージを送ると、この PC の `<PROJECT_DIR>` で Claude Code が動いて返事が来る
   - 返事が来なければ、手順 9 でログインし直して確かめる

1. 必要なら SSH でログインし直し、タスクとプロセスが残っていることを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-ScheduledTask -TaskName 'claude-remote-control').State
   Get-CimInstance Win32_Process -Filter "Name='claude.exe'" | Where-Object CommandLine -like '*--spawn same-dir*' | Select-Object ProcessId | Format-Table -AutoSize
   ```

   - `Running` と、手順 6 と同じプロセスが残っている
   - 手順 2 の変数は要らない

---

### Claude Code の Remote Control: 止める・もう一度始める

- この節は、SSH でログインした PowerShell に貼る（変数は要らない）
- 止めるのはこの項の手順 1、もう一度始めるのは手順 2

1. セッションを止める。

   ```powershell
   Stop-ScheduledTask -TaskName 'claude-remote-control'
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-CimInstance Win32_Process -Filter "Name='claude.exe'" | Where-Object CommandLine -like '*--spawn same-dir*' | Select-Object ProcessId | Format-Table -AutoSize
   ```

   - `claude.exe` のプロセスが消える（デスクトップで別に動かしている分は残る）
   - WezTerm の窓も閉じる

1. もう一度始めるときは、タスクを開始する。

   ```powershell
   Start-ScheduledTask -TaskName 'claude-remote-control'
   ```

   - 止めてから約 4 時間以内なら、claude.ai/code の同じセッションが戻る（それを過ぎると新しいセッションになる。公式ドキュメント）
   - ネットワークが約 10 分切れると、Claude Code のサーバーは自分で終わり WezTerm の窓が閉じる（公式ドキュメント）。そのときもこの手順で始め直す


---

## Windows のホットキー競合（任意）

- この節だけを実施するときは、各項の前提・実行場所・権限を先に確認する
- [検証記録](verification/windows-hotkey-conflict.md)・[参考資料](reference/windows-hotkey-conflict.md)・[ロールバックと注意点](extra/windows-hotkey-conflict.md)

### Windows のホットキー競合: 実施手順

> [!IMPORTANT]
> - 問題が起きる Windows 11 のユーザー・ログインセッションで実施する
> - 検出時には対象キーが実際に入力され、対応する操作が実行されることもある。先に作業を保存する
> - Hotkey Screener を未導入なら、[初回準備](#windows-のホットキー競合-初回準備)を先に行う
> - PowerShell を使う任意手順は、通常権限の Windows PowerShell 5.1 で実施する
> - 複数行のコードは Ctrl+V で貼る。[Windows の初期設定の「貼り付けの設定」](#貼り付けの設定)の手順 1〜4で設定済みなら、その貼り付け方法も使える

- 普段の調査は次の 6 手順で行う
- PowerShell に貼った後は、反転表示の「確認」から後ろの出力を、各手順の箇条書きで確かめる
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
   - 権限要求が頻発する場合は、[Program Files への配置](#windows-のホットキー競合-権限要求を減らすために-program-files-へ配置する任意)を行う

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
   - 書き方は[検証記録](verification/windows-hotkey-conflict.md)を参照する

---

### Windows のホットキー競合: 初回準備

- ZIP の取得と展開は初回だけ行う。更新する場合はツールを終了してから行う
- 検証した版とファイル構成は[検証記録](verification/windows-hotkey-conflict.md)を参照する
- 権限要求が頻発する場合は、[Program Files への配置](#windows-のホットキー競合-権限要求を減らすために-program-files-へ配置する任意)も行う

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
   - [実施手順](#windows-のホットキー競合-実施手順)の手順 1へ進む

---

### Windows のホットキー競合: 権限要求を減らすために Program Files へ配置する（任意）

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
   - [実施手順](#windows-のホットキー競合-実施手順)の手順 2へ戻り、対象キーだけ検出する

---

### Windows のホットキー競合: 使用アプリが分からない場合の切り分け

- 対象キーが一覧にない場合、検出でアプリが表示されない場合、設定変更で解消しない場合に行う
- 表示がない理由と、入力フック・アプリ内ショートカットの検出範囲は[参考資料](reference/windows-hotkey-conflict.md)を参照する

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

   - 解消しなければ候補の設定を元に戻し、終了した候補を通常起動してから、この項の手順 5で次の候補を調べる
   - 解消した場合は[実施手順](#windows-のホットキー競合-実施手順)の手順 5で必要な設定と保存状態を確認し、手順 6で結果を残して終了する
   - 特定できない場合は、次の任意手順も使い、試した入力条件・候補・ログを追加調査用に残す

---

### Windows のホットキー競合: ホットキーの登録可否を確認する（任意）

- アプリ名を返す試験ではない。登録成功でも、IME や入力フックによる処理は除外できない
- 試験中だけ対象キーを一時登録し、直ちに解除する。コードの実行中は対象キーを押さない
- 問題が起きるユーザー・セッションの、新しい通常権限の Windows PowerShell 5.1 で行う

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
   - [使用アプリが分からない場合の切り分け](#windows-のホットキー競合-使用アプリが分からない場合の切り分け)の手順 5へ戻り、アプリ設定と実操作で候補を絞る

---


---

## RDP をロックせずに切断（任意）

- この節だけを実施するときは、各項の前提・実行場所・権限を先に確認する
- [検証記録](verification/windows-rdp-disconnect.md)・[参考資料](reference/windows-rdp-disconnect.md)・[ロールバックと注意点](extra/windows-rdp-disconnect.md)

### RDP をロックせずに切断: 実施手順

> [!IMPORTANT]
> - **手順 1〜3 は、RDP（リモートデスクトップ）でつないだ Windows のセッションの中で行う**。手順 1 で管理者の Windows PowerShell（5.1）を開き、手順 2・3 をそこに貼る
> - 前提: Windows 11 Pro 以上で RDP 接続できること（Home は受け付けられない）。[ネットワークとリモート](#ネットワークとリモート)の手順 2、または設定の「システム → リモート デスクトップ」で有効にする
> - PC にサインイン中のユーザーでつなぐ。`tscon` に管理者の権限が要るので、そのユーザーは Administrators の一員にする
> - 前提: [Windows 11 の初期設定の「貼り付けの設定」の手順 1〜4](#貼り付けの設定)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ貼り付けの設定）。通していなければ、ブロックは Ctrl+V で貼る
> - **手順 3 を貼ると、その場で RDP が切れる**
> - **手順 4・5 は、クライアントの PC から SSH で行う**（[Windows 11 の初期設定の「OpenSSH サーバー」](#openssh-サーバー)）。SSH が無ければ、PC の前で画面を見る

- 上から順にコードブロックを貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

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
   - 自分の行のセッション名が `console` なら、PC の前のセッション（RDP ではない）。手順 3 は貼らない

1. セッションを PC の画面（コンソール）へ移し、RDP を切る。

   ```powershell
   tscon.exe (Get-Process -Id $PID).SessionId /dest:console
   ```

   - RDP のクライアントの窓が閉じる（クライアントが切断を知らせる）
   - 切れずに PowerShell にエラーが出たときは、管理者の PowerShell かを確かめて、手順 1 からやり直す
   - **次の手順は、RDP が切れてから、クライアントの PC で行う**（この手順の後ろに行を続けて貼らない）

1. クライアントの PC から、Windows に SSH でログインする。

   - `ssh <WIN_USER>@<WIN_HOST>` でログインする（[Windows 11 の初期設定の「SSH でログインを確かめる」の手順 4](#ssh-でログインを確かめる)と同じ）
   - PC の前にいるなら、SSH の代わりに PC の画面を見る。ロック画面ではなく、RDP で開いていたままのデスクトップが出ていればよい。そのときは手順 5 は飛ばす
   - **次の手順は、ログインした先のプロンプトが出てから貼る**（続けて貼ると、ログインの途中の入力として食われる）

1. SSH でログインしたシェルで、セッションが PC の画面に戻ったことを確かめる。

   ```powershell
   quser
   ```

   - 自分の行のセッション名が `console` で、状態が `Active`。ID は手順 2 と同じ
   - ログインした先のシェルが Git Bash でも cmd でも、そのまま `quser` と打てばよい

---

### RDP をロックせずに切断: ショートカットで切断する（任意）

- [実施手順](#rdp-をロックせずに切断-実施手順)の手順 1〜3 を、デスクトップのアイコンのダブルクリックにする。UAC の確認は毎回出る
- この項の手順 1 は、RDP でつないだセッションの中の Windows PowerShell に貼る（管理者でなくてよい。実施手順の手順 1 で開いたものに貼るなら、手順 3 より前に）
- ショートカットは、管理者として実行する Windows PowerShell で、手順 3 と同じ `tscon` を動かす

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

   - UAC の確認（Windows PowerShell）で「はい」を押すと、RDP が切れる（実施手順の手順 3 と同じ）
   - 切れないときは、[実施手順](#rdp-をロックせずに切断-実施手順)の手順 1〜3 で切って、エラーを見る
   - PC の前（コンソール）では使わない
   - 切った後の確かめ方は、実施手順の手順 4・5 と同じ


---

## Windows の OpenSSH クライアント（任意）

- この節だけを実施するときは、各項の前提・実行場所・権限を先に確認する
- [検証記録](verification/windows-ssh-client.md)・[参考資料](reference/windows-ssh-client.md)・[ロールバックと注意点](extra/windows-ssh-client.md)

### Windows の OpenSSH クライアント: 実施手順

- [検証記録](verification/windows-ssh-client.md)・[参考資料](reference/windows-ssh-client.md)・[ロールバックと注意点](extra/windows-ssh-client.md)

> [!IMPORTANT]
> - **この項の手順 8 だけ AlmaLinux 10 のホストで、ほかは Windows で行う**
> - この項の手順 1 で開く **管理者ではない Windows PowerShell 5.1** に貼る。更新・ロールバックも同じ窓を使う
> - 管理者の権限は要らない。Windows で変えるのは、自分のユーザーの `%USERPROFILE%\.ssh` だけ（ホストでは、手順 9 で自分のユーザーの `~/.ssh/authorized_keys` に足す）
> - 前提: [Windows 11 の初期設定の「貼り付けの設定」の手順 1〜4](#貼り付けの設定)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ貼り付けの設定）。通していなければ、ブロックは Ctrl+V で貼る
> - 前提: [Git for Windows](#git-for-windows) が `C:\Program Files\Git` に入っていること（Git の ssh でも同じ config を読めるかを、手順 7・10 で確かめる）
> - 前提: つなぐ先の AlmaLinux 10 のホストで sshd が動き、そのユーザーのパスワードで SSH に入れること（AlmaLinux 10 の既定。[注意点](extra/windows-ssh-client.md#注意点)）
> - **手順 4 と手順 9 には対話入力がある**（手順 4 は鍵を作るか公開鍵を作り直すときのパスフレーズ、手順 9 はホスト鍵の確認とホストのユーザーのパスワード）。鍵にパスフレーズを付けたなら、手順 10（2 回）・11 でも聞かれる

- 上から順にコードブロックを貼る。Windows の手順は手順 2 で変数を設定した PowerShell に、手順 8 はホストの端末に貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 鍵・config・known_hosts は `%USERPROFILE%\.ssh` に置き、Windows の ssh（PowerShell・WezTerm の起動メニュー）と Git の ssh（Git Bash・git）の両方で使う
- ssh-agent は使わない。鍵にパスフレーズを付けたら、その鍵を使うたびに（ssh・scp・ssh を使う git・WezTerm の起動メニュー）パスフレーズを聞かれる
- 逆向き（AlmaLinux 10 などから Windows 11 に入る）は、[Windows 11 の初期設定の「OpenSSH サーバー」](#openssh-サーバー)

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
   - **新しい PowerShell を開いたら**、手順 2 の 3 つのブロックを貼り直してから先へ進む

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
   - どれかに値があれば、git が別の ssh か別の `.ssh` を使う。その設定を外すまで、手順 7・10 の Git の ssh の確かめは、git の動きと一致しない

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
   - `中断: … 公開鍵を作れなかった` の前に `UNPROTECTED PRIVATE KEY FILE!` が出ていれば、手順 5・6 で秘密鍵のアクセス権を直してから、この手順を貼り直す
   - その表示が無ければ、パスフレーズが違う。この手順を貼り直す
   - 鍵が無ければ、`Enter passphrase (empty for no passphrase):` と `Enter same passphrase again:` でパスフレーズを 2 回聞かれ、鍵の指紋が出る
   - パスフレーズを付けると、鍵を使うたびに聞かれる。空にすると聞かれないが、秘密鍵のファイルを持つ人は誰でも入れる
   - **次の手順は、パスフレーズを入力し終えてから貼る**（続けて貼るとパスフレーズとして食われる）

1. 秘密鍵のアクセス権を確かめる。

   ```powershell
   icacls.exe "$env:USERPROFILE\.ssh\id_ed25519"
   ```

   - 出てくる主体が `NT AUTHORITY\SYSTEM`・`BUILTIN\Administrators`・自分のユーザー（`<HOSTNAME>\<WIN_USER>`）の 3 つだけならよい（`(I)` の付いた、受け継いだものでもよい）
   - ほかの主体（`Everyone`・`BUILTIN\Users`・`NT AUTHORITY\Authenticated Users` など）があれば、手順 6 で直す。無ければ手順 6 は飛ばす

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
     Write-Error '中断: 手順 2 の SSH_HOST・SSH_ALIAS・SSH_USER のどれかが空のまま。値を入れて貼り直す'
   } elseif ($SSH_ALIAS -notmatch '^[A-Za-z0-9_-]+$' -or $SSH_HOST -notmatch '^[A-Za-z0-9.:_-]+$' -or $SSH_USER -notmatch '^[A-Za-z0-9._-]+$') {
     Write-Error '中断: 手順 2 の値は、ASCII の英数字と . : _ - だけにする（空白・ワイルドカードは使わない）'
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
   - `user` などが手順 2 の値と違えば、config の前の方の `Host *` などが先に効いている。その行を直す
   - `Bad configuration option` が出たら、前からある config に、片方の ssh が知らない設定がある（[注意点](extra/windows-ssh-client.md#注意点)）
   - `Bad owner or permissions on …config` が出たら、config にほかの主体の書き込みの許可がある（[注意点](extra/windows-ssh-client.md#注意点)）
   - `中断: … BOM がある` ときは、メモ帳で config を開き、「名前を付けて保存」の文字コードを「UTF-8」（BOM なし）にして保存し直す

1. AlmaLinux 10 のホストで、ホスト鍵の指紋を表示する。

   ```bash
   ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
   ```

   - ホストの画面の端末か、すでにホストに入れている別の端末に貼る（`sudo` は要らない）
   - `256 SHA256:<指紋> no comment (ED25519)` の 1 行が出る。この指紋を、手順 9 の初回の接続で照合する
   - 同じ LAN から `ssh-keyscan` で取った指紋は、照合に使えない
   - **次の手順は、指紋を控えてから、手順 2 の変数を設定した PowerShell に貼る**

1. 公開鍵をホストの authorized_keys に足す（パスワードで 1 回ログインする）。

   ```powershell
   $pub = "$env:USERPROFILE\.ssh\id_ed25519.pub"
   if (-not $SSH_ALIAS) {
     Write-Error '中断: 手順 2 の SSH_ALIAS が空のまま。値を入れて貼り直す'
   } elseif (-not (Test-Path -LiteralPath $pub) -or [string](Get-Content -LiteralPath $pub -TotalCount 1) -notmatch '^ssh-ed25519 AAAA[0-9A-Za-z+/=]+( |$)') {
     Write-Error "中断: $pub が無いか、ed25519 の公開鍵の形でない"
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-Content -LiteralPath $pub -TotalCount 1 | & "$env:WINDIR\System32\OpenSSH\ssh.exe" -o PubkeyAuthentication=no $SSH_ALIAS 'umask 077; mkdir -p ~/.ssh && if [ -s ~/.ssh/authorized_keys ] && [ $(tail -c1 ~/.ssh/authorized_keys | wc -l) -eq 0 ]; then echo >> ~/.ssh/authorized_keys; fi && tr -d ''\r'' | sed ''1s/^\xEF\xBB\xBF//'' >> ~/.ssh/authorized_keys && echo added; if type restorecon >/dev/null 2>&1; then restorecon -F ~/.ssh ~/.ssh/authorized_keys; fi'
   }
   ```

   - 初回は `ED25519 key fingerprint is` の後ろに `SHA256:…` が出て、`Are you sure you want to continue connecting (yes/no/[fingerprint])?` と聞かれる
   - その指紋が手順 8 の指紋と同じなら `yes`、違えば `no` で止める
   - `<SSH_USER>@<SSH_HOST>'s password:` で、ホストのユーザーのパスワードを入れる
   - `added` と出ればよい
   - パスワードを聞かれずに `Permission denied` で終わるときは、ホストがパスワードでのログインを受け付けていない（[注意点](extra/windows-ssh-client.md#注意点)）
   - **次の手順は、パスワードを入力し終えて `added` が出てから貼る**（続けて貼るとパスワードとして食われる）

1. Windows の ssh と Git の ssh で、鍵でログインできることを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not $SSH_ALIAS) {
     Write-Error '中断: 手順 2 の SSH_ALIAS が空のまま。値を入れて貼り直す'
   } else {
     & "$env:WINDIR\System32\OpenSSH\ssh.exe" -o PreferredAuthentications=publickey $SSH_ALIAS 'whoami; ls -lZ ~/.ssh/authorized_keys'
     & 'C:\Program Files\Git\usr\bin\ssh.exe' -o PreferredAuthentications=publickey $SSH_ALIAS whoami
   }
   ```

   - パスワードを聞かれずに、`<SSH_USER>` と、`authorized_keys` の行、もう一度 `<SSH_USER>` が出ればよい
   - `authorized_keys` の行は、group と other に書き込みが無く（`-rw-------` など）、`ssh_home_t` が付いていればよい
   - 鍵にパスフレーズを付けたなら、2 回聞かれる
   - Git の ssh でホスト鍵を聞かれたら、Git の ssh が別の known_hosts を見ている（手順 3 の `HOME`）
   - `Permission denied (publickey…)` なら、鍵が登録されていないか、Windows の ssh が秘密鍵を使っていない。`UNPROTECTED PRIVATE KEY FILE!` が出ていれば、手順 6 で直す

1. WezTerm を自分用の設定で使うときだけ、起動メニューから接続先を開けることを確かめる。

   - 前提は、[Windows 11 の初期設定の「WezTerm」](#wezterm)と、自分用の設定（同書の[「Git Bash と WezTerm の設定」](#git-bash-と-wezterm-の設定)の手順 5）。入れていなければ、この手順は飛ばす
   - WezTerm で Ctrl+Shift+R（設定の読み直し）を押してから、Ctrl+Shift+M で起動メニューを開く
   - `ssh <SSH_ALIAS>` が並び、選ぶと新しいタブでホストのシェルに入ればよい（パスフレーズを付けたなら聞かれる）

---

### Windows の OpenSSH クライアント: 更新

- Windows の ssh は Windows Update、Git の ssh は[Git for Windows の更新](#git-for-windowsfirefoxwezterm-を上げる)の手順 2 で上がる。この項で別に上げるものは無い
- 上がった後と、`~/.ssh/config` を書き換えた後は、この項の手順 1 で、両方の ssh が config を読めることを確かめる
- [手順 2](#windows-の-openssh-クライアント-実施手順) の変数を設定した、管理者ではない Windows PowerShell（5.1）に貼る。新しい窓なら、手順 2 のブロックを貼り直してから貼る

1. 2 つの ssh の版と、両方が config を読めることを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not $SSH_ALIAS) {
     Write-Error '中断: 手順 2 の SSH_ALIAS が空のまま。値を入れて貼り直す'
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

## WireGuard（任意）

- この節だけを実施するときは、各項の前提・実行場所・権限を先に確認する
- [検証記録](verification/wireguard.md)・[参考資料](reference/wireguard.md)・[ロールバックと注意点](extra/wireguard.md)

### WireGuard: Windows 11 で使う

> [!IMPORTANT]
> - **Administrators のユーザーが Windows で行う**。[導入と鍵の用意](#wireguard-windows-11-で-wireguard-と鍵を用意する)の手順 1 で開く **管理者の Windows PowerShell 5.1** に貼る
> - 更新・ロールバックも同じ窓を使う。WireGuard は PC 全体に入り、トンネルは Windows のサービスとして動く
> - 前提: [Windows 11 の初期設定の「貼り付けの設定」の手順 1〜4](#貼り付けの設定)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ貼り付けの設定）。通していなければ、ブロックは Ctrl+V で貼る
> - **WG ホストで行う**のは、[登録と取り込み](#wireguard-windows-11-で-wg-ホストに登録して取り込む)の手順 2 と[トンネルの確認](#wireguard-windows-11-でトンネルを確かめる)の手順 4
> - ホスト側は[クライアントの登録](almalinux-setup.md#wireguard-クライアントを登録する)の手順 1・2・4〜6 と[トンネルの確認](almalinux-setup.md#wireguard-トンネルを確かめる)の手順 3 を参照する
> - [Windows 11 で WireGuard と鍵を用意する](#wireguard-windows-11-で-wireguard-と鍵を用意する)の手順 5 で **WireGuard の窓が開く**。開いてから次の手順を貼る
> - [Windows 11 でトンネルを確かめる](#wireguard-windows-11-でトンネルを確かめる)の手順 1 で、**PC を拠点の LAN の外のネットワークにつなぐ**（スマートフォンのテザリングなど）。その後の手順は LAN の外で行う

- 上から順に進める。[導入と鍵の用意](#wireguard-windows-11-で-wireguard-と鍵を用意する)の手順 2 の変数は、PowerShell を開き直したら貼り直す
- [登録と取り込み](#wireguard-windows-11-で-wg-ホストに登録して取り込む)の手順 3 だけは、関数名を手入力する
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- WG ホストの側は、AlmaLinux 10 の PC と同じ（`client add --pubkey` で公開鍵を登録して `apply` するだけで、ほかに変えるものは無い）

#### WireGuard: Windows 11 で WireGuard と鍵を用意する

1. Windows で、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く

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

   - 編集が必須なのは、1 行ずつの 4 ブロック（入れる値は、[鍵を作る](almalinux-setup.md#wireguard-鍵を作る)の手順 1 と同じ）
   - 最後に値を読み戻して確かめる
   - **既定値のままでもエラーにならない**ので、4 つの IP を書き換えたか必ずここで確かめる
   - 変数はその PowerShell の中だけで有効。**新しい PowerShell を開いたら**、この項の手順 2 の 5 つのブロックを貼り直してから先へ進む

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
   - 最後が `True` なら、前に作った鍵が残っている（この項の手順 6 で止まる）。使わないなら、[Windows 11 のロールバック](extra/wireguard.md#windows-11-のロールバック)の手順 1 で消す
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
   - インストーラーの画面は出ず、入れた後に WireGuard の窓も開かない（窓は、この項の手順 5 で開く）

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
   - 最後の 1 行（公開鍵、44 文字）だけを、[Windows 11 で WG ホストに登録して取り込む](#wireguard-windows-11-で-wg-ホストに登録して取り込む)の手順 2 で WG ホストに渡す。秘密鍵（`wg0.key`）は渡さない
   - **注意**: `%USERPROFILE%\wg-client` は、管理者の PowerShell からしか読めない（管理者ではない PowerShell やエクスプローラーでは開けない）

#### WireGuard: Windows 11 で WG ホストに登録して取り込む

1. Windows の PowerShell で、conf を取り込む関数を定義する。

   ```powershell
   function Import-WgClientConf {
     $dir = "$env:USERPROFILE\wg-client"
     $text = Get-Clipboard -Raw
     if (-not $text) { Write-Error '中断: クリップボードが空（この項の手順 2 の client show の出力をコピーし直す）'; return }
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
   - PowerShell を開き直した場合は、[Windows 11 で WireGuard と鍵を用意する](#wireguard-windows-11-で-wireguard-と鍵を用意する)の手順 2 と、この関数の定義を貼り直す

1. WG ホストで、[クライアントを登録する](almalinux-setup.md#wireguard-クライアントを登録する)の手順 1・2・4〜6 を行い、この PC の公開鍵を登録して conf を表示する。

   - ホスト側の手順 1 の `CLIENT_PUBKEY` に、[鍵の用意](#wireguard-windows-11-で-wireguard-と鍵を用意する)の手順 6 の公開鍵を貼る
   - `CLIENT_NAME` はこの PC だけの名前（例 `win-laptop`）にする。同名の端末は、ホスト側の手順 2 で登録を消してしまう
   - ホスト側の手順 6 の `client show` から、`[Interface]`〜`PersistentKeepalive` をこの PC のクリップボードにコピーする
   - `PrivateKey` はプレースホルダのままなので、**秘密情報を含まない**。どの経路で運んでもよい
   - **次の手順は、`client show` の出力をこの PC でコピーしてから行う**。コピー後は、コードブロックなど別の文字列をコピーしない

1. Windows の PowerShell で、`Import-WgClientConf` と手入力して Enter を押す。

   - 関数名はコピーせず手で打つ。クリップボードには、この項の手順 2 の conf を残しておく
   - `1`（置き換わった）と、`PrivateKey` 以外の行（`Address`・`PublicKey`・`Endpoint`・`AllowedIPs` など）が出ればよい
   - 残りの行が `client show` の出力のとおりで、途中で折り返されていないことを目で確かめる
   - `中断:` で始まるエラーが出たら、何も書いていない
   - conf をコピーし直し、この関数をもう一度呼んでもよい（`wg0.conf` を書き直す）

1. `wg0.conf` を WireGuard に取り込む。

   ```powershell
   & {
     $dir = "$env:USERPROFILE\wg-client"
     $store = "$env:ProgramFiles\WireGuard\Data\Configurations"
     if ((Get-Service -Name WireGuardManager -ErrorAction SilentlyContinue).Status -ne 'Running' -or -not (Test-Path -LiteralPath $store)) { Write-Error '中断: WireGuard のマネージャーが動いていない（「Windows 11 で WireGuard と鍵を用意する」の手順 5 からやり直す）'; return }
     if (-not (Test-Path -LiteralPath "$dir\wg0.conf")) { Write-Error '中断: wg0.conf が無い（この項の手順 3）'; return }
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
   - この項の手順 2・3 からやり直す
   - （この手順の代わりに）窓の「トンネルをファイルからインポート…」で `%USERPROFILE%\wg-client\wg0.conf` を選んでも、同じ `wg0.conf.dpapi` ができるはず

#### WireGuard: Windows 11 でトンネルを確かめる

1. PC を、拠点の LAN の外のネットワークにつなぐ（スマートフォンのテザリングなど）。

   - LAN 内でこの項の手順 2 を貼ると、そこで LAN の通信が切れる
   - **次の手順は、LAN の外につないでから貼る**

1. 拠点の LAN の外で、トンネルを張る。

   ```powershell
   & {
     $conf = "$env:ProgramFiles\WireGuard\Data\Configurations\wg0.conf.dpapi"
     if (-not (Test-Path -LiteralPath $conf)) { Write-Error '中断: wg0.conf.dpapi が無い（「Windows 11 で WG ホストに登録して取り込む」の手順 4）'; return }
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
   - `wg show` の `latest handshake` が数秒前で、`transfer` の received が 0 でない。まだ出ていなければ、この項の手順 3 の通信で出る
   - 窓で `wg0` を選び「有効化」を押しても同じ
   - **注意**: LAN 内で貼ってしまったら、そこで LAN の通信が切れる。PC の画面の WireGuard の窓で「無効化」を押す

1. PC で、トンネル IP → WG ホストの LAN 側 → ルーター → 相手拠点の順に疎通を試す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not ($WG_HOST_TUN_IP -and $WG_HOST_LAN_IP -and $ROUTER_LAN_IP -and $PEER_WG_LAN_IP)) {
     Write-Error '「Windows 11 で WireGuard と鍵を用意する」の手順 2 の変数が空のまま'
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
   - どこで止まるかで、疑う場所が変わる（[トンネルを確かめる](almalinux-setup.md#wireguard-トンネルを確かめる)の手順 2 と同じ）

1. WG ホストで、[トンネルを確かめる](almalinux-setup.md#wireguard-トンネルを確かめる)の手順 3 を（[クライアントを登録する](almalinux-setup.md#wireguard-クライアントを登録する)の手順 1 のシェルで）貼り、ハンドシェイクを確かめる。

   - `client list` の、この PC の名前の `LAST_HANDSHAKE` が「N 秒前」なら届いている
   - 最後の `ping`（拠点 → PC）は、応答が無くてよい
   - 片方向だけ失敗する、`latest handshake` が出ない、といった場合は [症状と原因の対応](verification/wireguard.md#症状と原因の対応実測)
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
   - 日常は、外出先で窓（か、通知領域の WireGuard のアイコン）から `wg0` を有効化し、拠点に戻る前に無効化する（この項の手順 2・5 のコマンドでも同じ）
   - **張ったまま再起動すると、起動したときにまた張られる**。拠点の LAN に戻る前に切る

1. 平文の鍵と conf を消す。

   ```powershell
   Remove-Item -LiteralPath "$env:USERPROFILE\wg-client\wg0.key", "$env:USERPROFILE\wg-client\wg0.conf"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ChildItem -LiteralPath "$env:USERPROFILE\wg-client" | Format-Table Name, Length
   ```

   - `wg0.pub` だけが残る
   - 取り込みをやり直すときは、後片付けの前に[登録と取り込み](#wireguard-windows-11-で-wg-ホストに登録して取り込む)の手順 4 を行う（`wg0.conf` が必要）

---

### WireGuard: Windows 11 の更新

- WireGuard のマネージャーは、1 時間ごとに新しい版を確かめる（起動した直後は数分待ってから）。新しい版があると、窓に「更新が利用できます！」のタブが出て、そこの「今すぐ更新」で上がる（Administrators の一員だけ）
- 窓からの更新は、公式の署名付きの一覧（`latest.sig`）で MSI を確かめてから入れる。winget で上げても、入るのは同じ公式の MSI
- 更新の間、マネージャーと、張っているトンネルのサービスは止まり、入れ終えると起動し直す（張っていれば数秒切れる）
- この項の手順 1 は、管理者の Windows PowerShell（5.1）に貼る

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



---

## 設定リポジトリと追加の道具（任意）

- 導入対象の本体は、この文書の基本設定または該当ツールの項で先に入れる
- 各項に指定したシェル・権限で実施する。設定の退避と既存の変更の確認を省かない
- 指定の無い PowerShell ブロックは、管理者ではない Windows PowerShell 5.1 に貼る

### 共通の bash 設定を更新する

自分のユーザーの bash（Windows 11 は Git Bash）で行う。更新後は端末を開き直す。

1. origin を HTTPS にそろえて、設定のリポジトリを pull する。

   ```bash
   git -C ~/.config/bash remote set-url origin https://github.com/ryo-aoki-pc/bash.git
   git -C ~/.config/bash pull --ff-only
   git -C ~/.config/bash log -1 --oneline
   ```

   - 新しいコミットが無ければ `Already up to date.` と出て、最後にいちばん新しいコミットが 1 行出る
   - `set-url` は、HTTPS で clone したホストでは何も変えない。SSH で clone したホストを HTTPS にそろえる
   - インターネットに出られないホストは、[SSH の SOCKS トンネル](almalinux-setup.md#ssh-の-socks-トンネル-実施手順)を張ったシェルで貼る
   - 手元で変えたファイルがあって pull が止まったら、`git -C ~/.config/bash status` で見る
   - 開いている端末には効かない。端末を開き直す

---

### WezTerm の設定を導入する


WezTerm nightly・Git・[共通の bash 設定](#git-bash-と-wezterm-の設定)を先に入れ、自分のユーザーの bash（Windows 11 は Git Bash）で行う。シェル統合は共通 bash 設定が読む。HackGen Console NF は任意。

この項の手順 1〜4 は WezTerm の外の Git Bash の窓で行い、手順 2 の退避前に WezTerm のウィンドウをすべて閉じる。

[背景説明](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/reference/install.md)・[検証記録](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/verification/install.md)

1. 既存の WezTerm の設定があるか確かめる。

   ```bash
   ls -ld ~/.wezterm.lua ~/.config/wezterm
   ```

   - どちらかが出たら、手順 2 で退避する
   - 2 行とも `No such file or directory` なら、設定は無い。手順 2 は飛ばす
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
   - `.bak` が 1 つでもあれば、どちらも動かさず `中断:` で止まる。この項の手順 3 へ進まず、中身を確かめて片付けてから手順 2 を貼り直す
   - 退避したものは、[WezTerm 設定のロールバック](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/extra/install.md#ロールバック)の手順 4 で戻せる

1. この設定を `~/.config/wezterm` に clone する。

   ```bash
   git clone https://github.com/ryo-aoki-pc/wezterm.git ~/.config/wezterm
   git -C ~/.config/wezterm log -1 --oneline
   ```

   - `Cloning into '/home/<USER>/.config/wezterm'...` の後に、最新のコミットが 1 行出る
   - `fatal: destination path '/home/<USER>/.config/wezterm' already exists and is not an empty directory.` と出たら、手順 1 から見直す

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
   - **次の手順は、起動し直した WezTerm のタブで貼る**（開いていたタブで貼ると、手順 6 の確かめが外れる）

1. 起動し直した WezTerm のタブで、シェル統合が読まれたか確かめる。

   ```bash
   echo "$TERM_PROGRAM"
   echo "$WEZTERM_SHELL_INTEGRATION"
   declare -F __wezterm_set_user_var __wezterm_notify_done __wz_mouse_off
   ```

   - 1 行目は `WezTerm`、2 行目は `.config/wezterm/shell/wezterm.sh` で終わるパス
   - 3 つ目は、WezTerm のパッケージの公式のシェル統合があるかどうかで変わる
     - AlmaLinux 10（COPR の公式統合）: `__wezterm_set_user_var`・`__wezterm_notify_done`・`__wz_mouse_off` の 3 行
     - 公式の統合が無いとき（Windows の Git Bash など）: `__wezterm_notify_done` と `__wz_mouse_off` の 2 行
   - 1 行目が空なら、WezTerm の外で貼っている。2 行目が空なら、手順 5 の前から開いていたタブで貼っている
   - `__wz_mouse_off` が出なければ、`~/.bashrc` の行が読まれていない。共通の bash 設定を見直す

---

### WezTerm のシェル統合を WSL で使う（任意）

Windows 側の[WezTerm 設定](#wezterm-の設定を導入する)と、WSL 側の共通 bash 設定を先に入れる。以下は WSL の bash で行い、Windows 側の統合を共通 bash の読み込み行より後ろで読む。

1. WSL のシェルで、Windows のホームを調べ、シェル統合のスクリプトが見えるか確かめる。

   ```bash
   WIN_HOME=$(wslpath "$(cd /mnt/c && cmd.exe /c 'echo %USERPROFILE%' | tr -d '\r')")
   ls -l "$WIN_HOME/.config/wezterm/shell/wezterm.sh"
   ```

   - `/mnt/c/Users/<WIN_USER>/.config/wezterm/shell/wezterm.sh` の 1 行が出ればよい
   - `No such file or directory` なら、Windows 側の[WezTerm 設定の導入](#wezterm-の設定を導入する)を先に済ませる

1. この項の手順 1 と同じシェルで、WSL の `~/.bashrc` に読み込む行を足す。

   ```bash
   echo "[ -r '$WIN_HOME/.config/wezterm/shell/wezterm.sh' ] && . '$WIN_HOME/.config/wezterm/shell/wezterm.sh'" >> ~/.bashrc
   tail -1 ~/.bashrc
   ```

   - `/mnt/c/Users/<WIN_USER>/.config/wezterm/shell/wezterm.sh` を 2 回含む 1 行が出る
   - WSL の `$HOME` は Linux 側なので、Windows 側の統合をこのパスで読む

1. WezTerm の起動メニューから、WSL のタブを開き直す。

   - `Ctrl+Shift+M` の起動メニューで、WSL のディストリビューションを選ぶ
   - **次の手順は、開き直した WSL のタブで貼る**

1. 開き直した WSL のタブで、シェル統合が読まれたか確かめる。

   ```bash
   echo "$TERM_PROGRAM"
   declare -F __wezterm_set_user_var __wezterm_notify_done __wz_mouse_off
   ```

   - `TERM_PROGRAM` が `WezTerm`、`__wezterm_notify_done` と `__wz_mouse_off` が出ればよい。WSL に COPR の公式統合があれば `__wezterm_set_user_var` も出る

---

### WezTerm の設定を更新する

自分のユーザーの bash（Windows 11 は Git Bash）で行う。WezTerm 本体の更新は同じ冊の更新節で行う。

1. 設定のリポジトリを pull する。

   ```bash
   git -C ~/.config/wezterm pull
   git -C ~/.config/wezterm log -1 --oneline
   ```

   - 新しいコミットが無ければ、`Already up to date.` と出る
   - 起動中の WezTerm は、ファイルが変わると設定を読み直す（効かなければ `Ctrl+Shift+R`）
   - シェル統合（`shell/`）とウィンドウの装飾の変更は、WezTerm を起動し直すまで効かない
   - 手元で変えたファイルがあって pull が止まったら、`git -C ~/.config/wezterm status` で見る

---

### LazyVim の設定を導入する

[Git for Windows](#git-for-windows)・[アプリを入れる](#アプリを入れる)の scoop・[HackGen Console NF](#hackgen-console-nf)・[Neovim](#neovim)を先に済ませる。管理者ではない PowerShell で行い、VC++ ランタイムの導入時だけ UAC を許可する。

この項の手順 2 の退避前に、Neovim を閉じる。

[背景説明](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/reference/setup.md)・[検証記録](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/verification/setup.md)

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
     $nvimPaths | ForEach-Object { '{0}: {1}' -f $_, (Test-Path -LiteralPath $_) }
   }
   ```

   - 退避したものは `moved: …` と出る。最後の 2 行がどちらも `False` なら、元の設定とデータは残っていない
   - `.bak` が 1 つでもあれば、どちらも動かさず `中断:` で止まる。中身を確かめて片付けてから、この項の手順 2 を貼り直す
   - `nvim` は設定、`nvim-data` はプラグイン・Mason のツール・undo など

1. この設定を `%LOCALAPPDATA%\nvim` に clone する。

   ```powershell
   if (-not (Test-Path "$env:LOCALAPPDATA\nvim\init.lua")) { git clone https://github.com/ryo-aoki-pc/LazyVimStarter.git "$env:LOCALAPPDATA\nvim" }
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

---

### LazyVim の設定とプラグインの版を揃える

設定と `lazy-lock.json` を取り込み、プラグインをその版に揃える。初回と整形用 lock の変更後は[安全な整形](#lazyvim-の安全な-markdown-整形を導入する)を入れ直す。外したプラグインは `:Lazy clean`、外した Mason ツールは `:MasonUninstall <名前>` で消す。

1. Windows 11 では、設定を最新にしてプラグインを揃える。

   ```powershell
   git -C "$env:LOCALAPPDATA\nvim" pull --ff-only; if ($?) { nvim --headless "+Lazy! restore" +qa }
   git -C "$env:LOCALAPPDATA\nvim" status --short
   ```

   - `git status --short` が何も出さなければ、`lazy-lock.json` の版に揃っている
   - `M lazy-lock.json` なら、導入時に lock が古い版で書き直されている。`git -C "$env:LOCALAPPDATA\nvim" checkout -- lazy-lock.json` で戻す
   - 続いて `nvim --headless "+Lazy! restore" +qa` をもう一度貼る。2 回目は導入も lock の書き直しも無い
   - `Not possible to fast-forward` なら、`restore` も状態表示も走らない。push していないコミットを先に push するか、`git -C "$env:LOCALAPPDATA\nvim" log --oneline '@{u}..'` で見る
   - `Your local changes to the following files would be overwritten by merge:` が `lazy-lock.json` を挙げたら、手元で lock が変わっている
   - `:Lazy update` の結果として残すのでなければ、`git -C "$env:LOCALAPPDATA\nvim" checkout -- lazy-lock.json` で戻してから、この手順を貼り直す

---

### LazyVim の安全な Markdown 整形を導入する

- AlmaLinux 10 / Windows 11 共通。Node.js 22 以上と npm が必要
- 初回と `tools/glfm-format/package-lock.json` の変更後に行う
- 整形用依存は Neovim のデータディレクトリの `glfm-format` に入る。Mason のツールとは別に管理する

1. Neovim で整形用の依存を導入する。

   ```vim
   :GlfmFormatInstall
   ```

   - 完了の通知が出るまで待つ
   - 取得するのは lock ファイルで固定した markdownlint-cli2 と Comrak (WASM 版)。整形時は通信しない
   - 失敗したら Node.js と npm が PATH にあるか確かめ、同じコマンドを入力し直す
   - lint の診断用は `:MasonInstall markdownlint-cli2` で導入する

1. Markdown ファイルで保存と手動整形を確かめる。

   ```markdown
   #動作確認

   用語
   : 説明

     - 内部の項目
   ```

   - `:w` または `<leader>cf` で `#動作確認` が `# 動作確認` に直る
   - `内部の項目` の行頭の 2 スペースが保たれる
   - `<leader>cf` はビジュアル選択した範囲にも使える
   - 説明の対応や本文を変える修正は除外するため、一部の lint 診断は残ることがある
   - `:ConformInfo` に `glfm_markdownlint` が出る。依存不足・設定不正・時間切れのときは原文を保持し、エラーを知らせる

---

### LazyVim の GitLab プレビューを設定する（任意）

GitLab でスコープ `read_api` の個人アクセストークンを用意する。編集中の内容とトークンは設定した GitLab（空なら gitlab.com）に送る。設定しなくても近似プレビューは使える。削除は [LazyVim のロールバック](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/extra/setup.md#gitlab-プレビューの設定を消す)で行う。

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

1. Windows 11 では、新しい端末でこの設定の README を開き、プレビューで確かめる。

   ```powershell
   nvim "$env:LOCALAPPDATA\nvim\README.md"
   ```

   - `<leader>cp` の右上に `GitLab: <ホスト名>` が出ればよい。近似表示ならバナーの理由を確認する。もう一度 `<leader>cp` で止め、`:qa` で閉じる
   - Neovide で使うなら、Neovide も起動し直す

---

### LazyVim の本体・外部コマンド・プラグインを更新する

設定の取り込みは[設定とプラグインの版を揃える](#lazyvim-の設定とプラグインの版を揃える)で行う。プラグイン更新後は動作を確認し、`lazy-lock.json` の差分をコミット・push する。

1. Windows 11 では、scoop で入れたものを上げる。

   ```powershell
   scoop update
   scoop update neovim ripgrep fd gcc nodejs zenhan lazygit
   nvim --version | Select-Object -First 1
   ```

   - 最新なら `latest version` と出る

1. Windows 11 では、プラグインを上げて差分を見る。

   ```powershell
   nvim --headless "+Lazy! update" +qa
   git -C "$env:LOCALAPPDATA\nvim" diff --stat
   ```

   - `lazy-lock.json` だけが変わっていればよい

---

### lazygit の設定を導入する

lazygit を終了してから、管理者ではない PowerShell で行う。lazygit・delta・VC++ ランタイム・HackGen Console NF は同冊の導入節で入れておく。

1. 既存設定を退避して、設定ディレクトリへ clone する。

   ```powershell
   $d = "$env:LOCALAPPDATA\lazygit"
   if (Test-Path -LiteralPath "$d.bak") {
     Write-Warning "$d.bak がすでにあるため中止しました。中身を確かめて片付けてから、貼り直してください"
   } else {
     if (Test-Path -LiteralPath $d) { Move-Item -LiteralPath $d -Destination "$d.bak" -ErrorAction Stop; "moved: $d -> $d.bak" }
     git clone https://github.com/ryo-aoki-pc/lazygit.git $d
     git -C $d branch --show-current
     lazygit --print-config-dir
   }
   ```

   - `.bak` が既にあるときは退避・clone をせず中断する
   - `custom` と `%LOCALAPPDATA%\lazygit` が出ればよい
   - 状態ファイルも同じ場所に置くが Git の追跡対象からは除外する
   - 戻すときは [lazygit のロールバック](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/extra/readme.md)を行う

---

### lazygit の Excel 差分表示を導入する（任意）

Python 3.9 以上・Git が必要。部分ステージには lazygit 0.66.0 以上・delta 0.20.1 以上が必要。Python が無ければ、先に `scoop install python` を行う。

1. 設定リポジトリへ移り、Excel の差分表示を導入して確かめる。

   ```powershell
   & {
     Push-Location -LiteralPath "$env:LOCALAPPDATA\lazygit" -ErrorAction Stop
     try {
       python --version
       python scripts/setup-excel-diff.py
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

---

### lazygit で Excel の差分を確かめる

対象の Excel がある Git リポジトリへ移ってから行う。例のファイル名は実際の名前に置き換える。属性の仕様は [Excel 差分の説明](https://github.com/ryo-aoki-pc/lazygit/blob/custom/README.md#excel-の差分表示)を参照する。

> [!CAUTION]
> - **通常の Excel 差分は閲覧用。`Enter` から行・ハンクをステージ・破棄しない**。既存の Excel にテキストのパッチは適用できず、新規ファイルでは Excel の代わりに変換後のテキストをステージする場合がある
> - `diff.excel.binary=true` はバイナリ扱いを保つだけで、これらの操作を禁止しない
> - 全体をステージするならファイル一覧で `Space`、部分ステージは[専用画面](#lazygit-で-excel-のセル変更を部分ステージする)の `E` を使う

1. Excel の属性と、作業中・ステージ済みの差分を確かめる。

   ```powershell
   git check-attr diff -- "売上表.xlsx"
   git diff -- "売上表.xlsx"
   git diff --cached -- "売上表.xlsx"
   ```

   - `売上表.xlsx: diff: excel` と、差分に `Sheet:`・セル番地が出ればよい
   - lazygit を開き直してファイルを選ぶと、同じ差分を delta で表示する。`|` で内蔵表示にしても同じテキスト差分になる
   - `unset` や別のドライバーなら、そのリポジトリの `.gitattributes`・`.git/info/attributes` の Excel 用の属性を確かめる
   - そのリポジトリだけに適用するなら、`.git/info/attributes` に `*.[xX][lL][sS][xX] diff=excel` を足す

---

### lazygit で Excel のセル変更を部分ステージする


lazygit・delta・Excel 差分表示を導入し、対象の Excel がある Git リポジトリへ移ってから行う。対象は HEAD と index の両方にある既存 `.xlsx` / `.xlsm` / `.xltx` / `.xltm`。新規ファイルは全体をコミットしてから使う。

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

### lazygit で大きな Excel の変換を待つ（任意）

対象の Excel がある Git リポジトリへ移ってから行う。変換中のブックは、完了後にファイルを選び直すか `R` で表示する。例のファイル名は実際の名前に置き換える。

1. 全セルの変換を待って差分を表示する。

   ```powershell
   $env:EXCEL_TEXTCONV_TIMEOUT = "0"; git diff -- "売上表.xlsx"
   ```

   - 環境変数は同じ窓に残る。戻すときは `Remove-Item Env:EXCEL_TEXTCONV_TIMEOUT` を実行する

---

### yazi の設定を導入する

yazi と依存ツールを先に入れる。Windows の `YAZI_FILE_ONE` と VC++ ランタイムは[yazi](#yazi)で設定する。

1. yazi を終了し、自分用の設定を clone する。

   ```powershell
   $dst = "$env:APPDATA\yazi\config"
   if ((Test-Path -LiteralPath $dst) -and (Test-Path -LiteralPath "$dst.bak")) {
     Write-Error "中断: $dst.bak が既にある。中身を確かめて片付けてから貼り直す"
   } else {
     if (Test-Path -LiteralPath $dst) { Move-Item -LiteralPath $dst -Destination "$dst.bak" -ErrorAction Stop }
     git clone -b custom https://github.com/ryo-aoki-pc/yazi.git $dst
     git -C $dst branch --show-current
   }
   ```

   - `custom` ブランチを使う。導入先は `%APPDATA%\yazi\config`
   - 既存設定と `.bak` が両方ある場合は何も変更せず中断する
   - `ya env` の Config で読み込む場所を確かめる

---

### yazi で複数ファイルをまとめて開く（任意）

`l` / `<Enter>` は既定でホバー中の 1 ファイルだけを開く。選択した複数ファイルをまとめて開くときだけ行う。

1. `%APPDATA%\yazi\config\init.lua` に、次の行を足す。

   ```lua
   require("smart-enter"):setup { open_multi = true }
   ```

   - yazi を開き直し、選択したファイルが `l` / `<Enter>` でまとめて開くことを確かめる

---

### mdtable を導入・更新する（任意）

Python 3.9 以上が必要。Python が無ければ、先に `scoop install python` を行う。

1. リポジトリを clone し、導入して確かめる。

   ```powershell
   git clone https://github.com/ryo-aoki-pc/md-table-excel.git "$env:USERPROFILE\md-table-excel"
   & {
     Push-Location -LiteralPath "$env:USERPROFILE\md-table-excel" -ErrorAction Stop
     try {
       python scripts/setup-mdtable.py
       python scripts/setup-mdtable.py --check
     } finally {
       Pop-Location
     }
   }
   ```

   - 依存はリポジトリ外の専用仮想環境へ入る
   - 起動コマンドは `%USERPROFILE%\.local\bin`。PATH に無いときは案内に従って加える
   - `--check` は何も変更せず状態を確かめる
   - 更新時は `git -C "$env:USERPROFILE\md-table-excel" pull --ff-only` を実行し、この項の手順 1 の `& { ... }` 部分（導入・確認）を貼り直す。`git clone` は再実行しない
   - 終わると元の作業ディレクトリへ戻る

---

### mdtable のブックを Excel で編集するときの注意

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

---

### mdtable で Markdown の表を Excel と往復する

編集する自分の Markdown があるディレクトリへ移ってから行う。例の `README.md` と `README.tables.xlsx` は、対象の文書名と対応するブック名に置き換える。Excel が必要。

> [!CAUTION]
> この項の手順 1・2 で Excel を編集する前に、[mdtable のブックを Excel で編集するときの注意](#mdtable-のブックを-excel-で編集するときの注意)を必ず読む。日付化・小数の桁落ちなどで、元の文字列を失うことがある。

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

1. ブックをファイルとして残すときは、書き出して取り込む。

   ```powershell
   mdtable export README.md
   mdtable import README.tables.xlsx --dry-run
   mdtable import README.tables.xlsx
   ```

   - `export` は Markdown と同じフォルダーに `README.tables.xlsx` を書く（`-o` で変更）。既存のブックは `--force` 無しでは上書きしない
   - `import` はブックに記録した Markdown に書き戻す（`--md` で変更）。`--dry-run` は差分だけを出す
   - 書き出した後に Markdown の表を変えていたら、衝突として書き戻さない。`--force` を付けるとブックの内容で上書きする
   - 同じブックを再度取り込むと「適用済み」になる。取り込み後はブックを消してよい

---

### 共通の bash 設定を手動で移行する（任意）

通常の導入が中断した場合は、[AlmaLinux 側の共通 bash 手動移行](almalinux-setup.md#共通の-bash-設定を手動で移行する任意)の全節を自分のユーザーの Git Bash で行う。WSL は WSL 側で別に行う。
