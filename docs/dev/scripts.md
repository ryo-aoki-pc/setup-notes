# Windows の手順書のスクリプト

手順書の項が実行するスクリプトの決まり。Windows PowerShell 5.1 と PowerShell 7 の両方で読める形にし、手順書と実行する処理を一か所で保守する。

## 置き場所と役割

- `scripts/windows/<id>/item.json` は項の定義、`check.ps1` は読み取り、`apply.ps1` は変更を受け持つ
- 対話の要る項は `terminal.ps1` にする。Git Bash の項は `check.sh`・`apply.sh` にする
- 共通の部品は `scripts/windows/_lib/SetupItem.psm1` に置く
- 1 項は 1 つの権限と 1 つの実行先にする。手順書の 1 手順が複数の独立した設定を変えるなら、項も手順も分ける
- 案内の項も、値を確実に読み取れるものは `check.ps1` を置く。読めないものは置かず、画面と人の操作で確かめる。`apply.ps1` が設定画面を開く形でもよい

## 項の定義

`item.json` は BOM 無しの UTF-8 の JSON にする。項目は次のとおり。

| 項目 | 内容 |
| --- | --- |
| `id` | ディレクトリと同じ、英小文字・数字・ハイフンの一意な名前 |
| `title`・`category` | 日本語の項名と手順書のカテゴリ |
| `kind` | `auto`（自動）・`guide`（画面の案内）・`terminal`（対話する端末）・`external`（別の場所での操作） |
| `shell` | `ps51`・`ps7`・`ps7\|ps51`・`gitbash`。手順書で貼る窓と同じ版 |
| `privilege`・`checkPrivilege` | 変更と読み取りの権限。`user`・`admin`。通常のユーザーで読める値を使い、できるだけ `checkPrivilege: user` にする |
| `requires`・`after` | 先に完了させる項の ID と、並び順だけを指定する項の ID の配列。指定が無ければ空の配列 |
| `effect` | `none`・`reboot`・`signin`。変更が効くために必須の操作 |
| `risk` | `level`（`normal`・`high`）、日本語の `warning`、`default: false`。危険な項は `high` と実行前に読む短い警告を持つ |
| `inputs[]` | 名前付きの入力の定義。入力が無ければ空の配列 |
| `open` | 案内の項が開く URI。`ms-settings:` だけを許す。使わない項では省く |
| `doc` | `file`（リポジトリからの相対パス）・`heading`（見出しの文字）・`steps`（手順番号の配列） |
| `timeoutSec` | 実行時間の上限（秒） |
| `checkCost` | `fast`・`slow`。時間やネットワークを使う読み取りは `slow` にし、まとめて状態を確かめるときは明示的に選ばれた場合だけ流す |

`inputs[]` の各要素は `name`・`label`・`type`・`required`・`pattern`・`notPattern`・`profile` を持つ。正規表現が要らない項目では `pattern`・`notPattern` を省く。

- `name` は PowerShell の名前付きの引数と同じ名前にする
- `type` は `string`・`enum`・`bool`・`pubkeys`・`text`。秘密の型は作らない
- `required` は必須かどうかの真偽値。空白だけの必須入力も空として扱う
- `pattern` に一致し、`notPattern` に一致しない値を受け付ける。正規表現は .NET と RE2 の共通部分だけにし、先読み・後読みを使わない
- `profile` は入力を保存するときの扱い。`shared`（ほかの PC と共通）・`per-machine`（PC ごとに見直す）・`never`（保存しない）

## 読み取りと変更

- `check.ps1` は入力が無くても動く。入力なしで決まる項は 0 か 10 を返す。入力と比べる項は、入力が無ければ今の値を表示して 14、入力があれば比べて 0・10（変更が再起動待ちなら 11）を返す
- `apply.ps1` は変更前の値を読み、変える値を示してから変更する。最後に check と同じ読み取りと判定で確かめる。再実行しても、完了した設定や印付きの行を重ねない
- 入力は `item.json` の `inputs[].name` と同じ名前付きの引数で受ける。必須入力が空なら `中断:` を出して 2 で止まる。Git Bash は `SETUP_IN_<NAME>` で受ける
- `Test-SetupInput` は `required`・`pattern`・`notPattern` を検査する。check からの `-AllowMissing` は入力なしだけを許し、渡された不正な値は許さない
- 日本語のコマンド出力は解析せず、レジストリや CIM の値を使う。値が無いことと、読み取る権限が無いことを混同しない
- check の `-PassThru` は、apply が同じ読み取りと判定を使うための内部用の引数。結果のハッシュテーブルを返し、表示・JSON の出力・終了は行わない
- 既存の別言語のスクリプトを使うときは `apply.ps1` で包む。既存の `--check` の終了コードが 0（適用済み）・1（未適用）なら、この決まりの 0・10 に読み替える

## 表示と結果

人が読む出力は日本語の行にする。

| 接頭辞 | 内容 |
| --- | --- |
| `今:` | 読み取った今の値 |
| `変える:` | 変更先の値 |
| `変えた:` | 読み戻して確かめた変更 |
| `そのまま:` | 変更せずに済んだ値 |
| `控える:` | 変更前の値や、後の操作に使う秘密でない値。ファイルに控えたとは限らない |
| `状態:` | 最終の判定 |
| `中断:` | 失敗・入力の誤り・前提が足りず進めない理由 |

apply は、変える前に `今:` と `変える:` を出す。`Complete-SetupItem` は、`Changed` か `Unchanged` があるときは `今:`・`変える:` を表示せず（JSON には残す）、`変えた:`・`そのまま:`・`控える:`・`状態:` だけを出す。

終了コードと JSON は、ほかのスクリプトや、まとめて状態を確かめる項から読むために使う。表示の日本語を解析しない。

| 終了コード | `state` | `状態:` の表示 |
| --- | --- | --- |
| 0 | `confirmed` | 確認済み |
| 10 | `change-needed` | 変更が要る |
| 11 | `reboot-pending` | 再起動待ち |
| 12 | `manual-pending` | 手作業待ち |
| 13 | `not-applicable` | 前提が足りない・対象外 |
| 14 | `current-only` | 今の値だけ（比べる値が無い） |
| 1 | `failed` | 失敗 |
| 2 | `invalid-input` | 引数の誤り |

`Complete-SetupItem` に、項の定義と `State`・`Current`・`Desired`・`Changed`・`Unchanged`・`Keep`・`Message` を渡す。この関数が同じデータから表示・JSON・終了コードを作り、終了コードを返す。関数自身では終了せず、スクリプトの最後を `exit (Complete-SetupItem -Item $item @result)` にする。

環境変数 `SETUP_ITEM_RESULT` があれば、その絶対パスへ UTF-8（BOM 無し）の JSON を書く。親ディレクトリは呼び出し元が作り、書き込み先を項ごとに分ける。指定が無ければ JSON は書かない。`scripts/` の中は書き込み先にできない。結果を書けなければ `中断:` と失敗の `状態:` を出して 1 を返す。

| JSON の項目 | 内容 |
| --- | --- |
| `schemaVersion` | 1 |
| `id` | 項の ID |
| `state`・`exitCode` | 表の状態と終了コード |
| `current`・`desired`・`changed`・`unchanged`・`keep` | 名前と値のオブジェクト。値が未設定なら `null`、項目が無ければ空のオブジェクト |
| `message` | 判定の補足。無ければ空文字列 |

## 文字コードと禁止すること

- `.ps1`・`.psm1` は BOM 付き UTF-8・CRLF にする。Windows PowerShell 5.1 でも日本語を読めるようにする
- `.sh` は UTF-8・LF、JSON は BOM 無し UTF-8・LF にする。改行はルートの `.gitattributes` で決める
- 秘密を引数・出力・結果・ファイルに出さない。`$PSScriptRoot` と配布した `scripts/` の中には書き込まない
- check は設定・プロファイル・ファイルを変えない。明示された `SETUP_ITEM_RESULT` への結果の出力だけは行う
- `auto` と check は対話で止まらない。対話が要る操作は `terminal` にする。画面を開いて戻るだけの `guide` は、手作業待ちを返す
- 開発の PC で apply と check を実行しない。構文は両方の PowerShell の `Parser.ParseFile` で調べ、設定の変更と読み戻しは検証用の PC で確かめる
