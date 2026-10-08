# AlmaLinux 10 の初期設定の手順（インストール直後の更新・sudo・SSH・導入元・日本語入力・GNOME・シェルのツール）

## 実施手順

- [検証記録](verification/almalinux-setup.md)・[参考資料](reference/almalinux-setup.md)

> [!IMPORTANT]
> - **すべて、この PC の GNOME のデスクトップで、インストールのときに作った管理者（`wheel` の一員）のユーザーとして行う**。手順 2 で開く端末に貼る。`sudo -i`・`su -` のシェルでは行わない（`gsettings` はログインしているユーザーの設定だけを変え、Homebrew は root での実行を断る）
> - 前提: AlmaLinux 10 の Workstation を入れた直後で、インターネットにつながっていること。インターネットに出られないホストの Homebrew は、[homebrew-offline.md](homebrew-offline.md) から入れる
> - **手順 3 で、sudo のパスワードを 1 回だけ聞かれる**（手順 3 から後の `sudo` は聞かない）
> - **対話入力のある手順**: 3（パスワード）・4・16・20・38（`[y/N]`。手順 4 では AlmaLinux の鍵、手順 38 では EPEL の鍵の確認も）・5（LVFS を有効にするか）・6（ファームウェアの更新があるとき）・25（確認 2 回）・47（RETURN）・49（`[y/n]`）・64・65（tmux の画面）。**目で確かめてから次へ進む手順**: 18・23・57
> - **画面で行う手順**: 1・2・50・59〜63・68・70〜73（59〜63・71 はキーを押して確かめる）。**再起動**: 8（要るときだけ）・67。**条件付きの手順**: 8・10・12・15・70

- 上から順にコードブロックを貼る。手順 9 の変数は、新しい端末を開いたら貼り直す（手順 50 より後では使わない）
- 項目ごとの手順（要らない項目の手順は飛ばしてよい。手順 1〜4・7〜9・42・43・46〜50・67 は飛ばさない）
  - 更新: OS は 4・7・8、ファームウェアは 5・6
  - PC 全体: sudo は 3、PC の名前は 10、SSH は 11・12、journal は 13、kdump は 14・15、コマンドが無いときのパッケージの案内は 16
  - 導入元: EPEL は 17、RPM Fusion は 18〜21、Flathub は 22〜24（確認用の Flatseal は 25・26）
  - 日本語入力: 27・28。確かめるのは 72
  - 表示: フォルダーの名前は 29、ダークモードは 30、ウィンドウのボタンは 32、時計と電池は 33、Files は 34、ホットコーナーは 36、拡大率は 37・70、トレイアイコンは 38・39、Dash のお気に入りは 41。確かめるのは 68・73
  - 入力: Caps Lock を Ctrl には 31、Alt+Tab は 35、Ctrl+Alt+T は 40。確かめるのは 71
  - シェル: 共通の bash 設定は 42・43、bash の補完とキー操作は 44・45・51・59、Homebrew は 46〜48、starship・zoxide・fzf・eza・bat・tmux は 49・52〜58・60〜66
- 手順の後に、この順に通す手順書
  - [Git](git.md)（`~/.gitconfig` の基本の設定）→ [Firefox](firefox.md)（最新版。手順 8〜11 の AAC・H.264 は、この文書の手順 18〜21 の RPM Fusion を使う）→ [HackGen Console NF](hackgen.md) → [WezTerm](wezterm-nightly.md) → [Claude Code](claude-code.md) → [Codex CLI](codex.md)
  - HackGen Console NF と WezTerm を入れたら、[WezTerm と HackGen Console NF をデスクトップで使う（任意）](#wezterm-と-hackgen-console-nf-をデスクトップで使う任意)
  - 必要なら: Homebrew のほかのツール（[yazi](yazi.md)・[lazygit](lazygit.md)・[git-delta](git-delta.md)・[Neovim](neovim.md)・[gdu](gdu.md)・[ShellCheck / shfmt](shellcheck.md)）、[btop](btop.md)・[GitHub CLI](gh.md)・[VS Code](vscode.md)・[Podman](podman.md)、役割ごとの手順書（[README の手順書とツール](../README.md#手順書とツール)）
- 手順の後: SSH を公開鍵だけにするなら[SSH を公開鍵だけにする（任意）](#ssh-を公開鍵だけにする任意)、OS を自動で更新するなら[dnf-automatic で自動で更新する（任意）](#dnf-automatic-で自動で更新する任意)、常時動かしておく PC は[画面オフ・画面ロック・自動サスペンドを止める（任意）](#画面オフ画面ロック自動サスペンドを止める任意)、[Wake on LAN を使う（任意）](#wake-on-lan-を使う任意)
  - Homebrew・Flatpak・starship・fzf・eza・bat・tmux の使い方と設定は、この文書の後ろの節。以後は[更新](#更新)・[ロールバック](#ロールバック)

> [!WARNING]
> - **手順 3 の後は、このユーザーで動くプログラム（ブラウザの拡張、AI のエージェント、`curl … | bash` のインストーラなど）が、パスワード無しで root の権限を使える**。人が触れる場所にある PC や、信用できないプログラムを動かすユーザーでは行わない。外すのは[ロールバック](#ロールバック)の最後の手順

1. インストールのときに作ったユーザーで GNOME にログインし、「ようこそ」の窓を閉じる。

   - インストールの後の最初の起動で、ログイン画面でユーザーを選び、パスワードを入れる
   - 初めてのログインでは、アクティビティの画面に「AlmaLinux 10.2 (Lavender Lion) へようこそ」の窓が出る。「スキップ」を押す（ツアーを見るなら「“ツアー”を始める」）
   - このログインで、ホームに日本語の名前のフォルダー（`ダウンロード`・`ドキュメント` など）ができる。手順 29 で英語の名前にする

1. 端末を開く。

   - Super キー（Windows キー）でアクティビティの画面を開き、「端末」と打って Enter。左の Dash の端末のアイコンでもよい
   - 端末のアプリは Ptyxis（「端末」）。手順 3 から、この端末に貼る

1. sudo をパスワード無しで使えるようにする（パスワードを 1 回聞かれる）。

   ```bash
   {
     if ! id -nG | grep -qw wheel; then
       echo '中断: このユーザーは wheel の一員ではない（インストールのときに管理者にしたユーザーで貼る）' >&2
     else
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
   - `Defaults:<USER> verifypw=any` は、`sudo -v`（Homebrew のインストーラが使う）もパスワード無しにする。`/etc/sudoers` の `%wheel ALL=(ALL) ALL` の行が残っているため
   - `中断:` が出たら、何も書いていない。インストールのときに管理者にしたユーザーでログインし直して、手順 2 から
   - 貼り直しても同じ内容で置き直すだけ（何度貼ってもよい）
   - **次の手順は、パスワードを入れて、プロンプトに戻ってから貼る**（続けて貼ると、パスワードとして食われる）

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

   - 初めてのときは `現在リモートが有効になっていないため、メタデータが利用できません。` に続けて `このリモートを有効にしますか? [Y|n]:` と聞かれる。`Y`（LVFS は Linux のベンダーのファームウェアを配るサービス。AlmaLinux 10 の既定では無効）
   - `新しいメタデータのダウンロードに成功しました:` と、更新できる機器の数が出る（仮想マシンでは `更新可能なデバイスはありません`）
   - `デーモンへの接続に失敗しました: … タイムアウトしました` と出たら、少し待ってから貼り直す（起動の直後は、fwupd の起動が間に合わないことがある）
   - **次の手順は、問いに答えてプロンプトに戻ってから貼る**（続けて貼ると、答えとして食われる）

1. ファームウェアの更新があれば、更新する。

   ```bash
   sudo fwupdmgr update
   ```

   - 更新が無ければ `No updatable devices` と出て終わる
   - 更新があれば、機器ごとに確認を聞かれる。`y`。再起動するかを聞かれたら `n`（手順 8 で再起動する）
   - **注意**: 更新の途中で電源を切らない。ノート PC は電源につないでおく
   - **次の手順は、問いに答え終わってプロンプトに戻ってから貼る**（続けて貼ると、答えとして食われる）

1. OS の再起動が要るかを確かめる。

   ```bash
   dnf needs-restarting -r
   ```

   - `再起動な必要ありません。`（表示のとおり）と出て、手順 6 でファームウェアを更新していなければ、手順 8 は飛ばす
   - `再起動が必要です` の形の行（カーネルや systemd などを更新したとき）が出たか、手順 6 でファームウェアを更新したなら、手順 8 で再起動する

1. 再起動が要るときだけ、再起動する。

   ```bash
   sudo systemctl reboot
   ```

   - 保存していない文書のあるアプリが開いていると、`Operation inhibited by …` で断られることがある。そのアプリを閉じてから貼り直す
   - **次の手順は、起動してログインし、手順 2 のように端末を開いてから貼る**

1. 変数を設定する（PC の名前を変えるなら、`HOST_NAME` に値を入れる）。

   ```bash
   HOST_NAME=''   # この PC の新しい名前（英小文字・数字・ハイフン。例: alma-pc）。変えないなら空のまま。<HOSTNAME>
   ```

   ```bash
   XKB_LAYOUT=$(localectl status 2>/dev/null | sed -n 's/^ *X11 Layout: \([a-z][a-z0-9_]*\).*/\1/p')   # キーボードの配列（自動）。JIS は jp、US は us。<XKB_LAYOUT>
   DASH_FAVORITES="['firefox.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Ptyxis.desktop', 'org.gnome.TextEditor.desktop']"   # Dash に並べるアプリ（左から）
   for v in USER HOST_NAME XKB_LAYOUT DASH_FAVORITES; do
     printf '%-14s = %s\n' "$v" "${!v}"
   done
   ```

   - 最後に値を読み戻して確かめる
   - `HOST_NAME` は、SSH・RDP・Samba・Syncthing などで、この PC を見分ける名前。変えないなら空のままにして、手順 10 を飛ばす
   - `XKB_LAYOUT` が空か、手元のキーボードと違うなら、`XKB_LAYOUT=jp`（JIS 配列）か `XKB_LAYOUT=us`（US 配列）を貼ってから先へ進む
   - `DASH_FAVORITES` は、手順 41 で左の Dash に並べるアプリ（`/usr/share/applications` の `.desktop` のファイル名）
   - `USER` が `root` になっているなら、ここで止めて、自分のユーザーの端末で貼り直す
   - 変数はその端末の中だけで有効。**新しい端末を開いたら**、手順 9 を貼り直してから先へ進む

1. PC の名前を変えるときだけ、名前を変える。

   ```bash
   if [ -z "${HOST_NAME}" ]; then echo '中断: 手順 9 の HOST_NAME が空のまま。名前を変えないなら、この手順は飛ばす' >&2; else
     echo "変える前: $(hostnamectl --static)"
     sudo hostnamectl hostname "${HOST_NAME}"
     echo "変えた後: $(hostnamectl --static)"
   fi
   ```

   - `変える前:` の名前を控える（[ロールバック](#ロールバック)の手順 39 で使う）
   - `変えた後:` に、手順 9 の名前が出ればよい
   - 開いている端末のプロンプトは、開き直すまで前の名前のまま

1. SSH の待ち受けとファイアウォールを確かめ、この PC の IP アドレスを見る。

   ```bash
   {
     systemctl is-enabled sshd
     systemctl is-active sshd
     sudo firewall-cmd --query-service=ssh
     sudo firewall-cmd --permanent --query-service=ssh
     ip -4 -brief address show scope global
   }
   ```

   - `enabled`・`active`・`yes`・`yes` と、この PC の IP アドレスが出ればよい（Workstation の既定。手順 12 は飛ばす）
   - どれかが違えば、手順 12 で直す
   - 別の PC からは `ssh <USER>@<IP>` でログインできる（初めてつなぐときは、ホストの鍵の fingerprint を聞かれる）

1. SSH の待ち受けか、ファイアウォールの ssh が違うときだけ、直す。

   ```bash
   {
     if ! rpm -q openssh-server; then sudo dnf install -y openssh-server; fi
     sudo systemctl enable --now sshd
     sudo firewall-cmd --permanent --add-service=ssh
     sudo firewall-cmd --reload
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
     ls -ld /var/log/journal
     journalctl --disk-usage
   }
   ```

   - `drwxr-sr-x+ … root systemd-journal … /var/log/journal` の行と、journal の大きさが出ればよい
   - journald が作った `/var/log/journal` には、グループ `systemd-journal` と、`wheel`・`adm` のグループが読める ACL が付かない。`systemd-tmpfiles` が、パッケージの定義どおりに付ける（すでにあるものだけを直すので、`--flush` の後に行う）
   - AlmaLinux 10 の既定では `/var/log/journal` が無く、journal は `/run/log/journal`（メモリー）にだけ書かれて、再起動で消える
   - 前の起動のログが読めることは、手順 67 の再起動の後に、手順 69 で確かめる

1. kdump が有効になっているか確かめる。

   ```bash
   systemctl is-enabled kdump
   cat /sys/kernel/kexec_crash_size
   grep -o 'crashkernel=[^ ]*' /proc/cmdline
   ```

   - `enabled` と、0 でない数（予約しているメモリーのバイト数。`268435456` で 256 MiB）と、`crashkernel=…` が出たら、手順 15 で止める
   - `disabled` と `0` が出て、`crashkernel=` が無ければ、手順 15 は飛ばす

1. kdump が有効なときだけ、止めて、カーネルが落ちたときのために予約しているメモリーを外す（効くのは再起動の後）。

   ```bash
   {
     sudo systemctl disable --now kdump
     sudo sed -i 's/^auto_reset_crashkernel yes$/auto_reset_crashkernel no/' /etc/kdump.conf
     sudo grubby --update-kernel=ALL --remove-args=crashkernel
     grep -n '^auto_reset_crashkernel' /etc/kdump.conf
     sudo grubby --info=ALL | grep -E '^args='
   }
   ```

   - `auto_reset_crashkernel no` と、`crashkernel=` を含まない `args=` の行が出ればよい
   - `auto_reset_crashkernel` を `no` にするのは、カーネルを更新したときに `crashkernel=` を付け直させないため
   - メモリーが空くのは、手順 67 の再起動の後
   - **注意**: カーネルが落ちたときの記録（vmcore）は残らなくなる

1. コマンドが無いときにパッケージを探して案内する機能（PackageKit-command-not-found）を外す。

   ```bash
   sudo dnf remove PackageKit-command-not-found
   ```

   - `削除中:` が `PackageKit-command-not-found` の 1 つだけになる。`これでよろしいですか? [y/N]:` に `y`
   - 外すと、無いコマンドを打ったときは `bash: <コマンド>: コマンドが見つかりません...` とだけ出て、パッケージを探して待たされない
   - **次の手順は、`完了しました!` が出てプロンプトに戻ってから貼る**（続けて貼ると、`[y/N]` の答えとして食われる）

1. EPEL が無ければ入れ、有効になったか確かめる。

   ```bash
   {
     if ! dnf repolist enabled | grep -qE '^epel'; then sudo dnf install -y epel-release; fi
     rpm -q epel-release
     dnf repolist enabled | grep -E '^epel'
   }
   ```

   - `epel-release` の版と、`epel` の行が出れば有効になっている
   - AlmaLinux の `extras` リポジトリにあるので、追加のリポジトリの設定は要らない。最後に出る「CRB を有効にすることを推奨」は、AlmaLinux 10 では既定で有効なので気にしなくてよい（[導入元一覧](tool-catalog.md#導入経路と-el10-での注意)）
   - EPEL の署名鍵は、EPEL からパッケージを初めて入れるとき（この文書では手順 38）に、dnf が 1 回だけ確認を求める
     - fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）であることを確かめてから `y`。違っていれば `N` で中断する
   - EPEL を使う手順書（[btop](btop.md)・[distrobox](distrobox.md)・[podman-compose](podman-compose.md)・[podman-tui](podman-tui.md)・[VirtualBox](virtualbox.md)）と、[導入元一覧](tool-catalog.md)の EPEL の行が使えるようになる

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
     rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i fusion
   }
   ```

   - `rpm --import` は何も表示しない
   - `gpg-pubkey-db85ddd7-67a63d8b RPM Fusion free repository for EL (10) ...` の 1 行が出れば、取り込めている

1. RPM Fusion（free）のリポジトリを入れる。

   ```bash
   sudo dnf --setopt=localpkg_gpgcheck=1 install https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-10.noarch.rpm
   ```

   - `--setopt=localpkg_gpgcheck=1` を外さない（外すと、手順 19 の鍵で署名を確かめずに入る。[検証記録](verification/almalinux-setup.md#rpm-fusion-実施手順--手順-3-補足-署名の確認とepel-を前提にした理由)・[参考資料](reference/almalinux-setup.md#rpm-fusion-選択した方針)）
   - EPEL が有効なホストでは、`インストール:` が `rpmfusion-free-release` の 1 つだけになる
   - 有効にするのは free だけ。nonfree は扱わない
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. RPM Fusion（free）が有効になったか確かめる。

   ```bash
   rpm -q rpmfusion-free-release
   dnf repolist enabled | grep -E '^rpmfusion'
   ```

   - `rpmfusion-free-release` の版と、`rpmfusion-free-updates` の行が出れば有効になっている
   - [Firefox の AAC・H.264](firefox.md#実施手順)（firefox.md の手順 8 から。RPM Fusion の `ffmpeg-libs` を入れる）が使えるようになる

1. flatpak を確かめ（無ければ入れ）、登録されているリモートを見る。

   ```bash
   {
     if ! rpm -q flatpak; then sudo dnf install -y flatpak; fi
     flatpak --version
     flatpak remotes --show-details
   }
   ```

   - `flatpak-1.16.0-…` と `Flatpak 1.16.0` が出る（Workstation には最初から入っている）
   - **入れた直後は `flatpak remotes` が `error: While opening repository /var/lib/flatpak/repo: ...` を出すが、壊れているわけではない**。リモートがまだ無いだけ
   - **`flathub` の行が既にあれば、手順 24 は何もしない**（`--if-not-exists` のため）

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
     flatpak remotes --show-details
   }
   ```

   - `flathub` の行が出て、`Options` の列が `system` になっていればよい
   - [導入元一覧](tool-catalog.md#gui)の「Flathub」の行にある GUI アプリが入れられるようになる。[Firefox](firefox.md) と [VS Code](vscode.md) は Flathub を使わず RPM で入れる

1. 確認用のアプリ（Flatseal）を入れる。

   ```bash
   sudo flatpak install flathub com.github.tchx84.Flatseal
   ```

   - 確認用のアプリは、小さい [Flatseal](https://flathub.org/apps/com.github.tchx84.Flatseal)（Flatpak アプリの権限を GUI で変えるツール）にしてある
   - **確認を 2 回聞かれる**。どちらも `y` で進める
     - 1 回目: runtime を入れるか（`Do you want to install it? [Y/n]`）
     - 2 回目: アプリの権限と入れるものの一覧を見せたうえでの最終確認（`Proceed with these changes to the system installation? [Y/n]`）
   - 最初の 1 本は runtime ごと落とすので、`/var/lib/flatpak` が 2.5 GB ほどになる。要らなければ、この手順と手順 26 は飛ばしてよい
   - **次の手順は、2 回の確認に答え、完了してから貼る**（続けて貼ると答えとして食われる）

1. 確認用のアプリが入り、サンドボックスが起動できるか確かめる。

   ```bash
   flatpak list --app --columns=application,version,branch,installation
   flatpak info com.github.tchx84.Flatseal
   flatpak run --command=true com.github.tchx84.Flatseal && echo 'sandbox OK'
   ls /var/lib/flatpak/exports/share/applications/
   ```

   - `flatpak list` に `com.github.tchx84.Flatseal  2.4.1  stable  system` のように出る
   - `sandbox OK` が出れば、アプリのサンドボックスが起動できている
   - 最後の行に `com.github.tchx84.Flatseal.desktop` が出れば、デスクトップのメニューに載せるためのファイルができている
   - メニューに載るのは、手順 67 の再起動の後

1. ibus-anthy と日本語のフォントが無ければ入れる。

   ```bash
   if ! rpm -q ibus ibus-anthy default-fonts-cjk-sans; then sudo dnf install -y ibus-anthy default-fonts-cjk-sans; fi
   ```

   - 3 つとも版が出れば、入っている（Workstation で入れた PC には最初から入っている）
   - `package … is not installed` が出たときは、続けて AppStream から入る。入れたときは、手順 67 の再起動の後に使えるようになる（動いている IBus は、ログインし直すまで Anthy を使えない）

1. 入力ソースを「キーボードの配列 + Anthy」にする。

   ```bash
   if [ -z "${XKB_LAYOUT}" ]; then echo '中断: 手順 9 の XKB_LAYOUT が空のまま。値を入れて貼り直す' >&2; else
     /usr/bin/gsettings get org.gnome.desktop.input-sources sources
     /usr/bin/gsettings set org.gnome.desktop.input-sources sources "[('xkb', '${XKB_LAYOUT}'), ('ibus', 'anthy')]"
     /usr/bin/gsettings get org.gnome.desktop.input-sources sources
     /usr/bin/gsettings get org.gnome.desktop.wm.keybindings switch-input-source
   fi
   ```

   - 最初の `get` は変える前の値（最初のログインの後は、今の配列だけの `[('xkb', 'us')]` など）。戻すときのために控えておく
   - 2 つ目の `get` が `[('xkb', 'jp'), ('ibus', 'anthy')]`（US 配列なら `'us'`）になればよい
   - **ほかの入力ソースは消える**。残したいものがあれば、`set` の値に並べて足す
   - 最後の `get` の `['<Super>space', 'XF86Keyboard']` が、入力ソースを切り替えるキー（Super+Space）
   - **注意**: `/usr/bin/` を外さない（Homebrew の `gsettings` は GNOME の dconf に書かない。手順 29〜41 も同じ）

1. ホームのフォルダーの名前を、日本語から英語にする（中身ごと移す）。

   ```bash
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
   - 中身は、フォルダーごと移る。英語の名前のフォルダーがもうあると、そのフォルダーは `飛ばした:` で変えない
   - 次のログインで「標準フォルダーの名前を現在の言語に合わせて更新しますか?」の窓は出ない（`~/.config/user-dirs.locale` は今の言語のまま）

1. ダークモードにする。

   ```bash
   /usr/bin/gsettings set org.gnome.desktop.interface color-scheme prefer-dark
   /usr/bin/gsettings get org.gnome.desktop.interface color-scheme
   ```

   - `'prefer-dark'` が出ればよい。設定の「外観」の「スタイル」の「ダーク」と同じで、すぐに効く

1. Caps Lock を Ctrl にする（今の配列の設定に足す）。

   ```bash
   xkb=$(/usr/bin/gsettings get org.gnome.desktop.input-sources xkb-options)
   echo "変える前: ${xkb}"
   case "${xkb}" in
     *"'ctrl:nocaps'"*) ;;
     '@as []') /usr/bin/gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']" ;;
     *) /usr/bin/gsettings set org.gnome.desktop.input-sources xkb-options "${xkb%]}, 'ctrl:nocaps']" ;;
   esac
   /usr/bin/gsettings get org.gnome.desktop.input-sources xkb-options
   ```

   - 最後に `['ctrl:nocaps']`（ほかの設定があれば、その後ろに `'ctrl:nocaps'`）が出ればよい。すぐに効く
   - 自分のセッションだけの設定。ログイン画面と、ほかのユーザーには効かない

1. ウィンドウのタイトルバーに、最小化と最大化のボタンを出す。

   ```bash
   /usr/bin/gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
   /usr/bin/gsettings get org.gnome.desktop.wm.preferences button-layout
   ```

   - `'appmenu:minimize,maximize,close'` が出ればよい（既定は `'appmenu:close'`）

1. 上部バーの時計に曜日と秒を出し、電池の残りを % で出す。

   ```bash
   /usr/bin/gsettings set org.gnome.desktop.interface clock-show-weekday true
   /usr/bin/gsettings set org.gnome.desktop.interface clock-show-seconds true
   /usr/bin/gsettings set org.gnome.desktop.interface show-battery-percentage true
   /usr/bin/gsettings list-recursively org.gnome.desktop.interface | grep -E 'clock-show-(weekday|seconds)|show-battery-percentage'
   ```

   - 3 行とも `true` が出ればよい
   - 電池の % は、電池のある PC だけに出る

1. Files とファイルを選ぶ窓で、隠しファイルを出し、フォルダーを先に並べる。

   ```bash
   for s in org.gtk.Settings.FileChooser org.gtk.gtk4.Settings.FileChooser; do
     /usr/bin/gsettings set "${s}" show-hidden true
     /usr/bin/gsettings set "${s}" sort-directories-first true
     /usr/bin/gsettings list-recursively "${s}" | grep -E 'show-hidden|sort-directories-first'
   done
   ```

   - 2 つのスキーマで、`show-hidden true` と `sort-directories-first true` が 2 行ずつ出ればよい（Files と GTK4 のアプリは `org.gtk.gtk4`、GTK3 のアプリは `org.gtk` を読む）
   - Files では Ctrl+H で、隠しファイルを出す・隠すを切り替えられる

1. Alt+Tab を、アプリごとではなくウィンドウごとの切り替えにする。

   ```bash
   /usr/bin/gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab']"
   /usr/bin/gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Super>Tab']"
   /usr/bin/gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
   /usr/bin/gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab']"
   /usr/bin/gsettings list-recursively org.gnome.desktop.wm.keybindings | grep -E 'switch-(applications|windows)'
   ```

   - `switch-windows ['<Alt>Tab']` と `switch-applications ['<Super>Tab']` などの 4 行が出ればよい
   - アプリごとの切り替えは Super+Tab に残る

1. 画面の左上の角（ホットコーナー）にマウスを当てても、アクティビティの画面を開かないようにする。

   ```bash
   /usr/bin/gsettings set org.gnome.desktop.interface enable-hot-corners false
   /usr/bin/gsettings get org.gnome.desktop.interface enable-hot-corners
   ```

   - `false` が出ればよい。アクティビティの画面は Super キーで開く

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
   /usr/bin/gsettings get org.gnome.mutter experimental-features
   ```

   - `['scale-monitor-framebuffer', 'xwayland-native-scaling']` が出ればよい（mutter 49 の既定は空）
   - 拡大率を選ぶのは、手順 67 の再起動の後に、手順 70 で行う
   - `xwayland-native-scaling` は、X11 のアプリ（XWayland）を、ぼかさずに拡大縮小させる

1. EPEL から、トレイアイコンを出す GNOME の拡張（AppIndicator）を入れる。

   ```bash
   sudo dnf install gnome-shell-extension-appindicator
   ```

   - `これでよろしいですか? [y/N]:` に `y`
   - EPEL からパッケージを入れるのが初めてなら、続けて EPEL の鍵の取り込みを聞かれる。fingerprint が手順 17 の値なら `y`、違っていれば `N`
   - 入るのは `gnome-shell-extension-appindicator`（AlmaLinux 10.2 では 61）
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
   /usr/bin/gsettings get org.gnome.shell enabled-extensions
   ```

   - 最後に、もとの拡張（`'background-logo@fedorahosted.org'`）と `'appindicatorsupport@rgcjonas.gmail.com'` が出ればよい
   - 動いている GNOME Shell は、ログインし直すまで、入れたばかりの拡張を読まない。手順 67 の再起動の後に、手順 69 で確かめる

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
   /usr/bin/gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings
   /usr/bin/gsettings list-recursively "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}"
   ```

   - 一覧に `'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal/'` があり、`binding '<Control><Alt>t'`・`command 'ptyxis --new-window'`・`name '端末'` が出ればよい。すぐに効く
   - 設定の「キーボード」→「キーボードショートカット」→「カスタムショートカット」にも出る

1. Dash のお気に入り（左の並び）を、手順 9 のアプリにする。

   ```bash
   if [ -z "${DASH_FAVORITES}" ]; then echo '中断: 手順 9 の DASH_FAVORITES が空のまま。値を入れて貼り直す' >&2; else
     /usr/bin/gsettings get org.gnome.shell favorite-apps
     /usr/bin/gsettings set org.gnome.shell favorite-apps "${DASH_FAVORITES}"
     /usr/bin/gsettings get org.gnome.shell favorite-apps
   fi
   ```

   - 最初の `get` は変える前の並び（Workstation では Firefox・カレンダー・Files・ソフトウェア・端末・テキストエディター・電卓）。戻すときのために控えておく
   - 2 つ目の `get` が手順 9 の値になればよい。すぐに効く

1. 共通の bash 設定を入れる。

   ```bash
   git clone https://github.com/ryo-aoki-pc/bash.git ~/.config/bash &&
     bash ~/.config/bash/install.sh
   ```

   - [README の共通の bash 設定を先に入れる](../README.md#共通の-bash-設定を先に入れる)と同じ（Workstation には git が最初から入っている）
   - `~/.bashrc: 設定済み（元の内容: ~/.bashrc.before-bash）` と `完了: 端末を開き直す。…` が出ればよい（元の `~/.bashrc` は `~/.bashrc.before-bash` に残る）
   - `~/.bashrc` の末尾に、`~/.config/bash/bashrc` を読む 1 行が足される。ツールごとの設定（Homebrew・starship・zoxide・fzf・eza・bat の `MANPAGER`・履歴と `shopt` など）は、この設定がまとめて読む。この文書では `~/.bashrc` に追記しない
   - すでに clone してあるなら `fatal: destination path … already exists` で止まる。そのときは `git -C ~/.config/bash pull --ff-only` で更新し、`bash ~/.config/bash/install.sh` を貼る

1. 共通の bash 設定を今の端末に読み込み、履歴と shopt の値を確かめる。

   ```bash
   . ~/.bashrc
   echo "${__bash_config_loaded-読まれていない}"
   printf '%s\n' "$HISTSIZE" "$HISTFILESIZE" "$HISTCONTROL"
   shopt histappend autocd cdspell dirspell globstar
   ```

   - `1`、`100000`・`100000`・`ignoreboth`、5 つの `on` が出ればよい

1. bash-completion が入っているか確かめ、無ければ入れる。

   ```bash
   if ! rpm -q bash-completion; then sudo dnf install -y bash-completion; fi
   ```

   - `bash-completion-2.11-…` と出れば入っている（Workstation で入れた PC は、最初から入っている）
   - `package bash-completion is not installed` のときは、続けて BaseOS から入る（依存の `pkgconf` 系 4 つも入る）

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
     bind -v | grep -E 'completion-ignore-case|show-all-if-ambiguous|colored-stats|colored-completion-prefix'
     bind -q history-search-backward
     bind -q beginning-of-line
   fi
   ```

   - `set … on` が 4 行、`history-search-backward は次を通して起動します "\eOA", "\e[5~", "\e[A".`、`beginning-of-line は次を通して起動します "\C-a", "\eOH", "\e[1~", "\e[H".` が出る（英語の環境では `… can be invoked via …`）
   - `beginning-of-line` に `"\e[1~"` が無ければ、`$include /etc/inputrc` の行が読まれていない
   - `中断:` が出たら、すでにある `~/.inputrc` に、`$include /etc/inputrc` が無ければ先頭に足し、`set` の 4 行と矢印の 4 行を手で足す。足したら `bind -f ~/.inputrc`

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
   - 終わりに `==> Installation successful!` と、PATH の通し方を書いた `==> Next steps:` が出る。`Next steps` の `~/.bashrc` への追記は行わない（共通の bash 設定が `brew shellenv` を読む）
   - 手順 3 の `verifypw=any` があるので、インストーラの `sudo` はパスワードを聞かない
   - **次の手順は、インストーラが終わってから貼る**（続けて貼ると `RETURN` の確認として食われる）

1. 共通の bash 設定を読み直して Homebrew の PATH を有効にし、入ったか確かめる。

   ```bash
   . ~/.bashrc
   brew --version
   command -v brew
   brew config | head -12
   ```

   - `command -v brew` が `/home/linuxbrew/.linuxbrew/bin/brew` を返す
   - `brew config` の `HOMEBREW_PREFIX` が `/home/linuxbrew/.linuxbrew` ならよい
   - 日々の操作は[Homebrew の使い方の基本](#homebrew-の使い方の基本)

1. brew で starship・zoxide・fzf・eza・bat・tmux を入れる。

   ```bash
   brew install starship zoxide fzf eza bat tmux
   ```

   - 依存も入れる計画なので、入れるものの一覧の後に `Do you want to proceed with the installation? [y/n]` と聞かれる。`y`（Enter は要らない）
   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
   - 要らないツールは、名前を外してから貼る（共通の bash 設定は、入っているものだけを読む）
   - **次の手順は、`y` と答えて、プロンプトに戻ってから行う**（続けて貼ると、後ろの行の文字が答えとして読まれる）

1. 開いている端末を閉じて、開き直す。

   - Ctrl+Alt+T（手順 40）でも開ける
   - 開き直した端末から、プロンプトが starship に変わり、zoxide・fzf・eza のエイリアス・bat の `MANPAGER` も効く（共通の bash 設定が、入っているツールを読む）
   - 今の端末で `. ~/.bashrc` を読み直さない（starship が、そのシェルで既に読んだ WezTerm のシェル統合より後ろで初期化され、WezTerm のフックが 2 回ずつ動く）
   - 手順 9 の変数は、この後は使わない
   - **次の手順は、開き直した端末で貼る**

1. bash の履歴・補完・キー操作の設定が効いていることを確かめる。

   ```bash
   printf '%s\n' "${HISTSIZE}" "${HISTFILESIZE}" "${HISTCONTROL}"
   shopt histappend autocd cdspell dirspell globstar
   complete -p -D
   complete -p brew
   bind -v | grep -E 'completion-ignore-case|show-all-if-ambiguous|colored-stats|colored-completion-prefix'
   bind -q history-search-backward
   ```

   - `100000`・`100000`・`ignoreboth`、5 つの `on` が出る
   - `complete -F _completion_loader -D`（Workstation では `complete -F _python_argcomplete_global -D` のこともある）と、`-F _brew brew` を含む行が出る（共通の bash 設定が Homebrew の補完を fzf より前に読む）
   - `set … on` が 4 行と、`history-search-backward は次を通して起動します "\eOA", "\e[5~", "\e[A".` が出る（英語の環境では `… can be invoked via …`）

1. starship が入り、プロンプトの文字列が作られるか確かめる。

   ```bash
   grep -n -e 'starship init' -e 'WEZTERM_SHELL_INTEGRATION' -e 'zoxide init' ~/.config/bash/bashrc
   starship --version
   command -v starship
   starship module directory
   starship explain
   ```

   - 最初の行で、starship → WezTerm → zoxide の順に出る（共通の bash 設定が初期化の順番を持つ。`~/.bashrc` の編集は不要）
   - `starship 1.26.0` のような版と、`/home/linuxbrew/.linuxbrew/bin/starship` が出る
   - `starship explain` は、今のプロンプトに出ている各部分の意味を 1 行ずつ説明する
   - 見た目を変えるなら[starship のプリセットを当てる（任意）](#starship-のプリセットを当てる任意)、細かい調整は[starship の設定ファイル](#starship-の設定ファイル)

1. fzf が入り、キー操作と補完が組み込まれたか確かめる。

   ```bash
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
   eza --version
   command -v eza
   eza -l --git --header ~/.config/bash
   alias ll la lt
   ```

   - `eza --version` は `v0.23.5 [+git]` のような行を含む（`[+git]` は git の連携込みのビルド）
   - `Permissions Size User Date Modified Git Name` の見出しの一覧が出る（`~/.config/bash` は git のリポジトリなので、`Git` の列が出る）
   - `ll` は `eza -l --git --group-directories-first`、`la` は `-la`、`lt` は `eza --tree --level=2`（共通の bash 設定が足す。`ls` は置き換えない）

1. bat の版と、色と行番号、man のページャを確かめる。

   ```bash
   bat --version
   command -v bat
   bat --color=always --style=numbers /etc/os-release | head -5
   printf '%s\n' "$MANPAGER"
   ```

   - `bat 0.26.1` のような版と、`/home/linuxbrew/.linuxbrew/bin/bat` が出る
   - 行番号付きで `NAME="AlmaLinux"` から 5 行が色付きで出る（`--color=always` を外してパイプに繋ぐと、装飾の無い `cat` と同じ出力になる）
   - 最後に `bat -plman` が出ればよい（共通の bash 設定が持つ）。`man bash` が bat の色で開く（`q` で閉じる）

1. tmux が入ったことを確かめる。

   ```bash
   tmux -V
   command -v tmux
   rpm -q tmux
   ```

   - `tmux 3.7c` のような版と `/home/linuxbrew/.linuxbrew/bin/tmux` が出る
   - 最後の行は `パッケージ tmux はインストールされていません`（英語の環境では `package tmux is not installed`）でよい
   - **BaseOS の tmux（`tmux-3.3a-…`）が出て、そちらで始めたセッションが動いているなら**、そのセッションには `/usr/bin/tmux attach` で入る（Homebrew の tmux からはつなげない。[検証記録](verification/almalinux-setup.md#tmux-実施手順--手順-2-補足-baseos-の-tmux-と並べたとき)）

1. zoxide の `z` と `zi` を確かめ、記録を試すディレクトリへ移る。

   ```bash
   type -t z zi
   zoxide --version
   command -v zoxide
   cd /usr/share
   ```

   - `function` が 2 行と、`zoxide 0.10.0` のような版、`/home/linuxbrew/.linuxbrew/bin/zoxide` が出る
   - **注意**: 対話のシェル（端末に貼る）で行う。スクリプトの中では記録されない
   - **次の手順は、プロンプトが戻ってから貼る**（zoxide はプロンプトを出すときに今のディレクトリを記録する。続けて貼ると、プロンプトが出る前に手順 58 が動き、`/usr/share` がまだ無い）

1. zoxide のデータベースに記録されたか確かめ、ホームに戻る。

   ```bash
   zoxide query --list
   cd ~
   ```

   - `/usr/share` が出れば動いている
   - 以後は `z share` のように末尾の一部を書けば `/usr/share` に飛ぶ。`zi` で候補を fzf で選べる

1. キーを押して、補完と履歴の検索を確かめる。

   - `systemctl star` と打って Tab: `systemctl start ` になる（bash-completion）
   - `ls /usr/s` と打って Tab: 1 回で `sbin/ share/ src/` の一覧が色付きで出る（`show-all-if-ambiguous`・`colored-stats`）
   - `cd /usr/SH` と打って Tab: `cd /usr/share/` になる（`completion-ignore-case`）
   - `printf` と打って ↑: 手順 55 の `printf '%s\n' "$MANPAGER"` の行が出る（`history-search-backward`。カーソルは `printf` の後ろに残る）。Ctrl+C で捨てる
   - `/usr/share` と打って Enter: `cd -- /usr/share` と出て移る（`autocd`）。`cd /usr/shaer` と打って Enter: `/usr/share` と出て移る（`cdspell`）。`cd` で戻る
   - `ls /usr/share/doc/bash-completion/**/*.md` と打って Enter: サブディレクトリの `.md` も出る（`globstar`）
   - `eza --gi` と打って Tab: `--git  --git-ignore  --git-repos  --git-repos-no-status` の一覧が出て、`eza --git` まで入る（Homebrew のコマンドの補完）

1. Ctrl+R を押し、履歴から手順 53 の `fzf --version` を選んで実行する。

   - 画面の下から fzf の一覧が開き、最下行の `>` の右に打った文字で絞り込める。`fzf --v` と打ち、上下キーで `fzf --version` の行を選ぶ
   - Enter でその行がプロンプトに入る（**実行はされない**）。もう一度 Enter で実行する
   - Esc か Ctrl+C で、何も選ばずに閉じる

1. `cat ` と打ってから Ctrl+T を押し、ファイルを選ぶ。

   - 今のディレクトリ（ホーム）の下のファイルの一覧が開く。`.bashrc` と打つと先頭が `.bashrc` になり、Enter でカーソルの位置に入る（`bashrc` だけでは、共通の bash 設定の `.config/bash/bashrc` が先頭に来る）
   - 右側に、選んでいるファイルの中身が bat の行番号と色付きで出る（共通の bash 設定が、bat があるときに入れる）
   - Tab で複数を選べる（選んだ行に印が付き、Enter で全部入る）
   - そのまま Enter で `cat .bashrc` が動く

1. `ls /usr/share/**` と打って Tab を押し、候補から選ぶ。

   - `**` の後の Tab で、`/usr/share/` の下のパスの一覧が開く。`doc/bash` と打つと先頭が `/usr/share/doc/bash/` になり、Enter で `ls /usr/share/doc/bash/` が入る。もう一度 Enter で実行する
   - `**` を付けなければ、今までどおりの補完
   - `ssh **<Tab>` は `~/.ssh/config` と `known_hosts` のホスト名、`export **<Tab>` は変数名の一覧になる

1. Alt+C を押してディレクトリを選んで移り、`cd -` で戻る。

   - 今のディレクトリの下のディレクトリの一覧が開く。選んで Enter で、`builtin cd -- <ディレクトリ>` と表示して移る
   - 端末が Alt を ESC の前置きとして送る設定のときに届く（届かなければ、`ESC` を押してから `c`）
   - `cd -` で元のディレクトリに戻る

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
   - `tmux attach -t work` で、手順 64 の画面に戻る
   - 中で `exit` と打つと、シェルが終わってセッションも終わる。`[exited]` と出てシェルに戻る
   - キーとコマンドは[tmux の使い方の基本](#tmux-の使い方の基本)
   - **次の手順は、`exit` でシェルに戻ってから貼る**（続けて貼ると、tmux の中のシェルへの入力になる）

1. tmux のセッションが残っていないことを確かめる。

   ```bash
   tmux ls
   ```

   - `no server running on /tmp/tmux-<UID>/default` と出る（セッションが 1 つも無くなると、tmux のサーバーも終わる）

1. 再起動する。

   ```bash
   sudo systemctl reboot
   ```

   - 再起動で効くもの: 手順 15 の kdump のメモリー（外したとき）、手順 27 で入れた ibus-anthy（入れたとき）、手順 37 の拡大率、手順 39 のトレイアイコン、手順 25 の Flatseal のメニュー
   - 保存していない文書のあるアプリが開いていると、`Operation inhibited by …` で断られることがある。そのアプリを閉じてから貼り直す
   - **次の手順は、起動してログインしてから行う**

1. ログインした画面で、上部バー・ウィンドウ・Dash が変わったことを確かめる。

   - 上部バーの時計に曜日と秒が出る（電池のある PC では、電池の % も）
   - 上部バーの右に、入力ソースの表示が出る
   - 画面が濃い色（ダーク）になっている。Super キーで開くアクティビティの画面の下の Dash が、手順 41 の並び
   - 端末などのウィンドウのタイトルバーの右に、最小化・最大化・閉じるの 3 つのボタンが出る
   - 「標準フォルダーの名前を現在の言語に合わせて更新しますか?」の窓は出ない。出たら、「次回から表示しない」をオンにして「古い名前のままにする」を押す

1. 端末を開き、再起動の後の状態を確かめる。

   ```bash
   journalctl --list-boots --no-pager | tail -n 2
   cat /sys/kernel/kexec_crash_size
   hostnamectl --static
   xdg-user-dir DOWNLOAD
   ibus list-engine | grep -w anthy
   gnome-extensions info appindicatorsupport@rgcjonas.gmail.com | grep -E '^ *(状態|State)'
   /usr/bin/gsettings get org.gnome.mutter experimental-features
   ```

   - `journalctl --list-boots` に 2 行出る（前の起動のログが残っている。手順 13）
   - `0` が出る（手順 15 で kdump を止めたとき）
   - 手順 10 の名前（変えたとき）と、`/home/<USER>/Downloads` が出る
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
   - Ctrl+Alt+T で、新しい端末の窓が開く

1. 入力ソースを切り替えて、日本語を打ってみる。

   - Super+Space で、上部バーの入力ソースの表示が切り替わる
   - Anthy に切り替えてからテキストエディターなどで `nihongo` と打ち、Space を押すと「日本語」に変わり、Enter で確定する
   - Anthy は、ひらがなで始まる
   - Anthy の中では、半角/全角キー（US 配列なら Ctrl+Space か Ctrl+J）で英字（直接入力）とひらがなを切り替える

1. Files で、フォルダーの名前と、隠しファイルとフォルダーの並びを確かめる。

   - Files（アクティビティの画面で「ファイル」）でホームを開くと、`Desktop`・`Documents`・`Downloads` などの英語の名前のフォルダーが並び、日本語の名前のフォルダーは無い
   - `.bashrc`・`.config` などの隠しファイルも出て、フォルダーがファイルより先に並ぶ
   - 左のサイドバーにも `Documents`・`Downloads` などが並び、押すとそのフォルダーが開く

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
     ssh-keygen -lf ~/.ssh/authorized_keys
   fi
   ```

   - 最後に、足した鍵の fingerprint（`256 SHA256:… (ED25519)`）が出ればよい
   - `restorecon` は、`~/.ssh` の SELinux のラベルを、sshd が読めるものに合わせる

1. つなぐ側の PC から、鍵でログインできることを確かめる。

   - `ssh -o PasswordAuthentication=no <USER>@<IP>` でログインできればよい（パスフレーズを付けた鍵なら、パスフレーズを聞かれる）
   - `Permission denied (publickey,…)` で断られたら、この節の手順 1 の鍵と、つなぐ側の鍵が合っていない。この節の手順 3 へは進まない
   - **次の手順は、鍵でログインできてから貼る**

1. パスワードでの SSH のログインを切る。

   ```bash
   {
     printf 'PasswordAuthentication no\nKbdInteractiveAuthentication no\n' | sudo install -m 0600 /dev/stdin /etc/ssh/sshd_config.d/40-pubkey-only.conf
     sudo sshd -t && sudo systemctl reload sshd
     sudo sshd -T | grep -Ei '^(passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication) '
   }
   ```

   - `passwordauthentication no`・`kbdinteractiveauthentication no`・`pubkeyauthentication yes` が出ればよい
   - sshd は、同じ設定の最初の値を使う。`/etc/ssh/sshd_config.d` のファイルは名前の順に読まれるので、AlmaLinux の `50-redhat.conf` より先に読まれる `40-…` にする
   - `sshd -t` が設定の誤りを見つけたら、reload しない（誤りの行が出る）。今つないでいるセッションは切れない

1. つなぐ側の PC から、パスワードでは断られることを確かめる。

   - `ssh -o PubkeyAuthentication=no <USER>@<IP>` が、パスワードを聞かずに `Permission denied (publickey,gssapi-keyex,gssapi-with-mic).` で断られればよい
   - 鍵（`ssh <USER>@<IP>`）では、そのまま入れる

1. 元に戻すときは、この節の手順 3 のファイルを消し、パスワードでもログインできるようにする。

   ```bash
   {
     sudo rm -f /etc/ssh/sshd_config.d/40-pubkey-only.conf
     sudo sshd -t && sudo systemctl reload sshd
     sudo sshd -T | grep -Ei '^(passwordauthentication|kbdinteractiveauthentication) '
   }
   ```

   - `passwordauthentication yes` と `kbdinteractiveauthentication no`（AlmaLinux 10 の既定）が出ればよい
   - 足した公開鍵は `~/.ssh/authorized_keys` に残る。要らなければ、その行を手で消す

---

## dnf-automatic で自動で更新する（任意）

- BaseOS の `dnf-automatic` のタイマーで、毎日、更新をダウンロードして入れる。再起動はしない（カーネルなどの更新は、[手順 7・8](#実施手順)で自分で再起動する）
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
     systemctl list-timers 'dnf-automatic*' --no-pager
   }
   ```

   - `dnf-automatic-install.timer` の行に、次に動く日時（`NEXT`）が出ればよい
   - 何を入れるか（`upgrade_type`）などは `/etc/dnf/automatic.conf` にある。このタイマーは、その設定の `apply_updates` に関わらず、更新を入れる

1. GNOME Software の自動の更新を止める。

   ```bash
   /usr/bin/gsettings set org.gnome.software download-updates false
   /usr/bin/gsettings get org.gnome.software download-updates
   ```

   - `false` が出ればよい（GNOME Software の「設定」の「自動更新」がオフになる）
   - 更新があることの通知と、手で入れる更新は、そのまま使える

1. 今すぐ 1 回動かして、動くことを確かめる。

   ```bash
   {
     sudo systemctl start dnf-automatic-install.service
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
  - [GNOME のヘッドレスのセッション](gnome-headless-session.md)はこの節の手順 1・2（サスペンドできる PC では手順 3・4 も）、[Claude Code で GUI を確かめる](claude-code-gui.md)は手順 1・2、[GNOME のデスクトップ共有](gnome-desktop-sharing.md)は手順 1〜4 を前提にしている
- **人が触れる場所にある PC では行わない**（画面をロックしないので、前にいる人がそのまま使える）
- GNOME を入れていない（デスクトップの無い）機械では、この節の手順 4・5 だけを行う
- GNOME にログインするユーザー本人の端末で、この節の手順 1 で変数を設定してから、上から順に貼る
- 戻すときは、この節の手順 6〜9。変える前の値ではなく**既定値**に戻る（Server with GUI で入れた PC は、既定でも電源につないでいる間は眠らない）

1. 変数を設定する。

   ```bash
   IDLE_DELAY=0               # 無操作で画面を消すまでの秒数。0 は消さない（GNOME の既定は 300）
   LOCK_ENABLED=false         # 画面が消えたときにロックするか。true / false（既定は true）
   POWER_BUTTON=interactive   # 電源ボタンを押したとき。interactive（電源オフの確認を出す）/ nothing（何もしない）
   for v in USER IDLE_DELAY LOCK_ENABLED POWER_BUTTON; do
     printf '%-12s = %s\n' "$v" "${!v}"
   done
   ```

   - **編集が必須の変数は無い**。既定のままなら、画面を消さず、ロックもしない
   - 最後に値を読み戻して確かめる
   - `USER` が `root` になっているなら、ここで止めて、自分のユーザーのシェルで貼り直す
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**（SSH を張り直したあとも）、この節の手順 1 のブロックを貼り直してから先へ進む

1. 自分のセッションの画面オフ・減光・ロック・自動サスペンド・電源ボタンを変える。

   ```bash
   /usr/bin/gsettings set org.gnome.desktop.session idle-delay "${IDLE_DELAY:?この節の手順 1 の IDLE_DELAY が空のまま。値を入れて貼り直す}"
   /usr/bin/gsettings set org.gnome.desktop.screensaver lock-enabled "${LOCK_ENABLED:?この節の手順 1 の LOCK_ENABLED が空のまま。値を入れて貼り直す}"
   /usr/bin/gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
   /usr/bin/gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type nothing
   /usr/bin/gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type nothing
   /usr/bin/gsettings set org.gnome.settings-daemon.plugins.power power-button-action "${POWER_BUTTON:?この節の手順 1 の POWER_BUTTON が空のまま。値を入れて貼り直す}"
   /usr/bin/gsettings get org.gnome.desktop.session idle-delay
   /usr/bin/gsettings get org.gnome.desktop.screensaver lock-enabled
   /usr/bin/gsettings list-recursively org.gnome.settings-daemon.plugins.power | grep -E 'idle-dim|sleep-inactive-(ac|battery)-type|power-button-action'
   ```

   - 最後の 3 つのコマンドで読み戻す
   - `uint32 0`、`false`、続いて `idle-dim false`・`power-button-action 'interactive'`・`sleep-inactive-ac-type 'nothing'`・`sleep-inactive-battery-type 'nothing'` の 4 行が出ればよい
   - 値が変わっていなければ、デスクトップの端末でこの節の手順 1 から貼り直す（`gsettings` は書けなかったときも終了コード 0 で終わる。[検証記録](verification/almalinux-setup.md#画面オフロックサスペンド-実施手順--手順-2-補足-変える前の値0-にしても暗くなる理由設定アプリの項目)・[参考資料](reference/almalinux-setup.md#選択した方針)）
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
     sudo dconf update
     sudo -u gdm env DCONF_PROFILE=gdm /usr/bin/gsettings list-recursively org.gnome.settings-daemon.plugins.power | grep -E 'sleep-inactive-(ac|battery)-type|power-button-action'
   fi
   ```

   - ファイルには、自動サスペンドと電源ボタンの設定を書く
   - 文字列の値は引用符（`'`）で囲む。囲まないと、`dconf update` が失敗する
   - `dconf update` は、成功すると何も出さない。`invalid value` と出たら、この手順を貼り直す
   - `power-button-action 'interactive'`・`sleep-inactive-ac-type 'nothing'`・`sleep-inactive-battery-type 'nothing'` の 3 行が出ればよい
   - `中断:` と出たら、何も書いていない

1. OS 全体で、サスペンドとハイバネートを止める。

   ```bash
   {
     sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
     systemctl is-enabled sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
   }
   ```

   - `Created symlink '/etc/systemd/system/sleep.target' → '/dev/null'.` のような行が 5 つ出て、`masked` が 5 行出ればよい
   - GNOME のメニュー・蓋・電源ボタンなど、どこから頼まれてもサスペンドが始まらなくなる
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
     busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager HandleLidSwitch
   }
   ```

   - `s "ignore"` と出ればよい（既定は `s "suspend"`）
   - 蓋の無い PC では何も変わらない（置いても害は無い）

1. 元に戻すときは、自分のセッションの値を既定値に戻す。

   ```bash
   /usr/bin/gsettings reset org.gnome.desktop.session idle-delay
   /usr/bin/gsettings reset org.gnome.desktop.screensaver lock-enabled
   /usr/bin/gsettings reset org.gnome.settings-daemon.plugins.power idle-dim
   /usr/bin/gsettings reset org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type
   /usr/bin/gsettings reset org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type
   /usr/bin/gsettings reset org.gnome.settings-daemon.plugins.power power-button-action
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
     sudo -u gdm env DCONF_PROFILE=gdm /usr/bin/gsettings list-recursively org.gnome.settings-daemon.plugins.power | grep -E 'sleep-inactive-(ac|battery)-type|power-button-action'
   }
   ```

   - 3 行とも `'suspend'` になればよい

1. 元に戻すときは、続けてサスペンドとハイバネートの mask を外す。

   ```bash
   {
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
     busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager HandleLidSwitch
   }
   ```

   - `s "suspend"` と出ればよい
   - 空の `/etc/systemd/logind.conf.d` は残る

---

## Wake on LAN を使う（任意）

- 電源を切った（シャットダウンした）この PC を、LAN の別の PC から起こせるようにする。有線 LAN だけ（Wi-Fi では使えない）
- **この節の手順 3 で再起動して UEFI の画面に入り、この節の手順 4 は UEFI の画面、この節の手順 7 は LAN の別の PC で行う**
- 仮想マシンでは、電源を切った VM は起こせない（VirtualBox など）

1. 変数を設定する（どちらも自動）。

   ```bash
   LAN_CON=$(nmcli -g NAME,TYPE connection show --active | awk -F: '$2 == "802-3-ethernet" { print $1; exit }')   # 有線 LAN の接続（自動）。<LAN_CON>
   LAN_IF=$(nmcli -g GENERAL.DEVICES connection show "${LAN_CON}" 2>/dev/null)   # その機器（自動）。<LAN_IF>
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
     nmcli -g 802-3-ethernet.wake-on-lan connection show "${LAN_CON}"
     sudo ethtool "${LAN_IF}" | grep -i 'wake-on'
     ip -brief link show "${LAN_IF}"
   fi
   ```

   - `magic` と、`Supports Wake-on:` の文字に `g` があり、`Wake-on: g` が出ればよい（`g` がマジック パケット）
   - 最後の行の `xx:xx:xx:xx:xx:xx` が MAC アドレス。この節の手順 7 で使うので控える
   - `Supports Wake-on:` に `g` が無ければ、この LAN のアダプターは Wake on LAN を使えない
   - `Wake-on: d` のままなら、アダプターのドライバが設定を受け付けていない。この節の手順 5 で、起動の後にもう一度見る（VirtualBox の VM の e1000 は、`Supports Wake-on: umbg` でも `d` のままだった）

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
     nmcli -g 802-3-ethernet.wake-on-lan connection show "${LAN_CON}"
   fi
   ```

   - `default` が出ればよい。UEFI の設定は、この節の手順 4 の画面で戻す

---

## WezTerm と HackGen Console NF をデスクトップで使う（任意）

- 前提: [HackGen Console NF](hackgen.md) と [WezTerm](wezterm-nightly.md) の実施手順を通してあること（どちらか一方だけなら、その手順だけを行う）
- WezTerm 自身のフォントは、[hackgen.md の WezTerm で使う（任意）](hackgen.md#wezterm-で使う任意)で変える
- 戻すときは、この節の手順 4

1. HackGen Console NF を入れたときだけ、GNOME の等幅のフォントにする。

   ```bash
   MONO_FONT='HackGen Console NF 11'   # 等幅のフォントの名前と大きさ。<MONO_FONT>
   ```

   ```bash
   if [ -z "${MONO_FONT}" ]; then echo '中断: MONO_FONT が空のまま。値を入れて貼り直す' >&2; else
     /usr/bin/gsettings get org.gnome.desktop.interface monospace-font-name
     /usr/bin/gsettings set org.gnome.desktop.interface monospace-font-name "${MONO_FONT}"
     /usr/bin/gsettings get org.gnome.desktop.interface monospace-font-name
   fi
   ```

   - 等幅のフォントは、端末の Ptyxis などが使う
   - 最初の `get` は変える前の値（AlmaLinux 10 の既定は `'Red Hat Mono Regular 10'`）
   - 2 つ目の `get` が `'HackGen Console NF 11'` になればよい。Ptyxis は既定でこのフォントを使うので、開いている端末もすぐに変わる

1. WezTerm を入れたときだけ、Ctrl+Alt+T と Dash のお気に入りの端末を WezTerm にする。

   ```bash
   kb=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal/
   /usr/bin/gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}" command 'wezterm start'
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

1. 元に戻すときは、等幅のフォント・Ctrl+Alt+T・お気に入りを戻す。

   ```bash
   kb=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal/
   /usr/bin/gsettings reset org.gnome.desktop.interface monospace-font-name
   /usr/bin/gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}" command 'ptyxis --new-window'
   fav=$(/usr/bin/gsettings get org.gnome.shell favorite-apps)
   /usr/bin/gsettings set org.gnome.shell favorite-apps "${fav//org.wezfurlong.wezterm.desktop/org.gnome.Ptyxis.desktop}"
   /usr/bin/gsettings get org.gnome.desktop.interface monospace-font-name
   /usr/bin/gsettings get "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}" command
   /usr/bin/gsettings get org.gnome.shell favorite-apps
   ```

   - `'Red Hat Mono Regular 10'`・`'ptyxis --new-window'` と、端末のところが `'org.gnome.Ptyxis.desktop'` のお気に入りが出ればよい

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
| `brew uninstall <formula>` | 消す。Homebrew 7.0.7 では、不要になった依存も既定で自動削除する（[注意点](#注意点)） |
| `brew list --versions` | 入っているものと版の一覧 |
| `brew leaves` | ほかの導入済み formula や cask から依存されていない formula の一覧。明示的に入れたものの履歴ではない |
| `brew info <formula>` | 版・依存・caveat（[gdu](gdu.md) のような名前の注意書き） |
| `brew deps --tree <formula>` | 依存の木。単独で入れたときに何が付いてくるか |
| `brew outdated` | 更新できるものの一覧。何も無ければ無出力 |
| `brew autoremove` | 依存として入って、もう誰も使っていないものを消す（`--dry-run` で確認できる） |

- `brew install`・`brew upgrade` などの管理操作は、Homebrew を入れた一般ユーザーで行う。通常のホストでは root での実行を断られる（`brew --version` などの例外は[検証記録](verification/almalinux-setup.md#統合前の記録-homebrewもとは-homebrewmd)）
- `sudo brew ...` は、sudo の PATH に Homebrew が無ければ `command not found` になる。[Homebrew を sudo でも使う（任意）](#homebrew-を-sudo-でも使う任意)の節を通しても、管理操作は一般ユーザーで行う
- 入れたコマンドを root のシェルでも使うなら [Homebrew を root のシェルでも使う（任意）](#homebrew-を-root-のシェルでも使う任意)の節を、`sudo <コマンド>` で使うなら [Homebrew を sudo でも使う（任意）](#homebrew-を-sudo-でも使う任意)の節を通す
- Homebrew 7.0.7 の `brew install` は、端末で依存や依存先も導入する計画なら `[y/n]` を聞く。指定したものだけの計画、または端末を使わない実行では聞かない（[注意点](#注意点)）
- Homebrew で入れるほかの手順書（[yazi](yazi.md)、[lazygit](lazygit.md)、[Neovim](neovim.md)、[git-delta](git-delta.md)、[gdu](gdu.md)、[ShellCheck / shfmt](shellcheck.md)、[Syncthing](syncthing.md)、[HackGen Console NF](hackgen.md)、[Dropbox（rclone）](dropbox-rclone.md)、[hadolint / dive / Trivy](image-tools.md)（Trivy だけは dnf）、[lazydocker](lazydocker.md)）は、[手順 46〜48](#実施手順) を前提にする

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
   - Homebrew 自体を削除した場合は、共通設定が自動で読み込みを省略する

---

## Homebrew を sudo でも使う（任意）

- **`sudo <コマンド>` で Homebrew のコマンドを使わないなら、この節は不要**
- sudo の設定に 1 行のファイル（`/etc/sudoers.d/homebrew`）を置き、sudo がコマンドを探す PATH（`secure_path`）の末尾に、Homebrew の `bin` と `sbin` を足す
- `sudo nvim /etc/hosts` や `sudo gdu-go /` のように、`sudo <コマンド>` で使えるようになる。`sudo -s`・`sudo -i` で開いた root のシェルでも使える
- `EDITOR=nvim` の `sudoedit` も、自分の設定の Homebrew の `nvim` で開くようになる（この節の前は、黙って `vi` で開く）
- sudo を通らない `su -`、コンソールや ssh での root のログインには効かない。そちらは [Homebrew を root のシェルでも使う（任意）](#homebrew-を-root-のシェルでも使う任意)の節を通す
- RPM にも同じ名前のコマンドがあると、`sudo` では RPM のほうが使われる
- `brew install` などの管理操作は、この節を通しても一般ユーザーで行う（通常のホストでは `sudo brew install` などを `Running Homebrew as root is extremely dangerous …` で断られる）
- [手順 46〜48](#実施手順) を終えた、Homebrew を入れたユーザーのシェルで貼る
- 補足: [参考資料](reference/almalinux-setup.md#homebrew-sudo-で使うときの補足)

> [!WARNING]
> - `/home/linuxbrew/.linuxbrew` は Homebrew を入れたユーザーの所有。`sudo` で打ったコマンドが `/usr/bin` などに無いと、そのユーザーが書き換えられるプログラムを root の権限で動かすことになる（そのユーザーを乗っ取られると、root まで取られる）
> - sudo の設定はホスト全体にかかる。このホストで `sudo` を使う、ほかのユーザーにも効く

1. sudo の `secure_path` の末尾に Homebrew を足すファイルを置き、`sudo` の PATH を確かめる。

   ```bash
   {
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
     - `/etc/sudoers.d` にほかのファイル（[手順 3](#実施手順) の `nopasswd` など）があれば、その行も出る
     - 日本語のロケール（`ja_JP.UTF-8`）では、`parsed OK` は `正しく構文解析されました` と出る
   - 最後の 2 行で、PATH の末尾が `:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin` で、`/home/linuxbrew/.linuxbrew/bin/brew` が出ればよい
   - `中断:` と出たら、何も書き換えていない（最後の 2 行は出る）
     - `既にある` なら、この節は通してある。最後の 2 行で確かめる
     - `既定と違う` なら、`secure_path` がほかで変えてある（`sudo grep -rn secure_path /etc/sudoers /etc/sudoers.d` で探す）。そのホストでは、この節は使わない
   - Homebrew で入れたコマンドを、`sudo jq --version` のように打てる
   - `sudo` でどれが使われるかは、`sudo bash -c 'type -a <コマンド>'` で見る（先頭の行が使われる）
   - 開いたままの root のシェル（`sudo -s` など）には効かない。開き直す

1. 元に戻すときは、この節の手順 1 で置いたファイルを消す。

   ```bash
   {
     sudo rm -f /etc/sudoers.d/homebrew
     sudo printenv PATH   # /sbin:/bin:/usr/sbin:/usr/bin
   }
   ```

   - 最後に `/sbin:/bin:/usr/sbin:/usr/bin` と出ればよい
   - 開いたままの root のシェル（`sudo -s` など）の PATH には残る。開き直すと消える
   - [Homebrew を root のシェルでも使う（任意）](#homebrew-を-root-のシェルでも使う任意)の節も通していれば、root のシェル（`sudo -i` も）では、root の共通の bash 設定が Homebrew を PATH に入れたまま

---

## starship のプリセットを当てる（任意）

- 公式が配っている設定一式を `~/.config/starship.toml` に書き出す
- **この節の手順 2 で、既存の設定は上書きされる**。自分で書いたものがあれば、先に退避する
- [手順 50](#実施手順) で開き直した端末（starship を読み込んだ端末）で貼る

1. 当てられるプリセットの一覧を見る。

   ```bash
   starship preset --list
   ```

   - `plain-text-symbols` と `no-nerd-font` は**Nerd Font が無い端末向け**で、記号を ASCII に置き換える
   - `nerd-font-symbols` / `pastel-powerline` / `gruvbox-rainbow` などは Nerd Font が要る（[HackGen Console NF](hackgen.md) など）
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

   - 設定ファイルの変更だけなら `~/.bashrc` を読み直す必要はない。starship は設定ファイルをプロンプトのたびに読むので、次のプロンプトから変わる
   - `--force` は既存のファイルを置き換える。付けないと既存設定がある場合に拒否されるので、節の先頭のとおり先に退避する
   - 共通設定は初期化済みの starship を再初期化しない。手で `eval "$(starship init bash)"` を重ねると `PS0` が重複するため、追加で実行しない

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
   - `starship config` で `$EDITOR` が開く
   - 設定の場所を変えたいときは、starship 自身が読む環境変数 `STARSHIP_CONFIG` を `~/.bashrc` で `export` する

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
   starship module username
   starship module hostname
   ```

   - 既存の設定を保ち、常時表示に必要な 2 項目だけを更新する。設定ファイルが無ければ作られる
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
- 共通の bash 設定が、fd があるときに候補の `FZF_*` の 3 つの変数を入れる。Ctrl+T の右側の bat のプレビュー（`FZF_CTRL_T_OPTS`）は、bat があれば入るので、[手順 49](#実施手順) の後から出ている。`~/.bashrc` への追記は要らない
- `**<Tab>` の候補は変わらない（`find` のまま）
- bat は[手順 49](#実施手順) で入れてある。fd は、この節の手順 1 で入れる（[yazi.md 手順 2](yazi.md#実施手順) の `YAZI_EXTRAS` で入れてあれば飛ばす）
- 戻すときは、この節の手順 5

1. brew で fd を入れる。

   ```bash
   brew install fd
   ```

   - 確認が出たら `y`（Enter は要らない）
   - EPEL の `fd-find` と二重に入れない（どちらも `fd` で、PATH の先頭の Homebrew 版が使われる）
   - **次の手順は、プロンプトに戻ってから行う**

1. 開いている端末を閉じて、開き直す。

   - 共通の bash 設定は、端末を開くときに fd と bat を見つけて変数を入れる
   - **次の手順は、開き直した端末で貼る**

1. fd と bat があり、変数が入ったか確かめる。

   ```bash
   command -v fd bat
   printf '%s\n' "${FZF_DEFAULT_COMMAND-}" "${FZF_CTRL_T_COMMAND-}" "${FZF_ALT_C_COMMAND-}" "${FZF_CTRL_T_OPTS-}"
   ```

   - 2 つのパスと、`fd` を使う候補の 3 変数・`bat` を使うプレビューの変数が出ればよい

1. `cat ` と打ってから Ctrl+T を押し、候補が fd の一覧になったことを確かめる。

   - `.git` の中のファイルと、`.gitignore` に書かれたファイルは一覧に出ない
   - 一覧の右側に、選んでいるファイルの中身が行番号と色付きで出る。Esc で閉じる
   - コマンドの中で同じプレビューを使うなら、`fzf --preview 'bat --color=always --style=numbers {}'`

1. 元に戻すときは、fd を消す。

   ```bash
   brew uninstall fd
   ```

   - `Uninstalling /home/linuxbrew/.linuxbrew/Cellar/fd/…` と出ればよい
   - 開き直した端末から、共通の bash 設定は候補の 3 つの変数を入れず、候補は fzf の既定の一覧に戻る
   - [yazi.md 手順 2](yazi.md#実施手順) の `YAZI_EXTRAS` で fd を入れてあれば、消さない（yazi の検索が使う）

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
     cat ~/.config/bat/config
     bat --config-file
   fi
   ```

   - 書いた 3 行と、`/home/<USER>/.config/bat/config` が出ればよい
   - テーマの一覧は `bat --list-themes`、認識する言語の一覧は `bat --list-languages`
   - 自前のシンタックス定義やテーマを足したときだけ `bat cache --build` が要る（キャッシュの場所は `bat --cache-dir`）
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

- OS（BaseOS・AppStream・EPEL・RPM Fusion から入れたもの。`epel-release`・`rpmfusion-free-release` とトレイアイコンの拡張も）は、[手順 4・7・8](#実施手順)を貼り直す。ファームウェアは[手順 5・6](#実施手順)
- [dnf-automatic で自動で更新する（任意）](#dnf-automatic-で自動で更新する任意)を通したなら、OS の更新は毎日自動で入る（再起動は手順 7・8 で自分で行う）
- EPEL の鍵をまだ取り込んでいなければ、`epel-release` が上がるときに確認を求められる（fingerprint は[手順 17](#実施手順)）
- Flatpak のアプリは `dnf upgrade` では上がらない（この節の手順 4）
- 別の手順書で入れたもの（Git・Firefox・HackGen Console NF・WezTerm・Claude Code・Codex CLI など）は、それぞれの手順書の「更新」
- この節の手順は、[手順 50](#実施手順) と同じ、開き直した端末に貼る

1. 共通の bash 設定を上げる。

   ```bash
   git -C ~/.config/bash pull --ff-only &&
     bash ~/.config/bash/install.sh
   ```

   - `Already up to date.`（上がったときは、変わったファイルの一覧）が出る
   - 上がったときは、端末を開き直すと効く

1. Homebrew 自身と formula の索引を更新し、上げられるものを見る。

   ```bash
   brew update
   brew outdated
   ```

   - `brew update` が `Already up-to-date.` を返し、`brew outdated` が無出力なら、上げるものは無いので、この節の手順 3 は飛ばす
   - **`brew install` / `brew upgrade` は既定で自動更新が走る**ので、普段は `brew update` を明示しなくてよい（抑えるには `HOMEBREW_NO_AUTO_UPDATE=1`）
   - インターネットに出られないホストでは、[homebrew-offline.md の更新](homebrew-offline.md#更新)で行う

1. 上げるものがあるときだけ、入れたものを上げる。

   ```bash
   brew upgrade
   ```

   - 特定のものだけなら `brew upgrade <formula>`
   - `[y/n]` と聞かれたら、`y` を押す（Enter は要らない。[注意点](#注意点)）
   - 動いている tmux のサーバーは、前の版のまま動き続ける。新しい版を使うのは、セッションを全部閉じて `tmux ls` が `no server running on …` になってから
   - fzf は、開いているシェルには前の版の `fzf --bash` が読まれたまま。新しい端末から新しい版になる。zoxide のデータベース（`~/.local/share/zoxide/db.zo`）は更新で消えない

1. Flatpak で入れたアプリを上げる。

   ```bash
   sudo flatpak update
   ```

   - 更新が無ければ `Nothing to do.` で終わる
   - 更新があれば `[Y/n]` と聞かれる。`y`

---

## ロールバック

- 残す項目の手順は飛ばす。項目ごとのこの節の手順
  - 表示と入力: ダークモードは 1、ボタンは 2、時計と電池は 3、Files は 4、Alt+Tab は 5、ホットコーナーは 6、Caps Lock は 7、拡大率は 8、Ctrl+Alt+T は 9、Dash のお気に入りは 10、トレイアイコンは 11・12
  - 日本語入力: 入力ソースは 13、ibus-anthy は 14。フォルダーの名前は 15
  - シェル: tmux のセッションは 16、履歴の控えは 17、ツールは 18・19（Homebrew ごと消すなら飛ばしてよい）、ツールの設定とキャッシュは 20、`~/.inputrc` は 21、共通の bash 設定は 22・23、Homebrew は 24〜26、bash-completion は 27
  - 導入元: Flathub は 28〜31、RPM Fusion は 32・33、EPEL は 34・35
  - PC 全体: パッケージの案内は 36、kdump は 37、journal は 38、PC の名前は 39、再起動と確かめは 40・41、sudo は 42
- 拡大率を 100% 以外にしていたら、この節の手順 8 の前に、設定の「ディスプレイ」の「スケーリング」で 100% に戻す
- gsettings の値は、変える前の値ではなく**既定値**に戻る。手順 28・41 で控えた値に戻すなら、`reset` の代わりに `set` を使う
- OS とファームウェアの更新、SSH（Workstation の既定のまま）、手順 46 の依存パッケージは戻さない
- 任意節で変えたものは、その節の最後の「元に戻すときは」の手順で戻す。[Homebrew を sudo でも使う（任意）](#homebrew-を-sudo-でも使う任意)を通したなら、先にその節の手順 2 を行う
- 別の手順書で入れたものは、それぞれの手順書のロールバックで先に戻す（Homebrew を消す前に HackGen Console NF などの Homebrew のもの、RPM Fusion を消す前に [firefox.md のロールバック](firefox.md#ロールバック)の手順 1 の FFmpeg）
- **EPEL・RPM Fusion を消しても、そこから入れたパッケージ（btop・distrobox・podman-compose・podman-tui・VirtualBox の `liblzf`・Firefox の FFmpeg など）は残り、更新されなくなる**。要らないものは、先に各手順書のロールバックで消す
- 手順 1〜23 は、手順 50 と同じ、開き直した端末に貼る

> [!CAUTION]
> **この節の手順 25 は、Homebrew で入れたものを全部消す**（この文書の外で入れた yazi・Neovim・HackGen Console NF なども）。**この節の手順 38 は、ディスクに残した journal（前の起動のログ）を消す**。**この節の手順 22 の後に閉じたシェルは、`~/.bash_history` を既定の 1,000 行に切り詰める**（残す履歴は、この節の手順 17 で控える）。どれも取り戻せない。

1. ダークモードを既定（淡色）に戻す。

   ```bash
   /usr/bin/gsettings reset org.gnome.desktop.interface color-scheme
   /usr/bin/gsettings get org.gnome.desktop.interface color-scheme
   ```

   - `'default'` が出ればよい

1. ウィンドウのボタンを既定に戻す。

   ```bash
   /usr/bin/gsettings reset org.gnome.desktop.wm.preferences button-layout
   /usr/bin/gsettings get org.gnome.desktop.wm.preferences button-layout
   ```

   - `'appmenu:close'` が出ればよい

1. 時計と電池の表示を既定に戻す。

   ```bash
   /usr/bin/gsettings reset org.gnome.desktop.interface clock-show-weekday
   /usr/bin/gsettings reset org.gnome.desktop.interface clock-show-seconds
   /usr/bin/gsettings reset org.gnome.desktop.interface show-battery-percentage
   /usr/bin/gsettings list-recursively org.gnome.desktop.interface | grep -E 'clock-show-(weekday|seconds)|show-battery-percentage'
   ```

   - 3 行とも `false` が出ればよい

1. Files とファイルを選ぶ窓の表示を既定に戻す。

   ```bash
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
   /usr/bin/gsettings list-recursively org.gnome.desktop.wm.keybindings | grep -E 'switch-(applications|windows)'
   ```

   - `switch-applications ['<Super>Tab', '<Alt>Tab']` と、`switch-windows @as []` などの 4 行が出ればよい

1. ホットコーナーを既定（有効）に戻す。

   ```bash
   /usr/bin/gsettings reset org.gnome.desktop.interface enable-hot-corners
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
   /usr/bin/gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings
   /usr/bin/dconf dump "${kb}"
   ```

   - `@as []`（ほかのショートカットがあれば、その一覧）が出て、最後の `dconf dump` が何も出さなければよい

1. Dash のお気に入りを既定に戻す。

   ```bash
   /usr/bin/gsettings reset org.gnome.shell favorite-apps
   /usr/bin/gsettings get org.gnome.shell favorite-apps
   ```

   - `['firefox.desktop', 'org.gnome.Calendar.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Software.desktop', 'org.gnome.Ptyxis.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Calculator.desktop']`（Workstation の既定）が出ればよい
   - 手順 41 で控えた並びに戻すなら、`reset` の代わりに `/usr/bin/gsettings set org.gnome.shell favorite-apps "<控えた値>"` を貼る（`<控えた値>` を置き換える）

1. トレイアイコンの拡張を無効にする。

   ```bash
   e=$(/usr/bin/gsettings get org.gnome.shell enabled-extensions)
   /usr/bin/gsettings set org.gnome.shell enabled-extensions "$(printf '%s' "${e}" | sed -e "s/, 'appindicatorsupport@rgcjonas.gmail.com'//" -e "s/'appindicatorsupport@rgcjonas.gmail.com', //" -e "s/\['appindicatorsupport@rgcjonas.gmail.com'\]/@as []/")"
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
   /usr/bin/gsettings get org.gnome.desktop.input-sources sources
   ```

   - `@a(ss) []`（既定値）になればよい
   - 手順 28 で控えた値に戻すなら、`/usr/bin/gsettings set org.gnome.desktop.input-sources sources "<控えた値>"` を貼る（`<控えた値>` を置き換える）

1. 手順 27 で ibus-anthy を入れたときだけ、ibus-anthy を消す。

   ```bash
   sudo dnf remove ibus-anthy
   ```

   - `anthy-unicode`・`ibus-anthy-python`・`kasumi-common`・`kasumi-unicode` も一緒に消える。`ibus` 本体と、手順 27 で入ったフォントは残る
   - 最初から入っていた PC（Workstation）では貼らない
   - **次の手順は、`[y/N]` に `y` と答えて、プロンプトに戻ってから貼る**

1. フォルダーの名前を日本語に戻すときだけ、英語の名前のフォルダーを日本語の名前に戻す（中身ごと移す）。

   ```bash
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

   - 手順 29 と同じ形で、`/home/<USER>/Downloads → /home/<USER>/ダウンロード` のような行が 8 つ出る
   - `user-dirs.dirs` の 8 行が日本語の名前に戻ればよい

1. tmux のセッションを全部終わらせる。

   ```bash
   tmux kill-server
   ```

   - 何も出ないか、`no server running on …` と出ればよい
   - tmux のセッションの中で動かしているもの（Claude Code など）も止まる。残したいものがあれば、先に終える

1. 履歴のファイルを控える。

   ```bash
   cp -p ~/.bash_history ~/.bash_history.bak
   wc -l ~/.bash_history.bak
   ```

   - 行数が出る。要らなくなったら `~/.bash_history.bak` は手で消す

1. starship・zoxide・eza・bat・tmux を消す。

   ```bash
   brew uninstall starship zoxide eza bat tmux
   ```

   - Homebrew ごと消すなら、この手順と手順 19 は飛ばしてよい（手順 25 で全部消える）
   - 残すツールは、名前を外してから貼る
   - 依存は、ほかの formula（[git-delta](git-delta.md) など）が必要とする間は残る。Homebrew 7 では、不要になった依存は自動で削除される（`Autoremoving … unneeded formulae:`）
   - 同じシェルでは、`command -v tmux` などがまだ前のパスを返す（bash が覚えている）。`hash -r` の後か新しいシェルでは、何も返さない
   - starship を消した後のこの端末では、プロンプトを出すたびに `-bash: /home/linuxbrew/.linuxbrew/bin/starship: そのようなファイルやディレクトリはありません` と出て、プロンプトの文字が消える。コマンドは動くので、この節の手順 23 で端末を開き直すまで、そのまま貼ってよい

1. fzf を使うツールがほかに無いときだけ、fzf を消す。

   ```bash
   brew uninstall fzf
   ```

   - fzf の実行ファイルは、zoxide の `zi` と [yazi](yazi.md) の絞り込みにも使う。それらを使うなら消さない
   - キー操作だけを無効にする場合は bash リポジトリ側を変更する。`~/.bashrc` に重ねて設定しない

1. ツールの設定・キャッシュ・履歴も消すときだけ、消す。

   ```bash
   rm -f ~/.config/starship.toml ~/.config/tmux/tmux.conf
   rm -rf ~/.cache/starship ~/.local/share/zoxide ~/.config/bat ~/.cache/bat
   ```

   - zoxide の履歴（`~/.local/share/zoxide/db.zo`）は、残しておけば、入れ直したときにそのまま使える

1. 手順 45 で作った `~/.inputrc` を消す。

   ```bash
   rm -f ~/.inputrc
   ```

   - 手順 45 が `中断:` で、すでにあった `~/.inputrc` に手で足したホストでは、足した行だけを手で消す

1. 共通の bash 設定も戻すときだけ、bash リポジトリの設定を戻す。

   - [bash のロールバック](https://github.com/ryo-aoki-pc/bash/blob/main/docs/quick-start.md#ロールバック)を参照する。ほかのツールの共通設定も外れる
   - ツールを消しただけなら、共通設定は残してよい（入っていないツールの設定は読まない）

1. 開いている端末を閉じて、開き直す。

   - 削除したツールの設定は、次のシェルでは共通設定から読み込まれない
   - 今のシェルには `bind -f` した設定と `shopt` が残っている。新しいシェルで効く

1. Homebrew を消す前に、何が消えるか見る。

   ```bash
   /home/linuxbrew/.linuxbrew/bin/brew leaves
   /home/linuxbrew/.linuxbrew/bin/brew list --versions | wc -l
   curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh -o /tmp/uninstall.sh
   bash /tmp/uninstall.sh --dry-run
   ```

   - `brew` はフルパスで呼ぶ（この節の手順 22 で共通の bash 設定を戻した後は、`brew` が PATH に無い）
   - 公式のアンインストーラを `/tmp/uninstall.sh` に落として、**まず `--dry-run` で何が消えるか見る**
   - `brew leaves` に出るものは、すべて使えなくなる
   - **次の手順は、内容を確かめてから貼る**

1. Homebrew のアンインストーラを本実行する（取り戻せない）。

   ```bash
   bash /tmp/uninstall.sh
   ```

   - `Are you sure you want to uninstall Homebrew? … [y/N]` と聞かれる。`y`
   - 終わりに `==> Homebrew uninstalled!` と、消さなかったファイルの一覧（`The following possible Homebrew files were not deleted:` の後の `/home/linuxbrew/.linuxbrew/etc/` など）が出る。残りは、この節の手順 26 で消す
   - インターネットに出られないホストでは、[ssh-socks-tunnel.md 手順 1〜3](ssh-socks-tunnel.md#実施手順) でトンネルを張ったシェルで、この節の手順 24 から貼る
   - **次の手順は、アンインストーラが終わってから貼る**（続けて貼ると確認として食われる）

1. アンインストーラと、残った `/home/linuxbrew` を消して、端末を開き直す。

   ```bash
   {
     rm -f /tmp/uninstall.sh
     sudo rm -rf /home/linuxbrew
     ls -ld /home/linuxbrew
   }
   ```

   - アンインストーラは、formula が置いた設定のファイル（`etc/` の証明書・openssl・dbus の設定など）を残す。`/home/linuxbrew` ごと消す
   - 最後に `ls: '/home/linuxbrew' にアクセスできません: そのようなファイルやディレクトリはありません` と出ればよい
   - 共通設定は Homebrew が無ければ何もしない。`~/.bashrc` の編集は不要

1. 手順 44 で bash-completion を入れたホストだけ、RPM を消す。

   ```bash
   sudo dnf remove bash-completion
   ```

   - `削除中:` に `bash-completion`、`未使用の依存関係の削除:` に `pkgconf` 系の 4 つが出る。`[y/N]` に `y`
   - 最初から入っていたホスト（Workstation）では貼らない
   - **次の手順は、`y` と答えてプロンプトに戻ってから行う**

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

   - 鍵は、EPEL からパッケージを入れたことがあるとき（手順 38）だけ登録されている

1. コマンドが無いときにパッケージを案内する機能を、入れ直す。

   ```bash
   sudo dnf install -y PackageKit-command-not-found
   ```

   - 開き直した端末から、無いコマンドを打つと、パッケージを探して案内する

1. 手順 15 で kdump を止めたときだけ、元に戻す（効くのは再起動の後）。

   ```bash
   {
     sudo sed -i 's/^auto_reset_crashkernel no$/auto_reset_crashkernel yes/' /etc/kdump.conf
     sudo kdumpctl reset-crashkernel --kernel=ALL
     sudo systemctl enable kdump
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
     ls -ld /var/log/journal /run/log/journal
   }
   ```

   - `/var/log/journal` が無い（`アクセスできません`）と、`/run/log/journal` の行が出ればよい
   - `/var/log/journal` を残すと、既定の `Storage=auto` のまま、ディスクに書き続ける
   - `journalctl --relinquish-var` で、journald に `/var/log/journal` を手放させてから消す（手放させずに消すと、動いている journald がすぐに作り直し、再起動の後もディスクに書き続けた）

1. 手順 10 で PC の名前を変えたときだけ、元の名前に戻す（`OLD_HOST_NAME` は必ず値を入れる）。

   ```bash
   OLD_HOST_NAME=''   # 手順 10 で控えた「変える前:」の名前。<HOSTNAME>
   ```

   ```bash
   if [ -z "${OLD_HOST_NAME}" ]; then echo '中断: OLD_HOST_NAME が空のまま。手順 10 で控えた名前を入れて貼り直す' >&2; else
     sudo hostnamectl hostname "${OLD_HOST_NAME}"
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
   cat /sys/kernel/kexec_crash_size
   journalctl --list-boots --no-pager
   hostnamectl --static
   xdg-user-dir DOWNLOAD
   ```

   - この節の手順 37 を行ったなら、0 でない数（`268435456` など）が出る
   - `journalctl --list-boots` は、見出しの行（`IDX BOOT ID …`）と、`0` で始まる今の起動の 1 行だけ
   - この節の手順 39 の名前と、この節の手順 15 を行ったなら日本語の名前（`/home/<USER>/ダウンロード`）が出る
   - 画面は淡色で、時計は時刻だけ、ウィンドウのボタンは閉じるだけに戻る

1. sudo のパスワード無しの設定を外す。

   ```bash
   {
     sudo rm -f /etc/sudoers.d/nopasswd
     sudo -k
     sudo -n true 2>&1 || true
   }
   ```

   - `sudo: パスワードが必要です`（英語の環境では `a password is required`）が出ればよい
   - この手順の後は、`sudo` がパスワードを聞く。そのため、この節の最後に行う

---

## 注意点

- **パスワードを聞かない sudo**: [手順 3](#実施手順) の後は、このユーザーで動くものがパスワード無しで root の権限を使える（リードの `[!WARNING]`）。外すのは[ロールバック](#ロールバック)の手順 42
- **アプリが再起動を止めることがある**: `sudo systemctl reboot` が `Operation inhibited by …` で断られたら、保存していない文書のあるアプリを閉じてから貼り直す
- **PC の名前を変えた後**: 開いている端末のプロンプトは前の名前のまま。ほかの PC の `~/.ssh/known_hosts` は名前でつないでいれば、新しい名前で鍵を聞かれる
- **SSH はパスワードでもログインできる**: Workstation の既定。公開鍵だけにするなら[SSH を公開鍵だけにする（任意）](#ssh-を公開鍵だけにする任意)
- **journal は rsyslog と二重に残る**: `/var/log/messages`（rsyslog）にも同じ内容が残る。journal の大きさは、既定でファイルシステムの 10%（4 GiB まで）
- **kdump を止めると、カーネルが落ちたときの記録（vmcore）は残らない**: 原因を調べるときは、[ロールバック](#ロールバック)の手順 37 で戻す
- **コマンドが見つからないときに、パッケージを案内しない**: 手順 16 の後は、`dnf provides '*/bin/<コマンド>'` で探す
- **EPEL・RPM Fusion は AlmaLinux の配布物ではない**: EPEL は Fedora のプロジェクトが作るリポジトリ。AppStream / BaseOS にあるパッケージは、そちらを使う
  - RPM Fusion の free は「Fedora がライセンス以外の理由で配れないオープンソースのソフト」を配る（RPM Fusion の Configuration の説明）。鍵は手順 18 で照合し、`rpmfusion-free-release` の署名も手順 20 で確かめる
  - EL10 向けの RPM Fusion は中身が少ない。調べた範囲では、free に `ffmpeg` 7.1.5 と `gstreamer1-plugins-bad-freeworld`、nonfree に `steam`（i686）がある（[導入元一覧](tool-catalog.md#導入経路と-el10-での注意)）
  - RPM Fusion の `ffmpeg-libs` は、EPEL の `libavcodec-free` と衝突する（[firefox.md 手順 9](firefox.md#実施手順)）
- **Homebrew と同じ名前の実行ファイルを、EPEL から二重に入れない**: 例えば EPEL の `fd-find` は `/usr/bin/fd` を置く。両方入れると、PATH の先頭の Homebrew 版が使われ、`dnf upgrade` で上がるのは使われないほうになる（[btop.md の注意点](btop.md#注意点)）
- **ほかの手順書のロールバックでは、EPEL・RPM Fusion を消さない**: 使う手順書が複数ある。消すときはこの文書の[ロールバック](#ロールバック)で行う
- **Flatpak は容量が大きい**: アプリ本体に加え、runtime・翻訳・GL ドライバ・コーデックの拡張の容量も確保する。`sudo flatpak uninstall --unused` で、使われなくなった runtime を消せる
- **Flatpak のアプリは `dnf upgrade` では上がらない**: [更新](#更新)の `sudo flatpak update` を別に実行する
- **Flatpak の権限はアプリごとに違う**: 入れる前に表示される権限の一覧を確かめる。入れた後は `flatpak info --show-permissions <ID>` で見られ、Flatseal か `sudo flatpak override` で変えられる
- **Flathub のアプリの公開元を確認する**: 検証済み（公開元がアプリの作者本人だと確認されたもの）と未検証（第三者が包んでいる場合がある）の 2 種類がある。[導入元一覧](tool-catalog.md#gui)の表に書き分けてある
  - Microsoft Edge などは Flathub でも x86_64 だけ（[導入元一覧](tool-catalog.md#aarch64-で使えないもの)）
  - [Firefox](firefox.md) のように RPM で入れたものを Flathub からも入れると、メニューに同じ名前が 2 つ並ぶと見込まれる
- **`gsettings` は、書けなかったときも終了コード 0 で終わる**: 読み戻しで確かめる。この文書の `gsettings` は `/usr/bin/gsettings` で呼ぶ（Homebrew の `gsettings` は、dconf ではなくファイルに書き、読み戻しでは変わったように見える）
- **ほかの入力ソースは消える**: 手順 28 の `set` は一覧をまるごと置き換える
- **Anthy はひらがなで始まる**: RHEL のパッチで既定の入力モードがひらがなになっている。英字を打つなら、Super+Space で配列に戻すか、半角/全角キーで直接入力にする
  - 変換は Mozc に比べて弱いと言われる（本書では比べていない）。よく使う語は、一緒に入る辞書のツール `kasumi-unicode` で登録する
  - 入力モードやキーの割り当ての設定画面は `/usr/libexec/ibus-setup-anthy`（アプリの一覧には出ない）
- **Caps Lock の働きは無くなる**: 手順 31 は Caps Lock を Ctrl にするだけ。大文字を続けて打つときは Shift を押す。JIS 配列では「英数」（Caps Lock）のキーが Ctrl になる
- **Alt+Tab はウィンドウを切り替える**: アプリごとに切り替えるのは Super+Tab
- **拡大率の設定は mutter の実験的な機能**: GNOME の更新で、名前や働きが変わることがある。うまく動かなければ、[ロールバック](#ロールバック)の手順 8 で外す
- **トレイアイコンの拡張は EPEL のもの**: GNOME Shell の更新に遅れることがある。拡張が動かなくなったら、[ロールバック](#ロールバック)の手順 11 で無効にする
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
- **Homebrew の導入先を変えるとすべてソースビルドになる**: [検証記録](verification/almalinux-setup.md#統合前の記録-homebrewもとは-homebrewmd)
- **PATH の先頭が Homebrew になる**: `brew shellenv` は `/home/linuxbrew/.linuxbrew/bin` を `PATH` の**先頭**に足す。同じ名前の RPM が入っていると Homebrew 版が勝つ（bat・[gdu](gdu.md) で実際に問題になる）
- **`sudo <tool>` は、そのままでは使えない**: sudo の PATH（`secure_path`）にも root の `PATH` にも、Homebrew は入っていない
  - `sudo <tool>` で使うなら、[Homebrew を sudo でも使う（任意）](#homebrew-を-sudo-でも使う任意)の節を通す（`sudo -s`・`sudo -i` のシェルでも使えるようになる）
  - root のシェル（`su -`、root のログイン、`sudo -i`）で使うなら、[Homebrew を root のシェルでも使う（任意）](#homebrew-を-root-のシェルでも使う任意)の節を通す
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
  - root は別に導入する: root 自身にも bash の共通設定を導入した場合にだけ、root のシェルで初期化される（[Homebrew を root のシェルでも使う（任意）](#homebrew-を-root-のシェルでも使う任意)）
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
- **eza のアイコンには Nerd Font が要る**: `--icons=always` はグリフを出すだけなので、フォントが無い端末では豆腐になる（[HackGen Console NF](hackgen.md)）
- **eza の `--git` は大きなリポジトリで遅くなる**: 毎回 git の状態を引くため。気になるなら `--no-git`、リポジトリの一覧だけなら `--git-repos-no-status`
- **bat を EPEL 版と二重に入れない**: どちらも `bat` という名前で、PATH の先頭にある Homebrew 版が勝つ
- **bat のテーマの見え方は端末に依存する**: `ansi` 以外を選ぶと端末の配色とぶつかることがある。true color が出るかは端末側の設定次第
- **Claude Code の `Ctrl+B` は、tmux の中では 2 回押す**: `Ctrl+b` → `Ctrl+b` で中のアプリに `Ctrl+b` を送る
- **BaseOS の tmux と混ぜない**: 同じソケットを使うので、版の違うクライアントからはセッションにつなげない（[検証記録](verification/almalinux-setup.md#tmux-実施手順--手順-2-補足-baseos-の-tmux-と並べたとき)）
- **tmux のセッションがログアウトしても残るのは、`KillUserProcesses=no` のとき**: AlmaLinux 10 の既定。`yes` にしたホストでは、ログアウトでセッションも止まるはず
- **PC を再起動すると、tmux のセッションも中のコマンドも消える**: 起動時に始め直す仕組みは、本書では作らない
- **Remote Control の性質**（公式ドキュメント。[Windows の手順書の注意点](windows-claude-remote-control.md#注意点)にも同じ内容）
  - このホストからは外向きの HTTPS だけで、受信のポートは開けない
  - つないでいる間、会話の転写（メッセージ・応答・ツールの動き）は Anthropic のサーバーに保存される
  - ネットワークが約 10 分切れると、`claude remote-control` は自分で終わる。tmux の中のシェルは残るので、[Claude Code を tmux の中で動かす（任意）](#claude-code-を-tmux-の中で動かす任意)の手順 8 で入り、その節の手順 4 のコマンドを打ち直す
  - 止めてから約 4 時間以内なら、`claude remote-control` で同じセッションが戻る
  - `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`・`DISABLE_GROWTHBOOK`・`ANTHROPIC_BASE_URL`（`api.anthropic.com` 以外）があると使えない
- **tmux でマウスを on にすると、Claude Code の画面でもホイールは tmux が受け取る**: コンテナの Claude Code（ログインしていない最初の画面）は、マウスの報告も代替画面も使っていなかった（`#{mouse_any_flag}` と `#{alternate_on}` が 0）。ホイールは tmux のコピーモードに入る
