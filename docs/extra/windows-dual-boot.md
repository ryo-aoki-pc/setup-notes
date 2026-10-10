# Windows 11 を AlmaLinux 10 とのデュアルブート向けに入れる手順（ESP を 2 GiB にし、AlmaLinux 用の空きを残す）の注意点

[手順書](../windows-dual-boot.md)・[検証記録](../verification/windows-dual-boot.md)・[参考資料](../reference/windows-dual-boot.md)

- 「手順 N」は[手順書](../windows-dual-boot.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す

## 注意点

- **この後 AlmaLinux 10 を入れるとき**
  - 「インストール先」で「カスタム」を選び、手順 5 の ESP（2 GiB。既存の Windows のパーティションと一緒に「不明」の下に並ぶ）を選んで、マウントポイントを `/boot/efi` にする。**「再フォーマット」に印を付けない**（付けると Windows のブートローダーが消える）
  - `/boot`・`/`・swap は、未割り当て領域に作る。インストーラは NTFS を縮められないので、空きは手順 5 で残した分だけ
  - インストーラは、NTFS のパーティションを見つけると、ハードウェアの時計を現地時刻として扱う（`/etc/adjtime` に `LOCAL`）。Windows の時計の設定（`RealTimeIsUniversal`）は変えなくてよい（[Windows 11 の初期設定の「サインイン・検索・キーボード」の手順 5](../windows-setup.md#サインイン検索キーボード) は飛ばす。AlmaLinux の時計を UTC にしたときだけ行う）
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
