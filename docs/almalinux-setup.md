# AlmaLinux 10 の初期設定の手順（インストール直後の更新・sudo・SSH・導入元・日本語入力・GNOME・シェルのツール・Git・Firefox・WezTerm・Neovim・AI エージェント）

## 実施手順

- [検証記録](verification/almalinux-setup.md)・[参考資料](reference/almalinux-setup.md)・[ロールバックと注意点](extra/almalinux-setup.md)

> [!IMPORTANT]
> - **すべて、この PC の GNOME のデスクトップで、インストールのときに作った管理者（`wheel` の一員）のユーザーとして行う**。[ログインと sudo](#ログインと-sudo)の手順 2 で開く端末に貼り、[WezTerm](#wezterm)の手順 5 で WezTerm を起動し直した後は、WezTerm のタブに貼る。`sudo -i`・`su -` のシェルでは行わない（`gsettings` はログインしているユーザーの設定だけを変え、Homebrew は root での実行を断る。git の設定も root の `~/.gitconfig` に書かれる）
> - 前提: AlmaLinux 10 の Workstation を入れた直後で、インターネットにつながっていること。インターネットに出られないホストの Homebrew は、[homebrew-offline.md](homebrew-offline.md) から入れる
> - 前提: AI エージェントと GitHub のアカウント。Claude Code は Pro / Max / Team / Enterprise か Console（無料の claude.ai プランでは使えない）、Codex CLI は Codex を利用できる ChatGPT のアカウント（API キーで使うなら API 側の従量課金）、Grok Build は grok.com のアカウント（発表時の対象は SuperGrok と X Premium+。今の対象は xAI の案内で確かめる）、GitHub CLI は GitHub のアカウント
> - **[Grok Build](#grok-build)の手順 2 のインストーラーは、`~/.bashrc` の末尾に PATH と補完のブロックを足す**（共通の bash 設定とは別。[参考資料](reference/almalinux-setup.md#grok-build-実施手順--手順-2-インストーラーが置くものと-bashrc)）
> - **sudo のパスワードを聞かれるのは 1 回だけ**（[ログインと sudo](#ログインと-sudo)の手順 3。この手順から後の `sudo` は聞かない）
> - **対話入力のある手順**: [ログインと sudo](#ログインと-sudo)の手順 3（パスワード）、[OS とファームウェアの更新](#os-とファームウェアの更新)の手順 1（`[y/N]` と AlmaLinux の鍵の確認）・2（LVFS を有効にするか）・3（ファームウェアの更新があるとき）、[システムの設定](#システムの設定)の手順 8（`[y/N]`）、[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 4（`[y/N]`）、[Flatpak と Flathub](#flatpak-と-flathub)の手順 4（確認 2 回）、[GNOME の表示と入力](#gnome-の表示と入力)の手順 10（`[y/N]` と EPEL の鍵の確認）、[Homebrew](#homebrew)の手順 2（RETURN）、[シェルのツール](#シェルのツール)の手順 1（`[y/n]`）、[tmux を試す](#tmux-を試す)の手順 1・2（tmux の画面）、[Firefox](#firefox)の手順 5・8・9（`[y/N]`）、[WezTerm](#wezterm)の手順 1（`[y/N]`）・3（`[y/N]` と COPR の鍵の確認）、[git-delta](#git-delta)の手順 2・[Neovim](#neovim)の手順 1・[lazygit](#lazygit)の手順 1・[yazi](#yazi)の手順 2（Homebrew の確認）、[Neovim](#neovim)の手順 3（LazyVimStarter の `[y/N]` と Neovim の画面）、[lazygit](#lazygit)の手順 4（lazygit の画面）、[GitHub CLI](#github-cli)の手順 2（鍵の確認 2 回）・3（`gh auth login`）、[yazi](#yazi)の手順 5（yazi の画面）、[Claude Code](#claude-code)の手順 3（`[y/N]` と鍵の確認）・5（Claude Code の画面）、[Codex CLI](#codex-cli)の手順 3（`Start Codex now?`）・5（ログイン）・8（Codex の画面）、[Grok Build](#grok-build)の手順 4（ログイン）・7（Grok の画面）、[再起動と確認](#再起動と確認)の手順 8（Neovim の画面）。**目で確かめてから次へ進む手順**: [EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 2、[Flatpak と Flathub](#flatpak-と-flathub)の手順 2、[シェルのツール](#シェルのツール)の手順 9、[Firefox](#firefox)の手順 2
> - **画面で行う手順**: [ログインと sudo](#ログインと-sudo)の手順 1・2、[シェルのツール](#シェルのツール)の手順 2、[キー操作を試す](#キー操作を試す)の手順 1〜5（キーを押して確かめる）、[Firefox](#firefox)の手順 7・11、[WezTerm](#wezterm)の手順 5（WezTerm を起動し直す）、[Neovim](#neovim)の手順 4・[yazi](#yazi)の手順 4（WezTerm の新しいタブを開く）、[WezTerm と HackGen Console NF をデスクトップで使う](#wezterm-と-hackgen-console-nf-をデスクトップで使う)の手順 3、[GitHub CLI](#github-cli)の手順 4・[Claude Code](#claude-code)の手順 5・[Codex CLI](#codex-cli)の手順 6・[Grok Build](#grok-build)の手順 5（ブラウザでのログイン）、[再起動と確認](#再起動と確認)の手順 2・4〜8（同じ項の手順 5 はキーを押して確かめる）。**再起動**: [OS とファームウェアの更新](#os-とファームウェアの更新)の手順 5（要るときだけ）、[再起動と確認](#再起動と確認)の手順 1。**条件付きの手順**: [OS とファームウェアの更新](#os-とファームウェアの更新)の手順 5、[システムの設定](#システムの設定)の手順 2・4・7、[Git](#git)の手順 7、[Firefox](#firefox)の手順 9、[HackGen Console NF](#hackgen-console-nf)の手順 3、[再起動と確認](#再起動と確認)の手順 4

- 上から順にコードブロックを貼る。[システムの設定](#システムの設定)の手順 1 の変数は、新しい端末を開いたら貼り直す（[シェルのツール](#シェルのツール)の手順 2 より後では使わない）
  - [Git](#git)・[Firefox](#firefox)・[HackGen Console NF](#hackgen-console-nf)・[git-delta](#git-delta)・[yazi](#yazi)・[Claude Code](#claude-code)の手順 1 の変数は、その項の中で新しい端末を開いたら貼り直す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 項目ごとの手順（要らない項目の手順は飛ばしてよい。[ログインと sudo](#ログインと-sudo)の手順 1〜3、[OS とファームウェアの更新](#os-とファームウェアの更新)の手順 1・4・5、[システムの設定](#システムの設定)の手順 1、[共通の bash 設定](#共通の-bash-設定)の手順 1・2、[Homebrew](#homebrew)の手順 1〜3、[シェルのツール](#シェルのツール)の手順 1・2、[Git](#git)の手順 1〜6、[Firefox](#firefox)の手順 1〜7（ブラウザでのログインに使う）、[HackGen Console NF](#hackgen-console-nf)の手順 1〜5（WezTerm とデスクトップの等幅のフォントに使う）、[WezTerm](#wezterm)の手順 1〜5、[再起動と確認](#再起動と確認)の手順 1 は飛ばさない）
  - 更新: OS は[OS とファームウェアの更新](#os-とファームウェアの更新)の手順 1・4・5、ファームウェアは同じ項の手順 2・3
  - PC 全体: sudo は[ログインと sudo](#ログインと-sudo)の手順 3。ほかは[システムの設定](#システムの設定)の手順で、PC の名前は 2、SSH は 3・4、journal は 5、kdump は 6・7、コマンドが無いときのパッケージの案内は 8
  - 導入元: EPEL は[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 1、RPM Fusion は同じ項の手順 2〜5、Flathub は[Flatpak と Flathub](#flatpak-と-flathub)の手順 1〜3（確認用の Flatseal は同じ項の手順 4・5）
  - 日本語入力: [日本語入力](#日本語入力)の手順 1・2（入力ソースは、[Neovim](#neovim)の手順 3 で「英語 (US) + Anthy」に変わる）。確かめるのは[再起動と確認](#再起動と確認)の手順 6
  - 表示: [GNOME の表示と入力](#gnome-の表示と入力)の手順で、フォルダーの名前は 1、ダークモードは 2、ウィンドウのボタンは 4、時計と電池は 5、Files は 6、ホットコーナーは 8、拡大率は 9 と[再起動と確認](#再起動と確認)の手順 4、トレイアイコンは 10・11、Dash のお気に入りは 13。確かめるのは[再起動と確認](#再起動と確認)の手順 2・7
  - 入力: [GNOME の表示と入力](#gnome-の表示と入力)の手順で、Caps Lock を Ctrl には 3、Alt+Tab は 7、Ctrl+Alt+T は 12（WezTerm にするのは[WezTerm と HackGen Console NF をデスクトップで使う](#wezterm-と-hackgen-console-nf-をデスクトップで使う)の手順 2）。確かめるのは[再起動と確認](#再起動と確認)の手順 5
  - シェル: 共通の bash 設定は[共通の bash 設定](#共通の-bash-設定)の手順 1・2、bash の補完とキー操作は同じ項の手順 3・4 と[シェルのツール](#シェルのツール)の手順 3・[キー操作を試す](#キー操作を試す)の手順 1、Homebrew は[Homebrew](#homebrew)の手順 1〜3、starship・zoxide・fzf・eza・bat・tmux は[シェルのツール](#シェルのツール)の手順 1・4〜10・[キー操作を試す](#キー操作を試す)の手順 2〜5・[tmux を試す](#tmux-を試す)の手順 1〜3
  - Git: `~/.gitconfig` の基本の設定は[Git](#git)の手順 1〜10、差分の表示（delta）は[git-delta](#git-delta)の手順 1〜4、lazygit は[lazygit](#lazygit)の手順 1〜4（自分用の設定は同じ項の手順 2）、GitHub CLI は[GitHub CLI](#github-cli)の手順 1〜5
  - ブラウザ: Firefox は[Firefox](#firefox)の手順 1〜7、AAC・H.264（RPM Fusion の FFmpeg）は同じ項の手順 8〜11
  - 端末: HackGen Console NF は[HackGen Console NF](#hackgen-console-nf)の手順 1〜5、WezTerm は[WezTerm](#wezterm)の手順 1〜4（自分用の設定は同じ項の手順 5）、等幅のフォントと Ctrl+Alt+T・Dash の端末は[WezTerm と HackGen Console NF をデスクトップで使う](#wezterm-と-hackgen-console-nf-をデスクトップで使う)の手順 1〜3
  - エディタとファイル: Neovim は[Neovim](#neovim)の手順 1・2・4、その自分用の設定（LazyVimStarter）は同じ項の手順 3 と[再起動と確認](#再起動と確認)の手順 8、yazi は[yazi](#yazi)の手順 1・2・4・5（自分用の設定は同じ項の手順 3）
  - AI エージェント: Claude Code は[Claude Code](#claude-code)の手順 1〜5、Codex CLI は[Codex CLI](#codex-cli)の手順 1〜8、Grok Build は[Grok Build](#grok-build)の手順 1〜7、Claude Code に入れる Codex・Grok のプラグインは[Codex・Grok のプラグイン](#codexgrok-のプラグイン)の手順 1・2（3 つを入れた後）
- Windows 11 の Git Bash の starship・zoxide・fzf・eza・bat は、[Windows 11 の初期設定の「シェルのツールを入れる」](windows-setup.md#シェルのツールを入れる)で scoop から入れる。確かめるのは、Git Bash で、この文書の[シェルのツール](#シェルのツール)の手順 4〜7・9・10 と[キー操作を試す](#キー操作を試す)の手順 2〜5
  - Windows 11 の Git Bash には、この文書の[Git](#git)の手順 1〜10 と[git-delta](#git-delta)の手順 1・3 も貼る（[Windows 11 の初期設定](windows-setup.md)から名指しする）
- 手順の後に、必要なら通す手順書: Homebrew のほかのツール（[gdu](gdu.md)・[ShellCheck / shfmt](shellcheck.md)）、[btop](btop.md)・[VS Code](vscode.md)・[Podman](podman.md)、3 つのコーディング用の CLI を 1 つのプロジェクトで使う[コーディングエージェントの共同作業](coding-agents.md)、役割ごとの手順書（[README の手順書とツール](../README.md#手順書とツール)）
- 手順の後: SSH を公開鍵だけにするなら[SSH を公開鍵だけにする（任意）](#ssh-を公開鍵だけにする任意)、OS を自動で更新するなら[dnf-automatic で自動で更新する（任意）](#dnf-automatic-で自動で更新する任意)、常時動かしておく PC は[画面オフ・画面ロック・自動サスペンドを止める（任意）](#画面オフ画面ロック自動サスペンドを止める任意)、[Wake on LAN を使う（任意）](#wake-on-lan-を使う任意)
  - Claude Code の不具合を避けるなら[Claude Code を stable チャンネルに切り替える（任意）](#claude-code-を-stable-チャンネルに切り替える任意)、SSH を切っても動かし続けるなら[Claude Code を tmux の中で動かす（任意）](#claude-code-を-tmux-の中で動かす任意)。改行を変換する設定（`core.autocrlf=true`）のときに clone したリポジトリがあれば[改行を変換して clone したリポジトリを直す](#改行を変換して-clone-したリポジトリを直す)
  - Homebrew・Flatpak・starship・fzf・eza・bat・tmux の使い方と設定、WezTerm・git-delta・Neovim・lazygit・yazi・Codex CLI・Grok Build の設定ファイル、Claude Code の使い方、ブラウザの無いホストでの Codex CLI と Grok Build のログインは、この文書の後ろの節。以後は[更新](#更新)・[ロールバック](extra/almalinux-setup.md#ロールバック)

> [!WARNING]
> - [ログインと sudo](#ログインと-sudo)の手順 3 の後は、**このユーザーで動くプログラム（ブラウザの拡張、AI のエージェント、`curl … | bash` のインストーラなど）が、パスワード無しで root の権限を使える**。人が触れる場所にある PC や、信用できないプログラムを動かすユーザーでは行わない。外すのは[ロールバック](extra/almalinux-setup.md#ロールバック)の最後の手順

### ログインと sudo

1. インストールのときに作ったユーザーで GNOME にログインし、「ようこそ」の窓を閉じる。

   - インストールの後の最初の起動で、ログイン画面でユーザーを選び、パスワードを入れる
   - 初めてのログインでは、アクティビティの画面に「AlmaLinux 10.2 (Lavender Lion) へようこそ」の窓が出る。「スキップ」を押す（ツアーを見るなら「“ツアー”を始める」）

1. 端末を開く。

   - Super キー（Windows キー）でアクティビティの画面を開き、「端末」と打って Enter。左の Dash の端末のアイコンでもよい
   - 端末のアプリは Ptyxis（「端末」）。この項の手順 3 から、この端末に貼る

1. sudo をパスワード無しで使えるようにする（パスワードを 1 回聞かれる）。

   ```bash
   {
     if ! id -nG | grep -qw wheel; then
       echo '中断: このユーザーは wheel の一員ではない（インストールのときに管理者にしたユーザーで貼る）' >&2
     else
       printf '\n\033[7m 確認 \033[0m\n'
       printf 'Defaults:%s verifypw=any\n%s ALL=(ALL) NOPASSWD: ALL\n' "${USER}" "${USER}" | sudo visudo -cf - &&
         printf 'Defaults:%s verifypw=any\n%s ALL=(ALL) NOPASSWD: ALL\n' "${USER}" "${USER}" | sudo install -m 0440 /dev/stdin /etc/sudoers.d/nopasswd
       sudo visudo -c
     fi
     sudo -k
     sudo -n -v && sudo -n true && echo 'sudo はパスワードを聞かない'
   }
   ```

   - 最初の `sudo` で `[sudo] <USER> のパスワード:` と聞かれる。ログインのパスワードを入れる（このユーザーで初めての `sudo` なら、その前に「あなたはシステム管理者から通常の講習を受けたはずです。」の注意が出る）
   - `stdin: 正しく構文解析されました` と、`/etc/sudoers` と `/etc/sudoers.d/nopasswd` の行（英語の環境では `parsed OK`）、最後に `sudo はパスワードを聞かない` が出ればよい
   - `中断:` が出たら、何も書いていない。インストールのときに管理者にしたユーザーでログインし直して、この項の手順 2 から
   - **次の手順は、パスワードを入れて、プロンプトに戻ってから貼る**（続けて貼ると、パスワードとして食われる）

### OS とファームウェアの更新

1. OS を最新にする。

   ```bash
   sudo dnf upgrade --refresh
   ```

   - 更新するものの一覧（トランザクション表）の後に `これでよろしいですか? [y/N]:` と聞かれる。`y`
   - インストールの後の最初の更新では、続けて AlmaLinux の署名鍵の取り込みを聞かれる（`GPG 鍵 0xC2A1E572 をインポート中:`）
     - `Userid : "AlmaLinux OS 10 <packager@almalinux.org>"` と `Fingerprint: EE6D B7B9 8F5B F5ED D9DA 0DE5 DEE5 C11C C2A1 E572` を確かめてから `y`（[AlmaLinux の Security のページ](https://almalinux.org/security/)の値と同じ）。違っていれば `N` で中断する
   - `何もしません。` と出たら、更新は無い
   - **次の手順は、`完了しました!` が出てプロンプトに戻ってから貼る**（続けて貼ると、`[y/N]` の答えとして食われる）

1. ファームウェアの情報（LVFS のメタデータ）を取り直す。

   ```bash
   sudo fwupdmgr refresh --force
   ```

   - 初めてのときは `現在リモートが有効になっていないため、メタデータが利用できません。` に続けて `このリモートを有効にしますか? [Y|n]:` と聞かれる。`Y`
   - `新しいメタデータのダウンロードに成功しました:` と、更新できる機器の数が出る（仮想マシンでは `更新可能なデバイスはありません`）
   - `デーモンへの接続に失敗しました: … タイムアウトしました` と出たら、少し待ってから貼り直す
   - **次の手順は、問いに答えてプロンプトに戻ってから貼る**（続けて貼ると、答えとして食われる）

1. ファームウェアの更新があれば、更新する。

   ```bash
   sudo fwupdmgr update
   ```

   - 更新が無ければ `No updatable devices` と出て終わる
   - 更新があれば、機器ごとに確認を聞かれる。`y`。再起動するかを聞かれたら `n`（この項の手順 5 で再起動する）
   - **注意**: 更新の途中で電源を切らない。ノート PC は電源につないでおく
   - **次の手順は、問いに答え終わってプロンプトに戻ってから貼る**（続けて貼ると、答えとして食われる）

1. OS の再起動が要るかを確かめる。

   ```bash
   dnf needs-restarting -r
   ```

   - `再起動な必要ありません。`（表示のとおり）と出て、この項の手順 3 でファームウェアを更新していなければ、この項の手順 5 は飛ばす
   - `再起動が必要です` の形の行（カーネルや systemd などを更新したとき）が出たか、この項の手順 3 でファームウェアを更新したなら、この項の手順 5 で再起動する

1. 再起動が要るときだけ、再起動する。

   ```bash
   sudo systemctl reboot
   ```

   - 保存していない文書のあるアプリが開いていると、`Operation inhibited by …` で断られることがある。そのアプリを閉じてから貼り直す
   - **次の手順は、起動してログインし、端末を開いてから貼る**（端末の開き方は[ログインと sudo](#ログインと-sudo)の手順 2）

### システムの設定

1. 変数を設定する（PC の名前を変えるなら、`HOST_NAME` に値を入れる）。

   ```bash
   HOST_NAME=''   # この PC の新しい名前（英小文字・数字・ハイフン。例: alma-pc）。変えないなら空のまま。<HOSTNAME>
   ```

   ```bash
   XKB_LAYOUT=$(localectl status 2>/dev/null | sed -n 's/^ *X11 Layout: \([a-z][a-z0-9_]*\).*/\1/p')   # キーボードの配列（自動）。JIS は jp、US は us。<XKB_LAYOUT>
   DASH_FAVORITES="['firefox.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Ptyxis.desktop', 'org.gnome.TextEditor.desktop']"   # Dash に並べるアプリ（左から）
   printf '\n\033[7m 確認 \033[0m\n'
   for v in USER HOST_NAME XKB_LAYOUT DASH_FAVORITES; do
     printf '%-14s = %s\n' "$v" "${!v}"
   done
   ```

   - 最後に値を読み戻して確かめる
   - `HOST_NAME` を変えないなら空のままにして、この項の手順 2 を飛ばす
   - `XKB_LAYOUT` が空か、手元のキーボードと違うなら、`XKB_LAYOUT=jp`（JIS 配列）か `XKB_LAYOUT=us`（US 配列）を貼ってから先へ進む
   - `USER` が `root` になっているなら、ここで止めて、自分のユーザーの端末で貼り直す
   - **新しい端末を開いたら**、この項の手順 1 を貼り直してから先へ進む

1. PC の名前を変えるときだけ、名前を変える。

   ```bash
   if [ -z "${HOST_NAME}" ]; then echo '中断: この項の手順 1 の HOST_NAME が空のまま。名前を変えないなら、この手順は飛ばす' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     echo "変える前: $(hostnamectl --static)"
     sudo hostnamectl hostname "${HOST_NAME}"
     echo "変えた後: $(hostnamectl --static)"
   fi
   ```

   - `変える前:` の名前を控える（[ロールバックの「システムの設定を戻す」](extra/almalinux-setup.md#システムの設定を戻す)の手順 4 で使う）
   - `変えた後:` に、この項の手順 1 の名前が出ればよい
   - 開いている端末のプロンプトは、開き直すまで前の名前のまま

1. SSH の待ち受けとファイアウォールを確かめ、この PC の IP アドレスを見る。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     systemctl is-enabled sshd
     systemctl is-active sshd
     sudo firewall-cmd --query-service=ssh
     sudo firewall-cmd --permanent --query-service=ssh
     ip -4 -brief address show scope global
   }
   ```

   - `enabled`・`active`・`yes`・`yes` と、この PC の IP アドレスが出ればよい（この項の手順 4 は飛ばす）
   - どれかが違えば、この項の手順 4 で直す

1. SSH の待ち受けか、ファイアウォールの ssh が違うときだけ、直す。

   ```bash
   {
     if ! rpm -q openssh-server; then sudo dnf install -y openssh-server; fi
     sudo systemctl enable --now sshd
     sudo firewall-cmd --permanent --add-service=ssh
     sudo firewall-cmd --reload
     printf '\n\033[7m 確認 \033[0m\n'
     systemctl is-active sshd
     sudo firewall-cmd --query-service=ssh
   }
   ```

   - `active` と `yes` が出ればよい

1. ログ（journal）を、再起動の後も残るようにディスクに書く。

   ```bash
   {
     sudo mkdir -p /etc/systemd/journald.conf.d
     printf '[Journal]\nStorage=persistent\n' | sudo tee /etc/systemd/journald.conf.d/50-persistent.conf >/dev/null
     sudo systemctl restart systemd-journald
     sudo journalctl --flush
     sudo systemd-tmpfiles --create --prefix /var/log/journal
     printf '\n\033[7m 確認 \033[0m\n'
     ls -ld /var/log/journal
     journalctl --disk-usage
   }
   ```

   - `drwxr-sr-x+ … root systemd-journal … /var/log/journal` の行と、journal の大きさが出ればよい

1. kdump が有効になっているか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl is-enabled kdump
   cat /sys/kernel/kexec_crash_size
   grep -o 'crashkernel=[^ ]*' /proc/cmdline
   ```

   - `enabled` と、0 でない数と、`crashkernel=…` が出たら、この項の手順 7 で止める
   - `disabled` と `0` が出て、`crashkernel=` が無ければ、この項の手順 7 は飛ばす

1. kdump が有効なときだけ、止めて、カーネルが落ちたときのために予約しているメモリーを外す（効くのは再起動の後）。

   ```bash
   {
     sudo systemctl disable --now kdump
     sudo sed -i 's/^auto_reset_crashkernel yes$/auto_reset_crashkernel no/' /etc/kdump.conf
     sudo grubby --update-kernel=ALL --remove-args=crashkernel
     printf '\n\033[7m 確認 \033[0m\n'
     grep -n '^auto_reset_crashkernel' /etc/kdump.conf
     sudo grubby --info=ALL | grep -E '^args='
   }
   ```

   - `auto_reset_crashkernel no` と、`crashkernel=` を含まない `args=` の行が出ればよい
   - **注意**: カーネルが落ちたときの記録（vmcore）は残らなくなる

1. コマンドが無いときにパッケージを探して案内する機能（PackageKit-command-not-found）を外す。

   ```bash
   sudo dnf remove PackageKit-command-not-found
   ```

   - `削除中:` が `PackageKit-command-not-found` の 1 つだけになる。`これでよろしいですか? [y/N]:` に `y`
   - **次の手順は、`完了しました!` が出てプロンプトに戻ってから貼る**（続けて貼ると、`[y/N]` の答えとして食われる）

### EPEL と RPM Fusion

1. EPEL が無ければ入れ、有効になったか確かめる。

   ```bash
   {
     if ! dnf repolist enabled | grep -qE '^epel'; then sudo dnf install -y epel-release; fi
     printf '\n\033[7m 確認 \033[0m\n'
     rpm -q epel-release
     dnf repolist enabled | grep -E '^epel'
   }
   ```

   - `epel-release` の版と、`epel` の行が出れば有効になっている
   - 最後に出る「CRB を有効にすることを推奨」は、気にしなくてよい
   - EPEL の署名鍵は、EPEL からパッケージを初めて入れるとき（この文書では[GNOME の表示と入力](#gnome-の表示と入力)の手順 10）に、dnf が 1 回だけ確認を求める
     - fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）であることを確かめてから `y`。違っていれば `N` で中断する

1. RPM Fusion（free）の署名鍵を落として、取り込む前に fingerprint と uid を確かめる。

   ```bash
   curl -fsSL 'https://rpmfusion.org/keys?action=AttachFile&do=get&target=RPM-GPG-KEY-rpmfusion-free-el-10' | gpg --show-keys
   ```

   - `gpg` が無ければ、`sudo dnf install -y gnupg2` で入れてから貼り直す
   - `pub` 行の fingerprint が `5FC4AE73FC2B08B9DFE7EB990C8489D8DB85DDD7`
   - uid が `RPM Fusion free repository for EL (10) <rpmfusion-gpg-key-el10-free@rpmfusion.org>`
   - 違っていればここで止める
   - **次の手順は、この 2 つを目で確かめてから貼る**

1. 一致したら、鍵を rpm に取り込み、入ったか確かめる。

   ```bash
   {
     sudo rpm --import 'https://rpmfusion.org/keys?action=AttachFile&do=get&target=RPM-GPG-KEY-rpmfusion-free-el-10'
     printf '\n\033[7m 確認 \033[0m\n'
     rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i fusion
   }
   ```

   - `rpm --import` は何も表示しない
   - `gpg-pubkey-db85ddd7-67a63d8b RPM Fusion free repository for EL (10) ...` の 1 行が出れば、取り込めている

1. RPM Fusion（free）のリポジトリを入れる。

   ```bash
   sudo dnf --setopt=localpkg_gpgcheck=1 install https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-10.noarch.rpm
   ```

   - `--setopt=localpkg_gpgcheck=1` を外さない（外すと、この項の手順 3 の鍵で署名を確かめずに入る）
   - EPEL が有効なホストでは、`インストール:` が `rpmfusion-free-release` の 1 つだけになる
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. RPM Fusion（free）が有効になったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   rpm -q rpmfusion-free-release
   dnf repolist enabled | grep -E '^rpmfusion'
   ```

   - `rpmfusion-free-release` の版と、`rpmfusion-free-updates` の行が出れば有効になっている

### Flatpak と Flathub

1. flatpak を確かめ（無ければ入れ）、登録されているリモートを見る。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     if ! rpm -q flatpak; then sudo dnf install -y flatpak; fi
     flatpak --version
     flatpak remotes --show-details
   }
   ```

   - `flatpak-1.16.0-…` と `Flatpak 1.16.0` が出る
   - **入れた直後は `flatpak remotes` が `error: While opening repository /var/lib/flatpak/repo: ...` を出すが、壊れているわけではない**。リモートがまだ無いだけ

1. Flathub の登録ファイルに埋め込まれた公開鍵の fingerprint を確かめる。

   ```bash
   curl -fsSL https://dl.flathub.org/repo/flathub.flatpakrepo | sed -n 's/^GPGKey=//p' | base64 -d | gpg --show-keys --with-fingerprint
   ```

   - 次の値と一致することを目で確かめる
     - `6E5C 05D9 79C7 6DAF 93C0 8135 4184 DD4D 907A 7CAE`（Flathub Repo Signing Key &lt;flathub@flathub.org&gt;、有効期限 2027-06-14）
   - **次の手順は、一致するのを確かめてから貼る**（違っていれば先へ進まない）

1. Flathub を system に登録して、登録されたか確かめる。

   ```bash
   {
     sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
     printf '\n\033[7m 確認 \033[0m\n'
     flatpak remotes --show-details
   }
   ```

   - `flathub` の行が出て、`Options` の列が `system` になっていればよい

1. 確認用のアプリ（Flatseal）を入れる。

   ```bash
   sudo flatpak install flathub com.github.tchx84.Flatseal
   ```

   - **確認を 2 回聞かれる**。どちらも `y` で進める
     - 1 回目: runtime を入れるか（`Do you want to install it? [Y/n]`）
     - 2 回目: アプリの権限と入れるものの一覧を見せたうえでの最終確認（`Proceed with these changes to the system installation? [Y/n]`）
   - 最初の 1 本は runtime ごと落とすので、`/var/lib/flatpak` が 2.5 GB ほどになる。要らなければ、この手順とこの項の手順 5 は飛ばしてよい
   - **次の手順は、2 回の確認に答え、完了してから貼る**（続けて貼ると答えとして食われる）

1. 確認用のアプリが入り、サンドボックスが起動できるか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   flatpak list --app --columns=application,version,branch,installation
   flatpak info com.github.tchx84.Flatseal
   flatpak run --command=true com.github.tchx84.Flatseal && echo 'sandbox OK'
   ls /var/lib/flatpak/exports/share/applications/
   ```

   - `flatpak list` に `com.github.tchx84.Flatseal  2.4.1  stable  system` のように出る
   - `sandbox OK` が出れば、アプリのサンドボックスが起動できている
   - 最後の行に `com.github.tchx84.Flatseal.desktop` が出れば、デスクトップのメニューに載せるためのファイルができている
   - メニューに載るのは、[再起動と確認](#再起動と確認)の手順 1 の再起動の後

### 日本語入力

1. ibus-anthy と日本語のフォントが無ければ入れる。

   ```bash
   if ! rpm -q ibus ibus-anthy default-fonts-cjk-sans; then sudo dnf install -y ibus-anthy default-fonts-cjk-sans; fi
   ```

   - 3 つとも版が出れば、入っている
   - `package … is not installed` が出たときは、続けて AppStream から入る。入れたときは、[再起動と確認](#再起動と確認)の手順 1 の再起動の後に使えるようになる

1. 入力ソースを「キーボードの配列 + Anthy」にする。

   ```bash
   if [ -z "${XKB_LAYOUT}" ]; then echo '中断: 「システムの設定」の手順 1 の XKB_LAYOUT が空のまま。値を入れて貼り直す' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     /usr/bin/gsettings get org.gnome.desktop.input-sources sources
     /usr/bin/gsettings set org.gnome.desktop.input-sources sources "[('xkb', '${XKB_LAYOUT}'), ('ibus', 'anthy')]"
     /usr/bin/gsettings get org.gnome.desktop.input-sources sources
     /usr/bin/gsettings get org.gnome.desktop.wm.keybindings switch-input-source
   fi
   ```

   - 最初の `get` は変える前の値（最初のログインの後は、今の配列だけの `[('xkb', 'us')]` など）。戻すときのために控えておく
   - 2 つ目の `get` が `[('xkb', 'jp'), ('ibus', 'anthy')]`（US 配列なら `'us'`）になればよい
   - **ほかの入力ソースは消える**（[Neovim](#neovim)の手順 3 でも、「英語 (US)」と Anthy の 2 つに置き換わる）。残したいものは、その後に `set` の値に並べて足す
   - **注意**: `/usr/bin/` を外さない（[GNOME の表示と入力](#gnome-の表示と入力)の手順 1〜13 も同じ）
   - **入力ソースは、[Neovim](#neovim)の手順 3 で「英語 (US)」と Anthy に変わる**（JIS 配列のキーボードでも US。Neovim の IME 連携のため）

### GNOME の表示と入力

1. ホームのフォルダーの名前を、日本語から英語にする（中身ごと移す）。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/python3 - <<'EOF'
   import pathlib, subprocess, urllib.parse
   home = pathlib.Path.home()
   names = {'DESKTOP': 'Desktop', 'DOWNLOAD': 'Downloads', 'TEMPLATES': 'Templates', 'PUBLICSHARE': 'Public',
            'DOCUMENTS': 'Documents', 'MUSIC': 'Music', 'PICTURES': 'Pictures', 'VIDEOS': 'Videos'}
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
   cat ~/.config/gtk-3.0/bookmarks
   ```

   - `/home/<USER>/ダウンロード → /home/<USER>/Downloads` のような行が 8 つ出る
   - `user-dirs.dirs` の 8 行が `$HOME/Desktop`・`$HOME/Downloads`・`$HOME/Templates`・`$HOME/Public`・`$HOME/Documents`・`$HOME/Music`・`$HOME/Pictures`・`$HOME/Videos` になり、Files のサイドバーのブックマーク（最後の行）も英語の名前を指せばよい
   - 英語の名前のフォルダーがもうあると、そのフォルダーは `飛ばした:` で変えない

1. ダークモードにする。

   ```bash
   /usr/bin/gsettings set org.gnome.desktop.interface color-scheme prefer-dark
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.desktop.interface color-scheme
   ```

   - `'prefer-dark'` が出ればよい

1. Caps Lock を Ctrl にする（今の配列の設定に足す）。

   ```bash
   xkb=$(/usr/bin/gsettings get org.gnome.desktop.input-sources xkb-options)
   echo "変える前: ${xkb}"
   case "${xkb}" in
     *"'ctrl:nocaps'"*) ;;
     '@as []') /usr/bin/gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']" ;;
     *) /usr/bin/gsettings set org.gnome.desktop.input-sources xkb-options "${xkb%]}, 'ctrl:nocaps']" ;;
   esac
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.desktop.input-sources xkb-options
   ```

   - 最後に `['ctrl:nocaps']`（ほかの設定があれば、その後ろに `'ctrl:nocaps'`）が出ればよい。すぐに効く

1. ウィンドウのタイトルバーに、最小化と最大化のボタンを出す。

   ```bash
   /usr/bin/gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.desktop.wm.preferences button-layout
   ```

   - `'appmenu:minimize,maximize,close'` が出ればよい

1. 上部バーの時計に曜日と秒を出し、電池の残りを % で出す。

   ```bash
   /usr/bin/gsettings set org.gnome.desktop.interface clock-show-weekday true
   /usr/bin/gsettings set org.gnome.desktop.interface clock-show-seconds true
   /usr/bin/gsettings set org.gnome.desktop.interface show-battery-percentage true
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings list-recursively org.gnome.desktop.interface | grep -E 'clock-show-(weekday|seconds)|show-battery-percentage'
   ```

   - 3 行とも `true` が出ればよい
   - 電池の % は、電池のある PC だけに出る

1. Files とファイルを選ぶ窓で、隠しファイルを出し、フォルダーを先に並べる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   for s in org.gtk.Settings.FileChooser org.gtk.gtk4.Settings.FileChooser; do
     /usr/bin/gsettings set "${s}" show-hidden true
     /usr/bin/gsettings set "${s}" sort-directories-first true
     /usr/bin/gsettings list-recursively "${s}" | grep -E 'show-hidden|sort-directories-first'
   done
   ```

   - 2 つのスキーマで、`show-hidden true` と `sort-directories-first true` が 2 行ずつ出ればよい

1. Alt+Tab を、アプリごとではなくウィンドウごとの切り替えにする。

   ```bash
   /usr/bin/gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab']"
   /usr/bin/gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Super>Tab']"
   /usr/bin/gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
   /usr/bin/gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab']"
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings list-recursively org.gnome.desktop.wm.keybindings | grep -E 'switch-(applications|windows)'
   ```

   - `switch-windows ['<Alt>Tab']` と `switch-applications ['<Super>Tab']` などの 4 行が出ればよい

1. 画面の左上の角（ホットコーナー）にマウスを当てても、アクティビティの画面を開かないようにする。

   ```bash
   /usr/bin/gsettings set org.gnome.desktop.interface enable-hot-corners false
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.desktop.interface enable-hot-corners
   ```

   - `false` が出ればよい

1. 設定の「ディスプレイ」で、拡大率に 125%・150% などを選べるようにする（効くのは再起動の後）。

   ```bash
   f=$(/usr/bin/gsettings get org.gnome.mutter experimental-features)
   echo "変える前: ${f}"
   for x in scale-monitor-framebuffer xwayland-native-scaling; do
     case "${f}" in
       *"'${x}'"*) ;;
       '@as []') f="['${x}']" ;;
       *) f="${f%]}, '${x}']" ;;
     esac
   done
   /usr/bin/gsettings set org.gnome.mutter experimental-features "${f}"
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.mutter experimental-features
   ```

   - `['scale-monitor-framebuffer', 'xwayland-native-scaling']` が出ればよい

1. EPEL から、トレイアイコンを出す GNOME の拡張（AppIndicator）を入れる。

   ```bash
   sudo dnf install gnome-shell-extension-appindicator
   ```

   - `これでよろしいですか? [y/N]:` に `y`
   - EPEL からパッケージを入れるのが初めてなら、続けて EPEL の鍵の取り込みを聞かれる。fingerprint が[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 1 の値なら `y`、違っていれば `N`
   - 入るのは `gnome-shell-extension-appindicator`
   - **次の手順は、`完了しました!` が出てプロンプトに戻ってから貼る**（続けて貼ると、`[y/N]` の答えとして食われる）

1. 入れた拡張を有効にする（効くのは再起動の後）。

   ```bash
   e=$(/usr/bin/gsettings get org.gnome.shell enabled-extensions)
   echo "変える前: ${e}"
   case "${e}" in
     *"'appindicatorsupport@rgcjonas.gmail.com'"*) ;;
     '@as []') /usr/bin/gsettings set org.gnome.shell enabled-extensions "['appindicatorsupport@rgcjonas.gmail.com']" ;;
     *) /usr/bin/gsettings set org.gnome.shell enabled-extensions "${e%]}, 'appindicatorsupport@rgcjonas.gmail.com']" ;;
   esac
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.shell enabled-extensions
   ```

   - 最後に、もとの拡張（`'background-logo@fedorahosted.org'`）と `'appindicatorsupport@rgcjonas.gmail.com'` が出ればよい

1. Ctrl+Alt+T で端末を開くようにする（ショートカットを足す）。

   ```bash
   kb=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal/
   list=$(/usr/bin/gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
   case "${list}" in
     *"'${kb}'"*) ;;
     '@as []') /usr/bin/gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['${kb}']" ;;
     *) /usr/bin/gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "${list%]}, '${kb}']" ;;
   esac
   /usr/bin/gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}" name '端末'
   /usr/bin/gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}" command 'ptyxis --new-window'
   /usr/bin/gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}" binding '<Control><Alt>t'
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings
   /usr/bin/gsettings list-recursively "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}"
   ```

   - 一覧に `'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal/'` があり、`binding '<Control><Alt>t'`・`command 'ptyxis --new-window'`・`name '端末'` が出ればよい。すぐに効く

1. Dash のお気に入り（左の並び）を、[システムの設定](#システムの設定)の手順 1 のアプリにする。

   ```bash
   if [ -z "${DASH_FAVORITES}" ]; then echo '中断: 「システムの設定」の手順 1 の DASH_FAVORITES が空のまま。値を入れて貼り直す' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     /usr/bin/gsettings get org.gnome.shell favorite-apps
     /usr/bin/gsettings set org.gnome.shell favorite-apps "${DASH_FAVORITES}"
     /usr/bin/gsettings get org.gnome.shell favorite-apps
   fi
   ```

   - 最初の `get` は変える前の並び（Workstation では Firefox・カレンダー・Files・ソフトウェア・端末・テキストエディター・電卓）。戻すときのために控えておく
   - 2 つ目の `get` が[システムの設定](#システムの設定)の手順 1 の値になればよい。すぐに効く

### 共通の bash 設定

1. 共通の bash 設定を入れる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   git clone https://github.com/ryo-aoki-pc/bash.git ~/.config/bash &&
     bash ~/.config/bash/install.sh
   ```

   - `~/.bashrc: 設定済み（元の内容: ~/.bashrc.before-bash）` と `完了: 端末を開き直す。…` が出ればよい
   - すでに clone してあるなら `fatal: destination path … already exists` で止まる。そのときは `git -C ~/.config/bash pull --ff-only` で更新し、`bash ~/.config/bash/install.sh` を貼る

1. 共通の bash 設定を今の端末に読み込み、履歴と shopt の値を確かめる。

   ```bash
   . ~/.bashrc
   printf '\n\033[7m 確認 \033[0m\n'
   echo "${__bash_config_loaded-読まれていない}"
   printf '%s\n' "$HISTSIZE" "$HISTFILESIZE" "$HISTCONTROL"
   shopt histappend autocd cdspell dirspell globstar
   ```

   - `1`、`100000`・`100000`・`ignoreboth`、5 つの `on` が出ればよい

1. bash-completion が入っているか確かめ、無ければ入れる。

   ```bash
   if ! rpm -q bash-completion; then sudo dnf install -y bash-completion; fi
   ```

   - `bash-completion-2.11-…` と出れば入っている
   - `package bash-completion is not installed` のときは、続けて BaseOS から入る

1. `~/.inputrc` を書き、今のシェルにも読ませる。

   ```bash
   if [ -e ~/.inputrc ]; then
     echo '中断: ~/.inputrc がすでにある。中身を見て、この手順の set と矢印の行を手で足す' >&2
   else
     cat > ~/.inputrc <<'EOF'
   # OS の設定（Home / End / Delete、Ctrl+矢印の単語の移動など）を先に読む。この行が無いと読まれなくなる
   $include /etc/inputrc
   # 補完: 大文字小文字を区別しない、候補が複数なら 1 回の Tab で一覧を出す、種類と打った部分を色で示す
   set completion-ignore-case on
   set show-all-if-ambiguous on
   set colored-stats on
   set colored-completion-prefix on
   # ↑/↓: 打った文字で始まる履歴だけをさかのぼる（何も打っていなければ 1 つずつ）
   "\e[A": history-search-backward
   "\e[B": history-search-forward
   "\eOA": history-search-backward
   "\eOB": history-search-forward
   EOF
     bind -f ~/.inputrc
     printf '\n\033[7m 確認 \033[0m\n'
     bind -v | grep -E 'completion-ignore-case|show-all-if-ambiguous|colored-stats|colored-completion-prefix'
     bind -q history-search-backward
     bind -q beginning-of-line
   fi
   ```

   - `set … on` が 4 行、`history-search-backward は次を通して起動します "\eOA", "\e[5~", "\e[A".`、`beginning-of-line は次を通して起動します "\C-a", "\eOH", "\e[1~", "\e[H".` が出る（英語の環境では `… can be invoked via …`）
   - `beginning-of-line` に `"\e[1~"` が無ければ、`$include /etc/inputrc` の行が読まれていない
   - `中断:` が出たら、すでにある `~/.inputrc` に、`$include /etc/inputrc` が無ければ先頭に足し、`set` の 4 行と矢印の 4 行を手で足す。足したら `bind -f ~/.inputrc`

### Homebrew

1. Homebrew の依存パッケージを入れる。

   ```bash
   sudo dnf install -y procps-ng curl file git
   ```

   - Workstation では、どれも入っている（`すでにインストールされています` と出る）

1. Homebrew の公式のインストーラを実行する。

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

   - インストーラは続行の確認で `RETURN` を求める
   - 終わりに `==> Installation successful!` と、PATH の通し方を書いた `==> Next steps:` が出る。`Next steps` の `~/.bashrc` への追記は行わない
   - **次の手順は、インストーラが終わってから貼る**（続けて貼ると `RETURN` の確認として食われる）

1. 共通の bash 設定を読み直して Homebrew の PATH を有効にし、入ったか確かめる。

   ```bash
   . ~/.bashrc
   printf '\n\033[7m 確認 \033[0m\n'
   brew --version
   command -v brew
   brew config | head -12
   ```

   - `command -v brew` が `/home/linuxbrew/.linuxbrew/bin/brew` を返す
   - `brew config` の `HOMEBREW_PREFIX` が `/home/linuxbrew/.linuxbrew` ならよい

### シェルのツール

1. brew で starship・zoxide・fzf・eza・bat・tmux を入れる。

   ```bash
   brew install starship zoxide fzf eza bat tmux
   ```

   - 入れるものの一覧の後に `Do you want to proceed with the installation? [y/n]` と聞かれる。`y`（Enter は要らない）
   - 要らないツールは、名前を外してから貼る
   - **次の手順は、`y` と答えて、プロンプトに戻ってから行う**（続けて貼ると、後ろの行の文字が答えとして読まれる）

1. 開いている端末を閉じて、開き直す。

   - Ctrl+Alt+T（[GNOME の表示と入力](#gnome-の表示と入力)の手順 12）でも開ける
   - 開き直した端末から、プロンプトが starship に変わり、zoxide・fzf・eza のエイリアス・bat の `MANPAGER` も効く
   - 今の端末で `. ~/.bashrc` を読み直さない（starship が、そのシェルで既に読んだ WezTerm のシェル統合より後ろで初期化され、WezTerm のフックが 2 回ずつ動く）
   - [システムの設定](#システムの設定)の手順 1 の変数は、この後は使わない
   - **次の手順は、開き直した端末で貼る**

1. bash の履歴・補完・キー操作の設定が効いていることを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   printf '%s\n' "${HISTSIZE}" "${HISTFILESIZE}" "${HISTCONTROL}"
   shopt histappend autocd cdspell dirspell globstar
   complete -p -D
   complete -p brew
   bind -v | grep -E 'completion-ignore-case|show-all-if-ambiguous|colored-stats|colored-completion-prefix'
   bind -q history-search-backward
   ```

   - `100000`・`100000`・`ignoreboth`、5 つの `on` が出る
   - `complete -F _completion_loader -D`（Workstation では `complete -F _python_argcomplete_global -D` のこともある）と、`-F _brew brew` を含む行が出る
   - `set … on` が 4 行と、`history-search-backward は次を通して起動します "\eOA", "\e[5~", "\e[A".` が出る（英語の環境では `… can be invoked via …`）

1. starship が入り、プロンプトの文字列が作られるか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   grep -n -e 'starship init' -e 'WEZTERM_SHELL_INTEGRATION' -e 'zoxide init' ~/.config/bash/bashrc
   starship --version
   command -v starship
   starship module directory
   starship explain
   ```

   - 最初の行で、starship → WezTerm → zoxide の順に出る
   - `starship 1.26.0` のような版と、`/home/linuxbrew/.linuxbrew/bin/starship` が出る

1. fzf が入り、キー操作と補完が組み込まれたか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   fzf --version
   command -v fzf
   bind -X
   bind -s | grep -F '"\ec"'
   complete -p cd vi ssh
   ```

   - `0.74.4 (Homebrew)` のような版と `/home/linuxbrew/.linuxbrew/bin/fzf` が出る
   - Ctrl+R・Ctrl+T の割り当て（`"\C-r": "__fzf_history__"`・`"\C-t": "fzf-file-widget"`）と、Alt+C のマクロ（`` "\ec": " \C-b\C-k \C-u`__fzf_cd__`… ``）が出る
   - `cd`・`vi`・`ssh` の補完の定義（`_fzf_dir_completion`・`_fzf_path_completion`・`_fzf_complete_ssh`）が出る

1. eza の版と Git の列、`ll`・`la`・`lt` を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   eza --version
   command -v eza
   eza -l --git --header ~/.config/bash
   alias ll la lt
   ```

   - `eza --version` は `v0.23.5 [+git]` のような行を含む
   - `Permissions Size User Date Modified Git Name` の見出しの一覧が出る
   - `ll` は `eza -l --git --group-directories-first`、`la` は `-la`、`lt` は `eza --tree --level=2`

1. bat の版と、色と行番号、man のページャを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   bat --version
   command -v bat
   bat --color=always --style=numbers /etc/os-release | head -5
   printf '%s\n' "$MANPAGER"
   ```

   - `bat 0.26.1` のような版と、`/home/linuxbrew/.linuxbrew/bin/bat` が出る
   - 行番号付きで `NAME="AlmaLinux"` から 5 行が色付きで出る
   - 最後に `bat -plman` が出ればよい

1. tmux が入ったことを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   tmux -V
   command -v tmux
   rpm -q tmux
   ```

   - `tmux 3.7c` のような版と `/home/linuxbrew/.linuxbrew/bin/tmux` が出る
   - 最後の行は `パッケージ tmux はインストールされていません`（英語の環境では `package tmux is not installed`）でよい
   - **BaseOS の tmux（`tmux-3.3a-…`）が出て、そちらで始めたセッションが動いているなら**、そのセッションには `/usr/bin/tmux attach` で入る

1. zoxide の `z` と `zi` を確かめ、記録を試すディレクトリへ移る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   type -t z zi
   zoxide --version
   command -v zoxide
   cd /usr/share
   ```

   - `function` が 2 行と、`zoxide 0.10.0` のような版、`/home/linuxbrew/.linuxbrew/bin/zoxide` が出る
   - **注意**: 対話のシェル（端末に貼る）で行う。スクリプトの中では記録されない
   - **次の手順は、プロンプトが戻ってから貼る**（zoxide はプロンプトを出すときに今のディレクトリを記録する。続けて貼ると、プロンプトが出る前にこの項の手順 10 が動き、`/usr/share` がまだ無い）

1. zoxide のデータベースに記録されたか確かめ、ホームに戻る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   zoxide query --list
   cd ~
   ```

   - `/usr/share` が出れば動いている

### キー操作を試す

1. キーを押して、補完と履歴の検索を確かめる。

   - `systemctl star` と打って Tab: `systemctl start ` になる（bash-completion）
   - `ls /usr/s` と打って Tab: 1 回で `sbin/ share/ src/` の一覧が色付きで出る（`show-all-if-ambiguous`・`colored-stats`）
   - `cd /usr/SH` と打って Tab: `cd /usr/share/` になる（`completion-ignore-case`）
   - `printf` と打って ↑: [シェルのツール](#シェルのツール)の手順 7 の `printf '%s\n' "$MANPAGER"` の行が出る（`history-search-backward`。カーソルは `printf` の後ろに残る）。Ctrl+C で捨てる
   - `/usr/share` と打って Enter: `cd -- /usr/share` と出て移る（`autocd`）。`cd /usr/shaer` と打って Enter: `/usr/share` と出て移る（`cdspell`）。`cd` で戻る
   - `ls /usr/share/doc/bash-completion/**/*.md` と打って Enter: サブディレクトリの `.md` も出る（`globstar`）
   - `eza --gi` と打って Tab: `--git  --git-ignore  --git-repos  --git-repos-no-status` の一覧が出て、`eza --git` まで入る（Homebrew のコマンドの補完）

1. Ctrl+R を押し、履歴から[シェルのツール](#シェルのツール)の手順 5 の `fzf --version` を選んで実行する。

   - 画面の下から fzf の一覧が開き、最下行の `>` の右に打った文字で絞り込める。`fzf --v` と打ち、上下キーで `fzf --version` の行を選ぶ
   - Enter でその行がプロンプトに入る（**実行はされない**）。もう一度 Enter で実行する
   - Esc か Ctrl+C で、何も選ばずに閉じる

1. `cat ` と打ってから Ctrl+T を押し、ファイルを選ぶ。

   - 今のディレクトリ（ホーム）の下のファイルの一覧が開く。`.bashrc` と打つと先頭が `.bashrc` になり、Enter でカーソルの位置に入る（`bashrc` だけでは、共通の bash 設定の `.config/bash/bashrc` が先頭に来る）
   - 右側に、選んでいるファイルの中身が bat の行番号と色付きで出る
   - そのまま Enter で `cat .bashrc` が動く

1. `ls /usr/share/**` と打って Tab を押し、候補から選ぶ。

   - `**` の後の Tab で、`/usr/share/` の下のパスの一覧が開く。`doc/bash` と打つと先頭が `/usr/share/doc/bash/` になり、Enter で `ls /usr/share/doc/bash/` が入る。もう一度 Enter で実行する

1. Alt+C を押してディレクトリを選んで移り、`cd -` で戻る。

   - 今のディレクトリの下のディレクトリの一覧が開く。選んで Enter で、`builtin cd -- <ディレクトリ>` と表示して移る
   - 端末が Alt を ESC の前置きとして送る設定のときに届く（届かなければ、`ESC` を押してから `c`）
   - `cd -` で元のディレクトリに戻る

### tmux を試す

1. tmux のセッションを作って入る。

   ```bash
   tmux new-session -s work
   ```

   - 画面の下に緑の帯（ステータス行）が出て、左端に `[work]` が出る
   - **`Ctrl+b` を押して離してから `d`** で抜ける（デタッチ）。シェルに戻って `[detached (from session work)]` と出る
   - **次の手順は、デタッチしてシェルに戻ってから貼る**（続けて貼ると、tmux の中のシェルへの入力になる）

1. セッションの一覧を見て、もう一度入る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   tmux ls
   tmux attach -t work
   ```

   - `tmux ls` の `work: 1 windows (created …)` は、tmux の画面を出た後のシェルに見える
   - `tmux attach -t work` で、この項の手順 1 の画面に戻る
   - 中で `exit` と打つと、シェルが終わってセッションも終わる。`[exited]` と出てシェルに戻る
   - **次の手順は、`exit` でシェルに戻ってから貼る**（続けて貼ると、tmux の中のシェルへの入力になる）

1. tmux のセッションが残っていないことを確かめる。

   ```bash
   tmux ls
   ```

   - `no server running on /tmp/tmux-<UID>/default` と出る

### Git

1. 変数を設定する（`GIT_USER_NAME` と `GIT_USER_EMAIL` は必ず値を入れる）。

   ```bash
   GIT_USER_NAME=''                     # ← コミットに載せる名前を引用符の中に書く（例: 'Taro Yamada'）。<GIT_USER_NAME>
   ```

   ```bash
   GIT_USER_EMAIL=''                    # ← コミットに載せるメールアドレスを引用符の中に書く。<GIT_USER_EMAIL>
   ```

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   for v in GIT_USER_NAME GIT_USER_EMAIL; do
     printf '%-14s = %s\n' "$v" "${!v}"
   done
   ```

   - 2 つとも `git log` に出る。push したリポジトリでは公開される
   - 最後に値を読み戻して確かめる。空のままなら、この項の手順 3 で中断する
   - **新しいシェルを開いたら**、この項の手順 1 の 3 つのブロックを貼り直してから先へ進む

1. git の版と、今の設定を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   git --version
   git config --list --show-scope --show-origin
   ```

   - AlmaLinux 10.2 では `git version 2.52.0` と出る（git は[Homebrew](#homebrew)の手順 1 で入っている）
   - 2 つ目は、設定を `<場所>	file:<ファイル>	<キー>=<値>` の形で 1 行ずつ出す。何も設定していなければ、何も出ない
   - **この項の手順 3〜5 のキー（`user.name`・`core.autocrlf` など）と `pull.ff` は、元の値・スコープ・ファイルを控える**。`global` に無いキーは「global は未設定」と控える（[ロールバックの「Git の道具を消す」](extra/almalinux-setup.md#git-の道具を消す)で戻す）
   - 実際に追加・変更したキーも控える。既存の値が同じなら「変更なし」、この項の手順 7 を飛ばしたら「`pull.ff` は変更なし」とする
   - Windows では、インストーラが書いた `system` の行（`core.autocrlf=true` など）も出る

1. 名前とメールアドレスを設定する。

   ```bash
   if [ -z "${GIT_USER_NAME}" ] || [ -z "${GIT_USER_EMAIL}" ]; then echo '中断: 「Git」の手順 1 の GIT_USER_NAME か GIT_USER_EMAIL が空のまま' >&2; else
     git config --global user.name "${GIT_USER_NAME}"
     git config --global user.email "${GIT_USER_EMAIL}"
     printf '\n\033[7m 確認 \033[0m\n'
     git config --global --get-regexp '^user\.'
   fi
   ```

   - `user.name <GIT_USER_NAME>` と `user.email <GIT_USER_EMAIL>` の 2 行が出る
   - `中断:` と出たら、この項の手順 1 で値を入れて貼り直す

1. pull を rebase にし、autostash を有効にし、改行を変換しないようにする。

   ```bash
   git config --global pull.rebase true
   git config --global rebase.autoStash true
   git config --global core.autocrlf false
   ```

   - 何も出ない。値はこの項の手順 6 でまとめて確かめる

1. 推奨の設定を入れる。

   ```bash
   git config --global init.defaultBranch main
   git config --global core.quotepath false
   git config --global fetch.prune true
   git config --global push.autoSetupRemote true
   git config --global rerere.enabled true
   git config --global merge.conflictStyle zdiff3
   git config --global diff.algorithm histogram
   git config --global branch.sort -committerdate
   git config --global tag.sort version:refname
   ```

   - 何も出ない。値はこの項の手順 6 でまとめて確かめる

1. 効いている値と、その値を書いた場所を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   cd ~
   for k in user.name user.email pull.rebase rebase.autoStash core.autocrlf \
            init.defaultBranch core.quotepath fetch.prune push.autoSetupRemote rerere.enabled \
            merge.conflictStyle diff.algorithm branch.sort tag.sort pull.ff; do
     printf '%-21s %s\n' "$k" "$(git config --show-scope --get "$k")"
   done
   ```

   - `pull.ff` を除く 14 行が、`global` とこの項の手順 3〜5 の値になる（`pull.rebase           global	true` など）
   - `pull.ff` 以外に `system` の行があれば、`global` に書けていない。この項の手順 3〜5 を貼り直す
   - 最後の `pull.ff` は、何も出ないのが普通
   - `pull.ff` が空か、`only` 以外なら、この項の手順 7 は飛ばす
   - `only` なら、その値とスコープをこの項の手順 2 の記録と照合してから手順 7 へ進む

1. この項の手順 6 で `pull.ff` が `only` だったときだけ、`true` で上書きする。

   ```bash
   git config --global pull.ff true
   printf '\n\033[7m 確認 \033[0m\n'
   git config --show-scope --get pull.ff
   ```

   - `global	true` と出る

   - `pull.ff` を今回変更したことを、この項の手順 2 の元値の記録に書き足す

1. 使い捨てのリポジトリで、改行・ブランチ名・日本語のファイル名・最初の push を確かめる。

   ```bash
   GIT_TEST_DIR=$(mktemp -d)
   cd "$GIT_TEST_DIR"
   git init -q --bare remote.git
   git init -q a
   cd a
   printf 'line 1\r\n' > crlf.txt
   printf '1\n' > a.txt
   touch 日本語.txt
   printf '\n\033[7m 確認 \033[0m\n'
   git status --short
   git add .
   git commit -q -m first
   git ls-files --eol crlf.txt
   git branch --show-current
   git remote add origin ../remote.git
   git push
   ```

   - `git status --short` に `?? 日本語.txt` がそのまま出る
   - `git ls-files --eol` は `i/crlf  w/crlf` で始まる
   - ブランチは `main`
   - `git push` の最後に `branch 'main' set up to track 'origin/main'.` と出る

1. この項の手順 8 と同じシェルで、別の clone から pull し、rebase と autostash を確かめる。

   ```bash
   cd "$GIT_TEST_DIR"
   git clone -q remote.git b
   cd a
   printf '2\n' >> a.txt
   git commit -q -a -m 'a: 2'
   git push -q
   cd ../b
   printf 'b\n' > b.txt
   git add b.txt
   git commit -q -m 'b: b.txt'
   printf 'line 2\r\n' >> crlf.txt
   printf '\n\033[7m 確認 \033[0m\n'
   git pull
   git log --oneline --graph
   git status --short
   ```

   - `git pull` が `Created autostash: …`・`Applied autostash.`・`Successfully rebased and updated refs/heads/main.` を出す
   - `git log` は枝分かれせず、`b: b.txt` → `a: 2` → `first` の 1 本になる
   - `git status --short` に `M crlf.txt` が残る

1. 使い捨てのリポジトリを消す。

   ```bash
   cd ~
   rm -rf "${GIT_TEST_DIR:?「Git」の手順 8 と同じシェルで貼る}"
   ```

   - 何も出ない

### Firefox

1. 変数を設定する。

   ```bash
   FF_PKG=firefox                  # 本書は最新版（Rapid Release）の firefox だけを扱う。変更しない。<FF_PKG>
   FF_L10N=firefox-l10n-ja         # 日本語 UI の言語パック。要らなければ空にする。<FF_L10N>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in FF_PKG FF_L10N; do printf '%-9s = %s\n' "$v" "${!v}"; done
   ```

   - **編集が必須の変数は無い**。最新版（Rapid Release）を入れるなら既定のままでよい
   - `FF_PKG` は `firefox` のまま使う
   - `FF_PKG` が空なら、ここで止めて直す
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. 署名鍵を落として、取り込む前に fingerprint と uid を確かめる。

   ```bash
   curl -fsSL https://packages.mozilla.org/rpm/firefox/signing-key.gpg | gpg --show-keys
   ```

   - `gpg` が無ければ、`sudo dnf install -y gnupg2` で入れてから貼り直す
   - `pub` 行の fingerprint が `14F26682D0916CDD81E37B6D61B7B526D98F0353`
   - uid が `Mozilla Software Releases <release@mozilla.com>`
   - 違っていればここで止める
   - **次の手順は、この 2 つを目で確かめてから貼る**

1. 一致したら、鍵を rpm に取り込み、入ったか確かめる。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     sudo rpm --import https://packages.mozilla.org/rpm/firefox/signing-key.gpg
     rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i mozilla
   }
   ```

   - `rpm --import` は期限切れの副鍵についての warning を出すが、問題ない
   - `gpg-pubkey-d98f0353-55a94004 Mozilla Software Releases ...` の 1 行が出る

1. Mozilla のリポジトリを追加し、入手できる版を見る。

   ```bash
   {
     sudo tee /etc/yum.repos.d/mozilla.repo >/dev/null <<'EOF'
   [mozilla]
   name=Mozilla Packages
   baseurl=https://packages.mozilla.org/rpm/firefox
   enabled=1
   gpgcheck=1
   repo_gpgcheck=0
   gpgkey=https://packages.mozilla.org/rpm/firefox/signing-key.gpg
   priority=10
   EOF
     printf '\n\033[7m 確認 \033[0m\n'
     dnf -q list --showduplicates "${FF_PKG}" | tail -6
   }
   ```

   - 一覧の下のほうに、`mozilla` リポジトリ提供の版が出る
   - `x86_64` の行も一緒に並ぶ

1. Firefox を入れる。

   ```bash
   sudo dnf install "${FF_PKG:?「Firefox」の手順 1 の FF_PKG が空のまま。値を入れて貼り直す}" ${FF_L10N}
   ```

   - AppStream の Firefox（ESR）が既に入っているホストでは、この 1 コマンドが `Upgrading: firefox` として解決される（参考資料を参照）
   - この文書を Firefox で見ているときは、入れ替わった後に Firefox を開き直す（この項の手順 7 で、新しい版で起動する）
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. Mozilla 公式のビルドが入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' "${FF_PKG}" ${FF_L10N}
   firefox --version
   rpm -qi "${FF_PKG}" | sed -n '/^Vendor/p;/^Build Date/p'
   ```

   - `from_repo` が `mozilla`、`Vendor` が `Mozilla` なら、Mozilla 公式のビルドが入っている

1. デスクトップのセッションで Firefox を起動し、`about:support` で公式のビルドかを確かめる。

   - 次のように出ればよい（日本語 UI の表記）
     - 「更新チャンネル」が `release`
     - 「プログラムの実行ファイル」が `/usr/lib/firefox/firefox-bin`（AppStream 版の `/usr/lib64` ではない）
   - 日本語パックを入れた場合は、`about:preferences` の言語で日本語を選べる

1. 入手できる版を見てから、RPM Fusion（[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 2〜5）の FFmpeg のライブラリを入れる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   dnf -q list --showduplicates ffmpeg-libs
   sudo dnf install ffmpeg-libs
   ```

   - 版は `ffmpeg-libs.aarch64  7.1.5-1.el10  rpmfusion-free-updates` のように出る
   - 依存として、RPM Fusion の `x264-libs`・`x265-libs` などと、EPEL のライブラリが入る
   - EPEL の `noopenh264` も依存で入るが、H.264 の再生には影響しない（参考資料を参照）
   - `conflicts with libswresample-free` と出て止まったら、この項の手順 9 で入れ直す。入ったときは手順 9 は飛ばす
   - **次の手順は、トランザクション表の `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. この項の手順 8 が `libavcodec-free` との衝突で止まったときだけ、それを外して入れ直す。

   ```bash
   sudo dnf install --allowerasing ffmpeg-libs
   ```

   - トランザクション表の `Removing dependent packages:` に、`libavcodec-free`・`libavutil-free`・`libswresample-free` の 3 つが出る
   - この 3 つのほかにも `Removing` に出たら、`N` で止める
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. FFmpeg のライブラリが入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' ffmpeg-libs rpmfusion-free-release epel-release
   ls /usr/lib64/libavcodec.so.*
   ```

   - `ffmpeg-libs 7.1.5-1.el10 rpmfusion-free-updates` の行と、`rpmfusion-free-release`・`epel-release` の行が出る
   - `/usr/lib64/libavcodec.so.61` がある

1. Firefox をすべて閉じてから起動し直し、AAC・H.264 の再生を確かめる。

   - **開いていたら全部閉じてから起動し直す**
   - `about:support` の「コーデックサポート情報」で、`H264` と `AAC` の「ソフトウェアデコーディング」が「対応」になる
   - 再生できなかった動画が再生できる

### HackGen Console NF

1. 変数を設定する。

   ```bash
   HACKGEN_FAMILY='HackGen Console NF'   # 確認と設定に使うファミリー名。<HACKGEN_FAMILY>
   printf '\n\033[7m 確認 \033[0m\n'
   printf '%-15s = %s\n' HACKGEN_FAMILY "${HACKGEN_FAMILY}"
   ```

   - **編集が必須の変数は無い**。この項の手順 5 の確認に使うファミリー名で、既定のまま進められる
   - 文字幅が半角 3:全角 5 の版を使いたいときだけ、`HackGen35 Console NF` に変える
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. `unzip` が入っているか確かめる。

   ```bash
   command -v unzip || echo 'unzip は未導入'
   ```

   - パスが出れば、この項の手順 3 は飛ばす
   - `unzip は未導入` と出たら、この項の手順 3 で入れる

1. `unzip` が未導入のときだけ、`unzip` を入れる。

   ```bash
   sudo dnf install -y unzip
   ```

1. HackGen を Homebrew の cask で入れる。

   ```bash
   brew install --cask font-hackgen-nerd
   ```

   - `==> Moving Font 'HackGenConsoleNF-Regular.ttf' to '/home/<USER>/.local/share/fonts/HackGenConsoleNF-Regular.ttf'` のような行が 4 つ出る
   - `font-hackgen-nerd was successfully installed!` で終わる

1. HackGen が入ったか確かめ、かな・漢字・記号・アイコンが入っているかも見る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   brew list --cask --versions font-hackgen-nerd
   ls ~/.local/share/fonts/
   fc-list : family style file | grep HackGen
   fc-match "${HACKGEN_FAMILY:?「HackGen Console NF」の手順 1 の HACKGEN_FAMILY が空のまま。値を入れて貼り直す}"
   for cp in 3042 6f22 e0b0 f09b; do printf 'U+%s: ' "${cp}"; fc-list ":charset=${cp}" family | grep -c -x -F "${HACKGEN_FAMILY:?「HackGen Console NF」の手順 1 の HACKGEN_FAMILY が空のまま。値を入れて貼り直す}"; done
   ```

   - `font-hackgen-nerd 2.10.0`、4 つの `.ttf`、`HackGen Console NF` と `HackGen35 Console NF` の Regular / Bold の 4 行が出る
   - `fc-match` が `HackGenConsoleNF-Regular.ttf: "HackGen Console NF" "Regular"` を返せばよい
   - **ファイル名が HackGen であることを確かめる**
   - 4 行とも `1` なら入っている（`あ` / `漢` / Powerline の三角 / GitHub のアイコン）

### WezTerm

1. chroot を明示して、COPR を有効化する。

   ```bash
   sudo dnf copr enable wezfurlong/wezterm-nightly "rhel-9-$(uname -m)"
   ```

   - 有効化してよいか `[y/N]` で聞かれる
   - **次の手順は、`[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. できた repo ファイルを確かめる。

   ```bash
   cat /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:wezfurlong:wezterm-nightly.repo
   ```

   - `baseurl` が `.../wezterm-nightly/rhel-9-$basearch/`、`gpgcheck=1` になっていればよい

1. WezTerm を入れる。

   ```bash
   sudo dnf install wezterm
   ```

   - 途中で COPR の GPG 鍵の取り込みを聞かれる
   - fingerprint は `FD90 9B62 88A8 4250 AD58 020F A698 91C5 CEA2 757D`（`wezfurlong_wezterm-nightly`）
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

1. WezTerm が入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   rpm -q wezterm wezterm-common wezterm-gui wezterm-mux-server
   dnf -q repoquery --installed --qf '%{name} %{from_repo}\n' 'wezterm*'
   wezterm --version
   ldd /usr/bin/wezterm-gui /usr/bin/wezterm /usr/bin/wezterm-mux-server | grep -c 'not found'   # 0 なら OK
   wezterm ls-fonts | sed -n '1,5p'
   ```

   - GUI は、**GNOME にログイン済みの実セッションの端末から** `wezterm` を起動すれば開く
   - アプリ一覧には「WezTerm」が出る

1. 自分用の設定（[ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm)）を入れ、起動し直した WezTerm に移る。

   - [その docs/install.md の実施手順](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md#実施手順)の手順 1〜4 を、この端末に貼る（`~/.config/wezterm` に clone する）
   - その手順 5〜7（`~/.bashrc` への直接の追記）は飛ばす。シェル統合は、[共通の bash 設定](#共通の-bash-設定)が読む
   - その手順 8 で WezTerm を起動し、手順 9 を WezTerm のタブに貼って確かめる
   - **この後の手順は、WezTerm のタブで貼る**（Nerd Font のアイコンを使う TUI の確かめも、WezTerm で見る）

### WezTerm と HackGen Console NF をデスクトップで使う

1. GNOME の等幅のフォントを HackGen Console NF にする。

   ```bash
   MONO_FONT='HackGen Console NF 11'   # 等幅のフォントの名前と大きさ。<MONO_FONT>
   ```

   ```bash
   if [ -z "${MONO_FONT}" ]; then echo '中断: MONO_FONT が空のまま。値を入れて貼り直す' >&2; else
     /usr/bin/gsettings get org.gnome.desktop.interface monospace-font-name
     /usr/bin/gsettings set org.gnome.desktop.interface monospace-font-name "${MONO_FONT}"
     printf '\n\033[7m 確認 \033[0m\n'
     /usr/bin/gsettings get org.gnome.desktop.interface monospace-font-name
   fi
   ```

   - 2 つ目の `get` が `'HackGen Console NF 11'` になればよい

1. Ctrl+Alt+T と Dash のお気に入りの端末を WezTerm にする。

   ```bash
   kb=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal/
   /usr/bin/gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}" command 'wezterm start'
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}" command
   fav=$(/usr/bin/gsettings get org.gnome.shell favorite-apps)
   /usr/bin/gsettings set org.gnome.shell favorite-apps "${fav//org.gnome.Ptyxis.desktop/org.wezfurlong.wezterm.desktop}"
   /usr/bin/gsettings get org.gnome.shell favorite-apps
   ```

   - `'wezterm start'` と、端末のところが `'org.wezfurlong.wezterm.desktop'` になったお気に入りが出ればよい
   - お気に入りに Ptyxis が無かったときは、お気に入りは変わらない

1. Ctrl+Alt+T と Dash から WezTerm が開き、等幅のフォントが変わったことを確かめる。

   - Ctrl+Alt+T と、Dash の WezTerm のアイコンで、WezTerm の窓が開く
   - Ptyxis（アクティビティの画面で「端末」）の文字が HackGen Console NF になっている

### git-delta

1. 変数を設定する。

   ```bash
   DELTA_NAVIGATE=true       # ページャ内で n / N を「次の変更・前の変更」にする。<DELTA_NAVIGATE>
   DELTA_LINE_NUMBERS=true   # 差分の左に行番号を出す。<DELTA_LINE_NUMBERS>
   DELTA_SIDE_BY_SIDE=false  # true にすると左右 2 面に分けて表示する。<DELTA_SIDE_BY_SIDE>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in DELTA_NAVIGATE DELTA_LINE_NUMBERS DELTA_SIDE_BY_SIDE; do printf '%-19s = %s\n' "$v" "${!v}"; done
   ```

   - **編集が必須の変数は無い**。既定のままで進められる
   - 広い画面で左右に並べたいなら、`DELTA_SIDE_BY_SIDE=true` にする
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. brew で git-delta を入れる。

   ```bash
   brew install git-delta
   ```

   - **次の手順は、Homebrew の確認が出たら答え、導入が成功してプロンプトに戻ってから貼る**（続けて貼ると確認の答えとして食われる）

1. `git config --global` で git の設定を書き、読み戻す。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   if [ -z "${DELTA_NAVIGATE}" ] || [ -z "${DELTA_LINE_NUMBERS}" ] || [ -z "${DELTA_SIDE_BY_SIDE}" ]; then
     echo '中断: 「git-delta」の手順 1 の変数が空。3 つとも設定してから貼り直す' >&2
   else
     git config --global core.pager delta &&
       git config --global interactive.diffFilter 'delta --color-only' &&
       git config --global delta.navigate "${DELTA_NAVIGATE}" &&
       git config --global delta.line-numbers "${DELTA_LINE_NUMBERS}" &&
       git config --global delta.side-by-side "${DELTA_SIDE_BY_SIDE}" &&
       git config --global merge.conflictstyle zdiff3 &&
       git config --global --get-regexp '^(core\.pager|interactive\.difffilter|delta\.(navigate|line-numbers|side-by-side)|merge\.conflictstyle)$'
   fi
   ```

   - 設定した 6 項目が出る。`中断:` が出た場合は、どの設定も書き換えていない
   - **`interactive.difffilter` と小文字で表示される**のが正しい

1. delta の版と、共通の bash 設定の clone の最後のコミットの差分の表示を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   delta --version
   brew list --versions git-delta
   command -v delta
   git -C ~/.config/bash show | delta --paging=never | head -20
   ```

   - 版は `delta 0.19.2` / `git-delta 0.19.2` のように出る
   - ファイル名のヘッダと、行ごとに背景色の付いた差分が出る
   - **`git diff` を単体で打ったときは、端末に直接出る場合だけ delta を通る**。`git diff | head` のようにパイプに繋ぐと git はページャを呼ばないので、素の差分が出る

### Neovim

1. brew で Neovim を入れる。

   ```bash
   brew install neovim
   ```

   - **次の手順は、Homebrew の確認が出たら答え、導入が成功してプロンプトに戻ってから貼る**（続けて貼ると確認の答えとして食われる）

1. Neovim が入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   nvim --version | head -3
   brew list --versions neovim
   command -v nvim
   ```

   - `NVIM v0.12.5` と `LuaJIT 2.1...` が出れば入っている
   - ここでは `nvim` を起動しない（この項の手順 3 の退避より前に起動すると、`~/.local/state/nvim` などができて、それも退避される）

1. 自分用の設定（[ryo-aoki-pc/LazyVimStarter](https://github.com/ryo-aoki-pc/LazyVimStarter)）を入れる。

   - [その docs/setup.md の「AlmaLinux 10 に導入する」](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#almalinux-10-に導入する-1-度だけ)の手順 3〜6・10・11・13〜18 を、上から順に貼る
   - 飛ばす手順: 1・2（EPEL。[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 1 で入れた）、7〜9（Homebrew。[Homebrew](#homebrew)で入れた。手順 9 の `~/.bashrc` への追記も行わない）、12（[HackGen Console NF](#hackgen-console-nf)で入れた）
   - その手順 3 で Node.js・ibus-anthy・wl-clipboard などを dnf で、手順 10 で lazygit・ripgrep・fd を Homebrew で入れる（Neovim は、この項の手順 1 で入っている）
   - その手順 13〜15 で、入力ソースは「英語 (US)」と Anthy の 2 つになり、Anthy の切り替えのキーから Ctrl+Space と Ctrl+J が外れる（JIS 配列のキーボードでも US にする。Neovim の IME 連携が、英数を `xkb:us::eng` に固定するため）
   - その手順 15 の後のログインし直しは、ここでは行わない（[再起動と確認](#再起動と確認)の手順 1 の再起動で読み直す）
   - その手順 17 で Neovim の画面が開く。Mason の導入を待ち、`:qa` で閉じてから次を貼る（その手順 18 は画面を開かない）
   - その手順 19（日本語検索・整形・IME 連携の確かめ）は、[再起動と確認](#再起動と確認)の手順 8 で行う

1. WezTerm で新しいタブを開き、既定のエディタを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   printf '%s / %s\n' "$EDITOR" "$VISUAL"
   alias vi
   ```

   - `nvim / nvim` と `alias vi='nvim'` が出ればよい
   - この 3 項目は共通の bash 設定が持つ（`nvim` があれば、開いたシェルで設定する）。元値の控えや `~/.bashrc` への追記は行わない
   - 開いていたタブは、`nvim` を入れる前の値のまま。`. ~/.bashrc` で読み直さない（[シェルのツール](#シェルのツール)の手順 2）

### lazygit

1. brew で lazygit を入れる。

   ```bash
   brew install lazygit
   ```

   - [Neovim](#neovim)の手順 3 で入っていれば、`Warning: lazygit … is already installed and up-to-date.` と出て何も変えない
   - **次の手順は、Homebrew の確認が出たら答え、導入が成功してプロンプトに戻ってから貼る**（続けて貼ると確認の答えとして食われる）

1. 自分用の設定（[ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit)）を入れる。

   - [その README の「導入方法」](https://github.com/ryo-aoki-pc/lazygit#導入方法)の Linux の例のとおりに、clone した `config.yml` を `~/.config/lazygit/config.yml` にリンクする
   - 差分の表示に delta（[git-delta](#git-delta)）、アイコンに Nerd Fonts（[HackGen Console NF](#hackgen-console-nf)）を使う設定
   - `e` キーで開くエディタは、`EDITOR`（[Neovim](#neovim)の手順 4）から決まる

1. lazygit が入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   lazygit --version
   brew list --versions lazygit
   command -v lazygit
   ```

   - `build source=Homebrew, version=0.65.1, os=linux, arch=arm64` のように出る

1. 共通の bash 設定の clone（`~/.config/bash`）で lazygit を起動して確かめる。

   ```bash
   (cd ~/.config/bash && lazygit)
   ```

   - 初回に `Thanks for using lazygit...` の案内が出たら Enter で閉じる。ファイル・変更差分・ブランチ・コミットの一覧が出ればよい
   - **注意**: git 管理下でないディレクトリで起動すると、リポジトリを作るか聞かれる
   - `q` で終了する
   - **次の手順は、`q` で終了してから貼る**（続けて貼ると lazygit への操作として食われる）

### GitHub CLI

1. `dnf config-manager` を使えるようにし、リポジトリを追加する。

   ```bash
   {
     sudo dnf install -y 'dnf-command(config-manager)'
     printf '\n\033[7m 確認 \033[0m\n'
     sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
     cat /etc/yum.repos.d/gh-cli.repo
   }
   ```

   - `Adding repo from: ...` と出て、`/etc/yum.repos.d/gh-cli.repo` ができる
   - `gpgcheck=1` になっていることを確認する

1. gh をインストールする。

   ```bash
   sudo dnf install gh
   ```

   - 初回は署名鍵の取り込みを **2 回**聞かれる
   - fingerprint が次の 2 つであることを目で確かめてから `y` と答える
     - `7F38 BBB5 9D06 4DBC B3D8 4D72 5612 B364 6231 3325`
     - `2C61 0620 1985 B60E 6C7A C873 23F3 D4EA 7571 6059`
   - どちらも Userid は `GitHub CLI <opensource+cli@github.com>`。違っていれば `N` で中断する
   - **次の手順は、答えてから貼る**（続けて貼ると答えとして食われる）

1. GitHub へのログインを始める。

   ```bash
   gh auth login
   ```

   - 対話で GitHub.com / HTTPS / ブラウザ認証を選ぶ
   - `Authenticate Git with your GitHub credentials?` は `Y`（既定）でよい。git の HTTPS の認証に gh を使う行が `~/.gitconfig` に入る（外すのは[ロールバックの「Git の道具を消す」](extra/almalinux-setup.md#git-の道具を消す)の手順 6）
   - ワンタイムコードが表示されたら、この項の手順 4 のブラウザで使う
   - **トークン（`gh auth token` の出力）や、認証中に表示されるワンタイムコードはこの文書に載せない**

1. ブラウザで、GitHub の認証を済ませる。

   - この項の手順 3 のワンタイムコードを、ブラウザの `https://github.com/login/device` に入れ、画面の案内に従う
   - SSH 越しの端末でこのホストのブラウザを開けないときは、手元のブラウザで開く
   - **次の手順は、`gh auth login` が終わってから貼る**（続けて貼ると対話の答えとして食われる）

1. 認証できたか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   gh auth status
   gh --version
   ```

   - 認証前の `gh auth status` は `You are not logged into any GitHub hosts.` を返す

### yazi

1. 変数を設定する。

   ```bash
   YAZI_EXTRAS="ffmpeg-full sevenzip jq poppler fd ripgrep fzf resvg imagemagick-full font-symbols-only-nerd-font"   # プレビューと検索に使う。空にすると yazi 本体だけ
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'YAZI_EXTRAS = %s\n' "${YAZI_EXTRAS}"
   ```

   - **編集が必須の変数は無い**
   - 最小構成にするなら、`YAZI_EXTRAS` を空にする
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. brew で yazi と、プレビュー・検索に使うツールを入れる。

   ```bash
   brew install yazi ${YAZI_EXTRAS}
   ```

   - 確認が出たら表示された導入予定を確かめて `y` と答え、処理が終わってプロンプトに戻ってから次の手順を貼る（[Homebrew の注意点](extra/almalinux-setup.md#注意点)）
   - fd と ripgrep は[Neovim](#neovim)の手順 3 で入っているので、`Warning: fd … is already installed and up-to-date.` のように出る

1. 自分用の設定（[ryo-aoki-pc/yazi](https://github.com/ryo-aoki-pc/yazi)）を入れる。

   - [その README の「インストール」](https://github.com/ryo-aoki-pc/yazi#インストール)のとおりに、`custom` ブランチを `~/.config/yazi` に clone する
   - ファイルを開くエディタは nvim（[Neovim](#neovim)）、`z` と `Z` のキーは fzf と zoxide（[シェルのツール](#シェルのツール)の手順 1）を使う

1. WezTerm で新しいタブを開き、y 関数を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   type -t y
   ```

   - `function` が出ればよい。`~/.bashrc` への関数の追記は不要
   - 共通の bash 設定は、`yazi` があるときだけ `y` を作る。開いていたタブには無いので、`. ~/.bashrc` で読み直さずに新しいタブで確かめる（[シェルのツール](#シェルのツール)の手順 2）

1. 同じタブで、yazi が入ったか確かめ、`y` で起動する。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   yazi --version
   ya --version
   brew list --versions yazi
   y
   ```

   - `Version: 26.9.1 (Homebrew ...)`、`Triple: aarch64-unknown-linux-gnu` のように出る
   - プレビューを確かめるには、PDF・動画・画像・書庫のあるディレクトリで右ペインを見る
   - 画像プレビューは端末側の対応が要る（[注意点](extra/almalinux-setup.md#注意点)）
   - 画面が出たら `q` で終了する
   - **ほかのコマンドは、`q` で終了してから貼る**（続けて貼ると yazi への操作として食われる）

### Claude Code

1. 変数を設定する。

   ```bash
   CC_CHANNEL=latest               # 追従するチャンネル。latest（出た版をすぐ配る）か stable（約 1 週間遅れ）。<CC_CHANNEL>
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'CC_CHANNEL = %s\n' "${CC_CHANNEL}"
   ```

   - **編集が必須の変数は無い**。既定の `latest`（最新版）でよければ、そのまま貼る
   - 大きな不具合のある版を避けたいなら `stable`（1 週間ほど遅れて、そうした版を飛ばすチャンネル）にする
   - 最後に値を読み戻して確かめる
   - `latest` か `stable` 以外が入っていたら、ここで止めて直す
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. リポジトリを追加する。

   ```bash
   if [ -z "${CC_CHANNEL}" ]; then echo '中断: 「Claude Code」の手順 1 の CC_CHANNEL が空のまま。値を入れて貼り直す' >&2; else
     sudo tee /etc/yum.repos.d/claude-code.repo >/dev/null <<EOF
   [claude-code]
   name=Claude Code
   baseurl=https://downloads.claude.ai/claude-code/rpm/${CC_CHANNEL:?「Claude Code」の手順 1 の CC_CHANNEL が空のまま。値を入れて貼り直す}
   enabled=1
   gpgcheck=1
   gpgkey=https://downloads.claude.ai/keys/claude-code.asc
   EOF
     printf '\n\033[7m 確認 \033[0m\n'
     cat /etc/yum.repos.d/claude-code.repo
   fi
   ```

   - `baseurl` の末尾がこの項の手順 1 で選んだチャンネル（既定なら `latest`）になっていることを確認する
   - `中断:` と出たら、何も書いていない

1. Claude Code をインストールする。

   ```bash
   sudo dnf install claude-code
   ```

   - トランザクション表で `claude-code` の版（既定の `latest` なら、その日の最新版）を確かめて `y` と答える
   - 初回は続けて署名鍵の取り込みを聞かれる
   - 表示される fingerprint が `31DD DE24 DDFA B679 F42D 7BD2 BAA9 29FF 1A7E CACE` であることを**目で確かめてから** `y` と答える
   - 違っていれば `N` で中断する
   - **次の手順は、答えてから貼る**（続けて貼ると答えとして食われる）

1. インストールできたか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}' claude-code
   dnf -q repoquery --available --latest-limit 1 --qf '%{name} %{version}-%{release} %{reponame}' claude-code
   claude --version
   rpm -ql claude-code
   ```

   - 1 行目（入っている版）と 2 行目（チャンネルにある一番新しい版）が同じなら、そのチャンネルの最新版が入っている
   - `2.1.283 (Claude Code)` のようにバージョンが出れば動く
   - 入るファイルは実行ファイル 1 つとライセンスだけ（[完了時点の状態](verification/almalinux-setup.md#claude-code-完了時点の状態)）

1. 確認用のディレクトリで `claude` を起動し、ブラウザでログインする。

   ```bash
   mkdir -p ~/claude-sandbox
   cd ~/claude-sandbox
   claude
   ```

   - フォルダーを信頼するか聞かれたら、`claude-sandbox` であることを確かめて信頼する
   - 画面の案内に従ってブラウザでログインする
   - Pro / Max / Team / Enterprise か Console のアカウントが要る（無料の claude.ai プランでは使えない）
   - `ANTHROPIC_API_KEY` を設定している場合は、ブラウザではなくその鍵を使ってよいか 1 度だけ聞かれる
   - **認証情報（トークン・API キー）はこの文書に載せない**
   - `/exit` で終える
   - **次の手順は、`/exit` で Claude Code を終えてシェルのプロンプトに戻ってから貼る**（続けて貼ると Claude Code への入力として食われる）

### Codex CLI

1. 既存の Codex が入っていないか確かめる。

   ```bash
   command -v codex
   ```

   - 新規の PC なら何も出ず、終了コードは 1 になる
   - パスが出たら、元の導入方法を確認してから進める。npm・Homebrew・standalone を重ねて入れない
   - `CODEX_HOME`・`CODEX_INSTALL_DIR`・`CODEX_RELEASE` は変えない（この項は、既定の場所への新規の standalone インストールを前提にする。ロールバックもその場所を消す）
   - 入れるのは端末で使う Codex CLI。デスクトップアプリとエディタの拡張機能は別に入れる

1. インストーラーが使う道具を入れる。

   ```bash
   sudo dnf install -y curl-minimal ca-certificates tar gzip
   ```

   - `curl` が既に入っていて `curl-minimal` と競合するときは、`curl-minimal` を外して実行する

1. 公式の standalone インストーラーで Codex CLI を入れる。

   ```bash
   curl -fsSL https://chatgpt.com/codex/install.sh | sh
   ```

   - `Codex CLI … installed successfully.` を確認する
   - `Start Codex now?` と聞かれたら `n` で答える
   - **次の手順は、インストーラーが終わり、シェルのプロンプトに戻ってから貼る**

1. 今の端末の PATH を通し、実行ファイルと版を確かめる。

   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   hash -r
   printf '\n\033[7m 確認 \033[0m\n'
   command -v codex
   codex --version
   ```

   - 自分のホームの `.local/bin/codex` と `codex-cli …` が出る
   - 新しく開いた端末でも `codex --version` が通ることを確認する

1. ChatGPT でのログインを始める。

   ```bash
   codex login
   ```

   - ブラウザが開く。自動で開かなければ、端末に出た URL を同じ PC のブラウザで開く
   - コマンドはログインが完了するまで待つ
   - ブラウザの無いホストでは、この項の手順 5・6 の代わりに[Codex CLI をブラウザの無いホストでログインする](#codex-cli-をブラウザの無いホストでログインする)を通す

1. ブラウザで ChatGPT にログインし、Codex との接続を承認する。

   - 利用するアカウント・ワークスペースを選ぶ
   - **次の手順は、端末でログインの成功を確認し、シェルのプロンプトに戻ってから貼る**

1. ログイン状態を確かめる。

   ```bash
   codex login status
   ```

   - ChatGPT でログイン済みであることを確認する
   - ログイン情報のファイルの中身を表示・共有する必要は無い

1. 確認用のディレクトリで Codex を起動する。

   ```bash
   mkdir -p ~/codex-sandbox
   cd ~/codex-sandbox
   git init
   codex
   ```

   - 作業場所の確認が出たら、`codex-sandbox` であることを確認する
   - 入力欄に「このディレクトリの状態を説明してください。ファイルは変更しないでください」と入力し、応答を確認する
   - 終了するときは `/quit` を入力する
   - **次の手順は、Codex を終了してシェルのプロンプトに戻ってから貼る**

### Grok Build

1. 既存の Grok と、同じ名前のコマンドが無いか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   command -v grok agent curl
   ls -ld ~/.grok
   ```

   - 新規の PC なら `curl` のパスだけが出て、`ls` は `No such file or directory` になる
   - `curl` のパスが出なければ、`sudo dnf install -y curl-minimal` で入れてから進む
   - `grok` か `~/.grok` があれば、元の導入方法を確かめてから進める。非公式の grok-cli も同じ `grok` と `~/.grok` を使うので、先に外す
   - `agent` のパスが出たら、それが何かを確かめる。インストーラーは `~/.local/bin/agent` を Grok へのリンクで置き換えることがある（[注意点](extra/almalinux-setup.md#注意点)）

1. 公式のインストーラーで Grok Build を入れる。

   ```bash
   curl -fsSL https://x.ai/cli/install.sh | bash
   ```

   - `Grok … installed to /home/<USER>/.grok/bin/grok` を確かめる
   - `Updated /home/<USER>/.grok/bin in PATH in /home/<USER>/.bashrc.` が出る。`~/.bashrc` の末尾に `# >>> grok installer >>>` から `# <<< grok installer <<<` までのブロックが足され、初回は元のファイルが `~/.bashrc.bak.<数字>` に控えられる
   - `~/.local/bin` が PATH にあるホスト（[Codex CLI](#codex-cli)で Codex を入れたホストなど）では、`Symlinked /home/<USER>/.local/bin/grok -> …` と `…/agent -> …` も出る
   - 質問は出ない

1. 今の端末の PATH を通し、実行ファイルと版を確かめる。

   ```bash
   export PATH="$HOME/.grok/bin:$PATH"
   hash -r
   printf '\n\033[7m 確認 \033[0m\n'
   command -v grok
   grok --version
   ```

   - 自分のホームの `.grok/bin/grok` と `grok 1.0.50 (…)` のような版が出る
   - 新しく開いた端末でも `grok --version` が通ることを確かめる

1. ブラウザでのログインを始める。

   ```bash
   grok login
   ```

   - ブラウザが開く。開かなければ、端末に出た `https://accounts.x.ai/oauth2/device?user_code=…` の URL を同じ PC のブラウザで開く
   - 端末に確認用のコード（`XXXX-XXXX` の形）が出て、`Waiting for authorization...` のまま待つ
   - ブラウザの無いホストでは、この項の手順 4・5 の代わりに[Grok Build をブラウザの無いホストでログインする](#grok-build-をブラウザの無いホストでログインする)を通す

1. ブラウザで grok.com のアカウントにログインし、Grok Build との接続を承認する。

   - ブラウザに出たコードが、端末のコードと同じであることを確かめてから承認する
   - **次の手順は、端末でログインの成功を確かめ、シェルのプロンプトに戻ってから貼る**

1. ログインを確かめる。

   ```bash
   grok models
   ```

   - `You are not authenticated.` が出なければ、ログインできている
   - ログインしていなくても終了コードは 0 で、モデルの一覧は出る。終了コードでは判定しない
   - ログインの情報は `~/.grok/auth.json` に入る。中身を表示・共有しない

1. 確認用のディレクトリで Grok を起動する。

   ```bash
   mkdir -p ~/grok-sandbox
   cd ~/grok-sandbox
   git init
   grok
   ```

   - フォルダーを信頼するか聞かれたら、`grok-sandbox` であることを確かめて信頼する
   - 入力欄に「このディレクトリの状態を説明してください。ファイルは変更しないでください」と入力し、応答を確かめる
   - 終了するときは `/quit` を入力する
   - **次の手順は、Grok を終了してシェルのプロンプトに戻ってから貼る**

### Codex・Grok のプラグイン

1. Node.js と bubblewrap を入れる（プラグインと sandbox が使う）。

   ```bash
   {
     sudo dnf install -y nodejs bubblewrap
     printf '\n\033[7m 確認 \033[0m\n'
     node --version
     bwrap --version
   }
   ```

   - `v22.…` と `bubblewrap 0.…` が出ればよい（プラグインは Node.js 18.18 以上が要る）
   - Node.js は、[Neovim](#neovim)の手順 3（LazyVimStarter の導入）で入っていれば、`Package nodejs-… is already installed.` と出る
   - Grok の sandbox には、Landlock が有効な Linux カーネルも要る（sandbox を使うときの条件とエラーは、[注意点](extra/almalinux-setup.md#注意点)の「Grok Build: sandbox は既定で無効」）
   - GNOME のデスクトップの PC には、Flatpak の依存として bubblewrap がもう入っている（`Package bubblewrap-… is already installed.`）

1. Claude Code に、OpenAI の Codex のプラグインと xAI の Grok Build のプラグインを入れる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   claude plugin marketplace add openai/codex-plugin-cc
   claude plugin marketplace add xai-org/grok-build-plugin-cc
   claude plugin install codex@openai-codex
   claude plugin install grok-build@xai-grok-build
   claude plugin list
   ```

   - `✔ Successfully added marketplace: openai-codex` と `xai-grok-build`、`✔ Successfully installed plugin: …（scope: user）` が 2 つ出る
   - 最後の一覧に、`codex@openai-codex` と `grok-build@xai-grok-build` が `Status: ✔ enabled` で出る
   - 動いている Claude Code には、起動し直すまで効かない

### 再起動と確認

1. 再起動する。

   ```bash
   sudo systemctl reboot
   ```

   - 保存していない文書のあるアプリが開いていると、`Operation inhibited by …` で断られることがある。そのアプリを閉じてから貼り直す
   - **次の手順は、起動してログインしてから行う**

1. ログインした画面で、上部バー・ウィンドウ・Dash が変わったことを確かめる。

   - 上部バーの時計に曜日と秒が出る（電池のある PC では、電池の % も）
   - 上部バーの右に、入力ソースの表示が出る
   - 画面が濃い色（ダーク）になっている。Super キーで開くアクティビティの画面の下の Dash が、[GNOME の表示と入力](#gnome-の表示と入力)の手順 13 の並び（端末のところは WezTerm。[WezTerm と HackGen Console NF をデスクトップで使う](#wezterm-と-hackgen-console-nf-をデスクトップで使う)の手順 2）
   - Files などのウィンドウのタイトルバーの右に、最小化・最大化・閉じるの 3 つのボタンが出る（自分用の設定の WezTerm は、タブバーの右端に自分でボタンを描く）
   - 「標準フォルダーの名前を現在の言語に合わせて更新しますか?」の窓は出ない。出たら、「次回から表示しない」をオンにして「古い名前のままにする」を押す

1. 端末を開き、再起動の後の状態を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   journalctl --list-boots --no-pager | tail -n 2
   cat /sys/kernel/kexec_crash_size
   hostnamectl --static
   xdg-user-dir DOWNLOAD
   ibus list-engine | grep -w anthy
   gnome-extensions info appindicatorsupport@rgcjonas.gmail.com | grep -E '^ *(状態|State)'
   /usr/bin/gsettings get org.gnome.mutter experimental-features
   ```

   - `journalctl --list-boots` に 2 行出る（前の起動のログが残っている。[システムの設定](#システムの設定)の手順 5）
   - `0` が出る（[システムの設定](#システムの設定)の手順 7 で kdump を止めたとき）
   - [システムの設定](#システムの設定)の手順 2 の名前（変えたとき）と、`/home/<USER>/Downloads` が出る
   - `anthy - Anthy` が出る
   - トレイアイコンの拡張が `ACTIVE` になっている
   - `['scale-monitor-framebuffer', 'xwayland-native-scaling']` が出る

1. 拡大率を変えるときだけ、設定の「ディスプレイ」の「スケーリング」で選ぶ。

   - アクティビティの画面で「設定」を開き、「ディスプレイ」→「スケーリング」で 125% などを選ぶ
   - 上に出る「適用」を押し、「この表示設定を保存しますか?」の窓で「変更を保存」を押す（押さないと、しばらくして元に戻る）
   - 選べる拡大率は、画面の解像度で決まる（解像度の低い画面では 100% しか出ないことがある）

1. キーボードで、Caps Lock・Alt+Tab・Ctrl+Alt+T を確かめる。

   - テキストエディターに何か打ち、Caps Lock を押したまま A を押すと、全部が選ばれる（Ctrl+A）。Caps Lock だけを押しても大文字にならない
   - ウィンドウを 2 つ以上開いて Alt+Tab を押すと、ウィンドウごとに切り替わる（同じアプリの窓も別に並ぶ）。Super+Tab はアプリごと
   - Ctrl+Alt+T で、WezTerm の新しい窓が開く（[WezTerm と HackGen Console NF をデスクトップで使う](#wezterm-と-hackgen-console-nf-をデスクトップで使う)の手順 2）

1. 入力ソースを切り替えて、日本語を打ってみる。

   - Super+Space で、上部バーの入力ソースの表示が「英語 (US)」と Anthy の間で切り替わる（[Neovim](#neovim)の手順 3。その手順を飛ばしたときは、[日本語入力](#日本語入力)の手順 2 の配列と Anthy の間）
   - Anthy に切り替えてからテキストエディターなどで `nihongo` と打ち、Space を押すと「日本語」に変わり、Enter で確定する
   - Anthy は、ひらがなで始まる
   - 英字と日本語の切り替えは、Super+Space と、Neovim の中の `<C-j>`（[Neovim](#neovim)の手順 3 で、Anthy の切り替えのキーから Ctrl+Space と Ctrl+J を外した）。JIS 配列のキーボードも US 配列として打つ（刻印と違う記号が出るキーがある）

1. Files で、フォルダーの名前と、隠しファイルとフォルダーの並びを確かめる。

   - Files（アクティビティの画面で「ファイル」）でホームを開くと、`Desktop`・`Documents`・`Downloads` などの英語の名前のフォルダーが並び、日本語の名前のフォルダーは無い
   - `.bashrc`・`.config` などの隠しファイルも出て、フォルダーがファイルより先に並ぶ
   - 左のサイドバーにも `Documents`・`Downloads` などが並び、押すとそのフォルダーが開く

1. Neovim で、日本語の検索・整形と IME 連携を確かめる。

   - [LazyVimStarter の docs/setup.md の「AlmaLinux 10 に導入する」](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#almalinux-10-に導入する-1-度だけ)の手順 19 を、WezTerm のタブで行う（[Neovim](#neovim)の手順 3 の続き）
   - `/tmp/lazyvim-check.md` が無いとき（`/tmp` を tmpfs にした PC では、再起動で消える）は、その手順 17 のブロックの 1 行目（`printf …`）を貼ってから開く
   - Neovim の画面が開く。`o` で足した行は保存せず、`:qa!` で閉じる（その手順 19 の最後の箇条書き）

---

## SSH を公開鍵だけにする（任意）

- 常時動かしておく PC で、パスワードでの SSH のログインを断り、公開鍵だけにする
- 鍵は、つなぐ側の PC で作る（`ssh-keygen -t ed25519`）。公開鍵の 1 行は、つなぐ側の `~/.ssh/id_ed25519.pub`（Windows は `%USERPROFILE%\.ssh\id_ed25519.pub`）
- この節の手順 2・4 は、つなぐ側の PC で行う

> [!WARNING]
> **この節の手順 3 の後は、パスワードでは SSH でログインできない**。この節の手順 2 で、鍵でログインできることを確かめてから貼る。SSH でつないで作業しているときは、そのセッションを閉じずに、別のセッションでこの節の手順 4 を確かめる。

1. 公開鍵を `~/.ssh/authorized_keys` に足す（`SSH_PUBKEY` は必ず値を入れる）。

   ```bash
   SSH_PUBKEY=''   # つなぐ側の PC の公開鍵（ssh-ed25519 AAAA… の 1 行）。<SSH_PUBKEY>
   ```

   ```bash
   if [ -z "${SSH_PUBKEY}" ]; then echo '中断: SSH_PUBKEY が空のまま。公開鍵の 1 行を入れて貼り直す' >&2
   elif ! printf '%s\n' "${SSH_PUBKEY}" | ssh-keygen -lf - >/dev/null; then echo '中断: SSH_PUBKEY が公開鍵の形ではない' >&2
   else
     install -d -m 700 ~/.ssh
     touch ~/.ssh/authorized_keys
     chmod 600 ~/.ssh/authorized_keys
     if grep -qxF "${SSH_PUBKEY}" ~/.ssh/authorized_keys; then echo 'この鍵はもうある'; else printf '%s\n' "${SSH_PUBKEY}" >> ~/.ssh/authorized_keys; fi
     restorecon -R ~/.ssh
     printf '\n\033[7m 確認 \033[0m\n'
     ssh-keygen -lf ~/.ssh/authorized_keys
   fi
   ```

   - 最後に、足した鍵の fingerprint（`256 SHA256:… (ED25519)`）が出ればよい

1. つなぐ側の PC から、鍵でログインできることを確かめる。

   - `ssh -o PasswordAuthentication=no <USER>@<IP>` でログインできればよい（パスフレーズを付けた鍵なら、パスフレーズを聞かれる）
   - `Permission denied (publickey,…)` で断られたら、この節の手順 1 の鍵と、つなぐ側の鍵が合っていない。この節の手順 3 へは進まない
   - **次の手順は、鍵でログインできてから貼る**

1. パスワードでの SSH のログインを切る。

   ```bash
   {
     printf 'PasswordAuthentication no\nKbdInteractiveAuthentication no\n' | sudo install -m 0600 /dev/stdin /etc/ssh/sshd_config.d/40-pubkey-only.conf
     printf '\n\033[7m 確認 \033[0m\n'
     sudo sshd -t && sudo systemctl reload sshd
     sudo sshd -T | grep -Ei '^(passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication) '
   }
   ```

   - `passwordauthentication no`・`kbdinteractiveauthentication no`・`pubkeyauthentication yes` が出ればよい
   - `sshd -t` が設定の誤りを見つけたら、reload しない（誤りの行が出る）。今つないでいるセッションは切れない

1. つなぐ側の PC から、パスワードでは断られることを確かめる。

   - `ssh -o PubkeyAuthentication=no <USER>@<IP>` が、パスワードを聞かずに `Permission denied (publickey,gssapi-keyex,gssapi-with-mic).` で断られればよい
   - 鍵（`ssh <USER>@<IP>`）では、そのまま入れる

1. 元に戻すときは、この節の手順 3 のファイルを消し、パスワードでもログインできるようにする。

   ```bash
   {
     sudo rm -f /etc/ssh/sshd_config.d/40-pubkey-only.conf
     sudo sshd -t && sudo systemctl reload sshd
     printf '\n\033[7m 確認 \033[0m\n'
     sudo sshd -T | grep -Ei '^(passwordauthentication|kbdinteractiveauthentication) '
   }
   ```

   - `passwordauthentication yes` と `kbdinteractiveauthentication no` が出ればよい
   - 足した公開鍵は `~/.ssh/authorized_keys` に残る。要らなければ、その行を手で消す

---

## dnf-automatic で自動で更新する（任意）

- BaseOS の `dnf-automatic` のタイマーで、毎日、更新をダウンロードして入れる。再起動はしない（カーネルなどの更新は、[OS とファームウェアの更新](#os-とファームウェアの更新)の手順 4・5 で自分で再起動する）
- GNOME Software の自動の更新（裏でダウンロードし、再起動のときに入れる）は、この節の手順 3 で止める（二重にしない）
- 戻すときは、この節の手順 5・6

1. dnf-automatic を入れる。

   ```bash
   sudo dnf install dnf-automatic
   ```

   - `インストール:` が `dnf-automatic` の 1 つだけになる。`これでよろしいですか? [y/N]:` に `y`
   - **次の手順は、`完了しました!` が出てプロンプトに戻ってから貼る**（続けて貼ると、`[y/N]` の答えとして食われる）

1. 更新を入れるタイマーを有効にする。

   ```bash
   {
     sudo systemctl enable --now dnf-automatic-install.timer
     printf '\n\033[7m 確認 \033[0m\n'
     systemctl list-timers 'dnf-automatic*' --no-pager
   }
   ```

   - `dnf-automatic-install.timer` の行に、次に動く日時（`NEXT`）が出ればよい

1. GNOME Software の自動の更新を止める。

   ```bash
   /usr/bin/gsettings set org.gnome.software download-updates false
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.software download-updates
   ```

   - `false` が出ればよい

1. 今すぐ 1 回動かして、動くことを確かめる。

   ```bash
   {
     sudo systemctl start dnf-automatic-install.service
     printf '\n\033[7m 確認 \033[0m\n'
     systemctl status dnf-automatic-install.service --no-pager | head -n 5
     journalctl -u dnf-automatic-install.service -b --no-pager | tail -n 5
   }
   ```

   - `Active: inactive (dead)` と、`… Finished dnf-automatic-install.service …` の行が出ればよい（更新が無ければすぐに終わる）
   - 更新があれば、入れ終わるまでプロンプトに戻らない

1. 元に戻すときは、タイマーを止め、GNOME Software の自動の更新を戻す。

   ```bash
   {
     sudo systemctl disable --now dnf-automatic-install.timer
     /usr/bin/gsettings reset org.gnome.software download-updates
     printf '\n\033[7m 確認 \033[0m\n'
     systemctl list-timers 'dnf-automatic*' --no-pager
     /usr/bin/gsettings get org.gnome.software download-updates
   }
   ```

   - タイマーの一覧が `0 timers listed.` になり、最後に `true` が出ればよい

1. 元に戻すときは、続けて dnf-automatic を外す。

   ```bash
   sudo dnf remove dnf-automatic
   ```

   - `削除中:` が `dnf-automatic` の 1 つだけになる。`これでよろしいですか? [y/N]:` に `y`

---

## 画面オフ・画面ロック・自動サスペンドを止める（任意）

- 常時動かしておく PC で、GNOME が画面を消したり、ロックしたり、放置で眠ったりしないようにする。ログイン画面・蓋・OS のサスペンドも止める
  - WireGuard・Samba・Syncthing・Dropbox のホストや、RDP で待ち受ける PC は、眠るとサービスが止まる
  - [GNOME のヘッドレスのセッション](gnome-headless-session.md)はこの節の手順 1・2（サスペンドできる PC ではこの節の手順 3・4 も）、[Claude Code で GUI を確かめる](claude-code-gui.md)はこの節の手順 1・2、[GNOME のデスクトップ共有](gnome-desktop-sharing.md)はこの節の手順 1〜4 を前提にしている
- **人が触れる場所にある PC では行わない**（画面をロックしないので、前にいる人がそのまま使える）
- GNOME を入れていない（デスクトップの無い）機械では、この節の手順 4・5 だけを行う
- GNOME にログインするユーザー本人の端末で、この節の手順 1 で変数を設定してから、上から順に貼る
- 戻すときは、この節の手順 6〜9。変える前の値ではなく**既定値**に戻る（Server with GUI で入れた PC は、既定でも電源につないでいる間は眠らない）

1. 変数を設定する。

   ```bash
   IDLE_DELAY=0               # 無操作で画面を消すまでの秒数。0 は消さない（GNOME の既定は 300）
   LOCK_ENABLED=false         # 画面が消えたときにロックするか。true / false（既定は true）
   POWER_BUTTON=interactive   # 電源ボタンを押したとき。interactive（電源オフの確認を出す）/ nothing（何もしない）
   printf '\n\033[7m 確認 \033[0m\n'
   for v in USER IDLE_DELAY LOCK_ENABLED POWER_BUTTON; do
     printf '%-12s = %s\n' "$v" "${!v}"
   done
   ```

   - **編集が必須の変数は無い**。既定のままなら、画面を消さず、ロックもしない
   - 最後に値を読み戻して確かめる
   - `USER` が `root` になっているなら、ここで止めて、自分のユーザーのシェルで貼り直す
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、この節の手順 1 のブロックを貼り直してから先へ進む

1. 自分のセッションの画面オフ・減光・ロック・自動サスペンド・電源ボタンを変える。

   ```bash
   /usr/bin/gsettings set org.gnome.desktop.session idle-delay "${IDLE_DELAY:?この節の手順 1 の IDLE_DELAY が空のまま。値を入れて貼り直す}"
   /usr/bin/gsettings set org.gnome.desktop.screensaver lock-enabled "${LOCK_ENABLED:?この節の手順 1 の LOCK_ENABLED が空のまま。値を入れて貼り直す}"
   /usr/bin/gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
   /usr/bin/gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type nothing
   /usr/bin/gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type nothing
   /usr/bin/gsettings set org.gnome.settings-daemon.plugins.power power-button-action "${POWER_BUTTON:?この節の手順 1 の POWER_BUTTON が空のまま。値を入れて貼り直す}"
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.desktop.session idle-delay
   /usr/bin/gsettings get org.gnome.desktop.screensaver lock-enabled
   /usr/bin/gsettings list-recursively org.gnome.settings-daemon.plugins.power | grep -E 'idle-dim|sleep-inactive-(ac|battery)-type|power-button-action'
   ```

   - `uint32 0`、`false`、続いて `idle-dim false`・`power-button-action 'interactive'`・`sleep-inactive-ac-type 'nothing'`・`sleep-inactive-battery-type 'nothing'` の 4 行が出ればよい
   - 値が変わっていなければ、デスクトップの端末でこの節の手順 1 から貼り直す
   - **注意**: `/usr/bin/` を外さない

1. ログイン画面（GDM）用の設定を書き、dconf を作り直して、ログイン画面から見える値を確かめる。

   ```bash
   if [ -z "${POWER_BUTTON}" ]; then echo '中断: この節の手順 1 の POWER_BUTTON が空のまま。値を入れて貼り直す' >&2; else
     sudo tee /etc/dconf/db/gdm.d/90-power >/dev/null <<EOF
   [org/gnome/settings-daemon/plugins/power]
   sleep-inactive-ac-type='nothing'
   sleep-inactive-battery-type='nothing'
   power-button-action='${POWER_BUTTON:?この節の手順 1 の POWER_BUTTON が空のまま。値を入れて貼り直す}'
   EOF
     printf '\n\033[7m 確認 \033[0m\n'
     sudo dconf update
     sudo -u gdm env DCONF_PROFILE=gdm /usr/bin/gsettings list-recursively org.gnome.settings-daemon.plugins.power | grep -E 'sleep-inactive-(ac|battery)-type|power-button-action'
   fi
   ```

   - `dconf update` は、成功すると何も出さない。`invalid value` と出たら、この手順を貼り直す
   - `power-button-action 'interactive'`・`sleep-inactive-ac-type 'nothing'`・`sleep-inactive-battery-type 'nothing'` の 3 行が出ればよい
   - `中断:` と出たら、何も書いていない

1. OS 全体で、サスペンドとハイバネートを止める。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
     systemctl is-enabled sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
   }
   ```

   - `Created symlink '/etc/systemd/system/sleep.target' → '/dev/null'.` のような行が 5 つ出て、`masked` が 5 行出ればよい
   - **注意**: ノート PC は、蓋を閉じても電池が減っても眠らない。閉じたまま鞄に入れると熱を持つので、持ち歩くときは電源を切る

1. 蓋を閉じても何もしないように、logind のドロップインを置く。

   ```bash
   {
     sudo mkdir -p /etc/systemd/logind.conf.d
     sudo tee /etc/systemd/logind.conf.d/90-lid.conf >/dev/null <<'EOF'
   [Login]
   HandleLidSwitch=ignore
   EOF
     sudo systemctl reload systemd-logind
     printf '\n\033[7m 確認 \033[0m\n'
     busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager HandleLidSwitch
   }
   ```

   - `s "ignore"` と出ればよい

1. 元に戻すときは、自分のセッションの値を既定値に戻す。

   ```bash
   /usr/bin/gsettings reset org.gnome.desktop.session idle-delay
   /usr/bin/gsettings reset org.gnome.desktop.screensaver lock-enabled
   /usr/bin/gsettings reset org.gnome.settings-daemon.plugins.power idle-dim
   /usr/bin/gsettings reset org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type
   /usr/bin/gsettings reset org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type
   /usr/bin/gsettings reset org.gnome.settings-daemon.plugins.power power-button-action
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.desktop.session idle-delay
   /usr/bin/gsettings get org.gnome.desktop.screensaver lock-enabled
   /usr/bin/gsettings list-recursively org.gnome.settings-daemon.plugins.power | grep -E 'idle-dim|sleep-inactive-(ac|battery)-type|power-button-action'
   ```

   - `uint32 300`、`true`、続いて `idle-dim true`・`power-button-action 'suspend'`・`sleep-inactive-ac-type 'suspend'`・`sleep-inactive-battery-type 'suspend'` の 4 行が出ればよい

1. 元に戻すときは、続けてログイン画面用の設定ファイルを消し、dconf を作り直して、ログイン画面から見える値が戻ったか確かめる。

   ```bash
   {
     sudo rm -f /etc/dconf/db/gdm.d/90-power
     sudo dconf update
     printf '\n\033[7m 確認 \033[0m\n'
     sudo -u gdm env DCONF_PROFILE=gdm /usr/bin/gsettings list-recursively org.gnome.settings-daemon.plugins.power | grep -E 'sleep-inactive-(ac|battery)-type|power-button-action'
   }
   ```

   - 3 行とも `'suspend'` になればよい

1. 元に戻すときは、続けてサスペンドとハイバネートの mask を外す。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
     systemctl is-enabled sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
   }
   ```

   - `Removed '/etc/systemd/system/sleep.target'.` のような行が 5 つ出て、`static` が 5 行出ればよい

1. 元に戻すときは、続けて蓋のドロップインを消し、logind に読み直させる。

   ```bash
   {
     sudo rm -f /etc/systemd/logind.conf.d/90-lid.conf
     sudo systemctl reload systemd-logind
     printf '\n\033[7m 確認 \033[0m\n'
     busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager HandleLidSwitch
   }
   ```

   - `s "suspend"` と出ればよい

---

## Wake on LAN を使う（任意）

- 電源を切った（シャットダウンした）この PC を、LAN の別の PC から起こせるようにする。有線 LAN だけ（Wi-Fi では使えない）
- **この節の手順 3 で再起動して UEFI の画面に入り、この節の手順 4 は UEFI の画面、この節の手順 7 は LAN の別の PC で行う**
- 仮想マシンでは、電源を切った VM は起こせない（VirtualBox など）

1. 変数を設定する（どちらも自動）。

   ```bash
   LAN_CON=$(nmcli -g NAME,TYPE connection show --active | awk -F: '$2 == "802-3-ethernet" { print $1; exit }')   # 有線 LAN の接続（自動）。<LAN_CON>
   LAN_IF=$(nmcli -g GENERAL.DEVICES connection show "${LAN_CON}" 2>/dev/null)   # その機器（自動）。<LAN_IF>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in LAN_CON LAN_IF; do
     printf '%-8s = %s\n' "$v" "${!v}"
   done
   ```

   - 最後に値を読み戻して確かめる
   - `LAN_CON` が空なら、有線の LAN の接続が無い（この節は使えない）
   - 新しい端末を開いたら（この節の手順 3 の再起動の後も）、この節の手順 1 を貼り直す

1. 有線の接続で、マジック パケットでの起動を有効にし、MAC アドレスを表示する。

   ```bash
   if [ -z "${LAN_CON}" ]; then echo '中断: この節の手順 1 の LAN_CON が空のまま（有線の LAN の接続が無い）' >&2; else
     sudo nmcli connection modify "${LAN_CON}" 802-3-ethernet.wake-on-lan magic
     sudo nmcli device reapply "${LAN_IF}"
     printf '\n\033[7m 確認 \033[0m\n'
     nmcli -g 802-3-ethernet.wake-on-lan connection show "${LAN_CON}"
     sudo ethtool "${LAN_IF}" | grep -i 'wake-on'
     ip -brief link show "${LAN_IF}"
   fi
   ```

   - `magic` と、`Supports Wake-on:` の文字に `g` があり、`Wake-on: g` が出ればよい
   - 最後の行の `xx:xx:xx:xx:xx:xx` が MAC アドレス。この節の手順 7 で使うので控える
   - `Supports Wake-on:` に `g` が無ければ、この LAN のアダプターは Wake on LAN を使えない
   - `Wake-on: d` のままなら、アダプターのドライバが設定を受け付けていない。この節の手順 5 で、起動の後にもう一度見る

1. 再起動して、UEFI の設定の画面に入る。

   ```bash
   sudo systemctl reboot --firmware-setup
   ```

   - 再起動して、UEFI（BIOS）の設定の画面が開く
   - **次の手順は、UEFI の設定の画面が開いてから行う**

1. UEFI の設定の画面で、Wake on LAN を有効にして保存し、AlmaLinux を起動する。

   - 項目の名前は機種による（`Wake on LAN`・`Power On By PCI-E`・`Resume by LAN` など）。「ErP」「Deep Sleep」のような待機電力を減らす設定は切る
   - 保存して終了（多くは F10）すると、AlmaLinux が起動する
   - **次の手順は、起動してログインし、端末を開いてから貼る**

1. この節の手順 1 を貼り直してから、Wake on LAN が有効なままか確かめる。

   ```bash
   sudo ethtool "${LAN_IF}" | grep -i 'wake-on'
   ```

   - `Wake-on: g` が出ればよい

1. この PC の電源を切る。

   ```bash
   sudo systemctl poweroff
   ```

   - LAN のケーブルはつないだまま、電源のコンセントも抜かない
   - **次の手順は、この PC の電源が切れてから、LAN の別の PC で行う**

1. LAN の別の PC からマジック パケットを送り、この PC が起動することを確かめる。

   - AlmaLinux など Python のある PC では、`python3 -c "import socket; m = bytes.fromhex('<MAC>'.replace(':', '').replace('-', '')); s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1); s.sendto(b'\xff' * 6 + m * 16, ('255.255.255.255', 9))"` で送れる（`<MAC>` はこの節の手順 2 の値）
   - 起動しなければ、UEFI の設定（この節の手順 4）と、LAN のアダプターのランプ（電源が切れていても点いているか）を見る

1. 元に戻すときは、マジック パケットでの起動を切る。

   ```bash
   if [ -z "${LAN_CON}" ]; then echo '中断: この節の手順 1 の LAN_CON が空のまま' >&2; else
     sudo nmcli connection modify "${LAN_CON}" 802-3-ethernet.wake-on-lan default
     sudo nmcli device reapply "${LAN_IF}"
     printf '\n\033[7m 確認 \033[0m\n'
     nmcli -g 802-3-ethernet.wake-on-lan connection show "${LAN_CON}"
   fi
   ```

   - `default` が出ればよい。UEFI の設定は、この節の手順 4 の画面で戻す

---

## Flatpak の使い方の基本

| コマンド | 用途 |
|---|---|
| `sudo flatpak update --appstream` | 検索用のアプリ一覧（appstream）を取り直す。**Flathub を登録した直後は、先にこれを 1 回実行しないと `flatpak search` が何も返さない** |
| `flatpak search <キーワード>` | Flathub のアプリを探す（ID が分かる） |
| `flatpak remote-info flathub <ID>` | 入れる前に大きさ・runtime・更新日を見る |
| `flatpak remote-ls flathub --app --arch=aarch64` | aarch64 向けに出ているアプリの一覧（Raspberry Pi で使えるか） |
| `sudo flatpak install flathub <ID>` | 入れる |
| `flatpak run <ID>` | 起動する（ふつうはデスクトップのメニューから起動する） |
| `flatpak list --app` | 入っているアプリ |
| `flatpak info --show-permissions <ID>` | アプリに与えられている権限（ファイル・デバイス・ネットワーク） |
| `sudo flatpak override <ID> --filesystem=<パス>` | 権限を足す（GUI でやるなら Flatseal） |
| `sudo flatpak override --reset <ID>` | 足した権限を元に戻す |
| `sudo flatpak uninstall <ID>` | 消す |
| `sudo flatpak uninstall --unused` | もう誰も使っていない runtime を消す |

- `flatpak` の読み取り系（`search` / `list` / `info` / `remote-ls`）は `sudo` 無しで動く
- Flathub を登録した直後に `flatpak search flatseal` が `No matches found` を返す場合は、`sudo flatpak update --appstream` で検索用のメタデータを取得してから検索し直す。`sudo flatpak update` を 1 度実行したあとも、同じように検索できるようになる

---

## Homebrew の使い方の基本

各手順書が使うコマンドはこれだけ。

| コマンド | 用途 |
|---|---|
| `brew install <formula>` | 入れる。ビルド済みのボトルがあれば `Pouring ...` と出て、ソースビルドは走らない |
| `brew uninstall <formula>` | 消す。Homebrew 7.0.7 では、不要になった依存も既定で自動削除する（[注意点](extra/almalinux-setup.md#注意点)） |
| `brew list --versions` | 入っているものと版の一覧 |
| `brew leaves` | ほかの導入済み formula や cask から依存されていない formula の一覧。明示的に入れたものの履歴ではない |
| `brew info <formula>` | 版・依存・caveat（[gdu](gdu.md) のような名前の注意書き） |
| `brew deps --tree <formula>` | 依存の木。単独で入れたときに何が付いてくるか |
| `brew outdated` | 更新できるものの一覧。何も無ければ無出力 |
| `brew autoremove` | 依存として入って、もう誰も使っていないものを消す（`--dry-run` で確認できる） |

- `brew install`・`brew upgrade` などの管理操作は、Homebrew を入れた一般ユーザーで行う。通常のホストでは root での実行を断られる（`brew --version` などの例外は[検証記録](verification/almalinux-setup.md#統合前の記録-homebrewもとは-homebrewmd)）
- `sudo brew ...` は、sudo の PATH に Homebrew が無ければ `command not found` になる。[Homebrew を sudo でも使う（任意）](#homebrew-を-sudo-でも使う任意)の節を通しても、管理操作は一般ユーザーで行う
- 入れたコマンドを root のシェルでも使うなら [Homebrew を root のシェルでも使う（任意）](#homebrew-を-root-のシェルでも使う任意)の節を、`sudo <コマンド>` で使うなら [Homebrew を sudo でも使う（任意）](#homebrew-を-sudo-でも使う任意)の節を通す
- Homebrew 7.0.7 の `brew install` は、端末で依存や依存先も導入する計画なら `[y/n]` を聞く。指定したものだけの計画、または端末を使わない実行では聞かない（[注意点](extra/almalinux-setup.md#注意点)）
- この文書の[HackGen Console NF](#hackgen-console-nf)・[git-delta](#git-delta)・[Neovim](#neovim)・[lazygit](#lazygit)・[yazi](#yazi)と、Homebrew で入れるほかの手順書（[gdu](gdu.md)、[ShellCheck / shfmt](shellcheck.md)、[Syncthing](syncthing.md)、[Dropbox（rclone）](dropbox-rclone.md)、[hadolint / dive / Trivy](image-tools.md)（Trivy だけは dnf）、[lazydocker](lazydocker.md)）は、[Homebrew](#homebrew)の手順 1〜3 を前提にする

---

## Homebrew を root のシェルでも使う（任意）

- root でも使う場合は、[bash の root 用導入手順](https://github.com/ryo-aoki-pc/bash/blob/main/docs/install.md#root-のシェルでも読む任意)で root 自身の clone と読み込み口を用意する
- 自分専用のマシンで、一般ユーザーを信用できる場合だけ行う。root のシェルから Homebrew のユーザー所有のコマンドを実行するため
- 共通設定の `brew shellenv` は Homebrew を PATH の先頭に入れる。同名の RPM コマンドより Homebrew が優先される
- `sudo <コマンド>` は別で、次の「Homebrew を sudo でも使う（任意）」の `secure_path` を使う

1. root のログインシェルから Homebrew が見えることを確かめる。

   ```bash
   sudo -i bash -c 'printenv PATH; command -v brew'
   ```

   - `/home/linuxbrew/.linuxbrew/bin/brew` が出ればよい。`/root/.bashrc` に PATH の行は追記しない
   - `brew install` などは一般ユーザーで行う

1. root の共通設定も外す場合だけ、bash のロールバックを行う。

   - [root の導入手順](https://github.com/ryo-aoki-pc/bash/blob/main/docs/install.md#root-のシェルでも読む任意)のロールバックを参照する

---

## Homebrew を sudo でも使う（任意）

- **`sudo <コマンド>` で Homebrew のコマンドを使わないなら、この節は不要**
- sudo の設定に 1 行のファイル（`/etc/sudoers.d/homebrew`）を置き、sudo がコマンドを探す PATH（`secure_path`）の末尾に、Homebrew の `bin` と `sbin` を足す
- `sudo nvim /etc/hosts` や `sudo gdu-go /` のように、`sudo <コマンド>` で使えるようになる。`sudo -s`・`sudo -i` で開いた root のシェルでも使える
- `EDITOR=nvim` の `sudoedit` も、自分の設定の Homebrew の `nvim` で開くようになる（この節の前は、黙って `vi` で開く）
- sudo を通らない `su -`、コンソールや ssh での root のログインには効かない。そちらは [Homebrew を root のシェルでも使う（任意）](#homebrew-を-root-のシェルでも使う任意)の節を通す
- RPM にも同じ名前のコマンドがあると、`sudo` では RPM のほうが使われる
- `brew install` などの管理操作は、この節を通しても一般ユーザーで行う（通常のホストでは `sudo brew install` などを `Running Homebrew as root is extremely dangerous …` で断られる）
- [Homebrew](#homebrew)の手順 1〜3 を終えた、Homebrew を入れたユーザーのシェルで貼る
- 補足: [参考資料](reference/almalinux-setup.md#homebrew-sudo-で使うときの補足)

> [!WARNING]
> - `/home/linuxbrew/.linuxbrew` は Homebrew を入れたユーザーの所有。`sudo` で打ったコマンドが `/usr/bin` などに無いと、そのユーザーが書き換えられるプログラムを root の権限で動かすことになる（そのユーザーを乗っ取られると、root まで取られる）
> - sudo の設定はホスト全体にかかる。このホストで `sudo` を使う、ほかのユーザーにも効く

1. sudo の `secure_path` の末尾に Homebrew を足すファイルを置き、`sudo` の PATH を確かめる。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     if sudo printenv PATH | grep -q /home/linuxbrew; then echo '中断: sudo の PATH に Homebrew が既にある' >&2
     elif [ "$(sudo printenv PATH)" != /sbin:/bin:/usr/sbin:/usr/bin ]; then echo '中断: sudo の PATH が AlmaLinux 10 の既定（/sbin:/bin:/usr/sbin:/usr/bin）と違う' >&2
     else
       line='Defaults secure_path = /sbin:/bin:/usr/sbin:/usr/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin'
       echo "${line}" | sudo visudo -cf - && echo "${line}" | sudo install -m 0440 /dev/stdin /etc/sudoers.d/homebrew
       sudo visudo -c
     fi
     sudo bash -c 'printenv PATH; command -v brew'
   }
   ```

   - `stdin: parsed OK`・`/etc/sudoers: parsed OK`・`/etc/sudoers.d/homebrew: parsed OK` の 3 行が出る
     - `/etc/sudoers.d` にほかのファイル（[ログインと sudo](#ログインと-sudo)の手順 3 の `nopasswd` など）があれば、その行も出る
     - 日本語のロケール（`ja_JP.UTF-8`）では、`parsed OK` は `正しく構文解析されました` と出る
   - 最後の 2 行で、PATH の末尾が `:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin` で、`/home/linuxbrew/.linuxbrew/bin/brew` が出ればよい
   - `中断:` と出たら、何も書き換えていない（最後の 2 行は出る）
     - `既にある` なら、この節は通してある。最後の 2 行で確かめる
     - `既定と違う` なら、`secure_path` がほかで変えてある（`sudo grep -rn secure_path /etc/sudoers /etc/sudoers.d` で探す）。そのホストでは、この節は使わない
   - 開いたままの root のシェル（`sudo -s` など）には効かない。開き直す

1. 元に戻すときは、この節の手順 1 で置いたファイルを消す。

   ```bash
   {
     sudo rm -f /etc/sudoers.d/homebrew
     printf '\n\033[7m 確認 \033[0m\n'
     sudo printenv PATH   # /sbin:/bin:/usr/sbin:/usr/bin
   }
   ```

   - 最後に `/sbin:/bin:/usr/sbin:/usr/bin` と出ればよい
   - 開いたままの root のシェル（`sudo -s` など）の PATH には残る。開き直すと消える

---

## starship のプリセットを当てる（任意）

- 公式が配っている設定一式を `~/.config/starship.toml` に書き出す
- **この節の手順 2 で、既存の設定は上書きされる**。自分で書いたものがあれば、先に退避する
- [シェルのツール](#シェルのツール)の手順 2 で開き直した端末（starship を読み込んだ端末）で貼る

1. 当てられるプリセットの一覧を見る。

   ```bash
   starship preset --list
   ```

   - `plain-text-symbols` と `no-nerd-font` は**Nerd Font が無い端末向け**で、記号を ASCII に置き換える
   - `nerd-font-symbols` / `pastel-powerline` / `gruvbox-rainbow` などは Nerd Font が要る（[HackGen Console NF](#hackgen-console-nf) など）
   - **次の手順は、使うプリセットを決めてから貼る**

1. 選んだプリセットを `~/.config/starship.toml` に書き出す（`STARSHIP_PRESET` は、この節の手順 1 で選んだ名前にする）。

   ```bash
   STARSHIP_PRESET=plain-text-symbols   # 当てるプリセット（この節の手順 1 の一覧から）。<STARSHIP_PRESET>
   ```

   ```bash
   if [ -z "${STARSHIP_PRESET}" ]; then echo '中断: STARSHIP_PRESET が空のまま。値を入れて貼り直す' >&2; else
     mkdir -p ~/.config
     starship preset "${STARSHIP_PRESET}" -o ~/.config/starship.toml --force &&
       wc -l ~/.config/starship.toml &&
       starship prompt
   fi
   ```

   - 設定ファイルの変更だけなら `~/.bashrc` を読み直す必要はない。次のプロンプトから変わる

---

## starship の設定ファイル

- `~/.config/starship.toml` は**既定では存在しない**（無ければ組み込みの既定値で動く）

1. `~/.config/starship.toml` に、設定を手で書く。

   ```bash
   mkdir -p ~/.config
   cat > ~/.config/starship.toml <<'EOF'
   add_newline = false

   [directory]
   truncation_length = 3
   truncate_to_repo = false
   EOF
   starship prompt
   ```

   - `~/.config/starship.toml` が既にあれば、まるごと置き換える（[starship のプリセットを当てる（任意）](#starship-のプリセットを当てる任意)の設定も消える）

---

## starship でユーザー名とホスト名を常に表示する（任意）

- ユーザーを切り替えても名前を出す（starship の既定は、SSH のときと、ログインしたユーザーと違うときだけ出す）
- 自分のユーザーのシェルで実行する。root の設定は別のファイルになる
- プリセットや[starship の設定ファイル](#starship-の設定ファイル)の例を使う場合は、先に適用する

1. ユーザー名とホスト名を常に表示する設定を入れる。

   ```bash
   mkdir -p ~/.config
   starship config username.show_always true
   starship config hostname.ssh_only false
   printf '\n\033[7m 確認 \033[0m\n'
   starship module username
   starship module hostname
   ```

   - ユーザー名とホスト名が出ることを確かめる
   - 次のプロンプトから反映される。端末の開き直しや `~/.bashrc` の読み直しは不要
   - 設定後にプリセットや設定ファイルを上書きした場合は、この節の手順をもう一度実行する

---

## fzf の使い方の基本

- 全部のキーと変数は `man fzf`（Homebrew のものが読める）と [README](https://github.com/junegunn/fzf#readme)

| シェルのキー | すること | 動きを変える変数 |
|---|---|---|
| Ctrl+R | 履歴を曖昧検索で選び、プロンプトに入れる（実行はしない） | `FZF_CTRL_R_OPTS` |
| Ctrl+T | 今のディレクトリの下のファイル・ディレクトリを選び、カーソルの位置に入れる（Tab で複数） | `FZF_CTRL_T_COMMAND`・`FZF_CTRL_T_OPTS` |
| Alt+C | 今のディレクトリの下のディレクトリを選んで `cd` する | `FZF_ALT_C_COMMAND`・`FZF_ALT_C_OPTS` |
| `<コマンド> **` + Tab | パス（`cd` などはディレクトリ、`ssh` はホスト、`export` は変数）を選んで入れる | `FZF_COMPLETION_TRIGGER`（既定 `**`）・`FZF_COMPLETION_OPTS` |

| fzf の画面のキー | すること |
|---|---|
| 文字 | 打つたびに絞り込む |
| ↑ / ↓、Ctrl+K / Ctrl+J、Ctrl+P / Ctrl+N | 候補を上下に動く |
| Enter | 選んで閉じる |
| Esc、Ctrl+C、Ctrl+G | 選ばずに閉じる |
| Tab / Shift+Tab | 複数を選ぶ・外す（Ctrl+T と `**<Tab>` のパスのとき） |
| Ctrl+R（履歴の中で） | 並びを「新しい順」と「一致の良い順」で切り替える（右上の `+S`） |

| 検索の書き方 | 意味 | 例（`apple banana cherry grape pineapple apple-pie` から） |
|---|---|---|
| `ap` | 文字が順に含まれる（曖昧一致） | `apple` `apple-pie` `grape` `pineapple` |
| `'ap` | その文字列をそのまま含む（完全一致） | 同上（`'apple` なら `apple` `apple-pie` `pineapple`） |
| `^ap` | その文字列で始まる | `apple` `apple-pie` |
| `le$` | その文字列で終わる | `apple` `pineapple` |
| `!ap` | 含まない | `banana` `cherry` |
| `ap le`（空白） | 両方に一致（AND） | `apple` `apple-pie` `pineapple` |
| `ap \| ch` | どちらかに一致（OR） | `apple` `cherry` `apple-pie` `grape` `pineapple` |

- 共通の見た目や動き（`--height`・`--layout`・`--border` など）は `FZF_DEFAULT_OPTS` に書く。本書では変えていない

---

## fzf で fd と bat を候補とプレビューに使う（任意）

- Ctrl+T と Alt+C の候補を、fd の一覧に変える（`.git` の中を除き、隠しファイルは含める。`.gitignore` の対象は fd が既定で除く）
- 共通の bash 設定が、fd があるときに候補の `FZF_*` の 3 つの変数を入れる。Ctrl+T の右側の bat のプレビュー（`FZF_CTRL_T_OPTS`）は、bat があれば入るので、[シェルのツール](#シェルのツール)の手順 1 の後から出ている。`~/.bashrc` への追記は要らない
- `**<Tab>` の候補は変わらない（`find` のまま）
- bat は[シェルのツール](#シェルのツール)の手順 1、fd は[Neovim](#neovim)の手順 3（自分用の Neovim の設定の導入）と[yazi](#yazi)の手順 2 で入れてある。fd が入っていれば、この節の手順 1・2 は飛ばす
- 戻すときは、この節の手順 5

1. brew で fd を入れる。

   ```bash
   brew install fd
   ```

   - 確認が出たら `y`（Enter は要らない）
   - EPEL の `fd-find` と二重に入れない
   - **次の手順は、プロンプトに戻ってから行う**

1. 開いている端末を閉じて、開き直す。

   - **次の手順は、開き直した端末で貼る**

1. fd と bat があり、変数が入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   command -v fd bat
   printf '%s\n' "${FZF_DEFAULT_COMMAND-}" "${FZF_CTRL_T_COMMAND-}" "${FZF_ALT_C_COMMAND-}" "${FZF_CTRL_T_OPTS-}"
   ```

   - 2 つのパスと、`fd` を使う候補の 3 変数・`bat` を使うプレビューの変数が出ればよい

1. `cat ` と打ってから Ctrl+T を押し、候補が fd の一覧になったことを確かめる。

   - `.git` の中のファイルと、`.gitignore` に書かれたファイルは一覧に出ない
   - 一覧の右側に、選んでいるファイルの中身が行番号と色付きで出る。Esc で閉じる

1. 元に戻すときは、fd を消す。

   ```bash
   brew uninstall fd
   ```

   - `Uninstalling /home/linuxbrew/.linuxbrew/Cellar/fd/…` と出ればよい
   - [Neovim](#neovim)の手順 3 か[yazi](#yazi)の手順 2 で fd を入れてあれば、消さない（自分用の Neovim の設定のファイルピッカーと yazi も使う）

---

## eza の表示を調整する

設定ファイルは無く、すべてコマンドラインオプションと環境変数で決める。よく使うもの:

| やりたいこと | オプション |
|---|---|
| 列の見出しを出す | `--header`（`-h`） |
| 時刻の書式を変える | `--time-style=long-iso` / `iso` / `relative` / `+%Y-%m-%d` |
| 8 進数のパーミッション | `--octal-permissions`（`-o`） |
| アイコンを出す | `--icons=always`（**Nerd Font が要る**） |
| ディレクトリを先に並べる | `--group-directories-first` |
| `.gitignore` のファイルを隠す | `--git-ignore` |
| git 連携を切る | `--no-git` |

- 色は `LS_COLORS` と `EZA_COLORS` を見る
- 全オプションは `eza --help`（86 行）と `man eza`

---

## bat の設定ファイル

- パッケージは設定ファイルを置かない。無ければ組み込みの既定値で動く
- 置き場所は `~/.config/bat/config`（`bat --config-file` で確認できる）
  - 既定の場所に置く限り bat は自分で見つける。別の場所に置きたいときだけ `BAT_CONFIG_PATH` を `~/.bashrc` に `export` する

1. よく変える 3 つだけを書いた、最小の設定ファイルを置く。

   ```bash
   BAT_THEME_NAME=ansi   # 使うテーマ。ansi は端末の 16 色にそのまま従う（一覧は bat --list-themes）。<BAT_THEME_NAME>
   ```

   ```bash
   if [ -z "${BAT_THEME_NAME}" ]; then echo '中断: BAT_THEME_NAME が空のまま。値を入れて貼り直す' >&2; else
     mkdir -p ~/.config/bat
     cat > ~/.config/bat/config <<EOF
   --theme="${BAT_THEME_NAME}"
   --style="numbers,changes,header"
   --paging=never
   EOF
     printf '\n\033[7m 確認 \033[0m\n'
     cat ~/.config/bat/config
     bat --config-file
   fi
   ```

   - 書いた 3 行と、`/home/<USER>/.config/bat/config` が出ればよい
   - `中断:` と出たら、何も書いていない

---

## tmux の使い方の基本

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

## tmux の設定ファイル（任意）

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
     printf '\n\033[7m 確認 \033[0m\n'
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
     printf '\n\033[7m 確認 \033[0m\n'
     tmux show -g mouse
     tmux show -g history-limit
     tmux kill-session -t "${TMUX_CHECK_ID}"
   else
     echo '中断: 確認用のセッションを作れなかった。既存セッションは終了しない' >&2
   fi
   ```

   - `mouse on` と `history-limit 50000` が出る

---

## Claude Code を tmux の中で動かす（任意）

- SSH でログインしたシェルから、tmux の中で Claude Code を動かすと、SSH を切っても Claude Code が動き続ける
- Remote Control（`claude remote-control`）で始めると、SSH を切った後も、スマートフォンの Claude のアプリや claude.ai/code のブラウザから続けて使える
- 前提: [Claude Code](#claude-code)で入れ、`claude` で claude.ai のアカウント（Pro / Max / Team / Enterprise）にログインしてあること。API キーでは Remote Control を使えない（公式ドキュメント）
- **この節の手順 4 には対話入力がある**（ディレクトリの信頼と、初回の Remote Control の確認）
- Windows の PC は [Claude Code の Remote Control（Windows）](windows-claude-remote-control.md)（Windows には tmux が無いので、タスク スケジューラと WezTerm を使う）
- Remote Control でなく、対話の `claude` を動かし続けるときは、この節の手順 4 で `claude` だけを打つ。別の SSH から `tmux attach -t claude` で戻れる

1. Claude Code と tmux が使えることと、ログインを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   claude --version
   tmux -V
   claude auth status --text
   ```

   - `claude` の版、`tmux 3.7c`、`Login method: …` の行が出ればよい
   - `Not logged in. Run claude auth login to authenticate.` なら、[Claude Code](#claude-code)の手順 5 でログインしてから続ける
   - `claude doctor` の `Remote Control` の段にも、使えないときは理由が出る（ログインしていないと `Not signed in to claude.ai` など）

1. Claude Code を動かすディレクトリに移る。

   - `cd <PROJECT_DIR>` で、Remote Control で作業させたいディレクトリ（プロジェクト）に移る
   - ホームそのものは選ばない

1. tmux のセッションを作って入る。

   ```bash
   tmux new-session -A -s claude
   ```

   - 左下に `[claude]` が出る。新規セッションのシェルは、この節の手順 2 のディレクトリから始まる
   - 同じ名前のセッションがあれば、そこで動いていたコマンドと作業場所のまま戻る（`-A`）。Claude Code がすでに動いているなら、この節の手順 4 は飛ばしてその画面を使う
   - シェルに戻っている場合は、中で `pwd` を確かめ、必要なら `cd <PROJECT_DIR>` で作業場所へ移る。ほかのコマンドが動いていれば、そこへこの節の手順 4 を貼らない
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
   printf '\n\033[7m 確認 \033[0m\n'
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

## 改行を変換して clone したリポジトリを直す

- 改行を変換する設定（`core.autocrlf=true`）のときに clone したリポジトリは、作業ツリーのファイルが CRLF のまま残る
- [Git](#git)の手順 4 の後は、それらが変更ありと出る。編集してコミットすると、CRLF で入る
- Windows で、Git for Windows の既定の設定のまま clone したリポジトリが当たる
- リポジトリごとに、そのリポジトリのトップのディレクトリで、この節の手順 1 から貼る
- **この節の手順 3 は、作業ツリーの追跡しているファイルをすべて書き直し、未コミットの変更を消す**。この節の手順 1 で変更が出たら、手順 2 で退避してから貼る

1. 直すリポジトリのトップで、未コミットの変更と、CRLF で書かれたファイルの数を見る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   git -c core.autocrlf=true status --short
   git ls-files --eol | grep -c 'i/lf *w/crlf'
   ```

   - 2 つ目の数が、直すファイルの数。`0` なら、この節は要らない
   - 1 つ目が何も出ないか、`??`（未追跡）の行だけなら、追跡しているファイルの変更は無い。この節の手順 2 と 4 は飛ばす
   - `??` 以外の行があれば、この節の手順 2 で追跡しているファイルの変更を退避する。未追跡ファイルはそのまま残す

1. この節の手順 1 で `??` 以外の変更が出たときだけ、前の設定のまま stash する。

   ```bash
   git -c core.autocrlf=true stash
   ```

   - `Saved working directory and index state WIP on …` と出る
   - `No local changes to save` なら、この節の手順 4 は飛ばす。エラーなら、ここで止めて原因を直す

1. 作業ツリーのファイルを、今の設定で書き直す。

   ```bash
   git rm -r -q --cached .
   git reset -q --hard
   printf '\n\033[7m 確認 \033[0m\n'
   git ls-files --eol | grep -c 'i/lf *w/crlf'
   git status --short
   ```

   - 数は `0` になる
   - `git status --short` は、もともとあった `??` の行以外は出さない

1. この節の手順 2 で保存成功の表示が出たときだけ、今回の変更を戻す。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   git stash pop
   git ls-files --eol
   ```

   - `git status` の形で、元の変更だけが出る
   - 戻したファイルも `w/lf` になる
   - この節の手順 2 からここまでは、別の stash を作らない

---

## WezTerm の設定ファイル

- パッケージ（Windows 11 ではインストーラ）は設定ファイルを置かない。無ければ組み込みの既定値で動く
- [WezTerm](#wezterm)の手順 5 で入れた自分用の設定は、`~/.config/wezterm/wezterm.lua`（下の表の 5）

| 優先 | 場所 | 用途 |
|---|---|---|
| 1 | `wezterm --config-file <path>` | 一時的に別の設定で起動する |
| 2 | 環境変数 `WEZTERM_CONFIG_FILE` | 同上（環境ごとに切り替える） |
| 3 | `~/.wezterm.lua` | **1 ファイルで済む設定はここ**（公式の推奨） |
| 4 | `${XDG_CONFIG_HOME}/wezterm/wezterm.lua`（`XDG_CONFIG_HOME` を設定している場合のみ） | 複数ファイルに分ける設定 |
| 5 | `~/.config/wezterm/wezterm.lua`（`XDG_CONFIG_HOME` 未設定のとき） | 同上 |

- **Windows 11 では**、`~` は `%USERPROFILE%`（`C:\Users\<WIN_USER>`）。置くのは `%USERPROFILE%\.wezterm.lua` か `%USERPROFILE%\.config\wezterm\wezterm.lua`
  - 表の 2 と 3 の間に、`wezterm.exe` と同じフォルダーの `wezterm.lua`（`C:\Program Files\WezTerm\wezterm.lua`）が入る。USB メモリで持ち運ぶとき用で、公式は勧めていない
- **自分用の設定**は [ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm) にある（Tokyo Night 系の配色・ピル型タブ・ステータスバー・シェル統合の設定）
  - 入れ方は、その [docs/install.md](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md)（本書と同じ書式の手順書。[WezTerm](#wezterm)の手順 5）。`~/.config/wezterm` に clone する。シェル統合は bash の共通設定が読むので、参照先の手順 5〜7（直接追記）は行わず、手順 8 で端末を開き直す
  - Windows 11 では、同じブロックを Git for Windows の Git Bash に貼る（[Windows 11 の初期設定の「Git Bash と WezTerm の設定」](windows-setup.md#git-bash-と-wezterm-の設定)）
  - どこを変えればよいかは [README の「カスタマイズの勘所」](https://github.com/ryo-aoki-pc/wezterm#カスタマイズの勘所)
  - nightly が前提（stable では未知のオプションで設定エラーになる）。本書で入れるのは、AlmaLinux 10 も Windows 11 も nightly
  - フォントは HackGen Console NF（[HackGen Console NF](#hackgen-console-nf)。Windows 11 は[Windows 11 の初期設定の「HackGen Console NF」](windows-setup.md#hackgen-console-nf)）
  - AlmaLinux 10 だけ: 本書の RPM が置く `/etc/profile.d/wezterm.sh`（公式の Bash 統合）と、この設定のシェル統合は一緒に動く（公式の統合の cwd・ユーザー変数・bash-preexec を保ったまま、この設定がプロンプトの区切りと完了通知を補う。[docs/install.md の手順 9 と注意点](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md#注意点)）
  - Windows 11 のインストーラはシェル統合を入れない。設定が無いときに開くシェルは `cmd.exe`（`%COMSPEC%`）で、この設定は Git Bash を既定にし、Git Bash と PowerShell のシェル統合を設定の中から読ませる（[README の「シェル統合」](https://github.com/ryo-aoki-pc/wezterm#シェル統合)）
  - `~/.wezterm.lua` があると、clone した設定は読まれない

---

## git-delta の設定ファイル

設定の実体は `~/.gitconfig` の `[delta]` セクション（Windows 11 では `C:\Users\<WIN_USER>\.gitconfig`。Git Bash・PowerShell・cmd の git が同じファイルを読む）。[git-delta](#git-delta)の手順 3 で書いた 3 つのほかによく使うもの:

| キー | 意味 |
|---|---|
| `features` | 名前付き設定のまとめ読み（`[delta "<名前>"]` を作って指定する） |
| `syntax-theme` | シンタックスハイライトの配色。一覧は `delta --list-syntax-themes` |
| `hyperlinks` | ファイル名を端末のハイパーリンクにする |
| `true-color` | 24 bit 色を使うか（既定は端末から自動判定） |
| `file-style` / `minus-style` / `plus-style` | ファイル名行・削除行・追加行の色 |

- 今の実効値は `delta --show-config` で全部出る
- `delta --help` にはオプションとして同じ名前が並んでおり、コマンドラインで一時的に上書きできる

---

## Neovim の設定ファイル

- パッケージは設定ファイルを置かない。無ければ組み込みの既定値（素の Vim に近い挙動）で動く
- 置き場所は `~/.config/nvim` で、読み込まれるのは `init.lua` か `init.vim` のどちらか一方
  - `XDG_CONFIG_HOME` を設定していれば `$XDG_CONFIG_HOME/nvim` になる。別の場所を使うなら `XDG_CONFIG_HOME` か `NVIM_APPNAME` を設定する
- Windows 11 の置き場所は `%LOCALAPPDATA%\nvim`（`init.lua`）。プラグイン・undo・ログは `%LOCALAPPDATA%\nvim-data`、キャッシュは `%TEMP%\nvim-data`（設定とデータの場所は、[Windows 11 の初期設定の「Neovim」](windows-setup.md#neovim)の手順 4 で確かめる）
  - Windows 11 では `XDG_CONFIG_HOME` を設定しない（yazi は読まず、WezTerm は `~/.config/wezterm` を読まなくなり、git は `~/.gitconfig` を読み続けるので、ツールごとに読む場所が割れる。[参考資料](reference/windows-setup.md#neovim-windows-11-では-選択した方針)）
- **自分用の設定**は [ryo-aoki-pc/LazyVimStarter](https://github.com/ryo-aoki-pc/LazyVimStarter) にある（LazyVim をベースに、日本語の入力・検索と Markdown（GLFM）の執筆を強くした設定）
  - 入れ方は [Neovim](#neovim)の手順 3 で通す [docs/setup.md の「AlmaLinux 10 に導入する」](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#almalinux-10-に導入する-1-度だけ)。外部コマンド・日本語入力（ibus-anthy）・フォントも入れる
  - Windows 11 の入れ方は [docs/setup.md の「Windows 11 に導入する」](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#windows-11-に導入する-1-度だけ)。既存の `%LOCALAPPDATA%\nvim` と `nvim-data` を `.bak` に退避してから clone し、Neovim・外部コマンド・lazygit も scoop で入れる
  - Windows 11 は、[Windows 11 の初期設定の「Neovim」](windows-setup.md#neovim)の手順 3 で通す
  - 何ができるか・どこを変えたかは [README の「主なカスタマイズ」](https://github.com/ryo-aoki-pc/LazyVimStarter#主なカスタマイズ)
- インターネットに出られないホストで、Mason が npm で入れるパッケージ（LSP サーバー・リンター）を入れるなら、[npm-offline.md](npm-offline.md) を通す

---

## lazygit の設定ファイル

- パッケージは設定ファイルを置かない。無ければ組み込みの既定値で動く
- 置き場所は `~/.config/lazygit/config.yml`（`lazygit --print-config-dir` で確認できる）
- Windows 11 の置き場所は `%LOCALAPPDATA%\lazygit\config.yml`（`%APPDATA%\lazygit\config.yml` があれば、そちらも見つける）。状態ファイル `state.yml` も同じフォルダーに入る（[Windows 11 の初期設定の「lazygit」](windows-setup.md#lazygit)の手順 5 で確かめる）
- **自分用の設定**は [ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit) にある（公式の既定の全項目に、あいまい検索・Nerd Fonts のアイコン・マウス無効などの変更を載せた `config.yml`）
  - 入れ方は [README の「導入方法」](https://github.com/ryo-aoki-pc/lazygit#導入方法)（[lazygit](#lazygit)の手順 2）。clone した `config.yml` を `~/.config/lazygit/config.yml` にリンクする
  - Windows 11 の入れ方は、同じ [README の「導入方法」](https://github.com/ryo-aoki-pc/lazygit#導入方法)の Windows の例（[Windows 11 の初期設定の「lazygit」](windows-setup.md#lazygit)の手順 4）（シンボリックリンクではなく、`%LOCALAPPDATA%\lazygit` に直接 clone する。元に戻すブロックもそこにある）
  - 何を変えたかは [設定のリポジトリの参考資料の「主な設定内容」](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/reference/readme.md#主な設定内容)
  - アイコンに Nerd Fonts が要る（`gui.nerdFontsVersion: "3"`）。端末のフォントを HackGen Console NF（[HackGen Console NF](#hackgen-console-nf)）にする
    - Windows 11 で入れるのは [Windows 11 の初期設定の「HackGen Console NF」](windows-setup.md#hackgen-console-nf)。Windows Terminal のフォントにするのは [Windows 11 の初期設定の任意節](windows-setup.md#windows-terminal-のフォントと貼り付けの警告を変える任意)で、WezTerm は自分用の設定で変わる
  - 差分の表示に delta を使う（[git-delta](#git-delta)。Windows 11 は [Windows 11 の初期設定の「git-delta」](windows-setup.md#git-delta)）。Windows の設定例の引用符は [README の「Windows で使う場合」](https://github.com/ryo-aoki-pc/lazygit#windows-で使う場合)
  - `e` キーで開くエディタは、`EDITOR` などから自動で決まる（[Neovim](#neovim)の手順 4）
    - Windows 11 で Windows PowerShell から起動するなら、[Windows 11 の初期設定の「Neovim を既定のエディタにする（任意）」](windows-setup.md#neovim-を既定のエディタにする任意)で、ユーザーの環境変数 `EDITOR` を `nvim` にする

---

## yazi の設定ファイル

- パッケージは設定ファイルを置かない。無ければ組み込みの既定値で動く
- 置き場所は `~/.config/yazi/` で、ファイル名は `yazi.toml`（全般）/ `keymap.toml`（キー割り当て）/ `theme.toml`（配色）
- Windows 11 の置き場所は `%APPDATA%\yazi\config\`（Windows の yazi は `XDG_CONFIG_HOME` を見ない。別の場所にするなら `YAZI_CONFIG_HOME` に絶対パスを入れる）
  - 状態は `%APPDATA%\yazi\state`、キャッシュは `%LOCALAPPDATA%\yazi`
  - yazi が読む場所は `ya env` の `Config` の行で確かめられる（[Windows 11 の初期設定の「yazi」](windows-setup.md#yazi)の手順 6）
- **既定値のファイルは配布物に入っていない**。変更する項目だけを設定ファイルに書く
- 既定値は[公式ドキュメントの Configuration](https://yazi-rs.github.io/docs/configuration/overview/) か、リポジトリの `yazi-config/preset/` を見る
- **自分用の設定**は [ryo-aoki-pc/yazi](https://github.com/ryo-aoki-pc/yazi) にある（上流の既定の設定を丸ごと置き、3 ペインの比率・行表示・独自のキー割り当てなどを変えた設定）
  - 入れ方は [README の「インストール」](https://github.com/ryo-aoki-pc/yazi#インストール)（[yazi](#yazi)の手順 3）。`custom` ブランチを `~/.config/yazi` に clone する
  - Windows 11 の入れ方は、同じ [README の「インストール」](https://github.com/ryo-aoki-pc/yazi#インストール)の Windows の例（`custom` ブランチを `%APPDATA%\yazi\config` に clone する。[Windows 11 の初期設定の「yazi」](windows-setup.md#yazi)の手順 5）。そこにある `YAZI_FILE_ONE` と VC++ のランタイムは、同じ項の手順 2・4 で済んでいる
  - 足したキーは [設定のリポジトリの参考資料の「独自キーバインド」](https://github.com/ryo-aoki-pc/yazi/blob/custom/docs/reference/readme.md#独自キーバインド抜粋)、使う外部コマンドは [README の「依存コマンド」](https://github.com/ryo-aoki-pc/yazi#依存コマンド)
  - 外部コマンドのうち fd・ripgrep・fzf は[yazi](#yazi)の手順 2 の `YAZI_EXTRAS` で入る（Windows 11 は[Windows 11 の初期設定の「yazi」](windows-setup.md#yazi)の手順 3。fzf の bash のキー操作は[共通の bash 設定](#共通の-bash-設定)から[シェルのツール](#シェルのツール)の手順 5 までの手順で入る）。エディタの nvim は[Neovim](#neovim)、zoxide は[シェルのツール](#シェルのツール)の手順 1 で入れる
    - Windows 11 の Git Bash の fzf のキー操作と zoxide は、[Windows 11 の初期設定の「シェルのツールを入れる」](windows-setup.md#シェルのツールを入れる)で入る（zoxide は 0.9.9 に止める）
  - Windows 11 では、`O`（対話的に開く）の候補に Neovide も出る。選んで使うなら、Neovide（scoop の extras の `neovide`）を入れておく

---

## Claude Code の使い方の基本

- 全部のオプションとサブコマンドは `claude --help`（サブコマンドの中は `claude mcp --help` など）。`--max-turns` のように `--help` に出ないものもある
- SSH を切っても動かし続けるには、tmux の中で起動する（[Claude Code を tmux の中で動かす（任意）](#claude-code-を-tmux-の中で動かす任意)）。Windows 11 は [windows-claude-remote-control.md](windows-claude-remote-control.md)（タスク スケジューラと WezTerm）

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

- [Windows 11 の初期設定の「Claude Code」](windows-setup.md#claude-code)で入れた `claude` にも、同じコマンドを Windows PowerShell で打つ

**セッションの中の操作**（公式ドキュメントの [Interactive mode](https://code.claude.com/docs/en/interactive-mode) と [Commands](https://code.claude.com/docs/en/commands) から）

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
- **Windows PowerShell 5.1 からパイプで渡すと、ASCII でない文字は化けるはず**: native のコマンドへのパイプは `$OutputEncoding`（5.1 の既定は ASCII）で送られる（[about_Preference_Variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-5.1)）。日本語の指示は引数で渡す

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
| `claude update` | dnf で入れた版では更新しない（`Claude is managed by a package manager.`）。[更新](#更新)の `sudo dnf upgrade claude-code` を使う。native installer の版（Windows 11）は、すぐに更新する（[Windows 11 の初期設定の更新](windows-setup.md#更新)） |
| `claude remote-control --name <名前> --spawn same-dir` | Remote Control のサーバーを始める（[Claude Code を tmux の中で動かす（任意）](#claude-code-を-tmux-の中で動かす任意)。Windows は [windows-claude-remote-control.md](windows-claude-remote-control.md)） |

- `local` と `user` の MCP サーバーは `~/.claude.json`（Windows では `%USERPROFILE%\.claude.json`）に書かれる（`local` はディレクトリごとの欄）
- **`claude auth status` は、端末に残った後ろの行を読んで捨てる**: ブラケットペースト無しで、ほかのコマンドと続けて貼るときは最後に置く（`claude --version` と `claude doctor` では捨てなかった）

---

## Claude Code を stable チャンネルに切り替える（任意）

- `latest` で不具合に当たったときに、1 週間ほど遅れて大きな不具合のある版を飛ばす `stable` へ移る
- `stable` の版は `latest` より古いので、`dnf upgrade` では下がらない（`Nothing to do.`）。この節の手順 2 の `distro-sync` で下げる
- repo ファイルの `baseurl` の末尾を書き換えるだけで、`dnf clean` は要らない
- [Claude Code](#claude-code)の手順 1 で `stable` を選んで入れた後に `latest` へ移るときは、この節の手順 4 だけを行う
- この節は AlmaLinux 10 の dnf のもの。Windows 11 でチャンネルを変えるときは、[Windows 11 の初期設定の「Claude Code」](windows-setup.md#claude-code)の手順 1 の補足

1. repo ファイルの `baseurl` を `stable` に書き換える。

   ```bash
   {
     sudo sed -i 's|/rpm/latest$|/rpm/stable|' /etc/yum.repos.d/claude-code.repo
     printf '\n\033[7m 確認 \033[0m\n'
     grep '^baseurl=' /etc/yum.repos.d/claude-code.repo
   }
   ```

   - `baseurl` の末尾が `stable` になっていることを確認する

1. 入っている版を `stable` の最新に合わせる。

   ```bash
   sudo dnf distro-sync claude-code
   ```

   - `stable` がすでに同じ版まで追いついていれば `Nothing to do.` で終わる
   - **次の手順は、答えてから貼る**（続けて貼ると答えとして食われる）

1. 入っている版を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}' claude-code
   dnf -q repoquery --available --latest-limit 1 --qf '%{name} %{version}-%{release} %{reponame}' claude-code
   claude --version
   ```

   - 1 行目と 2 行目が同じ版なら、`stable` の最新版に揃っている

1. 元に戻すときは、`baseurl` を `latest` に戻して最新版へ上げる。

   ```bash
   {
     sudo sed -i 's|/rpm/stable$|/rpm/latest|' /etc/yum.repos.d/claude-code.repo
     printf '\n\033[7m 確認 \033[0m\n'
     grep '^baseurl=' /etc/yum.repos.d/claude-code.repo
     sudo dnf upgrade claude-code
   }
   ```

   - `baseurl` の末尾が `latest` に戻ったことを確認する
   - トランザクション表が `Upgrading:` になっていることを確かめて `y` と答える
   - 答えた後、[Claude Code](#claude-code)の手順 4 のコマンドで版を確かめる

---

## Codex CLI をブラウザの無いホストでログインする

- [Codex CLI](#codex-cli)の手順 5・6（`codex login`）の代わりに行う。ここにある 2 つのコマンドは bash と PowerShell で共通なので、Windows ではそのまま PowerShell に貼る

1. 手元のブラウザで、デバイスコードによるログインを有効にする。

   - 個人アカウントは ChatGPT のセキュリティ設定、管理されたワークスペースは管理者の権限設定で許可する

1. Codex を入れたホストでデバイスコード認証を始める。

   ```bash
   codex login --device-auth
   ```

   - 端末に URL とワンタイムコードが出る

1. 手元のブラウザで表示された URL を開き、コードを入力する。

   - 自分で始めたログインのコードだけを入力する
   - **次の手順は、Codex を入れたホストでログインの成功を確認してから貼る**

1. Codex を入れたホストでログイン状態を確かめる。

   ```bash
   codex login status
   ```

   - 成功したら、[Codex CLI](#codex-cli)の手順 8 へ進む（Windows 11 は、[Windows 11 の初期設定の「Codex CLI」](windows-setup.md#codex-cli)の手順 8）

---

## Codex CLI の設定ファイル

| 用途 | AlmaLinux 10 | Windows 11 |
|---|---|---|
| ユーザー設定 | `~/.codex/config.toml` | `%USERPROFILE%\.codex\config.toml` |
| standalone の配布物 | `~/.codex/packages/standalone/` | `%USERPROFILE%\.codex\packages\standalone\` |
| ファイル保存の場合の認証情報 | `~/.codex/auth.json` | `%USERPROFILE%\.codex\auth.json` |

- 認証情報は OS の資格情報ストアに保存される場合もある。`auth.json` が無いだけで未ログインとは判断しない
- `auth.json` はパスワードと同じ扱いにし、Git・共有フォルダー・チャットへ載せない
- 初回導入のために `config.toml` を作る必要は無い

---

## Grok Build をブラウザの無いホストでログインする

- [Grok Build](#grok-build)の手順 4・5（`grok login`）の代わりに行う。ここにある 2 つのコマンドは bash と PowerShell で共通なので、Windows ではそのまま PowerShell に貼る

1. Grok を入れたホストで、デバイスコードでのログインを始める。

   ```bash
   grok login --device-auth
   ```

   - 端末に URL（`https://accounts.x.ai/oauth2/device?user_code=…`）と確認用のコードが出て、`Waiting for authorization...` のまま待つ

1. 手元のブラウザで表示された URL を開き、コードを確かめて承認する。

   - 自分で始めたログインのコードだけを承認する
   - **次の手順は、Grok を入れたホストでログインの成功を確かめてから貼る**

1. Grok を入れたホストでログインを確かめる。

   ```bash
   grok models
   ```

   - `You are not authenticated.` が出なければ、[Grok Build](#grok-build)の手順 7 へ進む（Windows 11 は、[Windows 11 の初期設定の「Grok Build」](windows-setup.md#grok-build)の手順 8）

---

## Grok Build の設定ファイル

| 用途 | AlmaLinux 10 | Windows 11 |
|---|---|---|
| ユーザー設定 | `~/.grok/config.toml` | `%USERPROFILE%\.grok\config.toml` |
| 実行ファイル | `~/.grok/bin/grok`（`~/.grok/downloads/` の配布物へのリンク） | `%USERPROFILE%\.grok\bin\grok.exe` |
| ログイン情報 | `~/.grok/auth.json` | `%USERPROFILE%\.grok\auth.json` |
| 会話の記録 | `~/.grok/sessions/` | `%USERPROFILE%\.grok\sessions\` |
| 信頼したフォルダー | `~/.grok/trusted_folders.toml` | `%USERPROFILE%\.grok\trusted_folders.toml` |
| プロジェクトの設定 | `<プロジェクト>/.grok/config.toml`（MCP サーバー・プラグイン・許可の規則） | 同じ |

- `auth.json` はパスワードと同じ扱いにし、Git・共有フォルダー・チャットへ載せない
- そのディレクトリで読まれる設定・指示書（AGENTS.md など）・MCP サーバーは、`grok inspect` で見られる（ログインしていなくても動く）
- 初回の導入のために `config.toml` を書く必要は無い（インストーラーが `[cli]` の 2 行を書く）
- 自動の更新を止めるときは、`config.toml` の `[cli]` の下に `auto_update = false` の行を足す。止めたら、[更新](#更新)の手順 8 で上げる

---

## 更新

- OS（BaseOS・AppStream・EPEL・RPM Fusion から入れたもの。`epel-release`・`rpmfusion-free-release` とトレイアイコンの拡張も）は[OS とファームウェアの更新](#os-とファームウェアの更新)の手順 1・4・5 を、ファームウェアは同じ項の手順 2・3 を貼り直す
- [dnf-automatic で自動で更新する（任意）](#dnf-automatic-で自動で更新する任意)を通したなら、OS の更新は毎日自動で入る（再起動は[OS とファームウェアの更新](#os-とファームウェアの更新)の手順 4・5 で自分で行う）
- EPEL の鍵をまだ取り込んでいなければ、`epel-release` が上がるときに確認を求められる（fingerprint は[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 1）
- Flatpak のアプリは `dnf upgrade` では上がらない（この節の手順 4）
- Firefox・WezTerm・GitHub CLI・Claude Code（それぞれのベンダーの dnf のリポジトリから入れたもの）と git・Node.js も、OS の更新で上がる
  - 1 つだけ上げるなら、`sudo dnf upgrade claude-code` のように名前を指定する（Firefox は言語パックと一緒に `sudo dnf upgrade firefox firefox-l10n-ja`）
  - Firefox の FFmpeg（RPM Fusion の `ffmpeg-libs`）も一緒に上がる。WezTerm の COPR は、`main` ブランチに追従して毎日〜数日おきにビルドされる
  - **dnf で入れた Claude Code は自動更新しない**。起動中に更新を知らせてくるが、`claude update` も `Claude is managed by a package manager.` と出して何もしない。リポジトリにその版が届くまで、少し遅れることもある。上がった版は[Claude Code](#claude-code)の手順 4 で確かめる
- HackGen Console NF・git-delta・Neovim・lazygit・yazi（Homebrew で入れたもの）は、この節の手順 3 で上がる
  - **Neovim の設定やプラグインは更新に追従しない**。メジャー更新の後は `:checkhealth` で壊れていないか見る
- 自分用の設定（WezTerm・Neovim・lazygit・yazi）は、それぞれのリポジトリの更新で上げる（Neovim のプラグインと外部コマンドは、[LazyVimStarter の docs/setup.md の「更新」](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#更新)）
  - yazi の自分用の設定は上流の版に合わせてある。yazi の版が上がったら、その [README の「上流の新しい版に追従する」](https://github.com/ryo-aoki-pc/yazi#上流の新しい版に追従する)で設定も追う
- Codex は、端末で起動したときに新しい版を裏で確かめる。新しい版があれば、その後の起動で `Update available!` と `1. Update now` が出る。そのまま Enter を押すと公式インストーラーが動いて上がり、`Update ran successfully! Please restart Codex.` と出たら `codex` を起動し直す
- Grok は自分で新しい版に上がる（設定の `[cli] auto_update` の既定）。確かめるのは対話の画面（`grok`）を起動したときで、新しい版は裏で `~/.grok/downloads` に入り、次に起動したときから使われる。自動の更新も `grok update` も、`~/.bashrc` を変えない
- この節の手順は、[シェルのツール](#シェルのツール)の手順 2 と同じ、開き直した端末に貼る

1. 共通の bash 設定を上げる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   git -C ~/.config/bash pull --ff-only &&
     bash ~/.config/bash/install.sh
   ```

   - `Already up to date.`（上がったときは、変わったファイルの一覧）が出る
   - 上がったときは、端末を開き直すと効く

1. Homebrew 自身と formula の索引を更新し、上げられるものを見る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   brew update
   brew outdated
   ```

   - `brew update` が `Already up-to-date.` を返し、`brew outdated` が無出力なら、上げるものは無いので、この節の手順 3 は飛ばす
   - インターネットに出られないホストでは、[homebrew-offline.md の更新](homebrew-offline.md#更新)で行う

1. 上げるものがあるときだけ、入れたものを上げる。

   ```bash
   brew upgrade
   ```

   - 特定のものだけなら `brew upgrade <formula>`
   - `[y/n]` と聞かれたら、`y` を押す（Enter は要らない）

1. Flatpak で入れたアプリを上げる。

   ```bash
   sudo flatpak update
   ```

   - 更新が無ければ `Nothing to do.` で終わる
   - 更新があれば `[Y/n]` と聞かれる。`y`

1. 起動中の Codex と Grok を終了する。

   - 端末の Codex と Grok は `/quit` で閉じる
   - 知らせを待たずに上げるときだけ、この節の手順 5〜8 を行う

1. 公式インストーラーをもう一度実行して、Codex CLI を上げる。

   ```bash
   curl -fsSL https://chatgpt.com/codex/install.sh | sh
   ```

   - `Start Codex now?` は `n` で答える
   - **次の手順は、シェルのプロンプトに戻ってから貼る**

1. Codex CLI の更新後の版を確かめる。

   ```bash
   codex --version
   ```

1. Grok Build の新しい版を入れ、版を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   grok update
   grok --version
   ```

   - 新しい版が無ければ `Already up to date (…)` と出る
   - 確かめるだけなら `grok update --check`（`(latest: …)` に最新の版が出る）

1. 2 つのプラグインのマーケットプレイスとプラグインを上げる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   claude plugin marketplace update openai-codex
   claude plugin marketplace update xai-grok-build
   claude plugin update codex@openai-codex
   claude plugin update grok-build@xai-grok-build
   claude plugin list
   ```

   - `✔ Successfully updated marketplace: …` が 2 つと、`✔ … updated …` か `✔ … is already at the latest version (…)` が 2 つ出る
   - 上がったプラグインは、Claude Code を起動し直すまで効かない（Remote Control も止めてから始め直す）
