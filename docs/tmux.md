# tmux インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

- [検証記録](verification/tmux.md)・[参考資料](reference/tmux.md)

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。Homebrew の導入・管理は一般ユーザーで行い、tmux のセッションもそのユーザーのものにする
> - **手順 1・3・4 には対話入力がある**（手順 1 は依存を入れるかの `[y/n]`、手順 3・4 は tmux の画面が開く）

- 上から順にコードブロックを貼る
- 手順の後: キーとコマンドは[使い方の基本](#使い方の基本)。マウスでさかのぼるなら[設定ファイル（任意）](#設定ファイル任意)。SSH を切っても Claude Code を動かし続けるなら[Claude Code を tmux の中で動かす（任意）](#claude-code-を-tmux-の中で動かす任意)。以後は[更新](#更新)・[ロールバック](#ロールバック)

1. brew で tmux を入れる。

   ```bash
   brew install tmux
   ```

   - 依存が付くときは、入れるものの一覧の後に `Do you want to proceed with the installation? [y/n]` と聞かれる。`y`（Enter は要らない）
   - 最後の caveat に、例の設定ファイル（`example_tmux.conf`）の場所が出る。本書では使わない
   - **次の手順は、`y` と答えてプロンプトに戻ってから貼る**（続けて貼ると、後ろの行の文字が答えとして読まれる）

1. tmux が入ったことを確かめる。

   ```bash
   tmux -V
   command -v tmux
   brew list --versions tmux
   rpm -q tmux
   ```

   - `tmux 3.7c` と `/home/linuxbrew/.linuxbrew/bin/tmux` が出る
   - 最後の行は `package tmux is not installed` でよい
   - **BaseOS の tmux（`tmux-3.3a-…`）が出て、そちらで始めたセッションが動いているなら**、そのセッションには `/usr/bin/tmux attach` で入る（Homebrew の tmux からはつなげない。[検証記録](verification/tmux.md)・[参考資料](reference/tmux.md)）

1. tmux のセッションを作って入る。

   ```bash
   tmux new-session -s work
   ```

   - 画面の下に緑の帯（ステータス行）が出て、左端に `[work]` が出る
   - **`Ctrl+b` を押して離してから `d`** で抜ける（デタッチ）。シェルに戻って `[detached (from session work)]` と出る
   - デタッチしても、セッションの中のシェルと、そこで動かしているコマンドは動き続ける
   - **次の手順は、デタッチしてシェルに戻ってから貼る**（続けて貼ると、tmux の中のシェルへの入力になる）

1. セッションの一覧を見て、もう一度入る。

   ```bash
   tmux ls
   tmux attach -t work
   ```

   - `tmux ls` の `work: 1 windows (created …)` は、tmux の画面を出た後のシェルに見える
   - `tmux attach -t work` で、手順 3 の画面に戻る
   - 中で `exit` と打つと、シェルが終わってセッションも終わる。`[exited]` と出てシェルに戻る
   - **次の手順は、`exit` でシェルに戻ってから貼る**（続けて貼ると、tmux の中のシェルへの入力になる）

1. セッションが残っていないことを確かめる。

   ```bash
   tmux ls
   ```

   - `no server running on /tmp/tmux-<UID>/default` と出る（セッションが 1 つも無くなると、tmux のサーバーも終わる）

---

## 使い方の基本

- tmux のキーは、**`Ctrl+b`（プレフィックス）を押して離してから**次のキーを押す
- 全部のキーは `Ctrl+b` → `?` で出る（`q` で閉じる）。`man tmux` も Homebrew の tmux のものが読める

| キー（`Ctrl+b` の後） | すること |
|---|---|
| `d` | デタッチ（セッションを残して抜ける） |
| `c` | 新しいウィンドウを作る |
| `n` / `p` | 次 / 前のウィンドウへ |
| `0`〜`9` | その番号のウィンドウへ |
| `w` | セッションとウィンドウの一覧から選ぶ（`q` で閉じる） |
| `s` | セッションの一覧から選ぶ |
| `%` | ペインを左右に分ける |
| `"` | ペインを上下に分ける |
| `o` / 矢印 | 次のペイン / その向きのペインへ |
| `z` | 今のペインを全画面にする（もう一度で戻る） |
| `x` | 今のペインを閉じる（`kill-pane …? (y/n)` に `y`） |
| `[` | さかのぼって読む（コピーモード。矢印・PageUp・PageDown で動き、`q` で戻る） |
| `$` / `,` | セッション / ウィンドウの名前を変える |
| `:` | tmux のコマンドを打つ |
| `Ctrl+b` | `Ctrl+b` を中のアプリに送る |

| コマンド | すること |
|---|---|
| `tmux new-session -s <名前>` | 名前を付けてセッションを作り、入る |
| `tmux new-session -A -s <名前>` | 同じ名前のセッションがあれば入り、無ければ作って入る |
| `tmux new-session -d -s <名前> <コマンド>` | 入らずに、コマンドを動かすセッションを作る（コマンドが終わるとセッションも終わる） |
| `tmux ls` | セッションの一覧（どこかで入っているものには `(attached)`） |
| `tmux attach -t <名前>` | セッションに入る |
| `tmux attach -d -t <名前>` | ほかの端末から入っていれば、そちらを外してから入る |
| `tmux kill-session -t <名前>` | セッションを終わらせる（中のコマンドも止まる） |
| `tmux kill-server` | すべてのセッションを終わらせる |

---

## 設定ファイル（任意）

- マウスのホイールでさかのぼれるようにし、さかのぼれる行数を 2000 から 50000 に増やす。Claude Code のように出力が長く続くものを、tmux の中で読み返すときに効く
- tmux は、サーバーが起動するときに `~/.tmux.conf` と `~/.config/tmux/tmux.conf` の**両方**を読む（あるものだけ）。新規作成は後者、既存設定がある場合はそのファイルに書く
- マウスを on にすると、マウスでの文字の選択は tmux が受け取る。端末の選択を使うときは、端末の決まりに従う（WezTerm などは Shift を押しながら）

1. 設定ファイルを書く。

   ```bash
   if [ -e ~/.tmux.conf ] || [ -e ~/.config/tmux/tmux.conf ]; then
     echo '中断: tmux の設定ファイルがすでにある。中身を見て、この節の set の 2 行を手で足す' >&2
   else
     mkdir -p ~/.config/tmux
     cat > ~/.config/tmux/tmux.conf <<'EOF'
   # マウス: ホイールでさかのぼる・クリックでペインを選ぶ・境界のドラッグで大きさを変える
   set -g mouse on
   # さかのぼれる行数（既定は 2000）
   set -g history-limit 50000
   EOF
     cat ~/.config/tmux/tmux.conf
   fi
   ```

   - 書いた 4 行が出る
   - `中断:` が出たら、すでにある設定ファイルの `mouse` と `history-limit` を編集する。両方のファイルがある場合は、後で読む `~/.config/tmux/tmux.conf` に別の値が無いことも確かめる

1. 動いている tmux にも読ませて、効いたか確かめる。

   ```bash
   if TMUX_CHECK_ID=$(tmux new-session -d -P -F '#{session_id}' -s "conf-check-$$"); then
     for conf in ~/.tmux.conf ~/.config/tmux/tmux.conf; do
       if [ -f "${conf}" ]; then tmux source-file "${conf}"; fi
     done
     tmux show -g mouse
     tmux show -g history-limit
     tmux kill-session -t "${TMUX_CHECK_ID}"
   else
     echo '中断: 確認用のセッションを作れなかった。既存セッションは終了しない' >&2
   fi
   ```

   - `mouse on` と `history-limit 50000` が出る
   - 既存・新規のどちらの設定ファイルも、起動時と同じ順で読み込む。既存セッションのマウス設定にも反映する
   - tmux の中でホイールを上へ回すと、さかのぼって読める（右上に `[5/258]` のような位置が出る）。下まで回すか `q` で戻る

---

## Claude Code を tmux の中で動かす（任意）

- SSH でログインしたシェルから、tmux の中で Claude Code を動かすと、SSH を切っても Claude Code が動き続ける
- Remote Control（`claude remote-control`）で始めると、SSH を切った後も、スマートフォンの Claude のアプリや claude.ai/code のブラウザから続けて使える
- 前提: [Claude Code](claude-code.md) を入れ、`claude` で claude.ai のアカウント（Pro / Max / Team / Enterprise）にログインしてあること。API キーでは Remote Control を使えない（公式ドキュメント）
- **この節の手順 4 には対話入力がある**（ディレクトリの信頼と、初回の Remote Control の確認）
- Windows の PC は [Claude Code の Remote Control（Windows）](windows-claude-remote-control.md)（Windows には tmux が無いので、タスク スケジューラと WezTerm を使う）
- Remote Control でなく、対話の `claude` を動かし続けるときは、この節の手順 4 で `claude` だけを打つ。別の SSH から `tmux attach -t claude` で戻れる

1. Claude Code と tmux が使えることと、ログインを確かめる。

   ```bash
   claude --version
   tmux -V
   claude auth status --text
   ```

   - `claude` の版、`tmux 3.7c`、`Login method: …` の行が出ればよい
   - `Not logged in. Run claude auth login to authenticate.` なら、[claude-code.md 手順 5](claude-code.md#実施手順) でログインしてから続ける
   - `claude doctor` の `Remote Control` の段にも、使えないときは理由が出る（ログインしていないと `Not signed in to claude.ai` など）

1. Claude Code を動かすディレクトリに移る。

   - `cd <PROJECT_DIR>` で、Remote Control で作業させたいディレクトリ（プロジェクト）に移る
   - ホームそのものは選ばない（Claude Code はホームの信頼を保存しない。[Windows の手順書](windows-claude-remote-control.md#実施手順)の手順 2）
   - この節の手順 4 は、tmux の中で見た作業ディレクトリの名前を Remote Control のセッション名にする

1. tmux のセッションを作って入る。

   ```bash
   tmux new-session -A -s claude
   ```

   - 左下に `[claude]` が出る。新規セッションのシェルは、この節の手順 2 のディレクトリから始まる
   - 同じ名前のセッションがあれば、そこで動いていたコマンドと作業場所のまま戻る（`-A`）。Claude Code がすでに動いているなら、この節の手順 4 は飛ばしてその画面を使う
   - シェルに戻っている場合は、中で `pwd` を確かめ、必要なら `cd <PROJECT_DIR>` で作業場所へ移る。ほかのコマンドが動いていれば、そこへ手順 4 を貼らない
   - **次の手順は、tmux の中のシェルで作業場所を確かめてから貼る**（動いているアプリへ貼ると、その入力として食われる）

1. tmux の中で Remote Control を始める。

   ```bash
   claude remote-control --name "$(basename "$PWD")" --spawn same-dir
   ```

   - 信頼のダイアログ（`Is this a project you created or one you trust?`）が出たら、**↓ で `Yes, I trust this folder` を選び Enter**（既定は `No, exit`）
   - 初めて Remote Control を使うときは `Enable Remote Control? (y/n)` が出る。`y`
   - `https://claude.ai/code/<SESSION_ID>` の URL と `space to show QR code` が出れば、始まっている
   - **`Ctrl+b` → `d` でデタッチする**（`Ctrl+C` を押すと Remote Control が止まる）
   - `Error: You must be logged in to use Remote Control.` で終わったら、`exit` で tmux を閉じて、この節の手順 1 からやり直す
   - **次の手順は、デタッチしてシェルに戻ってから貼る**（続けて貼ると、Claude Code への入力として食われる）

1. Remote Control が動いていることを確かめる。

   ```bash
   tmux ls
   pgrep -af 'claude remote-control'
   ```

   - `claude: 1 windows (created …)` と、`<PID> claude remote-control --name <名前> --spawn same-dir` が出ればよい
   - 2 行目が何も出なければ、`claude` は止まっている。`tmux attach -t claude` で中の表示を見る

1. SSH の接続を切る。

   ```bash
   exit
   ```

   - クライアントのプロンプトに戻る
   - tmux のセッションと、その中の Claude Code は、このホストで動き続ける

1. スマートフォンかブラウザから使う。

   - claude.ai/code か、Claude のアプリの **Code** の一覧に、この節の手順 2 のディレクトリの名前のセッションが出る
   - 開いてメッセージを送ると、このホストのそのディレクトリで Claude Code が動いて返事が来る
   - 返事が来なければ、この節の手順 8 でログインし直して、中の表示を見る
   - **次の手順は、SSH でログインし直してから貼る**

1. SSH でログインし直し、tmux のセッションに戻る。

   ```bash
   tmux attach -t claude
   ```

   - この節の手順 4 の画面に戻る
   - 動かし続けるなら、`Ctrl+b` → `d` で離れる
   - 止めるなら `Ctrl+C`。シェルに戻ったら `exit` で tmux のセッションも閉じる

---

## 更新

- 動いている tmux のサーバーは、更新しても前の版のまま動き続ける

1. brew で tmux を更新する。

   ```bash
   brew upgrade tmux
   ```

   - 新しい版を使うのは、セッションを全部閉じて `tmux ls` が `no server running on …` になってから
   - 前の版のサーバーへ新しい版のクライアントからつなぐと、つなげないことがある。更新前にセッションを終了し、新しい版でサーバーを起動し直す
   - **ほかのコマンドは、Homebrew の確認が出たら答え、更新が終わってから貼る**（続けて貼ると確認の答えとして食われる）

---

## ロールバック

- tmux のセッションの中で動かしているもの（Claude Code など）は、この節の手順 1 で止まる。残したいものがあれば、先に終える

1. tmux のセッションを全部終わらせる。

   ```bash
   tmux kill-server
   ```

   - 何も出ないか、`no server running on …` と出ればよい

1. brew で tmux を消す。

   ```bash
   brew uninstall tmux
   ```

   - tmux と一緒に入った依存も、ほかに使うものが無ければ一緒に消える（`Autoremoving 5 unneeded formulae:`）。ほかの formula が使っている依存は残る
   - `openssl@3` と `ca-certificates` が消えるときは、`/home/linuxbrew/.linuxbrew/etc/` の下の設定ファイルを残したという警告が出る。そのままでよい
   - 同じシェルでは、`command -v tmux` がまだ前のパスを返す（bash が覚えている）。`hash -r` の後か新しいシェルでは、何も返さない

1. 設定ファイルを作っていたときだけ、消す。

   ```bash
   rm -f ~/.config/tmux/tmux.conf                # 設定ファイルを作っていた場合
   ```

---

## 注意点

- **Homebrew 系に共通の注意**（`sudo tmux` はそのままでは見つからない、PATH の先頭が Homebrew）は [homebrew.md の注意点](homebrew.md#注意点)
- **Claude Code の `Ctrl+B` は、tmux の中では 2 回押す**。`Ctrl+b` → `Ctrl+b` で中のアプリに `Ctrl+b` を送る
- **BaseOS の tmux と混ぜない**: 同じソケットを使うので、版の違うクライアントからはセッションにつなげない（[検証記録](verification/tmux.md)・[参考資料](reference/tmux.md)）
- **ログアウトしてもセッションが残るのは、`KillUserProcesses=no` のとき**: AlmaLinux 10 の既定。`yes` にしたホストでは、ログアウトでセッションも止まるはず
- **PC を再起動すると、セッションも中のコマンドも消える**: 起動時に始め直す仕組みは、本書では作らない
- **Remote Control の性質**（公式ドキュメント。[Windows の手順書の注意点](windows-claude-remote-control.md#注意点)にも同じ内容）
  - このホストからは外向きの HTTPS だけで、受信のポートは開けない
  - つないでいる間、会話の転写（メッセージ・応答・ツールの動き）は Anthropic のサーバーに保存される
  - ネットワークが約 10 分切れると、`claude remote-control` は自分で終わる。tmux の中のシェルは残るので、[Claude Code を tmux の中で動かす（任意）](#claude-code-を-tmux-の中で動かす任意)の手順 8 で入り、その節の手順 4 のコマンドを打ち直す
  - 止めてから約 4 時間以内なら、`claude remote-control` で同じセッションが戻る
  - `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`・`DISABLE_GROWTHBOOK`・`ANTHROPIC_BASE_URL`（`api.anthropic.com` 以外）があると使えない
- **マウスを on にすると、Claude Code の画面でもホイールは tmux が受け取る**: コンテナの Claude Code（ログインしていない最初の画面）は、マウスの報告も代替画面も使っていなかった（`#{mouse_any_flag}` と `#{alternate_on}` が 0）。ホイールは tmux のコピーモードに入る
