# Claude Code 最新版インストール手順（AlmaLinux 10 は公式 dnf リポジトリ / Windows 11 は公式の native installer）

## 実施手順

> [!IMPORTANT]
> - **この実施手順は AlmaLinux 10 のもの**。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)から通す（管理者ではない Windows PowerShell 5.1 に貼る）
> - **すべて対象ホスト上で実行する**。手順 5 の認証だけブラウザを使う
> - **手順 3 には対話入力がある**（トランザクション表と署名鍵の取り込みの確認）。答えてから手順 4 を貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: `claude` のコマンドラインは[使い方の基本](#使い方の基本)。SSH を切っても動かし続ける（Remote Control も）なら [tmux.md の任意節](tmux.md#claude-code-を-tmux-の中で動かす任意)。以後は[更新](#更新)・[ロールバック](#ロールバック)。最新版で不具合に当たったら [stable チャンネルに切り替える（任意）](#stable-チャンネルに切り替える任意)

> [!WARNING]
> この実施手順（AlmaLinux 10）の既定の `latest` チャンネルは **x86_64 のコンテナでのみ検証した**。実機（aarch64）で本実行したのは `stable` チャンネル（[対象と検証環境](#対象と検証環境)）。

1. 変数を設定する。

   ```bash
   CC_CHANNEL=latest               # 追従するチャンネル。latest（出た版をすぐ配る）か stable（約 1 週間遅れ）。<CC_CHANNEL>
   printf 'CC_CHANNEL = %s\n' "${CC_CHANNEL}"
   ```

   - **編集が必須の変数は無い**。既定の `latest`（最新版）でよければ、そのまま貼る
   - 大きな不具合のある版を避けたいなら `stable`（1 週間ほど遅れて、そうした版を飛ばすチャンネル）にする
   - 最後に値を読み戻して確かめる
   - `latest` か `stable` 以外が入っていたら、ここで止めて直す
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

   <details>
   <summary>補足: 変数について</summary>

   - `CC_CHANNEL` は `baseurl` の末尾に埋まるだけ。入れた後でチャンネルを変えるときは、[stable チャンネルに切り替える（任意）](#stable-チャンネルに切り替える任意)の手順で repo ファイルを書き換える（`stable` へ移るときは版が下がるので、`upgrade` ではなく `distro-sync` を使う）
   - ネイティブインストーラ版にある `autoUpdatesChannel` / `minimumVersion` の設定は dnf 版では効かない（更新を行うのが dnf のため）

   </details>

1. リポジトリを追加する。

   ```bash
   if [ -z "${CC_CHANNEL}" ]; then echo '中断: 手順 1 の CC_CHANNEL が空のまま。値を入れて貼り直す' >&2; else
     sudo tee /etc/yum.repos.d/claude-code.repo >/dev/null <<EOF
   [claude-code]
   name=Claude Code
   baseurl=https://downloads.claude.ai/claude-code/rpm/${CC_CHANNEL:?手順 1 の CC_CHANNEL が空のまま。値を入れて貼り直す}
   enabled=1
   gpgcheck=1
   gpgkey=https://downloads.claude.ai/keys/claude-code.asc
   EOF
     cat /etc/yum.repos.d/claude-code.repo
   fi
   ```

   - `baseurl` の末尾が手順 1 で選んだチャンネル（既定なら `latest`）になっていることを確認する
   - `中断:` と出たら、何も書いていない

   <details>
   <summary>補足: チャンネルは baseurl で決まる</summary>

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

   </details>

1. Claude Code をインストールする。

   ```bash
   sudo dnf install claude-code
   ```

   - トランザクション表で `claude-code` の版（既定の `latest` なら、その日の最新版）を確かめて `y` と答える
   - 初回は続けて署名鍵の取り込みを聞かれる
   - 表示される fingerprint が `31DD DE24 DDFA B679 F42D 7BD2 BAA9 29FF 1A7E CACE` であることを**目で確かめてから** `y` と答える
   - 違っていれば `N` で中断する
   - **次の手順は、答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 鍵の取り込み</summary>

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

   </details>

1. インストールできたか確かめる。

   ```bash
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}' claude-code
   dnf -q repoquery --available --latest-limit 1 --qf '%{name} %{version}-%{release} %{reponame}' claude-code
   claude --version
   rpm -ql claude-code
   ```

   - 1 行目（入っている版）と 2 行目（チャンネルにある一番新しい版）が同じなら、そのチャンネルの最新版が入っている
   - `2.1.283 (Claude Code)` のようにバージョンが出れば動く
   - 入るファイルは実行ファイル 1 つとライセンスだけ（[完了時点の状態](#完了時点の状態)）
   - Node.js は要らない

   <details>
   <summary>補足: 最新版かどうかの確かめ方</summary>

   - `--available` はリポジトリにある版だけを見る（入っている版は含めない）。リポジトリには古い版も残っているので、`--latest-limit 1` で一番新しいものだけに絞る
   - 2026-09-26 の時点で、`latest` には 137 版、`stable` には 56 版が残っていた（x86_64 / aarch64 それぞれ）
   - ネイティブインストーラが最新版として取りに行くのは `https://downloads.claude.ai/claude-code-releases/latest` が指す版で、2026-09-26 は RPM の `latest` と同じ `2.1.283` だった。RPM に届くのが遅れることはある（[注意点](#注意点)）
   - コンテナの dnf 4.20.0 では、`--qf` の末尾に `\n` を付けると結果の後に空行が 1 行増えた。本書の 2026-09-22 版はそう書いていたので外した

   </details>

1. 作業したいディレクトリで `claude` を起動し、ブラウザでログインする。

   - 作業したいディレクトリに `cd` してから、引数無しで `claude` を起動する
   - 画面の案内に従ってブラウザでログインする
   - Pro / Max / Team / Enterprise か Console のアカウントが要る（無料の claude.ai プランでは使えない）
   - `ANTHROPIC_API_KEY` を設定している場合は、ブラウザではなくその鍵を使ってよいか 1 度だけ聞かれる
   - **認証情報（トークン・API キー）はこの文書に載せない**

   <details>
   <summary>補足: 認証</summary>

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

   </details>

---

## 使い方の基本

- 全部のオプションとサブコマンドは `claude --help`（サブコマンドの中は `claude mcp --help` など）。`--max-turns` のように `--help` に出ないものもある
- 表のコマンドは、本書で実行して確かめた（[付録](#付録-使い方の基本の検証記録2026-10-01)）。確かめていないものは、表の見出しの括弧と、その行に書いた
- 確かめたのは Linux だけ。[Windows 11 で使う](#windows-11-で使う)で入れた `claude` にも、同じコマンドを Windows PowerShell で打つ（公式の CLI reference は OS で分けていない）が、Windows では確かめていない
- SSH を切っても動かし続けるには、tmux の中で起動する（[tmux.md の任意節](tmux.md#claude-code-を-tmux-の中で動かす任意)）。Windows 11 は [windows-claude-remote-control.md](windows-claude-remote-control.md)（タスク スケジューラと WezTerm）

**起動と再開**（`-c`・`-r`・`-n`・`--model`・`--permission-mode`・`--add-dir` は `-p` と組み合わせて確かめた。`-r` の一覧から選ぶ画面と `claude "<最初の指示>"` は確かめていない）

| コマンド | すること |
|---|---|
| `claude` | 今のディレクトリで、対話のセッションを始める |
| `claude "<最初の指示>"` | 最初の指示を渡して、対話のセッションを始める |
| `claude -c` | 今のディレクトリの、いちばん最近の会話を続ける |
| `claude -r` | 会話の一覧から選んで再開する |
| `claude -r <名前か ID>` | `-n` で付けた名前か、セッションの ID の会話を再開する |
| `claude -n <名前>` | セッションに名前を付けて始める（`/resume` の一覧と端末のタイトルに出る） |
| `claude --model <別名>` | モデルを選んで始める（`opus`・`sonnet`・`haiku` などの別名か、モデルの正式な名前） |
| `claude --permission-mode plan` | 計画だけを立てるモード（ファイルを変えない）で始める。ほかに `acceptEdits`・`auto` など |
| `claude --add-dir <ディレクトリ>` | 今のディレクトリのほかに、読み書きしてよいディレクトリを足す |

**セッションの中の操作**（公式ドキュメントの [Interactive mode](https://code.claude.com/docs/en/interactive-mode) と [Commands](https://code.claude.com/docs/en/commands) から。本書では確かめていない）

| 操作 | すること |
|---|---|
| `Esc` | 今の応答やツールの実行を止める（ダイアログなら閉じる） |
| `Esc` を 2 回 | 入力があれば消す。空なら、前の時点に戻すメニューを開く |
| `Shift+Tab` | 許可のモードを順に切り替える（`default` → `acceptEdits` → `plan` …） |
| `Ctrl+C` | 動いているものを止める。何も動いていなければ 1 回目で入力を消し、2 回目で終わる |
| `Ctrl+J` | 改行する（どの端末でも。Shift+Enter は WezTerm などでだけ） |
| `!` で始める | Claude を通さずにシェルのコマンドを実行し、結果を会話に入れる |
| `@` | ファイルのパスを補完して、会話で指す |
| `Ctrl+R` | 入力の履歴をさかのぼって探す |
| `Ctrl+B` | 動いているコマンドを裏へ回す（tmux の中では 2 回押す） |
| `/help` | ヘルプとコマンドの一覧 |
| `/resume` | 会話の一覧から再開する |
| `/clear` | 会話を空にして始め直す |
| `/compact` | ここまでの会話を要約して、文脈を空ける |
| `/model` | モデルを変える |
| `/permissions` | 許可の規則を見る・変える |
| `/status` | 版・モデル・アカウント・接続の状態 |
| `/usage` | 使った量とプランの上限 |
| `/init` | このディレクトリの `CLAUDE.md` を作る |
| `/memory` | `CLAUDE.md` を編集する |
| `/remote-control` | このセッションを Remote Control につなぐ（`/rc`） |
| `/exit` | 終わる |

**非対話（`-p`）**（1 回答えて終わる。スクリプトやパイプで使う）

| コマンド | すること |
|---|---|
| `claude -p "<指示>"` | 答えだけを標準出力に出して終わる |
| `<コマンド> \| claude -p "<指示>"` | 標準入力の中身を、指示と一緒に渡す |
| `claude -p --output-format json "<指示>" \| jq -r .result` | 結果を JSON で受け取る（`result`・`session_id`・`is_error`・`num_turns`・`total_cost_usd` など） |
| `claude -p --allowedTools "Bash(touch *)" "<指示>"` | 聞かずに使ってよいツールを足す。`-p` では許可を聞けないので、無いと断られて `permission_denials` に残る |
| `claude -p --max-turns <数> "<指示>"` | ターンの数の上限。超えると `error_max_turns` で、終了コードは 1 |
| `claude -c -p "<指示>"` | 今のディレクトリのいちばん最近の会話に続けて、1 回答える |
| `claude -r <名前か ID> -p "<指示>"` | その会話に続けて、1 回答える |

- **`-p` はディレクトリの信頼の確認を飛ばす**（`claude --help`）。信頼できるディレクトリでだけ使う
- `date` のように読むだけのコマンドは、`--allowedTools` が無くても聞かずに動いた
- **Windows PowerShell 5.1 からパイプで渡すと、ASCII でない文字は化けるはず**: native のコマンドへのパイプは `$OutputEncoding`（5.1 の既定は ASCII）で送られる（[about_Preference_Variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-5.1)）。日本語の指示は引数で渡す（確かめていない）

**管理のサブコマンド**

| コマンド | すること |
|---|---|
| `claude --version` | 版を出す |
| `claude doctor` | 導入の状態を診る（読むだけ）。`Remote Control` の段に、使えるかと、使えない理由が出る |
| `claude auth status --text` | ログインしているかを出す（していなければ `Not logged in.` で、終了コードは 1） |
| `claude mcp add <名前> -- <コマンド> [<引数>…]` | 標準入出力でつなぐ MCP サーバーを足す（既定は `local`: このディレクトリで、自分だけ） |
| `claude mcp add -s user …` / `-s project …` | `user` はどのディレクトリでも使う。`project` はこのディレクトリの `.mcp.json` に書いて共有する |
| `claude mcp add --transport http <名前> <URL>` | HTTP でつなぐ MCP サーバーを足す |
| `claude mcp list` | MCP サーバーの一覧（つながるかも確かめる） |
| `claude mcp get <名前>` | 1 つの MCP サーバーの詳細とスコープ |
| `claude mcp remove <名前> -s <スコープ>` | MCP サーバーを消す |
| `claude update` | dnf で入れた版では更新しない（`Claude is managed by a package manager.`）。[更新](#更新)の `sudo dnf upgrade claude-code` を使う。native installer の版（Windows 11）は、すぐに更新する（[Windows 11 の更新](#windows-11-の更新)） |
| `claude remote-control --name <名前> --spawn same-dir` | Remote Control のサーバーを始める（[tmux.md の任意節](tmux.md#claude-code-を-tmux-の中で動かす任意)。Windows は [windows-claude-remote-control.md](windows-claude-remote-control.md)）。本書では、ログインしていないときのエラーだけを確かめた |

- `local` と `user` の MCP サーバーは `~/.claude.json`（Windows では `%USERPROFILE%\.claude.json`）に書かれる（`local` はディレクトリごとの欄）
- **`claude auth status` は、端末に残った後ろの行を読んで捨てる**: ブラケットペースト無しで、ほかのコマンドと続けて貼るときは最後に置く（`claude --version` と `claude doctor` では捨てなかった）
- ログインとログアウトは、セッションの中の `/login`・`/logout` か、`claude auth login`・`claude auth logout`（本書では試していない）

---

## 更新

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 の更新](#windows-11-の更新)
- **dnf で入れた Claude Code は自動更新しない**
- 通常の `dnf upgrade` に含まれる
- 追う版は repo ファイルの `baseurl` のチャンネルで決まる（既定は `latest`）

1. Claude Code だけを上げるときは、パッケージを指定して更新する。

   ```bash
   sudo dnf upgrade claude-code
   ```

   - 起動中に新しい版が出ると Claude Code が更新を知らせてくるが、dnf 版は自分で更新できない（root 権限が要るため）
   - `claude update` も、`Claude is managed by a package manager.` と出して何もしない
   - リポジトリ側にその版が届くまで、少し遅れることもある
   - 上がった版は[手順 4](#実施手順)のコマンドで確かめる

---

## stable チャンネルに切り替える（任意）

- `latest` で不具合に当たったときに、1 週間ほど遅れて大きな不具合のある版を飛ばす `stable` へ移る
- `stable` の版は `latest` より古いので、`dnf upgrade` では下がらない（`Nothing to do.`）。この節の手順 2 の `distro-sync` で下げる
- repo ファイルの `baseurl` の末尾を書き換えるだけで、`dnf clean` は要らない
- 手順 1 で `stable` を選んで入れた後に `latest` へ移るときは、この節の手順 4 だけを行う
- この節は AlmaLinux 10 の dnf のもの。Windows 11 でチャンネルを変えるときは、[Windows 11 で使う](#windows-11-で使う)の手順 2 の補足

1. repo ファイルの `baseurl` を `stable` に書き換える。

   ```bash
   {
     sudo sed -i 's|/rpm/latest$|/rpm/stable|' /etc/yum.repos.d/claude-code.repo
     grep '^baseurl=' /etc/yum.repos.d/claude-code.repo
   }
   ```

   - `baseurl` の末尾が `stable` になっていることを確認する

   <details>
   <summary>補足: キャッシュ</summary>

   dnf 4.20.0 のキャッシュは `/var/cache/dnf/claude-code-<16 桁の 16 進数>` のディレクトリに置かれる。実測では、`baseurl` を書き換えた直後の dnf が `stable` のメタデータ（10 kB）を取りに行き、このディレクトリが 2 つ（チャンネルごと）になった。前のチャンネルのメタデータは使われなかった。

   </details>

1. 入っている版を `stable` の最新に合わせる。

   ```bash
   sudo dnf distro-sync claude-code
   ```

   - トランザクション表が `Downgrading:` で、版が `stable` の最新（2026-09-26 は `2.1.274-1`）になっていることを確かめて `y` と答える
   - `stable` がすでに同じ版まで追いついていれば `Nothing to do.` で終わる
   - **次の手順は、答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: distro-sync の表示</summary>

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

   </details>

1. 入っている版を確かめる。

   ```bash
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}' claude-code
   dnf -q repoquery --available --latest-limit 1 --qf '%{name} %{version}-%{release} %{reponame}' claude-code
   claude --version
   ```

   - 1 行目と 2 行目が同じ版なら、`stable` の最新版に揃っている
   - 以後の `sudo dnf upgrade claude-code`（[更新](#更新)）は `stable` の版を追う

1. 元に戻すときは、`baseurl` を `latest` に戻して最新版へ上げる。

   ```bash
   {
     sudo sed -i 's|/rpm/stable$|/rpm/latest|' /etc/yum.repos.d/claude-code.repo
     grep '^baseurl=' /etc/yum.repos.d/claude-code.repo
     sudo dnf upgrade claude-code
   }
   ```

   - `baseurl` の末尾が `latest` に戻ったことを確認する
   - トランザクション表が `Upgrading:` になっていることを確かめて `y` と答える
   - 答えた後、[手順 4](#実施手順)のコマンドで版を確かめる

---

## ロールバック

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 のロールバック](#windows-11-のロールバック)
- ロールバックは **x86_64 のコンテナでだけ本実行した**（実機では未実行）
- 設定・履歴（`~/.claude/`、`~/.claude.json`、プロジェクト側の `.claude/`、`.mcp.json`）は残る

> [!CAUTION]
> 設定・履歴のファイルを消すと、設定・許可済みツール・MCP サーバー定義・セッション履歴がすべて消える。消す前に中身を確認する。

1. Claude Code を消す。

   ```bash
   sudo dnf remove claude-code
   ```

   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 消えたかの確かめ方</summary>

   `claude` を実行したことのある同じシェルでは、消した後も `command -v claude` が `/usr/bin/claude` を返した（bash がコマンドの場所を覚えているため）。`hash -r` の後か新しいシェルで確かめると、何も返さない。

   </details>

1. repo ファイルを消す。

   ```bash
   sudo rm -f /etc/yum.repos.d/claude-code.repo
   ```

1. 鍵も消すときだけ、署名鍵を消す。

   ```bash
   sudo rpm -e gpg-pubkey-1a7ecace-69caef70          # 鍵も消す場合
   ```

---

## Windows 11 で使う

> [!IMPORTANT]
> - **すべて Windows で行う**。この節の手順 1 で管理者ではない Windows PowerShell（5.1）を開き、手順 2〜5 をそこに貼る。手順 6 で開き直した PowerShell に、手順 7〜9 と、後ろの Windows 11 の 2 節（更新・ロールバック）を貼る。管理者の権限は要らない（自分のユーザーの `%USERPROFILE%` に入る）
> - 前提: [Windows 11 の初期設定の手順 16〜19](windows-setup.md#実施手順)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ貼り付けの設定）。通していなければ、ブロックは Ctrl+V で貼る
> - 前提: [Git for Windows](git.md#windows-11-で-git-for-windows-を入れる)（Claude Code の Bash のツールが Git Bash を使う）と、既定のブラウザにした [Firefox](firefox.md#windows-11-で使う)（この節の手順 8 のログインで開く）。[Windows 11 の初期設定](windows-setup.md)のリードの順に通していれば、どちらも入っている
> - **この節の手順 8 には対話入力がある**（Claude Code の最初の設定と、ブラウザでのログイン）。`/exit` で Claude Code を終えてから手順 9 を貼る

- 上から順にコードブロックを貼る。この節の手順 2 で変数を設定した PowerShell に、手順 5 までを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- Pro / Max / Team / Enterprise か Console のアカウントが要る（無料の claude.ai プランでは使えない）
- 手順の後: `claude` のコマンドラインは[使い方の基本](#使い方の基本)（確かめたのは Linux だけ）。SSH でログインして Remote Control を使い続けるなら [windows-claude-remote-control.md](windows-claude-remote-control.md)。以後は[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](#windows-11-のロールバック)

> [!WARNING]
> **この節と、後ろの Windows 11 の 2 節は、Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、公式の文書、インストーラ（`install.ps1`）と Windows の `claude.exe`（2.1.288）の中身と署名、Linux の PowerShell 7 での構文と模擬の実行、Linux の同じ版の native installer の動きだけ（[対象と検証環境](#対象と検証環境)）。

1. Windows で、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」でなくてよい）
   - 「Windows PowerShell (x86)」は開かない（32 ビットで動き、インストーラが `Claude Code does not support 32-bit Windows` で止まる）

1. 変数を設定する。

   ```powershell
   $CC_CHANNEL = 'latest'                # 追従するチャンネル。latest（出た版をすぐ配る）か stable（約 1 週間遅れ）。<CC_CHANNEL>
   'CC_CHANNEL = {0}' -f $CC_CHANNEL
   ```

   - **編集が必須の変数は無い**。既定の `latest`（最新版）でよければ、そのまま貼る
   - 大きな不具合のある版を避けたいなら `stable` にする（[実施手順](#実施手順)の手順 1 の `CC_CHANNEL` と同じ意味）
   - 最後に値を読み戻して確かめる
   - 変数はその PowerShell の中だけで有効。使うのはこの節の手順 4 だけ

   <details>
   <summary>補足: チャンネルの決まり方と、後から変える方法</summary>

   - この節の手順 4 のインストーラは、Claude Code の `claude install <チャンネル>` を動かす。`claude install` は、選んだチャンネルを自分のユーザーの設定（`%USERPROFILE%\.claude\settings.json`）の `autoUpdatesChannel` に書き、以後の自動の更新と `claude update` はそのチャンネルを追う（公式の文書の Install a specific version と Configure release channel。書かれることは Linux の native installer の 2.1.288 で確かめた）
   - 入れた後でチャンネルを変えるときは、`claude install stable`（戻すときは `claude install latest`）を打つ。Linux の 2.1.288 では、`latest` の 2.1.288 から `stable` の 2.1.285 に下がり、`autoUpdatesChannel` も `stable` になった（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）
   - セッションの中の `/config` の Auto-update channel でも変えられる（公式の文書。`stable` へ移るときは、今の版に留まるか、下げるかを聞かれる）
   - [実施手順](#実施手順)（AlmaLinux 10）の dnf の版では、チャンネルは repo ファイルの `baseurl` で決まり、`autoUpdatesChannel` は効かない

   </details>

1. Claude Code と Git for Windows があるか、64 ビットの PowerShell かを確かめる。

   ```powershell
   [Environment]::Is64BitProcess
   Get-Command claude -All -ErrorAction SilentlyContinue | Format-Table Source
   Test-Path "$env:USERPROFILE\.local\bin\claude.exe"
   Get-Command git -ErrorAction SilentlyContinue | Format-Table Source
   Test-Path 'C:\Program Files\Git\bin\bash.exe'
   ```

   - `True`、（claude は何も出ずに）`False`、`C:\Program Files\Git\cmd\git.exe`、`True` の順に出ればよい
   - 最初が `False` なら、32 ビットの PowerShell（x86）を開いている。閉じて、この節の手順 1 からやり直す
   - claude の行が `C:\Users\<WIN_USER>\.local\bin\claude.exe` だけで、3 つ目が `True` なら、もう native installer で入っている。この節の手順 4 は入れ直しになる（設定とログインは残る）
   - claude の行にほかの場所（WinGet・npm・scoop で入れたものなど）が出たら、そちらを先に外す（[注意点](#注意点)）
   - `WindowsApps` の `Claude.exe` が出たら、古い Claude Desktop が `claude` の名前を取っている。Claude Desktop を最新にする（公式の Troubleshoot installation）
   - git が出ず、最後が `False` なら、Git for Windows が無い。先に [git.md の Windows 11 で Git for Windows を入れる](git.md#windows-11-で-git-for-windows-を入れる)を通す（無くても Claude Code は動き、Bash のツールの代わりに PowerShell のツールを使う）

   <details>
   <summary>補足: 確かめていることと、Git for Windows の役割</summary>

   - `[Environment]::Is64BitProcess` は、インストーラが最初に見る値と同じ。スタートメニューの「Windows PowerShell (x86)」は、64 ビットの Windows でも 32 ビットで動く（公式の Troubleshoot installation）
   - native installer の置き場所は `%USERPROFILE%\.local\bin\claude.exe` に決まっている（公式の文書）。同じ名前のコマンドがほかにもあると、`PATH` の順で先のものが動き、版が食い違う（公式の Check for conflicting installations）
   - Git for Windows は任意（公式の Set up on Windows）。入っていれば、Claude Code は Git Bash を Bash のツールと Monitor のツールに使う。無ければ PowerShell のツールでコマンドを動かす
   - Claude Code が Git Bash を探す順は、`C:\Program Files\Git`・`C:\Program Files (x86)\Git` → `PATH` の `git` の `bin\bash.exe`（公式の Troubleshoot installation）。ほかの場所に入れたときは、設定の `env` の `CLAUDE_CODE_GIT_BASH_PATH` に `bash.exe` のパスを書く

   </details>

1. Claude Code を公式の native installer で入れる。

   ```powershell
   if (-not $CC_CHANNEL) {
     Write-Error '手順 2 の $CC_CHANNEL が空'
   } else {
     & ([scriptblock]::Create((Invoke-RestMethod -Uri https://claude.ai/install.ps1))) $CC_CHANNEL
   }
   ```

   - `Claude Code successfully installed!` と版（`Version: 2.1.288` など）の後に、最後に `Installation complete!`（前に絵文字の ✅ が付く）が出ればよい
   - `Setup notes:` に `Native installation exists but C:\Users\<WIN_USER>\.local\bin is not in your PATH.` と出ても、この節の手順 5 で足すので、ここでは何もしない
   - 赤いエラー（`Checksum verification failed`、`Failed to download binary` など）が出たら、そこで止まっている。[注意点](#注意点)と公式の [Troubleshoot installation](https://code.claude.com/docs/en/troubleshoot-install) を見る

   <details>
   <summary>補足: インストーラがすることと、irm | iex にしない理由</summary>

   `https://claude.ai/install.ps1` は `https://downloads.claude.ai/claude-code-releases/bootstrap.ps1` へ飛ぶ。2026-10-03 に読んだ中身（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）:

   - `claude-code-releases/latest` から一番新しい版の番号を取り、その版の `manifest.json` の `win32-x64`（arm64 の Windows なら `win32-arm64`）の sha256 と照らして、`claude.exe` を `%USERPROFILE%\.claude\downloads` に落とす。合わなければ `Checksum verification failed` で止まる
   - 落とした `claude.exe` で `claude install <チャンネル>` を動かし、終わったら落としたファイルを消す。`claude install` が、選んだチャンネルの版を `%USERPROFILE%\.local\share\claude\versions` に置き、`%USERPROFILE%\.local\bin\claude.exe` を作る
   - **インストーラは、`manifest.json` の GPG の署名も、`claude.exe` の Authenticode の署名も確かめない**（sha256 の照合だけで、`manifest.json` も同じ HTTPS のサーバーから取る）。署名はこの節の手順 7 で確かめる
   - `PATH` は変えない。`claude install` は、`PATH` に無ければ足し方を出すだけ（Windows の `claude.exe` の 2.1.288 の中に、`PATH` を書く処理の文字列は見当たらなかった）

   **公式の文書の既定の形 `irm https://claude.ai/install.ps1 | iex` にしない理由**:

   - `Invoke-Expression` はスクリプトを今のスコープで動かすので、スクリプトの先頭の `Set-StrictMode -Version Latest`・`$ErrorActionPreference = "Stop"`・`$ProgressPreference = 'SilentlyContinue'` が、入れた後の PowerShell にも残る（Linux の PowerShell 7.6.6 で確かめた。付録）。残ると、後から貼ったブロックで、未定義の変数がエラーになり、どのエラーでも止まるようになる
   - この手順の形（`& ([scriptblock]::Create(...)) <チャンネル>`）は、公式の文書がチャンネルを選ぶときに使う形で、別のスコープで動くので何も残らない。`irm` は `Invoke-RestMethod` の別名

   </details>

1. 自分のユーザーの PATH に `%USERPROFILE%\.local\bin` が無ければ足す。

   ```powershell
   & {
     $bin = "$env:USERPROFILE\.local\bin"
     $entries = @([Environment]::GetEnvironmentVariable('Path', 'User') -split ';' | Where-Object { $_ })
     if (-not (Test-Path -LiteralPath "$bin\claude.exe")) { Write-Error "中断: $bin\claude.exe が無い（この節の手順 4 で入っていない）"; return }
     if ($entries | Where-Object { $_.TrimEnd('\') -eq $bin }) {
       "PATH に $bin はもうある"
     } else {
       [Environment]::SetEnvironmentVariable('Path', (($entries + $bin) -join ';'), 'User')
       "PATH に $bin を足した"
     }
     [Environment]::GetEnvironmentVariable('Path', 'User') -split ';'
   }
   ```

   - `PATH に C:\Users\<WIN_USER>\.local\bin を足した`（か `はもうある`）の後に、自分のユーザーの PATH が 1 行ずつ出て、その中に `C:\Users\<WIN_USER>\.local\bin` があればよい
   - 何度貼ってもよい（あれば足さない）
   - 開いている PowerShell には効かない。この節の手順 6 で開き直す

   <details>
   <summary>補足: PATH の足し方</summary>

   - native installer は `PATH` を変えない（この節の手順 4 の補足）。公式の文書（Troubleshoot installation の Verify your PATH）は、Windows PowerShell に `[Environment]::SetEnvironmentVariable('PATH', "$currentPath;$env:USERPROFILE\.local\bin", 'User')` を貼る形で足す。この手順も同じ書き方で、あれば足さないようにしただけ
   - `SetEnvironmentVariable` の `User` は、レジストリの `HKCU\Environment` の `Path` に書き、開いているウィンドウに環境が変わったことを知らせる。そのため、この後に開いた PowerShell に効く（サインインし直さなくてよい）
   - 読むときに `%USERPROFILE%` のような書き方は展開され、書き戻すと展開した形（`C:\Users\<WIN_USER>\...`）で残る（.NET Framework の `Environment` の動き。Windows では確かめていない）。自分のユーザーの PATH なので、困ることは無いはず
   - 足すのは自分のユーザーの PATH だけで、システムの PATH（管理者の権限が要る）は変えない
   - 公式の文書は、画面からでも同じことができるとしている（システムのプロパティ → 環境変数 → ユーザー環境変数の `Path` → 新規）

   </details>

1. 開いている Windows PowerShell を閉じ、新しく開き直す。

   - ウィンドウを閉じ（`exit` と打ってもよい）、この節の手順 1 と同じように、管理者ではない Windows PowerShell を開く
   - 開き直した PowerShell は、この節の手順 5 で足した PATH と、Git for Windows を入れたばかりなら、その PATH も読む
   - この節の手順 2 の変数は、この後は使わない
   - **次の手順は、開き直した PowerShell に貼る**（前の PowerShell の `PATH` には、`.local\bin` が無いことがある）

1. Claude Code の場所・版・署名と、導入の状態を確かめる。

   ```powershell
   Get-Command claude -All | Format-Table Source
   claude --version
   $sig = Get-AuthenticodeSignature -LiteralPath "$env:USERPROFILE\.local\bin\claude.exe"
   '{0}  {1}' -f $sig.Status, $sig.SignerCertificate.Subject
   claude doctor
   ```

   - `claude` の場所は `C:\Users\<WIN_USER>\.local\bin\claude.exe` の 1 行だけ
   - `2.1.288 (Claude Code)` のように版が出る（`stable` を選んだら、`latest` より古い版）
   - 署名の行が `Valid  CN="Anthropic, PBC", O="Anthropic, PBC", ...` で始まればよい。`Valid` でなければ使わずに、[Windows 11 のロールバック](#windows-11-のロールバック)の手順 1・2 で消す
   - `claude doctor` に `Running: native (...)`・`Auto-updates: enabled`・`Auto-update channel: latest`（`stable` を選んだら `stable`）・`No installation issues found.` が出ればよい

   <details>
   <summary>補足: 署名と doctor の出力</summary>

   - 公式の文書（Binary integrity and code signing）は、Windows の `claude.exe` は「Anthropic, PBC」が署名し、`Get-AuthenticodeSignature` で確かめられるとしている
   - 2.1.288 の Windows の `claude.exe`（x64）の署名を Linux で読むと、署名者は DigiCert の Code Signing の CA が出した `CN="Anthropic, PBC"`（証明書の期限は 2026-10-20）で、DigiCert のタイムスタンプ（2026-10-02）が付いていた（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）。タイムスタンプがあるので、証明書の期限が切れた後も `Valid` のままのはず
   - `claude doctor` の行は、Linux の native installer の 2.1.288 の出力（同じ付録）から引いた。Windows では `Platform: win32-x64` になるはず（確かめていない）
   - 自動の更新は、Claude Code を起動したときと動いている間に確かめ、裏で入れて、次の起動から新しい版になる（公式の文書）。`claude doctor` の `Last update attempt` に最後の結果が出る

   </details>

1. `claude` を起動し、最初の設定とブラウザでのログインを行う。

   ```powershell
   claude
   ```

   - 文字の色の組み合わせ（`Choose the text style that looks best with your terminal`）を選んで Enter
   - `Select login method:` で `Claude account with subscription`（Pro / Max / Team / Enterprise）を選ぶ。Console のアカウントなら `Anthropic Console account`
   - 既定のブラウザ（Firefox）が開くので、claude.ai にログインして承認する。ブラウザが開かなければ、`c` で URL をコピーしてブラウザに貼る
   - ブラウザにコードが出たら、端末の `Paste code here if prompted >` に貼る
   - 端末に `Login successful` が出たら Enter。続く案内とフォルダーの信頼の確認（↓ で `Yes, I trust this folder`）に答えると、セッションが始まる
   - 前にログインしたことがある（`%USERPROFILE%\.claude` が残っている）なら、ログインは聞かれない。別のアカウントにするときは、セッションの中で `/login`
   - `/exit` で終える
   - **認証情報（トークン・コード）はこの文書に載せない**
   - **次の手順は、`/exit` で Claude Code を終えてから貼る**（続けて貼ると Claude Code への入力として食われる）

   <details>
   <summary>補足: ログインの流れと、ログインの情報の置き場所</summary>

   - 公式の文書（Authentication）: 最初の起動でブラウザが開く。`ANTHROPIC_API_KEY` を設定していると、ブラウザの代わりにその鍵を使ってよいか 1 度だけ聞かれる。ブラウザが Claude Code の待ち受けに戻れないとき（SSH のセッションなど）は、ブラウザに出たコードを端末に貼る
   - 画面の文言は、公式の文書と Windows の `claude.exe`（2.1.288）の中の文字列から引いた。Windows では画面を見ていない
   - 開き直した PowerShell は `C:\Users\<WIN_USER>` で始まる。ホームのフォルダーの信頼は保存されない（[windows-claude-remote-control.md](windows-claude-remote-control.md)）ので、起動のたびに聞かれる。作業したいディレクトリに `cd` してから起動してもよい
   - ログインの情報は `%USERPROFILE%\.claude\.credentials.json` に置かれ、ユーザーのプロファイルのアクセス権を引き継ぐ（公式の文書）
   - Remote Control（[windows-claude-remote-control.md](windows-claude-remote-control.md)）は claude.ai のアカウントでのログインが要る（API キーでは使えない）

   </details>

1. ログインしたかを確かめる。

   ```powershell
   claude auth status --text
   ```

   - `Login method: Claude Max account` のように、プランの行が出ればよい（ほかにメールアドレスと組織の行も出る）
   - `Not logged in. Run claude auth login to authenticate.` なら、ログインしていない。この節の手順 8 をやり直す
   - このコマンドの後ろに、別のコマンドを続けて貼らない（AlmaLinux 10 では、ブラケットペースト無しで、後ろに貼った行を読んで捨てた。[使い方の基本](#使い方の基本)）

---

## Windows 11 の更新

- **native installer の Claude Code は、自分で更新する**: 起動したときと動いている間に新しい版を確かめ、裏で入れて、次の起動から新しい版になる（公式の文書）
- 追う版は、[Windows 11 で使う](#windows-11-で使う)の手順 2 で選んだチャンネル。動いているセッションは、終えるまで古い版のまま
- 待たずに上げるときは、この節の手順 1 を Windows PowerShell（5.1）に貼る

1. Claude Code をすぐに更新する。

   ```powershell
   claude update
   claude --version
   ```

   - 新しい版があれば `Successfully updated from <古い版> to version <新しい版>`、無ければ `Claude Code is up to date (2.1.288)` のように出る
   - 更新の後に `claude` が見つからなくなったら、[注意点](#注意点)の `claude.exe.old.*` の項を見る

   <details>
   <summary>補足: 更新の動き</summary>

   - 出力の文言は公式の文書（Update manually）から。Linux の native installer の 2.1.288 では、`Current version: 2.1.288`・`Checking for updates to latest version...`・`Claude Code is up to date (2.1.288)` と出た（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）
   - Windows では、動いている `claude.exe` を同じフォルダーの `claude.exe.old.<数字>` に名前を変えてから、新しい版を置く（公式の Troubleshoot installation）
   - 新しい版は `%USERPROFILE%\.local\share\claude\versions` に置かれる。古い版は、使っているものと新しい 2 つを残して消される（公式の文書の Install on network storage）
   - [windows-claude-remote-control.md](windows-claude-remote-control.md) の実機では、検証の間に、自動の更新で 2.1.283 から 2.1.286 に上がった

   </details>

---

## Windows 11 のロールバック

- 上から順に、Windows PowerShell（5.1）に貼る（変数は使わない）
- 公式の文書（Uninstall Claude Code の Native installation と Remove configuration files）の手順に、本書で見つけた置き場所（更新の名残・キャッシュ・ロック）と `PATH` を足したもの
- [windows-claude-remote-control.md](windows-claude-remote-control.md) のタスクがあれば、先にそのロールバックを行う
- この節の手順 1〜3 では、設定・履歴・ログインの情報（`%USERPROFILE%\.claude`、`%USERPROFILE%\.claude.json`）と、プロジェクトの `.claude` と `.mcp.json` は残る

> [!CAUTION]
> **この節の手順 4 で `%USERPROFILE%\.claude` と `%USERPROFILE%\.claude.json` を消すと、設定・許可済みのツール・MCP サーバーの定義・セッションの履歴・ログインの情報・ディレクトリの信頼がすべて消える**。入れ直すかもしれないなら、手順 4 は行わない。

1. 動いている Claude Code と、Remote Control のタスクが無いことを確かめる。

   ```powershell
   Get-Process -Name claude -ErrorAction SilentlyContinue | Where-Object Path -like "$env:USERPROFILE\.local\*" | Format-Table Id, Path
   Get-ScheduledTask -TaskName 'claude-remote-control' -ErrorAction SilentlyContinue | Format-Table TaskName, State
   ```

   - どちらも何も出なければよい
   - プロセスが出たら、その Claude Code を `/exit` で終える（動いている `claude.exe` は消せない）
   - タスクが出たら、[windows-claude-remote-control.md のロールバック](windows-claude-remote-control.md#ロールバック)を先に行う

1. Claude Code の実行ファイルと、版・キャッシュ・ロックのフォルダーを消す。

   ```powershell
   Remove-Item -Path "$env:USERPROFILE\.local\bin\claude.exe", "$env:USERPROFILE\.local\bin\claude.exe.old.*" -Force -ErrorAction SilentlyContinue
   Remove-Item -LiteralPath "$env:USERPROFILE\.local\share\claude", "$env:USERPROFILE\.local\state\claude", "$env:USERPROFILE\.cache\claude" -Recurse -Force -ErrorAction SilentlyContinue
   Test-Path "$env:USERPROFILE\.local\bin\claude.exe", "$env:USERPROFILE\.local\share\claude"
   Get-ChildItem -LiteralPath "$env:USERPROFILE\.local\bin" -Force -ErrorAction SilentlyContinue | Format-Table Name
   ```

   - `False` が 2 行出ればよい
   - `True` が出たら、`claude.exe` がまだ動いている。この節の手順 1 からやり直す
   - 最後の一覧が空なら、`.local\bin` にはほかのものが無い（この節の手順 3 で PATH から外せる）

   <details>
   <summary>補足: 消すもの</summary>

   - 公式の文書の Windows PowerShell の手順が消すのは、`%USERPROFILE%\.local\bin\claude.exe` と `%USERPROFILE%\.local\share\claude`（版のファイル）の 2 つ
   - 本書は、更新の名残の `claude.exe.old.*`（[Windows 11 の更新](#windows-11-の更新)の補足）と、`%USERPROFILE%\.local\state\claude`（ロック）・`%USERPROFILE%\.cache\claude`（更新の途中のファイル）も消す。この 2 つは、Linux の native installer の 2.1.288 が作ったフォルダーと、`claude.exe` の中の置き場所の決め方（`XDG_*` が無ければホームの下）から足したもので、Windows では確かめていない
   - 空になった `%USERPROFILE%\.local\share` などは残る

   </details>

1. [Windows 11 で使う](#windows-11-で使う)の手順 5 で足したときだけ、PATH から `.local\bin` を外す。

   ```powershell
   & {
     $bin = "$env:USERPROFILE\.local\bin"
     if (Get-ChildItem -LiteralPath $bin -Force -ErrorAction SilentlyContinue) { Write-Error "中断: $bin にほかのファイルがある（ほかのツールが使っている）"; return }
     $entries = @([Environment]::GetEnvironmentVariable('Path', 'User') -split ';' | Where-Object { $_ })
     $rest = @($entries | Where-Object { $_.TrimEnd('\') -ne $bin })
     if ($rest.Count -lt $entries.Count) { [Environment]::SetEnvironmentVariable('Path', ($rest -join ';'), 'User') }
     Remove-Item -LiteralPath $bin -ErrorAction SilentlyContinue
     [Environment]::GetEnvironmentVariable('Path', 'User') -split ';'
   }
   ```

   - 自分のユーザーの PATH が 1 行ずつ出て、その中に `C:\Users\<WIN_USER>\.local\bin` が無ければよい
   - `中断:` が出たら、`.local\bin` をほかのツール（uv など）も使っている。PATH は外さない

1. 完全に消すときだけ、設定・履歴・ログインの情報を消す（取り戻せない）。

   ```powershell
   Remove-Item -LiteralPath "$env:USERPROFILE\.claude" -Recurse -Force
   Remove-Item -LiteralPath "$env:USERPROFILE\.claude.json" -Force
   Test-Path "$env:USERPROFILE\.claude", "$env:USERPROFILE\.claude.json"
   ```

   - `False` が 2 行出ればよい
   - Claude Desktop・VS Code の拡張機能・JetBrains のプラグインが入っていると、次に動いたときに `%USERPROFILE%\.claude` がまた作られる（公式の文書。全部消すなら、先にそれらを外す）
   - プロジェクトの `.claude` と `.mcp.json` は、それぞれのプロジェクトのディレクトリで手で消す

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 と Windows 11 に [Claude Code](https://code.claude.com/docs/) の CLI の最新版を入れる
  - AlmaLinux 10 では **dnf 管理で**入れ、`dnf upgrade` で追従できるようにする
  - Windows 11 では公式の native installer で入れ、Claude Code 自身の自動の更新に任せる
- **進め方**: どちらも Anthropic の公式の配布物を使い、npm も Node.js も使わない。**読者が書き換えるのは変数（チャンネル）だけ**で、既定のままで通る
  - **AlmaLinux 10**（[実施手順](#実施手順)）: 公式の RPM リポジトリの `latest` チャンネルを 1 つ足して `dnf install` する
  - **Windows 11**（[Windows 11 で使う](#windows-11-で使う)）: 管理者ではない Windows PowerShell 5.1 で公式の `install.ps1` を動かし、`%USERPROFILE%\.local\bin\claude.exe` に入れる。`PATH` は本書で足し、署名を確かめてから、ブラウザでログインする
- **状態（AlmaLinux 10）**: **実機で本実行済み（`stable`、2026-09-20）**。既定の `latest` は x86_64 のコンテナのみ（2026-09-26）
  - 実機（aarch64）: `stable` チャンネルの repo ファイルを置いて `dnf install claude-code` し、`claude-code-2.1.267-1.aarch64` が入っている。認証も済んでいて常用中（本書の初版は、そのホストの Claude Code で書いた）
  - 2026-09-22: 同じ OS の aarch64 のコンテナで、`stable` の手順 2〜4 を通し直した
  - 2026-09-26: 既定を `latest` に変え、x86_64 のコンテナで手順 1〜4・[更新](#更新)・[stable チャンネルに切り替える（任意）](#stable-チャンネルに切り替える任意)・[ロールバック](#ロールバック)を、この文書のコードブロックのまま通した（`claude-code-2.1.283-1.x86_64`）
  - **確認していないこと**: 実機（aarch64）での `latest`（aarch64 にも同じ版があることはメタデータで確認）、コンテナでの認証（手順 5）、認証後の `claude doctor`
  - 2026-09-28: 手順 2 と、[stable チャンネルに切り替える（任意）](#stable-チャンネルに切り替える任意)の手順 1・4のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../README.md#記法)）
    - 中のコマンドは変えていない。囲んだ形は構文の検査だけで、流していない
  - 2026-10-01: [使い方の基本](#使い方の基本)を足した（[付録](#付録-使い方の基本の検証記録2026-10-01)）
    - ログインの要るもの（`-p`・`-c`・`-r`・`-n`・`--model`・`--permission-mode`・`--add-dir`・`--allowedTools`・`--max-turns`・`--output-format json`）は、クラウドのホスト（Ubuntu 24.04）にあったログイン済みの Claude Code 2.1.287 で確かめた
    - ログインの要らないもの（`doctor`・`auth status`・`mcp`・`update`、ログインしていないときの `-p` と `remote-control`）は、x86_64 の AlmaLinux 10 のコンテナに手順 2〜4 で入れた `claude-code-2.1.287-1` で確かめた
    - **確認していないこと**: セッションの中の操作（キーとスラッシュコマンド）、`-r` の一覧から選ぶ画面、`claude auth login` / `logout`、`claude remote-control` の接続
  - 2026-10-02: 手順 2 の `{ … }` を、`CC_CHANNEL` が空なら何もせずに止める `if … fi` にした（中のコマンドは変えていない）
    - それまでは、ヒアドキュメントの中の `${CC_CHANNEL:?…}` が `sudo tee` しか止めず（[gnome-power.md 手順 3](gnome-power.md#実施手順) の補足）、repo ファイルは書かれずに、後ろの `cat` が `No such file or directory` を出した
    - 直した形は、擬似端末の対話の bash にブラケットペースト無しで、変数を空にしたときと値を入れたときの 1 回ずつ貼って確かめた（`sudo` はそのまま実行するスタブ、`/etc` は使い捨てのディレクトリに読み替えた）
- **状態（Windows 11）**: **Windows の実機では流していない（未検証。2026-10-03 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）:
    - 公式の文書: Windows の要件（Git for Windows は任意、管理者の権限は要らない）、置き場所、チャンネル、更新、アンインストール、`PATH` の足し方、署名
    - インストーラ: `install.ps1`（`bootstrap.ps1`）の中身。sha256 は照らすが、署名は確かめず、`PATH` も変えない
    - 配布物: 2.1.288 の `manifest.json` の GPG の署名、Windows の `claude.exe`（x64）の sha256 と Authenticode の署名者・タイムスタンプ（Linux で読んだだけ）、`claude.exe` の中の文字列（`PATH` の案内、置き場所、更新のときの名前の変え方）
    - Linux の native installer の同じ版（2.1.288）: `claude install latest` / `stable` で書かれる設定と置き場所、`claude doctor`・`claude update` の出力
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査。[Windows 11 で使う](#windows-11-で使う)の手順 4 は、本物の `install.ps1` を Linux の pwsh で動かし、`claude.exe` を落として sha256 が合うところまで通した（Windows の実行ファイルを動かすところで止まる）。同じ節の手順 5 と[Windows 11 のロールバック](#windows-11-のロールバック)の手順 2〜4 は、自分のユーザーの PATH とフォルダーを偽物にして流した（[付録](#付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
  - 別の手順書の実機（[windows-claude-remote-control.md](windows-claude-remote-control.md) の Windows 11 Pro 26H2）には、native installer の 2.1.286 が `C:\Users\<WIN_USER>\.local\bin\claude.exe` に入っていて、claude.ai にログインしてあった（2026-10-01。この節の手順で入れたものではない）
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
| OS | Windows 11（[Windows の OpenSSH サーバー](windows-openssh-server.md)の PC は 25H2・26H2）。x64 |
| PowerShell | Windows PowerShell 5.1（管理者でなくてよい） |
| Git for Windows | [git.md](git.md#windows-11-で-git-for-windows-を入れる)で入れたもの（`C:\Program Files\Git`） |
| 既定のブラウザ | Firefox（[firefox.md](firefox.md#windows-11-で使う)） |
| Claude Code | 2.1.288（2026-10-02、`latest`。`stable` は 2.1.285） |

> [!NOTE]
> 環境固有の値は**変数**で書いてある。AlmaLinux 10 は[手順 1](#実施手順)のシェル変数、Windows 11 は[Windows 11 で使う](#windows-11-で使う)の手順 2 の PowerShell の変数に 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
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

AlmaLinux 10 の実機（2026-09-20）の状態。検証コンテナは公式イメージのまま（Claude Code も追加のリポジトリも無し）。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)の手順 3 で確かめる。

| 項目 | 状態 |
|---|---|
| Claude Code | 未導入（`claude` 無し、`~/.claude` も無し） |
| Node.js / npm | 未導入。`nodejs` は appstream に 22.23.2 があるが入れていない |
| 有効な追加リポジトリ | epel、crb、raspberrypi、gh-cli（claude-code はまだ無し） |
| `~/.local/bin` | PATH には入っているがディレクトリは未作成 |

### 選択した方針

Linux に Claude Code を入れる経路は 3 つある（2026-09-22 時点の[公式ドキュメント](https://code.claude.com/docs/en/setup)）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **公式 dnf リポジトリ** | `downloads.claude.ai/claude-code/rpm/{stable,latest}`。aarch64 の RPM があり、署名鍵で検証される。更新は `dnf upgrade`（**自動更新はしない**） | **採用**（他のツールと同じ dnf 管理に揃う） |
| ネイティブインストーラ（`curl -fsSL https://claude.ai/install.sh \| bash`） | `~/.local/bin/claude` に入り、**バックグラウンドで自動更新する**。root 不要。ただし更新経路が dnf の外になり、`~/.local/share/claude/versions/` に版が積まれる | 不採用（自動更新が要るなら有力） |
| npm（`npm install -g @anthropic-ai/claude-code`） | Node.js 22 以上が要る。このホストに Node.js は無く、そのために入れることになる。中身は同じネイティブバイナリ | 不採用 |

- どれを選んでも入るのは同じネイティブバイナリで、Node.js は実行時に使わない
- `ripgrep` は同梱されている（Alpine など musl 系以外では別途入れなくてよい）

**`stable` と `latest` の違い**:

- `stable` は 1 週間ほど遅れて、大きな不具合のある版を飛ばす
- `latest` は出た版をすぐ配る
- リポジトリが別 URL になっているだけで、切り替えは `baseurl` の書き換え（[stable チャンネルに切り替える（任意）](#stable-チャンネルに切り替える任意)）

**既定を `latest` にした理由**:

- 本書の目的が最新版を入れることだから。`stable` のままだと 1 週間ほど遅れる
- ネイティブインストーラ（`install.sh` が取ってくる `bootstrap.sh`）も、まず `claude-code-releases/latest` が指す版を取ってくる（スクリプトを読んで確認。実行はしていない）
- 不具合に当たったときの逃げ道として、`stable` へ下げる節を用意した

2026-09-26 に見た各チャンネルの最新版（x86_64 / aarch64 とも同じ）:

| 配布元 | `stable` | `latest` |
|---|---|---|
| RPM リポジトリ（`rpm/<チャンネル>` の repodata） | `2.1.274-1` | `2.1.283-1` |
| リリースのポインタ（`claude-code-releases/<チャンネル>`） | `2.1.274` | `2.1.283` |

Windows 11 で Claude Code を入れる経路を比べた（2026-10-03 時点。中身はどれも公式の `claude.exe`）:

| 経路 | 状況 | 採否 |
|---|---|---|
| **公式の native installer（PowerShell の `install.ps1`）** | `%USERPROFILE%\.local\bin\claude.exe` に入り、管理者の権限は要らない。Claude Code 自身が裏で更新する（チャンネルは `latest` / `stable`）。sha256 は照らすが署名は確かめず、`PATH` も足さない | **採用**（公式が勧める形。[windows-claude-remote-control.md](windows-claude-remote-control.md) の前提もこの形） |
| 公式の native installer（CMD の `install.cmd`） | 同じものを CMD から入れる | 不採用（本書のブロックは Windows PowerShell にそろえる） |
| WinGet の `Anthropic.ClaudeCode` | `portable` で、公式の配布物の `claude.exe` をそのまま置く。自分では更新しない（`winget upgrade`。`CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE=1` で Claude Code に走らせられるが、動いている間は置き換えられないことがある）。2026-10-03 の winget-pkgs は 2.1.286 で、`latest` の 2.1.288 より遅れていた | 不採用（版が遅れ、更新を別に回すことになる） |
| scoop の `main/claude-code` | 2.1.288（公式の配布物と同じ sha256）。更新は `scoop update` | 不採用（公式の文書の経路ではなく、Claude Code 自身の更新との関係を確かめていない） |
| Chocolatey の `claude-code` | 2.1.285（コミュニティの保守） | 不採用 |
| npm（`@anthropic-ai/claude-code`） | Node.js が要る。PowerShell の実行ポリシーが、npm の作る `.ps1` の起動を止めることがある（公式の Troubleshoot installation） | 不採用 |
| WSL の中に Linux の手順で入れる | Linux の道具を使うなら有力（サンドボックスは WSL 2 だけ）。Windows の `claude.exe` とは別のもの | 不採用（Windows のプロジェクトで使い、[windows-claude-remote-control.md](windows-claude-remote-control.md) の前提にもなるため） |

- **Windows 11 の手順もこの文書に置いた**: 同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、OS ごとにファイルを分けない。手順が OS で違うので、[syncthing.md](syncthing.md) と同じく後ろの節に分けた
- **インストーラは `& ([scriptblock]::Create(...)) <チャンネル>` の形で動かす**: 公式の文書がチャンネルを選ぶときに使う形。既定の `irm … | iex` は、インストーラの設定（`Set-StrictMode` など）を、入れた後の PowerShell に残す（[Windows 11 で使う](#windows-11-で使う)の手順 4 の補足）
- **`PATH` は本書で足す**: インストーラも `claude install` も足さず、足し方を出すだけなので、公式の文書の Verify your PATH と同じ書き方で、自分のユーザーの PATH に足す（同じ節の手順 5）
- **署名は入れた後に確かめる**: インストーラは sha256 しか照らさないので、公式の文書の `Get-AuthenticodeSignature` で `claude.exe` の署名を見る（同じ節の手順 7）。インストーラの中で動く前の確かめにはならない
- **Git for Windows を前提にした**: 公式の文書では任意だが、Claude Code の Bash のツール（と Monitor のツール）が Git Bash を使う。[Windows 11 の初期設定](windows-setup.md)のリードの順で、先に入れる

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

### 注意点

- **`latest` は不具合のある版もそのまま届く**: `stable` なら飛ばされる版も入る。困ったら [stable チャンネルに切り替える（任意）](#stable-チャンネルに切り替える任意)
- **自動更新しない**: ネイティブインストーラ版と違い、dnf 版は自分では更新しない
  - `CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE=1` は Homebrew / WinGet 向けで、apt / dnf / apk は root 権限が要るため対象外
- **更新の通知が先に来ることがある**: リポジトリに新しい版が届く前に「更新がある」と言われることがある。その場合は時間をおいて `sudo dnf upgrade claude-code`
- **`claude` が 2 つ入ると混乱する**: ネイティブインストーラや npm で入れたものが `~/.local/bin/claude` にあると、PATH の順序でそちらが勝つ。`command -v claude` と `claude doctor` で確認する
- **アカウントが要る**: 無料の claude.ai プランでは使えない
- **設定ファイルは残る**: `dnf remove` しても `~/.claude` は消えない
- **`-p` は許可を聞けない**: 許可の要るツールは断られ、JSON の `permission_denials` に残る。要るものは `--allowedTools` で渡す（[使い方の基本](#使い方の基本)）
- **SSH を切ると止まる**: SSH のシェルで起動した `claude` は、切断で止まる。動かし続けるなら tmux の中で起動する（[tmux.md の任意節](tmux.md#claude-code-を-tmux-の中で動かす任意)）
- **Windows 11 の注意点**
  - **`PATH` は自分で足す**: インストーラも `claude install` も足さない（[Windows 11 で使う](#windows-11-で使う)の手順 5）。足さないと、開き直した PowerShell でも `claude` が見つからない
  - **Windows PowerShell (x86) では入らない**: `Claude Code does not support 32-bit Windows` で止まる。x86 の付かない「Windows PowerShell」で入れ直す
  - **`claude` が 2 つ入ると混乱する**: WinGet・npm・scoop で入れたものが `PATH` の先にあると、そちらが動く。`Get-Command claude -All` で確かめ、`winget uninstall Anthropic.ClaudeCode` や `npm uninstall -g @anthropic-ai/claude-code` で外す。古い Claude Desktop は `WindowsApps` に `Claude.exe` を置き、`claude` で Desktop が開くので、最新にする（公式の Troubleshoot installation）
  - **更新の後に `claude` が見つからないとき**: Windows の更新は、`claude.exe` を `claude.exe.old.<数字>` に名前を変えてから新しい版を置く。置けず、名前も戻せなかったときは `claude.exe` が無くなる。公式の文書は、一番新しい `claude.exe.old.*` の名前を戻す（`Get-ChildItem "$env:USERPROFILE\.local\bin\claude.exe.old.*" | Sort-Object Name | Select-Object -Last 1 | Rename-Item -NewName claude.exe`）か、入れ直すとしている
  - **`The process cannot access the file` で止まるとき**: 前のインストーラが動いているか、ウイルス対策が `%USERPROFILE%\.claude\downloads` のファイルを調べている。ほかの PowerShell を閉じ、そのフォルダーを消してから入れ直す（公式の Troubleshoot installation）
  - **`irm … | iex` で入れた PowerShell には、インストーラの設定が残る**: `Set-StrictMode -Version Latest` などが残るので、その窓は閉じて開き直す（[Windows 11 で使う](#windows-11-で使う)の手順 4 の補足）
  - **ログインの情報は `%USERPROFILE%\.claude\.credentials.json`**: パスワードと同じ重みで扱い、ログや issue に貼らない
  - **Windows PowerShell 5.1 のパイプ**: `<コマンド> | claude -p` で日本語を渡すと化けるはず（[使い方の基本](#使い方の基本)の非対話の注意）

### 参照

- [Advanced setup — Claude Code Docs](https://code.claude.com/docs/en/setup) — dnf / apt / apk リポジトリの設定、チャンネル、アンインストール、署名の検証。Windows 11 の節は、Set up on Windows・Install a specific version（チャンネルを選ぶ形）・Update manually・Binary integrity and code signing・Uninstall の Windows PowerShell
- [Troubleshoot installation and login — Claude Code Docs](https://code.claude.com/docs/en/troubleshoot-install) — インストールが失敗したときの切り分け。Windows 11 の節は、Verify your PATH・Check for conflicting installations・`claude.exe` missing after an update on Windows・Claude Code does not support 32-bit Windows・Git Bash を探す順
- [CLI reference — Claude Code Docs](https://code.claude.com/docs/en/cli-reference) — `claude` のオプションとサブコマンド（[使い方の基本](#使い方の基本)）
- [Interactive mode](https://code.claude.com/docs/en/interactive-mode) / [Commands](https://code.claude.com/docs/en/commands) — セッションの中のキーとスラッシュコマンド
- [Run Claude Code programmatically](https://code.claude.com/docs/en/headless) — `-p` と `--output-format`
- [Connect Claude Code to tools via MCP](https://code.claude.com/docs/en/mcp) — `claude mcp` とスコープ
- [Continue local sessions from any device with Remote Control](https://code.claude.com/docs/en/remote-control) — `claude remote-control`
- `man dnf.conf`（`gpgcheck`、`baseurl`）
- [Authentication — Claude Code Docs](https://code.claude.com/docs/en/authentication) — 最初の起動のログインの流れと、Windows のログインの情報の置き場所（`.credentials.json`）
- [winget-pkgs の Anthropic.ClaudeCode](https://github.com/microsoft/winget-pkgs/tree/master/manifests/a/Anthropic/ClaudeCode) / [scoop の main/claude-code](https://github.com/ScoopInstaller/Main/blob/master/bucket/claude-code.json) — Windows 11 で採らなかった経路の定義
- [about_Preference_Variables（`$OutputEncoding`）— Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-5.1) — Windows PowerShell 5.1 が native のコマンドへパイプで渡す文字コード
- [Windows 11 の初期設定](windows-setup.md) — 同じ PC で先に行う設定（貼り付けの設定と、この文書を通す順）
- [windows-claude-remote-control.md](windows-claude-remote-control.md) — Windows 11 の節で入れた Claude Code を、SSH の切断後も Remote Control で使う

---

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
- 新しいコンテナで、この文書の折り畳みの外にある bash のコードブロック 12 個（手順 1〜4、[更新](#更新)の手順 1、[stable チャンネルに切り替える（任意）](#stable-チャンネルに切り替える任意)の手順 1〜4、[ロールバック](#ロールバック)の手順 1〜3）を、上から順にそのまま抜き出したスクリプトを流した
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

2.1.288 の `manifest.json`（`buildDate` は 2026-10-02T17:00:28Z）の署名を、`https://downloads.claude.ai/keys/claude-code.asc` の鍵（fingerprint `31DD DE24 DDFA B679 F42D  7BD2 BAA9 29FF 1A7E CACE`。[実施手順](#実施手順)の手順 3 の dnf の鍵と同じ）で確かめた（gpg 2.4.4）:

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

- 署名の中の証明書を Linux の PowerShell 7.6.6 の `X509Certificate2` に読ませると、`Subject` は `CN="Anthropic, PBC", O="Anthropic, PBC", L=San Francisco, S=California, C=US, SERIALNUMBER=4860621, ...` だった（名前に `,` があるので引用符で囲まれる）。[Windows 11 で使う](#windows-11-で使う)の手順 7 の箇条書きは、この形から引いた
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

**[Windows 11 で使う](#windows-11-で使う)の手順 2・4**: 文書から抜き出したブロックを、`$env:USERPROFILE` を一時的なディレクトリにして、そのまま流した（本物の `install.ps1` を取って動かす）:

- 手順 2 は `CC_CHANNEL = latest` を出した
- `$CC_CHANNEL` を空にした手順 4 は、`手順 2 の $CC_CHANNEL が空` のエラーだけを出し、何も取らなかった
- `latest` の手順 4 は、版（2.1.288）と `manifest.json` を取り、`win32-x64` の `claude.exe` を `%USERPROFILE%\.claude\downloads` に落として sha256 が合い、`Setting up Claude Code...` まで進んだ。その後の `claude.exe install latest` は、Linux では Windows の実行ファイルを動かせないので、`failed to run` のエラーで止まった。落としたファイルは消え、空の `.claude\downloads` が残った
- 流した後の PowerShell は、`$ErrorActionPreference` が `Continue`、`$ProgressPreference` が `Continue`、未定義の変数を読んでもエラーにならなかった（インストーラの設定が残っていない）

**`irm … | iex` との違い**: `install.ps1` と同じ先頭（`param` と `Set-StrictMode -Version Latest`・`$ErrorActionPreference = "Stop"`・`$ProgressPreference = "SilentlyContinue"`）の文字列を `iex` に渡すと、流した後も `$ErrorActionPreference` が `Stop`、`$ProgressPreference` が `SilentlyContinue` のままで、未定義の変数を読むと `VariableIsUndefined` のエラーになった。`& ([scriptblock]::Create(...)) stable` では何も残らず、位置引数の `stable` が `$Target` に入った。Windows PowerShell 5.1 では確かめていない

**[Windows 11 で使う](#windows-11-で使う)の手順 5 と[Windows 11 のロールバック](#windows-11-のロールバック)の手順 2〜4**: 文書から抜き出したブロックの `[Environment]::GetEnvironmentVariable('Path', 'User')` と `SetEnvironmentVariable('Path', …, 'User')` を、値を覚えておく偽物に置き換え（Linux の .NET は `User` の環境変数を持たない）、`$env:USERPROFILE` を一時的なディレクトリにして流した（パスの `\` は Linux の pwsh がそのまま区切りとして扱った）:

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
