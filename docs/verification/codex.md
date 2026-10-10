# Codex CLI を AlmaLinux 10・Windows 11 に入れるの検証記録

[手順書](../codex.md)・[ロールバック](../extra/codex.md)

## 現在の検証状態（2026-10-10）

- Raspberry Pi 5 / AlmaLinux 10.2 / aarch64 の実機で、専用の一般ユーザー `<TEST_USER>` に公式インストーラーで Codex 0.161.0 を導入し、0.162.1 への手動更新・再導入・新しいシェルと CLI の撤去を確認した（[今回の付録](#付録-raspberry-pi-5--aarch64-実機での検証2026-10-10)）。
- 起動時の実際のネットワーク問い合わせで 0.162.1 の更新キャッシュが自然生成され、次回 TUI に更新選択肢が表示された。自作 PTY ドライバーでの試験と分けて、実端末の PTY で Enter を入力し、0.161.0 → 0.162.1 の更新成功・正常終了を確認した。PATH ブロック追加と再導入時の重複防止も確認済み。
- 既存ユーザー `<USER>` の Codex 0.160.0 と Grok 1.0.50 は更新せず、既存認証を利用する確認を分けて実施した。初回ログイン・ブラウザでの承認・デバイスコード認証の操作そのものは今回の記録対象外。
- 検証後は専用ユーザーで追加した状態・ユーザー・ホームを撤去し、OS の RPM 一覧が実施前と同じことを確認した。Windows の実行、認証済みユーザーのログアウトは今回も未確認。

以下の「補足」から 2026-10-09 の付録・「本文から分離した確認範囲と実測」までは過去の記録を保持したものです。その中の実機・aarch64・認証後に関する未検証の記述は当時の状態を表します。

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> AlmaLinux 10.2 / x86_64 のクリーン VM で導入・版の確認・0.160.0 から 0.160.1 への更新を本実行した（2026-10-06、認証前まで）。以前のコンテナでは再導入・配布物の削除も検証した。実機、ログイン、AI への依頼は未検証（[検証範囲](#対象と検証環境)）。

### Windows 11 で使う: 検証状況の記録

> [!WARNING]
> Windows 11 の実機では未検証。公式資料・インストーラーの内容と構文を確認した範囲は[補足](#対象と検証環境)に記載する。

### 対象と検証環境

- **目的**: Codex CLI を AlmaLinux 10 と Windows 11 に入れ、ログインと最初の起動まで進める
- **調査日**: 2026-10-05
- **状態**:
  - AlmaLinux 10: **10.2 / x86_64 のクリーン VM で実施手順 1〜4 と 0.160.1 への更新を本実行済み（2026-10-06、認証前まで）**。以前のコンテナでも検証。一般ユーザーで 0.160.0 の導入・`--version`・ヘルプ・未ログインの表示・同じ版の再導入・配布物の削除を確認
  - AlmaLinux 10（2026-10-09、コンテナ）: 起動したときの `Update available!` から 0.161.0 → 0.162.0 に上がることと、`codex update` を確認。Homebrew の cask と比べた（[付録](#付録-起動したときの更新とパッケージマネージャー2026-10-09)）
  - AlmaLinux の実機・aarch64・ログイン後の対話画面・sandbox 内のコマンド実行は未検証
  - Windows 11: 公式資料と `install.ps1` の読み取り、文書の PowerShell ブロック 10 個を Linux の PowerShell 7.6.6 で構文検査（エラー 0）。Windows PowerShell 5.1 での実行は未検証
  - Windows の実機でのインストール・PATH・認証・sandbox・更新・削除、ARM64 は未検証
  - 共通: ChatGPT へのログイン、デバイスコード認証、AI への依頼は未検証

### 選択した方針

- 公式 CLI のページが案内する standalone インストーラーを採る。Node.js やパッケージマネージャーの導入を増やさず、両 OS で同じ配布元を使える
- Windows は native の PowerShell で使う。Linux 用の開発環境が必要な場合の WSL は、本書の対象外
- AlmaLinux 専用の公式対応表を確認したわけではない。Linux 用配布物を AlmaLinux 10 で確認した範囲だけを検証済みとする
- 更新は、起動したときの知らせ（`1. Update now`）と、公式 CLI ページと同じインストーラーの再実行で説明する（前者は 2026-10-09 に追加）
- パッケージマネージャー（Homebrew の cask・scoop・WinGet）では入れない。理由は[参考資料](../reference/codex.md#実施手順--手順-3-補足-パッケージマネージャーで入れない理由)

### 完了時点の状態

- 以下は読者が手順を終えたときの確認点。今回の検証でログイン・AI 応答まで通したという意味ではない
- 自分のユーザーで `codex --version` と `codex login status` を実行できる
- `codex-sandbox` で Codex を起動して応答を確認できる
- 実際のプロジェクトでは、そのディレクトリへ移って `codex` を起動する

### 付録: コンテナと構文の検証記録（2026-10-05）

- 検証環境はクラウドの Linux 上の Docker。`almalinux:10` は AlmaLinux 10.2 (Lavender Lion) / x86_64 だった
- Docker イメージの digest は `sha256:838c2fafefb1a8a0d7f8cdbc3b0551c2a2b1eb0cd87aad6d62aecadb18311f1b`
- 検証用の一般ユーザーを作り、そのログインシェルで実行した。ホストの Codex・設定・認証情報には触れていない
- 検証環境だけで、プロキシと CA バンドルを渡した。dnf のミラー選択が遅かったため、BaseOS / AppStream は `repo.almalinux.org` を指定した（署名検証は有効）
- インストーラーの質問を出さないため、検証時だけ `CODEX_NON_INTERACTIVE=1` を渡した。初回は取得した `install.sh` を `sh` で実行し、再導入は本文と同じ `curl … | sh` で実行した

| 確認 | 結果 |
|---|---|
| 初回導入 | `0.160.0-x86_64-unknown-linux-musl` を取得し、成功の表示まで進んだ |
| PATH と版 | ログインシェルには最初から `~/.local/bin` があり、`codex --version` は `codex-cli 0.160.0` |
| `codex --help`・`codex login --help` | 正常終了。`login status` と `--device-auth` の存在を確認 |
| `codex login status` | `Not logged in`、終了コード 1（ログインは行っていない） |
| インストーラーの再実行 | `Updating Codex CLI` と出て、同じ 0.160.0 を再選択して正常終了 |
| 確認用の作業場所 | ディレクトリ作成と `git init` が正常終了。対話の `codex` は起動していない |
| `codex logout` | 未ログインのため `Not logged in`。認証済みの資格情報を消す動作は未検証 |
| Linux のロールバック | リンク 2 本と `packages/standalone` を削除後、`command -v codex` が終了コード 1。`.codex` 自体は残った |
| bash のブロック 13 個 | `bash -n` で構文の誤り 0 |
| PowerShell のブロック 10 個 | Linux の PowerShell 7.6.6 の構文解析器で誤り 0。Windows の API・レジストリ・ジャンクションの動作や 5.1 との互換を保証する検査ではない |

読み取った公式インストーラーの SHA-256:

| ファイル | SHA-256 |
|---|---|
| `install.sh` | `150e3cf675682efeaac115aa3747add3f27887896d04ce6d0b56478d8b428bf6` |
| `install.ps1` | `3522b77d4485eac014e70fa946787c95fad3874a4e9047557c1e044eb268d13e` |

- インストーラーが PATH に行を足す分岐、別の方法で導入済みの場合の移行、Windows の処理はソースを読んだだけ
- 上のハッシュは調査対象を識別するための記録で、将来のインストーラーにそのまま適用する固定値ではない

---

### 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1〜4、更新の手順 2・3に相当するインストーラーの再実行と版の確認。

**結果**: 公式 standalone インストーラーで Codex CLI 0.160.0 を導入した。Workstation に curl があったため、本文の案内どおり手順 2 の `curl-minimal` は外した。同じインストーラーを再実行すると、検証中に最新が変わっており 0.160.0 から 0.160.1 へ更新された。`Start Codex now?` は `n` と答え、最終の `codex --version` は `codex-cli 0.160.1`、`codex login status` は `Not logged in`。`~/.local/bin/codex` で見つかることを確認した。

**今回の未確認範囲**: 認証・AI への依頼・対話画面・sandbox での実行、Windows の手順、ロールバックは今回確認していない。

### 付録: 現行版の新規 VM での再検証（2026-10-06）

公式 ISO から新規導入した AlmaLinux 10.2 Workstation の x86_64 VM（kernel `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active）で、`5da3478` の本文を SSH 対話 PTY に渡した。試験専用のユーザー・鍵と設定値を使用し、利用者の実アカウントの資格情報は持ち込んでいない。

実施手順 1〜4 を通した。事前の command -v は終了 1、standalone の Codex CLI 0.160.1 が入り、実行場所は自分の ~/.local/bin/codex だった。依存の curl-minimal の指定は、導入済み curl へ解決して成功し、競合は起きなかった。~/.local/bin は OS 既定の PATH にあり、インストーラも既存 PATH と表示した。起動の質問には n と答え、`codex login status` は Not logged in（終了 1）。実アカウントの認証・AI への依頼・更新・ロールバックは行っていない。

### 付録: 起動したときの更新とパッケージマネージャー（2026-10-09）

利用者の依頼（パッケージマネージャーで入れられるならその手順にする。自動で最新になるなら公式の方法でよい）を受けて、公式インストーラーの更新の動きと、Homebrew の cask を比べた。

| 項目 | 値 |
|---|---|
| 環境 | クラウドの Linux の Docker の上の `almalinux:10`（AlmaLinux 10.2、x86_64、digest `sha256:838c2fafefb1a8a0d7f8cdbc3b0551c2a2b1eb0cd87aad6d62aecadb18311f1b`）。プロキシの環境変数と CA を渡した |
| 版 | Codex CLI 0.161.0（古い版として入れた）と 0.162.0（調査時の最新） |
| 公式インストーラーの確認 | 新規の一般ユーザー（`/etc/skel` の `.bashrc`）。端末の代わりに `script` の PTY（150×40） |
| Homebrew の確認 | 別のコンテナの一般ユーザー。[共通の bash 設定](https://github.com/ryo-aoki-pc/bash)と Homebrew 7.0.9 |

**公式インストーラーで入れた Codex の起動時の更新**:

- 古い版は `curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh -s -- --release 0.161.0` で入れた（`~/.local/bin` が PATH に無いユーザーなので、`~/.bashrc` に PATH のブロックが足された）
- 対話の画面を起動すると、最新の版を `https://api.github.com/repos/openai/codex/releases/latest` に問い合わせた
- この検証環境では、その問い合わせが `403 Forbidden` で失敗し（`~/.codex/logs_2.sqlite` に `Failed to update version`）、`~/.codex/version.json` はできなかった
- そこで、`~/.codex/version.json` に `latest_version` を `0.162.0`、`last_checked_at` を今の時刻にして書き、起動した
- 画面に `Update available!`・`0.161.0 -> 0.162.0`・`1. Update now`（`sh -c 'curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh'` を動かすと表示）・`2. Skip`・`3. Skip until next version` が出た
- Enter を押すと、`Updating Codex CLI from 0.161.0 to 0.162.0` から `Codex CLI 0.162.0 installed successfully.`・`Update ran successfully! Please restart Codex.` まで進んで、画面が終わった
- その後の `codex --version` は `codex-cli 0.162.0`。`~/.codex/packages/standalone/releases` には 0.161.0 と 0.162.0 が残った
- `version.json` が新しいうちの起動では、問い合わせは行われなかった（ログに無い）
- `codex update`（最新のとき）: 同じインストーラーが動き、`Codex CLI 0.162.0 installed successfully.`・`Update ran successfully! Please restart Codex.`、終了コード 0
- 対話の画面は、終わった後も `codex app-server --listen unix:// --managed-daemon`（配布物は `~/.codex/packages/app-server-daemon/`）を残した。`codex app-server daemon stop` で止まった
- 確認していないこと: GitHub への問い合わせが通ったときの知らせ（この環境では通らない）、ログイン後の画面、Windows 11

**Homebrew の cask**（`brew install --cask codex`）:

- 0.162.0 が入り、`/home/linuxbrew/.linuxbrew/bin/codex` にリンクされた。bash の補完は `$(brew --prefix)/etc/bash_completion.d/` に入り、`~/.bashrc` は変わらなかった
- `codex update`: `Error: Could not detect the Codex installation method. Please update manually: https://developers.openai.com/codex/cli/`、終了コード 1
- `brew outdated --cask` と `brew upgrade --cask codex` は動いた（最新なので上げるものは無かった）
- `brew uninstall --cask codex` はリンクを消し、`~/.codex` は残った
- 共通の bash 設定では Homebrew の `bin` が `~/.local/bin` より PATH で先なので、standalone の Codex が残っていても Homebrew の方が動いた

**ほかの配布**（定義を読んだだけ）:

- scoop の main の `codex` は 0.162.0。extras には無い
- WinGet の `OpenAI.Codex` は 0.161.0（zip の中の実行ファイルを portable で置く）

## 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

### Windows 11 のロールバック

- 設定・会話履歴と、Windows sandbox が作ったユーザー・ポリシーなどは残る。OS の sandbox 設定を元に戻す手順は未検証

## 付録: Raspberry Pi 5 / aarch64 実機での検証（2026-10-10）

| 項目 | 値 |
|---|---|
| 環境 | Raspberry Pi 5、AlmaLinux 10.2 (Lavender Lion)、aarch64、kernel `6.12.96-20260724.v8.1.el10` |
| 対象 | setup-notes #117、取得時の commit `814b590` |
| 実行ユーザー | 新規の一般ユーザー `<TEST_USER>` のログインシェル。HOME・CODEX_HOME は変更せず、既存ユーザー `<USER>` の設定・認証をコピーしていない |
| 版 | 指定した旧版 0.161.0 と、実行時の最新 0.162.1（aarch64 の standalone 配布物） |
| インストーラー | `https://chatgpt.com/codex/install.sh` を取得して `sh` で実行。SHA-256 `150e3cf675682efeaac115aa3747add3f27887896d04ce6d0b56478d8b428bf6`（2026-10-10 取得） |
| 認証 | 試験ユーザーの `codex login status` は `Not logged in`、終了コード 1。既存ユーザーの初回認証・ログアウトは行っていない |

### 導入・手動更新・再導入

| 確認 | 実測結果 |
|---|---|
| 古い版の導入 | `CODEX_NON_INTERACTIVE=1 sh install.sh --release 0.161.0` が成功、終了コード 0。`codex --version` は `codex-cli 0.161.0` |
| 新しいシェル | `bash -lic` で `~/.local/bin/codex` と 0.161.0 を確認。OS 既定の PATH には最初から `.local/bin` があり、この実行では installer の PATH ブロックは追加されなかった |
| 手動更新 | 公式インストーラーを `CODEX_NON_INTERACTIVE=1` で再実行し、0.162.1 を導入。終了コード 0。更新前後の `.bashrc` の `cmp` も終了コード 0 |
| 同じ版の再導入 | インストーラーをもう一度実行し、終了コード 0 と 0.162.1 を確認 |
| 更新後の新しいシェル | `~/.local/bin/codex` と `codex-cli 0.162.1` を確認 |

### 実ネットワークの問い合わせと TUI 更新

- 古い 0.161.0 で、この試験ユーザーの更新キャッシュを外して、実際の PTY で `codex` を起動した。初回の起動後、`~/.codex/version.json` に `latest_version = 0.162.1` と `last_checked_at = 2026-10-10T02:33:19.438477340Z` が自然生成された。2026-10-09 のコンテナ記録と異なり、最新版・時刻を手で注入していない。
- 次回起動の画面に `1. Update now` と、公式インストーラーを `CODEX_NON_INTERACTIVE=1` で実行するコマンドが表示された。初回の PTY ドライバーは画面の特定文字列も同時に要求していたため Enter を送らず、120 秒後に SIGINT で終了した。内側の CLI は終了コード -2、更新前後の版は 0.161.0 のままであり、この回を TUI 更新成功とはしていない。
- 更新選択肢を固有のインストーラー URL と組み合わせて検出するようドライバーを修正して再試験した。実ネットワークの再問い合わせで `last_checked_at = 2026-10-10T02:47:04.461504665Z` のキャッシュが自然生成され、更新選択肢を検出して Enter を送ったが、120 秒後も版は 0.161.0 のまま（SIGINT、子プロセスの戻り値 -2）。入力の受理・インストーラー実行は確認できず、この回も TUI 更新成功とはしていない。初回の出力は別の控えに保存した。
- 続いて 0.161.0 を入れ直し、試験ユーザーの実端末の PTY で `TERM=xterm-256color codex` を起動した。0.161.0 → 0.162.1 の更新メニューを確認して Enter を入力すると、`Updating Codex`、aarch64 の standalone 配布物の導入、`Codex CLI 0.162.1 installed successfully.`、`Update ran successfully! Please restart Codex.` まで進み、終了コード 0 で終わった。直後の `codex --version` も `codex-cli 0.162.1`、終了コード 0。手動の再導入と分けた TUI 更新の成功として記録する。
- 実端末の初回起動は `TERM=dumb` が CLI に拒否されたため、端末種別を指定して再実行した。自作ドライバーの入力が受理されなかった原因は断定していない。画面収集用ドライバーの終了コード 0 と、内側の CLI の更新成功は分けて判定した。

### PATH ブロック追加の補助試験

- 既定のログイン PATH では `.local/bin` がすでに含まれるため、インストーラーを呼ぶときだけ `PATH=/usr/bin:/bin` として、同じ専用ユーザーの HOME で再実行した。`PATH was added to /home/<TEST_USER>/.bashrc` と成功を表示し、0.162.1 を確認した。
- Codex の開始・終了 marker がそれぞれ 1 個あり、無関係の確認用行が保持されることを確認。再実行しても `.bashrc` のバイト比較は一致した（終了コード 0）。
- Codex のブロックだけを控えに抽出し、OS のシェル設定を読み込まない `bash --noprofile --norc` で読み込むと `~/.local/bin/codex` と 0.162.1 が見つかった。既定 `.bashrc` の PATH 追加とは分けて検査した。

### CLI の撤去と残る範囲

- 試験ユーザーの `codex app-server daemon stop` は終了コード 0。リンクと `~/.codex/packages/standalone` を撤去した後、新しいログインシェルの `command -v codex` は終了コード 1。無関係の `.bashrc` の行は保持した。
- 初回の撤去補助では `rg` が試験ユーザーの PATH に無く、installer ブロック削除の条件が実行されなかった。`grep` に置き換えた再試験では、開始・終了 marker の不在を明示的に検査して終了コード 0。新しいシェルでの CLI 不在と、無関係の行・確認用リンクの保持も再確認した。
- CLI のロールバックでは `.codex` の設定・履歴等を保持する本文の方針に合わせた。その確認後、今回作成した未認証の専用ユーザーで追加した検証状態だけを片付けるため、別の最終復元操作として `.codex` を撤去した。通常の CLI ロールバックで既存ユーザーの `.codex` 全体を消す手順ではない。
- 最終復元では CLI 状態の不在・新しいシェルでの CLI 不在・無関係の確認用行とリンクの保持をすべて終了コード 0 で確認した。今回作成したユーザー・同名グループ・ホームを削除し、OS の `rpm -qa` をソートした一覧の SHA-256 は実施前後で一致した。
- 実機での導入・更新確認は、初回の ChatGPT ログイン、ブラウザ承認、デバイスコード認証の操作、Windows の実行の証明にはしない。
