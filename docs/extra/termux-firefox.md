# Android のセットアップの注意点

[手順書の「Termux の Firefox」](../android.md#termux-の-firefox)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/termux-firefox.md)・[参考資料](../reference/termux-firefox.md)

- 手順番号は、名前を付けた手順書の項の番号を指す

## 注意点

- Termux の Firefox は、サンドボックスを外してビルドされている。知らないサイトの普段の閲覧には使わず、自分のサイトの確かめなどに使う（[補足](../reference/termux-firefox.md#termux-の-firefox--手順-2-補足-サンドボックスと更新)）
- [Termux の Firefox: ホーム画面のアイコンで起動する](../android.md#termux-の-firefox-ホーム画面のアイコンで起動する)の手順 3 の「他のアプリの上に重ねて表示」は、Termux がほかのアプリの画面に重ねて表示できるようになる権限。要らなくなったらオフに戻せる
- Firefox は、[Termux の Firefox: 起動と終了](../android.md#termux-の-firefox-起動と終了)の手順 2 のメニューの「Exit」で閉じる。`pkill -f termux-x11` で止めると、次の起動で「Restore Session」が出る
- `pkg upgrade` で FFmpeg の版が Firefox の読める上限を超えると、H.264 が再生されなくなるおそれがある（確かめていない）。そのときは、[Termux: 更新](../android.md#termux-更新)の手順 1 で Firefox も上げる
- ルート証明書は、[Termux の Firefox: ルート証明書を入れる](../android.md#termux-の-firefox-ルート証明書を入れる)の手順 2 でホストの指紋と比べる。違えば取り込まない。サイトの警告の画面では進まない
