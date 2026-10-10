# Windows 11 でホットキーを使用しているアプリを調べる手順の参考資料

[手順書](../windows-hotkey-conflict.md) / [検証記録](../verification/windows-hotkey-conflict.md)

## 補足

### 実施手順 / 手順 1・2: 補足: 登録一覧に載るホットキー

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

### 実施手順 / 手順 3: 補足: Detect application の検出方式

- 公式説明では、グローバルなメッセージフックの DLL を使い、選んだホットキーの入力を模擬して、そのイベントを待つ（[Hotkey Screener](https://www.ntwind.com/freeware/hotkey-screener.html)）
- 検出は登録情報だけを読む操作ではない。キーに割り当てられた処理が実行されることがあるため、対象キーを選んでから検出する
- 検出前に作業を保存する。割り当てられた操作が不明なまま、複数のキーをまとめて検出しない
- 公式は 32 bit・64 bit、通常権限・管理者権限のプロセスへの対応を説明している。個々の環境での検出成否は[検証記録](../verification/windows-hotkey-conflict.md)で管理する

### 実施手順 / 手順 4: 補足: 使用アプリの情報と Windows の通知

- `RegisterHotKey` で登録したキーが押されると、Windows は登録先へ `WM_HOTKEY` を投稿する
- `WM_HOTKEY` の `wParam` はホットキーの識別子、`lParam` は修飾キーと仮想キーコードを表す。メッセージのパラメーターに使用アプリ名や PID が入っているわけではない（[WM_HOTKEY](https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-hotkey)）
- 登録先のウィンドウハンドルが分かる場合は、`GetWindowThreadProcessId` でそのウィンドウを作成したスレッドとプロセスの ID を取得できる。この関数はキーの組み合わせから所有アプリを検索するものではない（[Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowthreadprocessid)）
- `RegisterHotKey` の `hWnd` が `NULL` なら、通知先は登録したスレッドのメッセージキューになる。特定のウィンドウを経由しない登録もある
- Hotkey Screener が `hWnd = NULL` の登録をどこまで検出するかは、公式ページに明示されていない。今回確認した登録方式は[検証記録](../verification/windows-hotkey-conflict.md)に残し、全種類の登録への対応を保証しない
- 表示されたアプリ名と PID を実行中のプロセスと照合する。同名の実行ファイルが複数ある場合も、名前だけで同じプロセスと判断しない
- 検出結果はアプリを調べる手がかりとして使い、そのアプリの対象キーの設定と変更後の動作を照合する

### 実施手順 / 手順 5: 補足: 設定を一つずつ変える理由

- 検出したアプリの同じキーを解除または変更し、変更前と同じウィンドウ・入力方式・キー操作で比較する
- 複数のアプリをまとめて止めると、どの変更で競合が解消したか分からなくなる
- 設定変更で改善しなかった場合は元に戻す。アプリを終了して比較した場合は、通常起動してから次の候補へ進む
- 設定画面に同じキーがあるだけでは、その時点で取り込んでいることまでは確定しない。設定の一致、検出結果、変更後の実操作を区別して記録する
- 解消した競合を記録するために、問題の設定を再び有効にすることは必須にしない

### 実施手順 / 手順 6: 補足: 記録と診断ツールの終了

- 対象キー、検出したアプリ情報、変更前後の設定、実操作の結果を残す。未検出の状態と、登録一覧に無い状態は分けて書く
- 調査したユーザー・ログインセッションや入力方式が違えば結果も変わり得るため、比較した条件を残す
- Hotkey Screener の終了時に、検出用 DLL が各プロセスから直ちに解放されるかは公式ページに明示されていない
- ツールの終了確認と、DLL の解放確認は同じではない。終了だけで DLL の解放まで確認したと記録しない
- 共有する記録では、ユーザー名などを含む実行パスの固有部分を伏せる

### 初回準備 / 手順 1〜3: 補足: 配布と署名

- 公式の配布は ZIP。展開して使う形を既定の経路にする（[Hotkey Screener](https://www.ntwind.com/freeware/hotkey-screener.html)）
- NTWind は、2007 年 3 月 1 日以降の新しい公開版にデジタル署名を付ける方針を説明している。配布方針と、取得したファイルの署名が有効であることは別に確認する（[Digital Signatures](https://www.ntwind.com/software/digital-signatures.html)）
- ソース公開や検出用 DLL の内部実装は確認できていない。公式に明示されていない動作は、対応済みと推測して記載しない

### 権限要求を減らすために Program Files へ配置する（任意） / 手順 1〜4: 補足: UIAccess の配置

- 公式は、管理者権限を求めるメッセージが頻発する場合に、EXE と DLL を `%ProgramFiles%` 配下へコピーして、その場所から再起動するよう案内している
- この配置は公式の UIAccess の案内に対応する。初回から必須の配置として扱わず、権限要求が頻発した場合の対処にする
- 配置先からの起動と権限要求の結果は、実際に配置した環境で確認する。通常の展開先での検出成功を、Program Files 配置の検証結果に含めない

### 使用アプリが分からない場合の切り分け / 手順 1〜6: 補足: 登録と入力フックを分ける

- Hotkey Screener の公式説明には、あるアプリが登録したキーを、別のアプリが低レベルキーボードフックや raw input で抑止するため、検出できない場合がある
- `WH_KEYBOARD_LL` のフックは `RegisterHotKey` と別の仕組み。フックが非ゼロを返すと、キーを後続のフックや対象ウィンドウへ渡さないことができる（[LowLevelKeyboardProc](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/legacy/ms644985(v=vs.85))）
- ツールがメッセージフックを使うことは、入力を抑止した低レベルフックの所有アプリまで調べられることを意味しない
- 一覧に対象キーが無い場合と、一覧にはあるが検出結果が表示されない場合は区別する。どちらも「使用アプリ無し」の証明にはしない
- 対象アプリのメニューからの動作、入力方式、フォーカス、接続方法をそろえ、常駐アプリの設定を一つずつ比較する
- 入力ログにキーの押下が無い場合も、そのログだけで特定アプリを原因と決めない

### ホットキーの登録可否を確認する（任意） / 手順 3: 補足: RegisterHotKey で分かる範囲

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

### ホットキーの登録可否を確認する（任意） / 手順 2・3: 補足: 同じスレッドで解除する理由

- `hWnd = NULL` で登録したホットキーは呼び出したスレッドに属する。`UnregisterHotKey` は呼び出しスレッドが登録したホットキーを解除する（[RegisterHotKey](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-registerhotkey)、[UnregisterHotKey](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-unregisterhotkey)）
- PowerShell から登録と解除を別々に呼ぶ構成にせず、同じスレッド内で登録、エラー取得、解除まで完了する構成にする
- 登録失敗のエラーはその直後に取得する。成功時の古いエラー値を今回の結果として使わない
- 解除するのは、試験自身が登録に成功した場合だけ。競合で登録に失敗したときに、既存アプリの登録を解除しようとしない
- 解除の成否も確認する。解除失敗を登録可能の正常結果に含めず、診断用 PowerShell を閉じてから対象アプリの確認へ進む

### ロールバック / 手順 1・2: 補足: 調査と対処の戻し方

- 調査前に有効状態とキー設定を控え、その調査で変えた設定だけを戻せるようにする
- 改善しなかった設定を戻す操作と、解消した競合の対処を取り消す操作は区別する。後者は競合が再び起きる可能性を含む
- アプリの通常の設定画面で戻せる対処を優先し、診断目的でサービス停止やアプリのアンインストールを行う構成にはしない

### 選択した方針

- 対象キーの使用アプリを調べる主手順は、Hotkey Screener の登録一覧から対象を選んで検出する形にする
- 初回のダウンロード・展開と、繰り返す調査操作を分ける。通常は ZIP を展開して起動し、Program Files 配置は権限要求が頻発した場合の対処にする
- 検出したアプリのキー設定と、変更後の実操作を合わせて判断する
- 一覧に無いキーや未検出の状態は、一般的な入力の切り分けへ進む分岐として残す
- PowerShell の登録可否試験は任意の補助にする。使用アプリを取得する機能ではなく、入力フックなども検出できないため
- ツールの実機での確認範囲は[検証記録](../verification/windows-hotkey-conflict.md)へ分け、公式説明だけで実機検証済みにしない

### 参照

- [Hotkey Screener — NTWind Software](https://www.ntwind.com/freeware/hotkey-screener.html)（登録一覧、検出方式、Windows 対応、権限、未検出の条件）
- [Digital Signatures — NTWind Software](https://www.ntwind.com/software/digital-signatures.html)（配布するソフトの署名方針）
- [RegisterHotKey — Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-registerhotkey)（システム全体の登録、成否、スレッドへの所属、OS の既定ホットキー）
- [WM_HOTKEY — Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-hotkey)（通知先、識別子、修飾キー、仮想キーコード）
- [GetWindowThreadProcessId — Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowthreadprocessid)（指定したウィンドウの作成元スレッドとプロセス）
- [UnregisterHotKey — Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-unregisterhotkey)（呼び出しスレッドが登録したホットキーの解除）
- [System Error Codes (1300–1699) — Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/debug/system-error-codes--1300-1699-)（1409）
- [LowLevelKeyboardProc — Microsoft Learn](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/legacy/ms644985(v=vs.85))（低レベルフックによる入力の抑止）

---
