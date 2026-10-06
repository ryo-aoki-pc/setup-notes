# Windows 11 を AlmaLinux 10 とのデュアルブート向けに入れる手順（ESP を 2 GiB にし、AlmaLinux 用の空きを残す）

## 実施手順

- [検証記録](verification/windows-dual-boot.md)・[参考資料](reference/windows-dual-boot.md)

> [!IMPORTANT]
> - **入れる先のディスクの中身は、手順 5 ですべて消える**。そのディスクに Windows 11 を新しく入れ、後ろに AlmaLinux 10 用の未割り当て領域を残す
> - **インストールメディアは、Rufus で作成済みとする**。「インストーラーをカスタムしますか?」でオンにした項目は次の 7 つ（[選択した方針](reference/windows-dual-boot.md#選択した方針)）
>   - 「4GB以上のRAM、セキュアブート及びTPM 2.0の要件を削除」「オンラインアカウントの要件を削除」「ローカルアカウントを次の名前で作成:」「地域設定をこのユーザーと同じものに設定」「データ収集を無効化」「BitLocker 自動デバイス暗号化を無効化します。」「利便性向上パッチ(Microsoftの各種ソフトウェアの無効化)」
>   - **「⚠サイレント⚠ ディスクの削除とインストール:」はオフにしてある**こと（オンだと、最初に見つかったディスクを確かめずに消して入れる）
>   - ビルド 26200 以降の ISO で出る「Windows CA 2023署名のブートローダーを使用する」「インストール時にSkuSiPolicy.p7bを適応する」もオフのまま（既定でオフ）
> - 手順 1〜3・6〜8 は、PC の画面と機器で行う。**手順 4・5 は、セットアップのコマンド プロンプトに手で 1 行ずつ打つ**（貼り付けられない）
> - 手順 9〜13 は、入れた Windows の管理者の Windows PowerShell（5.1）に貼る。入れたばかりの Windows は貼り付けの設定（[Windows 11 の初期設定の手順 16〜19](windows-setup.md#実施手順)）を通していないので、ブロックは Ctrl+V で貼る（右クリックで貼ると、行が逆順になる）

- 上から順に進める。手順 10・12・13 は、条件に当たるときだけ行う
- やり直すときは、手順 3 から始める（ロールバックの節は無い）。手順 5 のパーティションが残っていれば、手順 4・5 は飛ばしてよい

- 手順の後: AlmaLinux 10 は、手順 5 で残した未割り当て領域に入れる（この文書には含めない。入れるときの注意は[注意点](#注意点)）。Windows の初期設定（更新・貼り付けの設定・表示・電源など）は、[Windows 11 の初期設定](windows-setup.md)で行う
- 両方の OS を入れた後、Windows から次回だけ AlmaLinux を起動したいときは、[QEFI Entry Manager を使う節](#次回だけ-almalinux-で起動する任意)へ進む

> [!CAUTION]
> **手順 5 の `clean` で、選んだディスクのパーティションとデータをすべて消す（取り戻せない）。** ディスクの番号は、手順 4 で大きさを見て確かめる。

1. PC の UEFI（BIOS）の設定画面で、起動の設定を確かめる。

   - 起動のモードは UEFI にする（CSM・Legacy の起動は切る）
   - Secure Boot と TPM は有効のままにする
   - Secure Boot の項目に「Microsoft 3rd Party UEFI CA」を許可する設定があれば、許可にする（Rufus の USB の起動と、後で入れる AlmaLinux の起動に要る）
   - USB からの起動を許可する
   - 設定画面の開き方（電源を入れた直後に押すキー）と項目の名前は、PC のメーカーごとに違う

1. LAN ケーブルを抜き、Wi-Fi にもつながない状態にする。

   - Rufus の「オンラインアカウントの要件を削除」は、インストールの間はネットワークから外しておくことを条件にしている（Rufus の画面の説明）
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
   - Enter の前に、打った文字が画面に正しく出ているかを見る（日本語の配列でないキーボードでは、`\` や手順 5 の `=`・`"` が別の記号になる）
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
   - 1 つ目の `exit` で diskpart を、2 つ目の `exit` でコマンド プロンプトを閉じる
   - 途中で打ち間違えたら、`select disk 0`（控えた番号）から打ち直す

1. セットアップに戻り、手順 5 の「Windows」のパーティションを選んでインストールする。

   - 「言語設定を選択」→「キーボード設定を選択」→「セットアップ オプションの選択」→「プロダクト キーを入力してください」→「イメージの選択」→「適用される通知とライセンス条項」の順に進む
   - 「キーボード設定を選択」の「キーボードの種類」は、日本語のキーボードなら「日本語キーボード (106/109 キー)」にする（既定が「PC/AT 拡張キーボード (101/102 キー)」のことがある）
   - 「セットアップ オプションの選択」では「Windows 11 のインストール」を選び、「ファイル、アプリ、設定など、すべてが削除されることに同意します」に印を付ける
   - プロダクト キーが無ければ「プロダクト キーがありません」を押し、「イメージの選択」でエディション（Windows 11 Pro など）を選ぶ
   - **「Windows 11 をインストールする場所の選択」では、手順 5 で作った Windows の大きさのパーティション（`ディスク 0 パーティション 3: Windows` のように、手順 4 で控えたディスクのパーティション 3）を選び、「次へ」を押す**
   - この画面では「パーティションの削除」を押さず、「未割り当て領域」も選ばない（選ぶと、セットアップがそこに自分の並びを作る）
   - 「インストール準備完了」の画面で「インストール」を押す。途中で何度か再起動する
   - 最初の再起動のときに USB を抜く（挿したままだと、PC によっては USB から起動し直し、セットアップが最初から始まる）
   - **注意**: 「適用される通知とライセンス条項」の画面には「戻る」が無い。Esc を押すと「本当に終了しますか?」が出て、「はい」で PC が再起動する（手順 3 からやり直す）

1. 初回の起動を待ち、Rufus で作ったローカル アカウントでデスクトップまで進む。

   - 「ネットワークに接続しましょう」の画面が出たら、「インターネットに接続していません」を押す
   - 地域・キーボード・ライセンス・プライバシー・アカウントの質問は出ない（Rufus の設定）。ロック画面が出たら、キーを押すとそのままサインインする
   - デスクトップが出たら、LAN ケーブルや Wi-Fi につないでよい
   - ローカル アカウントのパスワードは空。**次にサインインするときに「サインインする前にユーザーのパスワードを変更する必要があります。」が出る**ので、「OK」を押して新しいパスワードを決める（「パスワード」の欄は空のまま）

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、右側の「管理者として実行する」を押す（Ctrl+Shift+Enter でも同じ）
   - 「ユーザー アカウント制御」で「はい」を押す。窓の名前が「管理者: Windows PowerShell」になる
   - Rufus で作ったローカル アカウントは Administrators の一員なので、昇格できる

1. パーティションの並び・ESP の大きさ・未割り当て領域・WinRE の場所を確かめる。

   ```powershell
   $d = (Get-Partition -DriveLetter C).DiskNumber
   Get-Partition -DiskNumber $d | Format-Table PartitionNumber, DriveLetter, Size, Type -AutoSize
   Get-Disk -Number $d | Format-List Number, PartitionStyle, Size, LargestFreeExtent
   reagentc /info
   ```

   - パーティションが `System`（`2147483648`）・`Reserved`（`16777216`）・`Basic`（C:）・`Recovery`（`1073741824`）の順に 4 つ並べばよい（`Size` はバイト）
   - `PartitionStyle` が `GPT` で、`LargestFreeExtent` が AlmaLinux 用に残した大きさ（バイト）になっていればよい
   - `reagentc /info` の Windows RE の状態が `Enabled` で、場所が `…\partition4\Recovery\WindowsRE`（回復パーティション）なら、手順 10 は飛ばす
   - 場所が `partition3`（C:）か空なら、手順 10 で回復パーティションへ移す

1. WinRE が回復パーティションに無いときだけ、回復パーティションへ移す。

   ```powershell
   reagentc /disable
   reagentc /enable
   reagentc /info
   ```

   - 最後の `reagentc /info` で、場所が `…\partition4\Recovery\WindowsRE` になればよい

1. 高速スタートアップ・BitLocker・タイムゾーンの状態を確かめる。

   ```powershell
   Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' | Format-List HiberbootEnabled
   Get-BitLockerVolume -MountPoint C: | Format-List VolumeStatus, ProtectionStatus
   Get-TimeZone | Format-List Id
   ```

   - `HiberbootEnabled : 0` なら高速スタートアップは切れている（Rufus の「利便性向上パッチ」）。`1` なら、手順 12 で切る。`0` なら手順 12 は飛ばす
   - `VolumeStatus : FullyDecrypted` と `ProtectionStatus : Off` なら、BitLocker は使われていない（Rufus の BitLocker の項目）。暗号化されていたら[注意点](#注意点)
   - `Id : Tokyo Standard Time` なら、手順 13 は飛ばす。違えば、手順 13 で直す
   - Home エディションで `Get-BitLockerVolume` が無いと出たら、代わりに `manage-bde -status C:` で見る

1. 高速スタートアップが有効なときだけ、切る。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name HiberbootEnabled -Value 0 -Type DWord
   Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' | Format-List HiberbootEnabled
   ```

   - `HiberbootEnabled : 0` が出ればよい
   - Rufus と同じ値を書くだけで、休止状態そのものは残る

1. タイムゾーンが東京でないときだけ、直す。

   ```powershell
   Set-TimeZone -Id 'Tokyo Standard Time'
   Get-TimeZone | Format-List Id
   ```

   - `Id : Tokyo Standard Time` が出ればよい
   - 設定アプリの「時刻と言語」→「日付と時刻」でも同じ

---

## 次回だけ AlmaLinux で起動する（任意）

> [!IMPORTANT]
> - Windows 11 から操作する。AlmaLinux を導入済みで、PC の起動メニューから AlmaLinux のエントリを選んで起動できることが前提
> - QEFI Entry Manager と PowerShell は管理者として起動する。PowerShell のブロックは Ctrl+V で貼る
> - この節では、次回だけの起動先（`BootNext`）を指定する。通常の起動順（`BootOrder`）や GRUB の既定の選択は変更しない

- 初回はこの節の手順 1 から行う。展開済みなら、この節の手順 5 から行う（管理者の Windows PowerShell を開いておく）
- 同梱 CLI に表示の不具合があるため、Windows 標準の BCDEdit も使って確認する（この節の[検証記録](verification/windows-dual-boot.md)・[参考資料](reference/windows-dual-boot.md)）
- 再起動前に取り消すときは、[次回起動の指定を取り消す](#次回起動の指定を取り消す任意)へ進む。QEFI Entry Manager を閉じるだけでは取り消せない

1. Windows のブラウザで、公式の Windows 向け ZIP をダウンロードする。

   - [公式リリース v0.5.0](https://github.com/Inokinoki/QEFIEntryManager/releases/tag/v0.5.0) の Assets から `QEFI.Entry.Manager.for.Windows.Qt6.8.3.zip` を選ぶ
   - 「ダウンロード」フォルダーに、この名前で保存する（末尾に `(1)` などが付いたら、既存のファイルと区別してからこの名前にする）
   - この節はこの配布物を対象にする。別の版は、この節の手順 3 のハッシュと一致しない

1. 管理者の Windows PowerShell（5.1）を開く。

   - [手順 8](#実施手順)と同じように、スタートメニューから「管理者として実行する」で開く
   - この窓は、GUI で指定した後の確認にも使うので残しておく
   - **次の手順は、管理者の窓が開いてから貼る**

1. ダウンロードした ZIP の SHA256 を確かめる。

   ```powershell
   if ((Get-FileHash -LiteralPath "$env:USERPROFILE\Downloads\QEFI.Entry.Manager.for.Windows.Qt6.8.3.zip" -Algorithm SHA256 -ErrorAction Stop).Hash -ne 'FC2D83F1369AF02A48072644B08CA7D3D4B2547B955A2088918E7C1179051A10') {
       throw '中断: ZIP の SHA256 が確認した配布物と一致しません。展開せず、取得元とファイル名を確かめてください。'
   } else {
       'SHA256 は確認した配布物と一致しました。'
   }
   ```

   - 一致したと出れば、この節の手順 4 へ進む。エラーなら中断する
   - 「ダウンロード」を別の場所へ移している場合は、この節の手順 1 で `%USERPROFILE%\Downloads` に保存する

1. エクスプローラーで、ZIP の中身をすべて展開する。

   - ZIP を右クリックして「すべて展開」を選び、展開先を `%LOCALAPPDATA%\Programs\QEFIEntryManager` にする
   - 展開先が既にある場合は上書きせず中断する。この節では、異なる版を混ぜない
   - 展開先の直下に `QEFIEntryManager.exe`・`qefibootmgr.exe`・`Qt6Core.dll` があり、`platforms` フォルダーもあることを確かめる
   - ZIP の中から直接起動せず、exe だけを別のフォルダーに移さない

1. 管理者の PowerShell で、現在の起動順と AlmaLinux のエントリを確かめる。

   ```powershell
   & "$env:LOCALAPPDATA\Programs\QEFIEntryManager\qefibootmgr.exe" -v
   if ($LASTEXITCODE -ne 0) { throw '中断: QEFI の一覧を取得できませんでした。' }
   & "$env:SystemRoot\System32\bcdedit.exe" /enum firmware
   if ($LASTEXITCODE -ne 0) { throw '中断: BCDEdit の一覧を取得できませんでした。' }
   ```

   - CLI の `BootOrder` の並びと、AlmaLinux の `Boot` の後ろの 4 桁の番号を控える。AlmaLinux の行は `*` 付き（有効）であることを確かめる
   - BCDEdit の AlmaLinux の項目の `identifier`（識別子）と `path` を控える。名前だけでなく、CLI の EFI パスと同じブートローダーを指すことを確かめる（通常は `\EFI\almalinux\shimx64.efi`）
   - BCDEdit の `{fwbootmgr}`（ファームウェアのブート マネージャー）の `displayorder` も控える
   - `{fwbootmgr}` に `bootsequence` が既にあれば中断する。別の次回起動の予約を、この節では上書きしない
   - エラー・空の起動順・AlmaLinux が無い・無効・同名の候補を区別できない場合も中断する。番号を推測せず、エントリの追加・削除はしない
   - **次の手順は、両方の一覧と AlmaLinux の対応を確かめてから行う**

1. エクスプローラーで、QEFI Entry Manager を管理者として起動する。

   - 展開先の `QEFIEntryManager.exe` を右クリックして「管理者として実行」を選ぶ
   - UAC は、展開した実行ファイルであることを確かめてから「はい」を押す（配布物は署名無し）
   - `Boot Entries` タブに、この節の手順 5 と同じエントリが並ぶことを確かめる
   - 起動できない・一覧が出ない場合は中断する。Windows の保護を無効にして進めない

1. GUI で AlmaLinux を選び、次回の起動先に指定する。

   - この節の手順 5 で控えた番号と名前の行を選び、`Set reboot` を押す
   - `Reboot to …` の対象が AlmaLinux であることを確かめ、`Do you want to reboot now?` には `No` を選ぶ
   - **`No` は「今は再起動しない」で、予約の取り消しではない**
   - `Make default`・`Move up`・`Move down`・`Save` は使わない
   - **次の手順は、`No` を選んでから管理者の PowerShell に貼る**

1. 管理者の PowerShell で、次回の起動先と通常の起動順を読み戻す。

   ```powershell
   & "$env:LOCALAPPDATA\Programs\QEFIEntryManager\qefibootmgr.exe" -v
   if ($LASTEXITCODE -ne 0) { throw '中断: QEFI の一覧を取得できませんでした。再起動しないでください。' }
   & "$env:SystemRoot\System32\bcdedit.exe" /enum firmware
   if ($LASTEXITCODE -ne 0) { throw '中断: BCDEdit の一覧を取得できませんでした。再起動しないでください。' }
   ```

   - `BootNext` が、この節の手順 5 で控えた AlmaLinux の 4 桁の番号と一致することを確かめる
   - BCDEdit の `{fwbootmgr}` に `bootsequence` があり、その識別子が AlmaLinux の項目と一致することも確かめる（`BootNext: 0000` だけでは成功とみなさない）
   - `BootOrder` と `{fwbootmgr}` の `displayorder` が、どちらもこの節の手順 5 と同じ並びであることを確かめる
   - どれかが一致しない・予約が出ない・エラーが出た場合は、再起動せず中断する。自分が設定した予約だけを[取り消す節](#次回起動の指定を取り消す任意)で解除する

1. Windows で作業を保存して、再起動する。

   - 未保存の作業を保存し、スタートメニューの電源から「再起動」を選ぶ
   - AlmaLinux の GRUB のメニューが出たら、AlmaLinux の項目を選ぶ（UEFI の起動先の指定は、GRUB の既定の項目までは変えない）

1. AlmaLinux の画面で、起動できたことを確かめる。

   - AlmaLinux のログイン画面からログインし、デスクトップが出ることを確かめる
   - `BootNext` は次の起動で 1 回だけ使われ、その後は元の `BootOrder` に従う
   - その後の起動が必ず Windows になるわけではない。元の起動順の先頭が AlmaLinux なら、通常も AlmaLinux のブートローダーに進む

---

## 次回起動の指定を取り消す（任意）

- QEFI Entry Manager で指定した後、まだ再起動していないときに行う。展開先は[次回だけ起動する節](#次回だけ-almalinux-で起動する任意)と同じで、管理者の Windows PowerShell（5.1）に貼る
- 解除するのは次回だけの予約。AlmaLinux のエントリ自体は消さず、通常の起動順も変えない

1. BCDEdit で、取り消す予約を確かめる。

   ```powershell
   & "$env:SystemRoot\System32\bcdedit.exe" /enum firmware
   if ($LASTEXITCODE -ne 0) { throw '中断: BCDEdit の一覧を取得できませんでした。' }
   ```

   - `{fwbootmgr}` の `bootsequence` が自分の指定したエントリの識別子であることを確かめる。別の対象や不明な対象なら中断する
   - `{fwbootmgr}` に `bootsequence` が無ければ、この節の手順 2 は飛ばす

1. 自分が指定した予約が残っているときだけ、解除する。

   ```powershell
   & "$env:LOCALAPPDATA\Programs\QEFIEntryManager\qefibootmgr.exe" -N
   if ($LASTEXITCODE -ne 0) { throw '中断: 次回起動の指定を解除できませんでした。' }
   ```

   - オプションは大文字の `-N`。`-B`（エントリ削除）や `-O`（起動順削除）は使わない
   - `BootNext deleted` が出ても成功と決めず、この節の手順 3 で確認する

1. 予約が消え、通常の起動順が変わっていないことを確かめる。

   ```powershell
   & "$env:LOCALAPPDATA\Programs\QEFIEntryManager\qefibootmgr.exe" -v
   if ($LASTEXITCODE -ne 0) { throw '中断: QEFI の一覧を取得できませんでした。' }
   & "$env:SystemRoot\System32\bcdedit.exe" /enum firmware
   if ($LASTEXITCODE -ne 0) { throw '中断: BCDEdit の一覧を取得できませんでした。' }
   ```

   - BCDEdit の `{fwbootmgr}` に `bootsequence` が無く、`BootOrder` と `displayorder` が指定前の並びならよい
   - CLI の `BootNext: 0000` は、予約が消えた根拠にも、エントリ `0000` の予約が残っている根拠にもならない
   - BCDEdit に予約が残る・一覧の取得に失敗する・起動順が違う場合は、解除できたとみなさず中断する

---

## 注意点

- **この後 AlmaLinux 10 を入れるとき**
  - 「インストール先」で「カスタム」を選び、手順 5 の ESP（2 GiB。既存の Windows のパーティションと一緒に「不明」の下に並ぶ）を選んで、マウントポイントを `/boot/efi` にする。**「再フォーマット」に印を付けない**（付けると Windows のブートローダーが消える）
  - `/boot`・`/`・swap は、未割り当て領域に作る。インストーラは NTFS を縮められないので、空きは手順 5 で残した分だけ
  - インストーラは、NTFS のパーティションを見つけると、ハードウェアの時計を現地時刻として扱う（`/etc/adjtime` に `LOCAL`）。Windows の時計の設定（`RealTimeIsUniversal`）は変えなくてよい（[Windows 11 の初期設定の手順 52](windows-setup.md#実施手順) は飛ばす。AlmaLinux の時計を UTC にしたときだけ行う）
  - GRUB の道具（`grub2-tools`）が os-prober を依存で入れ、os-prober は有効のまま。インストールの最後に、GRUB のメニューへ「Windows Boot Manager」が入るはず
- **BitLocker（デバイスの暗号化）**
  - この文書では Rufus の項目で自動の暗号化を止めている。手順 11 で暗号化されていたら、回復キーを PC の外に控える（`manage-bde -protectors -get C:`。Microsoft アカウントに保存されていれば `https://aka.ms/myrecoverykey` でも見られる）
  - AlmaLinux の GRUB から Windows を起動すると、TPM の測定値（PCR 7 など）が Windows が封じたときと変わり、回復キーを聞かれることがある（Microsoft の BitLocker の文書からの推測）。そのときは PC の起動メニューで「Windows Boot Manager」を選んで起動する
- **Rufus のローカル アカウント**
  - パスワードは空のまま作られる。次のサインインで変更を求められるまでは、PC の前の誰でもサインインできる
  - `net accounts /maxpwage:unlimited` で、この PC のローカル アカウント全体のパスワードの有効期限が無くなる
- **「利便性向上パッチ」の副作用**: OneDrive のセットアップと、Outlook・Teams のアプリが入らない。要るなら、後から入れる
- **インストールが「Windows 11 のインストールが失敗しました」で止まったとき**
  - Shift+F10 のコマンド プロンプトで `type C:\$Windows.~BT\Sources\Panther\setuperr.log` を見る
  - `0x80070570`（`Error in apply of …`）は、メディアの `install.wim` が壊れている。同じメディアでやり直しても、同じファイルで止まる。Rufus でメディアを作り直し、作った PC で `install.wim` のハッシュを ISO の中のものと比べてから使う
- **手順 4・5 を飛ばしてやり直したとき**: C: に前の回の残りがあると、セットアップが `C:\Windows.old` を作る。要らなければ、ディスク クリーンアップで消す
