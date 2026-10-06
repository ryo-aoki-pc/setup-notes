# Codex CLI を AlmaLinux 10・Windows 11 に入れるの検証記録

[手順書](../codex.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

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
  - AlmaLinux の実機・aarch64・対話画面・sandbox 内のコマンド実行は未検証
  - Windows 11: 公式資料と `install.ps1` の読み取り、文書の PowerShell ブロック 10 個を Linux の PowerShell 7.6.6 で構文検査（エラー 0）。Windows PowerShell 5.1 での実行は未検証
  - Windows の実機でのインストール・PATH・認証・sandbox・更新・削除、ARM64 は未検証
  - 共通: ChatGPT へのログイン、デバイスコード認証、AI への依頼は未検証

### 選択した方針

- 公式 CLI のページが案内する standalone インストーラーを採る。Node.js やパッケージマネージャーの導入を増やさず、両 OS で同じ配布元を使える
- Windows は native の PowerShell で使う。Linux 用の開発環境が必要な場合の WSL は、本書の対象外
- AlmaLinux 専用の公式対応表を確認したわけではない。Linux 用配布物を AlmaLinux 10 で確認した範囲だけを検証済みとする
- 更新は公式 CLI ページと同じ、インストーラーの再実行で説明する

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

## 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

### Windows 11 のロールバック

- 設定・会話履歴と、Windows sandbox が作ったユーザー・ポリシーなどは残る。OS の sandbox 設定を元に戻す手順は未検証
