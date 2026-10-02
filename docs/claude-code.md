# Claude Code 最新版インストール手順（AlmaLinux 10 / 公式 dnf リポジトリ）

## 実施手順

> [!IMPORTANT]
> - **すべて対象ホスト上で実行する**。手順 5 の認証だけブラウザを使う
> - **手順 3 には対話入力がある**（トランザクション表と署名鍵の取り込みの確認）。答えてから手順 4 を貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: `claude` のコマンドラインは[使い方の基本](#使い方の基本)。SSH を切っても動かし続ける（Remote Control も）なら [tmux.md の任意節](tmux.md#claude-code-を-tmux-の中で動かす任意)。以後は[更新](#更新)・[ロールバック](#ロールバック)。最新版で不具合に当たったら [stable チャンネルに切り替える（任意）](#stable-チャンネルに切り替える任意)

> [!WARNING]
> 既定の `latest` チャンネルは **x86_64 のコンテナでのみ検証した**。実機（aarch64）で本実行したのは `stable` チャンネル（[対象と検証環境](#対象と検証環境)）。

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
- SSH を切っても動かし続けるには、tmux の中で起動する（[tmux.md の任意節](tmux.md#claude-code-を-tmux-の中で動かす任意)）

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
| `claude update` | dnf で入れた版では更新しない（`Claude is managed by a package manager.`）。[更新](#更新)の `sudo dnf upgrade claude-code` を使う |
| `claude remote-control --name <名前> --spawn same-dir` | Remote Control のサーバーを始める（[tmux.md の任意節](tmux.md#claude-code-を-tmux-の中で動かす任意)。Windows は [windows-claude-remote-control.md](windows-claude-remote-control.md)）。本書では、ログインしていないときのエラーだけを確かめた |

- `local` と `user` の MCP サーバーは `~/.claude.json` に書かれる（`local` はディレクトリごとの欄）
- **`claude auth status` は、端末に残った後ろの行を読んで捨てる**: ブラケットペースト無しで、ほかのコマンドと続けて貼るときは最後に置く（`claude --version` と `claude doctor` では捨てなかった）
- ログインとログアウトは、セッションの中の `/login`・`/logout` か、`claude auth login`・`claude auth logout`（本書では試していない）

---

## 更新

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

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 に [Claude Code](https://code.claude.com/docs/) の CLI の最新版を **dnf 管理で**入れ、`dnf upgrade` で追従できるようにする
- **進め方**: Anthropic が公式に配っている RPM リポジトリの `latest` チャンネルを 1 つ足して `dnf install` する。**読者が書き換えるのは冒頭の変数ブロック（チャンネル）だけ**。npm も Node.js も使わない
- **状態**: **実機で本実行済み（`stable`、2026-09-20）**。既定の `latest` は x86_64 のコンテナのみ（2026-09-26）
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

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${CC_CHANNEL}` | 追従するチャンネル。`baseurl` の末尾になる | `latest` / `stable` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`2.1.283` など）は実行日によって変わる。`<作業したいディレクトリ>` のような `<...>` を含むコマンドは bash のコードブロックに置いていない。
>
> **API キー・OAuth トークン・認証時のコードは書かない。** 鍵の fingerprint は公開情報なので本文に書いてある。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

実機（2026-09-20）の状態。検証コンテナは公式イメージのまま（Claude Code も追加のリポジトリも無し）。

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

### 完了時点の状態

実機（`stable`、2026-09-20）:

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

### 参照

- [Advanced setup — Claude Code Docs](https://code.claude.com/docs/en/setup) — dnf / apt / apk リポジトリの設定、チャンネル、アンインストール、署名の検証
- [Troubleshoot installation and login — Claude Code Docs](https://code.claude.com/docs/en/troubleshoot-install) — インストールが失敗したときの切り分け
- [CLI reference — Claude Code Docs](https://code.claude.com/docs/en/cli-reference) — `claude` のオプションとサブコマンド（[使い方の基本](#使い方の基本)）
- [Interactive mode](https://code.claude.com/docs/en/interactive-mode) / [Commands](https://code.claude.com/docs/en/commands) — セッションの中のキーとスラッシュコマンド
- [Run Claude Code programmatically](https://code.claude.com/docs/en/headless) — `-p` と `--output-format`
- [Connect Claude Code to tools via MCP](https://code.claude.com/docs/en/mcp) — `claude mcp` とスコープ
- [Continue local sessions from any device with Remote Control](https://code.claude.com/docs/en/remote-control) — `claude remote-control`
- `man dnf.conf`（`gpgcheck`、`baseurl`）

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
