# Windows 11 を AlmaLinux 10 とのデュアルブート向けに入れる手順（ESP を 2 GiB にし、AlmaLinux 用の空きを残す）

## 実施手順

> [!IMPORTANT]
> - **入れる先のディスクの中身は、手順 5 ですべて消える**。そのディスクに Windows 11 を新しく入れ、後ろに AlmaLinux 10 用の未割り当て領域を残す
> - **インストールメディアは、Rufus で作成済みとする**。「インストーラーをカスタムしますか?」でオンにした項目は次の 7 つ（[選択した方針](#選択した方針)）
>   - 「4GB以上のRAM、セキュアブート及びTPM 2.0の要件を削除」「オンラインアカウントの要件を削除」「ローカルアカウントを次の名前で作成:」「地域設定をこのユーザーと同じものに設定」「データ収集を無効化」「BitLocker 自動デバイス暗号化を無効化します。」「利便性向上パッチ(Microsoftの各種ソフトウェアの無効化)」
>   - **「⚠サイレント⚠ ディスクの削除とインストール」はオフにしてある**こと（オンだと、最初に見つかったディスクを確かめずに消して入れる）
> - 手順 1〜3・6〜8 は、PC の画面と機器で行う。**手順 4・5 は、セットアップのコマンド プロンプトに手で 1 行ずつ打つ**（貼り付けられない）
> - 手順 9〜13 は、入れた Windows の管理者の Windows PowerShell（5.1）に貼る

- 上から順に進める。手順 10・12・13 は、条件に当たるときだけ行う
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- やり直すときは、手順 3 から始める（ロールバックの節は無い）

> [!WARNING]
> **この文書の手順は、実機でも VM でも実行していない**（利用者の指示で、動作確認は行わなかった）。Microsoft の文書と、Rufus 4.15 のソースから書いた（[対象と検証環境](#対象と検証環境)）。

- 手順の後: AlmaLinux 10 は、手順 5 で残した未割り当て領域に入れる（この文書には含めない。入れるときの注意は[注意点](#注意点)）

> [!CAUTION]
> **手順 5 の `clean` で、選んだディスクのパーティションとデータをすべて消す（取り戻せない）。** ディスクの番号は、手順 4 で大きさを見て確かめる。

1. PC の UEFI（BIOS）の設定画面で、起動の設定を確かめる。

   - 起動のモードは UEFI にする（CSM・Legacy の起動は切る）
   - Secure Boot と TPM は有効のままにする
   - Secure Boot の項目に「Microsoft 3rd Party UEFI CA」を許可する設定があれば、許可にする（Rufus の USB の起動と、後で入れる AlmaLinux の起動に要る）
   - USB からの起動を許可する
   - 設定画面の開き方（電源を入れた直後に押すキー）と項目の名前は、PC のメーカーごとに違う

   <details>
   <summary>補足: 3rd Party UEFI CA が要る理由</summary>

   - Rufus は、大きなファイル（`install.wim`）がある ISO を NTFS で USB に書き、USB の末尾に UEFI:NTFS の小さなパーティションを足す。PC はまずこの UEFI:NTFS を起動し、それが NTFS の中の Windows のブートローダーを起動する（Rufus 4.15 の `src/drive.c`）
   - Rufus の `res/uefi/readme.txt` によれば、UEFI:NTFS のブートローダーと NTFS のドライバーは Microsoft の Secure Boot の署名付き。この署名は 3rd Party UEFI CA（Microsoft Corporation UEFI CA）で確かめられる
   - AlmaLinux 10 の shim も、同じ系列の CA（2011 と 2023 の Microsoft UEFI CA）で署名されている（AlmaLinux の wiki）
   - Secured-core PC など、3rd Party UEFI CA を既定で許可しない PC がある。許可していないと、Secure Boot の違反で起動が止まる

   </details>

1. LAN ケーブルを抜き、Wi-Fi にもつながない状態にする。

   - Rufus の「オンラインアカウントの要件を削除」は、インストールの間はネットワークから外しておくことを条件にしている（Rufus の画面の説明）
   - つなぐのは、手順 7 でデスクトップが出てから

1. Rufus の USB を挿し、PC の起動メニューから UEFI で起動して、セットアップの最初の画面まで進める。

   - 起動メニューを出すキー（F12・F11・Esc など）は PC ごとに違う。USB が 2 つ出るなら、名前が「UEFI:」で始まる方を選ぶ
   - 黒い画面に UEFI:NTFS の文字が流れてから、Windows のセットアップが始まる
   - 「言語設定」の画面が出たら、まだ「次へ」を押さずに手順 4 へ進む
   - Secure Boot の違反で止まるなら、手順 1 の 3rd Party UEFI CA を見直す

1. Shift+F10 でコマンド プロンプトを開き、UEFI で起動したことと、入れる先のディスクの番号を確かめる。

   ```text
   reg query HKLM\System\CurrentControlSet\Control /v PEFirmwareType
   diskpart
   list disk
   ```

   - 1 行ずつ打って Enter を押す（2 行目から `DISKPART>` のプロンプトになる）
   - Enter の前に、打った文字が画面に正しく出ているかを見る（キーボードの配置が合わないと、`\` や手順 5 の `=`・`"` が別の記号になる）
   - ノート PC で Shift+F10 が効かなければ、Shift+Fn+F10 を押す
   - 1 行目の結果が `0x2` なら UEFI で起動している。`0x1` なら BIOS（Legacy）の起動なので、手順 1・3 からやり直す
   - `list disk` に、ディスクの番号・大きさ・空き・GPT の印が並ぶ。**Windows を入れるディスクの番号を、大きさで見分けて控える**
   - Rufus の USB も 1 台のディスクとして並ぶ（USB メモリの大きさのもの）。選ばない

   <details>
   <summary>補足: PEFirmwareType と、ディスクを外しておくこと</summary>

   - `PEFirmwareType` は、WinPE（セットアップの環境）がどのモードで起動したかを示す値。Microsoft の文書（[参照](#参照)）では、`0x1` が BIOS、`0x2` が UEFI
   - UEFI で起動していないと、手順 5 の GPT のディスクに Windows を入れられない
   - ほかに内蔵のディスク（データ用など）がある PC では、取り違えないように、可能なら外してから始める

   </details>

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
   - `list partition` に 4 つのパーティション（2048 MB・16 MB・Windows の大きさ・1024 MB）が並べばよい
   - 1 つ目の `exit` で diskpart を、2 つ目の `exit` でコマンド プロンプトを閉じる
   - 途中で打ち間違えたら、`select disk 0`（控えた番号）から打ち直す

   <details>
   <summary>補足: 4 つのパーティションと、並べる順番</summary>

   Microsoft のサンプルの `CreatePartitions-UEFI.txt`（[参照](#参照)）と同じ形で、大きさだけを変えた。

   | 順 | パーティション | 大きさ | 形式 | 役目 |
   |---|---|---|---|---|
   | 1 | ESP（EFI システム パーティション） | 2 GiB | FAT32 | Windows と AlmaLinux のブートローダーを置く。AlmaLinux と共用する |
   | 2 | MSR（Microsoft 予約パーティション） | 16 MB | 無し | Windows が使う。中身は見えない |
   | 3 | Windows | `204800` MB の例で 200 GiB | NTFS | C: になる |
   | 4 | 回復（WinRE） | 1 GiB | NTFS | Windows の回復環境。ドライブ文字を付けない |
   | — | 未割り当て | 残り | — | AlmaLinux 10 を入れる |

   - **ESP を最初に置く**: Microsoft の GPT の FAQ は、ESP をディスクの先頭に置き、1 台のディスクに ESP を 2 つ作らないよう書いている。AlmaLinux も、この ESP を共用する
   - **MSR は 16 MB**: Microsoft の今の文書の値（古い FAQ には 32 MB・128 MB とある）
   - **回復は Windows のすぐ後ろ**: Microsoft の文書は「Windows のパーティションの直後に置く」としている。WinRE の更新で大きさが足りないとき、Windows が C: を縮めて回復パーティションを広げられるため
   - **回復は 1 GiB**: Microsoft は、自分で並びを作るときは 990 MB 以上（空き 250 MB 以上）を勧めている
   - `set id=` の値は回復パーティションの種類、`gpt attributes=0x8000000000000001` は「ドライブ文字を付けない」と「プラットフォームに要る」の 2 つの属性
   - サンプルは `create partition primary` で残り全部を取ってから `shrink` で回復の分を空けるが、ここでは後ろに AlmaLinux の領域を残すので、Windows と回復の大きさを `size=` で決めた

   </details>

1. セットアップに戻り、手順 5 の「Windows」のパーティションを選んでインストールする。

   - 「言語設定」→「キーボード設定の選択」→「セットアップの選択オプション」（「Windows 11 のインストール」を選び、すべてが削除されることへの同意に印を付ける）→「プロダクト キー」→「イメージの選択」→「適用される通知とライセンス条項」の順に進む
   - **「Windows 11 をインストールする場所の選択」では、手順 5 で作った Windows の大きさのパーティション（手順 4 で控えたディスクの、パーティション 3）を選び、「次へ」を押す**
   - この画面では「パーティションの削除」を押さず、「未割り当て領域」も選ばない（選ぶと、セットアップがそこに自分の並びを作る）
   - 「Ready to install」の画面で「インストール」を押す。途中で何度か再起動する
   - 最初の再起動のときに USB を抜く（挿したままだと、PC によっては USB から起動し直し、セットアップが最初から始まる）

   <details>
   <summary>補足: 画面の名前と、既存のパーティションに入れるとき</summary>

   - 画面の名前は、Microsoft のサポートの「インストール メディアを使用して Windows を再インストールする」の日本語のページ（[参照](#参照)）から写した。実物の画面では確かめていない
   - 一覧が手順 5 の前のままなら、画面の更新のボタンを押す
   - 既にある ESP と MSR を、セットアップは作り直さずに使う（Microsoft の古い文書では、どちらも無いときだけ作る）
   - WinRE がどこに入るかは、手順 9 で確かめる

   </details>

1. 初回の起動を待ち、Rufus で作ったローカル アカウントでデスクトップまで進む。

   - Rufus の設定で、地域・キーボード・ライセンス・プライバシー・アカウントの質問は出ないはず（出たら、画面に従って進む）
   - ネットワークにつなぐよう求められたら、インターネットにつながずに進む選択肢を選ぶ
   - ローカル アカウントのパスワードは空。**次にサインインするときに、パスワードの変更を求められる**ので、そこで決める
   - デスクトップが出たら、LAN ケーブルや Wi-Fi につないでよい

   <details>
   <summary>補足: Rufus が OOBE で行うこと</summary>

   - Rufus 4.15 の `src/wue.c` は、オンにした項目から `unattend.xml` を作り、USB の `sources\$OEM$\$$\Panther\` に置く
   - セットアップがファイルをコピーするときに `C:\Windows\Panther\` へ入り、初回の起動（OOBE）とその前の段階で使われる
   - 「ローカルアカウントを次の名前で作成:」: Administrators のローカル アカウントを空のパスワードで作り、最初のサインインのときに `net user "<名前>" /logonpasswordchg:yes`（次のサインインでパスワードの変更を求める）と `net accounts /maxpwage:unlimited`（パスワードの有効期限を無くす）を実行する
   - 「オンラインアカウントの要件を削除」: `BypassNRO` を 1 にする（ネットワーク無しで進む選択肢を出す）
   - 「データ収集を無効化」: ライセンスの画面を出さず、プライバシーの質問に「いいえ」で答える（`HideEULAPage`・`ProtectYourPC` が 3）
   - 「地域設定をこのユーザーと同じものに設定」: Rufus を動かした PC の入力ロケール・ロケール・タイムゾーンを書く（タイムゾーンは手順 11 で確かめる）
   - ネットワークの画面を隠す設定（`HideOnlineAccountScreens` など）は、Rufus はサイレントのときにしか書かない

   </details>

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、右クリックして「管理者として実行」で開く
   - Rufus で作ったローカル アカウントは Administrators の一員なので、昇格できる

1. パーティションの並び・ESP の大きさ・未割り当て領域・WinRE の場所を確かめる。

   ```powershell
   $d = (Get-Partition -DriveLetter C).DiskNumber
   Get-Partition -DiskNumber $d | Format-Table PartitionNumber, DriveLetter, Size, Type -AutoSize
   Get-Disk -Number $d | Format-List Number, PartitionStyle, Size, LargestFreeExtent
   reagentc /info
   ```

   - パーティションが `System`（2 GB）・`Reserved`（16 MB）・`Basic`（C:）・`Recovery`（1 GB）の順に 4 つ並べばよい
   - `PartitionStyle` が `GPT` で、`LargestFreeExtent` が AlmaLinux 用に残した大きさ（バイト）になっていればよい
   - `reagentc /info` の Windows RE の状態が `Enabled` で、場所が `…\partition4\Recovery\WindowsRE`（回復パーティション）なら、手順 10 は飛ばす
   - 場所が `partition3`（C:）か空なら、手順 10 で回復パーティションへ移す

   <details>
   <summary>補足: WinRE の場所</summary>

   - Microsoft の文書によれば、セットアップは WinRE のイメージをまず `C:\Windows\System32\Recovery` に置き、specialize の段階で回復パーティションへコピーする
   - セットアップが、自分で作っていない回復パーティション（手順 5）を使うかは、Microsoft の文書では確かめられなかった
   - WinRE が C: にあっても回復環境は動く。回復パーティションが使われずに残るだけ

   </details>

1. WinRE が回復パーティションに無いときだけ、回復パーティションへ移す。

   ```powershell
   reagentc /disable
   reagentc /enable
   reagentc /info
   ```

   - 最後の `reagentc /info` で、場所が `…\partition4\Recovery\WindowsRE` になればよい

   <details>
   <summary>補足: この 2 つのコマンドで移る理由</summary>

   - Microsoft の KB5028997（回復パーティションを手で広げる手順。[参照](#参照)）は、`reagentc /disable` で WinRE を C: に戻し、回復パーティションを作り直してから `reagentc /enable` で WinRE を有効にし、`reagentc /info` で回復パーティションに入ったことを確かめている
   - この手順では、回復パーティションは手順 5 で作ってあるので、作り直しを省いた

   </details>

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

   <details>
   <summary>補足: 高速スタートアップを切る理由と、タイムゾーン</summary>

   - 高速スタートアップは、シャットダウンのときに Windows のカーネルの状態を休止状態のファイルに書いて、次の起動を速くする。切っておくと、AlmaLinux に切り替える前のシャットダウンが、毎回ふつうのシャットダウンになる
   - Rufus の「利便性向上パッチ」は、最初のサインインのときに `HiberbootEnabled` を 0 にする（`src/wue.c`）
   - Rufus の「地域設定をこのユーザーと同じものに設定」は、Rufus を動かした PC のタイムゾーンの表示名（`GetTimeZoneInformation` の `StandardName`）を、`unattend.xml` の `TimeZone` に書く
   - `TimeZone` が受け付けるのは `Tokyo Standard Time` のような ID。日本語の Windows で表示名が日本語になっていると合わない（推測）
   - Rufus の issue（[参照](#参照)）にも、この項目でタイムゾーンが設定されなかった報告がある

   </details>

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

## 補足

### 対象と検証環境

- **目的**: 1 台のディスクに Windows 11 と AlmaLinux 10 を入れるために、Windows を先に新しく入れる
  - Windows のセットアップのコマンド プロンプトで、ESP を 2 GiB で作り、Windows と回復のパーティションの後ろに AlmaLinux 用の未割り当て領域を残す
  - AlmaLinux 10 のインストールは、この文書には含めない（[注意点](#注意点)に、入れるときの要点だけを置いた）
- **進め方**: インストールメディアは、利用者が Rufus で作ったもの（「インストーラーをカスタムしますか?」の 7 項目をオン）を使う。手順 4・5 はセットアップのコマンド プロンプトに手で打ち、手順 9〜13 は入れた Windows の PowerShell に貼る
- **状態**: **未検証（実機でも VM でも実行していない）**
  - 利用者の指示で、動作確認は行わなかった
  - 次の資料から書いた（[参照](#参照)）
    - diskpart の並び: Microsoft Learn の UEFI/GPT のパーティションの文書と、サンプルの `CreatePartitions-UEFI.txt`
    - セットアップの画面の名前: Microsoft のサポートの、インストール メディアで再インストールする手順（日本語）
    - Rufus の項目が行うこと: Rufus 4.15（2026-06-30）のソース（`src/wue.c`・`src/drive.c`・`res/loc/rufus.loc`）
    - WinRE の移し方: Microsoft の KB5028997
    - AlmaLinux 10.2 のインストーラ（Anaconda 40.22.3.46）の振る舞い: rhinstaller/anaconda の `rhel-10` ブランチと、blivet のソース
  - 途中まで試した VM（QEMU の TCG）では、Rufus のソースどおりに作ったメディアが、Secure Boot が有効なまま UEFI:NTFS から Windows のブートマネージャーまで起動した。その先は画面が出ないまま中止した（[付録](#付録-vm-での試み2026-10-03中止)）
  - **確認していないこと**: この文書のすべての手順。特に、セットアップのコマンド プロンプトでの打ち込み（日本語のキーボードの配置を含む）、セットアップが手順 5 の回復パーティションを使うか、Rufus の項目が OOBE の画面に与える影響、タイムゾーンの扱い、Home エディション

| 項目 | 想定 |
|---|---|
| PC | x86_64、UEFI（Secure Boot と TPM 2.0 が有効）、内蔵のディスク 1 台 |
| Windows | Windows 11（24H2 以降。調べた時点の評価版は 26H2、ビルド 26300） |
| メディア | Rufus 4.15 で作った USB（GPT、ターゲットは UEFI、NTFS + UEFI:NTFS） |
| 後で入れるもの | AlmaLinux 10.2（x86_64） |

> [!NOTE]
> 手順 5 の値（ディスクの番号 `0`、Windows の大きさ `204800`）は例で、手で打つときに直す。この文書は実行していないので、出力例は載せていない。

手順書全体に関わる理由・落とし穴（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 選択した方針

- **ESP を 2 GiB にする**
  - セットアップの「Windows 11 をインストールする場所の選択」の画面では、ESP の大きさを選べない。そこで、手順 5 で diskpart を使って先に作る
  - Microsoft Learn（2026-09-09 更新）が示すのは最小（512 / 512e のディスクで 200 MB、4Kn で 300 MB）だけで、上限は無い。diskpart の文書の例も `create partition efi size=1000`
  - 2026-05 の更新プログラム KB5089549 は、ESP の空きが 10 MB 以下の 24H2 / 25H2 の PC で失敗した（Windows のリリース正常性）
  - AlmaLinux の shim と GRUB、ファームウェアの更新のファイル、将来の UKI や別の Linux を置いても余裕がある。AlmaLinux のインストーラが自分で ESP を作るときは 500〜600 MiB
- **ESP は Windows と AlmaLinux で共用する**: 1 台のディスクに ESP を 2 つ作らない（Microsoft の GPT の FAQ）。Rufus も、USB の UEFI:NTFS のパーティションを ESP の種類にしない（Windows のセットアップが 2 つ目の ESP で失敗するため。`src/drive.c` のコメント）
- **並びは Microsoft のサンプルに合わせ、大きさを `size=` で決める**: ESP → MSR → Windows → 回復の順。回復を Windows の直後に置き、AlmaLinux の領域はその後ろに残す（手順 5 の補足）
- **Windows のセットアップの中で diskpart を使う**: 別の道具でパーティションを作ると、Rufus の USB のほかにもう 1 本のメディアが要る。セットアップの環境（WinPE）に入っている diskpart で足りる
- **「⚠サイレント⚠ ディスクの削除とインストール」は使わない**: 最初に見つかったディスクを確かめずに消し、ESP を 260 MB で作って、残り全部を Windows にする（`src/wue.c`）。手順 5 の並びにならない
- **ロールバックの節は置かない**: ディスクを消して入れ直す手順なので、戻すときも手順 3 から入れ直す

**Rufus の 7 項目と、この文書の手順の関係**:

| Rufus の項目 | Rufus がすること（4.15 の `src/wue.c`） | この文書の手順 |
|---|---|---|
| 4GB以上のRAM、セキュアブート及びTPM 2.0の要件を削除 | `boot.wim` の中のレジストリに `HKLM\SYSTEM\Setup\LabConfig` の `BypassTPMCheck`・`BypassSecureBootCheck`・`BypassRAMCheck` を書く | 無し（要件を満たす PC でも、Rufus はオンを勧めている） |
| オンラインアカウントの要件を削除 | `BypassNRO` を 1 にする。ネットワークから外しておくことが条件 | 手順 2・7 |
| ローカルアカウントを次の名前で作成: | 空のパスワードの管理者のアカウントを作り、次のサインインで変更を求める | 手順 7 |
| 地域設定をこのユーザーと同じものに設定 | Rufus を動かした PC の入力ロケール・ロケール・タイムゾーンを書く | 手順 11・13 |
| データ収集を無効化 | ライセンスの画面を隠し、プライバシーの質問に「いいえ」で答える | 手順 7 |
| BitLocker 自動デバイス暗号化を無効化します。 | `PreventDeviceEncryption` を true にする | 手順 11 |
| 利便性向上パッチ(Microsoftの各種ソフトウェアの無効化) | OneDrive・Outlook・Teams を外し、Copilot・ニュースなどを切り、`HiberbootEnabled` を 0 にする | 手順 11・12 |

### 完了時点の状態

手順どおりに進めたときの、ディスクの並び（想定。実行していない）:

| パーティション | 大きさ | Windows の `Type` | 後で AlmaLinux から見たとき |
|---|---|---|---|
| 1. ESP | 2 GiB | `System` | `/boot/efi` に割り当てる（フォーマットしない） |
| 2. MSR | 16 MB | `Reserved` | 触らない |
| 3. Windows | 手順 5 の `size=` | `Basic`（C:） | 触らない |
| 4. 回復 | 1 GiB | `Recovery` | 触らない |
| 未割り当て | ディスクの残り | — | AlmaLinux 10 を入れる |

- 高速スタートアップは切れている（`HiberbootEnabled` が 0）
- BitLocker（デバイスの暗号化）は使われていない
- Rufus で作ったローカル アカウントがあり、パスワードは次のサインインで決める

### 注意点

- **この後 AlmaLinux 10 を入れるとき**（AlmaLinux 10.2 のインストーラのソースから読んだこと。試していない）
  - 「インストール先」で「カスタム」を選び、手順 5 の ESP（2 GiB。既存の Windows のパーティションと一緒に「不明」の下に並ぶ）を選んで、マウントポイントを `/boot/efi` にする。**「再フォーマット」に印を付けない**（付けると Windows のブートローダーが消える）
  - `/boot`・`/`・swap は、未割り当て領域に作る。インストーラは NTFS を縮められないので、空きは手順 5 で残した分だけ
  - インストーラは、NTFS のパーティションを見つけると、ハードウェアの時計を現地時刻として扱う（`/etc/adjtime` に `LOCAL`）。Windows の時計の設定（`RealTimeIsUniversal`）は変えなくてよい
  - GRUB の道具（`grub2-tools`）が os-prober を依存で入れ、os-prober は有効のまま。インストールの最後に、GRUB のメニューへ「Windows Boot Manager」が入るはず
- **BitLocker（デバイスの暗号化）**
  - この文書では Rufus の項目で自動の暗号化を止めている。手順 11 で暗号化されていたら、回復キーを PC の外に控える（`manage-bde -protectors -get C:`。Microsoft アカウントに保存されていれば `https://aka.ms/myrecoverykey` でも見られる）
  - AlmaLinux の GRUB から Windows を起動すると、TPM の測定値（PCR 7 など）が Windows が封じたときと変わり、回復キーを聞かれることがある（Microsoft の BitLocker の文書からの推測）。そのときは PC の起動メニューで「Windows Boot Manager」を選んで起動する
- **Rufus のローカル アカウント**
  - パスワードは空のまま作られる。次のサインインで変更を求められるまでは、PC の前の誰でもサインインできる
  - `net accounts /maxpwage:unlimited` で、この PC のローカル アカウント全体のパスワードの有効期限が無くなる
- **「利便性向上パッチ」の副作用**: OneDrive のセットアップと、Outlook・Teams のアプリが入らない。要るなら、後から入れる

### 参照

- [UEFI/GPT-based hard drive partitions](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/configure-uefigpt-based-hard-drive-partitions)（ESP・MSR・回復の大きさと並び、サンプルの `CreatePartitions-UEFI.txt`）
- [Windows and GPT FAQ](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-and-gpt-faq)（ESP は先頭に 1 つ）
- [create partition efi](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/create-partition-efi)（diskpart の `create partition efi size=`）
- [Boot to UEFI Mode or legacy BIOS mode](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/boot-to-uefi-mode-or-legacy-bios-mode)（`PEFirmwareType`）
- [Windows Recovery Environment (Windows RE) technical reference](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-recovery-environment--windows-re--technical-reference)（セットアップが WinRE を回復パーティションへコピーする段階、回復パーティションの広げ方）
- [KB5028997: Instructions to manually resize your partition to install the WinRE update](https://support.microsoft.com/en-us/topic/kb5028997-instructions-to-manually-resize-your-partition-to-install-the-winre-update-400faa27-9343-461c-ada9-24c8229763bf)（`reagentc /disable` → `reagentc /enable`）
- [インストール メディアを使用して Windows を再インストールする](https://support.microsoft.com/ja-jp/windows/reinstall-windows-with-the-installation-media-d8369486-3e33-7d9c-dccc-859e2b022fc7)（セットアップの画面の名前）
- [Windows 11, version 25H2 known issues](https://learn.microsoft.com/en-us/windows/release-health/status-windows-11-25h2)（KB5089549 と ESP の空き）
- [BitLocker countermeasures](https://learn.microsoft.com/en-us/windows/security/operating-system-security/data-protection/bitlocker/countermeasures) / [Find your BitLocker recovery key](https://support.microsoft.com/en-us/windows/find-your-bitlocker-recovery-key-6b71ad27-0b89-ea08-f143-056f5ab347d6)（PCR 7、回復キー）
- [Rufus](https://github.com/pbatard/rufus) 4.15 のソース: `src/wue.c`（「インストーラーをカスタムしますか?」の各項目）、`src/drive.c`（USB の並びと UEFI:NTFS）、`res/loc/rufus.loc`（日本語の表示）、[issue #2499](https://github.com/pbatard/rufus/issues/2499)（地域設定でタイムゾーンが設定されなかった報告）
- [rhinstaller/anaconda](https://github.com/rhinstaller/anaconda) の `rhel-10` ブランチ（既存の ESP の再利用、Windows の検出と `/etc/adjtime`）

---

### 付録: VM での試み（2026-10-03、中止）

**目的**: この文書の手順 3〜13 を VM で通す予定だった。利用者の指示で、途中で中止した。

**環境**: Ubuntu 24.04 / x86_64 のクラウドホスト（KVM 無し）の QEMU 8.2.2（TCG）。OVMF は Ubuntu の 2024.02-2ubuntu0.9 の `OVMF_CODE_4M.secboot.fd` と `OVMF_VARS_4M.ms.fd`（db に Microsoft の 2011 と 2023 の CA が入っている）、swtpm の TPM 2.0、NVMe のディスク。

**メディア**: Rufus は Windows でしか動かないので、Windows 11 Enterprise 評価版（26H2、日本語、ビルド 26300.9457）の ISO から、Rufus 4.15 のソースどおりの USB のイメージを Linux の道具で作った。

- GPT で、NTFS の「Main Data Partition」と、末尾 1 MiB の「UEFI:NTFS」（basic data、ドライブ文字を付けない属性。中身は Rufus の `res/uefi/uefi-ntfs.img`）
- `boot.wim` の 2 番のイメージの SYSTEM ハイブに `LabConfig` の 3 つの値、空の `appraiserres.dll`、Rufus の `setup.exe` のラッパー
- `sources\$OEM$\$$\Panther\unattend.xml`（7 項目で `src/wue.c` が書く内容を、そのまま生成したもの）

**結果**:

- Secure Boot が有効なまま、UEFI:NTFS 2.8 が起動し（`Secure Boot status: Enabled`）、NTFS の中の `efi\boot\bootx64.efi` から Windows のブートマネージャーが起動した
- ブートマネージャーが `boot.wim`（約 670 MB）を読み込んだ後、画面が真っ黒のままになった。vCPU はカーネルとユーザーモードのコードを実行し続けていたが、1 回目（`-vga std`・`-cpu max`）は約 45 分待っても画面は出なかった
- CPU を `Skylake-Client-v4` に変えた回（約 15 分）、元の ISO を CD として起動した回（約 6 分）、さらに表示を `ramfb` に変えた回（約 38 分）も、同じだった
- ここで利用者の指示により中止した。パーティションの手順（手順 4 以降）には進んでいない
