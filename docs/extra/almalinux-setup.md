# AlmaLinux 10 の初期設定の手順（インストール直後の更新・sudo・SSH・導入元・日本語入力・GNOME・シェルのツール・Git・Firefox・WezTerm・Neovim・AI エージェント）のロールバックと注意点

[手順書](../almalinux-setup.md)・[検証記録](../verification/almalinux-setup.md)・[参考資料](../reference/almalinux-setup.md)

- 手順書の実施手順は項（###）ごとに 1 から数える。「<項>の手順 N」は手順書のその項の手順、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- 残す項目の手順は飛ばす。項目ごとのこの節の手順
  - AI エージェント: [AI エージェントとプラグインを消す](#ai-エージェントとプラグインを消す)の手順で、Codex・Grok のプラグインは 1、Claude Code は 2〜4、Codex CLI は 5〜7、Grok Build は 8〜11
  - Git: [Git の道具を消す](#git-の道具を消す)の手順で、lazygit は 1、git-delta は 2・3、GitHub CLI は 4〜8、Git の設定は 9〜13
  - 端末とエディタ: [端末とエディタを消す](#端末とエディタを消す)の手順で、yazi は 1、自分用の Neovim の設定は 2、Neovim は 3・4、Node.js は 5、デスクトップの等幅のフォントと Ctrl+Alt+T は 6、WezTerm は 7〜9（自分用の設定は 7）、HackGen Console NF は 10
  - ブラウザ: [Firefox を戻す](#firefox-を戻す)の手順 1〜5（AAC・H.264 のための FFmpeg だけなら 1）
  - 表示と入力: [表示と入力を戻す](#表示と入力を戻す)の手順で、ダークモードは 1、ボタンは 2、時計と電池は 3、Files は 4、Alt+Tab は 5、ホットコーナーは 6、Caps Lock は 7、拡大率は 8、Ctrl+Alt+T は 9、Dash のお気に入りは 10、トレイアイコンは 11・12
  - 日本語入力: [表示と入力を戻す](#表示と入力を戻す)の手順で、入力ソースは 13、ibus-anthy は 14。フォルダーの名前は 15
  - シェル: [シェルのツールと bash の設定を戻す](#シェルのツールと-bash-の設定を戻す)の手順で、tmux のセッションは 1、履歴の控えは 2、ツールは 3・4（Homebrew ごと消すなら飛ばしてよい）、ツールの設定とキャッシュは 5、`~/.inputrc` は 6、共通の bash 設定は 7・8。[Homebrew と bash-completion を消す](#homebrew-と-bash-completion-を消す)の手順で、Homebrew は 1〜3、bash-completion は 4
  - 導入元: [Flatpak・RPM Fusion・EPEL を消す](#flatpakrpm-fusionepel-を消す)の手順で、Flathub は 1〜4、RPM Fusion は 5・6、EPEL は 7・8
  - PC 全体: [システムの設定を戻す](#システムの設定を戻す)の手順で、パッケージの案内は 1、kdump は 2、journal は 3、PC の名前は 4、再起動と確かめは 5・6、sudo は 7
- 拡大率を 100% 以外にしていたら、[表示と入力を戻す](#表示と入力を戻す)の手順 8 の前に、設定の「ディスプレイ」の「スケーリング」で 100% に戻す
- gsettings の値は、変える前の値ではなく**既定値**に戻る。「日本語入力」の手順 2 と「GNOME の表示と入力」の手順 13 で控えた値に戻すなら、`reset` の代わりに `set` を使う
- OS とファームウェアの更新、SSH（Workstation の既定のまま）、「Homebrew」の手順 1 の依存パッケージは戻さない。項の中で入れた共通の道具（「HackGen Console NF」の手順 3 の `unzip`、「GitHub CLI」の手順 1 の `dnf-command(config-manager)`、「Codex CLI」の手順 2 のパッケージ、「Neovim」の手順 3 で自分用の設定が入れた外部コマンド〔Node.js を除く〕、「yazi」の手順 2 の `YAZI_EXTRAS`）も残す
- 任意節で変えたものは、その節の最後の「元に戻すときは」の手順で戻す。[Homebrew を sudo でも使う（任意）](../almalinux-setup.md#homebrew-を-sudo-でも使う任意)を通したなら、先にその節の手順 2 を行う
  - [Claude Code を tmux の中で動かす（任意）](../almalinux-setup.md#claude-code-を-tmux-の中で動かす任意)で Remote Control を動かしているなら、[AI エージェントとプラグインを消す](#ai-エージェントとプラグインを消す)の前に、その節の手順 8 で止める
- 別の手順書で入れたもの（VS Code・Podman・[コーディングエージェントの共同作業](coding-agents.md#ロールバック)など）は、それぞれの手順書のロールバックで先に戻す
- この文書で入れたものは、この節の項を上から順に戻す（Homebrew を消す前に Homebrew のもの、RPM Fusion を消す前に[Firefox を戻す](#firefox-を戻す)の手順 1 の FFmpeg）
  - 自分用の設定は、[Git の道具を消す](#git-の道具を消す)と[端末とエディタを消す](#端末とエディタを消す)の中で戻す（Neovim と WezTerm は、それぞれのリポジトリのロールバックへ案内する。lazygit と yazi は、clone を残すか消すかを箇条書きに書いた）

> [!WARNING]
> [Git の道具を消す](#git-の道具を消す)の手順 5 は、**ほかの端末を含め、GitHub CLI が生成した認証トークンをすべて失効させる。** このホストから認証情報を消すだけなら、同じ項の手順 4 だけでよい。[Firefox を戻す](#firefox-を戻す)で**ダウングレードした Firefox は、新しいプロファイルを読めないことがある**（[注意点](#注意点)）。

- **EPEL・RPM Fusion を消しても、そこから入れたパッケージ（btop・distrobox・podman-compose・podman-tui・VirtualBox の `liblzf`・Firefox の FFmpeg など）は残り、更新されなくなる**。要らないものは、先に各手順書のロールバックで消す
- [表示と入力を戻す](#表示と入力を戻す)と[シェルのツールと bash の設定を戻す](#シェルのツールと-bash-の設定を戻す)の手順は、「シェルのツール」の手順 2 と同じ、開き直した端末に貼る
- [端末とエディタを消す](#端末とエディタを消す)から後の項は、WezTerm ではなく、Ptyxis（アクティビティの画面で「端末」）に貼る（WezTerm を消すため）

> [!CAUTION]
> [Homebrew と bash-completion を消す](#homebrew-と-bash-completion-を消す)の手順 2 は、**Homebrew で入れたものを全部消す**（この文書の yazi・Neovim などと、この文書の外で入れたものも。`~/.local/share/fonts` のフォントは残るので、先に[端末とエディタを消す](#端末とエディタを消す)の手順 10 で消す）。[システムの設定を戻す](#システムの設定を戻す)の手順 3 は、**ディスクに残した journal（前の起動のログ）を消す**。[シェルのツールと bash の設定を戻す](#シェルのツールと-bash-の設定を戻す)の手順 7 の後に閉じたシェルは、**`~/.bash_history` を既定の 1,000 行に切り詰める**（残す履歴は、同じ項の手順 2 で控える）。[AI エージェントとプラグインを消す](#ai-エージェントとプラグインを消す)の手順 11 は、**`~/.grok`（ログイン情報・会話の記録・設定・信頼したフォルダーの記録・Grok が作った worktree）を消す**（入れ直すかもしれないなら、行わない）。どれも取り戻せない。Claude Code の設定・履歴（`~/.claude/`・`~/.claude.json`）は、この節では消さない。手で消すと、設定・許可済みツール・MCP サーバー定義・セッション履歴がすべて消える（消す前に中身を確認する）。

### AI エージェントとプラグインを消す

1. 2 つのプラグインとマーケットプレイスを外す。

   ```bash
   claude plugin uninstall codex@openai-codex
   claude plugin uninstall grok-build@xai-grok-build
   claude plugin marketplace remove openai-codex
   claude plugin marketplace remove xai-grok-build
   printf '\n\033[7m 確認 \033[0m\n'
   claude plugin list
   ```

   - 最後の一覧に、2 つのプラグインが出なければよい
   - プラグインのデータ（`~/.claude/plugins/data/` の下）も消える
   - Node.js は、ここでは外さない（[端末とエディタを消す](#端末とエディタを消す)の手順 5）

1. Claude Code を消す。

   ```bash
   sudo dnf remove claude-code
   ```

   - 設定・履歴（`~/.claude/`、`~/.claude.json`、プロジェクト側の `.claude/`、`.mcp.json`）は残る
   - 確認用のディレクトリ `~/claude-sandbox`（[Claude Code](../almalinux-setup.md#claude-code)の手順 5）も残る。要らなければ手で消す
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. repo ファイルを消す。

   ```bash
   sudo rm -f /etc/yum.repos.d/claude-code.repo
   ```

1. 鍵も消すときだけ、署名鍵を消す。

   ```bash
   sudo rpm -e gpg-pubkey-1a7ecace-69caef70          # 鍵も消す場合
   ```

1. 起動中の Codex を終了し、ログイン情報も外す場合はログアウトする。

   ```bash
   codex logout
   ```

   - ログイン情報を共有するエディタの拡張機能なども、次回ログインが必要になる

1. この手順で入れたリンクと配布物を消す。

   ```bash
   rm -f ~/.local/bin/codex ~/.local/bin/codex-code-mode-host
   rm -rf ~/.codex/packages/standalone
   hash -r
   printf '\n\033[7m 確認 \033[0m\n'
   command -v codex
   ```

   - 最後に何も出なければ、PATH 上に Codex は無い
   - パスが出る場合は、別の導入方法の Codex が残っている
   - `~/.codex` 全体は消さない（設定・会話履歴などが入っている）
   - 確認用のディレクトリ `~/codex-sandbox`（[Codex CLI](../almalinux-setup.md#codex-cli)の手順 8）も残る。要らなければ手で消す

1. インストーラーが PATH のブロックを足した場合だけ、シェルの設定を戻す。

   - `~/.bashrc` の `# >>> Codex installer >>>` から `# <<< Codex installer <<<` までをエディタで削除する
   - `~/.local/bin` 自体や、ほかのツールが書いた PATH の行は消さない
   - 新しい端末を開いて確認する

1. 起動中の Grok を終了し、ログイン情報も外すならログアウトする。

   ```bash
   grok logout
   ```

   - ログインしていなければ `No cached session to log out of.` と出る

1. この手順で入れたリンクと配布物を消す。

   ```bash
   for f in ~/.local/bin/grok ~/.local/bin/agent; do
     case "$(readlink "$f")" in
       "$HOME/.grok/"*) rm -f "$f" ;;
     esac
   done
   rm -f ~/.grok/bin/grok ~/.grok/bin/agent
   rm -rf ~/.grok/downloads ~/.grok/completions
   hash -r
   printf '\n\033[7m 確認 \033[0m\n'
   command -v grok agent
   ```

   - 最後に何も出なければ、PATH 上に Grok は無い
   - `~/.local/bin` の `grok`・`agent` は、`~/.grok` を指すリンクだけを消す（ほかのツールの `agent` は残る）
   - パスが出る場合は、別の導入方法の Grok か、別のツールの `agent` が残っている
   - 確認用のディレクトリ `~/grok-sandbox`（[Grok Build](../almalinux-setup.md#grok-build)の手順 7）も残る。要らなければ手で消す

1. インストーラーが `~/.bashrc` に足したブロックを消す。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   if grep -qx '# >>> grok installer >>>' ~/.bashrc && grep -qx '# <<< grok installer <<<' ~/.bashrc; then
     sed -i --follow-symlinks '/^# >>> grok installer >>>$/,/^# <<< grok installer <<<$/d' ~/.bashrc
     grep -c 'grok' ~/.bashrc
   else
     echo '中断: ~/.bashrc に grok installer の印が 2 つそろっていない。エディタで確かめる' >&2
   fi
   ```

   - 最後に `0` が出れば、`~/.bashrc` に Grok の行は無い（ほかに grok を含む行を自分で書いていれば、その数が出る）
   - ブロックの前の空行は残る。`~/.bashrc.bak.<数字>` も残るので、要らなければ手で消す
   - 新しい端末を開いて確かめる
   - この項の手順 8〜10 で、ログイン・CLI・PATH の設定を外す。ログイン情報・会話の記録・設定（`~/.grok` の残り）は残る

1. 完全に消すときだけ、`~/.grok` を消す（取り戻せない）。

   ```bash
   rm -rf ~/.grok
   printf '\n\033[7m 確認 \033[0m\n'
   ls -ld ~/.grok
   ```

   - `No such file or directory` になればよい
   - Grok が作った worktree（`~/.grok/worktrees` の下）も消える。中の作業が要るなら、先に取り込む

### Git の道具を消す

1. brew で lazygit を消す。

   ```bash
   brew uninstall lazygit
   ```

   - `~/.config/lazygit/`（自分用の設定のリンク `config.yml` も）と `~/.local/state/lazygit/` は残るので、要らなければ手で消す
   - 自分用の設定の clone（README の例では `~/lazygit-config`）も残る。消すときは、`git -C ~/lazygit-config status --short` と `git -C ~/lazygit-config log --oneline '@{u}..'` が、どちらも何も出さないことを先に確かめる（コミットしていない変更と、push していないコミットが無い）
   - 自分用の Neovim の設定（LazyVimStarter）は、`<leader>gg` で lazygit を使う。消すと、そのキーが使えなくなる

1. brew で git-delta を消し、git から delta の設定を外す。

   ```bash
   brew uninstall git-delta
   git config --global --unset core.pager
   git config --global --unset interactive.diffFilter
   git config --global --remove-section delta
   ```

   - **`core.pager` を消し忘れると、`git diff` のたびに `delta: command not found` になる**
   - `merge.conflictstyle` は、ここでは外さない（[Git](../almalinux-setup.md#git)も同じ設定を使う。戻すかは、この項の手順 10 で決める）

1. delta の設定が消えたか確かめる。

   ```bash
   git config --global --get-regexp '^(core\.pager|interactive\.difffilter|delta\.)'   # 何も出なければ消えている
   ```

   - 何も出なければ消えている
   - lazygit の `git.diffRenderers` に delta の項目を足していた場合は、その項目も消す（ほかの renderer は残す）。以前の `git.paging` を使っていた場合は、そちらの delta 設定を外す

1. このホストの認証情報も外すときだけ、ローカルからログアウトする。

   ```bash
   gh auth logout
   ```

   - 対話でホストとアカウントを選び、確認に答える
   - OS の資格情報ストアまたは gh の設定から、このアカウントの保存された認証情報を外す。GitHub 側のトークンは失効しない
   - `~/.config/gh` に残る設定も不要なら、ログアウト後に手で消す。ディレクトリを消すだけでは、資格情報ストアのトークンは消せない
   - **次の手順は、`gh auth logout` が終わってから行う**（続けて貼ると対話の答えとして食われる）

1. 全端末の GitHub CLI のトークンも失効させるときだけ、ブラウザで GitHub の認可を取り消す。

   - `https://github.com/settings/applications` を開き、「Authorized OAuth Apps」の「GitHub CLI」→「Revoke Access」→「I understand, revoke access」で取り消す
   - 本書のブラウザ認証で作ったトークンが対象。ほかの端末も、次に使うときに認証し直す
   - 本書の手順とは別に作った PAT を使っている場合は、その PAT の設定から取り消す

1. Git の資格情報のヘルパーから gh を外し、gh を消す。

   ```bash
   for k in credential.https://github.com.helper credential.https://gist.github.com.helper; do
     if git config --global --get-all "$k" | grep -q 'auth git-credential'; then git config --global --unset-all "$k"; fi
   done
   sudo dnf remove gh
   ```

   - [GitHub CLI](../almalinux-setup.md#github-cli)の手順 3 で Git の認証に `Y` と答えたときに gh が `~/.gitconfig` に書いた行（`credential.https://github.com.helper` と `credential.https://gist.github.com.helper`）を外す。書いていなければ、何も変えない
   - パッケージを消すだけでは、設定と保存された認証情報は残る。認証も外すなら、gh を消す前にこの項の手順 4 を行う
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. repo ファイルを消す。

   ```bash
   sudo rm -f /etc/yum.repos.d/gh-cli.repo
   ```

1. 鍵も消すときだけ、署名鍵を消す。

   ```bash
   sudo rpm -e gpg-pubkey-62313325-69d4e1f8 gpg-pubkey-75716059-63172e8a   # 鍵も消す場合
   ```

1. [Git](../almalinux-setup.md#git)の手順 4・5・7 で今回追加・変更したキーだけ、元に戻す（`merge.conflictStyle` を除く）。

   - 手順書の「Git」で `global` に書いた設定を外す。`system` と `local` の設定は変えない
   - git 本体は消さない（gh などが依存している）
   - 「Git」の手順 2 で控えた元の値・スコープと、今回変更したキーの記録を使う。変更しなかったキーはそのまま残す
   - 「Git」の手順 2 の記録で、元の `global` が未設定だったキーだけ、`git config --global --unset <キー>` の形で 1 行ずつ外す
   - 元の `global` に値があったキーは、この項の手順 12 で書き戻す。変更なしのキーと、「Git」の手順 7 を飛ばした場合の `pull.ff` は触らない
   - 対象は `pull.rebase`・`rebase.autoStash`・`core.autocrlf`・`init.defaultBranch`・`core.quotepath`・`fetch.prune`・`push.autoSetupRemote`・`rerere.enabled`・`diff.algorithm`・`branch.sort`・`tag.sort`・`pull.ff`
   - 例: 今回初めて追加した `core.autocrlf` なら `git config --global --unset core.autocrlf`
   - 外すと何も出ない。最後のキーを外した `~/.gitconfig` の節も消える

1. git-delta も消したとき（この項の手順 2）だけ、今回変えた `merge.conflictStyle` も元に戻す。

   - git-delta を残すなら、そのまま残す（同じ設定を使う）
   - 今回追加し、元の `global` が未設定なら `git config --global --unset merge.conflictStyle` で外す
   - 元の `global` に値があったなら、この項の手順 12 で書き戻す。変更なしなら触らない

1. 名前とメールアドレスも戻すときだけ、今回変えた値を元に戻す。

   - 今回追加し、元の `global` が未設定だったものだけ、`git config --global --unset user.name` または `git config --global --unset user.email` で外す
   - 元の `global` に値があったものは、この項の手順 12 で書き戻す。変更なしのものは触らない
   - 外すと、`git commit` が `Author identity unknown` で止まることがある（検証コンテナでは止まった）

1. この項の手順 9〜11 で戻すと決めたキーのうち、元の `global` に値があったものは、「Git」の手順 2 で控えた値で書き戻す。

   - `git config --global <キー> <元の値>` の形で、キーごとに 1 行ずつ貼る
   - 例: 元の `core.autocrlf` を戻すなら `git config --global core.autocrlf <元の値>`
   - 空白を含む値は引用符で囲む。元の値が `system` や `local` だけにあった場合は、それを `global` に写さない（今回追加した `global` を外せば、元のスコープの値がまた効く）
   - 残すと決めた `merge.conflictStyle`・名前・メールアドレスと、今回変更しなかったキーは書き戻さない

1. 外れたか確かめる。

   ```bash
   git config --global --list
   ```

   - 今回戻すキーが、「Git」の手順 2 で記録した元の `global` と一致すればよい（元が未設定なら出ない、元の値があればその値が出る）
   - 残すと決めたキーと、本書で変更しなかったキーはそのまま。元の設定が空で、今回の設定をすべて外した場合だけ、何も出ない
   - 元は `~/.gitconfig` が無かった場合も、空のファイルが残る（中身が無いので、git の動きは変わらない）

### 端末とエディタを消す

1. brew で yazi を消す。

   ```bash
   brew uninstall yazi
   ```

   - 依存ツール（`YAZI_EXTRAS` で入れたもの）は他でも使うので、消すなら個別に指定する
   - 端末を開き直すと、yazi が無ければ共通設定は `y()` を定義しない。`~/.config/yazi/` は残るので、不要な場合だけ別に消す
   - 自分用の設定の clone（`~/.config/yazi`）を消すときは、`git -C ~/.config/yazi status --short` と `git -C ~/.config/yazi log --oneline '@{u}..'` が、どちらも何も出さないことを先に確かめる（コミットしていない変更と、push していないコミットが無い）

1. 自分用の Neovim の設定とプラグインを消し、退避した設定に戻す。

   - [LazyVimStarter の docs/setup.md の「ロールバック」](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#ロールバック)の手順 1〜3 を、上から順に貼る
   - その手順 2 は、設定のディレクトリごと消す（push していない変更は取り戻せない）。その手順 1 で、何も出ないことを確かめてから行う
   - その手順 3 で、入力ソースが既定（空）に戻り、Anthy の切り替えのキーに Ctrl+Space と Ctrl+J が戻る。日本語入力を残すなら、その手順 3 の箇条書きのとおり、入力ソースを導入の前の値（[日本語入力](../almalinux-setup.md#日本語入力)の手順 2 で設定した `[('xkb', 'jp'), ('ibus', 'anthy')]` など）に書き戻す
   - その手順 4（Homebrew の Neovim・lazygit・HackGen Console NF をまとめて消す）は行わない。Neovim はこの項の手順 4、lazygit は[Git の道具を消す](#git-の道具を消す)の手順 1、HackGen Console NF はこの項の手順 10 で消す

1. 既定のエディタの扱いを確認する。

   - 自分用の bash 設定で Neovim を指定している場合は、先にそちらの `EDITOR`・`VISUAL`・`vi` を変更する
   - 本書ではエディタ設定を `~/.bashrc` に書かないので、追記の削除は不要
   - この項の手順 4 の後に端末を開き直すと、Neovim が無ければ共通設定はエディタを変更しない
   - 別の場所にも `nvim` がある場合は引き続き使われる。個別の変更は共通設定側で行う

1. brew で Neovim を消す。

   ```bash
   brew uninstall neovim
   ```

   - 他の formula が使う依存は残る。不要になった依存は Homebrew が自動で削除する場合がある（[Homebrew の注意点](#注意点)）。残った不要な依存を整理する操作は `brew autoremove`
   - `~/.config/nvim`、`~/.local/share/nvim`（プラグイン）、`~/.local/state/nvim`（undo・swap）は残るので、要らなければ手で消す

1. ほかに使うものが無いときだけ、Node.js を外す。

   ```bash
   sudo dnf remove nodejs nodejs-npm
   ```

   - [Codex・Grok のプラグイン](../almalinux-setup.md#codexgrok-のプラグイン)の手順 1 と、自分用の Neovim の設定（その導入の手順 3）が入れたもの。プラグイン（[AI エージェントとプラグインを消す](#ai-エージェントとプラグインを消す)の手順 1）と自分用の設定（この項の手順 2）を外してから行う
   - [npm-offline.md](../npm-offline.md) で Node.js を使っているなら、外さない（自分用の Neovim の設定の Mason も使うが、この項の手順 2 で消えている）
   - bubblewrap は外さない（Flatpak と GNOME のデスクトップも使う）
   - トランザクション表の `Removing:` に `nodejs` と `nodejs-npm`、`Removing unused dependencies:` に一緒に入った `nodejs-libs`・`libuv` などが出る。ほかに使っているパッケージが出たら `N` で止める。よければ `y` と答える
   - **次の手順は、答えてから貼る**（続けて貼ると答えとして食われる）

1. デスクトップの等幅のフォント・Ctrl+Alt+T・お気に入りを戻す。

   ```bash
   kb=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal/
   /usr/bin/gsettings reset org.gnome.desktop.interface monospace-font-name
   /usr/bin/gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}" command 'ptyxis --new-window'
   fav=$(/usr/bin/gsettings get org.gnome.shell favorite-apps)
   /usr/bin/gsettings set org.gnome.shell favorite-apps "${fav//org.wezfurlong.wezterm.desktop/org.gnome.Ptyxis.desktop}"
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.desktop.interface monospace-font-name
   /usr/bin/gsettings get "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}" command
   /usr/bin/gsettings get org.gnome.shell favorite-apps
   ```

   - `'Red Hat Mono Regular 10'`・`'ptyxis --new-window'` と、端末のところが `'org.gnome.Ptyxis.desktop'` のお気に入りが出ればよい
   - [WezTerm と HackGen Console NF をデスクトップで使う](../almalinux-setup.md#wezterm-と-hackgen-console-nf-をデスクトップで使う)で変えたものを戻す
   - この手順の後、Ctrl+Alt+T は Ptyxis を開く（割り当てごと外すのは[表示と入力を戻す](#表示と入力を戻す)の手順 9）

1. 自分用の WezTerm の設定を外し、退避した設定に戻す。

   - [ryo-aoki-pc/wezterm の docs/install.md の「ロールバック」](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md#ロールバック)の手順 1〜4 を、上から順に貼る
   - その手順 3 は `~/.config/wezterm` を消す（commit・push していないものは取り戻せない）。その手順 2 で確かめてから行う
   - その手順 5・6 は、その文書の任意節を通したときだけ

1. WezTerm の 4 パッケージを消す。

   ```bash
   sudo dnf remove wezterm wezterm-common wezterm-gui wezterm-mux-server
   ```

   - 消えるのはこの 4 パッケージだけで、巻き添えの依存パッケージは無い
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. COPR の repo ファイルを消す。

   ```bash
   sudo dnf copr remove wezfurlong/wezterm-nightly      # repo ファイルを消す
   ```

   - `~/.config/wezterm/` や `~/.wezterm.lua`（自分で作った設定）は消えないので、不要なら手で消す
   - 自分用の設定（`ryo-aoki-pc/wezterm`）は、この項の手順 7 で外す
   - COPR の GPG 鍵は `gpg-pubkey-cea2757d-651b2a3e` として残る（`rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n'` で確認できる）
   - 消すなら `sudo rpm -e gpg-pubkey-cea2757d-651b2a3e`

1. HackGen を消し、fontconfig から消えたか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   brew uninstall --cask font-hackgen-nerd
   ls ~/.local/share/fonts/
   fc-list : family | grep -c HackGen
   ```

   - `==> Removing Font '/home/<USER>/.local/share/fonts/...'` が 4 行出る
   - `grep -c` が `0` になれば消えている。`ls` は何も出さない（[yazi](../almalinux-setup.md#yazi)の手順 2 の Symbols Nerd Font を残したときは、`SymbolsNerdFont` で始まるファイルだけを出す。空の `~/.local/share/fonts` は残る）
   - `~/.local/share/fonts` は Homebrew の外なので、[Homebrew と bash-completion を消す](#homebrew-と-bash-completion-を消す)で Homebrew ごと消すときも、先にこの手順を行う。Symbols Nerd Font も、そのときは先に `brew uninstall --cask font-symbols-only-nerd-font` で消す

### Firefox を戻す

1. FFmpeg のライブラリを消す。

   ```bash
   sudo dnf remove ffmpeg-libs
   ```

   - 「Firefox」の手順 8 で一緒に入った依存も、ほかに使うものが無ければ一緒に消える
   - AAC・H.264 のための FFmpeg だけ外すなら、この手順だけ行う。RPM Fusion 自体も外すなら、続けて[Flatpak・RPM Fusion・EPEL を消す](#flatpakrpm-fusionepel-を消す)の手順 5・6 を行う
   - EPEL は外さない（[btop.md](../btop.md) などほかの手順書でも使う。外すなら[Flatpak・RPM Fusion・EPEL を消す](#flatpakrpm-fusionepel-を消す)の手順 7・8）
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. Mozilla の repo ファイルを消す。

   ```bash
   sudo rm -f /etc/yum.repos.d/mozilla.repo
   ```

1. AppStream に無い言語パックを、ダウングレードより先に消す。

   ```bash
   sudo dnf remove ${FF_L10N}                    # 言語パックは AppStream に無いので先に消す
   ```

   - `FF_L10N`・`FF_PKG` は、手順書の[Firefox](../almalinux-setup.md#firefox)の手順 1 の変数（新しいシェルでは、そのブロックを貼り直す）
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. Firefox を AppStream の ESR（140 系）にダウングレードする。

   ```bash
   sudo dnf distro-sync "${FF_PKG}"              # 140 系へダウングレードされる
   ```

   - プロファイル（`~/.mozilla/firefox`、新しく作られた場合は `~/.config/mozilla/firefox`）は、この項のどの手順でも消えない
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. Mozilla の鍵も消すときだけ、その署名鍵を消す。

   ```bash
   sudo rpm -e gpg-pubkey-d98f0353-55a94004
   ```

### 表示と入力を戻す

1. ダークモードを既定（淡色）に戻す。

   ```bash
   /usr/bin/gsettings reset org.gnome.desktop.interface color-scheme
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.desktop.interface color-scheme
   ```

   - `'default'` が出ればよい

1. ウィンドウのボタンを既定に戻す。

   ```bash
   /usr/bin/gsettings reset org.gnome.desktop.wm.preferences button-layout
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.desktop.wm.preferences button-layout
   ```

   - `'appmenu:close'` が出ればよい

1. 時計と電池の表示を既定に戻す。

   ```bash
   /usr/bin/gsettings reset org.gnome.desktop.interface clock-show-weekday
   /usr/bin/gsettings reset org.gnome.desktop.interface clock-show-seconds
   /usr/bin/gsettings reset org.gnome.desktop.interface show-battery-percentage
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings list-recursively org.gnome.desktop.interface | grep -E 'clock-show-(weekday|seconds)|show-battery-percentage'
   ```

   - 3 行とも `false` が出ればよい

1. Files とファイルを選ぶ窓の表示を既定に戻す。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   for s in org.gtk.Settings.FileChooser org.gtk.gtk4.Settings.FileChooser; do
     /usr/bin/gsettings reset "${s}" show-hidden
     /usr/bin/gsettings reset "${s}" sort-directories-first
     /usr/bin/gsettings list-recursively "${s}" | grep -E 'show-hidden|sort-directories-first'
   done
   ```

   - `org.gtk` は `show-hidden false`・`sort-directories-first false`、`org.gtk.gtk4` は `show-hidden false`・`sort-directories-first true`（どちらも既定）が出ればよい

1. Alt+Tab を既定（アプリごと）に戻す。

   ```bash
   /usr/bin/gsettings reset org.gnome.desktop.wm.keybindings switch-applications
   /usr/bin/gsettings reset org.gnome.desktop.wm.keybindings switch-applications-backward
   /usr/bin/gsettings reset org.gnome.desktop.wm.keybindings switch-windows
   /usr/bin/gsettings reset org.gnome.desktop.wm.keybindings switch-windows-backward
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings list-recursively org.gnome.desktop.wm.keybindings | grep -E 'switch-(applications|windows)'
   ```

   - `switch-applications ['<Super>Tab', '<Alt>Tab']` と、`switch-windows @as []` などの 4 行が出ればよい

1. ホットコーナーを既定（有効）に戻す。

   ```bash
   /usr/bin/gsettings reset org.gnome.desktop.interface enable-hot-corners
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.desktop.interface enable-hot-corners
   ```

   - `true` が出ればよい

1. Caps Lock を Ctrl にする設定を外す（ほかの配列の設定は残す）。

   ```bash
   xkb=$(/usr/bin/gsettings get org.gnome.desktop.input-sources xkb-options)
   echo "変える前: ${xkb}"
   case "${xkb}" in
     "['ctrl:nocaps']") /usr/bin/gsettings reset org.gnome.desktop.input-sources xkb-options ;;
     *"'ctrl:nocaps'"*) /usr/bin/gsettings set org.gnome.desktop.input-sources xkb-options "$(printf '%s' "${xkb}" | sed -e "s/, 'ctrl:nocaps'//" -e "s/'ctrl:nocaps', //")" ;;
   esac
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.desktop.input-sources xkb-options
   ```

   - 最後に `@as []`（ほかの設定があれば、`'ctrl:nocaps'` を除いた一覧）が出ればよい

1. 拡大率の設定（mutter の実験的な機能）を外す（効くのは再起動の後）。

   ```bash
   f=$(/usr/bin/gsettings get org.gnome.mutter experimental-features)
   echo "変える前: ${f}"
   for x in scale-monitor-framebuffer xwayland-native-scaling; do
     f=$(printf '%s' "${f}" | sed -e "s/, '${x}'//" -e "s/'${x}', //" -e "s/\['${x}'\]/@as []/")
   done
   /usr/bin/gsettings set org.gnome.mutter experimental-features "${f}"
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.mutter experimental-features
   ```

   - 最後に `@as []`（ほかの機能を足していれば、その一覧）が出ればよい

1. Ctrl+Alt+T のショートカットを消す。

   ```bash
   kb=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal/
   list=$(/usr/bin/gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
   case "${list}" in
     "['${kb}']") /usr/bin/gsettings reset org.gnome.settings-daemon.plugins.media-keys custom-keybindings ;;
     *"'${kb}'"*) /usr/bin/gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$(printf '%s' "${list}" | sed -e "s|, '${kb}'||" -e "s|'${kb}', ||")" ;;
   esac
   /usr/bin/dconf reset -f "${kb}"
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings
   /usr/bin/dconf dump "${kb}"
   ```

   - `@as []`（ほかのショートカットがあれば、その一覧）が出て、最後の `dconf dump` が何も出さなければよい

1. Dash のお気に入りを既定に戻す。

   ```bash
   /usr/bin/gsettings reset org.gnome.shell favorite-apps
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.shell favorite-apps
   ```

   - `['firefox.desktop', 'org.gnome.Calendar.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Software.desktop', 'org.gnome.Ptyxis.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Calculator.desktop']`（Workstation の既定）が出ればよい
   - 「GNOME の表示と入力」の手順 13 で控えた並びに戻すなら、`reset` の代わりに `/usr/bin/gsettings set org.gnome.shell favorite-apps "<控えた値>"` を貼る（`<控えた値>` を置き換える）

1. トレイアイコンの拡張を無効にする。

   ```bash
   e=$(/usr/bin/gsettings get org.gnome.shell enabled-extensions)
   /usr/bin/gsettings set org.gnome.shell enabled-extensions "$(printf '%s' "${e}" | sed -e "s/, 'appindicatorsupport@rgcjonas.gmail.com'//" -e "s/'appindicatorsupport@rgcjonas.gmail.com', //" -e "s/\['appindicatorsupport@rgcjonas.gmail.com'\]/@as []/")"
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.shell enabled-extensions
   ```

   - `['background-logo@fedorahosted.org']` が出ればよい（`'appindicatorsupport@rgcjonas.gmail.com'` が無い）

1. トレイアイコンの拡張を外す。

   ```bash
   sudo dnf remove gnome-shell-extension-appindicator
   ```

   - `削除中:` が `gnome-shell-extension-appindicator` の 1 つだけになる。`これでよろしいですか? [y/N]:` に `y`
   - **次の手順は、`完了しました!` が出てプロンプトに戻ってから貼る**（続けて貼ると、`[y/N]` の答えとして食われる）

1. 入力ソースを既定値に戻す。

   ```bash
   /usr/bin/gsettings reset org.gnome.desktop.input-sources sources
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.desktop.input-sources sources
   ```

   - `@a(ss) []`（既定値）になればよい
   - 「日本語入力」の手順 2 で控えた値に戻すなら、`/usr/bin/gsettings set org.gnome.desktop.input-sources sources "<控えた値>"` を貼る（`<控えた値>` を置き換える）

1. 「日本語入力」の手順 1 で ibus-anthy を入れたときだけ、ibus-anthy を消す。

   ```bash
   sudo dnf remove ibus-anthy
   ```

   - `anthy-unicode`・`ibus-anthy-python`・`kasumi-common`・`kasumi-unicode` も一緒に消える。`ibus` 本体と、「日本語入力」の手順 1 で入ったフォントは残る
   - 最初から入っていた PC（Workstation）では貼らない
   - **次の手順は、`[y/N]` に `y` と答えて、プロンプトに戻ってから貼る**

1. フォルダーの名前を日本語に戻すときだけ、英語の名前のフォルダーを日本語の名前に戻す（中身ごと移す）。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/python3 - <<'EOF'
   import pathlib, subprocess, urllib.parse
   home = pathlib.Path.home()
   names = {'DESKTOP': 'デスクトップ', 'DOWNLOAD': 'ダウンロード', 'TEMPLATES': 'テンプレート', 'PUBLICSHARE': '公開',
            'DOCUMENTS': 'ドキュメント', 'MUSIC': '音楽', 'PICTURES': '画像', 'VIDEOS': 'ビデオ'}
   moved = {}
   for key, name in names.items():
       old = pathlib.Path(subprocess.run(['xdg-user-dir', key], capture_output=True, text=True, check=True).stdout.strip())
       new = home / name
       if old == new:
           print(f'そのまま: {new}')
           continue
       if new.exists():
           print(f'飛ばした: {new} がすでにある（{old} はそのまま）')
           continue
       if old != home and old.is_dir():
           old.rename(new)
           moved[old] = new
       else:
           new.mkdir()
       subprocess.run(['xdg-user-dirs-update', '--set', key, str(new)], check=True)
       print(f'{old} → {new}')
   bookmarks = home / '.config/gtk-3.0/bookmarks'
   if moved and bookmarks.exists():
       uri = lambda p: 'file://' + urllib.parse.quote(str(p))
       lines = bookmarks.read_text().splitlines()
       for old, new in moved.items():
           lines = [uri(new) + line[len(uri(old)):] if line == uri(old) or line.startswith(uri(old) + ' ') else line for line in lines]
       bookmarks.write_text('\n'.join(lines) + '\n')
   EOF
   grep '^XDG_' ~/.config/user-dirs.dirs
   ```

   - 「GNOME の表示と入力」の手順 1 と同じ形で、`/home/<USER>/Downloads → /home/<USER>/ダウンロード` のような行が 8 つ出る
   - `user-dirs.dirs` の 8 行が日本語の名前に戻ればよい

### シェルのツールと bash の設定を戻す

1. tmux のセッションを全部終わらせる。

   ```bash
   tmux kill-server
   ```

   - 何も出ないか、`no server running on …` と出ればよい
   - tmux のセッションの中で動かしているもの（Claude Code など）も止まる。残したいものがあれば、先に終える

1. 履歴のファイルを控える。

   ```bash
   cp -p ~/.bash_history ~/.bash_history.bak
   printf '\n\033[7m 確認 \033[0m\n'
   wc -l ~/.bash_history.bak
   ```

   - 行数が出る。要らなくなったら `~/.bash_history.bak` は手で消す

1. starship・zoxide・eza・bat・tmux を消す。

   ```bash
   brew uninstall starship zoxide eza bat tmux
   ```

   - Homebrew ごと消すなら、この手順とこの項の手順 4 は飛ばしてよい（[Homebrew と bash-completion を消す](#homebrew-と-bash-completion-を消す)の手順 2 で全部消える）
   - 残すツールは、名前を外してから貼る
   - 依存は、ほかの formula（[git-delta](../almalinux-setup.md#git-delta) など）が必要とする間は残る。Homebrew 7 では、不要になった依存は自動で削除される（`Autoremoving … unneeded formulae:`）
   - 同じシェルでは、`command -v tmux` などがまだ前のパスを返す（bash が覚えている）。`hash -r` の後か新しいシェルでは、何も返さない
   - starship を消した後のこの端末では、プロンプトを出すたびに `-bash: /home/linuxbrew/.linuxbrew/bin/starship: そのようなファイルやディレクトリはありません` と出て、プロンプトの文字が消える。コマンドは動くので、この項の手順 8 で端末を開き直すまで、そのまま貼ってよい

1. fzf を使うツールがほかに無いときだけ、fzf を消す。

   ```bash
   brew uninstall fzf
   ```

   - fzf の実行ファイルは、zoxide の `zi` と [yazi](../almalinux-setup.md#yazi) の絞り込みにも使う。それらを使うなら消さない
   - キー操作だけを無効にする場合は bash リポジトリ側を変更する。`~/.bashrc` に重ねて設定しない

1. ツールの設定・キャッシュ・履歴も消すときだけ、消す。

   ```bash
   rm -f ~/.config/starship.toml ~/.config/tmux/tmux.conf
   rm -rf ~/.cache/starship ~/.local/share/zoxide ~/.config/bat ~/.cache/bat
   ```

   - zoxide の履歴（`~/.local/share/zoxide/db.zo`）は、残しておけば、入れ直したときにそのまま使える

1. 「共通の bash 設定」の手順 4 で作った `~/.inputrc` を消す。

   ```bash
   rm -f ~/.inputrc
   ```

   - 「共通の bash 設定」の手順 4 が `中断:` で、すでにあった `~/.inputrc` に手で足したホストでは、足した行だけを手で消す

1. 共通の bash 設定も戻すときだけ、bash リポジトリの設定を戻す。

   - [bash のロールバック](https://github.com/ryo-aoki-pc/bash/blob/main/docs/quick-start.md#ロールバック)を参照する。ほかのツールの共通設定も外れる
   - ツールを消しただけなら、共通設定は残してよい（入っていないツールの設定は読まない）

1. 開いている端末を閉じて、開き直す。

   - 削除したツールの設定は、次のシェルでは共通設定から読み込まれない
   - 今のシェルには `bind -f` した設定と `shopt` が残っている。新しいシェルで効く

### Homebrew と bash-completion を消す

1. Homebrew を消す前に、何が消えるか見る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   /home/linuxbrew/.linuxbrew/bin/brew leaves
   /home/linuxbrew/.linuxbrew/bin/brew list --versions | wc -l
   curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh -o /tmp/uninstall.sh
   bash /tmp/uninstall.sh --dry-run
   ```

   - `brew` はフルパスで呼ぶ（[シェルのツールと bash の設定を戻す](#シェルのツールと-bash-の設定を戻す)の手順 7 で共通の bash 設定を戻した後は、`brew` が PATH に無い）
   - 公式のアンインストーラを `/tmp/uninstall.sh` に落として、**まず `--dry-run` で何が消えるか見る**
   - `brew leaves` に出るものは、すべて使えなくなる
   - **次の手順は、内容を確かめてから貼る**

1. Homebrew のアンインストーラを本実行する（取り戻せない）。

   ```bash
   bash /tmp/uninstall.sh
   ```

   - `Are you sure you want to uninstall Homebrew? … [y/N]` と聞かれる。`y`
   - 終わりに `==> Homebrew uninstalled!` と、消さなかったファイルの一覧（`The following possible Homebrew files were not deleted:` の後の `/home/linuxbrew/.linuxbrew/etc/` など）が出る。残りは、この項の手順 3 で消す
   - インターネットに出られないホストでは、[ssh-socks-tunnel.md の手順 1〜3](../ssh-socks-tunnel.md#実施手順) でトンネルを張ったシェルで、この項の手順 1 から貼る
   - **次の手順は、アンインストーラが終わってから貼る**（続けて貼ると確認として食われる）

1. アンインストーラと、残った `/home/linuxbrew` を消して、端末を開き直す。

   ```bash
   {
     rm -f /tmp/uninstall.sh
     sudo rm -rf /home/linuxbrew
     printf '\n\033[7m 確認 \033[0m\n'
     ls -ld /home/linuxbrew
   }
   ```

   - アンインストーラは、formula が置いた設定のファイル（`etc/` の証明書・openssl・dbus の設定など）を残す。`/home/linuxbrew` ごと消す
   - 最後に `ls: '/home/linuxbrew' にアクセスできません: そのようなファイルやディレクトリはありません` と出ればよい
   - 共通設定は Homebrew が無ければ何もしない。`~/.bashrc` の編集は不要

1. 「共通の bash 設定」の手順 3 で bash-completion を入れたホストだけ、RPM を消す。

   ```bash
   sudo dnf remove bash-completion
   ```

   - `削除中:` に `bash-completion`、`未使用の依存関係の削除:` に `pkgconf` 系の 4 つが出る。`[y/N]` に `y`
   - 最初から入っていたホスト（Workstation）では貼らない
   - **次の手順は、`y` と答えてプロンプトに戻ってから行う**

### Flatpak・RPM Fusion・EPEL を消す

1. 確認用のアプリ（Flatseal）を消す。

   ```bash
   sudo flatpak uninstall com.github.tchx84.Flatseal
   ```

   - 消す前に `[Y/n]` で聞かれる
   - アプリが自分のホームに作ったデータ（`~/.var/app/<ID>`）は `uninstall` では消えない。要らなければ手で消す
   - **次の手順は、答えて完了してから貼る**（続けて貼ると答えとして食われる）

1. 使われなくなった runtime を消す。

   ```bash
   sudo flatpak uninstall --unused
   ```

   - 消す前に `[Y/n]` で聞かれる
   - **次の手順は、答えて完了してから貼る**（続けて貼ると答えとして食われる）

1. Flathub から入れたアプリが残っていないか確かめる。

   ```bash
   flatpak list --app --columns=application,origin
   ```

   - **Flathub から入れたアプリが残っていると、Flathub の登録は消せない**
   - **次の手順は、`flathub` のものが無いことを確かめてから貼る**

1. Flathub の登録を消す。

   ```bash
   {
     sudo flatpak remote-delete flathub
     printf '\n\033[7m 確認 \033[0m\n'
     flatpak remotes --show-details
   }
   ```

   - 最後の `flatpak remotes --show-details` が何も出さなければ、リモートが無い状態に戻っている
   - `flatpak` のパッケージ自体は消さない（GNOME のデスクトップでは `gnome-software` が依存している）

1. RPM Fusion（free）のリポジトリを消す。

   ```bash
   sudo dnf remove --noautoremove rpmfusion-free-release
   ```

   - `削除中:` が `rpmfusion-free-release` の 1 つだけになる
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. RPM Fusion の鍵も消すときだけ、その署名鍵を消す。

   ```bash
   sudo rpm -e gpg-pubkey-db85ddd7-67a63d8b
   ```

1. `epel-release` を消す。

   ```bash
   sudo dnf remove --noautoremove epel-release
   ```

   - `削除中:` が `epel-release` の 1 つだけになる（`--noautoremove` が無いと、`dnf-plugins-core` なども一緒に消える）
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. EPEL の鍵も消すときだけ、その署名鍵を消す。

   ```bash
   sudo rpm -e gpg-pubkey-e37ed158-65785fa9
   ```

   - 鍵は、EPEL からパッケージを入れたことがあるとき（「GNOME の表示と入力」の手順 10）だけ登録されている

### システムの設定を戻す

1. コマンドが無いときにパッケージを案内する機能を、入れ直す。

   ```bash
   sudo dnf install -y PackageKit-command-not-found
   ```

   - 開き直した端末から、無いコマンドを打つと、パッケージを探して案内する

1. 「システムの設定」の手順 7 で kdump を止めたときだけ、元に戻す（効くのは再起動の後）。

   ```bash
   {
     sudo sed -i 's/^auto_reset_crashkernel no$/auto_reset_crashkernel yes/' /etc/kdump.conf
     sudo kdumpctl reset-crashkernel --kernel=ALL
     sudo systemctl enable kdump
     printf '\n\033[7m 確認 \033[0m\n'
     grep -n '^auto_reset_crashkernel' /etc/kdump.conf
     sudo grubby --info=ALL | grep -E '^args='
   }
   ```

   - `auto_reset_crashkernel yes` と、`crashkernel=2G-64G:256M,64G-:512M` を含む `args=` の行が出ればよい

1. journal を、メモリーだけに書く既定に戻す（ディスクのログを消す。取り戻せない）。

   ```bash
   {
     sudo rm -f /etc/systemd/journald.conf.d/50-persistent.conf
     sudo journalctl --relinquish-var
     sudo rm -rf /var/log/journal
     sudo systemctl restart systemd-journald
     printf '\n\033[7m 確認 \033[0m\n'
     ls -ld /var/log/journal /run/log/journal
   }
   ```

   - `/var/log/journal` が無い（`アクセスできません`）と、`/run/log/journal` の行が出ればよい
   - `/var/log/journal` を残すと、既定の `Storage=auto` のまま、ディスクに書き続ける
   - `journalctl --relinquish-var` で、journald に `/var/log/journal` を手放させてから消す（手放させずに消すと、動いている journald がすぐに作り直し、再起動の後もディスクに書き続けた）

1. 「システムの設定」の手順 2 で PC の名前を変えたときだけ、元の名前に戻す（`OLD_HOST_NAME` は必ず値を入れる）。

   ```bash
   OLD_HOST_NAME=''   # 「システムの設定」の手順 2 で控えた「変える前:」の名前。<HOSTNAME>
   ```

   ```bash
   if [ -z "${OLD_HOST_NAME}" ]; then echo '中断: OLD_HOST_NAME が空のまま。「システムの設定」の手順 2 で控えた名前を入れて貼り直す' >&2; else
     sudo hostnamectl hostname "${OLD_HOST_NAME}"
     printf '\n\033[7m 確認 \033[0m\n'
     hostnamectl --static
   fi
   ```

   - 控えた名前が出ればよい。元の名前を控えていなければ、推測で戻さない

1. 再起動する。

   ```bash
   sudo systemctl reboot
   ```

   - **次の手順は、起動してログインし、端末を開いてから貼る**

1. 元に戻ったことを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   cat /sys/kernel/kexec_crash_size
   journalctl --list-boots --no-pager
   hostnamectl --static
   xdg-user-dir DOWNLOAD
   ```

   - この項の手順 2 を行ったなら、0 でない数（`268435456` など）が出る
   - `journalctl --list-boots` は、見出しの行（`IDX BOOT ID …`）と、`0` で始まる今の起動の 1 行だけ
   - この項の手順 4 の名前と、[表示と入力を戻す](#表示と入力を戻す)の手順 15 を行ったなら日本語の名前（`/home/<USER>/ダウンロード`）が出る
   - 画面は淡色で、時計は時刻だけ、ウィンドウのボタンは閉じるだけに戻る

1. sudo のパスワード無しの設定を外す。

   ```bash
   {
     sudo rm -f /etc/sudoers.d/nopasswd
     sudo -k
     printf '\n\033[7m 確認 \033[0m\n'
     sudo -n true 2>&1 || true
   }
   ```

   - `sudo: パスワードが必要です`（英語の環境では `a password is required`）が出ればよい
   - この手順の後は、`sudo` がパスワードを聞く。そのため、この節の最後に行う

---

## 注意点

- **パスワードを聞かない sudo**: [手順書の「ログインと sudo」の手順 3](../almalinux-setup.md#ログインと-sudo) の後は、このユーザーで動くものがパスワード無しで root の権限を使える（リードの `[!WARNING]`）。外すのは[システムの設定を戻す](#システムの設定を戻す)の手順 7
- **アプリが再起動を止めることがある**: `sudo systemctl reboot` が `Operation inhibited by …` で断られたら、保存していない文書のあるアプリを閉じてから貼り直す
- **PC の名前を変えた後**: 開いている端末のプロンプトは前の名前のまま。ほかの PC の `~/.ssh/known_hosts` は名前でつないでいれば、新しい名前で鍵を聞かれる
- **SSH はパスワードでもログインできる**: Workstation の既定。公開鍵だけにするなら[SSH を公開鍵だけにする（任意）](../almalinux-setup.md#ssh-を公開鍵だけにする任意)
- **journal は rsyslog と二重に残る**: `/var/log/messages`（rsyslog）にも同じ内容が残る。journal の大きさは、既定でファイルシステムの 10%（4 GiB まで）
- **kdump を止めると、カーネルが落ちたときの記録（vmcore）は残らない**: 原因を調べるときは、[システムの設定を戻す](#システムの設定を戻す)の手順 2 で戻す
- **コマンドが見つからないときに、パッケージを案内しない**: 「システムの設定」の手順 8 の後は、`dnf provides '*/bin/<コマンド>'` で探す
- **EPEL・RPM Fusion は AlmaLinux の配布物ではない**: EPEL は Fedora のプロジェクトが作るリポジトリ。AppStream / BaseOS にあるパッケージは、そちらを使う
  - RPM Fusion の free は「Fedora がライセンス以外の理由で配れないオープンソースのソフト」を配る（RPM Fusion の Configuration の説明）。鍵は「EPEL と RPM Fusion」の手順 2 で照合し、`rpmfusion-free-release` の署名も同じ項の手順 4 で確かめる
  - EL10 向けの RPM Fusion は中身が少ない。調べた範囲では、free に `ffmpeg` 7.1.5 と `gstreamer1-plugins-bad-freeworld`、nonfree に `steam`（i686）がある（[導入元一覧](../tool-catalog.md#導入経路と-el10-での注意)）
  - RPM Fusion の `ffmpeg-libs` は、EPEL の `libavcodec-free` と衝突する（[「Firefox」の手順 9](../almalinux-setup.md#firefox)）
- **Homebrew と同じ名前の実行ファイルを、EPEL から二重に入れない**: 例えば EPEL の `fd-find` は `/usr/bin/fd` を置く。両方入れると、PATH の先頭の Homebrew 版が使われ、`dnf upgrade` で上がるのは使われないほうになる（[btop.md の注意点](btop.md#注意点)）
- **ほかの手順書のロールバックでは、EPEL・RPM Fusion を消さない**: 使う手順書が複数ある。消すときはこの文書の[ロールバック](#ロールバック)で行う
- **Flatpak は容量が大きい**: アプリ本体に加え、runtime・翻訳・GL ドライバ・コーデックの拡張の容量も確保する。`sudo flatpak uninstall --unused` で、使われなくなった runtime を消せる
- **Flatpak のアプリは `dnf upgrade` では上がらない**: [更新](../almalinux-setup.md#更新)の `sudo flatpak update` を別に実行する
- **Flatpak の権限はアプリごとに違う**: 入れる前に表示される権限の一覧を確かめる。入れた後は `flatpak info --show-permissions <ID>` で見られ、Flatseal か `sudo flatpak override` で変えられる
- **Flathub のアプリの公開元を確認する**: 検証済み（公開元がアプリの作者本人だと確認されたもの）と未検証（第三者が包んでいる場合がある）の 2 種類がある。[導入元一覧](../tool-catalog.md#gui)の表に書き分けてある
  - Microsoft Edge などは Flathub でも x86_64 だけ（[導入元一覧](../tool-catalog.md#aarch64-で使えないもの)）
  - [Firefox](../almalinux-setup.md#firefox) のように RPM で入れたものを Flathub からも入れると、メニューに同じ名前が 2 つ並ぶと見込まれる
- **`gsettings` は、書けなかったときも終了コード 0 で終わる**: 読み戻しで確かめる。この文書の `gsettings` は `/usr/bin/gsettings` で呼ぶ（Homebrew の `gsettings` は、dconf ではなくファイルに書き、読み戻しでは変わったように見える）
- **ほかの入力ソースは消える**: 「日本語入力」の手順 2 の `set` は一覧をまるごと置き換える
- **Anthy はひらがなで始まる**: RHEL のパッチで既定の入力モードがひらがなになっている。英字を打つなら、Super+Space で配列（「Neovim」の手順 3 の後は「英語 (US)」）に戻す。Anthy の中の切り替えのキー（Ctrl+Space・Ctrl+J）は、「Neovim」の手順 3 で外れる
  - 変換は Mozc に比べて弱いと言われる（本書では比べていない）。よく使う語は、一緒に入る辞書のツール `kasumi-unicode` で登録する
  - 入力モードやキーの割り当ての設定画面は `/usr/libexec/ibus-setup-anthy`（アプリの一覧には出ない）
- **Caps Lock の働きは無くなる**: 「GNOME の表示と入力」の手順 3 は Caps Lock を Ctrl にするだけ。大文字を続けて打つときは Shift を押す。JIS 配列では「英数」（Caps Lock）のキーが Ctrl になる
- **Alt+Tab はウィンドウを切り替える**: アプリごとに切り替えるのは Super+Tab
- **拡大率の設定は mutter の実験的な機能**: GNOME の更新で、名前や働きが変わることがある。うまく動かなければ、[表示と入力を戻す](#表示と入力を戻す)の手順 8 で外す
- **トレイアイコンの拡張は EPEL のもの**: GNOME Shell の更新に遅れることがある。拡張が動かなくなったら、[表示と入力を戻す](#表示と入力を戻す)の手順 11 で無効にする
- **フォルダーの名前を聞かれたら**: ログインのときに「標準フォルダーの名前を現在の言語に合わせて更新しますか?」の窓が出たら、「次回から表示しない」をオンにして「古い名前のままにする」を押す（日本語の名前に戻さない）
- **画面オフ・画面ロック・自動サスペンドを止める節の dconf のファイルの型**: 文字列は `'nothing'` のように引用符で囲む。`idle-delay` のような uint32 は `uint32 0` と書く
  - 引用符が無いと `dconf update` が失敗し、データベースは前の内容のまま残る。`uint32` が無いと、エラーにならずに無視される
  - Server with GUI の `gnome-settings-daemon-server-defaults` の override も、`power-button-action=nothing` に引用符が無く、読み飛ばされている（`sleep-inactive-ac-timeout=0` は効いていて、電源につないでいる間は眠らない）
  - 自分で変えた値（`gsettings` と設定アプリが書く user-db）は、`/etc/dconf/db` のデータベースより優先される。その節の手順 2 を `gsettings` で行うのはこのため
  - 仮想マシンの中では、gnome-settings-daemon は放置によるサスペンドをしない。電源ボタンは `nothing` 以外だと電源オフになる
  - その節の手順 4 の後は、設定アプリに「自動サスペンド」の行が出ない。戻すなら `gsettings` か、その節の手順 6〜9 で行う
- **`~/.inputrc` を作ったら `$include /etc/inputrc` を忘れない**: 無いと Home / End / Delete / Ctrl+矢印が効かなくなる
- **`globstar` は `rm` でも効く**: `rm **` はサブディレクトリの中まで消す。`**` を打つ前に `echo **` で見る
- **`autocd` は、ディレクトリと同じ名前のコマンドが無いときだけ**: コマンドの探索が先で、見つからなかったときにディレクトリとして試す
- **`show-all-if-ambiguous` は候補が多いと長い一覧になる**: `ls /usr/share/<Tab>` のような場所では、既定と同じく `Display all 123 possibilities? (y or n)` と聞かれる
- **Homebrew の導入・更新は一般ユーザーで行う**: 通常のホストでは、インストーラや `brew install` などの管理操作は root を拒否する。ただし**実行するユーザーが `sudo` できる必要がある**（`/home/linuxbrew` を作るため）
- **Homebrew の導入先を変えるとすべてソースビルドになる**: [検証記録](../verification/almalinux-setup.md#統合前の記録-homebrewもとは-homebrewmd)
- **PATH の先頭が Homebrew になる**: `brew shellenv` は `/home/linuxbrew/.linuxbrew/bin` を `PATH` の**先頭**に足す。同じ名前の RPM が入っていると Homebrew 版が勝つ（bat・[gdu](../gdu.md) で実際に問題になる）
- **`sudo <tool>` は、そのままでは使えない**: sudo の PATH（`secure_path`）にも root の `PATH` にも、Homebrew は入っていない
  - `sudo <tool>` で使うなら、[Homebrew を sudo でも使う（任意）](../almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節を通す（`sudo -s`・`sudo -i` のシェルでも使えるようになる）
  - root のシェル（`su -`、root のログイン、`sudo -i`）で使うなら、[Homebrew を root のシェルでも使う（任意）](../almalinux-setup.md#homebrew-を-root-のシェルでも使う任意)の節を通す
  - どちらも通さないなら、RPM で入れるか、フルパス（`/home/linuxbrew/.linuxbrew/bin/<tool>`）を渡す。bat で root のファイルを読むなら、`sudo cat` か、フルパスの `sudo /home/linuxbrew/.linuxbrew/bin/bat`
- **`brew install` は、依存や依存先も含む計画なら端末で `[y/n]` を聞く**（Homebrew 7.0.7 の既定の ask mode）
  - 同じブロックに後ろの行があると、その文字が答えとして読まれ、`n` で中止になる。`brew install` は、`[y/n]` に答えてから次の手順を貼る
  - 7.0.7 のヘルプでは、指定した formula / cask だけを入れる計画と、TTY が無い実行では確認を省く。端末では表示に従い、確認を求められたら答える
  - `brew upgrade` も 7.0.7 では ask mode が既定。名前を指定した場合はその名前以外も更新する計画、名前を省略した場合は更新対象があるときに、TTY で確認する
  - 導入・更新が終わり、プロンプトに戻ってから次の手順を貼る。確認を省く指定は `HOMEBREW_NO_ASK=1`、または `brew install` / `brew upgrade` の `--no-ask` / `--yes` / `-y`
- **不要な依存は自動で消えることがある**: Homebrew 7.0.7 の `brew uninstall` と `brew cleanup` は、不要になった依存を既定で自動削除する
  - 自動削除を止めるときは、そのコマンドに `HOMEBREW_NO_AUTOREMOVE=1` を付ける。明示的な `brew autoremove` は、残った不要な依存を消すための操作
- **`~/.bashrc` を読まない文脈では見えない**: cron や一部の非対話シェルでは `brew shellenv` が走らないので、Homebrew で入れたコマンドが見つからない。スクリプトからはフルパスで呼ぶ
- **Homebrew はユーザーごとではなく、ホストに 1 つ**: `/home/linuxbrew` は共有なので、別ユーザーが使うには、そのユーザーにも bash の共通設定を導入する（書き込みには所有者の権限が要る）
- 古い版とキャッシュを掃除するなら `brew cleanup` を実行する
- **Homebrew は匿名の利用統計が既定で有効**: 止めるなら `brew analytics off`
- **starship・zoxide・fzf の初期化は、共通の bash 設定が読む**: `brew install` だけではプロンプトも `z` も変わらない。共通設定が starship → WezTerm → zoxide、Homebrew の補完 → fzf の順に読む。端末を開き直すと効く
  - WezTerm のシェル統合の `A` / `B` は失われる: `PS1` が毎回作り直されるため。並びによらない（[bash の参考資料の読む順番](https://github.com/ryo-aoki-pc/bash/blob/main/docs/reference/readme.md#読む順番)）
  - root は別に導入する: root 自身にも bash の共通設定を導入した場合にだけ、root のシェルで初期化される（[Homebrew を root のシェルでも使う（任意）](../almalinux-setup.md#homebrew-を-root-のシェルでも使う任意)）
- **starship はプロンプトごとに外部プロセスが起動する**: git の状態を調べるので、大きなリポジトリや遅いストレージ（Raspberry Pi の microSD）では体感できるほど遅くなることがある。`starship timings` で犯人を探し、要らないモジュールは `disabled = true` で切る
- **starship の記号には Nerd Font が要るものがある**: 既定のプロンプト記号 `❯` は普通のフォントでも出るが、プリセットによっては Nerd Font 前提。無い端末では `plain-text-symbols` / `no-nerd-font` を当てる
- **zoxide の `--cmd cd` は影響範囲が広い**: `cd` を置き換えると、シェル関数やエイリアス経由の `cd` の挙動も変わる。既定の `z` から始めるのが無難
- **zoxide の学習はプロンプトを出すたびに走る**: `PROMPT_COMMAND` にフックが入り、そのときの今のディレクトリを記録する。yazi の `z` キーと、zoxide の対話関数 `zi`（fzf で候補を選ぶ）はこのデータベースを共有する
- **fzf を入れると、readline の Ctrl+R と Ctrl+T は使えなくなる**: `reverse-search-history` と `transpose-chars`。Ctrl+S（前方の検索）は残る
  - Ctrl+R は実行しない: 選んだ行がプロンプトに入るだけ。確かめてから Enter
  - Alt+C は端末しだい: Alt を ESC の前置きで送らない端末では届かない。`ESC` を押してから `c` でも同じ
  - `**` の補完は、fzf が知っているコマンドだけ。ほかのコマンドに付けるには `_fzf_setup_completion path <コマンド>`（README）
  - tmux の中でも同じキーで動く: `M-c` は tmux のプレフィックスとぶつからない（`Ctrl+b` が既定）
- **`alias ls=eza`・`alias cat=bat` は勧めない**: `ll` / `la` / `lt` と `bat` を打つ運用を勧める
  - eza は GNU `ls` の全オプションを実装していない（`-G` の意味が違い、`--time-style` に渡せる値も別物）
  - bat は既定でページャ（`less`）を開くので、`cat` のつもりで打つと画面が切り替わる。`-A` / `-v` / `-e` などフラグの意味も GNU `cat` と違う
  - エイリアスは対話シェルにしか効かないのでスクリプトは壊れないが、**壊れないぶん挙動の違いに気づきにくい**
- **エイリアスの確認に `type -t` は使えない**: bash は非対話シェルでエイリアスを展開しないため、`type -t ll` はエイリアスを見つけられない（`alias ll` なら確認できる）
- **eza のアイコンには Nerd Font が要る**: `--icons=always` はグリフを出すだけなので、フォントが無い端末では豆腐になる（[HackGen Console NF](../almalinux-setup.md#hackgen-console-nf)）
- **eza の `--git` は大きなリポジトリで遅くなる**: 毎回 git の状態を引くため。気になるなら `--no-git`、リポジトリの一覧だけなら `--git-repos-no-status`
- **bat を EPEL 版と二重に入れない**: どちらも `bat` という名前で、PATH の先頭にある Homebrew 版が勝つ
- **bat のテーマの見え方は端末に依存する**: `ansi` 以外を選ぶと端末の配色とぶつかることがある。true color が出るかは端末側の設定次第
- **Claude Code の `Ctrl+B` は、tmux の中では 2 回押す**: `Ctrl+b` → `Ctrl+b` で中のアプリに `Ctrl+b` を送る
- **BaseOS の tmux と混ぜない**: 同じソケットを使うので、版の違うクライアントからはセッションにつなげない（[検証記録](../verification/almalinux-setup.md#tmux-実施手順--手順-2-補足-baseos-の-tmux-と並べたとき)）
- **tmux のセッションがログアウトしても残るのは、`KillUserProcesses=no` のとき**: AlmaLinux 10 の既定。`yes` にしたホストでは、ログアウトでセッションも止まるはず
- **PC を再起動すると、tmux のセッションも中のコマンドも消える**: 起動時に始め直す仕組みは、本書では作らない
- **Remote Control の性質**（公式ドキュメント。[Windows の手順書の注意点](windows-claude-remote-control.md#注意点)にも同じ内容）
  - このホストからは外向きの HTTPS だけで、受信のポートは開けない
  - つないでいる間、会話の転写（メッセージ・応答・ツールの動き）は Anthropic のサーバーに保存される
  - ネットワークが約 10 分切れると、`claude remote-control` は自分で終わる。tmux の中のシェルは残るので、[Claude Code を tmux の中で動かす（任意）](../almalinux-setup.md#claude-code-を-tmux-の中で動かす任意)の手順 8 で入り、その節の手順 4 のコマンドを打ち直す
  - 止めてから約 4 時間以内なら、`claude remote-control` で同じセッションが戻る
  - `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`・`DISABLE_GROWTHBOOK`・`ANTHROPIC_BASE_URL`（`api.anthropic.com` 以外）があると使えない
- **tmux でマウスを on にすると、Claude Code の画面でもホイールは tmux が受け取る**: コンテナの Claude Code（ログインしていない最初の画面）は、マウスの報告も代替画面も使っていなかった（`#{mouse_any_flag}` と `#{alternate_on}` が 0）。ホイールは tmux のコピーモードに入る
- **Git: リポジトリの `local` の設定は `global` に勝つ**
  - リポジトリの中で `git config --show-scope --get pull.rebase` と打つと、効いている値と場所が出る
  - `.gitattributes` の `text`・`eol` も、`core.autocrlf` より優先される
- **Git: `core.autocrlf=false` は、CRLF を LF に直さない**
  - Windows のエディタが CRLF で保存したファイルは、CRLF のままコミットされる
  - 改行を揃えたいリポジトリには `.gitattributes` を置く
- **Git: `sudo git` や root には効かない**: root は root の `~/.gitconfig` を読む
- **Git: `rerere` は、覚えた解き方を黙って当てる**
  - 当てた後も `git add` はしないので、`git diff` で確かめてから add する
  - 間違った解き方を覚えたら、`git rerere forget <ファイル>` で忘れさせる
- **Firefox: チャンネルが変わる**: ESR（年 1 回のメジャー更新）から Rapid Release（4 週間ごと）に移る
  - 企業ポリシーで ESR を使っている場合は、この手順を使わない
- **Firefox: セキュリティ更新の出所が変わる**: AppStream 版は AlmaLinux が、mozilla 版は Mozilla が直接出す
  - `dnf upgrade` の対象になるのは同じだが、AlmaLinux のエラータ（`dnf updateinfo`）には載らない
- **Firefox: ダウングレードするとプロファイルを読めないことがある**: 156 で開いたプロファイルを 140 で開くと、「新しいバージョンの Firefox で作成されたプロファイル」と警告が出る
  - 戻す前提があるなら、先に `~/.mozilla/firefox`（新しく作られた場合は `~/.config/mozilla/firefox`）を退避しておく
- **Firefox: 言語パックは本体と同時に上げる**: バージョンが食い違うと UI が英語に戻る。`dnf upgrade` 全体を流していれば自動で揃う
- Firefox: パッケージの導入・削除が終わったことを確かめる
- **Firefox: RPM Fusion は Fedora の外のリポジトリ**: free は「Fedora がライセンス以外の理由で配れないオープンソースのソフト」を配る（RPM Fusion の Configuration の説明）
  - 鍵の照合と、`rpmfusion-free-release` の署名の確かめ方は [「EPEL と RPM Fusion」の手順 2〜5](../almalinux-setup.md#epel-と-rpm-fusion) にある
- **Firefox: FFmpeg を入れたら Firefox を起動し直す**: 起動中の Firefox は読み直さない（[「Firefox」の手順 11](../almalinux-setup.md#firefox)）
- **Firefox: EPEL の `libavcodec-free` とは同居できない**: 入っていると「Firefox」の手順 8 が止まる。残したままだと H.264 が再生できない（同じ項の手順 9）
- **Firefox: aarch64 では Widevine を必要とするコンテンツの再生を前提にしない**
- **HackGen Console NF: 自分のユーザーにしか入らない**: 置き場所が `~/.local/share/fonts` なので、別のユーザーや root で動くアプリからは見えない
- **HackGen Console NF: `unzip` が要る**: Homebrew の formula（ボトル）は `unzip` 無しで入るが、zip で配られる cask は展開に `unzip` を使う
- **HackGen Console NF: Console 版は記号が半角になる**: 矢印などが 1 セル幅で出る（`wezterm ls-fonts --text '→'` で `cells=1`）
  - Console ではない通常版（HackGen / HackGen35）は NF 版の zip に入っておらず、NF 無しの cask `font-hackgen` にある
- **HackGen Console NF: NF 版と NF 無しの版は別の cask**: `font-hackgen-nerd`（Console の 2 ファミリー × NF）と `font-hackgen`（4 ファミリー、アイコン無し）
  - ファミリー名は NF 版だけ末尾に ` NF` が付く
- **HackGen Console NF: ファミリー名は `HackGen Console NF`**（スペース入り）。ファイル名（`HackGenConsoleNF-Regular.ttf`）や PostScript 名（`HackGenConsoleNF-Regular`）とは違う。アプリの設定にはファミリー名を書く
- **HackGen Console NF: 等幅だけを一覧に出すアプリ**: fontconfig はこのフォントを `spacing=90`（`dual`）と見なす
- **HackGen Console NF: GNOME の端末や VS Code など WezTerm 以外のアプリ**: それぞれの設定でファミリー名 `HackGen Console NF` を指定する
- **HackGen Console NF: Powerline の記号**: WezTerm は `U+E0B0` などの一部の記号を既定で自分で描く（`custom_block_glyphs`）。ほかの端末ではフォントのグリフが使われる
- **WezTerm: EL9 向けバイナリを EL10 で使っている。** 作者はこの組み合わせを保証していない
  - いまは EL9/EL10 のライブラリ soname がすべて一致しているので動く
  - 将来 COPR 側のビルド環境（EL9）と EL10 の間で soname が食い違えば、`dnf upgrade` が依存関係で止まるか、入っても起動しなくなる
  - 止まったときは `dnf upgrade --exclude='wezterm*'` で他を先に上げ、COPR に `epel-10` chroot が追加されていないか[プロジェクトページ](https://copr.fedorainfracloud.org/coprs/wezfurlong/wezterm-nightly/)を見る
  - 追加されていたら、`sudo dnf copr remove wezfurlong/wezterm-nightly` → `sudo dnf copr enable wezfurlong/wezterm-nightly`（chroot 省略）で乗り換えられる
- **WezTerm: nightly は毎日変わる。** `dnf upgrade` のたびに WezTerm も更新される
  - 安定版に固定したければ、COPR ではなく GitHub Releases の安定版 rpm（`wezterm-<version>-1.centos9.rpm`、こちらも EL10 向けは無い）か Flathub を使う
- **WezTerm: `TERM` は既定の `xterm-256color` のまま**。EL10 の `ncurses-base` に `wezterm` の terminfo は無い（`infocmp wezterm` → rc=1、`ncurses-term` も未導入）

  設定で `term = "wezterm"` にするなら、先に公式ドキュメントの手順で terminfo を入れる:

  ```bash
  tempfile=$(mktemp) \
    && curl -o "$tempfile" https://raw.githubusercontent.com/wezterm/wezterm/main/termwiz/data/wezterm.terminfo \
    && tic -x -o ~/.terminfo "$tempfile" \
    && rm "$tempfile"
  ```

- **WezTerm: `/etc/profile.d/wezterm.sh` は全ユーザーの対話シェルに読み込まれる。** WezTerm 以外の端末でも OSC シーケンスを出す（大半の端末は無視する）
  - `bash-preexec` を内蔵しているので、`PROMPT_COMMAND` や `DEBUG` trap を自前で使っている環境では干渉に注意
  - 無効化は `WEZTERM_SHELL_SKIP_ALL=1`。自分用の WezTerm の設定（「WezTerm」の手順 5）を使うなら、止めない（その docs/install.md の注意点）
- **WezTerm: 既存の `_copr:...yazi.repo` など EL10 向け COPR と混在させても問題ない。** repo ごとに `baseurl` の chroot が違うだけ
- **git-delta: `core.pager` は PATH に `delta` がある文脈でしか動かない**
  - Homebrew の PATH は `~/.bashrc` の `brew shellenv` で通っているので、`~/.bashrc` を読まない文脈（cron、一部の非対話シェル、他ユーザー、`sudo -i` しない root）で `git diff` を打つと `delta: command not found` になる
  - 固くしたいなら、フルパスで指定する: `git config --global core.pager /home/linuxbrew/.linuxbrew/bin/delta`
- **git-delta: 表示だけを変える。差分の中身は変わらない**: `git diff > patch.diff` はページャを通らないので従来どおりのパッチが出る。`git apply` や CI の挙動には影響しない
- **git-delta: `sudo git` には効かない**: root は root の `~/.gitconfig` を読むので、この設定は入っていない
- **git-delta: `interactive.diffFilter` が変えるのは `git add -p` の表示だけ**: 選択の操作自体は git のまま
- **git-delta: lazygit は `core.pager` を見ない**: 0.65.1 では別途 `git.diffRenderers` を設定する（自分用の lazygit の設定（[「lazygit」の手順 2](../almalinux-setup.md#lazygit)）が設定する）
- **git-delta も、Homebrew の注意のとおり**: PATH の先頭が Homebrew になる、`~/.bashrc` を読まない文脈では見えない、など
- **Neovim: EPEL の `neovim` と両方入れない**: PATH の先頭が Homebrew なので、Homebrew 版が勝つ。どちらか一方にする
- **Neovim: `sudo nvim` は、そのままでは動かない**: sudo の PATH に Homebrew が無い
  - [Homebrew を sudo でも使う（任意）](../almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節を通すと動く。root の Neovim は `/root/.config/nvim` を読む
  - root のファイルを自分の設定で編集するなら、`sudo nvim` ではなく `sudoedit` を使う（その節を通すか、`SUDO_EDITOR` にフルパスを渡す。[「Neovim」の手順 4](../almalinux-setup.md#neovim)）
  - root のシェル（`su -`、root のログイン、`sudo -i`）で使うなら、[Homebrew を root のシェルでも使う（任意）](../almalinux-setup.md#homebrew-を-root-のシェルでも使う任意)の節を通す（`sudo nvim` は、その節だけでは動かない）
- **Neovim: プロバイダは別途**: Python / Node.js のプラグインを使うなら、それぞれ `pynvim` / `neovim` パッケージを入れる。Node.js 本体は、[「Neovim」の手順 3](../almalinux-setup.md#neovim) の自分用の設定の導入で入る
- **Neovim: 設定とプラグインは更新に追従しない**: `brew upgrade neovim` でメジャー版が上がると、古い API を使うプラグインが壊れることがある
- **Neovim: `vi` は RPM の `vim-minimal`**: 別物が `/usr/bin/vi` として残っている。エイリアスを張らない限り `vi` は Neovim にならない
- **lazygit も、Homebrew の注意のとおり**: PATH の先頭が Homebrew になる、`sudo lazygit` はそのままでは使えない、など
  - RPM 版と両方入れると分かりにくくなるので、どちらか一方にする
- **lazygit: COPR 経路は「有効化は成功するのに入らない」**: `dnf copr enable` が通っても、メタデータが取れなければ `dnf install` は `No match for argument` になるだけで、原因は警告行にしか出ない
  - COPR を使う前に `curl -sS -o /dev/null -w '%{http_code}\n' -L <chroot の repodata/repomd.xml>` で 200 が返るか確かめると早い
- **lazygit: git が要る**: lazygit は git のラッパーなので、git の設定（`user.name` / `user.email`、認証）はそのまま効く
- **lazygit: 設定ファイルは自分で作る**: `lazygit --print-config-dir` が返すディレクトリは、初回起動時には空のことがある
- **GitHub CLI: EPEL と公式リポジトリが両方有効だと、更新のたびに両者を比較する**: バージョンが高い公式側が選ばれるので、実害は無い
  - EPEL 側だけを使いたいなら、`exclude=gh` を `gh-cli` 側に書くか、リポジトリを無効にする
- **GitHub CLI: トークンの置き場所**: OS の資格情報ストアを優先し、使えない場合は `~/.config/gh/hosts.yml` に平文で保存する。保存先は `gh auth status` で確認し、平文ファイルをバックアップや共有に混ぜない
  - `gh auth logout` はローカルの認証情報を外す。GitHub 側のトークンの失効は別の操作（[Git の道具を消す](#git-の道具を消す)の手順 5）
- **GitHub CLI: `gh` は git を呼ぶ**: `gh repo clone` などは git に依存する。最小構成のホストでは git 一式が付いてくる
- **GitHub CLI: 全アーキ共通リポジトリ**: `dnf list gh` に `i386` / `armv6hl` の行が出るのは正常
- **yazi も、Homebrew の注意のとおり**: PATH の先頭が Homebrew になる（同名のコマンドは RPM 版より Homebrew 版が勝つ）、`sudo yazi` はそのままでは使えない（root で使うなら、[Homebrew を sudo でも使う（任意）](../almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節を通すか、フルパスで呼ぶ）、など
  - RPM 版と両方入れると分かりにくくなるので、どちらか一方にする
- **yazi: 画像プレビューは端末に依存する**: Kitty / WezTerm / foot などのグラフィックプロトコル、または Überzug++ が要る。GNOME 端末では文字ベースの表示になる
- **yazi: `q` と `Q`**: `y` 関数経由なら `q` で終了時にそのディレクトリへ移動し、`Q` なら移動しない
- **yazi: Homebrew の更新は自分の責任で**: `brew upgrade` は指定しなければ全 formula を上げる。yazi だけ上げるなら `brew upgrade yazi`
- **Claude Code: `latest` は不具合のある版もそのまま届く**: `stable` なら飛ばされる版も入る。困ったら [Claude Code を stable チャンネルに切り替える（任意）](../almalinux-setup.md#claude-code-を-stable-チャンネルに切り替える任意)
- **Claude Code: 自動更新しない**: ネイティブインストーラ版と違い、dnf 版は自分では更新しない
  - `CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE=1` は Homebrew / WinGet 向けで、apt / dnf / apk は root 権限が要るため対象外
- **Claude Code: 更新の通知が先に来ることがある**: リポジトリに新しい版が届く前に「更新がある」と言われることがある。その場合は時間をおいて `sudo dnf upgrade claude-code`
- **Claude Code: `claude` が 2 つ入ると混乱する**: ネイティブインストーラや npm で入れたものが `~/.local/bin/claude` にあると、PATH の順序でそちらが勝つ。`command -v claude` と `claude doctor` で確認する
- **Claude Code: アカウントが要る**: 無料の claude.ai プランでは使えない
- **Claude Code: 設定ファイルは残る**: `dnf remove` しても `~/.claude` は消えない
- **Claude Code: `-p` は許可を聞けない**: 許可の要るツールは断られ、JSON の `permission_denials` に残る。要るものは `--allowedTools` で渡す（[Claude Code の使い方の基本](../almalinux-setup.md#claude-code-の使い方の基本)）
- **Claude Code: SSH を切ると止まる**: SSH のシェルで起動した `claude` は、切断で止まる。動かし続けるなら tmux の中で起動する（[Claude Code を tmux の中で動かす（任意）](../almalinux-setup.md#claude-code-を-tmux-の中で動かす任意)）
- **Grok Build: 非公式の grok-cli と名前がぶつかる**: npm の `grok-dev`（もとは `@vibe-kit/grok-cli`）も `grok` のコマンドと `~/.grok` を使う。両方は入れない
- **Grok Build: `agent` のコマンドも入る**: 中身は `grok` と同じ。インストーラーは、`~/.local/bin` に `agent` があっても `ln -sf` で置き換える（Cursor の CLI など、ほかの `agent` を使っているなら、入れた後に確かめる）
- **Grok Build: `XAI_API_KEY` を設定すると、ログインが無いときに API キーで動く**（API の従量課金になる）。サブスクリプションで使うなら設定しない
- **Grok Build: sandbox は既定で無効**: `--sandbox workspace`・`--sandbox read-only` などで、書ける場所を絞れる。Linux では Landlock が有効なカーネルと bubblewrap が要る（`sudo dnf install -y bubblewrap`。GNOME のデスクトップの PC には Flatpak と一緒に入っている）。Windows には sandbox が無い（公式の文書は Linux と macOS だけ）
  - `runtime-socket deny path` と `Permission denied (os error 13)` が出たら、ソケットの親ディレクトリの検索権限を確かめる。ソケット本体の権限を緩める必要は無い。このときの Grok のレビューは動いていないので、[コーディングエージェントの共同作業の「相互にレビューする」](../coding-agents.md#相互にレビューする)の代替へ進む
  - カーネルの保護を適用できないエラー（`could not apply the '<プロファイル>' sandbox profile`）が出たら、Landlock が有効なカーネルで OS を起動してから、同じ sandbox を再試行する。bubblewrap を入れただけで解決したとは扱わない（[起動できないときの補足](../reference/almalinux-setup.md#grok-build-注意点-linux-の-sandbox-を起動できないとき)）
- **Grok Build: Claude Code の指示書も読む**: AGENTS.md のほかに、CLAUDE.md・CLAUDE.local.md・`~/.claude/CLAUDE.md` も読む（読み込まれたものは `grok --trust inspect` の `Project Instructions`）。読むのは信頼したフォルダーだけ
- **Grok Build: 会話のデータの扱い**: 学習と保存に使うかは、Grok の中の `/privacy`（Coding data, retention, and training の Opt in / Opt out）で選ぶ（[参考資料](../reference/almalinux-setup.md#grok-build-注意点-会話のデータの扱い)）
- **Codex・Grok のプラグインはどのプロジェクトでも動く**: 自分のユーザーに入るので、どのディレクトリの Claude Code でも、起動と終了のたびに `node` で hook を動かす。外すときは、Node.js より先にプラグインを外す（[AI エージェントとプラグインを消す](#ai-エージェントとプラグインを消す)の手順 1 の後に、[端末とエディタを消す](#端末とエディタを消す)の手順 5）
