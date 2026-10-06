# Claude Code 最新版インストール手順（AlmaLinux 10 は公式 dnf リポジトリ / Windows 11 は公式の native installer）の検証記録

[手順書](../claude-code.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> この実施手順（AlmaLinux 10）の既定の `latest` チャンネルは **x86_64 のクリーン VM とコンテナで検証した**（VM は 2026-10-06、認証前まで）。実機（aarch64）で本実行したのは `stable` チャンネル（[対象と検証環境](#対象と検証環境)）。

### 実施手順 / 手順 2: 補足: チャンネルは baseurl で決まる

この手順のヒアドキュメントだけ `<<EOF`（クォート無し）にしてある。`${CC_CHANNEL}` を展開して `baseurl` に埋めるため。

公式ドキュメントの dnf 向けの例と同じ形。既定の `latest` のまま貼ると、次のファイルになる（2026-09-26、コンテナ）:

```
[claude-code]
name=Claude Code
baseurl=https://downloads.claude.ai/claude-code/rpm/latest
enabled=1
gpgcheck=1
gpgkey=https://downloads.claude.ai/keys/claude-code.asc
```

実機に置いてあるのは `stable` を選んだファイルで、違いは `baseurl` の末尾（`.../rpm/stable`）だけ。

`repo_gpgcheck` は書かない（既定の 0）。パッケージ自体の署名は `gpgcheck=1` で検証される。署名鍵はどちらのチャンネルも同じ（手順 3 の補足）。

### 実施手順 / 手順 3: 補足: 鍵の取り込み

`dnf install` の途中で、トランザクション表の `[y/N]` の後に鍵の取り込みを聞かれる。実測（x86_64 のコンテナ、`latest`、2026-09-26）:

```
Installing:
 claude-code         x86_64         2.1.283-1         claude-code         104 M
...
Total download size: 104 M
Installed size: 230 M
Is this ok [y/N]: y
Downloading Packages:
claude-code-2.1.283-1.x86_64.rpm                 67 MB/s | 104 MB     00:01
...
Importing GPG key 0x1A7ECACE:
 Userid     : "Anthropic Claude Code Release Signing <security@anthropic.com>"
 Fingerprint: 31DD DE24 DDFA B679 F42D 7BD2 BAA9 29FF 1A7E CACE
 From       : https://downloads.claude.ai/keys/claude-code.asc
Is this ok [y/N]: y
Key imported successfully
...
Complete!
```

2026-09-22 に `stable`（aarch64、`2.1.267-1`）で入れたときも同じ fingerprint だった。この fingerprint は公式ドキュメントに載っているものと一致する。同じ鍵が apt / apk のリポジトリとリリースの `manifest.json` の署名にも使われている。

依存は `glibc >= 2.17` だけ（`rpm -q --requires claude-code`）なので、デスクトップ系のパッケージは一切付いてこない。

### 実施手順 / 手順 4: 補足: 最新版かどうかの確かめ方

- `--available` はリポジトリにある版だけを見る（入っている版は含めない）。リポジトリには古い版も残っているので、`--latest-limit 1` で一番新しいものだけに絞る
- 2026-09-26 の時点で、`latest` には 137 版、`stable` には 56 版が残っていた（x86_64 / aarch64 それぞれ）
- ネイティブインストーラが最新版として取りに行くのは `https://downloads.claude.ai/claude-code-releases/latest` が指す版で、2026-09-26 は RPM の `latest` と同じ `2.1.283` だった。RPM に届くのが遅れることはある（[注意点](../claude-code.md#注意点)）
- コンテナの dnf 4.20.0 では、`--qf` の末尾に `\n` を付けると結果の後に空行が 1 行増えた。本書の 2026-09-22 版はそう書いていたので外した

### 実施手順 / 手順 5: 補足: 認証

`claude` を引数無しで起動すると、ブラウザでのログインに進む。SSH 越しなど、そのホストでブラウザを開けない場合は、表示される URL を手元のブラウザで開いてコードを貼る形になる。**この手順はコンテナでは実行していない**（実機では認証済みで常用している）。

認証後の状態は `claude doctor` で確認できる（インストールの健全性、設定ファイルの検証エラー、更新の結果を表示する読み取り専用の診断）。認証後の出力は本書では未確認。

`claude doctor` は未認証でも動く。x86_64 のコンテナ（`latest`、2026-09-26）で手順 4 の直後に実行した出力の抜粋:

```
Claude Code doctor

Running: package-manager (2.1.283)
Platform: linux-x64
Package manager: rpm
Path: /usr/bin/claude
Search: OK (bundled)
Auto-updates: Managed by package manager
Auto-update channel: latest
...
No installation issues found.
```

ただし、これだけで `~/.claude/` と `~/.claude.json` ができる。

### 使い方の基本 / 手順 0: 本文中の記録

- 表のコマンドは、本書で実行して確かめた（[付録](#付録-使い方の基本の検証記録2026-10-01)）。確かめていないものは、表の見出しの括弧と、その行に書いた

### 使い方の基本 / 手順 0: 本文中の記録

- 確かめたのは Linux だけ。[Windows 11 で使う](../claude-code.md#windows-11-で使う)で入れた `claude` にも、同じコマンドを Windows PowerShell で打つ（公式の CLI reference は OS で分けていない）が、Windows では確かめていない

### 使い方の基本 / 手順 0: 本文中の記録

**起動と再開**（`-c`・`-r`・`-n`・`--model`・`--permission-mode`・`--add-dir` は `-p` と組み合わせて確かめた。`-r` の一覧から選ぶ画面と `claude "<最初の指示>"` は確かめていない）

### 使い方の基本 / 手順 0: 本文中の記録

- ログインとログアウトは、セッションの中の `/login`・`/logout` か、`claude auth login`・`claude auth logout`（本書では試していない）

### stable チャンネルに切り替える（任意） / 手順 1: 補足: キャッシュ

dnf 4.20.0 のキャッシュは `/var/cache/dnf/claude-code-<16 桁の 16 進数>` のディレクトリに置かれる。実測では、`baseurl` を書き換えた直後の dnf が `stable` のメタデータ（10 kB）を取りに行き、このディレクトリが 2 つ（チャンネルごと）になった。前のチャンネルのメタデータは使われなかった。

### stable チャンネルに切り替える（任意） / 手順 2: 本文中の記録

   - トランザクション表が `Downgrading:` で、版が `stable` の最新（2026-09-26 は `2.1.274-1`）になっていることを確かめて `y` と答える

### stable チャンネルに切り替える（任意） / 手順 2: 補足: distro-sync の表示

実測（2026-09-26、`2.1.283-1` から）:

```
Claude Code                                      37 kB/s |  10 kB     00:00
...
Downgrading:
 claude-code         x86_64         2.1.274-1         claude-code          98 M

Transaction Summary
================================================================================
Downgrade  1 Package

Total download size: 98 M
Is this ok [y/N]: y
...
Downgraded:
  claude-code-2.1.274-1.x86_64

Complete!
```

### ロールバック / 手順 0: 本文中の記録

- ロールバックは **x86_64 のコンテナでだけ本実行した**（実機では未実行）

### Windows 11 で使う / 手順 0: 本文中の記録

- 手順の後: `claude` のコマンドラインは[使い方の基本](../claude-code.md#使い方の基本)（確かめたのは Linux だけ）。SSH でログインして Remote Control を使い続けるなら [windows-claude-remote-control.md](../windows-claude-remote-control.md)。以後は[Windows 11 の更新](../claude-code.md#windows-11-の更新)・[Windows 11 のロールバック](../claude-code.md#windows-11-のロールバック)

### Windows 11 で使う: 検証状況の記録

> [!WARNING]
> **この節と、後ろの Windows 11 の 2 節は、Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、公式の文書、インストーラ（`install.ps1`）と Windows の `claude.exe`（2.1.288）の中身と署名、Linux の PowerShell 7 での構文と模擬の実行、Linux の同じ版の native installer の動きだけ（[対象と検証環境](#対象と検証環境)）。

### Windows 11 で使う / 手順 2: 補足: チャンネルの決まり方と、後から変える方法

- この節の手順 4 のインストーラは、Claude Code の `claude install <チャンネル>` を動かす。`claude install` は、選んだチャンネルを自分のユーザーの設定（`%USERPROFILE%\.claude\settings.json`）の `autoUpdatesChannel` に書き、以後の自動の更新と `claude update` はそのチャンネルを追う（公式の文書の Install a specific version と Configure release channel。書かれることは Linux の native installer の 2.1.288 で確かめた）
- 入れた後でチャンネルを変えるときは、`claude install stable`（戻すときは `claude install latest`）を打つ。Linux の 2.1.288 では、`latest` の 2.1.288 から `stable` の 2.1.285 に下がり、`autoUpdatesChannel` も `stable` になった（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）
- セッションの中の `/config` の Auto-update channel でも変えられる（公式の文書。`stable` へ移るときは、今の版に留まるか、下げるかを聞かれる）
- [実施手順](../claude-code.md#実施手順)（AlmaLinux 10）の dnf の版では、チャンネルは repo ファイルの `baseurl` で決まり、`autoUpdatesChannel` は効かない

### Windows 11 で使う / 手順 4: 補足: インストーラがすることと、irm | iex にしない理由

`https://claude.ai/install.ps1` は `https://downloads.claude.ai/claude-code-releases/bootstrap.ps1` へ飛ぶ。2026-10-03 に読んだ中身（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）:

- `claude-code-releases/latest` から一番新しい版の番号を取り、その版の `manifest.json` の `win32-x64`（arm64 の Windows なら `win32-arm64`）の sha256 と照らして、`claude.exe` を `%USERPROFILE%\.claude\downloads` に落とす。合わなければ `Checksum verification failed` で止まる
- 落とした `claude.exe` で `claude install <チャンネル>` を動かし、終わったら落としたファイルを消す。`claude install` が、選んだチャンネルの版を `%USERPROFILE%\.local\share\claude\versions` に置き、`%USERPROFILE%\.local\bin\claude.exe` を作る
- **インストーラは、`manifest.json` の GPG の署名も、`claude.exe` の Authenticode の署名も確かめない**（sha256 の照合だけで、`manifest.json` も同じ HTTPS のサーバーから取る）。署名はこの節の手順 7 で確かめる
- `PATH` は変えない。`claude install` は、`PATH` に無ければ足し方を出すだけ（Windows の `claude.exe` の 2.1.288 の中に、`PATH` を書く処理の文字列は見当たらなかった）

**公式の文書の既定の形 `irm https://claude.ai/install.ps1 | iex` にしない理由**:

- `Invoke-Expression` はスクリプトを今のスコープで動かすので、スクリプトの先頭の `Set-StrictMode -Version Latest`・`$ErrorActionPreference = "Stop"`・`$ProgressPreference = 'SilentlyContinue'` が、入れた後の PowerShell にも残る（Linux の PowerShell 7.6.6 で確かめた。付録）。残ると、後から貼ったブロックで、未定義の変数がエラーになり、どのエラーでも止まるようになる
- この手順の形（`& ([scriptblock]::Create(...)) <チャンネル>`）は、公式の文書がチャンネルを選ぶときに使う形で、別のスコープで動くので何も残らない。`irm` は `Invoke-RestMethod` の別名

### Windows 11 で使う / 手順 7: 補足: 署名と doctor の出力

- 公式の文書（Binary integrity and code signing）は、Windows の `claude.exe` は「Anthropic, PBC」が署名し、`Get-AuthenticodeSignature` で確かめられるとしている
- 2.1.288 の Windows の `claude.exe`（x64）の署名を Linux で読むと、署名者は DigiCert の Code Signing の CA が出した `CN="Anthropic, PBC"`（証明書の期限は 2026-10-20）で、DigiCert のタイムスタンプ（2026-10-02）が付いていた（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）。タイムスタンプがあるので、証明書の期限が切れた後も `Valid` のままのはず
- `claude doctor` の行は、Linux の native installer の 2.1.288 の出力（同じ付録）から引いた。Windows では `Platform: win32-x64` になるはず（確かめていない）
- 自動の更新は、Claude Code を起動したときと動いている間に確かめ、裏で入れて、次の起動から新しい版になる（公式の文書）。`claude doctor` の `Last update attempt` に最後の結果が出る

### Windows 11 の更新 / 手順 1: 補足: 更新の動き

- 出力の文言は公式の文書（Update manually）から。Linux の native installer の 2.1.288 では、`Current version: 2.1.288`・`Checking for updates to latest version...`・`Claude Code is up to date (2.1.288)` と出た（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）
- Windows では、動いている `claude.exe` を同じフォルダーの `claude.exe.old.<数字>` に名前を変えてから、新しい版を置く（公式の Troubleshoot installation）
- 新しい版は `%USERPROFILE%\.local\share\claude\versions` に置かれる。古い版は、使っているものと新しい 2 つを残して消される（公式の文書の Install on network storage）
- [windows-claude-remote-control.md](../windows-claude-remote-control.md) の実機では、検証の間に、自動の更新で 2.1.283 から 2.1.286 に上がった

### 対象と検証環境

- **目的**: AlmaLinux 10 と Windows 11 に [Claude Code](https://code.claude.com/docs/) の CLI の最新版を入れる
  - AlmaLinux 10 では **dnf 管理で**入れ、`dnf upgrade` で追従できるようにする
  - Windows 11 では公式の native installer で入れ、Claude Code 自身の自動の更新に任せる
- **進め方**: どちらも Anthropic の公式の配布物を使い、npm も Node.js も使わない。**読者が書き換えるのは変数（チャンネル）だけ**で、既定のままで通る
  - **AlmaLinux 10**（[実施手順](../claude-code.md#実施手順)）: 公式の RPM リポジトリの `latest` チャンネルを 1 つ足して `dnf install` する
  - **Windows 11**（[Windows 11 で使う](../claude-code.md#windows-11-で使う)）: 管理者ではない Windows PowerShell 5.1 で公式の `install.ps1` を動かし、`%USERPROFILE%\.local\bin\claude.exe` に入れる。`PATH` は本書で足し、署名を確かめてから、ブラウザでログインする
- **状態（AlmaLinux 10）**: **実機で本実行済み（`stable`、2026-09-20）**。既定の `latest` は x86_64 のクリーン VM（2026-10-06、認証前まで）とコンテナ（2026-09-26）で検証
  - 実機（aarch64）: `stable` チャンネルの repo ファイルを置いて `dnf install claude-code` し、`claude-code-2.1.267-1.aarch64` が入っている。認証も済んでいて常用中（本書の初版は、そのホストの Claude Code で書いた）
  - 2026-09-22: 同じ OS の aarch64 のコンテナで、`stable` の手順 2〜4 を通し直した
  - 2026-09-26: 既定を `latest` に変え、x86_64 のコンテナで手順 1〜4・[更新](../claude-code.md#更新)・[stable チャンネルに切り替える（任意）](../claude-code.md#stable-チャンネルに切り替える任意)・[ロールバック](../claude-code.md#ロールバック)を、この文書のコードブロックのまま通した（`claude-code-2.1.283-1.x86_64`）
  - **確認していないこと**: 実機（aarch64）での `latest`（aarch64 にも同じ版があることはメタデータで確認）、コンテナでの認証（手順 5）、認証後の `claude doctor`
  - 2026-09-28: 手順 2 と、[stable チャンネルに切り替える（任意）](../claude-code.md#stable-チャンネルに切り替える任意)の手順 1・4のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../../README.md#記法)）
    - 中のコマンドは変えていない。囲んだ形は構文の検査だけで、流していない
  - 2026-10-01: [使い方の基本](../claude-code.md#使い方の基本)を足した（[付録](#付録-使い方の基本の検証記録2026-10-01)）
    - ログインの要るもの（`-p`・`-c`・`-r`・`-n`・`--model`・`--permission-mode`・`--add-dir`・`--allowedTools`・`--max-turns`・`--output-format json`）は、クラウドのホスト（Ubuntu 24.04）にあったログイン済みの Claude Code 2.1.287 で確かめた
    - ログインの要らないもの（`doctor`・`auth status`・`mcp`・`update`、ログインしていないときの `-p` と `remote-control`）は、x86_64 の AlmaLinux 10 のコンテナに手順 2〜4 で入れた `claude-code-2.1.287-1` で確かめた
    - **確認していないこと**: セッションの中の操作（キーとスラッシュコマンド）、`-r` の一覧から選ぶ画面、`claude auth login` / `logout`、`claude remote-control` の接続
  - 2026-10-02: 手順 2 の `{ … }` を、`CC_CHANNEL` が空なら何もせずに止める `if … fi` にした（中のコマンドは変えていない）
    - それまでは、ヒアドキュメントの中の `${CC_CHANNEL:?…}` が `sudo tee` しか止めず（[gnome-power.md 手順 3](../gnome-power.md#実施手順) の補足）、repo ファイルは書かれずに、後ろの `cat` が `No such file or directory` を出した
    - 直した形は、擬似端末の対話の bash にブラケットペースト無しで、変数を空にしたときと値を入れたときの 1 回ずつ貼って確かめた（`sudo` はそのまま実行するスタブ、`/etc` は使い捨てのディレクトリに読み替えた）
- **状態（Windows 11）**: **Windows の実機では流していない（未検証。2026-10-03 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）:
    - 公式の文書: Windows の要件（Git for Windows は任意、管理者の権限は要らない）、置き場所、チャンネル、更新、アンインストール、`PATH` の足し方、署名
    - インストーラ: `install.ps1`（`bootstrap.ps1`）の中身。sha256 は照らすが、署名は確かめず、`PATH` も変えない
    - 配布物: 2.1.288 の `manifest.json` の GPG の署名、Windows の `claude.exe`（x64）の sha256 と Authenticode の署名者・タイムスタンプ（Linux で読んだだけ）、`claude.exe` の中の文字列（`PATH` の案内、置き場所、更新のときの名前の変え方）
    - Linux の native installer の同じ版（2.1.288）: `claude install latest` / `stable` で書かれる設定と置き場所、`claude doctor`・`claude update` の出力
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査。[Windows 11 で使う](../claude-code.md#windows-11-で使う)の手順 4 は、本物の `install.ps1` を Linux の pwsh で動かし、`claude.exe` を落として sha256 が合うところまで通した（Windows の実行ファイルを動かすところで止まる）。同じ節の手順 5 と[Windows 11 のロールバック](../claude-code.md#windows-11-のロールバック)の手順 2〜4 は、自分のユーザーの PATH とフォルダーを偽物にして流した（[付録](#付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
  - 別の手順書の実機（[windows-claude-remote-control.md](../windows-claude-remote-control.md) の Windows 11 Pro 26H2）には、native installer の 2.1.286 が `C:\Users\<WIN_USER>\.local\bin\claude.exe` に入っていて、claude.ai にログインしてあった（2026-10-01。この節の手順で入れたものではない）
  - **確かめていないこと**: Windows で貼ること（すべての手順）、`claude install` が Windows で出す文言と `PATH` の案内、`PATH` を足して開き直した PowerShell で `claude` が動くこと、`Get-AuthenticodeSignature` の結果、ブラウザでのログイン、`claude update`、ロールバック、arm64 の Windows、Git for Windows が無いとき

AlmaLinux 10:

| 項目 | 実機 | 検証コンテナ（`stable`） | 検証コンテナ（`latest`） |
|---|---|---|---|
| 実施日 | 2026-09-20 | 2026-09-22 | 2026-09-26 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/almalinux:10`、Docker 29.3.1 / 非特権） |
| カーネル | 6.12.96 | ホストと同じ | クラウドのホストのもの（6.18 系。AlmaLinux のカーネルではない） |
| dnf | 4.20.0 | 4.20.0 | 4.20.0 |
| チャンネル | `stable` | `stable` | `latest`（切り替えの節で `stable` も） |
| 入った Claude Code | `claude-code-2.1.267-1.aarch64`（93 MB / 展開後 207 MB） | 同じ（`2.1.267-1`） | `claude-code-2.1.283-1.x86_64`（104 MB / 展開後 230 MB） |
| Node.js | 未導入（`node` / `npm` 無し。dnf 版は不要） | 未導入 | 未導入 |
| 認証 | 済み（常用中） | 未実施 | 未実施 |

Windows 11（前提にしている環境。ほかの Windows の手順書の実機の記録と同じ PC を想定）:

| 項目 | 値 |
|---|---|
| OS | Windows 11（[Windows の OpenSSH サーバー](../windows-openssh-server.md)の PC は 25H2）。x64 |
| PowerShell | Windows PowerShell 5.1（管理者でなくてよい） |
| Git for Windows | [git.md](../git.md#windows-11-で-git-for-windows-を入れる)で入れたもの（`C:\Program Files\Git`） |
| 既定のブラウザ | Firefox（[firefox.md](../firefox.md#windows-11-で使う)） |
| Claude Code | 2.1.288（2026-10-02、`latest`。`stable` は 2.1.285） |

> [!NOTE]
> 環境固有の値は**変数**で書いてある。AlmaLinux 10 は[手順 1](../claude-code.md#実施手順)のシェル変数、Windows 11 は[Windows 11 で使う](../claude-code.md#windows-11-で使う)の手順 2 の PowerShell の変数に 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${CC_CHANNEL}` | 追従するチャンネル。`baseurl` の末尾になる | `latest` / `stable` |
> | `$CC_CHANNEL` | Windows 11 で追従するチャンネル。インストーラに渡し、設定の `autoUpdatesChannel` になる | `latest` / `stable` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` / `<WIN_USER>`（Windows のユーザー名）のプレースホルダで書いてある。バージョン（`2.1.283` など）は実行日によって変わる。`<作業したいディレクトリ>` のような `<...>` を含むコマンドは、bash と PowerShell のコードブロックに置いていない。
>
> **API キー・OAuth トークン・認証時のコードは書かない。** 鍵の fingerprint は公開情報なので本文に書いてある。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

AlmaLinux 10 の実機（2026-09-20）の状態。検証コンテナは公式イメージのまま（Claude Code も追加のリポジトリも無し）。Windows 11 の PC は、[Windows 11 で使う](../claude-code.md#windows-11-で使う)の手順 3 で確かめる。

| 項目 | 状態 |
|---|---|
| Claude Code | 未導入（`claude` 無し、`~/.claude` も無し） |
| Node.js / npm | 未導入。`nodejs` は appstream に 22.23.2 があるが入れていない |
| 有効な追加リポジトリ | epel、crb、raspberrypi、gh-cli（claude-code はまだ無し） |
| `~/.local/bin` | PATH には入っているがディレクトリは未作成 |

### 選択した方針

Linux に Claude Code を入れる経路は 3 つある（2026-09-22 時点の[公式ドキュメント](https://code.claude.com/docs/en/setup)）:

2026-09-26 に見た各チャンネルの最新版（x86_64 / aarch64 とも同じ）:

Windows 11 で Claude Code を入れる経路を比べた（2026-10-03 時点。中身はどれも公式の `claude.exe`）:

| 経路 | 状況 | 採否 |
|---|---|---|
| **公式の native installer（PowerShell の `install.ps1`）** | `%USERPROFILE%\.local\bin\claude.exe` に入り、管理者の権限は要らない。Claude Code 自身が裏で更新する（チャンネルは `latest` / `stable`）。sha256 は照らすが署名は確かめず、`PATH` も足さない | **採用**（公式が勧める形。[windows-claude-remote-control.md](../windows-claude-remote-control.md) の前提もこの形） |
| 公式の native installer（CMD の `install.cmd`） | 同じものを CMD から入れる | 不採用（本書のブロックは Windows PowerShell にそろえる） |
| WinGet の `Anthropic.ClaudeCode` | `portable` で、公式の配布物の `claude.exe` をそのまま置く。自分では更新しない（`winget upgrade`。`CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE=1` で Claude Code に走らせられるが、動いている間は置き換えられないことがある）。2026-10-03 の winget-pkgs は 2.1.286 で、`latest` の 2.1.288 より遅れていた | 不採用（版が遅れ、更新を別に回すことになる） |
| scoop の `main/claude-code` | 2.1.288（公式の配布物と同じ sha256）。更新は `scoop update` | 不採用（公式の文書の経路ではなく、Claude Code 自身の更新との関係を確かめていない） |
| Chocolatey の `claude-code` | 2.1.285（コミュニティの保守） | 不採用 |
| npm（`@anthropic-ai/claude-code`） | Node.js が要る。PowerShell の実行ポリシーが、npm の作る `.ps1` の起動を止めることがある（公式の Troubleshoot installation） | 不採用 |
| WSL の中に Linux の手順で入れる | Linux の道具を使うなら有力（サンドボックスは WSL 2 だけ）。Windows の `claude.exe` とは別のもの | 不採用（Windows のプロジェクトで使い、[windows-claude-remote-control.md](../windows-claude-remote-control.md) の前提にもなるため） |

| npm（`npm install -g @anthropic-ai/claude-code`） | Node.js 22 以上が要る。このホストに Node.js は無く、そのために入れることになる。中身は同じネイティブバイナリ | 不採用 |

- ネイティブインストーラ（`install.sh` が取ってくる `bootstrap.sh`）も、まず `claude-code-releases/latest` が指す版を取ってくる（スクリプトを読んで確認。実行はしていない）

| 配布元 | `stable` | `latest` |
|---|---|---|
| RPM リポジトリ（`rpm/<チャンネル>` の repodata） | `2.1.274-1` | `2.1.283-1` |
| リリースのポインタ（`claude-code-releases/<チャンネル>`） | `2.1.274` | `2.1.283` |

### 完了時点の状態

Windows 11 は流していないので、記録は無い。

AlmaLinux 10 の実機（`stable`、2026-09-20）:

```
$ dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' claude-code
claude-code 2.1.267-1 claude-code
$ claude --version
2.1.267 (Claude Code)
$ rpm -ql claude-code
/usr/bin/claude
/usr/share/doc/claude-code/copyright
$ rpm -q --requires claude-code
glibc >= 2.17
$ rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i anthropic
gpg-pubkey-1a7ecace-69caef70 Anthropic Claude Code Release Signing <security@anthropic.com> public key
```

x86_64 のコンテナ（`latest`、2026-09-26。最初の 4 つが手順 4 のコマンド）:

```
$ dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}' claude-code
claude-code 2.1.283-1 claude-code
$ dnf -q repoquery --available --latest-limit 1 --qf '%{name} %{version}-%{release} %{reponame}' claude-code
claude-code 2.1.283-1 claude-code
$ claude --version
2.1.283 (Claude Code)
$ rpm -ql claude-code
/usr/bin/claude
/usr/share/doc/claude-code/copyright
$ rpm -q --requires claude-code
glibc >= 2.17
$ rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i anthropic
gpg-pubkey-1a7ecace-69caef70 Anthropic Claude Code Release Signing <security@anthropic.com> public key
```

- 認証すると `~/.claude/`（設定・セッション履歴）と `~/.claude.json` ができる
- プロジェクト側の設定は `.claude/` と `.mcp.json`

### 付録: コンテナでの検証記録（2026-09-22）

`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで手順 2〜4 を通した。実機で加えた変更は `dnf install podman` だけ。 最後にもう 1 つ新しいコンテナを立て、**この文書のコードブロックをそのまま抜き出したスクリプト**（`sudo` を外し、`dnf install` / `dnf upgrade` に `-y` を付けただけ）を流して、上から順に貼れば通ることを確かめている。

| 手順 | 結果 |
|---|---|
| 2. repo | `tee` で作成。`dnf` がメタデータ（9.8 kB）を取得できた |
| 3. install | `dnf install --assumeno claude-code` → `Installing: claude-code aarch64 2.1.267-1 claude-code 93 M / Installed size: 207 M`、依存パッケージ無し。本実行では鍵の fingerprint `31DD DE24 ... 1A7E CACE` が表示され `Key imported successfully` |
| 4. 検証 | `claude --version` → `2.1.267 (Claude Code)`。`rpm -ql` は `/usr/bin/claude` と copyright の 2 ファイル |

実機（2026-09-20 に `stable` チャンネルで導入）と同じ `2.1.267-1` が入った。

#### 未確認事項

- 手順 5 の認証（コンテナでは未実施。実機では 2026-09-20 に実行して以後常用）
- `latest` チャンネルの動作と、`stable` との切り替え（`baseurl` を書き換えたときの `dnf upgrade` / `distro-sync` の挙動）
- `claude doctor` の出力
- ロールバック（`dnf remove` と鍵の削除）の本実行
- ネイティブインストーラ版・npm 版との併存時の優先順位（`~/.local/bin/claude` が PATH の先にある場合）

### 付録: latest チャンネルの検証記録（2026-09-26）

**環境**: Ubuntu 24.04 / x86_64 のクラウドホスト上の Docker 29.3.1（cgroup v1）で、`quay.io/almalinuxorg/almalinux:10`（`sha256:8322019282c6f7d253888ec688d6b90675963f31c4692709177e25eb9301c4c8`、AlmaLinux 10.2）を**非特権**・`--network host` で立て、非 root ユーザー（NOPASSWD の sudo）で実行した。実機で加えた変更は無い。

**検証の準備**（本書の手順には含めない）:

- このホストの外向きの HTTPS はプロキシを通るので、プロキシの CA を `/etc/pki/ca-trust/source/anchors/` に置いて `update-ca-trust` し、`/etc/dnf/dnf.conf` に `proxy=` を書いた
- AlmaLinux の mirrorlist が `http://` のミラーを返し、プロキシが CONNECT 以外の要求を 405 で断ったので、`almalinux-*.repo` の `mirrorlist=` を止めて、コメントになっていた `baseurl=https://repo.almalinux.org/...` を有効にした。claude-code のリポジトリは最初から https なので、この変更の影響を受けない
- `sudo` と `util-linux`（`script` のため）を dnf で入れた

**やり方**:

- 1 つ目のコンテナで、`-y` 付きの dnf で同じ操作を試して挙動を確かめた
- 新しいコンテナで、この文書の折り畳みの外にある bash のコードブロック 12 個（手順 1〜4、[更新](../claude-code.md#更新)の手順 1、[stable チャンネルに切り替える（任意）](../claude-code.md#stable-チャンネルに切り替える任意)の手順 1〜4、[ロールバック](../claude-code.md#ロールバック)の手順 1〜3）を、上から順にそのまま抜き出したスクリプトを流した
- `sudo` も `-y` 無しの dnf もそのまま。全体を `script` で作った pty の中で流し、6 秒おきに `y` を送った。全体で 42 秒
- ブロックの間に確認のコマンドを挟んだ（下表の「追加」）

| 手順 | 結果 |
|---|---|
| 1. 変数 | `CC_CHANNEL = latest` |
| 2. repo | `baseurl=https://downloads.claude.ai/claude-code/rpm/latest`。dnf がメタデータ（23 kB）を取得した |
| 3. install | `Installing: claude-code x86_64 2.1.283-1 claude-code 104 M / Installed size: 230 M`、依存パッケージ無し。`[y/N]` はトランザクションと鍵の 2 回。fingerprint `31DD DE24 ... 1A7E CACE` が表示され `Key imported successfully` |
| 4. 確認 | repoquery の 2 行がどちらも `claude-code 2.1.283-1 claude-code`。`claude --version` → `2.1.283 (Claude Code)`。`rpm -ql` は `/usr/bin/claude` と copyright の 2 ファイル |
| 追加: `claude doctor` | 未認証のまま実行して終了コード 0。`Package manager: rpm`、`Auto-updates: Managed by package manager`、`Auto-update channel: latest`、`No installation issues found.`。これだけで `~/.claude/` と `~/.claude.json` ができた |
| 更新 1 | `Nothing to do.`（入れた直後なので） |
| 切り替え 1 | `baseurl=https://downloads.claude.ai/claude-code/rpm/stable` |
| 切り替え 2 | `stable` のメタデータ（10 kB）を取得し、`Downgrading: claude-code x86_64 2.1.274-1 claude-code 98 M` → `Downgraded: claude-code-2.1.274-1.x86_64` |
| 切り替え 3 | repoquery の 2 行がどちらも `claude-code 2.1.274-1 claude-code`。`claude --version` → `2.1.274 (Claude Code)` |
| 追加: もう一度 `distro-sync` | `Nothing to do.`。`/var/cache/dnf/` の claude-code のキャッシュが、チャンネルごとに別のディレクトリ（2 つ）になっていた |
| 切り替え 4 | `baseurl` が `latest` に戻り、`Upgrading: claude-code x86_64 2.1.283-1` → `Upgraded: claude-code-2.1.283-1.x86_64` |
| ロールバック 1 | `Removing: claude-code x86_64 2.1.283-1 @claude-code 230 M` → `Removed: claude-code-2.1.283-1.x86_64` |
| 追加: `command -v claude` | 同じシェルでは `/usr/bin/claude` を返した（ファイルはもう無い）。`hash -r` の後は何も返さず終了コード 1 |
| ロールバック 2・3 | repo ファイルが消え、`rpm -e` は終了コード 0。gpg-pubkey は AlmaLinux の鍵だけに戻った。`~/.claude/` と `~/.claude.json` は残った |

1 つ目のコンテナでも同じ版（`2.1.283-1` → `2.1.274-1` → `2.1.283-1`）で、鍵の rpm 名も実機と同じ `gpg-pubkey-1a7ecace-69caef70` だった。

#### 残っている未確認事項

- 2026-09-22 の未確認事項のうち、`latest` の動作・`stable` との切り替え・未認証での `claude doctor`・ロールバックの本実行は、この検証で確かめた（x86_64 のコンテナ）
- 実機（aarch64）での `latest`。aarch64 の `latest` にも `2.1.283-1` があることは repodata で確かめた
- 手順 5 の認証と、認証後の `claude doctor`（コンテナでは未認証のまま）
- ネイティブインストーラ版・npm 版との併存時の優先順位（`~/.local/bin/claude` が PATH の先にある場合）

### 付録: 使い方の基本の検証記録（2026-10-01）

**ログインの要らないもの**: [tmux.md の付録](tmux.md#付録-コンテナでの検証記録2026-10-01)と同じ x86_64 の AlmaLinux 10 のコンテナ（`10-init`、systemd と sshd）に、手順 2〜4 の `latest` で `claude-code-2.1.287-1` を入れ、SSH でログインした一般ユーザー（ログインしていない）で実行した。

| コマンド | 結果 |
|---|---|
| `claude auth status --text` | `Not logged in. Run claude auth login to authenticate.`、終了コード 1。`--text` を外すと JSON（`"loggedIn": false`） |
| `claude doctor` | `Package manager: rpm`・`Auto-updates: Managed by package manager`・`No installation issues found.`。`Remote Control` の段に `Not signed in to claude.ai` など 5 行 |
| `claude update` | `Current version: 2.1.287` の後に `Claude is managed by a package manager.` と `Please use your package manager to update.`、終了コード 0 |
| `claude mcp add hello -- /usr/bin/echo hi` | `Added stdio MCP server hello with command: /usr/bin/echo hi to local config`、`File modified: ~/.claude.json [project: <PROJECT_DIR>]` |
| `claude mcp add -s user …` | `to user config`、`File modified: ~/.claude.json` |
| `claude mcp add --transport http -s project web https://mcp.example.invalid/mcp` | `.mcp.json` に `"type": "http"` と `url` が書かれた |
| `claude mcp list` / `get` | `✘ Failed to connect`（`echo` は MCP サーバーではないので）。`get` は `Scope: Local config (private to you in this project)` と、消すときの `claude mcp remove hello -s local` |
| `claude mcp remove …` | 3 つとも消え、`list` は `No MCP servers configured.` に戻った |
| `claude -p "hi"` | `Not logged in · Please run /login`、終了コード 1 |
| `claude remote-control --name proj --spawn same-dir` | `Error: You must be logged in to use Remote Control.`、終了コード 1。`claude remote-control --help` もログインしていないと同じエラーで、help は出なかった |
| `claude --name hup-test`（SSH のシェルで、tmux を使わずに起動） | SSH のクライアントを落とすと、`claude` のプロセスも消えた |
| `claude auth status --text` の後ろに `echo` の 2 行を続けて貼る（ブラケットペースト無し） | `echo` は 2 行とも実行されなかった。`claude --version` や `claude doctor \| head -3` の後ろの `echo` は実行された |

**ログインの要るもの**: クラウドのホスト（Ubuntu 24.04、x86_64）にあったログイン済みの Claude Code 2.1.287（`claude auth status --text` は `Login method: Claude API account`）で、空のディレクトリから実行した。その環境の Claude Code の環境変数を引き継がないように `env -i` で HOME・PATH・プロキシだけを渡した。

| コマンド | 結果 |
|---|---|
| `claude -p "1+1 の答えの数字だけを返して"` | `2` |
| `echo "hello tmux" \| claude -p "標準入力の文字列を大文字にして、それだけを返して"` | `HELLO TMUX` |
| `claude -p --output-format json "…" \| jq …` | `result` が `5`、`num_turns` が 1、`is_error` が false。キーは `result`・`session_id`・`total_cost_usd`・`permission_denials` など 25 個 |
| `claude -p -n tmux-test "合言葉は「りんご」です…"` → `claude -c -p "合言葉を答えて…"` → `claude -r tmux-test -p "…"` | `了解`、`りんご`、`りんご` |
| `claude -p "touch made.txt を実行して…"` | `承認が得られず、実行できませんでした。`、`permission_denials` に `Bash`。ファイルはできなかった |
| 同じ指示に `--allowedTools "Bash(touch *)"` | `成功しました。`、ファイルができた |
| `date +%Y` を実行させる指示（`--allowedTools` 無し） | 聞かずに動き、`2026` |
| 同じ指示に `--max-turns 1` | `subtype` が `error_max_turns`、`is_error` が true、終了コード 1 |
| `--model haiku` | `modelUsage` のキーが `claude-haiku-4-5-20251001` |
| `--permission-mode plan` で `touch` を実行させる指示 | プランモードのため実行しなかった、と答え、ファイルはできなかった |
| 作業ディレクトリの外のファイルを Read で読ませる指示 | `--add-dir` 無しでは `permission_denials` に `Read`。`--add-dir <そのディレクトリ>` 付きで中身（`banana`）を返した |

- 対話の `claude` は、ログインしていないコンテナではテーマを選ぶ最初の画面まで（tmux の中でも同じ）。ログイン済みのホストでも、`env -i` で起動すると最初の設定の画面からログインの方法を選ぶ画面に進んだので、そこで止めた（ログインはしていない）
- セッションの中のキーとスラッシュコマンドは、公式ドキュメントの Interactive mode と Commands の表から載せた

---

### 付録: Windows 11 の配布物と資料の調査（2026-10-03）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、インストーラと配布物と資料を読んだ記録。

#### インストーラ（`install.ps1`）

```
$ curl -sS -o /dev/null -w '%{http_code} %{redirect_url}\n' https://claude.ai/install.ps1
302 https://downloads.claude.ai/claude-code-releases/bootstrap.ps1
$ curl -sS -o install.ps1 -L https://claude.ai/install.ps1
$ sha256sum install.ps1
cd17c6b555f761d60373659824bf805e1510538226e4c7028e19d7494937a333  install.ps1
```

3,189 バイトの PowerShell。読んだ中身:

- `param` の位置引数 `$Target`（既定は `latest`。`^(stable|latest|\d+\.\d+\.\d+(-[^\s]+)?)$` に合わないと拒む）
- 先頭で `Set-StrictMode -Version Latest`・`$ErrorActionPreference = "Stop"`・`$ProgressPreference = 'SilentlyContinue'`
- `[Environment]::Is64BitProcess` が偽なら `Claude Code does not support 32-bit Windows. ...` で止まる
- `$env:PROCESSOR_ARCHITECTURE` が `ARM64` なら `win32-arm64`、ほかは `win32-x64`
- `https://downloads.claude.ai/claude-code-releases/latest` から版の番号を取り（`$Target` によらず一番新しい版。コメントは「最新のインストーラを持つため」）、`<版>/manifest.json` の `platforms.<プラットフォーム>.checksum` を読む
- `<版>/<プラットフォーム>/claude.exe` を `Invoke-WebRequest` で `%USERPROFILE%\.claude\downloads\claude-<版>-<プラットフォーム>.exe` に落とし、`Get-FileHash` の sha256 が合わなければ `Checksum verification failed` で消して止まる
- `Setting up Claude Code...` を出して `& $binaryPath install $Target` を動かし、`finally` で 1 秒待ってから落としたファイルを消す。終了コードが 0 でなければ `Installation failed (exit code <N>)`、0 なら `✅ Installation complete!`
- `manifest.json` の署名（`manifest.json.sig`）も、`claude.exe` の Authenticode の署名も、確かめる処理は無い。`PATH` にも触らない

#### リリースと `manifest.json`

```
$ for c in latest stable; do printf '%s: ' $c; curl -fsS https://downloads.claude.ai/claude-code-releases/$c; echo; done
latest: 2.1.288
stable: 2.1.285
```

2.1.288 の `manifest.json`（`buildDate` は 2026-10-02T17:00:28Z）の署名を、`https://downloads.claude.ai/keys/claude-code.asc` の鍵（fingerprint `31DD DE24 DDFA B679 F42D  7BD2 BAA9 29FF 1A7E CACE`。[実施手順](../claude-code.md#実施手順)の手順 3 の dnf の鍵と同じ）で確かめた（gpg 2.4.4）:

```
gpg:                using RSA key 31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE
gpg: Good signature from "Anthropic Claude Code Release Signing <security@anthropic.com>" [unknown]
```

Windows の行:

| プラットフォーム | sha256 | 大きさ |
|---|---|---|
| `win32-x64` | `84304f7d4b0cd0ebcbe8318695a260151b48991a6659c3366fdd5da290c0ab91` | 249,149,600 |
| `win32-arm64` | `5015d2b92866232b85384ac6e5eef4ff155418a92123503e52714c29186af8c6` | 236,673,184 |

`2.1.288/win32-x64/claude.exe` を取り、sha256 が `manifest.json` と一致した。

#### `claude.exe`（2.1.288、x64）の署名

osslsigncode 2.8 の `verify` の出力の抜粋（Windows の `Get-AuthenticodeSignature` は通していない）:

```
Signer's certificate:
	Signer #0:
		Subject: /jurisdictionC=US/jurisdictionST=Delaware/businessCategory=Private Organization/serialNumber=4860621/C=US/ST=California/L=San Francisco/O=Anthropic, PBC/CN=Anthropic, PBC
		Issuer : /C=US/O=DigiCert, Inc./CN=DigiCert Trusted G4 Code Signing RSA4096 SHA384 2021 CA1
		Certificate expiration date:
			notBefore : Oct 14 00:00:00 2025 GMT
			notAfter : Oct 20 23:59:59 2026 GMT
Countersignatures:
	Timestamp time: Oct  2 16:56:42 2026 GMT
	Issuer: /C=US/O=DigiCert, Inc./CN=DigiCert Trusted G4 TimeStamping RSA4096 SHA256 2025 CA1
...
Number of verified signatures: 1
Succeeded
```

- 署名の中の証明書を Linux の PowerShell 7.6.6 の `X509Certificate2` に読ませると、`Subject` は `CN="Anthropic, PBC", O="Anthropic, PBC", L=San Francisco, S=California, C=US, SERIALNUMBER=4860621, ...` だった（名前に `,` があるので引用符で囲まれる）。[Windows 11 で使う](../claude-code.md#windows-11-で使う)の手順 7 の箇条書きは、この形から引いた
- 公式の文書（Binary integrity and code signing）の「signed by "Anthropic, PBC"」と合う

#### `claude.exe` の中の文字列

`strings` で読んだ（Linux 版の 2.1.288 の実行ファイルにも同じ文字列がある）:

- Windows で `PATH` に無いときの案内: `Native installation exists but ${D} is not in your PATH. Add it by opening: System Properties → Environment Variables → Edit User PATH → New → Add the path above. Then restart your terminal.`（`${D}` は `claude.exe` のフォルダー）。`SetEnvironmentVariable`・`HKCU\Environment` のような、`PATH` を書く処理の文字列は無かった
- 置き場所: 版は `<XDG_DATA_HOME か ホーム\.local\share>\claude\versions`、更新の途中のファイルは `<XDG_CACHE_HOME か ホーム\.cache>\claude\staging`、ロックは `<XDG_STATE_HOME か ホーム\.local\state>\claude\locks`、実行ファイルは `ホーム\.local\bin\claude.exe`
- 更新のときに退ける名前は `<実行ファイル>.old.<ミリ秒>.<PID>`
- `claude install` は、`latest` / `stable` を渡されると、自分のユーザーの設定に `autoUpdatesChannel` を書く（`Install: Saved autoUpdatesChannel=...`）
- 更新のときに `manifest.json` の署名を確かめる処理の文言（`predates manifest signature enforcement` など）がある。どの条件で強制されるかは読んでいない

#### Linux の native installer の同じ版での動き

一時的な `HOME` で、Linux の 2.1.288 の実行ファイル（`manifest.json` の `linux-x64` と sha256 が一致）に `install latest` を動かした（`install.ps1` が Windows で動かすのと同じ `claude install`。標準入力無し・`TERM=dumb`。空行は詰めた）:

```
Checking installation status...
Installing Claude Code native build latest...
Setting up launcher and shell integration...
⚠ Setup notes:
  ● Native installation exists but ~/.local/bin is not in your PATH. Run:
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> your shell config file && source your shell config file
✔ Claude Code successfully installed!
  Version: 2.1.288
  Location: ~/.local/bin/claude
  Next: Run claude --help to get started
⚠ Setup notes:
  ● Native installation exists but ~/.local/bin is not in your PATH. Run:
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> your shell config file && source your shell config file
```

- `Setup notes:` は、成功の表示の前と後に 2 回出た
- できたもの: `~/.local/bin/claude`（`~/.local/share/claude/versions/2.1.288` へのリンク）、`~/.cache/claude/staging`、`~/.local/state/claude/locks`、`~/.claude/settings.json`（`{"autoUpdatesChannel": "latest"}`）、`~/.claude.json`。シェルの設定ファイルは変わらなかった
- `claude doctor`: `Running: native (2.1.288)`・`Config install method: native`・`Auto-updates: enabled`・`Auto-update channel: latest`・`Last update attempt: none recorded`・`No installation issues found.`
- `claude update`: `Current version: 2.1.288`・`Checking for updates to latest version...`・`Claude Code is up to date (2.1.288)`、終了コード 0
- 続けて `claude install stable`: `Installing Claude Code native build stable...`・`Version: 2.1.285`。`claude --version` は `2.1.285 (Claude Code)`、`autoUpdatesChannel` は `stable` になり、`versions` には 2.1.285 と 2.1.288 が残った

#### 公式の文書（2026-10-03）

- Advanced setup の Set up on Windows: native の Windows は Git for Windows が任意（Bash のツールと Monitor のツールに Git Bash が要る。無ければ PowerShell のツール）、管理者として動かさなくてよい
- 同じ文書: native installer は裏で自動で更新する。WinGet・Homebrew・apt・dnf・apk は自動では更新しない。`claude update` の出力は `Successfully updated from <古い版> to version <新しい版>` か `Claude Code is up to date (<版>)`。アンインストールの Windows PowerShell は `.local\bin\claude.exe` と `.local\share\claude`、設定は `.claude` と `.claude.json`
- Troubleshoot installation: PowerShell のインストーラが終わっても `claude` が見つからないときは、`[Environment]::SetEnvironmentVariable('PATH', "$currentPath;$env:USERPROFILE\.local\bin", 'User')` で足して端末を開き直す。更新の後に `claude.exe` が無いときは、`claude.exe.old.*` の一番新しいものの名前を戻す（v2.1.281 より前は、退けたファイルを消すことがあった）
- Authentication: Windows のログインの情報は `%USERPROFILE%\.claude\.credentials.json`

#### パッケージの定義（採らなかった経路）

- winget の `Anthropic.ClaudeCode`（winget-pkgs の 2026-10-03 の `master` を浅い sparse clone で見た）: 最新は 2.1.286（`ReleaseDate: 2026-09-30`）。`InstallerType: portable`、`Commands: claude`、x64 と arm64 の `InstallerUrl` は `downloads.claude.ai/claude-code-releases/2.1.286/win32-*/claude.exe`、`Publisher: Anthropic PBC`。定義の先頭のコメントは `Created with YamlCreate.ps1 Dumplings Mod`
- scoop の `main/claude-code`: 2.1.288。`storage.googleapis.com` の `claude-code-releases/2.1.288/win32-x64/claude.exe` で、`hash` は上の `win32-x64` と同じ。`autoupdate` は `manifest.json` の `checksum` を使う。`notes` に Git と `CLAUDE_CODE_GIT_BASH_PATH`
- Chocolatey の `claude-code`: 2.1.285（`community.chocolatey.org` のパッケージの飛び先の名前で見ただけ）

---

### 付録: Windows 11 の PowerShell のブロックの Linux での確認（2026-10-03）

Linux（クラウドのコンテナ）の PowerShell 7.6.6 と PSScriptAnalyzer 1.25.0 で確かめた。

**構文と Windows PowerShell 5.1 との互換**:

- Windows 11 の 3 節の `powershell` のブロック 12 個を、PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。指摘は 0

**[Windows 11 で使う](../claude-code.md#windows-11-で使う)の手順 2・4**: 文書から抜き出したブロックを、`$env:USERPROFILE` を一時的なディレクトリにして、そのまま流した（本物の `install.ps1` を取って動かす）:

- 手順 2 は `CC_CHANNEL = latest` を出した
- `$CC_CHANNEL` を空にした手順 4 は、`手順 2 の $CC_CHANNEL が空` のエラーだけを出し、何も取らなかった
- `latest` の手順 4 は、版（2.1.288）と `manifest.json` を取り、`win32-x64` の `claude.exe` を `%USERPROFILE%\.claude\downloads` に落として sha256 が合い、`Setting up Claude Code...` まで進んだ。その後の `claude.exe install latest` は、Linux では Windows の実行ファイルを動かせないので、`failed to run` のエラーで止まった。落としたファイルは消え、空の `.claude\downloads` が残った
- 流した後の PowerShell は、`$ErrorActionPreference` が `Continue`、`$ProgressPreference` が `Continue`、未定義の変数を読んでもエラーにならなかった（インストーラの設定が残っていない）

**`irm … | iex` との違い**: `install.ps1` と同じ先頭（`param` と `Set-StrictMode -Version Latest`・`$ErrorActionPreference = "Stop"`・`$ProgressPreference = "SilentlyContinue"`）の文字列を `iex` に渡すと、流した後も `$ErrorActionPreference` が `Stop`、`$ProgressPreference` が `SilentlyContinue` のままで、未定義の変数を読むと `VariableIsUndefined` のエラーになった。`& ([scriptblock]::Create(...)) stable` では何も残らず、位置引数の `stable` が `$Target` に入った。Windows PowerShell 5.1 では確かめていない

**[Windows 11 で使う](../claude-code.md#windows-11-で使う)の手順 5 と[Windows 11 のロールバック](../claude-code.md#windows-11-のロールバック)の手順 2〜4**: 文書から抜き出したブロックの `[Environment]::GetEnvironmentVariable('Path', 'User')` と `SetEnvironmentVariable('Path', …, 'User')` を、値を覚えておく偽物に置き換え（Linux の .NET は `User` の環境変数を持たない）、`$env:USERPROFILE` を一時的なディレクトリにして流した（パスの `\` は Linux の pwsh がそのまま区切りとして扱った）:

- 手順 5、PATH に無いとき: `PATH に <USERPROFILE>\.local\bin を足した` で、書いたのは 1 回、値は前の値の後ろに `;<USERPROFILE>\.local\bin`
- もう 1 度: `はもうある` で、書かなかった。末尾に `\` の付いた `<USERPROFILE>\.local\bin\` があるときも `はもうある`
- PATH が空のとき: `<USERPROFILE>\.local\bin` だけを書いた
- `claude.exe` が無いとき: `中断: <USERPROFILE>\.local\bin\claude.exe が無い（この節の手順 4 で入っていない）` で、書かなかった
- ロールバックの手順 2: `claude.exe`・`claude.exe.old.<数字>.<数字>`・`.local\share\claude`・`.local\state\claude`・`.cache\claude` が消え、`False` が 2 行出た。空の `.local\bin`・`.local\share`・`.local\state`・`.cache` と、`.claude`・`.claude.json` は残った
- ロールバックの手順 3、`.local\bin` が空のとき: PATH から `<USERPROFILE>\.local\bin` だけが外れ（書いたのは 1 回）、`.local\bin` も消えた。もう 1 度流すと、書かなかった
- `.local\bin` に別のファイル（`uv.exe`）があるとき: ロールバックの手順 2 の一覧に `uv.exe` が出て、手順 3 は `中断: <USERPROFILE>\.local\bin にほかのファイルがある（ほかのツールが使っている）` で、PATH を変えなかった
- ロールバックの手順 4: `.claude` と `.claude.json` が消え、`False` が 2 行出た

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと
1. `claude install` が Windows で出す文言（`Setup notes:` の `PATH` の案内と、`Location:` の表示）
1. `PATH` を足して開き直した PowerShell で `claude` が動くこと（`SetEnvironmentVariable` の知らせが、スタートメニューから開いた PowerShell に届くこと）
1. `Get-AuthenticodeSignature` が `Valid` を返し、署名者が `CN="Anthropic, PBC", …` で始まること
1. Firefox でのログインと、`claude auth status --text` の表示
1. 自動の更新と `claude update`、更新のときの `claude.exe.old.*`
1. ロールバック（動いている `claude.exe` を消せないこと、`.local\state\claude` と `.cache\claude` が Windows でも作られること）
1. arm64 の Windows、Git for Windows が無いとき、Windows PowerShell 5.1 での `irm … | iex` の後に設定が残ること

---

### 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1〜4。

**結果**: 既定の `latest` チャンネルで署名鍵の fingerprint を本文と比べて取り込み、`claude-code-2.1.289-1` を導入した。導入済み版とリポジトリの版の一致、`/usr/bin/claude`、ライセンスの場所を確認した。

**今回の未確認範囲**: 認証・AI への依頼・Remote Control・Windows の手順、更新・ロールバックは今回流していない。

### 付録: 現行版の新規 VM での再検証（2026-10-06）

公式 ISO から新規導入した AlmaLinux 10.2 Workstation の x86_64 VM（kernel `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active）で、`5da3478` の本文を SSH 対話 PTY に渡した。試験専用のユーザー・鍵と設定値を使用し、利用者の実アカウントの資格情報は持ち込んでいない。

実施手順 1〜4 を latest のまま通し、署名鍵の fingerprint が本文と一致することを確認した。claude-code 2.1.291-1 が入り、installed / available の最新値も一致、`claude --version` は 2.1.291 だった。実アカウントの認証・AI への依頼・stable 切替・更新・ロールバックはこの再検証で行っていない。

### 手順中の実測・検証状況の記録

**セッションの中の操作**（公式ドキュメントの [Interactive mode](https://code.claude.com/docs/en/interactive-mode) と [Commands](https://code.claude.com/docs/en/commands) から。本書では確かめていない）

### 手順中の実測・検証状況の記録

- **Windows PowerShell 5.1 からパイプで渡すと、ASCII でない文字は化けるはず**: native のコマンドへのパイプは `$OutputEncoding`（5.1 の既定は ASCII）で送られる（[about_Preference_Variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-5.1)）。日本語の指示は引数で渡す（確かめていない）

### 手順中の実測・検証状況の記録

| `claude remote-control --name <名前> --spawn same-dir` | Remote Control のサーバーを始める（[tmux.md の任意節](../tmux.md#claude-code-を-tmux-の中で動かす任意)。Windows は [windows-claude-remote-control.md](../windows-claude-remote-control.md)）。本書では、ログインしていないときのエラーだけを確かめた |

### ロールバック / 手順 1: 補足: 消えたかの確かめ方

`claude` を実行したことのある同じシェルでは、消した後も `command -v claude` が `/usr/bin/claude` を返した（bash がコマンドの場所を覚えているため）。`hash -r` の後か新しいシェルで確かめると、何も返さない。

### Windows 11 で使う / 手順 5: 補足: PATH の足し方

- 読むときに `%USERPROFILE%` のような書き方は展開され、書き戻すと展開した形（`C:\Users\<WIN_USER>\...`）で残る（.NET Framework の `Environment` の動き。Windows では確かめていない）。自分のユーザーの PATH なので、困ることは無いはず

### Windows 11 で使う / 手順 8: 補足: ログインの流れと、ログインの情報の置き場所

- 画面の文言は、公式の文書と Windows の `claude.exe`（2.1.288）の中の文字列から引いた。Windows では画面を見ていない

### Windows 11 のロールバック / 手順 2: 補足: 消すもの

- 本書は、更新の名残の `claude.exe.old.*`（[Windows 11 の更新](../claude-code.md#windows-11-の更新)の補足）と、`%USERPROFILE%\.local\state\claude`（ロック）・`%USERPROFILE%\.cache\claude`（更新の途中のファイル）も消す。この 2 つは、Linux の native installer の 2.1.288 が作ったフォルダーと、`claude.exe` の中の置き場所の決め方（`XDG_*` が無ければホームの下）から足したもので、Windows では確かめていない
