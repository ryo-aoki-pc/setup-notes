# AlmaLinux 10 のセットアップ

- 補足・注意点と検証記録は、冒頭の「この文書の補足と注意点」と、用途末尾の「補足と注意点」から開く

> [!IMPORTANT]
> - 前提: AlmaLinux 10 Workstation を入れた PC と、インターネット接続。オフラインの Homebrew は[別手順](#homebrew-のオフライン導入)を使う
> - **GNOME にログインした、インストール時の管理者ユーザー（`wheel`）の bash で行う**。`sudo -i`・`su -` のシェルでは行わない

- どの項も単独で通せる。目的の項のリードの前提を先に満たす
- 新しく入れた PC では、カテゴリを上から順に、要る項を選んで通す
- 対話・GUI・再起動は各手順の案内に従い、プロンプトに戻ってから次へ進む
- bash のブロックは、ブラケットペーストの効く端末（GNOME の端末・WezTerm・SSH の先）に貼り、貼った後に Enter を押す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 新しい端末では、使う項の変数の手順を貼り直す
- Windows 11 は[Windows の初期設定](windows-setup.md)から指定された項だけを使う
- 仮想マシン（VirtualBox・VirtualBox の bootc ゲスト・kvm-container）は、[仮想マシンのセットアップ](virtual-machines.md)で入れる
- 共通の bash 設定・シェルのツール・HackGen Console NF・WezTerm は、[シェルと端末のセットアップ](shell-terminal.md#almalinux-10-で使う)で入れる
- GNOME のリモート操作（デスクトップ共有・ヘッドレスセッション・リモートログイン）・Neovim・Samba は、[GNOME のリモート操作のセットアップ](gnome-remote.md)・[Neovim のセットアップ](neovim.md)・[Samba のセットアップ](samba.md)で入れる
- コンテナ（Podman・podman-compose・podman-tui・lazydocker・Distrobox）は、[コンテナのセットアップ](containers.md)で入れる
- 入れたものを上げるときは、[更新](#更新)の案内に従う

> [!WARNING]
> - [ログインと sudo](#ログインと-sudo)の手順 3 の後は、**このユーザーのプログラムがパスワード無しで root 権限を使える**。人が触れる場所の PC や信用できないプログラムを使うユーザーでは行わない
> - sudo のパスワード入力は「ログインと sudo」の手順 3 だけ

<details id="この文書の補足と注意点">
  <summary>この文書の補足と注意点</summary>

**注意点**

- **シェルと端末の注意は、[シェルと端末のセットアップ](shell-terminal.md)の各用途の末尾の「補足と注意点」にある**: `~/.inputrc` と shopt・シェルのツール（starship・zoxide・fzf・eza・bat・tmux）・HackGen Console NF・WezTerm のもの

- **`gsettings` は、書けなかったときも終了コード 0 で終わる**: 読み戻しで確かめる。この文書の `gsettings` は `/usr/bin/gsettings` で呼ぶ（Homebrew の `gsettings` は、dconf ではなくファイルに書き、読み戻しでは変わったように見える）

**省略できない初期設定**

必要な項だけを通す場合も、次の手順は省略しない。

- [ログインと sudo](#ログインと-sudo)の手順 1〜3、[OS とファームウェアの更新](#os-とファームウェアの更新)の手順 1・2・3
- [システムの設定](#システムの設定)の手順 1、[共通の bash 設定](shell-terminal.md#共通の-bash-設定)の手順 1・2
- [Homebrew](#homebrew)の手順 1〜2、[シェルのツール](shell-terminal.md#シェルのツール)の手順 1・2
- [Git](#git)の手順 1〜6、[Firefox](#firefox)の手順 1〜6（ブラウザ認証に使う）
- [HackGen Console NF](shell-terminal.md#hackgen-console-nf)の手順 1〜5（WezTerm と等幅のフォントに使う）、[WezTerm](shell-terminal.md#wezterm)の手順 1〜3
- [再起動と確認](#再起動と確認)の手順 1

**更新**

- **Git の dnf upgrade**
- 通常の `sudo dnf upgrade` にも含まれる

- **Firefox の RPM 版の更新**
- Firefox 内蔵の自動更新機能は RPM 版では無効で（`/usr/lib/firefox` に一般ユーザーの書き込み権が無い）、更新は dnf 側で行う
- 本体だけ上げて言語パックを取り残すと UI が英語に戻るので、両方まとめて上げる

**選択した方針**

- **GNOME の設定は `gsettings` の読み戻しで確かめる**: `gsettings` は書けなかったときも終了コード 0 で終わる。`/usr/bin/gsettings` で呼ぶ（Homebrew の glib の `gsettings` は dconf に書かない。画面オフ・ロック・サスペンドの記録（`docs/verification/almalinux-setup.md` の「画面オフ・ロック・サスペンド: 実施手順 / 手順 2: 補足: 変える前の値、0 にしても暗くなる理由、設定アプリの項目」））
  - 一覧の値（`xkb-options`・`experimental-features`・`custom-keybindings`）は、まるごと置き換えず、無ければ足す。ほかの設定で入っている値を消さないため

**参照**

- [Windows 11 の初期設定](windows-setup.md) — Windows 11 側の同じ形の手順書

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

## 基本の設定

- インストール直後の sudo・更新・SSH・ログの設定、パッケージの入手元（EPEL・RPM Fusion・Flathub・Homebrew）、OS の自動更新・Secure Boot の署名鍵・ユーザーサービスの常駐。共通の bash 設定は、[シェルと端末のセットアップ](shell-terminal.md#共通の-bash-設定)で入れる

### ログインと sudo

- インストールのときに作った管理者のユーザーで GNOME にログインし、sudo をパスワード無しで使えるようにする
- 前提: 無し
- 実行場所: この PC の画面（GNOME のログイン画面）。この項の手順 3 は、この項の手順 2 で開く端末（bash）

1. インストールのときに作ったユーザーで GNOME にログインし、「ようこそ」の窓を閉じる。

   - インストールの後の最初の起動で、ログイン画面でユーザーを選び、パスワードを入れる
   - 「AlmaLinux 10.2 (Lavender Lion) へようこそ」で「スキップ」を押す。ツアーを見るなら「“ツアー”を始める」

1. 端末を開く。

   - Super キー（Windows キー）でアクティビティの画面を開き、`terminal` と打って Enter（「ターミナル」が出る）。アクティビティの画面の下の Dash の、ターミナルのアイコンでもよい
   - 端末のアプリは Ptyxis（画面の表示は「ターミナル」）。この項の手順 3 から、この端末に貼る

1. sudo をパスワード無しで使えるようにする（パスワードを 1 回聞かれる）。

   ```bash
   # sudo を使うユーザーの所属を確かめる
   if ! id -nG | grep -qw wheel; then
     echo '中断: このユーザーは wheel の一員ではない（インストールのときに管理者にしたユーザーで貼る）' >&2
   else
     printf '\n\033[7m 確認 \033[0m\n'
     # sudo の設定を検査して書き込む
     printf 'Defaults:%s verifypw=any\n%s ALL=(ALL) NOPASSWD: ALL\n' "${USER}" "${USER}" | sudo visudo -cf - &&
       printf 'Defaults:%s verifypw=any\n%s ALL=(ALL) NOPASSWD: ALL\n' "${USER}" "${USER}" | sudo install -m 0440 /dev/stdin /etc/sudoers.d/nopasswd
     sudo visudo -c
   fi
   # 認証を解除して sudo の動作を確かめる
   sudo -k
   sudo -n -v && sudo -n true && echo 'sudo はパスワードを聞かない'
   ```

   - `[sudo] <USER> のパスワード:` にはログインのパスワードを入れる
   - `stdin: 正しく構文解析されました`（英語では `parsed OK`）、`/etc/sudoers`・`/etc/sudoers.d/nopasswd`、最後に `sudo はパスワードを聞かない` が出ればよい
   - `中断:` が出たら、何も書いていない。インストールのときに管理者にしたユーザーでログインし直して、この項の手順 2 から
   - **次の手順は、パスワードを入れて、プロンプトに戻ってから貼る**（終わる前に貼ると、動いているコマンドへの入力になる）

<details id="ログインと-sudo-の補足と注意点">
  <summary>ログインと sudo の補足と注意点</summary>

**[ログインと sudo](#ログインと-sudo)の手順 1: 日本語の名前のフォルダー**

- このログインで、ホームに日本語の名前のフォルダー（`ダウンロード`・`ドキュメント` など）ができる。[GNOME の表示と入力](#gnome-の表示と入力)の手順 2 で英語の名前にする

**[ログインと sudo](#ログインと-sudo)の手順 3: 貼り直し**

- 貼り直しても同じ内容で置き直すだけ（何度貼ってもよい）

**選択した方針**

- **sudo をパスワード無しにする（[ログインと sudo](#ログインと-sudo)の手順 3）**: このリポジトリの手順書は、NOPASSWD を前提に書いてある（README の記法）。最初に設定する
  - `/etc/sudoers.d/nopasswd` に、このユーザーだけの 2 行を置く。`/etc/sudoers` の `%wheel ALL=(ALL) ALL` は残す
  - `Defaults:<USER> verifypw=any` も置く。`sudo -v`（`-v` は資格を更新するだけ）は、`verifypw` の既定の `all` では、そのユーザーに当たるすべての行が NOPASSWD のときだけパスワードを聞かない。`%wheel` の行が残るので、`verifypw=any` が無いと Homebrew のインストーラの `sudo -v` がパスワードを聞いた（sudoers(5) の `verifypw`）
  - 書く前に `visudo -cf -` で確かめ、`install -m 0440` で置き、最後に `visudo -c` で全体を確かめる（書式の誤りがあると `sudo` そのものが使えなくなるため）

**参照**

- [sudoers(5)](https://www.sudo.ws/docs/man/sudoers.man/) — `verifypw`（`sudo -v` のときの認証の条件）と `NOPASSWD`、`/etc/sudoers.d` の読み込み

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

---

### OS とファームウェアの更新

- OS のパッケージを最新にし、ファームウェアの更新があれば入れて、要るときだけ再起動する
- 前提: [ログインと sudo](#ログインと-sudo)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）

- **この項の手順 2 の更新中は電源を切らない**。ノート PC は電源につないでおく

1. OS を更新し、ファームウェアの情報を再取得する。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # OS のパッケージを更新する
   sudo dnf upgrade --refresh
   # ファームウェアの情報を取得する
   sudo fwupdmgr refresh --force
   ```

   - 更新するものの一覧（トランザクション表）の後に `これでよろしいですか? [y/N]:` と聞かれる。`y`
   - AlmaLinux の署名鍵の確認が出たら、`Userid : "AlmaLinux OS 10 <packager@almalinux.org>"` と `Fingerprint: EE6D B7B9 8F5B F5ED D9DA 0DE5 DEE5 C11C C2A1 E572` を確かめてから `y`（[AlmaLinux の Security のページ](https://almalinux.org/security/)の値と同じ）。違っていれば `N` で中断する
   - `行うべきことはありません。` と出たら、更新は無い（`[y/N]` も、署名鍵の確認も出ない）
   - 初めてのときは `現在リモートが有効になっていないため、メタデータが利用できません。` に続けて `このリモートを有効にしますか? [Y|n]:` と聞かれる。`Y`
   - `新しいメタデータのダウンロードに成功しました:`、または更新できる機器が無い旨の行が出ればよい
   - `デーモンへの接続に失敗しました: … タイムアウトしました` と出たら、少し待ってから貼り直す
   - **次の手順は、問いに答えてプロンプトに戻ってから貼る**（続けて貼ると、リモートの有効化を断ったときや情報の取得に失敗したときも、更新の行が動く）

1. ファームウェアを更新し、OS の再起動の要否を確認する。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # ファームウェアを更新する
   sudo fwupdmgr update
   # 再起動が必要かを確かめる
   dnf needs-restarting -r
   ```

   - 更新が無ければ `No updatable devices` と出て終わる
   - 更新があれば、機器ごとに確認を聞かれる。`y`。再起動するかを聞かれたら `n`（この項の手順 3 で再起動する）
   - `再起動な必要ありません。`（表示のとおり）と出て、この項の手順 2 でファームウェアを更新していなければ、この項の手順 3 は飛ばす
   - `再起動が必要です` の形の行（カーネルや systemd などを更新したとき）が出たか、この項の手順 2 でファームウェアを更新したなら、この項の手順 3 で再起動する

1. 再起動が要るときだけ、再起動する。

   ```bash
   sudo systemctl reboot
   ```

   - 保存していない文書のあるアプリが開いていると、`Operation inhibited by …` で断られることがある。そのアプリを閉じてから貼り直す
   - **次の手順は、起動してログインし、端末を開いてから貼る**（端末の開き方は[ログインと sudo](#ログインと-sudo)の手順 2）

<details id="os-とファームウェアの更新-の補足と注意点">
  <summary>OS とファームウェアの更新 の補足と注意点</summary>

**[OS とファームウェアの更新](#os-とファームウェアの更新)の手順 1**

- インストールの後の最初の更新では、続けて AlmaLinux の署名鍵の取り込みを聞かれる（`GPG 鍵 0xC2A1E572 をインポート中:`）

- 更新が無いときは、AlmaLinux の署名鍵は、[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 1 で取り込まれる

- `新しいメタデータのダウンロードに成功しました:` と、更新できる機器の数が出る（VirtualBox の VM では `更新可能なデバイスはありません`。Hyper-V と VMware の VM では `N 個のデバイスが更新可能です` と出て、[OS とファームウェアの更新](#os-とファームウェアの更新)の手順 2 で `UEFI dbx` の更新を聞かれることがある）

**[OS とファームウェアの更新](#os-とファームウェアの更新)の手順 1: fwupd の起動待ち**

- `デーモンへの接続に失敗しました: … タイムアウトしました` が出るのは、起動の直後に fwupd の起動が間に合わないことがあるため

**選択した方針**

- **ファームウェアは fwupd（[OS とファームウェアの更新](#os-とファームウェアの更新)の手順 1・2）**: Workstation に入っている `fwupdmgr` で、LVFS から入れる。AlmaLinux 10 の既定では LVFS のリモートが無効で、`refresh` が有効にするかを聞く
  - `--assume-yes` を付けても、この問いは出た。リモートの有効化と情報取得の結果を確かめてから更新へ進むため、`refresh` と `update` は別の手順にする

**参照**

- [AlmaLinux の Security のページ](https://almalinux.org/security/) — AlmaLinux 10 の署名鍵の fingerprint

- `man fwupdmgr`（`refresh`・`update`）と [LVFS](https://fwupd.org/) — ファームウェアを配るサービス

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

---

### システムの設定

- PC の名前・SSH の待ち受け・ログ（journal）の保存・kdump・コマンドが無いときの案内を設定する
- 前提: [ログインと sudo](#ログインと-sudo)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）

- **この項の手順 7 で kdump を止めると、カーネルが落ちたときの記録（vmcore）は残らなくなる**

1. 変数を設定する（PC の名前を変えるなら、`HOST_NAME` に値を入れる）。

   ```bash
   HOST_NAME=''   # この PC の新しい名前（英小文字・数字・ハイフン。例: alma-pc）。変えないなら空のまま。<HOSTNAME>
   ```

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   for v in USER HOST_NAME; do
     printf '%-9s = %s\n' "$v" "${!v}"
   done
   ```

   - `HOST_NAME` を変えないなら空のままにして、この項の手順 2 を飛ばす
   - `USER` が `root` になっているなら、ここで止めて、自分のユーザーの端末で貼り直す
   - **新しい端末を開いたら**、この項の手順 1 を貼り直してから先へ進む

1. PC の名前を変えるときだけ、名前を変える。

   ```bash
   # ホスト名を変更して読み戻す
   if [ -z "${HOST_NAME}" ]; then echo '中断: この項の手順 1 の HOST_NAME が空のまま。名前を変えないなら、この手順は飛ばす' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     echo "変える前: $(hostnamectl --static)"
     sudo hostnamectl hostname "${HOST_NAME}"
     echo "変えた後: $(hostnamectl --static)"
   fi
   ```

   - `変えた後:` に、この項の手順 1 の名前が出ればよい
   - `変える前:` の名前を控える
   - 開いている端末のプロンプトは、開き直すまで前の名前のまま

1. SSH の待ち受けとファイアウォールを確かめ、この PC の IP アドレスを見る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # SSH サーバーの起動状態を確かめる
   systemctl is-enabled sshd
   systemctl is-active sshd
   # SSH の通信許可を確かめる
   sudo firewall-cmd --query-service=ssh
   sudo firewall-cmd --permanent --query-service=ssh
   # 接続に使う IP アドレスを確かめる
   ip -4 -brief address show scope global
   ```

   - `enabled`・`active`・`yes`・`yes` と、この PC の IP アドレスが出ればよい（この項の手順 4 は飛ばす）
   - どれかが違えば、この項の手順 4 で直す

1. SSH の待ち受けか、ファイアウォールの ssh が違うときだけ、直す。

   ```bash
   # SSH サーバーを導入して起動する
   if ! rpm -q openssh-server; then sudo dnf install -y openssh-server; fi
   sudo systemctl enable --now sshd
   # SSH の通信を許可する
   sudo firewall-cmd --permanent --add-service=ssh
   sudo firewall-cmd --reload
   printf '\n\033[7m 確認 \033[0m\n'
   # SSH サーバーの動作を確かめる
   systemctl is-active sshd
   # SSH の通信許可を確かめる
   sudo firewall-cmd --query-service=ssh
   ```

   - `active` と `yes` が出ればよい

1. ログ（journal）を、再起動の後も残るようにディスクに書く。

   ```bash
   # journal の保存先を設定する
   sudo mkdir -p /etc/systemd/journald.conf.d
   printf '[Journal]\nStorage=persistent\n' | sudo tee /etc/systemd/journald.conf.d/50-persistent.conf >/dev/null
   # 設定を反映して journal を書き出す
   sudo systemctl restart systemd-journald
   sudo journalctl --flush
   sudo systemd-tmpfiles --create --prefix /var/log/journal
   printf '\n\033[7m 確認 \033[0m\n'
   ls -ld /var/log/journal
   journalctl --disk-usage
   ```

   - `/var/log/journal` が `root systemd-journal`・`drwxr-sr-x+` で、journal の大きさが出ればよい

1. kdump が有効になっているか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # kdump の起動設定を確かめる
   systemctl is-enabled kdump
   # クラッシュ用メモリーの予約を確かめる
   cat /sys/kernel/kexec_crash_size
   grep -o 'crashkernel=[^ ]*' /proc/cmdline
   ```

   - `enabled` と、0 でない数と、`crashkernel=…` が出たら、この項の手順 7 で止める
   - `disabled` と `0` が出て、`crashkernel=` が無ければ、この項の手順 7 は飛ばす

1. kdump が有効なときだけ、止めて、カーネルが落ちたときのために予約しているメモリーを外す（効くのは再起動の後）。

   ```bash
   # kdump を停止して自動起動を無効にする
   sudo systemctl disable --now kdump
   # クラッシュ用メモリーの予約を無効にする
   sudo sed -i 's/^auto_reset_crashkernel yes$/auto_reset_crashkernel no/' /etc/kdump.conf
   sudo grubby --update-kernel=ALL --remove-args=crashkernel
   printf '\n\033[7m 確認 \033[0m\n'
   grep -n '^auto_reset_crashkernel' /etc/kdump.conf
   sudo grubby --info=ALL | grep -E '^args='
   ```

   - `auto_reset_crashkernel no` と、`crashkernel=` を含まない `args=` の行が出ればよい

1. コマンドが無いときにパッケージを探して案内する機能（PackageKit-command-not-found）を外す。

   ```bash
   sudo dnf remove PackageKit-command-not-found
   ```

   - `削除中:` が `PackageKit-command-not-found` の 1 つだけになる。`これでよろしいですか? [y/N]:` に `y`
   - **次の手順は、`完了しました!` が出てプロンプトに戻ってから貼る**（終わる前に貼ると、動いているコマンドへの入力になる）

<details id="システムの設定-の補足と注意点">
  <summary>システムの設定 の補足と注意点</summary>

**注意点**

- **PC の名前を変えた後**: 開いている端末のプロンプトは前の名前のまま。ほかの PC の `~/.ssh/known_hosts` は名前でつないでいれば、新しい名前で鍵を聞かれる

- **SSH はパスワードでもログインできる**: Workstation の既定。公開鍵だけにするなら[SSH を公開鍵だけにする](#ssh-を公開鍵だけにする)

- **journal は rsyslog と二重に残る**: `/var/log/messages`（rsyslog）にも同じ内容が残る。journal の大きさは、既定でファイルシステムの 10%（4 GiB まで）

- **コマンドが見つからないときに、パッケージを案内しない**: [システムの設定](#システムの設定)の手順 8 の後は、`dnf provides '*/bin/<コマンド>'` で探す

**[システムの設定](#システムの設定)の手順 1**

- 最後に値を読み戻して確かめる

**[システムの設定](#システムの設定)の手順 1: 変数の意味**

- `HOST_NAME` は、SSH・RDP・Samba などで、この PC を見分ける名前
- 変数はその端末の中だけで有効なので、新しい端末を開いたら貼り直す

**[システムの設定](#システムの設定)の手順 3: SSH の既定とログイン**

- `enabled`・`active`・`yes`・`yes` は、Workstation の既定
- 別の PC からは `ssh <USER>@<IP>` でログインできる（初めてつなぐときは、ホストの鍵の fingerprint を聞かれる）

**[システムの設定](#システムの設定)の手順 5: journal の置き場所**

- AlmaLinux 10 の既定では `/var/log/journal` が無く、journal は `/run/log/journal`（メモリー）にだけ書かれて、再起動で消える
- journald が作った `/var/log/journal` に付かない ACL は、`wheel`・`adm` のグループが読めるもの（付け直す仕組みはこの折りたたみの「選択した方針」）
- 前の起動のログが読めることは、[再起動と確認](#再起動と確認)の手順 1 の再起動の後に、[再起動と確認](#再起動と確認)の手順 3 で確かめる

**[システムの設定](#システムの設定)の手順 6: 予約しているメモリー**

- `/sys/kernel/kexec_crash_size` の数は、予約しているメモリーのバイト数（`268435456` で 256 MiB）

**[システムの設定](#システムの設定)の手順 7: 効く時期**

- メモリーが空くのは、[再起動と確認](#再起動と確認)の手順 1 の再起動の後

**[システムの設定](#システムの設定)の手順 8: 外した後**

- 外すと、無いコマンドを打ったときは `bash: <コマンド>: コマンドが見つかりません...` とだけ出て、パッケージを探して待たされない

**選択した方針**

- **journal を永続にする（[システムの設定](#システムの設定)の手順 5）**: `/etc/systemd/journald.conf.d/` のドロップインで `Storage=persistent` にする（`/etc/systemd/journald.conf` は書き換えない）
  - journald が作った `/var/log/journal` には、`systemd-journal` のグループと ACL が付かなかった。`systemd-tmpfiles --create --prefix /var/log/journal` で、パッケージの tmpfiles の定義どおりに付け直す
  - tmpfiles の定義（`/usr/lib/tmpfiles.d/systemd.conf` の `z`・`a+`）は、すでにあるものだけを直す。`/var/log/journal` は `journalctl --flush` のときに作られるので、tmpfiles はその後に行う（前に行うと、何も直らなかった）

- **kdump を止める（[システムの設定](#システムの設定)の手順 6・7）**: カーネルが落ちたときの記録が要らない PC では、予約されるメモリー（`crashkernel=`）を空ける
  - `/etc/kdump.conf` の `auto_reset_crashkernel` を `no` にする。`yes` のままだと、カーネルを入れたときに kernel-install の `92-crashkernel.install` が `crashkernel=` を付け直す
  - `crashkernel=` は `grubby --update-kernel=ALL --remove-args=crashkernel` で、入っているすべてのカーネルの起動の項目から外す

- **PackageKit-command-not-found を外す（[システムの設定](#システムの設定)の手順 8）**: 無いコマンドを打つたびにリポジトリを探して待たされるため。パッケージは `dnf provides` で探す

**参照**

- `man journald.conf`（`Storage=`）と `man systemd-tmpfiles`

- `man kdump.conf`（`auto_reset_crashkernel`）と `/usr/lib/kernel/install.d/92-crashkernel.install` — カーネルを入れたときに `crashkernel=` を付け直す仕組み

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

---

### EPEL と RPM Fusion

- EPEL と RPM Fusion（free）のリポジトリを、署名鍵を確かめてから入れる
- 前提: [ログインと sudo](#ログインと-sudo)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）

1. EPEL が無ければ入れ、有効になったか確かめる。

   ```bash
   # EPEL のリポジトリを導入する
   if ! dnf repolist enabled | grep -qE '^epel'; then sudo dnf install -y epel-release; fi
   printf '\n\033[7m 確認 \033[0m\n'
   rpm -q epel-release
   dnf repolist enabled | grep -E '^epel'
   ```

   - `epel-release` の版と、`epel` の行が出れば有効になっている
   - 最後に出る「CRB を有効にすることを推奨」は、気にしなくてよい
   - [OS とファームウェアの更新](#os-とファームウェアの更新)の手順 1 で更新が無かったときは、ここで AlmaLinux の署名鍵が、確認を求めずに取り込まれる（「確認」の見出しより前の dnf の出力に、`GPG 鍵 0xC2A1E572 をインポート中:` と出る）
     - その出力の `Fingerprint:` が `EE6D B7B9 8F5B F5ED D9DA 0DE5 DEE5 C11C C2A1 E572` であることを確かめる。違っていれば、ここで中断する（鍵は取り込まれた後なので、次の手順へ進まない）
   - EPEL の署名鍵の確認が出たら、fingerprint `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）なら `y`、違っていれば `N` で中断する

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
   # RPM Fusion の署名鍵を取り込む
   sudo rpm --import 'https://rpmfusion.org/keys?action=AttachFile&do=get&target=RPM-GPG-KEY-rpmfusion-free-el-10'
   printf '\n\033[7m 確認 \033[0m\n'
   rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i fusion
   ```

   - `rpm --import` は何も表示しない
   - `gpg-pubkey-db85ddd7-67a63d8b` と RPM Fusion の鍵の名前が出ればよい

1. RPM Fusion のリポジトリを導入し、有効になったことを確認する。

   ```bash
   # RPM Fusion のリポジトリを導入する
   sudo dnf --setopt=localpkg_gpgcheck=1 install https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-10.noarch.rpm
   printf '\n\033[7m 確認 \033[0m\n'
   rpm -q rpmfusion-free-release
   dnf repolist enabled | grep -E '^rpmfusion'
   ```

   - `--setopt=localpkg_gpgcheck=1` を外さない（外すと、この項の手順 3 の鍵で署名を確かめずに入る）
   - EPEL が有効なホストでは、`インストール:` が `rpmfusion-free-release` の 1 つだけになる
   - トランザクション表を見て、`[y/N]` に答える
   - `rpmfusion-free-release` の版と、`rpmfusion-free-updates` の行が出れば有効になっている

<details id="epel-と-rpm-fusion-の補足と注意点">
  <summary>EPEL と RPM Fusion の補足と注意点</summary>

**注意点**

- **EPEL・RPM Fusion は AlmaLinux の配布物ではない**: EPEL は Fedora のプロジェクトが作るリポジトリ。AppStream / BaseOS にあるパッケージは、そちらを使う
  - RPM Fusion の free は「Fedora がライセンス以外の理由で配れないオープンソースのソフト」を配る（RPM Fusion の Configuration の説明）。鍵は[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 2 で照合し、`rpmfusion-free-release` の署名も[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 4 で確かめる
  - EL10 向けの RPM Fusion は中身が少ない。調べた範囲では、free に `ffmpeg` 7.1.5 と `gstreamer1-plugins-bad-freeworld`、nonfree に `steam`（i686）がある（[導入経路と EL10 での注意](tool-catalog.md#導入経路と-el10-での注意)）
  - RPM Fusion の `ffmpeg-libs` は、EPEL の `libavcodec-free` と衝突する（[Firefox](#firefox)の手順 8）

**[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 1**

- EPEL の署名鍵は、EPEL からパッケージを初めて入れるとき（この文書では[GNOME の表示と入力](#gnome-の表示と入力)の手順 11）に、dnf が 1 回だけ確認を求める

- fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）であることを確かめてから `y`。違っていれば `N` で中断する

**[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 1: EPEL の入手元と使う手順書**

- `epel-release` は AlmaLinux の `extras` リポジトリにあるので、追加のリポジトリの設定は要らない
- 最後に出る「CRB を有効にすることを推奨」を気にしなくてよいのは、AlmaLinux 10 では CRB が既定で有効なため（[導入経路と EL10 での注意](tool-catalog.md#導入経路と-el10-での注意)）
- EPEL を使う手順書（[btop](#btop)・[Distrobox](containers.md#distrobox)・[podman-compose](containers.md#podman-compose)・[podman-tui](containers.md#podman-tui)・[VirtualBox](virtual-machines.md#virtualbox)）と、[導入元一覧](tool-catalog.md)の EPEL の行が使えるようになる

**[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 1: 出力例と、EPEL の鍵**

`epel-release` は、repo ファイル（`/etc/yum.repos.d/epel.repo` と、無効の `epel-testing.repo`）と、鍵のファイル `/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-10` を置く。

取り込んだ鍵は、`rpm -q gpg-pubkey` に `gpg-pubkey-e37ed158-65785fa9` として出る。

**[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 3**

- `gpg-pubkey-db85ddd7-67a63d8b RPM Fusion free repository for EL (10) ...` の 1 行が出れば、取り込めている

**[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 4: localpkg_gpgcheck と free**

- `--setopt=localpkg_gpgcheck=1` を外さない理由は、検証記録（`docs/verification/almalinux-setup.md` の「RPM Fusion: 実施手順 / 手順 3: 補足: 署名の確認と、EPEL を前提にした理由」）とこの折りたたみの「選択した方針」
- 有効にするのは free だけ。nonfree は扱わない

**[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 4: 使えるようになるもの**

- [Firefox](#firefox)（RPM Fusion の `ffmpeg-libs` を入れる）が使えるようになる

**選択した方針**

- **署名を確かめて入れる**: Configuration の `--nogpgcheck` の例は使わず、keys ページの方法（鍵を先に取り込み、`localpkg_gpgcheck=1`）にした（この折りたたみの「EPEL と RPM Fusion の手順 4: localpkg_gpgcheck と free」）
- **free だけ**: 本書を使う [Firefox](#firefox) は、free の `ffmpeg-libs` で足りる。nonfree は有効にしない
- **EPEL を前提にする**: `rpmfusion-free-release` が `epel-release` を要求し、RPM Fusion の Configuration も EPEL を先に有効にする順で書いている（この折りたたみの「EPEL と RPM Fusion の手順 4: localpkg_gpgcheck と free」）

**参照**

- [EPEL — Fedora Docs](https://docs.fedoraproject.org/en-US/epel/) — EPEL とは何か。入れ方は同じ文書の [Getting Started](https://docs.fedoraproject.org/en-US/epel/getting-started/)（CRB と `epel-release`）
- `man dnf`（`remove` の `--noautoremove`）
- [導入経路と EL10 での注意](tool-catalog.md#導入経路と-el10-での注意) — EPEL とほかの導入元の比較

- [Configuration — RPM Fusion](https://rpmfusion.org/Configuration) — free / nonfree の区別と、EL 向けの有効化（EPEL を先に有効にすること、`--nogpgcheck` の例、Alma・Rocky の `crb enable`）
- [Trusting Package Integrity — RPM Fusion](https://rpmfusion.org/keys) — 鍵の fingerprint と、鍵を先に取り込んで `localpkg_gpgcheck=1` で入れる方法
- `man dnf.conf`（`localpkg_gpgcheck`）

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

---

### Flatpak と Flathub

- flatpak を確かめ、署名鍵を確かめてから Flathub を system に登録し、確認用のアプリ（Flatseal）で動きを確かめる
- 前提: [ログインと sudo](#ログインと-sudo)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）

- 確認用のアプリ（Flatseal）が不要なら、この項の手順 4 は飛ばせる

1. flatpak を確かめ（無ければ入れ）、登録されているリモートを見る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # Flatpak を導入して版を確かめる
   if ! rpm -q flatpak; then sudo dnf install -y flatpak; fi
   flatpak --version
   # 登録済みのリモートを確かめる
   flatpak remotes --show-details
   ```

   - パッケージの flatpak と、コマンドの Flatpak の版が出ればよい
   - 導入直後の `flatpak remotes` の `error: While opening repository /var/lib/flatpak/repo: ...` は正常。次の手順へ進む

1. Flathub の登録ファイルに埋め込まれた公開鍵の fingerprint を確かめる。

   ```bash
   curl -fsSL https://dl.flathub.org/repo/flathub.flatpakrepo | sed -n 's/^GPGKey=//p' | base64 -d | gpg --show-keys --with-fingerprint
   ```

   - 次の値と一致することを目で確かめる
     - `6E5C 05D9 79C7 6DAF 93C0 8135 4184 DD4D 907A 7CAE`（Flathub Repo Signing Key &lt;flathub@flathub.org&gt;、有効期限 2027-06-14）
   - **次の手順は、一致するのを確かめてから貼る**（違っていれば先へ進まない）

1. Flathub を system に登録して、登録されたか確かめる。

   ```bash
   # Flathub をリモートに登録する
   sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
   printf '\n\033[7m 確認 \033[0m\n'
   flatpak remotes --show-details
   ```

   - `flathub` の行が出て、`Options` の列が `system` になっていればよい

1. Flatseal を導入し、サンドボックスの起動を確認する。

   ```bash
   # Flatseal を導入する
   sudo flatpak install flathub com.github.tchx84.Flatseal
   printf '\n\033[7m 確認 \033[0m\n'
   # Flatseal の導入状態を確かめる
   flatpak list --app --columns=application,version,branch,installation
   flatpak info com.github.tchx84.Flatseal
   # サンドボックスの起動を確かめる
   flatpak run --command=true com.github.tchx84.Flatseal && echo 'sandbox OK'
   # アプリの起動ファイルを確かめる
   ls /var/lib/flatpak/exports/share/applications/
   ```

   - **確認を 2 回聞かれる**。どちらも `y` で進める
     - 1 回目: runtime を入れるか（`Do you want to install it? [Y/n]`）
     - 2 回目: アプリの権限と入れるものの一覧を見せたうえでの最終確認（`Proceed with these changes to the system installation? [Y/n]`）
   - `flatpak list` に `com.github.tchx84.Flatseal` が `system` として出ればよい
   - `sandbox OK` が出れば、アプリのサンドボックスが起動できている
   - 最後の行に `com.github.tchx84.Flatseal.desktop` が出れば、デスクトップのメニューに載せるためのファイルができている
   - メニューに載るのは、[再起動と確認](#再起動と確認)の手順 1 の再起動の後

#### Flatpak の使い方の基本

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

- Flathub を登録した直後に `flatpak search flatseal` が `No matches found` を返す場合は、`sudo flatpak update --appstream` で検索用のメタデータを取得してから検索し直す。`sudo flatpak update` を 1 度実行したあとも、同じように検索できるようになる

<details id="flatpak-と-flathub-の補足と注意点">
  <summary>Flatpak と Flathub の補足と注意点</summary>

**注意点**

- **Flatpak は容量が大きい**: アプリ本体に加え、runtime・翻訳・GL ドライバ・コーデックの拡張の容量も確保する。`sudo flatpak uninstall --unused` で、使われなくなった runtime を消せる

- **Flatpak のアプリは `dnf upgrade` では上がらない**: [更新](#更新)の `sudo flatpak update` を別に実行する

- **Flatpak の権限はアプリごとに違う**: 入れる前に表示される権限の一覧を確かめる。入れた後は `flatpak info --show-permissions <ID>` で見られ、Flatseal か `sudo flatpak override` で変えられる

- **Flathub のアプリの公開元を確認する**: 検証済み（公開元がアプリの作者本人だと確認されたもの）と未検証（第三者が包んでいる場合がある）の 2 種類がある。[GUI](tool-catalog.md#gui)の表に書き分けてある
  - Microsoft Edge などは Flathub でも x86_64 だけ（[aarch64 で使えないもの](tool-catalog.md#aarch64-で使えないもの)）
  - [Firefox](#firefox) のように RPM で入れたものを Flathub からも入れると、メニューに同じ名前が 2 つ並ぶと見込まれる

**[Flatpak と Flathub](#flatpak-と-flathub)の手順 1**

- `flatpak-1.16.0-…` と `Flatpak 1.16.0` が出る

**[Flatpak と Flathub](#flatpak-と-flathub)の手順 1: flatpak と Flathub の登録**

検証記録（`docs/verification/almalinux-setup.md` の「Flatpak の記録」）を参照する。

- Workstation には flatpak が最初から入っている
- `flathub` の行が既にあれば、[Flatpak と Flathub](#flatpak-と-flathub)の手順 3 は何もしない（`--if-not-exists` のため）

**[Flatpak と Flathub](#flatpak-と-flathub)の手順 2: 鍵は登録ファイルの中にある**

`flathub.flatpakrepo` は鍵を**本文に base64 で埋め込んで**いて、`flatpak remote-add` はこの鍵をリモートの設定に取り込む。以後の取得はすべてこの鍵で署名を検証する。したがって、確かめるべきは「登録ファイルの中の鍵が Flathub のものか」の 1 点になる（[VS Code](#vs-code) の手順で rpm の鍵を確かめているのと同じ考え方）。

`gpg --show-keys` は鍵を**鍵束に取り込まずに表示するだけ**。ただし `~/.gnupg` が無ければ最初の実行で作られる（`gpg: directory '/home/<USER>/.gnupg' created`）。

**[Flatpak と Flathub](#flatpak-と-flathub)の手順 3: 使えるようになるもの**

- [GUI](tool-catalog.md#gui)の「Flathub」の行にある GUI アプリが入れられるようになる。[Firefox](#firefox) と [VS Code](#vs-code) は Flathub を使わず RPM で入れる

**[Flatpak と Flathub](#flatpak-と-flathub)の手順 4**

- `flatpak list` に `com.github.tchx84.Flatseal  2.4.1  stable  system` のように出る

- 最初の 1 本は runtime ごと落とすので、`/var/lib/flatpak` が 1.7 GB ほどになる（runtime が GNOME 50 のとき）。要らなければ、この手順は飛ばしてよい

**[Flatpak と Flathub](#flatpak-と-flathub)の手順 4: 確認用のアプリ**

- 確認用のアプリは、小さい [Flatseal](https://flathub.org/apps/com.github.tchx84.Flatseal)（Flatpak アプリの権限を GUI で変えるツール）にしてある

**[Flatpak の使い方の基本](#flatpak-の使い方の基本)のリード**

- `flatpak` の読み取り系（`search` / `list` / `info` / `remote-ls`）は `sudo` 無しで動く

**参照**

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

---

### Homebrew

- Homebrew を公式のインストーラで `/home/linuxbrew/.linuxbrew` に入れ、共通の bash 設定で PATH を通す
- 前提: [ログインと sudo](#ログインと-sudo)と[共通の bash 設定](shell-terminal.md#共通の-bash-設定)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）
- インターネットに出られない PC は、この項を飛ばし、[Homebrew のオフライン導入](#homebrew-のオフライン導入)を通す
- **GNOME で日本語入力を使う PC は、この項の手順 3 を飛ばさない**。Homebrew が既に入っていても、IBus の PATH 固定まで行う

1. Homebrew の依存パッケージを入れる。

   ```bash
   sudo dnf install -y procps-ng curl file git
   ```

   - Workstation では、どれも入っている（`は既にインストールされています。` と出る）

1. Homebrew を導入して共通の bash 設定を読み、動作を確認する。

   ```bash
   # Homebrew を導入する
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   # 共通の bash 設定を読み込む
   . ~/.bashrc
   printf '\n\033[7m 確認 \033[0m\n'
   brew --version
   command -v brew
   brew config | head -12
   ```

   - インストーラは続行の確認で `RETURN` を求める
   - `==> Installation successful!` と `==> Next steps:` が出ればよい。`Next steps` の `~/.bashrc` への追記は行わない
   - `command -v brew` が `/home/linuxbrew/.linuxbrew/bin/brew` を返す
   - `brew config` の `HOMEBREW_PREFIX` が `/home/linuxbrew/.linuxbrew` ならよい

1. IBus の GNOME 向けユーザーサービスの PATH を、Homebrew を含まない固定値にする。

   ```bash
   # IBus の PATH 設定を書き込む
   mkdir -p ~/.config/systemd/user/org.freedesktop.IBus.session.GNOME.service.d
   printf '%s\n' '[Service]' 'Environment=PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin' > ~/.config/systemd/user/org.freedesktop.IBus.session.GNOME.service.d/10-system-path.conf
   # ユーザーサービスの設定を読み直す
   systemctl --user daemon-reload
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user show org.freedesktop.IBus.session.GNOME.service -p Environment
   ```

   - `Environment=PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin` が出ればよい
   - GNOME で日本語入力を使う PC では、この手順を飛ばさない（[Homebrew の補足と注意点](#homebrew-の補足と注意点)の「Homebrew の手順 3: IBus の PATH を固定する理由」）
   - 効くのは、[再起動と確認](#再起動と確認)の手順 1 の再起動の後

#### Homebrew の使い方の基本

この文書の各項が使うコマンドはこれだけ。

| コマンド | 用途 |
|---|---|
| `brew install <formula>` | 入れる。ビルド済みのボトルがあれば `Pouring ...` と出て、ソースビルドは走らない |
| `brew list --versions` | 入っているものと版の一覧 |
| `brew leaves` | ほかの導入済み formula や cask から依存されていない formula の一覧。明示的に入れたものの履歴ではない |
| `brew info <formula>` | 版・依存・caveat（[gdu](#gdu) のような名前の注意書き） |
| `brew deps --tree <formula>` | 依存の木。単独で入れたときに何が付いてくるか |
| `brew outdated` | 更新できるものの一覧。何も無ければ無出力 |

- `brew install`・`brew upgrade` などの管理操作は、導入した一般ユーザーで行う
- [Homebrew を sudo でも使う](#homebrew-を-sudo-でも使う)を通しても、管理操作は一般ユーザーで行う
- 入れたコマンドを root のシェルでも使うなら [Homebrew を root のシェルでも使う](#homebrew-を-root-のシェルでも使う)を、`sudo <コマンド>` で使うなら [Homebrew を sudo でも使う](#homebrew-を-sudo-でも使う)を通す
- `brew install` の確認が出たら答えてから進む（[Homebrew の補足と注意点](#homebrew-の補足と注意点)の「注意点」）
- Homebrew からツールを入れる手順は、[Homebrew](#homebrew)の手順 1〜2 を前提にする。Trivy は dnf で入れる

#### Homebrew を root のシェルでも使う

- root のログインシェルでも、Homebrew で入れたコマンドを使う
- 前提: [Homebrew](#homebrew)と[共通の bash 設定を root に入れる](shell-terminal.md#共通の-bash-設定を-root-に入れる)（root 自身の clone と読み込み口）を通してある
- 実行場所: Homebrew を入れた自分のユーザーの端末（bash）
- root のシェルでも、同名の RPM コマンドより Homebrew が優先される（共通設定の `brew shellenv` が PATH の先頭に入れる）
- 自分専用のマシンで、一般ユーザーを信用できる場合だけ行う。root のシェルから Homebrew のユーザー所有のコマンドを実行するため
- `sudo <コマンド>` は別で、[Homebrew を sudo でも使う](#homebrew-を-sudo-でも使う)の `secure_path` を使う

1. root のログインシェルから Homebrew が見えることを確かめる。

   ```bash
   sudo -i bash -c 'printenv PATH; command -v brew'
   ```

   - `/home/linuxbrew/.linuxbrew/bin/brew` が出ればよい。`/root/.bashrc` に PATH の行は追記しない
   - `brew install` などは一般ユーザーで行う

#### Homebrew を sudo でも使う

- sudo の設定に 1 行のファイル（`/etc/sudoers.d/homebrew`）を置き、sudo がコマンドを探す PATH（`secure_path`）の末尾に、Homebrew の `bin` と `sbin` を足す
- 前提: [Homebrew](#homebrew)の手順 1〜2 を通してある
- 実行場所: Homebrew を入れた自分のユーザーの端末（bash）
- **`sudo <コマンド>` で Homebrew のコマンドを使わないなら、この項は不要**
- sudo を通らない `su -`、コンソールや ssh での root のログインには効かない。そちらは [Homebrew を root のシェルでも使う](#homebrew-を-root-のシェルでも使う)を通す
- RPM にも同じ名前のコマンドがあると、`sudo` では RPM のほうが使われる
- `brew install` などの管理操作は、この項を通しても一般ユーザーで行う（通常のホストでは `sudo brew install` などを `Running Homebrew as root is extremely dangerous …` で断られる）

> [!WARNING]
> - `/home/linuxbrew/.linuxbrew` は Homebrew を入れたユーザーの所有。`sudo` で打ったコマンドが `/usr/bin` などに無いと、そのユーザーが書き換えられるプログラムを root の権限で動かすことになる（そのユーザーを乗っ取られると、root まで取られる）
> - sudo の設定はホスト全体にかかる。このホストで `sudo` を使う、ほかのユーザーにも効く

1. sudo の `secure_path` の末尾に Homebrew を足すファイルを置き、`sudo` の PATH を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # sudo の PATH 設定を検査して書き込む
   if sudo printenv PATH | grep -q /home/linuxbrew; then echo '中断: sudo の PATH に Homebrew が既にある' >&2
   elif [ "$(sudo printenv PATH)" != /sbin:/bin:/usr/sbin:/usr/bin ]; then echo '中断: sudo の PATH が AlmaLinux 10 の既定（/sbin:/bin:/usr/sbin:/usr/bin）と違う' >&2
   else
     line='Defaults secure_path = /sbin:/bin:/usr/sbin:/usr/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin'
     echo "${line}" | sudo visudo -cf - && echo "${line}" | sudo install -m 0440 /dev/stdin /etc/sudoers.d/homebrew
     sudo visudo -c
   fi
   # sudo の PATH と brew の場所を確かめる
   sudo bash -c 'printenv PATH; command -v brew'
   ```

   - `stdin: parsed OK`・`/etc/sudoers: parsed OK`・`/etc/sudoers.d/homebrew: parsed OK` の 3 行が出る
     - `/etc/sudoers.d` にほかのファイル（[ログインと sudo](#ログインと-sudo)の手順 3 の `nopasswd` など）があれば、その行も出る
     - 日本語のロケール（`ja_JP.UTF-8`）では、`parsed OK` は `正しく構文解析されました` と出る
   - 最後の 2 行で、PATH の末尾が `:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin` で、`/home/linuxbrew/.linuxbrew/bin/brew` が出ればよい
   - `中断:` と出たら、何も書き換えていない（最後の 2 行は出る）
     - `既にある` なら、この項は通してある。最後の 2 行で確かめる
     - `既定と違う` なら、`secure_path` がほかで変えてある（`sudo grep -rn secure_path /etc/sudoers /etc/sudoers.d` で探す）。そのホストでは、この項は使わない
   - 開いたままの root のシェル（`sudo -s` など）には効かない。開き直す

<details id="homebrew-の補足と注意点">
  <summary>Homebrew の補足と注意点</summary>

**注意点**

- **Homebrew と同じ名前の実行ファイルを、EPEL から二重に入れない**: 例えば EPEL の `fd-find` は `/usr/bin/fd` を置く。両方入れると、PATH の先頭の Homebrew 版が使われ、`dnf upgrade` で上がるのは使われないほうになる（[btop の補足と注意点](#btop-の補足と注意点)の「注意点」）

- **Homebrew の導入・更新は一般ユーザーで行う**: 通常のホストでは、インストーラや `brew install` などの管理操作は root を拒否する。ただし**実行するユーザーが `sudo` できる必要がある**（`/home/linuxbrew` を作るため）

- **Homebrew の導入先を変えるとすべてソースビルドになる**: 検証記録（`docs/verification/almalinux-setup.md` の「Homebrew の記録」）

- **PATH の先頭が Homebrew になる**: `brew shellenv` は `/home/linuxbrew/.linuxbrew/bin` を `PATH` の**先頭**に足す。同じ名前の RPM が入っていると Homebrew 版が勝つ（bat・[gdu](#gdu) で実際に問題になる）
  - `python3` も Homebrew 版が先に見つかる。この版には `gi` が無いので、PyGObject を使う処理は `/usr/bin/python3` で呼ぶ。GNOME の日本語入力には、[Homebrew](#homebrew)の手順 3 を通す

- **`sudo <tool>` は、そのままでは使えない**: sudo の PATH（`secure_path`）にも root の `PATH` にも、Homebrew は入っていない
  - `sudo <tool>` で使うなら、[Homebrew を sudo でも使う](#homebrew-を-sudo-でも使う)の節を通す（`sudo -s`・`sudo -i` のシェルでも使えるようになる）
  - root のシェル（`su -`、root のログイン、`sudo -i`）で使うなら、[Homebrew を root のシェルでも使う](#homebrew-を-root-のシェルでも使う)の節を通す
  - どちらも通さないなら、RPM で入れるか、フルパス（`/home/linuxbrew/.linuxbrew/bin/<tool>`）を渡す。bat で root のファイルを読むなら、`sudo cat` か、フルパスの `sudo /home/linuxbrew/.linuxbrew/bin/bat`

- **`brew install` は、依存や依存先も含む計画なら端末で `[y/n]` を聞く**（Homebrew 7.0.7 の既定の ask mode）
  - ブラケットペーストが効く bash 5.1 以降では、同じ入力の後ろの行は確認の答えとして読まれず、`[y/n]` に答えた後に動く
  - 7.0.7 のヘルプでは、指定した formula / cask だけを入れる計画と、TTY が無い実行では確認を省く。端末では表示に従い、確認を求められたら答える
  - `brew upgrade` も 7.0.7 では ask mode が既定。名前を指定した場合はその名前以外も更新する計画、名前を省略した場合は更新対象があるときに、TTY で確認する
  - 確認が出たら導入・更新の計画を確かめ、表示に従って答える。確認を省く指定は `HOMEBREW_NO_ASK=1`、または `brew install` / `brew upgrade` の `--no-ask` / `--yes` / `-y`

- **不要な依存は自動で消えることがある**: Homebrew 7.0.7 の `brew uninstall` と `brew cleanup` は、不要になった依存を既定で自動削除する
  - 自動削除を止めるときは、そのコマンドに `HOMEBREW_NO_AUTOREMOVE=1` を付ける。明示的な `brew autoremove` は、残った不要な依存を消すための操作

- **`~/.bashrc` を読まない文脈では見えない**: cron や一部の非対話シェルでは `brew shellenv` が走らないので、Homebrew で入れたコマンドが見つからない。スクリプトからはフルパスで呼ぶ

- **Homebrew はユーザーごとではなく、ホストに 1 つ**: `/home/linuxbrew` は共有なので、別ユーザーが使うには、そのユーザーにも bash の共通設定を導入する（書き込みには所有者の権限が要る）

- 古い版とキャッシュを掃除するなら `brew cleanup` を実行する

- **Homebrew は匿名の利用統計が既定で有効**: 止めるなら `brew analytics off`

**[Homebrew](#homebrew)の手順 2: Next steps を行わない理由**

- `Next steps` の `~/.bashrc` への追記を行わないのは、共通の bash 設定が `brew shellenv` を読むため

**[Homebrew](#homebrew)の手順 2: 日々の操作**

- 日々の操作は[Homebrew の使い方の基本](#homebrew-の使い方の基本)

**[Homebrew](#homebrew)の手順 3: IBus の PATH を固定する理由**

- Anthy のエンジン（`/usr/libexec/ibus-engine-anthy`）は、`exec python3 /usr/share/ibus-anthy/engine/main.py` と書かれた sh の包みで、PATH で最初に見つかった `python3` で動く
- 共通の bash 設定は、Homebrew のディレクトリを PATH の先頭に置く。2026-10-11 の Hyper-V の VM では、`gnome-shell` と `ibus-daemon` の環境にも Homebrew を含む PATH があった。セッションへ取り込まれる具体的な経路は、確かめていない
- Homebrew の `python3` は、formula の依存として入る（2026-10-11 は、[yazi](#yazi)の手順 2 の既定のツールで `python@3.15` が入った）。この `python3` には `gi`（PyGObject）が無いので、エンジンが `ModuleNotFoundError: No module named 'gi'` で起動しない
  - 上部バーの表示は `あ` に変わるが、打った字は英字のまま入り、Space でも変換されない
  - `ibus list-engine` は、エンジンが起動できない状態でも `anthy - Anthy` を出す。FXB では、入力不能の状態でも journal の `ModuleNotFoundError` は 0 行だった。この行が無いことだけでは、復旧したと判断できない
  - 入力不能の状態で出たのは、gnome-shell の `Gio.IOErrorEnum: タイムアウトしました`（`_setEngine`）。切り替えた後も `ibus engine` は `xkb:us::eng` のままで、Anthy のエンジンのプロセスは無かった。包みをその PATH で `--xml` 付きで呼ぶと、`ModuleNotFoundError` が出た
- GNOME のユーザーサービス `org.freedesktop.IBus.session.GNOME.service` が `ibus-daemon` を起動する（FXA・FXB の `systemctl --user show` の起動コマンド・PID と、プロセスの環境を照合）。ドロップインは、このユニットの PATH だけを `/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin` に置き換える
  - Homebrew を含まない、決め打ちの PATH であり、systemd のユーザーマネージャーの既定値を写したものではない。`~/.local/bin`・`~/bin` なども、このユニットの PATH から外れる
  - FXA のドロップインを置く前の `ibus-daemon` の PATH は、`/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/home/<USER>/.local/bin:/home/<USER>/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin` だった（Homebrew 本体は導入済み。`FXA/out/02-baseline-before-step4.txt`）。Homebrew 導入前のユーザーマネージャーの PATH は、今回の証跡では確かめていない
  - 検証した VM では、この設定の後に起動した `ibus-daemon` から、Anthy のエンジンは `/usr/bin/python3` で起動された。端末と `gnome-shell` の PATH は変わらない
  - GNOME 以外のセッションや、別の経路で `ibus-daemon` を起動する構成は対象の外で、確かめていない。セッションの PATH で起動される `/usr/libexec/ibus-setup-anthy`（Anthy の設定）が開くかも、確かめていない
- 2026-10-11 の通しでは、Hyper-V・VMware・VirtualBox の VM で、この設定が無いと変換できなかった。直しの確かめは Hyper-V の VM に限る（検証記録（`docs/verification/almalinux-setup.md` の「手順書を直した所と、その確かめ」））
  - FXA では、Homebrew の `python3` が無い状態で記録の手順 4 を置き、[yazi](#yazi)の手順 2 で `python@3.15` を入れ、再起動した後に、テキストエディターで「日本語」への変換と確定を確かめた
  - FXB では、入力不能の状態から記録の手順 4 と再起動を通し、テキストエディターと WezTerm の Neovim で日本語入力と IME 切り替えを確かめた。Neovim の整形は、初めから整形済みで、変化を見分けられなかった
  - ログインし直しだけで効くこと・VMware・VirtualBox・実機での直しは、確かめていない

**[Homebrew を root のシェルでも使う](#homebrew-を-root-のシェルでも使う)のリード**


- root のログインシェルでも、Homebrew で入れたコマンドを使う。PATH は、root に入れた共通の bash 設定が足す

**[Homebrew を root のシェルでも使う](#homebrew-を-root-のシェルでも使う)の手順 1: シェルごとの PATH**

| 入口 | 読むファイル | Homebrew のコマンド |
|---|---|---|
| `su -`、ssh での root のログイン | `/etc/profile` → `/root/.bash_profile` → `/root/.bashrc` | 使える |
| `sudo -i` | 同上。PATH の始まりは sudo の `secure_path` | 使える |
| `sudo -s`、`su`（`-` 無し） | `/root/.bashrc`（`sudo -s` でも `HOME` は `/root`） | 使える |
| `sudo <コマンド>` | 読まない。PATH は `secure_path` の `/sbin:/bin:/usr/sbin:/usr/bin` | 使えない（`sudo: jq: command not found`）。[Homebrew を sudo でも使う](#homebrew-を-sudo-でも使う)の節で使える |

- **`su`（`-` 無し）も、Homebrew のユーザーの PATH を引き継がない**: PATH は root のものに置き換わる
- **cron や systemd の unit では見えない**: `~/.bashrc` を読まないため（この折りたたみの「注意点」の「`~/.bashrc` を読まない文脈」と同じ）。フルパスで書く

**[Homebrew を sudo でも使う](#homebrew-を-sudo-でも使う)のリード**

- `sudo nvim /etc/hosts` や `sudo gdu-go /` のように、`sudo <コマンド>` で使えるようになる。`sudo -s`・`sudo -i` で開いた root のシェルでも使える

- `EDITOR=nvim` の `sudoedit` も、自分の設定の Homebrew の `nvim` で開くようになる（この項の前は、黙って `vi` で開く）

**[Homebrew を sudo でも使う](#homebrew-を-sudo-でも使う)の手順 1: 使い方**

- Homebrew で入れたコマンドを、`sudo jq --version` のように打てる
- `sudo` でどれが使われるかは、`sudo bash -c 'type -a <コマンド>'` で見る（先頭の行が使われる）

**[Homebrew を sudo でも使う](#homebrew-を-sudo-でも使う)の手順 1: 呼び出し方ごとの PATH**

| 入口 | PATH | Homebrew のコマンド |
|---|---|---|
| `sudo <コマンド>`、`sudo -u <ユーザー> <コマンド>`、`sudo bash <スクリプト>` | `secure_path`（`/sbin:/bin:/usr/sbin:/usr/bin` の後ろに 2 つ） | 使える（`sudo jq --version` は `jq-1.8.2`） |
| `sudo -E <コマンド>` | 同上（`-E` でも、自分の PATH は渡らない） | 使える |
| `sudo -s` | `/root/.local/bin:/root/bin` の後ろに `secure_path` | 使える（PATH の末尾） |
| `sudo -i` | `/root/.local/bin:/root/bin:/usr/local/sbin` の後ろに `secure_path` | 使える（PATH の末尾） |
| `sudoedit`（`EDITOR=nvim`） | エディタを `secure_path` で探し、自分のユーザーと自分の環境で動かす | Homebrew の `nvim`。設定は自分の `~/.config/nvim` |
| `sudo EDITOR=nvim visudo` | エディタを `secure_path` で探し、root で動かす | Homebrew の `nvim`。設定は `/root/.config/nvim` |
| `su -`、`sudo su -`、ssh での root のログイン | sudo の `secure_path` を通らない | 使えない（[Homebrew を root のシェルでも使う](#homebrew-を-root-のシェルでも使う)の節で使える） |

**選択した方針**

- **Homebrew に揃える判断の実質は「更新の一元化」**: `brew upgrade` 1 本で、Homebrew から入れたものがまとめて上がる

**参照**

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

---

### Homebrew のオフライン導入

- インターネットに出られないホスト（以下、オフラインのホスト）に、SSH の SOCKS トンネル越しに Homebrew を入れる。トンネルの出口は、インターネットに出られるホスト（以下、オンラインのホスト）
- 前提: [SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1〜3 を、接続元をオンラインのホスト、接続先をオフラインのホストとして通してある。オフラインのホストには、[共通の bash 設定](shell-terminal.md#共通の-bash-設定)の手順 1・2 を、そのトンネルのシェルで通してある
- 実行場所: トンネルを張ってログインした、オフラインのホストの自分のユーザーのシェル（`ALL_PROXY` を入れたシェル。Homebrew の通信にもトンネルを使う）。この項の手順 5 には、オンラインのホストで行う操作がある
- この項の手順 3 で貼る[Homebrew](#homebrew)の手順 1〜3（同じ項の手順 3 は、GNOME で日本語入力を使う PC だけ）も、同じシェルのまま貼る
- **オフラインのホストには、`sudo` できる自分のユーザーでログインする**（[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1 の `OFFLINE_USER`）。root ではログインしない（Homebrew の導入・更新は root では行わない）
- Neovim の Mason に npm のパッケージを入れるなら、この項の手順 5 でトンネルを閉じる前に、このシェルで [npm のオフライン導入](#npm-のオフライン導入) を貼る（npm は `ALL_PROXY` を読まない）

> [!WARNING]
>
> - トンネルを張っている間は、オフラインのホストのどのユーザーもインターネットに出られる（出口はオンラインのホスト。[SSH の SOCKS トンネル の補足と注意点](#ssh-の-socks-トンネル-の補足と注意点)の「注意点」）。使い終わったら、この項の手順 5 で閉じる

1. トンネルのシェルで、Homebrew の取得先に届くかと、Homebrew が使うパッケージを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # Homebrew の取得先への接続を確かめる
   for u in https://github.com https://raw.githubusercontent.com https://formulae.brew.sh https://ghcr.io/v2/; do
     printf '%-34s %s\n' "$u" "$(curl -sS -o /dev/null --connect-timeout 10 -w '%{http_code}' "$u")"
   done
   # 依存パッケージの導入状態を確かめる
   rpm -q procps-ng curl file git
   ```

   - 4 つの URL の数字が、どれも `000` 以外なら届いている（ghcr.io は `401`）
   - `000` と `Failed to connect to 127.0.0.1 port 1080` が出たら、トンネルか `ALL_PROXY` が無い。[SOCKS トンネル](#ssh-の-socks-トンネル)の手順 2 からやり直す
   - `rpm -q` の 4 つがどれも入っていれば、**この項の手順 2 は飛ばし、この項の手順 3 でも[Homebrew](#homebrew)の手順 1 を飛ばす**
   - dnf がトンネル無しで届くリポジトリ（社内のミラーなど）を使うホストなら、この項の手順 2 は飛ばす

1. この項の手順 1 で入っていないパッケージがあったときだけ、[SSH の SOCKS トンネルの「dnf にもトンネルを使わせる」](#ssh-の-socks-トンネル-dnf-にもトンネルを使わせる)を行う。

   - **次の手順は、その項の `Metadata cache created.` が出てから貼る**

1. この項の手順 1 のシェルのまま、[Homebrew](#homebrew)の手順 1〜3 を貼る。

   - `command -v brew` が `/home/linuxbrew/.linuxbrew/bin/brew` を返すなら、[Homebrew](#homebrew)の手順 1〜2 は飛ばす
   - [Homebrew](#homebrew)の手順 1 の dnf は、この項の手順 2 の設定で通る（この項の手順 1 で 4 つとも入っていたなら飛ばす）
   - [Homebrew](#homebrew)の手順 2 は、[共通の bash 設定](shell-terminal.md#共通の-bash-設定)の手順 1・2 を入れてあるシェルで貼る
   - [Homebrew](#homebrew)の手順 3 は、GNOME で日本語入力を使う PC だけで貼る。Homebrew が入っていても、この手順は飛ばさない
   - **次の手順は、[Homebrew](#homebrew)の手順 2（GNOME で日本語入力を使う PC は同じ項の手順 3）まで終えてから貼る**（導入結果と、必要な PC では IBus の PATH 固定を確かめてから、jq の導入へ進む）

1. 確かめるために、brew で jq をトンネル越しに入れる。

   ```bash
   brew install jq
   ```

   - 入れるものの一覧の後に `==> Do you want to proceed with the installation? [y/n]` と聞かれたら、`y` を押す（Enter は要らない）
   - `Pouring` が出て、ソースからのビルドにならなければよい
   - ほかの Homebrew で入れる項も、この項の手順 5 の前に、このシェルで貼る
   - **次の手順は、確認が出たら `y` を押し、入れ終わってから貼る**（続けて進むと、導入を断ったときや失敗したときもトンネルを閉じることになる）

1. [SSH の SOCKS トンネルの「トンネルを閉じる」](#ssh-の-socks-トンネル-トンネルを閉じる)の手順 1〜4 で、トンネルを閉じて、転送を付けずにログインし直す。

   - その項で `exit` した後の、転送を付けないログインは、オンラインのホストで行う
   - その項の最後の確かめで、`ss` が何も出さず、`届かない（期待どおり）` になることを確かめる
   - **次の手順は、ログインし直したオフラインのホストのシェルで貼る**

1. オフラインのホストで、トンネルが無くても jq が動くことを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # jq の版と実行ファイルの場所を確かめる
   brew list --versions jq
   command -v jq
   # JSON の値を取り出して確かめる
   echo '{"host": "offline"}' | jq -r .host
   ```

   - jq の版、Homebrew のパス、`offline` が出ればよい

#### Homebrew のオフライン導入: 更新

- オフラインのホストで、SSH の SOCKS トンネル越しに Homebrew と、Homebrew で入れたものを上げる
- 前提: [Homebrew のオフライン導入](#homebrew-のオフライン導入)を通してある。[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1〜3 で、トンネルを張り直してある
- 実行場所: トンネルを張ってログインした、オフラインのホストの自分のユーザーのシェル（`ALL_PROXY` を入れたシェル）

1. [共通の bash 設定・Homebrew・Flatpak を上げる](#共通の-bash-設定homebrewflatpak-を上げる)の手順 2・3 を貼る。

   - `brew outdated` が何も出さなければ、上げるものは無いので、[共通の bash 設定・Homebrew・Flatpak を上げる](#共通の-bash-設定homebrewflatpak-を上げる)の手順 3 は飛ばす
   - `brew upgrade` が `[y/n]` と聞いたら、`y` を押す（[Homebrew のオフライン導入](#homebrew-のオフライン導入)の手順 4 と同じ確認）
   - **次の手順は、上げ終わってから行う**（続けて進むと、更新を断ったときや失敗したときもトンネルを閉じることになる）

1. [SSH の SOCKS トンネルの「トンネルを閉じる」](#ssh-の-socks-トンネル-トンネルを閉じる)の手順 1 で、トンネルを閉じる。

<details id="homebrew-のオフライン導入-の補足と注意点">
  <summary>Homebrew のオフライン導入 の補足と注意点</summary>

**注意点**

- **トンネルそのものの注意は、[SSH の SOCKS トンネル の補足と注意点](#ssh-の-socks-トンネル-の補足と注意点)の「注意点」**: 転送中はオフラインのホストのどのユーザーもプロキシを使える、出口はオンラインのホスト、`socks5h` の `h`、`https_proxy` が勝つ、`sudo` は `ALL_PROXY` を渡さない、dnf の行が残る
- **`sudo brew` はもともと使えない**: [Homebrew の補足と注意点](#homebrew-の補足と注意点)の「注意点」
- **ほかの手順書の `sudo dnf` も、[Homebrew のオフライン導入](#homebrew-のオフライン導入)の手順 2 を行ったときだけ通る**: [HackGen Console NF](shell-terminal.md#hackgen-console-nf)の手順 3（`unzip`）は、dnf の設定で通った
- **トンネルが要るのは、取得するときだけ**: `brew install` / `brew update` / `brew upgrade` は要る。`brew list` / `brew uninstall` / `brew autoremove` は要らない
  - トンネル無しの `brew install hello` は、`curl: (6) Could not resolve host: ghcr.io` と `Error: Failed to download resource "hello"` で失敗した
- **brew は、依存が付くときに `[y/n]` を聞く**: ほかの Homebrew 系の手順書の `brew install` でも、端末から実行すると同じように聞かれる（[Homebrew の補足と注意点](#homebrew-の補足と注意点)の「注意点」）
- **ssh が切れると、トンネルも消える**: 途中の `brew install` や dnf は、取得の途中なら失敗するはず。そのときは [SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 2 から張り直して、同じコマンドを貼り直す
- **入れた後もネットワークを使うツールは、オフラインのホストではその部分が動かない**: たとえば外部の API を呼ぶ処理や、LAN の外の端末との同期

**[Homebrew のオフライン導入](#homebrew-のオフライン導入)のリード**

- **[Homebrew のオフライン導入](#homebrew-のオフライン導入)の手順 3・4 には対話入力がある**（インストーラの `RETURN`、brew の `[y/n]`）。終わってから次の手順を貼る

**[Homebrew のオフライン導入](#homebrew-のオフライン導入)の手順 1: ghcr.io の 401**

- ghcr.io が `401` になるのは、トークンが無いため

**[Homebrew のオフライン導入](#homebrew-のオフライン導入)の手順 2: dnf の設定**

- AlmaLinux 10 の初期設定の[Homebrew](#homebrew)の手順 1 の dnf が、トンネルを通るようになる

**[Homebrew のオフライン導入](#homebrew-のオフライン導入)の手順 3: Homebrew の導入とトンネル**

- AlmaLinux 10 の初期設定の[Homebrew](#homebrew)の手順 2 のインストーラも、中で使う curl と git が `ALL_PROXY` を読むので、そのまま通る
- 同書の[Homebrew](#homebrew)の手順 2 を共通の bash 設定を入れてあるシェルで貼るのは、`brew shellenv` を共通設定が実行するため

- GNOME で日本語入力を使う PC は、同書の[Homebrew](#homebrew)の手順 3 も通す。このオフライン経路での実行は未確認。

**[Homebrew のオフライン導入](#homebrew-のオフライン導入)の手順 4**

- `==> Pouring jq--…bottle…tar.gz` と出て、ソースからのビルドにならない

**[Homebrew のオフライン導入](#homebrew-のオフライン導入)の手順 6**

- `jq 1.8.2` のような版、`/home/linuxbrew/.linuxbrew/bin/jq`、`offline` が出る

**選択した方針**

この方針の検証記録（`docs/verification/homebrew-offline.md` の「選択した方針」）

| 経路 | 要るもの | 採否 |
|---|---|---|
| **ssh の SOCKS トンネル（[SSH の SOCKS トンネル](#ssh-の-socks-トンネル) の `ssh -R 1080`）で、オフラインのホストから取得する** | オンラインのホストからオフラインのホストへ ssh でログインできること。どちらのホストにも追加のソフトは要らない | **採用。** オフラインのホストで curl・git・brew・dnf がそのまま外に届き、AlmaLinux 10 の初期設定の Homebrew の手順とほかの Homebrew 系の手順書を変えずに貼れる。オフラインのホストが自分のアーキのボトルを取るので、2 台のアーキが違ってもよい。トンネルの張り方どうしの比較（`-D`・HTTP プロキシ）は、SOCKS トンネルの参考資料の[SSH の SOCKS トンネル の補足と注意点](#ssh-の-socks-トンネル-の補足と注意点)の「選択した方針」 |
| `/home/linuxbrew/.linuxbrew` を tar にして運ぶ | 同じ OS・同じアーキのホストで Homebrew と formula を入れる。上げるたびに作り直して運ぶ | 本書では扱わない（ネットワークで届かないときの方法） |
| `brew fetch` でボトルだけを運ぶ | Homebrew 本体（git のリポジトリと portable-ruby）と、formula の API の JSON も要る | 本書では扱わない |

- **Homebrew の導入（AlmaLinux 10 の初期設定の[Homebrew](#homebrew)の手順 1〜2）を、リードで前提として挙げるのではなく、[Homebrew のオフライン導入](#homebrew-のオフライン導入)の手順 3 にした**: ほかの Homebrew 系の手順書と違い、トンネルを張ったシェルの中で貼る必要があるため
- **トンネルの手順は、AlmaLinux 10 の「SSH の SOCKS トンネル」を前提にした**: [npm のオフライン導入](#npm-のオフライン導入) でも、同じトンネルを使う
  - [VirtualBox の bootc ゲスト: ホストオンリーアダプターだけの VM でビルドする](virtual-machines.md#virtualbox-の-bootc-ゲスト-ホストオンリーアダプターだけの-vm-でビルドする) の現行手順は、オンラインのホストでビルドしたイメージを VM に運ぶ方式で、トンネルは使わない

**参照**

- [SSH の SOCKS トンネル](#ssh-の-socks-トンネル) — 前提の手順書（トンネルの張り方・dnf の設定・閉じ方。ssh・curl・git・dnf の参照もそちら）
- [Homebrew — Manpage の USING HOMEBREW BEHIND A PROXY](https://docs.brew.sh/Manpage#using-homebrew-behind-a-proxy) — Homebrew が読むプロキシの環境変数
- [Homebrew](#homebrew)の手順 1〜2 — [Homebrew のオフライン導入](#homebrew-のオフライン導入)の手順 3 で貼る Homebrew 本体の導入手順


- 検証記録（`docs/verification/homebrew-offline.md`）

</details>

---

### dnf-automatic で自動で更新する

- BaseOS の `dnf-automatic` のタイマーで、毎日、更新をダウンロードして入れる。再起動はしない（カーネルなどの更新は、[OS とファームウェアの更新](#os-とファームウェアの更新)の手順 2 の `dnf needs-restarting -r` で要否を確かめ、要るときだけ同じ項の手順 3 で再起動する）
- 前提: [ログインと sudo](#ログインと-sudo)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）

1. dnf-automatic を入れる。

   ```bash
   sudo dnf install dnf-automatic
   ```

   - `インストール:` が `dnf-automatic` の 1 つだけになる。`これでよろしいですか? [y/N]:` に `y`
   - **次の手順は、`完了しました!` が出てプロンプトに戻ってから貼る**（続けて貼ると、導入を断ったときや失敗したときもタイマーを有効にする行が動く）

1. 更新を入れるタイマーを有効にする。

   ```bash
   # 自動更新のタイマーを有効にする
   sudo systemctl enable --now dnf-automatic-install.timer
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl list-timers 'dnf-automatic*' --no-pager
   ```

   - `dnf-automatic-install.timer` の行に、次に動く日時（`NEXT`）が出ればよい

1. GNOME Software の自動の更新を止める。

   ```bash
   # GNOME Software の自動取得を無効にする
   /usr/bin/gsettings set org.gnome.software download-updates false
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.software download-updates
   ```

   - `false` が出ればよい

1. 今すぐ 1 回動かして、動くことを確かめる。

   ```bash
   # 自動更新を手動で開始する
   sudo systemctl start dnf-automatic-install.service
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl status dnf-automatic-install.service --no-pager | head -n 5
   journalctl -u dnf-automatic-install.service -b --no-pager | tail -n 5
   ```

   - `Active: inactive (dead)` と、`… Finished dnf-automatic-install.service …` の行が出ればよい（更新が無ければすぐに終わる）
   - 更新があれば、入れ終わるまでプロンプトに戻らない

<details id="dnf-automatic-で自動で更新する-の補足と注意点">
  <summary>dnf-automatic で自動で更新する の補足と注意点</summary>

**[dnf-automatic で自動で更新する](#dnf-automatic-で自動で更新する)のリード**

- GNOME Software の自動の更新（裏でダウンロードし、再起動のときに入れる）は、[dnf-automatic で自動で更新する](#dnf-automatic-で自動で更新する)の手順 3 で止める（二重にしない）

**[dnf-automatic で自動で更新する](#dnf-automatic-で自動で更新する)の手順 2: 入れる更新の設定**

- 何を入れるか（`upgrade_type`）などは `/etc/dnf/automatic.conf` にある。このタイマーは、その設定の `apply_updates` に関わらず、更新を入れる

**[dnf-automatic で自動で更新する](#dnf-automatic-で自動で更新する)の手順 3: GNOME Software の設定**

- `download-updates` を `false` にすると、GNOME Software の「設定」の「自動更新」がオフになる
- 更新があることの通知と、手で入れる更新は、そのまま使える

**選択した方針**

- **dnf-automatic**: `dnf-automatic-install.timer` で、毎日更新を入れる（再起動はしない）。GNOME Software の自動の更新（`download-updates`）は切る。2 つの仕組みが同じ更新を落とし合わないようにするため

**参照**

- [dnf-automatic](https://dnf.readthedocs.io/en/latest/automatic.html) — `dnf-automatic-install.timer` と `/etc/dnf/automatic.conf`

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

---

### Secure Boot の署名鍵

- Secure Boot が有効な PC（または VM）で、自分でビルドしたカーネルモジュールを読み込めるように、署名用の鍵を作って MOK に登録する
- 前提: [ログインと sudo](#ログインと-sudo)を通してある（bootc のシステムでは、`sudo` できるユーザーでログインしてある）
- 実行場所: Secure Boot を使う PC（または VM）の、自分のユーザーの端末（bash）か SSH
- **カーネルモジュールをビルドする項より先に通す**。この項の手順 3 で Secure Boot が無効と分かったら、この項はそこで終わり
- bootc のシステム（AlmaLinux Atomic Desktop など）でも同じ手順になる

> [!IMPORTANT]
> - **この項の手順 5 を SSH で貼る前に、VM のウィンドウを開いておく**（再起動直後の MokManager を操作するため）
> - **この項の手順 6 は、起動の途中の MokManager の画面で行う**（最初の画面は 10 秒で消える。VM なら VM のウィンドウで操作する）

1. `mokutil` と `openssl` が入っているか確かめる。

   ```bash
   rpm -q mokutil openssl
   ```

   - 2 つとも版が出れば、手順 2 は飛ばす
   - `package mokutil is not installed` のように出たら、手順 2 で入れる

1. どちらかが未導入のときだけ、`mokutil` と `openssl` を入れる。

   ```bash
   sudo dnf install -y mokutil openssl
   ```

   - bootc のシステムでは dnf で入れられないが、Atomic Desktop のイメージには 2 つとも入っている

1. Secure Boot が有効かを見る。

   ```bash
   mokutil --sb-state
   ```

   - `SecureBoot enabled` なら、手順 4 から続ける
   - **`SecureBoot disabled`（または `EFI variables are not supported on this system`）なら、この項の手順はここで終わり**

1. 鍵がまだ無いときだけ、署名用の鍵を作り、MOK への登録を予約する。

   ```bash
   # 署名鍵の有無を確かめる
   if sudo test -e /var/lib/shim-signed/mok/MOK.der; then echo '中断: 鍵が既にある。作り直さずに、手順 7 で登録を確かめる' >&2; else
     # 署名鍵と証明書を生成する
     sudo mkdir -m 0700 -p /var/lib/shim-signed/mok
     sudo openssl req -nodes -new -x509 -newkey rsa:2048 -outform DER -addext "extendedKeyUsage=codeSigning" -subj "/CN=Local kernel module signing key/" -days 36500 -keyout /var/lib/shim-signed/mok/MOK.priv -out /var/lib/shim-signed/mok/MOK.der
     printf '\n\033[7m 確認 \033[0m\n'
     # 署名鍵のファイルを確かめる
     sudo ls -l /var/lib/shim-signed/mok
     # 署名鍵の登録を予約する
     sudo mokutil --import /var/lib/shim-signed/mok/MOK.der
   fi
   ```

   - `MOK.priv`（秘密鍵。`-rw-------`）と `MOK.der`（公開鍵の証明書）ができる
   - **`MOK.priv` は登録した鍵で信頼するモジュールを作れる秘密鍵**。root 以外に読ませず、ほかのマシンに持ち出さない
   - **場所とファイル名は変えない**
   - **一時パスワードを 2 回聞かれる**（手順 6 の MokManager で 1 回だけ使う。本書には残さない）
   - `中断: 鍵が既にある` と出たら、前に作った鍵がある。手順 7 へ進む
   - ホストオンリーだけの VM は、この手順の代わりに[オフラインビルド](virtual-machines.md#virtualbox-の-bootc-ゲスト-ホストオンリーアダプターだけの-vm-でビルドする)の手順 2〜5 を通す
   - 鍵はホストで作り、証明書だけを VM に置いて予約する。手順 5 からは同じ
   - 鍵を作る間は `.....+++` のような行が流れる
   - **次の手順は、一時パスワードに答えてから貼る**（続けて貼ると、登録の予約に失敗したときも再起動の行が動く）

1. 再起動する。

   ```bash
   sudo systemctl reboot
   ```


1. 起動の途中の MokManager で、鍵を登録する。

   - 最初の画面の `Press any key to perform MOK management` は、`Booting in 10 seconds` から数え下げて 10 秒で消える。消える前に何かキーを押す（VM なら、VM のウィンドウで押す）
   - 続けて `Enroll MOK` → `Continue` → `Yes` → 手順 4 の一時パスワード → `Reboot` と進む
   - **何もしないで進むと登録されない**。そのときは `sudo mokutil --import /var/lib/shim-signed/mok/MOK.der`（手順 4 の最後の行）を貼り直してから、手順 5 からやり直す
   - **注意**: MokManager でキーボードが効かない PC がある（検証記録: `docs/verification/secure-boot-mok.md` の「実施手順 / 手順 6: 補足: 画面の並びと、登録できなかった PC」の手順 6 の補足を参照）
   - **次の手順は、起動したらログインし、新しい端末を開いてから貼る**

1. 鍵が登録されたか確かめる。

   ```bash
   sudo mokutil --test-key /var/lib/shim-signed/mok/MOK.der
   ```

   - `/var/lib/shim-signed/mok/MOK.der is already enrolled` が出れば、登録できている
   - 登録できていなければ `is not enrolled` になる。手順 6 の箇条書きのとおりやり直す

<details id="secure-boot-の署名鍵-の補足と注意点">
  <summary>Secure Boot の署名鍵 の補足と注意点</summary>

**注意点**

- MokManager の画面を逃すと、登録の予約も消える
- **鍵を作り直したら、署名したモジュールも作り直す**: bootc のゲストでは、ビルドに `--no-cache` を足す（[VirtualBox の bootc ゲスト: 更新](virtual-machines.md#virtualbox-の-bootc-ゲスト-更新)）

**[Secure Boot の署名鍵](#secure-boot-の署名鍵)のリード**

- **[Secure Boot の署名鍵](#secure-boot-の署名鍵)の手順 4 で一時パスワードを 2 回聞かれ、[Secure Boot の署名鍵](#secure-boot-の署名鍵)の手順 5 で再起動する**。答えてから次の手順を貼る

- 通すと使えるようになるもの（この鍵で署名したモジュールが、Secure Boot のまま読み込まれる）:
  - [VirtualBox](virtual-machines.md#virtualbox) のホストのモジュール（`vboxdrv` など）
  - [VirtualBox の bootc ゲスト](virtual-machines.md#virtualbox-の-bootc-ゲスト) のモジュール（`vboxguest` など）

**[Secure Boot の署名鍵](#secure-boot-の署名鍵)の手順 1: 2 つの役目と、入っていた環境**

- `mokutil` は、Secure Boot が有効かを見る（[Secure Boot の署名鍵](#secure-boot-の署名鍵)の手順 3）のと、MOK への登録の予約と確認（[Secure Boot の署名鍵](#secure-boot-の署名鍵)の手順 4・7）に使う。`openssl` は鍵を作る（[Secure Boot の署名鍵](#secure-boot-の署名鍵)の手順 4）
- VirtualBox（`docs/verification/virtualbox.md` の「実施前の状態」）の実機（GNOME の PC）と、VirtualBox の bootc ゲスト（`docs/verification/virtualbox-guest-bootc.md` の「実施前の状態」）の VM（Atomic Desktop のイメージ）には、どちらも入っていた
- 素のコンテナ（`quay.io/almalinuxorg/almalinux:10`）には、どちらも無かった

**[Secure Boot の署名鍵](#secure-boot-の署名鍵)の手順 2: bootc のシステム**

- bootc のシステムで dnf で入れられないのは、`/usr` が読み取り専用だから

**[Secure Boot の署名鍵](#secure-boot-の署名鍵)の手順 3: Secure Boot が無効のとき**

- Secure Boot が無効なら、署名していないモジュールも読み込まれるので、「Secure Boot の署名鍵」の項は要らない

**[Secure Boot の署名鍵](#secure-boot-の署名鍵)の手順 4: 登録の予約**

- 最後の `mokutil --import` で、公開鍵を UEFI の MOK に登録する予約をする（登録するのは、[Secure Boot の署名鍵](#secure-boot-の署名鍵)の手順 6 の MokManager）

**[Secure Boot の署名鍵](#secure-boot-の署名鍵)の手順 5**

- 起動の途中で青い **MokManager** の画面が出る（[Secure Boot の署名鍵](#secure-boot-の署名鍵)の手順 6）

**[Secure Boot の署名鍵](#secure-boot-の署名鍵)の手順 5: VM のウィンドウを先に開いておく**

- MokManager の最初の画面は、再起動の途中で出て、出てから 10 秒で消える（[Secure Boot の署名鍵](#secure-boot-の署名鍵)の手順 6）。VM に SSH でつないで貼ったときは、消える前に、VM のウィンドウでキーを押すことになる
- Hyper-V の第 2 世代の VM では、[Secure Boot の署名鍵](#secure-boot-の署名鍵)の手順 5 を貼ってから 3 秒足らずで最初の画面が出た（検証記録の付録（`docs/verification/secure-boot-mok.md` の「付録: Hyper-V の VM で通した記録（2026-10-11）」））。[Secure Boot の署名鍵](#secure-boot-の署名鍵)の手順 5 の `sudo systemctl reboot` から最初の画面までを、ほかのハイパーバイザと実機で測った記録は無い
  - VirtualBox の VM の記録にある時間は、別のコマンド（`bootc switch --apply`。イメージの切り替えの後に再起動する）を貼ってから 54 秒、の 1 つだけ（VirtualBox の bootc ゲスト の検証記録の付録（`docs/verification/virtualbox-guest-bootc.md` の「付録: ホストでビルドして VM に運ぶ形の本実行（2026-09-30）」））
- その VM では、画面を見張る道具がキーを送った。人が、貼った後にウィンドウを開いて間に合うかも、先に開いておけば間に合うかも、確かめていない

**[Secure Boot の署名鍵](#secure-boot-の署名鍵)の手順 7**

- `sudo` が要る。鍵のディレクトリは root だけが入れる（`drwx------`）

**[Secure Boot の署名鍵](#secure-boot-の署名鍵)の手順 7: 読み込めないときの見方**

- `sudo keyctl list %:.platform` に、[Secure Boot の署名鍵](#secure-boot-の署名鍵)の手順 4 の鍵の CN があるかを見る（`keyutils` パッケージ）
- `sudo dmesg` に `Loading of module with unavailable key is rejected` が出ていれば、モジュールを署名した鍵が登録されていない（検証記録（`docs/verification/secure-boot-mok.md` の「実施手順 / 手順 6: 補足: 画面の並びと、登録できなかった PC」）の手順 6 の補足）

**選択した方針**

- **鍵の場所は `/var/lib/shim-signed/mok/MOK.{der,priv}` に固定する**: VirtualBox の `vboxdrv.sh` と Guest Additions の `vboxadd` が、この場所を決め打ちで使う
- **鍵は 1 つにし、作り直さない**: 登録済みの鍵を作り直すと、その鍵で署名したモジュールと合わなくなる。[Secure Boot の署名鍵](#secure-boot-の署名鍵)の手順 4 は、鍵があれば `中断:` で止まる
- **CN は用途を問わない名前にする**: 1 つの鍵で、この PC（VM）のモジュールのどれにも署名するため
- **登録は、モジュールをビルドする前に済ませる**: 鍵が登録済みなら、[VirtualBox](virtual-machines.md#virtualbox) の `dnf install` の `%post` が、ビルド → 署名 → 読み込みまで一度に済ませる（[VirtualBox: VirtualBox を入れる](virtual-machines.md#virtualbox-virtualbox-を入れる)の手順 4 の補足）

**参照**

- [RHEL 10 — Managing, monitoring, and updating the kernel](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html-single/managing_monitoring_and_updating_the_kernel/index) — Secure Boot でのモジュールの署名、MOK への鍵の登録、`.platform` キーリング
- `man mokutil`（`--sb-state` / `--import` / `--test-key` / `--list-new` / `--delete` / `--list-delete`）
- [VirtualBox](virtual-machines.md#virtualbox) / [VirtualBox の bootc ゲスト](virtual-machines.md#virtualbox-の-bootc-ゲスト) — この鍵で署名したモジュールを使う手順書


- 検証記録（`docs/verification/secure-boot-mok.md`）

</details>

---

### ユーザーサービスの常駐

- 自分のユーザーの linger を有効にして、ログアウトしている間も、そのユーザーのサービスが動くようにする
- 前提: [ログインと sudo](#ログインと-sudo)を通してある
- 実行場所: 常駐させるユーザー自身のシェル（デスクトップの端末か SSH の bash）

> [!IMPORTANT]
> - **`sudo -i` した root のシェルでは行わない**（`${USER}` が `root` になる）

1. linger が有効になっているか確かめる。

   ```bash
   loginctl show-user "$(id -u)" -p Linger
   ```

   - `Linger=yes` が出れば、手順 2 は飛ばす
   - `Linger=no` と出たら、手順 2 で有効にする

1. linger が無効のときだけ、linger を有効にして、有効になったか確かめる。

   ```bash
   # ユーザーサービスの常駐を有効にする
   sudo loginctl enable-linger "${USER}"
   printf '\n\033[7m 確認 \033[0m\n'
   loginctl show-user "$(id -u)" -p Linger
   ls /var/lib/systemd/linger
   ```

   - `enable-linger` は何も出さない
   - `Linger=yes` と、自分のユーザー名が出ればよい

<details id="ユーザーサービスの常駐-の補足と注意点">
  <summary>ユーザーサービスの常駐 の補足と注意点</summary>

**注意点**

- **linger はユーザーごとに 1 つで、使う側の手順書で共有する**: どれか 1 本で有効にすれば、ほかの手順書では[ユーザーサービスの常駐](#ユーザーサービスの常駐)の手順 1 で `Linger=yes` を確かめるだけでよい。切るのは、どれも使わなくなったときだけ
- **ログアウト中も動かすなら、PC を眠らせない**: linger はサスペンドを止めない（[画面オフ・画面ロック・自動サスペンドを止める](#画面オフ画面ロック自動サスペンドを止める)。Workstation で入れた PC は、ログイン画面のまま 15 分で眠る）
- **`sudo -iu` で切り替えたシェルでは、`systemctl --user` が失敗する**: `XDG_RUNTIME_DIR` が無いため（Podman の検証記録（`docs/verification/podman.md`）・[Podman の補足と注意点](containers.md#podman-の補足と注意点)の「参照」）。常駐させるユーザーで、直接ログインしたシェルを使う

**[ユーザーサービスの常駐](#ユーザーサービスの常駐)のリード**

- 通すと使えるようになるもの（ログアウトしている間も動く）:
  - [Podman: Quadlet で自動起動する](containers.md#podman-quadlet-で自動起動する)で動かすコンテナ

**[ユーザーサービスの常駐](#ユーザーサービスの常駐)の手順 1: 有効になっているとき**

- `Linger=yes` が出るのは、ほかの手順書で有効にしてあるとき

**[ユーザーサービスの常駐](#ユーザーサービスの常駐)の手順 2: linger**

- linger を有効にすると、ログインしていない間もユーザーの systemd が動き続ける

**選択した方針**

- **ユーザーのサービス + linger にする**: 常駐させるものを、同期するファイルやコンテナの持ち主のユーザーで動かす。root も cron も要らない
  - 代わりに root が管理するシステムのサービスにすれば linger は要らないが、使う側の手順書はどれもユーザーのサービスにしている
- **確認は `loginctl show-user` で行う**: `Linger=` の値は logind が持つ状態そのもの。`/var/lib/systemd/linger/<USER>` のファイルは、その記録

**参照**

- `man loginctl`（`enable-linger` / `disable-linger` / `show-user`）
- `man logind.conf`（`KillUserProcesses=`）/ `man user@.service`


- 検証記録（`docs/verification/linger.md`）

</details>

---

## GNOME のデスクトップ

- 日本語入力と、GNOME の表示・入力・電源の設定

### 日本語入力

- GNOME で日本語を打てるように、Anthy と日本語のフォントを入れ、入力ソースを「キーボードの配列 + Anthy」にする
- 前提: [ログインと sudo](#ログインと-sudo)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）
- **Homebrew を入れた（これから入れる）PC では、[Homebrew](#homebrew)の手順 3 も通す**。Homebrew が既に入っていても、IBus の PATH 固定まで行う

- **この項の手順 3 で、ほかの入力ソースは消える**。残すものは `set` の値に足す

1. 変数を設定する。

   ```bash
   XKB_LAYOUT=$(localectl status 2>/dev/null | sed -n 's/^ *X11 Layout: \([a-z][a-z0-9_]*\).*/\1/p')   # キーボードの配列（自動）。JIS は jp、US は us。<XKB_LAYOUT>
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'XKB_LAYOUT = %s\n' "${XKB_LAYOUT}"
   ```

   - `XKB_LAYOUT` が空か配列と違えば、`XKB_LAYOUT=jp`（JIS）か `XKB_LAYOUT=us`（US）を貼ってから進む
   - **新しい端末を開いたら**、この項の手順 1 を貼り直してから先へ進む

1. ibus-anthy と日本語のフォントが無ければ入れる。

   ```bash
   if ! rpm -q ibus ibus-anthy default-fonts-cjk-sans; then sudo dnf install -y ibus-anthy default-fonts-cjk-sans; fi
   ```

   - 3 つとも版が出れば、入っている
   - `package … is not installed` が出たときは、続けて AppStream から入る。入れたときは、[再起動と確認](#再起動と確認)の手順 1 の再起動の後に使えるようになる

1. 入力ソースを「キーボードの配列 + Anthy」にする。

   ```bash
   # 入力ソースの変数を確かめる
   if [ -z "${XKB_LAYOUT}" ]; then echo '中断: この項の手順 1 の XKB_LAYOUT が空のまま。値を入れて貼り直す' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     # 入力ソースを設定して読み戻す
     /usr/bin/gsettings get org.gnome.desktop.input-sources sources
     /usr/bin/gsettings set org.gnome.desktop.input-sources sources "[('xkb', '${XKB_LAYOUT}'), ('ibus', 'anthy')]"
     /usr/bin/gsettings get org.gnome.desktop.input-sources sources
     # 入力切替のキーを確かめる
     /usr/bin/gsettings get org.gnome.desktop.wm.keybindings switch-input-source
   fi
   ```

   - 2 つ目の `get` が `[('xkb', 'jp'), ('ibus', 'anthy')]`（US 配列なら `'us'`）になればよい
   - 英字を打つときは Super+Space でキーボードの配列に戻す
   - **注意**: `/usr/bin/` を外さない（[GNOME の表示と入力](#gnome-の表示と入力)の手順 1〜14 も同じ）
   - 最初の `get` の値を、変える前の値として控える

<details id="日本語入力-の補足と注意点">
  <summary>日本語入力 の補足と注意点</summary>

**注意点**

- **Anthy はひらがなで始まる**: RHEL のパッチで既定の入力モードがひらがなになっている。英字を打つなら、Super+Space で配列（Neovim のセットアップの「Neovim」の手順 2 の後は「英語 (US)」）に戻す。Anthy の中の切り替えのキー（Ctrl+Space・Ctrl+J）は、Neovim のセットアップの「Neovim」の手順 2 で外れる
  - 変換は Mozc に比べて弱いと言われる（本書では比べていない）。よく使う語は、一緒に入る辞書のツール `kasumi-unicode` で登録する
  - 入力モードやキーの割り当ての設定画面は `/usr/libexec/ibus-setup-anthy`（アプリの一覧には出ない）

**[日本語入力](#日本語入力)の手順 1**

- 最後に値を読み戻して確かめる

**[日本語入力](#日本語入力)の手順 2: 入っているときと入れたとき**

検証記録（`docs/verification/almalinux-setup.md` の「日本語入力 の記録」）を参照する。

- Workstation で入れた PC には、3 つとも最初から入っている
- 入れたときに[再起動と確認](#再起動と確認)の手順 1 の再起動を待つのは、動いている IBus が、ログインし直すまで Anthy を使えないため

**[日本語入力](#日本語入力)の手順 3**

- [Neovim](neovim.md#neovim)の手順 2 では、JIS 配列でも入力ソースが「英語 (US)」と Anthy に変わる

- 最初の `get` は変える前の値（最初のログインの後は、今の配列だけの `[('xkb', 'us')]` など）。この値を控える

**[日本語入力](#日本語入力)の手順 3: 入力ソースを切り替えるキー**

- `['<Super>space', 'XF86Keyboard']` は入力ソース切り替えのキーの設定値

**参照**

- [Enabling Chinese, Japanese, or Korean text input — Using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/using_the_gnome_desktop_environment/customizing-the-desktop-environment) — 8.2 節。日本語は `ibus-anthy`、切り替えは Super+Space
- [ibus/ibus-anthy](https://github.com/ibus/ibus-anthy) — Anthy のエンジン
- [CentOS Stream 10 の ibus-anthy](https://gitlab.com/redhat/centos-stream/rpms/ibus-anthy) — RHEL のビルドの設定（配列 `default`、切り替えのキー）と、ひらがなで始めるパッチ

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

---

### GNOME の表示と入力

- ホームのフォルダーの名前・ダークモード・キーの割り当て・上部バー・Files・拡大率・トレイアイコン・Dash のお気に入りを、自分用に変える
- 前提: [ログインと sudo](#ログインと-sudo)を通してある。この項の手順 11（EPEL から入れる）には、[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 1 も要る
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）

1. 変数を設定する。

   ```bash
   DASH_FAVORITES="['firefox.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Ptyxis.desktop', 'org.gnome.TextEditor.desktop']"   # Dash に並べるアプリ（左から）
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'DASH_FAVORITES = %s\n' "${DASH_FAVORITES}"
   ```

   - **編集が必須の変数は無い**
   - **新しい端末を開いたら**、この項の手順 1 を貼り直してから先へ進む

1. ホームのフォルダーの名前を、日本語から英語にする（中身ごと移す）。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # ホームのフォルダー名とブックマークを揃える
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
   # フォルダーとブックマークの設定を読み戻す
   grep '^XDG_' ~/.config/user-dirs.dirs
   cat ~/.config/gtk-3.0/bookmarks
   ```

   - `user-dirs.dirs` の 8 行が `$HOME/` の下の `Desktop`・`Downloads`・`Templates`・`Public`・`Documents`・`Music`・`Pictures`・`Videos` を指し、ブックマークも英語の名前を指せばよい
   - 英語の名前のフォルダーがもうあると、そのフォルダーは `飛ばした:` で変えない

1. ダークモードにする。

   ```bash
   # 配色の設定をダークモードにする
   /usr/bin/gsettings set org.gnome.desktop.interface color-scheme prefer-dark
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.desktop.interface color-scheme
   ```

   - `'prefer-dark'` が出ればよい

1. Caps Lock を Ctrl にする（今の配列の設定に足す）。

   ```bash
   # 現在のキー設定を取得する
   xkb=$(/usr/bin/gsettings get org.gnome.desktop.input-sources xkb-options)
   echo "変える前: ${xkb}"
   # Caps Lock の Ctrl 割り当てを追加する
   case "${xkb}" in
     *"'ctrl:nocaps'"*) ;;
     '@as []') /usr/bin/gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']" ;;
     *) /usr/bin/gsettings set org.gnome.desktop.input-sources xkb-options "${xkb%]}, 'ctrl:nocaps']" ;;
   esac
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.desktop.input-sources xkb-options
   ```

   - `ctrl:nocaps` が含まれていればよい

1. ウィンドウのタイトルバーに、最小化と最大化のボタンを出す。

   ```bash
   # ウィンドウの操作ボタンを設定する
   /usr/bin/gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.desktop.wm.preferences button-layout
   ```

   - `'appmenu:minimize,maximize,close'` が出ればよい

1. 上部バーの時計に曜日と秒を出し、電池の残りを % で出す。

   ```bash
   # 時計の表示を設定する
   /usr/bin/gsettings set org.gnome.desktop.interface clock-show-weekday true
   /usr/bin/gsettings set org.gnome.desktop.interface clock-show-seconds true
   # 電池の残量表示を有効にする
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
   # アプリを切り替えるキーを設定する
   /usr/bin/gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab']"
   /usr/bin/gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Super>Tab']"
   # ウィンドウを切り替えるキーを設定する
   /usr/bin/gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
   /usr/bin/gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab']"
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings list-recursively org.gnome.desktop.wm.keybindings | grep -E 'switch-(applications|windows)'
   ```

   - `switch-windows ['<Alt>Tab']` と `switch-applications ['<Super>Tab']` などの 4 行が出ればよい

1. 画面の左上の角（ホットコーナー）にマウスを当てても、アクティビティの画面を開かないようにする。

   ```bash
   # ホットコーナーを無効にする
   /usr/bin/gsettings set org.gnome.desktop.interface enable-hot-corners false
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.desktop.interface enable-hot-corners
   ```

   - `false` が出ればよい

1. 設定の「ディスプレイ」で、拡大率に 125%・150% などを選べるようにする（効くのは再起動の後）。

   ```bash
   # 拡大率に関する機能の設定を取得する
   f=$(/usr/bin/gsettings get org.gnome.mutter experimental-features)
   echo "変える前: ${f}"
   # 拡大率の実験的な機能を追加する
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
   - 入るのは `gnome-shell-extension-appindicator` と、依存の 3 つ（`libappindicator-gtk3`・`libdbusmenu`・`libdbusmenu-gtk3`）
   - **次の手順は、`完了しました!` が出てプロンプトに戻ってから貼る**（続けて貼ると、導入や署名鍵の確認を断ったときも、拡張を有効にする設定が書かれる）

1. 入れた拡張を有効にする（効くのは再起動の後）。

   ```bash
   # 有効な GNOME 拡張の一覧を取得する
   e=$(/usr/bin/gsettings get org.gnome.shell enabled-extensions)
   echo "変える前: ${e}"
   # トレイアイコンの拡張を有効にする
   case "${e}" in
     *"'appindicatorsupport@rgcjonas.gmail.com'"*) ;;
     '@as []') /usr/bin/gsettings set org.gnome.shell enabled-extensions "['appindicatorsupport@rgcjonas.gmail.com']" ;;
     *) /usr/bin/gsettings set org.gnome.shell enabled-extensions "${e%]}, 'appindicatorsupport@rgcjonas.gmail.com']" ;;
   esac
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.shell enabled-extensions
   ```

   - 最後の一覧に `appindicatorsupport@rgcjonas.gmail.com` が含まれていればよい

1. Ctrl+Alt+T で端末を開くようにする（ショートカットを足す）。

   ```bash
   # 端末用のショートカットを一覧に登録する
   kb=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal/
   list=$(/usr/bin/gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
   case "${list}" in
     *"'${kb}'"*) ;;
     '@as []') /usr/bin/gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['${kb}']" ;;
     *) /usr/bin/gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "${list%]}, '${kb}']" ;;
   esac
   # 端末の起動コマンドとキーを設定する
   /usr/bin/gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}" name '端末'
   /usr/bin/gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}" command 'ptyxis --new-window'
   /usr/bin/gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}" binding '<Control><Alt>t'
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings
   /usr/bin/gsettings list-recursively "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}"
   ```

   - 一覧に `'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal/'` と、`binding '<Control><Alt>t'`・`command 'ptyxis --new-window'`・`name '端末'` が出ればよい

1. Dash のお気に入り（アクティビティの画面の下の並び）を、この項の手順 1 のアプリにする。

   ```bash
   # Dash のアプリ一覧を設定して読み戻す
   if [ -z "${DASH_FAVORITES}" ]; then echo '中断: この項の手順 1 の DASH_FAVORITES が空のまま。値を入れて貼り直す' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     /usr/bin/gsettings get org.gnome.shell favorite-apps
     /usr/bin/gsettings set org.gnome.shell favorite-apps "${DASH_FAVORITES}"
     /usr/bin/gsettings get org.gnome.shell favorite-apps
   fi
   ```

   - 2 つ目の `get` がこの項の手順 1 の値になればよい
   - 最初の `get` の並びを控える

#### GNOME の表示と入力が動かなくなったとき

- 拡大率の実験的な機能やトレイアイコンの拡張が動かないときに、該当する設定だけを無効にする
- 前提: [GNOME の表示と入力](#gnome-の表示と入力)で、該当する機能を有効にしてある
- 実行場所: GNOME にログインしているユーザー本人の端末（bash）

1. 拡大率がうまく動かないときは、mutter の実験的な機能を外す（効くのは再起動の後）。

   ```bash
   # 拡大率に関する機能の設定を取得する
   f=$(/usr/bin/gsettings get org.gnome.mutter experimental-features)
   echo "変える前: ${f}"
   # 拡大率の実験的な機能を無効にする
   for x in scale-monitor-framebuffer xwayland-native-scaling; do
     f=$(printf '%s' "${f}" | sed -e "s/, '${x}'//" -e "s/'${x}', //" -e "s/\['${x}'\]/@as []/")
   done
   /usr/bin/gsettings set org.gnome.mutter experimental-features "${f}"
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.mutter experimental-features
   ```

   - 最後に `@as []`（ほかの機能を足していれば、その一覧）が出ればよい

1. トレイアイコンの拡張が動かなくなったときは、その拡張を無効にする。

   ```bash
   # トレイアイコンの拡張を無効にする
   e=$(/usr/bin/gsettings get org.gnome.shell enabled-extensions)
   /usr/bin/gsettings set org.gnome.shell enabled-extensions "$(printf '%s' "${e}" | sed -e "s/, 'appindicatorsupport@rgcjonas.gmail.com'//" -e "s/'appindicatorsupport@rgcjonas.gmail.com', //" -e "s/\['appindicatorsupport@rgcjonas.gmail.com'\]/@as []/")"
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.shell enabled-extensions
   ```

   - `['background-logo@fedorahosted.org']` が出ればよい（`'appindicatorsupport@rgcjonas.gmail.com'` が無い）

<details id="gnome-の表示と入力-の補足と注意点">
  <summary>GNOME の表示と入力 の補足と注意点</summary>

**注意点**

- **Caps Lock の働きは無くなる**: [GNOME の表示と入力](#gnome-の表示と入力)の手順 4 は Caps Lock を Ctrl にするだけ。大文字を続けて打つときは Shift を押す。JIS 配列では「英数」（Caps Lock）のキーが Ctrl になる

- **Alt+Tab はウィンドウを切り替える**: アプリごとに切り替えるのは Super+Tab

- **拡大率の設定は mutter の実験的な機能**: GNOME の更新で、名前や働きが変わることがある。うまく動かなければ、[GNOME の表示と入力が動かなくなったとき](#gnome-の表示と入力が動かなくなったとき)の手順 1 で外す

- **トレイアイコンの拡張は EPEL のもの**: GNOME Shell の更新に遅れることがある。拡張が動かなくなったら、[GNOME の表示と入力が動かなくなったとき](#gnome-の表示と入力が動かなくなったとき)の手順 2 で無効にする

- **フォルダーの名前を聞かれたら**: ログインのときに「標準フォルダーの名前を現在の言語に合わせて更新しますか?」の窓が出たら、「次回から表示しない」をオンにして「古い名前のままにする」を押す（日本語の名前に戻さない）

**[GNOME の表示と入力](#gnome-の表示と入力)の手順 1**

- 最後に値を読み戻して確かめる

- **編集が必須の変数は無い**。既定のままなら、Dash に Firefox・ファイル・端末（Ptyxis）・テキストエディターが並ぶ

**[GNOME の表示と入力](#gnome-の表示と入力)の手順 1: 変数の意味**

- `DASH_FAVORITES` は、[GNOME の表示と入力](#gnome-の表示と入力)の手順 14 で、アクティビティの画面の下の Dash に並べるアプリ（`/usr/share/applications` の `.desktop` のファイル名）

**[GNOME の表示と入力](#gnome-の表示と入力)の手順 2**

- `/home/<USER>/ダウンロード → /home/<USER>/Downloads` のような行が 8 つ出る

**[GNOME の表示と入力](#gnome-の表示と入力)の手順 2: 中身とログインの窓**

- 中身は、フォルダーごと移る
- 次のログインで「標準フォルダーの名前を現在の言語に合わせて更新しますか?」の窓は出ない（`~/.config/user-dirs.locale` は今の言語のまま）

**[GNOME の表示と入力](#gnome-の表示と入力)の手順 3: 設定アプリとの対応**

- 設定の「外観」の「スタイル」の「ダーク」と同じで、すぐに効く

**[GNOME の表示と入力](#gnome-の表示と入力)の手順 4**

- 最後に `['ctrl:nocaps']`（ほかの設定があれば、その後ろに `'ctrl:nocaps'`）が出ればよい。すぐに効く

**[GNOME の表示と入力](#gnome-の表示と入力)の手順 4: 効く範囲**

- 自分のセッションだけの設定。ログイン画面と、ほかのユーザーには効かない

**[GNOME の表示と入力](#gnome-の表示と入力)の手順 5: 既定値**

- `button-layout` の既定は `'appmenu:close'`

**[GNOME の表示と入力](#gnome-の表示と入力)の手順 7: 2 つのスキーマ**

- Files と GTK4 のアプリは `org.gtk.gtk4`、GTK3 のアプリは `org.gtk` を読む
- Files では Ctrl+H で、隠しファイルを出す・隠すを切り替えられる

**[GNOME の表示と入力](#gnome-の表示と入力)の手順 8: アプリごとの切り替え**

- アプリごとの切り替えは Super+Tab に残る

**[GNOME の表示と入力](#gnome-の表示と入力)の手順 9: アクティビティの画面**

- ホットコーナーを切った後も、アクティビティの画面は Super キーで開く

**[GNOME の表示と入力](#gnome-の表示と入力)の手順 10: 拡大率を選ぶ時期**

- 拡大率を選ぶのは、[再起動と確認](#再起動と確認)の手順 1 の再起動の後に、[再起動と確認](#再起動と確認)の手順 4 で行う

**[GNOME の表示と入力](#gnome-の表示と入力)の手順 11: 版**

- 入る `gnome-shell-extension-appindicator` は、AlmaLinux 10.2 では 61

**[GNOME の表示と入力](#gnome-の表示と入力)の手順 12**

- 最後に、もとの拡張（`'background-logo@fedorahosted.org'`）と `'appindicatorsupport@rgcjonas.gmail.com'` が出ればよい

**[GNOME の表示と入力](#gnome-の表示と入力)の手順 12: 効く時期**

- 動いている GNOME Shell は、ログインし直すまで、入れたばかりの拡張を読まない。[再起動と確認](#再起動と確認)の手順 1 の再起動の後に、[再起動と確認](#再起動と確認)の手順 3 で確かめる

**[GNOME の表示と入力](#gnome-の表示と入力)の手順 13: 設定アプリでの表示**

- 足したショートカットは、設定の「キーボード」→「キーボードショートカット」→「カスタムショートカット」にも出る

**[GNOME の表示と入力](#gnome-の表示と入力)の手順 14**

- 2 つ目の `get` が[GNOME の表示と入力](#gnome-の表示と入力)の手順 1 の値になればよい。すぐに効く

**選択した方針**

- **ホームのフォルダーの名前を英語にする（[GNOME の表示と入力](#gnome-の表示と入力)の手順 2）**: 端末で打ちやすく、Homebrew・WezTerm などの既定の場所と合わせるため
  - `xdg-user-dirs-update --force` は空のフォルダーを作り直すだけで、中身を移さない。中身を残すために、フォルダーを `mv` してから `xdg-user-dirs-update --set` で場所を書き換える
  - Files のサイドバーのブックマーク（`~/.config/gtk-3.0/bookmarks`）も、日本語の名前の URI のままになるので書き換える
  - `~/.config/user-dirs.locale` を今のロケールに合わせる。xdg-user-dirs-gtk は、このファイルのロケールが今のロケールと違うときに、ログインで「標準フォルダーの名前を現在の言語に合わせて更新しますか?」の窓を出す（xdg-user-dirs-gtk のソース）

- **Caps Lock を Ctrl に（[GNOME の表示と入力](#gnome-の表示と入力)の手順 4）**: XKB の `ctrl:nocaps`（xkeyboard-config の説明は「Caps Lock as Ctrl」）を `xkb-options` に足す。Caps Lock の働きは無くなる。自分のセッションの設定なので、ログイン画面と仮想コンソールは変わらない

- **拡大率（[GNOME の表示と入力](#gnome-の表示と入力)の手順 10）**: GNOME の設定に 125%・150% などの拡大率を出すのは、mutter の実験的な機能 `scale-monitor-framebuffer`。`xwayland-native-scaling` は、X11 のアプリをぼやけさせずに拡大する（mutter 49 の gschema の説明）。AlmaLinux 10.2 の mutter 49.4 の既定は `[]`

- **トレイアイコン（[GNOME の表示と入力](#gnome-の表示と入力)の手順 11・12）**: EPEL の `gnome-shell-extension-appindicator`（AppIndicator と KStatusNotifierItem を扱う）。AppStream の `gnome-shell-extension-status-icons` は、旧来の XEmbed のトレイアイコンだけを扱い、今のアプリが使う AppIndicator / KStatusNotifierItem を出さない

- **Ctrl+Alt+T（[GNOME の表示と入力](#gnome-の表示と入力)の手順 13）**: GNOME 49 の media-keys には端末を開くキーが無いので、カスタムのショートカットにする。コマンドは、新しい窓を開く `ptyxis --new-window`

**参照**

- [xdg-user-dirs](https://www.freedesktop.org/wiki/Software/xdg-user-dirs/) と [xdg-user-dirs-gtk](https://gitlab.gnome.org/GNOME/xdg-user-dirs-gtk) — `user-dirs.dirs`・`user-dirs.locale` と、名前を更新するかを聞く窓

- mutter 49.4 の `/usr/share/glib-2.0/schemas/org.gnome.mutter.gschema.xml` — `experimental-features` の `scale-monitor-framebuffer` と `xwayland-native-scaling` の説明

- [gnome-shell-extension-appindicator](https://github.com/ubuntu/gnome-shell-extension-appindicator) — AppIndicator / KStatusNotifierItem のトレイアイコン（EPEL のパッケージの上流）

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

---

### 画面オフ・画面ロック・自動サスペンドを止める

- 常時動かしておく PC で、GNOME が画面を消したり、ロックしたり、放置で眠ったりしないようにする。ログイン画面・蓋・OS のサスペンドも止める
  - [GNOME のヘッドレスのセッション](gnome-remote.md#gnome-のヘッドレスセッション)はこの項の手順 1・2 が前提。サスペンドできる PC では手順 3・4 も通す
  - [GNOME のデスクトップ共有](gnome-remote.md#gnome-のデスクトップ共有)はこの項の手順 1〜4 が前提
- 前提: [ログインと sudo](#ログインと-sudo)を通してある
- 実行場所: GNOME にログインするユーザー本人の端末（bash）。この項の手順 1 で変数を設定したシェルに貼る
- **人が触れる場所にある PC では行わない**（画面をロックしないので、前にいる人がそのまま使える）
- GNOME を入れていない（デスクトップの無い）機械では、この項の手順 4・5 だけを行う

- **この項の手順 4 の後は、ノート PC は蓋を閉じても電池が減っても眠らない**。閉じたまま鞄に入れると熱を持つので、持ち歩くときは電源を切る

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
   - `USER` が `root` になっているなら、ここで止めて、自分のユーザーのシェルで貼り直す
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、この項の手順 1 のブロックを貼り直してから先へ進む

1. 自分のセッションの画面オフ・減光・ロック・自動サスペンド・電源ボタンを変える。

   ```bash
   # 画面オフと画面ロックを設定する
   /usr/bin/gsettings set org.gnome.desktop.session idle-delay "${IDLE_DELAY:?この項の手順 1 の IDLE_DELAY が空のまま。値を入れて貼り直す}"
   /usr/bin/gsettings set org.gnome.desktop.screensaver lock-enabled "${LOCK_ENABLED:?この項の手順 1 の LOCK_ENABLED が空のまま。値を入れて貼り直す}"
   # 減光と自動サスペンドを無効にする
   /usr/bin/gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
   /usr/bin/gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type nothing
   /usr/bin/gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type nothing
   # 電源ボタンの動作を設定する
   /usr/bin/gsettings set org.gnome.settings-daemon.plugins.power power-button-action "${POWER_BUTTON:?この項の手順 1 の POWER_BUTTON が空のまま。値を入れて貼り直す}"
   printf '\n\033[7m 確認 \033[0m\n'
   # 画面オフと画面ロックの設定を読み戻す
   /usr/bin/gsettings get org.gnome.desktop.session idle-delay
   /usr/bin/gsettings get org.gnome.desktop.screensaver lock-enabled
   # 電源管理の設定を読み戻す
   /usr/bin/gsettings list-recursively org.gnome.settings-daemon.plugins.power | grep -E 'idle-dim|sleep-inactive-(ac|battery)-type|power-button-action'
   ```

   - `uint32 0`、`false`、続いて `idle-dim false`・`power-button-action 'interactive'`・`sleep-inactive-ac-type 'nothing'`・`sleep-inactive-battery-type 'nothing'` の 4 行が出ればよい
   - 値が変わっていなければ、デスクトップの端末でこの項の手順 1 から貼り直す
   - **注意**: `/usr/bin/` を外さない

1. ログイン画面（GDM）用の設定を書き、dconf を作り直して、ログイン画面から見える値を確かめる。

   ```bash
   # ログイン画面の電源設定を書き込む
   if [ -z "${POWER_BUTTON}" ]; then echo '中断: この項の手順 1 の POWER_BUTTON が空のまま。値を入れて貼り直す' >&2; else
     sudo tee /etc/dconf/db/gdm.d/90-power >/dev/null <<EOF
   [org/gnome/settings-daemon/plugins/power]
   sleep-inactive-ac-type='nothing'
   sleep-inactive-battery-type='nothing'
   power-button-action='${POWER_BUTTON:?この項の手順 1 の POWER_BUTTON が空のまま。値を入れて貼り直す}'
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
   printf '\n\033[7m 確認 \033[0m\n'
   sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
   systemctl is-enabled sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
   ```

   - `masked` が 5 行出ればよい

1. 蓋を閉じても何もしないように、logind のドロップインを置く。

   ```bash
   # ふたを閉じたときの動作を設定する
   sudo mkdir -p /etc/systemd/logind.conf.d
   sudo tee /etc/systemd/logind.conf.d/90-lid.conf >/dev/null <<'EOF'
   [Login]
   HandleLidSwitch=ignore
   EOF
   # logind の設定を反映する
   sudo systemctl reload systemd-logind
   printf '\n\033[7m 確認 \033[0m\n'
   busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager HandleLidSwitch
   ```

   - `s "ignore"` と出ればよい

<details id="画面オフ画面ロック自動サスペンドを止める-の補足と注意点">
  <summary>画面オフ・画面ロック・自動サスペンドを止める の補足と注意点</summary>

**注意点**

- **画面オフ・画面ロック・自動サスペンドを止める節の dconf のファイルの型**: 文字列は `'nothing'` のように引用符で囲む。`idle-delay` のような uint32 は `uint32 0` と書く
  - 引用符が無いと `dconf update` が失敗し、データベースは前の内容のまま残る。`uint32` が無いと、エラーにならずに無視される
  - Server with GUI の `gnome-settings-daemon-server-defaults` の override も、`power-button-action=nothing` に引用符が無く、読み飛ばされている（`sleep-inactive-ac-timeout=0` は効いていて、電源につないでいる間は眠らない）
  - 自分で変えた値（`gsettings` と設定アプリが書く user-db）は、`/etc/dconf/db` のデータベースより優先される。[画面オフ・画面ロック・自動サスペンドを止める](#画面オフ画面ロック自動サスペンドを止める)の手順 2 を `gsettings` で行うのはこのため
  - 仮想マシンの中では、gnome-settings-daemon は放置によるサスペンドをしない。電源ボタンは `nothing` 以外だと電源オフになる
  - [画面オフ・画面ロック・自動サスペンドを止める](#画面オフ画面ロック自動サスペンドを止める)の手順 4 の後は、設定アプリに「自動サスペンド」の行が出ない

**[画面オフ・画面ロック・自動サスペンドを止める](#画面オフ画面ロック自動サスペンドを止める)のリード**

- Samba のホストや、RDP で待ち受ける PC は、眠るとサービスが止まる

**[画面オフ・画面ロック・自動サスペンドを止める](#画面オフ画面ロック自動サスペンドを止める)の手順 1**

- 最後に値を読み戻して確かめる

**[画面オフ・画面ロック・自動サスペンドを止める](#画面オフ画面ロック自動サスペンドを止める)の手順 1: 変数の有効な範囲**

検証記録（`docs/verification/almalinux-setup.md` の「画面オフ・ロック・サスペンド の記録」）を参照する。

- 変数はそのシェルの中だけで有効なので、新しいシェルを開いたら貼り直す

**[画面オフ・画面ロック・自動サスペンドを止める](#画面オフ画面ロック自動サスペンドを止める)の手順 1: 変数について**

- 画面を消したいなら、`IDLE_DELAY` に秒数を入れる（`300` で 5 分）。消えたときにロックもするなら `LOCK_ENABLED=true`
- 放置したときにサスペンドするかどうかは変数にしていない。[画面オフ・画面ロック・自動サスペンドを止める](#画面オフ画面ロック自動サスペンドを止める)の手順 2・3 で `nothing`（何もしない）を直接書く
  - [画面オフ・画面ロック・自動サスペンドを止める](#画面オフ画面ロック自動サスペンドを止める)の手順 4 でサスペンドとハイバネートを OS ごと止めるので、ほかに選べる値が無いため
- `POWER_BUTTON` も同じ理由で、`suspend` / `hibernate` は選ばない
  - `interactive` は、設定アプリの「電源ボタンの挙動」の「電源オフ」にあたる
  - 押すと何をするかを聞く画面が出て、何も選ばなければ 60 秒で電源が切れる（RHEL 10 の文書の 13.1.2 節）

**[画面オフ・画面ロック・自動サスペンドを止める](#画面オフ画面ロック自動サスペンドを止める)の手順 2: 読み戻し**

- 最後の 3 つのコマンドで読み戻す

**[画面オフ・画面ロック・自動サスペンドを止める](#画面オフ画面ロック自動サスペンドを止める)の手順 3: ログイン画面の設定ファイル**

- ファイルには、自動サスペンドと電源ボタンの設定を書く
- 文字列の値は引用符（`'`）で囲む。囲まないと、`dconf update` が失敗する

**[画面オフ・画面ロック・自動サスペンドを止める](#画面オフ画面ロック自動サスペンドを止める)の手順 4**

- `Created symlink '/etc/systemd/system/sleep.target' → '/dev/null'.` のような行が 5 つ出て、`masked` が 5 行出ればよい

**[画面オフ・画面ロック・自動サスペンドを止める](#画面オフ画面ロック自動サスペンドを止める)の手順 4: mask の効き目**

- GNOME のメニュー・蓋・電源ボタンなど、どこから頼まれてもサスペンドが始まらなくなる

**[画面オフ・画面ロック・自動サスペンドを止める](#画面オフ画面ロック自動サスペンドを止める)の手順 5: 蓋の既定値**

- `HandleLidSwitch` の既定は `s "suspend"`
- 蓋の無い PC では何も変わらない（置いても害は無い）

**参照**

- [Changing system power settings — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/changing-system-power-settings) — 電源ボタン（dconf と logind）と蓋（logind）の設定
- [gnome-settings-daemon 47.2 の電源のスキーマ](https://gitlab.gnome.org/GNOME/gnome-settings-daemon/-/blob/47.2/data/org.gnome.settings-daemon.plugins.power.gschema.xml.in) — `sleep-inactive-*`・`idle-dim`・`power-button-action` の既定値と説明
- [GDM 47.0 のログイン画面の既定の設定](https://gitlab.gnome.org/GNOME/gdm/-/blob/47.0/data/dconf/defaults/00-upstream-settings) — 電源のキーが無いこと
- `man dconf`（`dconf update` とプロファイル）/ `man 5 logind.conf`（`HandleLidSwitch`）/ `man systemctl`（`mask`）

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

---

## Git と開発の道具

- Git・git-delta・GitHub CLI・lazygit・excel-diff・yazi・mdtable・md-format（mdfmt）・ShellCheck と shfmt・VS Code と、オフラインの npm。Neovim（LazyVim）は、[Neovim のセットアップ](neovim.md)で入れる

### Git

- コミットに載せる名前とメールアドレスと、pull・改行・ブランチなどの git の設定を `--global` に書き、使い捨てのリポジトリで確かめる
- 前提: [Homebrew](#homebrew)の手順 1 で git を入れてある（Workstation では最初から入っている）
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ

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
   - 値が空のままなら、この項の手順 3 で中断する
   - **新しいシェルを開いたら**、この項の手順 1 の 3 つのブロックを貼り直してから先へ進む

1. git の版と、今の設定を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # Git の版を確かめる
   git --version
   # 読み込まれている Git の設定を確かめる
   git config --list --show-scope --show-origin
   ```

   - `git version` と版が出ればよい
   - 既存の設定が、場所・ファイル・キーと値の形で出る。未設定なら何も出ない
   - 実際に追加・変更したキーも控える。既存の値が同じなら「変更なし」、この項の手順 7 を飛ばしたら「`pull.ff` は変更なし」とする
   - **この項の手順 3〜5 のキーと `pull.ff` の元の値・スコープ・ファイルを控える**。`global` に無ければ「global は未設定」と控える

1. 名前とメールアドレスを設定する。

   ```bash
   # コミットに記録する作成者情報を設定する
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
   # pull と rebase の動作を設定する
   git config --global pull.rebase true
   git config --global rebase.autoStash true
   # 改行の自動変換を無効にする
   git config --global core.autocrlf false
   ```

   - 何も出ない。値はこの項の手順 6 でまとめて確かめる

1. 推奨の設定を入れる。

   ```bash
   # 新規リポジトリのブランチ名を設定する
   git config --global init.defaultBranch main
   # パス名の表示を設定する
   git config --global core.quotepath false
   # fetch と push の動作を設定する
   git config --global fetch.prune true
   git config --global push.autoSetupRemote true
   # 競合の記録と表示形式を設定する
   git config --global rerere.enabled true
   git config --global merge.conflictStyle zdiff3
   # 差分の比較方式を設定する
   git config --global diff.algorithm histogram
   # ブランチとタグの表示順を設定する
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

   - `pull.ff` を除く 14 行が、`global` とこの項の手順 3〜5 の値になればよい
   - `pull.ff` 以外に `system` の行があれば、`global` に書けていない。この項の手順 3〜5 を貼り直す
   - 最後の `pull.ff` は、何も出ないのが普通
   - `pull.ff` が空か、`only` 以外なら、この項の手順 7 は飛ばす
   - `only` なら、その値とスコープをこの項の手順 2 の記録と照合してから手順 7 へ進む

1. この項の手順 6 で `pull.ff` が `only` だったときだけ、`true` で上書きする。

   ```bash
   # pull の fast-forward を許可する
   git config --global pull.ff true
   printf '\n\033[7m 確認 \033[0m\n'
   git config --show-scope --get pull.ff
   ```

   - `global	true` と出る
   - `pull.ff` を今回変更したことを、この項の手順 2 の元値の記録に書き足す

1. 使い捨てのリポジトリで、改行・ブランチ名・日本語のファイル名・最初の push を確かめる。

   ```bash
   # 確認用のリポジトリを作成する
   GIT_TEST_DIR=$(mktemp -d)
   cd "$GIT_TEST_DIR"
   git init -q --bare remote.git
   git init -q a
   cd a
   # 改行と日本語名を含むファイルを作成する
   printf 'line 1\r\n' > crlf.txt
   printf '1\n' > a.txt
   touch 日本語.txt
   printf '\n\033[7m 確認 \033[0m\n'
   # 作成したファイルの状態を確かめる
   git status --short
   # ファイルをコミットして改行とブランチを確かめる
   git add .
   git commit -q -m first
   git ls-files --eol crlf.txt
   git branch --show-current
   # リモートを登録して push する
   git remote add origin ../remote.git
   git push
   ```

   - `git status --short` に `?? 日本語.txt` がそのまま出る
   - `git ls-files --eol` は `i/crlf  w/crlf` で始まる
   - ブランチは `main`
   - `git push` の最後に `branch 'main' set up to track 'origin/main'.` と出る

1. この項の手順 8 と同じシェルで、別の clone から pull し、rebase と autostash を確かめる。

   ```bash
   # リポジトリを複製して送信側の変更を作成する
   cd "$GIT_TEST_DIR"
   git clone -q remote.git b
   cd a
   printf '2\n' >> a.txt
   git commit -q -a -m 'a: 2'
   git push -q
   # 受信側のコミットと未コミットの変更を作成する
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
   # 確認用のリポジトリを削除する
   cd ~
   rm -rf "${GIT_TEST_DIR:?「Git」の手順 8 と同じシェルで貼る}"
   ```

   - 何も出ない

#### 改行を変換して clone したリポジトリを直す

- 改行を変換する設定（`core.autocrlf=true`）のときに clone したリポジトリは、作業ツリーのファイルが CRLF のまま残る
- [Git](#git)の手順 4 の後は、それらが変更ありと出る。編集してコミットすると、CRLF で入る
- Windows で、Git for Windows の既定の設定のまま clone したリポジトリが当たる
- 前提: [Git](#git)を通してある
- 実行場所: 自分のユーザーの端末（bash。Windows 11 では Git Bash）の、直すリポジトリのトップのディレクトリ。リポジトリごとに、この項の手順 1 から貼る
- **この項の手順 3 は、作業ツリーの追跡しているファイルをすべて書き直し、未コミットの変更を消す**。この項の手順 1 で変更が出たら、手順 2 で退避してから貼る

1. 直すリポジトリのトップで、未コミットの変更と、CRLF で書かれたファイルの数を見る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # 改行変換を有効にして変更の有無を確かめる
   git -c core.autocrlf=true status --short
   # CRLF のファイル数を確かめる
   git ls-files --eol | grep -c 'i/lf *w/crlf'
   ```

   - 2 つ目の数が、直すファイルの数。`0` なら、この項は要らない
   - 1 つ目が何も出ないか、`??`（未追跡）の行だけなら、追跡しているファイルの変更は無い。この項の手順 2 と 4 は飛ばす
   - `??` 以外の行があれば、この項の手順 2 で追跡しているファイルの変更を退避する。未追跡ファイルはそのまま残す

1. この項の手順 1 で `??` 以外の変更が出たときだけ、前の設定のまま stash する。

   ```bash
   git -c core.autocrlf=true stash
   ```

   - `Saved working directory and index state WIP on …` と出る
   - `No local changes to save` なら、この項の手順 4 は飛ばす。エラーなら、ここで止めて原因を直す

1. 作業ツリーのファイルを、今の設定で書き直す。

   ```bash
   # インデックスと作業ツリーを作り直す
   git rm -r -q --cached .
   git reset -q --hard
   printf '\n\033[7m 確認 \033[0m\n'
   # 改行が CRLF のファイル数を確かめる
   git ls-files --eol | grep -c 'i/lf *w/crlf'
   # 作業ツリーの状態を確かめる
   git status --short
   ```

   - 数は `0` になる
   - `git status --short` は、もともとあった `??` の行以外は出さない

1. この項の手順 2 で保存成功の表示が出たときだけ、今回の変更を戻す。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # 退避した変更を戻す
   git stash pop
   # 改行の状態を確かめる
   git ls-files --eol
   ```

   - `git status` の形で、元の変更だけが出る
   - 戻したファイルも `w/lf` になる
   - この項の手順 2 からここまでは、別の stash を作らない

<details id="git-の補足と注意点">
  <summary>Git の補足と注意点</summary>

**注意点**

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

**[Git](#git)の手順 1**

- 最後に値を読み戻して確かめる。空のままなら、[Git](#git)の手順 3 で中断する

**[Git](#git)の手順 1: 変数について**

検証記録（`docs/verification/almalinux-setup.md` の「Git: 補足の実測」）

- GitHub に push するなら、メールアドレスに GitHub の noreply のアドレス（`<ID>+<GITHUB_USER>@users.noreply.github.com`）を使うと、私用のアドレスをコミットに載せずに済む。アドレスは GitHub の Settings の Emails で確かめる
- 名前に空白を入れるときは、引用符の中に書く（引用符が無いと、空白の後ろがコマンドとして実行される）
- 使うのは[Git](#git)の手順 3 だけ。後から変えるときは、[Git](#git)の手順 1 と[Git](#git)の手順 3 を貼り直す（`git config --global` は同じキーを上書きする）
- 変数はそのシェルの中だけで有効

**[Git](#git)の手順 2**

- Windows では、インストーラが書いた `system` の行（`core.autocrlf=true` など）も出る

- AlmaLinux 10.2 では `git version 2.52.0` と出る（git は[Homebrew](#homebrew)の手順 1 で入っている）

- 2 つ目は、設定を `<場所>	file:<ファイル>	<キー>=<値>` の形で 1 行ずつ出す。何も設定していなければ、何も出ない

**[Git](#git)の手順 4: 設定の意味**

- `pull.rebase true`: `git pull` が、取ってきた履歴の上に自分のコミットを載せ直す（マージコミットを作らない）
- `rebase.autoStash true`: 未コミットの変更があっても pull できる（pull の前に stash し、後で戻す）
- `core.autocrlf false`: チェックアウトでもコミットでも、改行を変換しない

**[Git](#git)の手順 5: 推奨の設定と、入れなかった設定**

| キー | 値 | 変わること |
|---|---|---|
| `init.defaultBranch` | `main` | `git init` の最初のブランチを `main` にする |
| `core.quotepath` | `false` | 日本語のファイル名を、`"\346\227\245…"` と書かずにそのまま出す |
| `fetch.prune` | `true` | fetch・pull のたびに、リモートで消えたブランチの追跡ブランチ（`origin/…`）を消す。ローカルのブランチは消さない |
| `push.autoSetupRemote` | `true` | 新しいブランチの最初の `git push` で、`-u origin <ブランチ>` を付けなくても追跡を設定する |
| `rerere.enabled` | `true` | 一度解いた衝突の解き方を覚え、同じ衝突に当たったら自動で当てる。rebase で同じ衝突を何度も解かずに済む |
| `merge.conflictStyle` | `zdiff3` | 衝突の表示に、共通の祖先の内容も出す（git 2.35 以降） |
| `diff.algorithm` | `histogram` | 差分の取り方。既定の `myers` より、関数を動かしたときなどに読みやすい差分になりやすい |
| `branch.sort` | `-committerdate` | `git branch` を、最近コミットしたブランチから並べる |
| `tag.sort` | `version:refname` | `git tag` を版の順（`v1.9` の後に `v1.10`）に並べる |

- `merge.conflictStyle zdiff3` は [git-delta](#git-delta) と同じ設定で、どちらを先に通してもよい

入れなかったもの:

- `core.editor`: 好みで決める。未設定なら、環境変数 `VISUAL`・`EDITOR` のエディタ、どちらも無ければ `vi` が開く。Windows では、インストーラで選んだエディタが `system` に入る
- `rerere.autoUpdate`: 覚えた解き方を当てた後に、`git add` までする。当てた結果を `git diff` で見てから add したいので入れない
- `fetch.pruneTags`: リモートに無いタグを、ローカルからも消す
- `pull.ff only`: 分岐したときの pull が、rebase せずに止まる（[Git](#git)の手順 7）
- `push.default`: 既定の `simple`（今のブランチを、同じ名前の追跡ブランチにだけ push する）のままでよい

**[Git](#git)の手順 6**

- `pull.ff` を除く 14 行が、`global` と[Git](#git)の手順 3〜5 の値になる（`pull.rebase           global	true` など）

**[Git](#git)の手順 6: pull.ff**

- 最後の `pull.ff` が何も出さないのは、設定が無いこと

**[Git](#git)の手順 8: 確かめている設定**

- `?? 日本語.txt` がそのまま出るのは `core.quotepath`
- `i/crlf  w/crlf` は、CRLF のまま入ったこと（`core.autocrlf`）
- ブランチの `main` は `init.defaultBranch`
- `branch 'main' set up to track 'origin/main'.` は `push.autoSetupRemote`

**[Git](#git)の手順 9: 残る変更**

- `M crlf.txt` は、pull の前の、未コミットの変更

**[改行を変換して clone したリポジトリを直す](#改行を変換して-clone-したリポジトリを直す)の手順 2: 保存しなかったとき**

- `No local changes to save` は、今回は保存していないこと

**[改行を変換して clone したリポジトリを直す](#改行を変換して-clone-したリポジトリを直す)の手順 4: 別の stash を作らない理由**

- `pop` は先頭の stash を戻すため

**選択した方針**

| 経路 | 状況 | 採否 |
|---|---|---|
| **winget の `Git.Git` を `--scope machine` で** | 上流のインストーラを、winget が sha256 を確かめてから黙って動かす。`C:\Program Files\Git` に入り、`winget upgrade` で上がる。管理者の権限が要る | **採用** |
| winget の `--scope user` | 同じインストーラで、winget はスコープのスイッチを渡さない。入る先はインストーラが権限で決める | 不採用（PC 全体に入れるので、winget にも `machine` を指定する） |
| 上流のインストーラを落として、画面で入れる | 選択を画面で選べる。版の確認と更新は手作業 | 不採用 |
| scoop の `main/git` | Git for Windows の持ち運び版（PortableGit）を `~\scoop\apps\git` に入れ、`git` などを `~\scoop\shims` に置く。`C:\Program Files\Git\bin\bash.exe` が無い | 不採用（[Windows 11 の初期設定](windows-setup.md)は、PC 全体に入れた Git for Windows を使う） |

- **インストーラの選択は既定のまま**（winget の `--custom` や `--override` で `/o:` を渡さない）
  - 本書は `system` を変えず `global` で上書きするので、`system` の `core.autocrlf=true`・`pull.rebase=false`・`init.defaultBranch=master` は既定のままでよい（[Git](#git)の手順 6 で確かめる）
  - 既定の PATH の選択（`cmd` だけを足す）で、PowerShell・scoop から `git` が見つかる。Unix の道具まで足す選択は、Windows の `find`・`sort` を隠す（インストーラの画面の警告）
  - `--override` は、winget が渡す黙って動かすスイッチ（`/SP- /SILENT …`）ごと置き換える（winget のソース）
- **Git for Windows は、scoop の `scoop update` が使う git も兼ねる**
  - scoop は、scoop の git が入っていなければ `PATH` の `git` を使う（[Git for Windows](windows-setup.md#git-for-windows)の手順 3 の補足）

**参照**

- `git help config` — 各キーの意味と既定値、設定の場所の順（`system` / `global` / `local`）
- `git help pull` — `--rebase`、`--autostash`、`pull.ff`
- `git help gitattributes` — `text`・`eol` と `core.autocrlf` の関係
- `git help rerere` — 解き方の記録と `forget`
- [Git for Windows](https://gitforwindows.org/) — 公式のサイト
- [winget-pkgs の `Git.Git`](https://github.com/microsoft/winget-pkgs/tree/master/manifests/g/Git/Git) — winget の定義（スコープ・インストーラの種類・スイッチ・sha256）
- [Silent or Unattended Installation](https://gitforwindows.org/silent-or-unattended-installation) — Git for Windows のインストーラを黙って動かすときのスイッチと、`/o:` で渡せる選択の一覧
- [git-for-windows/build-extra の `installer/install.iss`](https://github.com/git-for-windows/build-extra/blob/main/installer/install.iss) — インストーラの既定の選択、入れる先、`system` に書く値
- [Git for Windows のリリースノート](https://github.com/git-for-windows/build-extra/blob/main/ReleaseNotes.md) — 2.56.0 の `mingw64` から `ucrt64` への変更
- [microsoft/winget-cli](https://github.com/microsoft/winget-cli) — `ShellExecuteInstallerHandler.cpp`（インストーラに渡すスイッチ）、`ManifestCommon.cpp`（Inno Setup の既定のスイッチ）、`UninstallFlow.cpp`（削除のコマンド）、`doc/Settings.md`（スコープの既定）
- [Inno Setup の Uninstaller Command-Line Parameters](https://jrsoftware.org/ishelp/topic_uninstcmdline.htm) — 削除のプログラムの `/SILENT`
- [Pro Git 8.1 Git の設定](https://git-scm.com/book/ja/v2/Git-%E3%81%AE%E3%82%AB%E3%82%B9%E3%82%BF%E3%83%9E%E3%82%A4%E3%82%BA-Git-%E3%81%AE%E8%A8%AD%E5%AE%9A) — `core.autocrlf` の説明

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

---

### git-delta

- 差分を色付きで見やすくする git-delta を Homebrew で入れ、git のページャにする
- 前提: [共通の bash 設定](shell-terminal.md#共通の-bash-設定)と[Homebrew](#homebrew)を通し、PATH に Homebrew が入った端末（[シェルのツール](shell-terminal.md#シェルのツール)の手順 2 で開き直した端末）を開いてある
- 実行場所: 前提の端末（GNOME にログインした自分のユーザーの bash）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ

1. 変数を設定する。

   ```bash
   DELTA_NAVIGATE=true       # ページャ内で n / N を「次の変更・前の変更」にする。<DELTA_NAVIGATE>
   DELTA_LINE_NUMBERS=true   # 差分の左に行番号を出す。<DELTA_LINE_NUMBERS>
   DELTA_SIDE_BY_SIDE=false  # true にすると左右 2 面に分けて表示する。<DELTA_SIDE_BY_SIDE>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in DELTA_NAVIGATE DELTA_LINE_NUMBERS DELTA_SIDE_BY_SIDE; do printf '%-19s = %s\n' "$v" "${!v}"; done
   ```

   - **編集が必須の変数は無い**
   - 広い画面で左右に並べたいなら、`DELTA_SIDE_BY_SIDE=true` にする
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこの項の手順 1 を貼り直す

1. brew で git-delta を入れる。

   ```bash
   brew install git-delta
   ```

   - **次の手順は、Homebrew の確認が出たら答え、導入が成功してプロンプトに戻ってから貼る**（続けて貼ると、導入を断ったときや失敗したときも、git のページャを delta に変更する行が動く）

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
   # delta の版と実行ファイルの場所を確かめる
   delta --version
   brew list --versions git-delta
   command -v delta
   # 差分を delta で表示する
   git -C ~/.config/bash show --format= | delta --paging=never | head -20
   ```

   - `delta` または `git-delta` と版が出ればよい
   - ファイル名のヘッダと、行ごとに背景色の付いた差分が出る
   - 差分の行が出ないときは、`git -C ~/.config/bash log -1 --oneline` で最後のコミットを確かめる。差分を持たないコミット（マージコミットなど）なら、この差分表示の確認は飛ばす（その場合の出力は VM では確かめていない）

#### git-delta の設定ファイル

設定の実体は `~/.gitconfig` の `[delta]` セクション。

<details id="git-delta-の補足と注意点">
  <summary>git-delta の補足と注意点</summary>

**注意点**

- **git-delta: `core.pager` は PATH に `delta` がある文脈でしか動かない**
  - Homebrew の PATH は `~/.bashrc` の `brew shellenv` で通っているので、`~/.bashrc` を読まない文脈（cron、一部の非対話シェル、他ユーザー、`sudo -i` しない root）で `git diff` を打つと `delta: command not found` になる
  - 固くしたいなら、フルパスで指定する: `git config --global core.pager /home/linuxbrew/.linuxbrew/bin/delta`

- **git-delta: 表示だけを変える。差分の中身は変わらない**: `git diff > patch.diff` はページャを通らないので従来どおりのパッチが出る。`git apply` や CI の挙動には影響しない

- **git-delta: `sudo git` には効かない**: root は root の `~/.gitconfig` を読むので、この設定は入っていない

- **git-delta: `interactive.diffFilter` が変えるのは `git add -p` の表示だけ**: 選択の操作自体は git のまま

- **git-delta: lazygit は `core.pager` を見ない**: 0.65.1 では別途 `git.diffRenderers` を設定する（自分用の lazygit の設定（[lazygit](#lazygit)の手順 2）が設定する）

- **git-delta も、Homebrew の注意のとおり**: PATH の先頭が Homebrew になる、`~/.bashrc` を読まない文脈では見えない、など

**[git-delta](#git-delta)の手順 1**

- 最後の行で値を読み戻して確かめる

- **編集が必須の変数は無い**。既定のままで進められる

**[git-delta](#git-delta)の手順 1: 変数について**

検証記録（`docs/verification/almalinux-setup.md` の「git-delta の記録」）を参照する。

- 3 つとも表示の好みなので、既定のままで進められる
- 3 つとも `~/.gitconfig` の `[delta]` に書かれる値で、後から `git config --global delta.side-by-side true` で変えられる
- `navigate` を `true` にすると、ページャ（`less`）の中で `n` が「次の変更へ」になる。delta が `less` に渡すオプションで実現しているので、`core.pager` 経由で起動したときだけ効く

**[git-delta](#git-delta)の手順 2: 降ってくるボトル**

aarch64 で降ってくるボトルは `git-delta--0.19.2.arm64_linux.bottle.tar.gz`。

- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない

**[git-delta](#git-delta)の手順 2: formula 名とコマンド名**

- formula 名は `git-delta` だが、入るコマンドは `delta`（`brew install delta` でも同じ formula に解決される）

**[git-delta](#git-delta)の手順 3: git の設定の書き方**

- `~/.gitconfig` を直接編集せず、`git config --global` で書く（既にある `[user]` や `[core]` を壊さない）
- ブロックの最後の行で、書けたか読み戻す
- `interactive.difffilter` と小文字で表示されるのは、git がキー名を正規化するため。`~/.gitconfig` の中では `diffFilter` のまま
- `merge.conflictstyle zdiff3` は delta とは独立した設定だが、コンフリクト表示が読みやすくなるので一緒に入れている
- `zdiff3` は git 2.35 以降で使える（AlmaLinux 10 の RPM は 2.52.0）
- [Git](#git)の手順 5 でも同じ値を入れる。先に通していても、同じキーが書き直されるだけ

**[git-delta](#git-delta)の手順 4**

- **`git diff` を単体で打ったときは、端末に直接出る場合だけ delta を通る**。`git diff | head` のようにパイプに繋ぐと git はページャを呼ばないので、素の差分が出る

- 版は `delta 0.19.2` / `git-delta 0.19.2` のように出る

**[git-delta](#git-delta)の手順 4: 差分の出し方**

- ブロックの最後の行で、変更のあるリポジトリの差分を出す

**[git-delta の設定ファイル](#git-delta-の設定ファイル)のリード**

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

**選択した方針**

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `git-delta 0.19.2` の `arm64_linux` ボトルがある。upstream の最新と一致。formula に `delta` という別名が付いているので `brew install delta` でも入る | **採用** |
| EPEL / AppStream / CRB | **`delta` も `git-delta` も無い**（`dnf list --available delta git-delta` → `Error: No matching Packages to list`）。※ `delta` という名前の無関係なパッケージも無い | 使えない |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-gnu` の tar と `.rpm` が置いてある。rpm を直接入れると dnf のリポジトリ管理外になり更新が手作業になる | 不採用（Homebrew に揃える） |
| `cargo install git-delta` | Rust toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |
| diff-so-fancy / difftastic | 別物（difftastic は EPEL に `0.67.0` がある）。構文木で比較する difftastic とは用途が違うので、置き換えではなく併用できる | 対象外 |

**参照**

- [dandavison/delta — README](https://github.com/dandavison/delta) — 使い方、`~/.gitconfig` の書き方、side-by-side と navigate の説明
- [delta manual](https://dandavison.github.io/delta/) — 全設定項目、`features` による設定のまとめ方、他ツールとの連携
- [lazygit 0.65.1 の差分表示設定](https://github.com/jesseduffield/lazygit/blob/v0.65.1/docs/Custom_DiffRenderers.md) — `git.diffRenderers` の `stdinFilter` と delta の指定
- `delta --help` / `delta --show-config` / `delta --list-syntax-themes` — オプションと実効値、配色の一覧
- `git help config` の `core.pager` / `interactive.diffFilter` — git 側の仕様
- [Homebrew](#homebrew)の手順 1〜2 — Homebrew 本体の導入手順。`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件は[Homebrew の補足と注意点](#homebrew-の補足と注意点)の「注意点」、`brew` の基本操作は[Homebrew の使い方の基本](#homebrew-の使い方の基本)
- [ScoopInstaller/Main — delta.json](https://github.com/ScoopInstaller/Main/blob/master/bucket/delta.json) — scoop の版、x64 の zip と hash、`delta.exe` の shim
- [winget-pkgs — dandavison.delta 0.20.1](https://github.com/microsoft/winget-pkgs/blob/master/manifests/d/dandavison/delta/0.20.1/dandavison.delta.installer.yaml) — 同じ zip の sha256 と、VC++ ランタイムの依存（採らなかった経路）
- [delta manual — Using Delta on Windows](https://dandavison.github.io/delta/tips-and-tricks/using-delta-on-windows.html) — Windows では新しい less が要るという案内
- [src/utils/bat/output.rs（0.20.1）](https://github.com/dandavison/delta/blob/0.20.1/src/utils/bat/output.rs)・[src/features/navigate.rs](https://github.com/dandavison/delta/blob/0.20.1/src/features/navigate.rs) — ページャの探し方と、Windows の less の検索履歴の写しの場所
- [git-for-windows/MINGW-packages — git-wrapper.c](https://github.com/git-for-windows/MINGW-packages/blob/main/mingw-w64-git/git-wrapper.c)・[mingw-w64-git.mak](https://github.com/git-for-windows/MINGW-packages/blob/main/mingw-w64-git/mingw-w64-git.mak) — `cmd\git.exe` が PATH の先頭に `usr\bin` を足すこと
- [ScoopInstaller/Scoop](https://github.com/ScoopInstaller/Scoop) — `install`・`update`・`uninstall` の表示と、arm64 の Windows 11 で x64 の定義を使うこと（`lib/manifest.ps1` の `Get-SupportedArchitecture`）
- [ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit) — 自分用の lazygit の設定。README の「前提ツール」と「Windows で使う場合」
- [Windows 11 の初期設定](windows-setup.md) — [貼り付けの設定](windows-setup.md#貼り付けの設定)の手順 1〜5、scoop（[アプリを入れる](windows-setup.md#アプリを入れる)の手順 2・3）、「PowerShell 7 のプロファイルを設定する」
- [Windows 11 で WezTerm を入れる](shell-terminal.md#windows-11-で-wezterm-を入れる) — VC++ ランタイム（[Windows 11 で WezTerm を入れる](shell-terminal.md#windows-11-で-wezterm-を入れる)の手順 3）と、Git Bash で開く自分用の設定

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

---

### GitHub CLI

- GitHub の dnf のリポジトリから GitHub CLI（`gh`）を入れ、GitHub にログインする
- 前提: GitHub のアカウントを用意し、[ログインと sudo](#ログインと-sudo)を通してある
  - この項の手順 4 のブラウザ認証には、このホストのブラウザ（[Firefox](#firefox)）か、手元のブラウザを使う
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ

1. `dnf config-manager` を使えるようにし、リポジトリを追加する。

   ```bash
   # dnf のリポジトリ管理コマンドを導入する
   sudo dnf install -y 'dnf-command(config-manager)'
   printf '\n\033[7m 確認 \033[0m\n'
   sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
   cat /etc/yum.repos.d/gh-cli.repo
   ```

   - `/etc/yum.repos.d/gh-cli.repo` ができればよい
   - `gpgcheck=1` になっていることを確認する

1. gh をインストールする。

   ```bash
   sudo dnf install gh
   ```

   - 入るパッケージの一覧の後に `これでよろしいですか? [y/N]` と聞かれる。`y`
   - 初回は、続けて署名鍵の取り込みを **2 回**聞かれる
   - fingerprint が次の 2 つであることを目で確かめてから `y` と答える（この順に出る）
     - `2C61 0620 1985 B60E 6C7A C873 23F3 D4EA 7571 6059`
     - `7F38 BBB5 9D06 4DBC B3D8 4D72 5612 B364 6231 3325`
   - どちらも Userid は `GitHub CLI <opensource+cli@github.com>`。違っていれば `N` で中断する
   - 1 つ目の鍵の取り込みで `The certificate is expired: …` と出ても、導入は続く
   - **次の手順は、答えてから貼る**（続けて貼ると、導入や署名鍵の確認を断ったときも、GitHub への認証を始める行が動く）

1. GitHub へのログインを始める。

   ```bash
   gh auth login
   ```

   - 対話で GitHub.com / HTTPS / ブラウザ認証を選ぶ
   - `Authenticate Git with your GitHub credentials?` は `Y`
   - ワンタイムコードが表示されたら、この項の手順 4 のブラウザで使う
   - **トークン（`gh auth token` の出力）や、認証中に表示されるワンタイムコードはこの文書に載せない**

1. ブラウザで、GitHub の認証を済ませる。

   - この項の手順 3 のワンタイムコードを、ブラウザの `https://github.com/login/device` に入れ、画面の案内に従う
   - SSH 越しの端末でこのホストのブラウザを開けないときは、手元のブラウザで開く
   - **次の手順は、`gh auth login` が終わってから貼る**（ブラウザで認証し、端末で認証が終わったことを確かめてから進む）

1. 認証できたか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # GitHub の認証状態を確かめる
   gh auth status
   # GitHub CLI の版を確かめる
   gh --version
   ```

   - 認証前の `gh auth status` は `You are not logged into any GitHub hosts.` を返す

<details id="github-cli-の補足と注意点">
  <summary>GitHub CLI の補足と注意点</summary>

**注意点**

- **GitHub CLI: EPEL と公式リポジトリが両方有効だと、更新のたびに両者を比較する**: バージョンが高い公式側が選ばれるので、実害は無い
  - EPEL 側だけを使いたいなら、`exclude=gh` を `gh-cli` 側に書くか、リポジトリを無効にする

- **GitHub CLI: トークンの置き場所**: OS の資格情報ストアを優先し、使えない場合は `~/.config/gh/hosts.yml` に平文で保存する。保存先は `gh auth status` で確認し、平文ファイルをバックアップや共有に混ぜない
  - `gh auth logout` はローカルの認証情報を外す。GitHub 側のトークンの失効は別の操作

- **GitHub CLI: `gh` は git を呼ぶ**: `gh repo clone` などは git に依存する。最小構成のホストでは git 一式が付いてくる

- **GitHub CLI: 全アーキ共通リポジトリ**: `dnf list gh` に `i386` / `armv6hl` の行が出るのは正常

**[GitHub CLI](#github-cli)の手順 1**

- `repo の追加: https://cli.github.com/packages/rpm/gh-cli.repo` と出て、`/etc/yum.repos.d/gh-cli.repo` ができる

**[GitHub CLI](#github-cli)の手順 1: 生成される repo ファイルと、dnf4 と dnf5 の構文の違い**

検証記録（`docs/verification/almalinux-setup.md` の「GitHub CLI の記録」）を参照する。

追加するのは公式が配っている repo ファイルで、生成される `/etc/yum.repos.d/gh-cli.repo` は次のとおり:

```ini
[gh-cli]
name=packages for the GitHub CLI
baseurl=https://cli.github.com/packages/rpm
enabled=1
gpgcheck=1
gpgkey=https://cli.github.com/packages/githubcli-archive-keyring.asc
```

AlmaLinux 10.2 の dnf は **4.20.0**（`dnf5` パッケージは未導入）なので `--add-repo` を使う。Fedora の dnf5 では `dnf config-manager addrepo --from-repofile=…` の形になる（[GitHub CLI の公式 Linux 導入手順](https://github.com/cli/cli/blob/trunk/docs/install_linux.md#dnf5)）。

**[GitHub CLI](#github-cli)の手順 2**

- 1 つ目の鍵を取り込むと、`警告: Certificate 23F3D4EA75716059:` と、次の行に `The certificate is expired: …` が出る（2026-09-05 に期限が切れている）。導入は続く

**[GitHub CLI](#github-cli)の手順 2: 署名鍵**

- 鍵が 2 本あるので、初回は取り込みを 2 回聞かれる

**[GitHub CLI](#github-cli)の手順 4: 認証**

トークンは OS の資格情報ストアに保存される。ストアを使えない場合は `~/.config/gh/hosts.yml` の平文保存に切り替わる。保存先は `gh auth status` で確認する。`gh auth token` の出力は**記録しない**。

**選択した方針**

- 両方が有効なら、dnf はバージョンの高い `gh-cli` 側を選ぶ
- `armv6hl` や `i386` の行が見えるのは、このリポジトリが `baseurl` にアーキテクチャを含まない**全アーキテクチャ共通**の作りだから（Mozilla のリポジトリと同じ）

**参照**

- [ScoopInstaller/Main — gh.json](https://github.com/ScoopInstaller/Main/blob/master/bucket/gh.json) — Windows 11 の scoop の定義（版・zip と sha256・`bin\gh.exe`）
- [winget-pkgs — GitHub.cli 2.102.0](https://github.com/microsoft/winget-pkgs/blob/master/manifests/g/GitHub/cli/2.102.0/GitHub.cli.installer.yaml) — MSI（machine）と portable（採らなかった経路）
- [gh 2.102.0 の login_flow.go](https://github.com/cli/cli/blob/v2.102.0/pkg/cmd/auth/shared/login_flow.go)・[git_credential.go](https://github.com/cli/cli/blob/v2.102.0/pkg/cmd/auth/shared/git_credential.go)・[gitcredentials](https://github.com/cli/cli/tree/v2.102.0/pkg/cmd/auth/shared/gitcredentials) — ログインの問いと、Git の認証に Yes と答えたときの動き
- [gh 2.102.0 の internal/config/config.go](https://github.com/cli/cli/blob/v2.102.0/internal/config/config.go)・[status.go](https://github.com/cli/cli/blob/v2.102.0/pkg/cmd/auth/status/status.go)・[logout.go（v2.102.0）](https://github.com/cli/cli/blob/v2.102.0/pkg/cmd/auth/logout/logout.go) — トークンの置き場所、状態の表示、ログアウト
- [gh 2.102.0 の internal/ghcmd/cmd.go](https://github.com/cli/cli/blob/v2.102.0/internal/ghcmd/cmd.go) — `GH_PATH` と自分の場所、新しい版の知らせ
- [cli/go-gh v2.16.1 — pkg/config/config.go](https://github.com/cli/go-gh/blob/v2.16.1/pkg/config/config.go) — 設定・状態・データ・キャッシュの場所
- [zalando/go-keyring v0.2.8 — keyring_windows.go](https://github.com/zalando/go-keyring/blob/v0.2.8/keyring_windows.go) — 資格情報マネージャーの項目の名前
- [GitHub CLI manual — gh help environment](https://cli.github.com/manual/gh_help_environment) — `GH_CONFIG_DIR`・`GH_PATH` など
- [Windows 11 の初期設定](windows-setup.md) — [貼り付けの設定](windows-setup.md#貼り付けの設定)の手順 1〜5、scoop（[アプリを入れる](windows-setup.md#アプリを入れる)の手順 2・3）、「PowerShell 7 のプロファイルを設定する」。[Git](#git) — Git for Windows と、その Git Credential Manager

- 検証記録（`docs/verification/almalinux-setup.md`）

- [GitHub CLI の公式 Linux 導入手順](https://github.com/cli/cli/blob/trunk/docs/install_linux.md) — RPM の DNF4 と DNF5 の構文

</details>

---

### lazygit

- Git を端末の画面で操作する lazygit を Homebrew で入れ、自分用の設定を入れて起動を確かめる
- 前提: [共通の bash 設定](shell-terminal.md#共通の-bash-設定)と[Homebrew](#homebrew)を通し、PATH に Homebrew が入った端末（[シェルのツール](shell-terminal.md#シェルのツール)の手順 2 で開き直した端末）を開いてある
  - この項の手順 2 は、[lazygit の設定を導入する](#lazygit-の設定を導入する)の前提も要る
- 実行場所: 前提の端末（GNOME にログインした自分のユーザーの bash）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ

1. brew で lazygit を入れる。

   ```bash
   brew install lazygit
   ```

   - [Neovim](neovim.md#neovim)の手順 2 で入っていれば、`Warning: lazygit … is already installed and up-to-date.` と出て何も変えない
   - **次の手順は、Homebrew の確認が出たら答え、導入が成功してプロンプトに戻ってから貼る**（続けて進むと、導入を断ったときや失敗したときも、自分用の設定の導入へ進む）

1. 自分用の設定（[ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit)）を入れる。

   - [lazygit の設定を導入する](#lazygit-の設定を導入する)の全項を通す
   - 差分の表示に delta（[git-delta](#git-delta)）、アイコンに Nerd Fonts（[HackGen Console NF](shell-terminal.md#hackgen-console-nf)）を使う設定
   - `e` キーで開くエディタは、`EDITOR`（[Neovim](neovim.md#neovim)の手順 3）から決まる

1. lazygit が入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   lazygit --version
   brew list --versions lazygit
   command -v lazygit
   ```

   - lazygit の版と `build source=Homebrew` が出ればよい

1. 共通の bash 設定の clone（`~/.config/bash`）で lazygit を起動して確かめる。

   ```bash
   (cd ~/.config/bash && lazygit)
   ```

   - 初回に `Thanks for using lazygit...` の案内が出たら Enter で閉じる（この項の手順 2 の設定を入れていれば、出ない）。ファイル・変更差分・ブランチ・コミットの一覧が出ればよい
   - `q` で終了する
   - **次の手順は、`q` で終了してから貼る**（lazygit を開いたまま貼ると、lazygit への入力になる）

#### lazygit の設定ファイル

- 置き場所は `~/.config/lazygit/config.yml`（`lazygit --print-config-dir` で確認できる）

#### lazygit の設定を導入する

- 自分用の lazygit の設定（[ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit)）を `~/lazygit-config` に clone し、`~/.config/lazygit/config.yml` にリンクする
- 前提: [lazygit](#lazygit)の手順 1 で lazygit を入れ、[git-delta](#git-delta)と[HackGen Console NF](shell-terminal.md#hackgen-console-nf)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ。この項の手順 1 の前の、既存の `config.yml` の確認と退避を省かない

> [!CAUTION]
> - この項の手順 1 は既存の `~/.config/lazygit/config.yml` を置き換える
> - 残す通常ファイルがある場合は止め、別名へ退避してから、この項の手順 1 を貼る

1. 設定を clone してリンクする。

   ```bash
   # lazygit の設定を取得する
   git clone https://github.com/ryo-aoki-pc/lazygit.git ~/lazygit-config
   # 設定ファイルへのリンクを作成する
   mkdir -p ~/.config/lazygit
   ln -sf ~/lazygit-config/config.yml ~/.config/lazygit/config.yml
   ```

   - 設定の置き場所は `lazygit --print-config-dir` で確かめる

#### lazygit の設定を更新する

- 自分用の lazygit の設定の clone を GitHub の `custom` に合わせる。持ち主が上流の新しい版に合わせて `custom` を載せ替えた（force push した）後も、この項で合わせる
- 前提: [lazygit の設定を導入する](#lazygit-の設定を導入する)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ。この項の手順 1 の手元の変更の確認を省かない
- lazygit 本体は[共通の bash 設定・Homebrew・Flatpak を上げる](#共通の-bash-設定homebrewflatpak-を上げる)の手順 2・3 で上げる

> [!WARNING]
> - この項の手順 3 では、この clone でコミットしたものは新しい `custom` に載らない（前の位置は `git -C ~/lazygit-config reflog` で見られる）。
>
> - **この項の手順 4 は、ぶつからなかったファイルの分も含め、手元の変更を作業ツリーから消す**。変更は stash にだけ残る

1. 手元の変更を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   git -C ~/lazygit-config status --short --branch
   ```

   - 1 行目が `## custom...origin/custom` で始まればよい（`[ahead …, behind …]` が続いてもよい）
   - 2 行目から出る行（` M config.yml` など）は手元の変更。この項の手順 2 で残したまま合わせる
   - 1 行目が `## HEAD (no branch)` で、前にこの項の手順 2 を貼って止まったままなら、この項の手順 2 は飛ばし、手順 3 から貼る
   - そのほかに、1 行目が `## custom` で始まらなければ、中断する

1. GitHub の `custom` に合わせる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   git -C ~/lazygit-config pull --rebase --autostash
   git -C ~/lazygit-config status --short --branch
   ```

   - `Successfully rebased and updated refs/heads/custom.`・`Fast-forward`・`Already up to date.` のどれかが出て、`status` の 1 行目が `## custom...origin/custom`（`[ahead`・`[behind` が付かない）で、2 行目から `UU` の行が無ければよい
   - 手元の変更を退避して戻したときは、`Created autostash:`・`Applied autostash.` が出て、`status` の 2 行目から同じ形で残る
   - 1 行目が `## HEAD (no branch)` なら（`Could not apply` と出て止まった。`UU` の行も出る）、この項の手順 3 を貼る。手順 4 へ進むかは、手順 3 の `status` で決める
   - 1 行目が `## HEAD (no branch)` でなければ、この項の手順 3 は飛ばす
   - 1 行目が `## custom...origin/custom` で始まり、2 行目から `UU` で始まる行があれば（`resulted in conflicts` と出た）、この項の手順 4 を貼る。無ければ、この項の手順 4 は飛ばす
   - 書き換わった `custom` を取り込んだときは、`(forced update)` の行が出る

1. この項の手順 2 の `status` の 1 行目が `## HEAD (no branch)` のときだけ、手元の変更を残して rebase を取り消し、新しい `custom` に移る。

   ```bash
   # 競合中の rebase を中止する
   git -C ~/lazygit-config rebase --abort
   printf '\n\033[7m 確認 \033[0m\n'
   git -C ~/lazygit-config rebase --autostash --onto origin/custom HEAD
   git -C ~/lazygit-config status --short --branch
   ```

   - `Successfully rebased and updated refs/heads/custom.` と出て、`status` の 1 行目が `## custom...origin/custom`（`[ahead`・`[behind` が付かない）で、2 行目から `UU` の行が無ければよい
   - 手元の未コミットの変更は残る
   - 2 行目から `UU` で始まる行があれば、この項の手順 4 を貼る。無ければ、この項の手順 4 は飛ばす

1. この項の手順 2・3 の `status` が `## custom` で始まり `UU` の行を出したときだけ、作業ツリーを新しい設定に戻す。

   ```bash
   # 作業ツリーの変更を破棄する
   git -C ~/lazygit-config reset -q --hard
   printf '\n\033[7m 確認 \033[0m\n'
   # 作業ツリーの状態を確かめる
   git -C ~/lazygit-config status --short --branch
   # 退避した変更の内容を確かめる
   git --no-pager -C ~/lazygit-config stash show -p
   ```

   - `status` が `## custom...origin/custom` の 1 行だけになり、その後ろに手元の変更の差分が出ればよい
   - 要るものをエディタで書き直す
   - 書き直したら、`git -C ~/lazygit-config stash drop` で stash を消す

1. 設定の元にした上流の版と、入っている本体の版を比べる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # 設定の基になったリリースを確かめる
   git --no-pager -C ~/lazygit-config log -1 --format=%s origin/main
   # lazygit 本体の版を確かめる
   lazygit --version
   ```

   - 設定の元にした上流の版と、`version=` の版が同じならよい
   - 本体の方が古ければ、[共通の bash 設定・Homebrew・Flatpak を上げる](#共通の-bash-設定homebrewflatpak-を上げる)の手順 2・3 で上げる

<details id="lazygit-の補足と注意点">
  <summary>lazygit の補足と注意点</summary>

**注意点**

- **lazygit も、Homebrew の注意のとおり**: PATH の先頭が Homebrew になる、`sudo lazygit` はそのままでは使えない、など
  - RPM 版と両方入れると分かりにくくなるので、どちらか一方にする

- **lazygit: COPR 経路は「有効化は成功するのに入らない」**: `dnf copr enable` が通っても、メタデータが取れなければ `dnf install` は `No match for argument` になるだけで、原因は警告行にしか出ない
  - COPR を使う前に `curl -sS -o /dev/null -w '%{http_code}\n' -L <chroot の repodata/repomd.xml>` で 200 が返るか確かめると早い

- **lazygit: git が要る**: lazygit は git のラッパーなので、git の設定（`user.name` / `user.email`、認証）はそのまま効く

- **lazygit: 設定ファイルは自分で作る**: `lazygit --print-config-dir` が返すディレクトリは、初回起動時には空のことがある

**[lazygit](#lazygit)の手順 1: ボトル**

- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない

**[lazygit](#lazygit)の手順 3**

- `build source=Homebrew, version=0.65.1, os=linux, arch=arm64` のように出る

**[lazygit](#lazygit)の手順 3・4: 起動時の注意**

検証記録（`docs/verification/almalinux-setup.md` の「lazygit: 実施手順 / 手順 3: 補足: 起動時の注意」）

`lazygit --version` の `git version` 欄には、lazygit が呼ぶ git のバージョンが出る。

- **git が入っていないと lazygit は起動しない。**

- Homebrew 版は git を依存に持たないので、RPM の git か `brew install git` のどちらかが要る

git 管理下でないディレクトリで起動すると `Would you like to create a new repository?` と聞かれる。意図せず `.git` を作らないよう、リポジトリのルートで起動する。

**[lazygit](#lazygit)の手順 4**

- **注意**: git 管理下でないディレクトリで起動すると、リポジトリを作るか聞かれる

**[lazygit の設定ファイル](#lazygit-の設定ファイル)のリード**

- パッケージは設定ファイルを置かない。無ければ組み込みの既定値で動く

- Windows 11 は `%LOCALAPPDATA%\lazygit\config.yml`（`%APPDATA%\lazygit\config.yml` があれば、そちらも読む）。`state.yml` も同じフォルダー
- Windows 11 の場所は[lazygit](windows-setup.md#lazygit)の手順 6 で確かめる
- **自分用の設定**は [ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit) にある（公式の既定の全項目に、あいまい検索・Nerd Fonts のアイコン・マウス無効などの変更を載せた `config.yml`）
  - 導入は[lazygit](#lazygit)の手順 2。`config.yml` を `~/.config/lazygit/config.yml` にリンクする
  - 更新は[lazygit の設定を更新する](#lazygit-の設定を更新する)（[lazygit の設定を更新する](windows-setup.md#lazygit-の設定を更新する)）で行う
  - Windows 11 は[lazygit](windows-setup.md#lazygit)の手順 5。リンクにせず `%LOCALAPPDATA%\lazygit` に直接 clone する
  - 何を変えたかは [設定のリポジトリの参考資料の「主な設定内容」](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/reference/readme.md#主な設定内容)
  - アイコンに Nerd Fonts が要る（`gui.nerdFontsVersion: "3"`）。端末のフォントを HackGen Console NF（[HackGen Console NF](shell-terminal.md#hackgen-console-nf)）にする
    - Windows 11 への導入は[Windows 11 で HackGen Console NF を入れる](shell-terminal.md#windows-11-で-hackgen-console-nf-を入れる)。WezTerm は自分用の設定で変わる
    - Windows Terminal のフォントは[Windows Terminal のフォントと貼り付けの警告を変える](shell-terminal.md#windows-terminal-のフォントと貼り付けの警告を変える)で変える
  - 差分に delta を使う（[git-delta](#git-delta)・[git-delta](windows-setup.md#git-delta)）。Windows の引用符は[設定例](https://github.com/ryo-aoki-pc/lazygit#windows-で使う場合)を参照する
  - `e` キーで開くエディタは、`EDITOR` などから自動で決まる（[Neovim](neovim.md#neovim)の手順 3）
    - Windows 11 で Windows PowerShell から起動するなら、[Neovim を既定のエディタにする](neovim.md#neovim-を既定のエディタにする)で、ユーザーの環境変数 `EDITOR` を `nvim` にする

**[lazygit の設定を導入する](#lazygit-の設定を導入する)の手順 1**

- `e` キーのエディタは `EDITOR` から決まる

- 一時的に試すなら `lazygit --use-config-file ~/lazygit-config/config.yml` を使う

**[lazygit の設定を更新する](#lazygit-の設定を更新する)の手順 2**


- `[ahead 1]` などが残ったら、この clone でコミットしたものが新しい `custom` の上に載っている

**[lazygit の設定を更新する](#lazygit-の設定を更新する)の手順 2: force push と分岐点**

- 持ち主が `custom` を新しい `main` の上へ載せ直すと、古い `custom` からは fast-forward で移れない。`git pull --ff-only` は `fatal: Not possible to fast-forward, aborting.` で止まる
- `git pull --rebase --autostash` は、fetch 前の `origin/custom` と、その reflog から分岐点（fork point）を求める
- 古い `custom` のコミットを重ねず、この clone だけのコミットを新しい `custom` の上に載せる
- clone 直後には `origin/custom` の reflog が無い。最初の fetch が作る reflog の行は、古い `custom` の位置も持つ。lazygit の自動の fetch などで先に取得していても、その reflog が残っていれば分岐点が分かる
- `--rebase --autostash` を明示するので、global の `pull.rebase`・`rebase.autoStash` の設定には頼らない

**[lazygit の設定を更新する](#lazygit-の設定を更新する)の手順 3: 分岐点が分からないときの載せ直し**

- 先に fetch 済みで、`origin/custom` の reflog も期限切れなどで無いと、古い `custom` のコミットを全部載せ直そうとする
- 最初のコミットで衝突すると `Could not apply` で止まり、`status` の 1 行目が `## HEAD (no branch)` になる。2 行目からは、止まったコミットの `UU` の行が出る（[lazygit の設定を更新する](#lazygit-の設定を更新する)の手順 4 の autostash の衝突とは別のもので、[lazygit の設定を更新する](#lazygit-の設定を更新する)の手順 4 には進まない）
- `rebase --abort` は rebase を始める前に戻し、autostash があれば手元の変更も戻す。その後の `rebase --autostash --onto origin/custom HEAD` は、載せ直すコミットが無いので、新しい `custom` に移るだけになる
- この方法では、この clone だけのコミットは新しい `custom` に載らない。前の位置は HEAD の reflog に残る
- `git reset --keep origin/custom` は、手元の変更のあるファイルを新しい `custom` も変えていると、`Entry '<ファイル>' not uptodate. Cannot merge.` で止まり、何も変えない
- `--onto` なら autostash の衝突も、[lazygit の設定を更新する](#lazygit-の設定を更新する)の手順 4 と同じ方法で扱える

**[lazygit の設定を更新する](#lazygit-の設定を更新する)の手順 4: autostash の衝突と reset の範囲**

- git 2.52.0 は、autostash を戻すときに衝突すると `Applying autostash resulted in conflicts.`・`Your changes are safe in the stash.` と出す。rebase 自体は終わり、終了コードは 0 になる
- 文言は git の版で違う。成功のメッセージや終了コードだけでは判定せず、`status` の 1 行目が `## custom...origin/custom` で、2 行目から `UU` の行があるかで見分ける。手元の変更は `stash@{0}: autostash` に残る
- この状態で使う `reset -q --hard` は、移動先を指定せず、作業ツリー全体を現在の HEAD（新しい `custom`）に戻す。ぶつからなかったファイルの手元の変更も作業ツリーから消えるが、autostash の stash にすべて残り、`stash show -p` で出る
- 最初から `git reset --hard origin/custom` で合わせる方法は採らない。stash に入っていない未コミットの変更が消え、この clone だけのコミットも新しい `custom` に載らない

**[lazygit の設定を更新する](#lazygit-の設定を更新する)の手順 5**

- `lazygit v0.66.0 のデフォルト設定に更新` の版と、その次の行の `version=0.66.0` が同じならよい

**[lazygit の設定を更新する](#lazygit-の設定を更新する)の手順 5: 版の表示と pager**

- `origin/main` の最後のコミットの題は、上流の既定設定を取り込んだ版を示す。本体の `--version` の `version=` と比べる
- `git log` は設定済みの pager（delta）を通るので、`--no-pager` を付ける。`status` は pager を使わない

**選択した方針**

- `atim/lazygit` でも同じ 403
- dnf を介さず `curl -L` で `repomd.xml` を取っても同じ。COPR の配信元（`download.copr.fedorainfracloud.org`）が S3 の署名付き URL にリダイレクトし、その署名が期限切れになっている
- 一方で COPR 全体が落ちているわけではない。同じ日に `lihaohong/yazi` の `epel-10-aarch64` はメタデータを取得できている（[yazi](#yazi)）
- **プロジェクトごとの問題で、いずれ直る可能性がある**

**参照**

- [jesseduffield/lazygit — README](https://github.com/jesseduffield/lazygit) — 各 OS のインストール方法と機能一覧
- [lazygit Config Docs](https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md) — `config.yml` の項目（`os.edit` など）
- [Homebrew](#homebrew)の手順 1〜2 — Homebrew 本体の導入手順。`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件は[Homebrew の補足と注意点](#homebrew-の補足と注意点)の「注意点」、`brew` の基本操作は[Homebrew の使い方の基本](#homebrew-の使い方の基本)
- [atim/lazygit — Copr](https://copr.fedorainfracloud.org/coprs/atim/lazygit/) / [dejan/lazygit — Copr](https://copr.fedorainfracloud.org/coprs/dejan/lazygit/) — chroot の一覧（`epel-10-aarch64` はある）
- [ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit) — 自分用の設定（`config.yml`）。導入方法と変えた項目は README にある
- [ScoopInstaller/Extras — lazygit.json](https://github.com/ScoopInstaller/Extras/blob/master/bucket/lazygit.json) — Windows 11 の scoop の定義
- [lazygit Config Docs（v0.66.0）](https://github.com/jesseduffield/lazygit/blob/v0.66.0/docs/Config.md) — Windows の設定の場所（`%LOCALAPPDATA%\lazygit\config.yml`）と `LG_CONFIG_FILE`
- [lazygit の設定を導入する](#lazygit-の設定を導入する) — 自分用の設定の Windows の clone の例

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

---

### excel-diff

- Excel のブックと Word の文書の差分表示・部分ステージ・2 つのファイルの取り込みに使う道具（[excel-diff](https://github.com/ryo-aoki-pc/excel-diff)）

#### excel-diff を導入・更新する

- Excel のブックと Word の文書の差分をテキストで出す textconv と、`git excel-stage`・`git excel-merge`・`git word-stage`・`git word-merge` を Git 全体に入れ、導入状態を確かめる
- 前提: Python 3.9 以上と git が入っている（git は[Homebrew](#homebrew)の手順 1 で入る）
  - 部分ステージと lazygit での取り込みには、lazygit 0.66.0 以上・delta 0.20.1 以上も要る
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）。`sudo` は、ensurepip で止まったときの `python3-pip` の導入だけで使う
- 更新時は `git -C ~/excel-diff status` で既存の変更を確かめてから進む

1. Python の版を確かめる。

   ```bash
   python3 --version
   ```

   - `Python 3.9` 以上の版が出ればよい
   - 3.9 より古い版やエラーが出たら、その Python を更新してから貼り直す

1. リポジトリを clone し、導入して確かめる。

   ```bash
   # excel-diff のソースを取得する
   git clone https://github.com/ryo-aoki-pc/excel-diff.git ~/excel-diff
   # コマンドを導入して設定を検査する
   (
     cd ~/excel-diff || exit
     printf '\n\033[7m 確認 \033[0m\n'
     python3 scripts/setup-excel-diff.py &&
       python3 scripts/setup-excel-diff.py --check
   )
   ```

   - 導入時に「Excel・Word の差分と部分ステージをグローバルに設定しました。」、確認時に「Excel・Word の差分と部分ステージの設定を確認しました。」が出ればよい
   - その後ろに「変換スクリプト:」「部分ステージ: … (git excel-stage / git word-stage)」「取り込み: git excel-merge / git word-merge」「attributes:」の行が出ればよい
   - 仮想環境の作成が ensurepip で止まる場合は `sudo dnf install python3-pip` を行い、この項の手順 2 の `(`〜`)` 部分を貼り直す
   - 同期したリポジトリでも端末ごとに一度実施し、スクリプトを更新したら再実行する
   - 更新時は `git -C ~/excel-diff pull --ff-only` を実行し、この項の手順 2 の `(`〜`)` 部分（導入・確認）を貼り直す。`git clone` は再実行しない

#### lazygit で Excel の差分を確かめる

- Excel のブックのある Git リポジトリで、ブックの差分がシートとセル番地の付いたテキストで出ることを確かめる
- 前提: [excel-diff を導入・更新する](#excel-diff-を導入更新する)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）の、ブックのある Git リポジトリのディレクトリ。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ

1. Excel のある Git リポジトリで差分を確かめる（`売上表.xlsx` は実際のファイル名）。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # 差分変換の属性を確かめる
   git check-attr diff -- "売上表.xlsx"
   # 作業ツリーとインデックスの差分を表示する
   git diff -- "売上表.xlsx"
   git diff --cached -- "売上表.xlsx"
   ```

   - 最初に `売上表.xlsx: diff: excel` が出て、差分に `Sheet:` とセル番地が出ればよい
   - 日本語のファイル名が引用符と 8 進数で出ても、同じファイル
   - lazygit を開き直してファイルを選ぶと delta で表示する。`|` の内蔵表示でも Excel のテキスト差分が出る
   - `unset` や別のドライバーが出たら、そのリポジトリの `.gitattributes`・`.git/info/attributes` を確認する
   - そのリポジトリだけに設定するなら、`.git/info/attributes` に `*.[xX][lL][sS][xX] diff=excel` を足す
   - 全体をステージするには、lazygit の**ファイル一覧で `Space`** を押す
   - **通常差分の `Enter` から行・ハンクのステージや破棄を行わない**。既存 Excel にはパッチを適用できず、新規ファイルはテキストをステージしてしまう場合がある
   - `diff.excel.binary=true` でも、この操作は禁止されない。部分ステージは[専用画面](#lazygit-で-excel-のセル変更を部分ステージする)の `E` で行う

#### lazygit で Excel のセル変更を部分ステージする

- lazygit の専用画面で、Excel のブックのセルの変更を選んで index に入れる
- 前提: [lazygit](#lazygit)・[git-delta](#git-delta)・[excel-diff を導入・更新する](#excel-diff-を導入更新する)を通してある（lazygit 0.66.0 以上・delta 0.20.1 以上）
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）で、ブックのある Git リポジトリを開いた lazygit。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ
- 対象は HEAD と index にある既存 `.xlsx` / `.xlsm` / `.xltx` / `.xltm` / `.xlam` / `.xlsb`
- 新規ファイルは全体をコミットしてから使う

1. lazygit のファイル一覧で対象を選び、`E` を押す。

   - 端末から開くなら `git excel-stage -- "売上表.xlsx"`。実際のファイル名に置き換える
   - 専用画面が開くまで待つ。大きいブックでは「Excel を読み込んでいます」と出る

1. 専用画面で `Enter` → `Space` を押してハンクを選ぶ。

   - 左右の矢印で移動し、ステージ済み差分を確認する
   - 値・通常の数式は `.cells.txt`、セルの書式（表示形式・フォント・塗りつぶし・罫線・配置・保護・セルのスタイル）は `.formats.txt` のハンクで選ぶ。同じセルの値と書式は別々に選べる。置換は削除・追加の両方を選ぶ
   - 行の高さ・列の幅・条件付き書式・画像・マクロ・行列の挿入や移動を反映する場合は、元のファイル一覧で全体をステージする
   - 対応できない変更は index を変更せず中断する。[対応条件と制限](https://github.com/ryo-aoki-pc/excel-diff/blob/main/docs/extra/readme.md)を確認する

1. 選択を確認して専用画面の `X` で適用し、`q` で戻る。

   - `X` の前に `q` で閉じれば選択を取り消す
   - 作業中の Excel は変えず、選ばなかったセルの書式と、画像・マクロは index 側のものを保持する
   - 開いた後に対象の index・作業ファイルが変わった場合は中断する。閉じて `E` から開き直す
   - 選んだ文字列セルのふりがなは引き継がない。未選択のセルは保持する
   - 値・数式を選んだときは、次に Excel で開いたときに再計算する。スクリプトはマクロ・外部リンク更新・数式再計算を実行しない

#### lazygit で大きな Excel の変換を待つ

- 大きなブックの差分を、全セルの変換が終わるまで待ってから出す
- 前提: [excel-diff を導入・更新する](#excel-diff-を導入更新する)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）の、ブックのある Git リポジトリのディレクトリ。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ

1. 全セルの変換を待って差分を表示する（`売上表.xlsx` は実際のファイル名）。

   ```bash
   EXCEL_TEXTCONV_TIMEOUT=0 git diff -- "売上表.xlsx"
   ```

   - 通常の変換中のブックは、完了後に選び直すか `R` で表示する

#### lazygit で 2 つの Excel のセルの変更を取り込む

- 2 つのブックを比べ、取り込み元のセルの値・通常の数式・セルの書式を選んで取り込み先へ書き込む
- 前提: [excel-diff を導入・更新する](#excel-diff-を導入更新する)・[lazygit](#lazygit)・[git-delta](#git-delta)を通してある（lazygit 0.66.0 以上・delta 0.20.1 以上）
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ。Git リポジトリの外でも使える
- 書き換えるのは最初に指定する取り込み先で、`.bak` は作らない。取り込み先を Excel などで開いていたら閉じておく
- 対象は両方とも `.xlsx` / `.xlsm` / `.xltx` / `.xltm` / `.xlam` / `.xlsb` で、シートの構成が同じブック
- xlsb 同士、または xlsx 系（`.xlsx` / `.xlsm` / `.xltx` / `.xltm` / `.xlam`）同士を指定する
- 対応条件と制限は[excel-diff の注意点](https://github.com/ryo-aoki-pc/excel-diff/blob/main/docs/extra/readme.md#注意点)を確認する

1. 変数を設定する（`EXCEL_TARGET`・`EXCEL_SOURCE` は必ず値を入れる）。

   ```bash
   EXCEL_TARGET=''                       # ← 取り込み先（書き換えるブック）の絶対パス
   ```

   ```bash
   EXCEL_SOURCE=''                       # ← 取り込み元のブックの絶対パス
   ```

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'EXCEL_TARGET = %s\nEXCEL_SOURCE = %s\n' "$EXCEL_TARGET" "$EXCEL_SOURCE"
   ```

   - 取り込み先と取り込み元の絶対パスを読み戻して確かめる
   - 新しい端末を開いたら、この項の手順 1 を貼り直してから先へ進む

1. 2 つのブックを比べる専用画面を開く。

   ```bash
   # 取り込み先と取り込み元を指定してブックを開く
   if [ -z "$EXCEL_TARGET" ] || [ -z "$EXCEL_SOURCE" ]; then
     echo '中断: この項の手順 1 の EXCEL_TARGET または EXCEL_SOURCE が空のまま' >&2
   else
     git excel-merge -- "$EXCEL_TARGET" "$EXCEL_SOURCE"
   fi
   ```

   - 「書き換えるファイル: …」「取り込み元: …」が指定したパスであることを確かめる
   - 「差分がありません。取り込み先は変えていません。」または「取り込める差分がありません（取り込めない違い N セル）。取り込み先は変えていません。」が出たら、この項の手順 3 は飛ばす
   - 「取り込めない違い（N セル）: …」が出たら、一覧のセルは選べない
   - 「Excel の取り込みに失敗しました: …」が出たら、理由を確かめてからやり直す
   - **次の手順は、専用画面で行う**

1. 専用画面でハンクを選び、取り込み先へ書き込んで閉じる。

   - `Enter` → `Space` を押してハンクを選び、左右の矢印で移動して選択を確かめる。置換は削除・追加の両方を選ぶ
   - 値・数式は `.cells.txt`、セルの書式は `.formats.txt` で選ぶ。同じセルの値と書式は別々に選べる
   - `X` で書き込み、「N セルを取り込み先へ書き込みました。q で元の画面へ戻ってください。」が出たら `q` で閉じる。書式も選んだときは「値 N セル・書式 M セルを…」（書式だけなら「書式 M セルを…」）と出る
   - `X` の前に `q` で閉じれば選択を取り消し、「取り込むセルが選ばれていません。取り込み先は変えていません。」が出る
   - 「セル変更が選択されていません。Enter・Space でハンクを選び、X で反映してください。」が出たら、ハンクを選んで `X` を押す
   - 取り込み先を Excel などで開いたために書き込めなければ、閉じて `X` を押し直す
   - 専用画面を閉じると、端末に「N セルを取り込み先へ書き込みました: …」（書式も取り込んだときは「値 N セル・書式 M セルを取り込み先へ書き込みました: …」、書式だけなら「書式 M セルを取り込み先へ書き込みました: …」）が出ればよい

#### lazygit で Word の差分を確かめる

- Word の文書のある Git リポジトリで、文書の差分が段落ごとのテキストで出ることを確かめる
- 前提: [excel-diff を導入・更新する](#excel-diff-を導入更新する)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）の、文書のある Git リポジトリのディレクトリ。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ
- 対象は Transitional の OOXML の `.docx` / `.docm` / `.dotx` / `.dotm`。暗号化・`.doc`・Strict は表示しない

1. Word のある Git リポジトリで差分を確かめる（`仕様書.docx` は実際のファイル名）。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # Word 用の差分変換の属性を確かめる
   git check-attr diff -- "仕様書.docx"
   # 作業ツリーとインデックスの差分を表示する
   git diff -- "仕様書.docx"
   git diff --cached -- "仕様書.docx"
   ```

   - 最初に `仕様書.docx: diff: word` が出て、差分に `# 本文` と段落の行が出ればよい
   - 日本語のファイル名が引用符と 8 進数で出ても、同じファイル
   - lazygit を開き直してファイルを選ぶと delta で表示する。`|` の内蔵表示でも Word のテキスト差分が出る
   - `unset` や別のドライバーが出たら、そのリポジトリの `.gitattributes`・`.git/info/attributes` を確認する
   - そのリポジトリだけに設定するなら、`.git/info/attributes` に `*.[dD][oO][cC][xX] diff=word` を足す
   - 全体をステージするには、lazygit の**ファイル一覧で `Space`** を押す
   - **通常差分の `Enter` から行・ハンクのステージや破棄を行わない**。既存 Word にはパッチを適用できず、新規ファイルはテキストをステージしてしまう場合がある
   - `diff.word.binary=true` でも、この操作は禁止されない。部分ステージは[専用画面](#lazygit-で-word-の変更を部分ステージする)の `E` で行う
   - 大きい文書の変換を待つなら、[lazygit で大きな Excel の変換を待つ](#lazygit-で大きな-excel-の変換を待つ)と同じ環境変数 `EXCEL_TEXTCONV_TIMEOUT` を使い、ファイル名を対象の Word に置き換える

#### lazygit で Word の変更を部分ステージする

- lazygit の専用画面で、Word の文書の段落・表・書式などの変更を選んで index に入れる
- 前提: [lazygit](#lazygit)・[git-delta](#git-delta)・[excel-diff を導入・更新する](#excel-diff-を導入更新する)を通してある（lazygit 0.66.0 以上・delta 0.20.1 以上）
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）で、文書のある Git リポジトリを開いた lazygit。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ
- 対象は HEAD と index にある既存 `.docx` / `.docm` / `.dotx` / `.dotm`
- 新規ファイルは全体をコミットしてから使う
- 対象は Transitional の OOXML。暗号化・`.doc`・Strict・電子署名付きの文書は部分ステージしない
- 選べる単位と選べない違いは excel-diff の[Word の部分ステージ](https://github.com/ryo-aoki-pc/excel-diff/blob/main/docs/reference/readme.md#word-の部分ステージ)、制限は[Word の注意点](https://github.com/ryo-aoki-pc/excel-diff/blob/main/docs/extra/readme.md#word-の注意点)を参照する

1. lazygit のファイル一覧で対象を選び、`E` を押す。

   - 端末から開くなら `git word-stage -- "仕様書.docx"`。実際のファイル名に置き換える
   - 「Word を読み込んでいます。大きい文書では選択画面が開くまで時間がかかります。」が出たら、専用画面が開くまで待つ

1. 専用画面で対象の部分を選び、`Enter` → `Space` を押してハンクを選ぶ。

   - ファイル一覧の `001-本文.word.txt` などから、対象の部分を選ぶ
   - 左右の矢印で移動し、ステージ済み差分を確認する
   - 段落・表・セクションの設定・ヘッダーとフッターの段落を選べる。置換は削除・追加の両方を選ぶ
   - 形が同じ表は、表の形・行・セルごとに選ぶ。行の追加などで形が変わった表と、目次など段落をまたぐフィールドは、まとまりの変更行をすべて選ぶ
   - 太字や色などの書式だけを反映するなら、書式の目印が異なる行を選ぶ
   - 「このまとまりの変更行をすべて選んでください。」で止まったら、そのまとまりの変更行をすべて選ぶ
   - コメント、脚注・文末脚注の参照、グラフ・図形など選べない違いは、元のファイル一覧で全体をステージする
   - 「段落単位で反映できません」で止まったら、表示された理由を確かめる。index は変わらない

1. 選択を確認して専用画面の `X` で適用し、`q` で戻る。

   - 「N か所の変更を Word のままステージしました。q で元の画面へ戻ってください。」が出ればよい
   - 目次などを選ぶと「目次などの参照先に合わせて、表示が同じ N か所を取り込み元のものにしました。」も出ることがある。表示が同じ段落を取り込み元のものにしただけで、文字は変わらない
   - `X` の前に `q` で閉じれば選択を取り消す
   - 作業中の Word は変えない
   - 「変更が選択されていません。Enter・Space でハンクを選び、X で反映してください。」が出たら、ハンクを選んで `X` を押す
   - 開いた後に対象の index・作業ファイルが変わった場合は中断する。閉じて `E` から開き直す
   - 目次・相互参照・文書内リンクの参照先が無くなると表示されたら、参照先の段落の変更も選ぶ

#### lazygit で 2 つの Word の変更を取り込む

- 2 つの文書を比べ、取り込み元の段落・表・書式などの変更を選んで取り込み先へ書き込む
- 前提: [excel-diff を導入・更新する](#excel-diff-を導入更新する)・[lazygit](#lazygit)・[git-delta](#git-delta)を通してある（lazygit 0.66.0 以上・delta 0.20.1 以上）
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ。Git リポジトリの外でも使える
- 書き換えるのは最初に指定する取り込み先で、`.bak` は作らない。取り込み先を Word などで開いていたら閉じておく
- 対象は両方とも Transitional の OOXML の `.docx` / `.docm` / `.dotx` / `.dotm`。暗号化・`.doc`・Strict・電子署名付きの文書は取り込まない。対応条件と制限は[excel-diff の Word の注意点](https://github.com/ryo-aoki-pc/excel-diff/blob/main/docs/extra/readme.md#word-の注意点)を確認する

1. 変数を設定する（`WORD_TARGET`・`WORD_SOURCE` は必ず値を入れる）。

   ```bash
   WORD_TARGET=''                       # ← 取り込み先（書き換える文書。例: 仕様書.docx）の絶対パス
   ```

   ```bash
   WORD_SOURCE=''                       # ← 取り込み元の文書（例: 仕様書-更新.docx）の絶対パス
   ```

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'WORD_TARGET = %s\nWORD_SOURCE = %s\n' "$WORD_TARGET" "$WORD_SOURCE"
   ```

   - 取り込み先と取り込み元の絶対パスを読み戻して確かめる
   - 新しい端末を開いたら、この項の手順 1 を貼り直してから先へ進む

1. 2 つの文書を比べる専用画面を開く。

   ```bash
   # 取り込み先と取り込み元を指定して文書を開く
   if [ -z "$WORD_TARGET" ] || [ -z "$WORD_SOURCE" ]; then
     echo '中断: この項の手順 1 の WORD_TARGET または WORD_SOURCE が空のまま' >&2
   else
     printf '\n\033[7m 確認 \033[0m\n'
     git word-merge -- "$WORD_TARGET" "$WORD_SOURCE"
   fi
   ```

   - 「書き換えるファイル: …」「取り込み元: …」が指定したパスであることを確かめる
   - 「Word を読み込んでいます。大きい文書では画面が開くまで時間がかかります。」が出たら、画面が開くまで待つ
   - 「差分がありません。取り込み先は変えていません。」または「取り込める差分がありません（取り込めない違い N か所）。取り込み先は変えていません。」が出たら、この項の手順 3 は飛ばす
   - 「取り込めない違い（N か所）: …」が出たら、一覧の違いは選べない。コメント、脚注・文末脚注の参照、グラフ・図形などの違いがあるなら、その表示を確かめる
   - 「Word の取り込みに失敗しました: …」が出たら、理由を確かめてからやり直す
   - **次の手順は、専用画面で行う**

1. 専用画面でハンクを選び、取り込み先へ書き込んで閉じる。

   - `Enter` → `Space` を押してハンクを選び、左右の矢印で移動して選択を確かめる。置換は削除・追加の両方を選ぶ
   - 目次や、行を足した表など、`"2/1"` のように番号に `/` が付く行のまとまりは、まとまりの変更行をすべて選ぶ
   - `X` で書き込み、「N か所の変更を取り込み先へ書き込みました。q で元の画面へ戻ってください。」が出たら `q` で閉じる
   - 目次などを選ぶと「目次などの参照先に合わせて、表示が同じ N か所を取り込み元のものにしました。」も出ることがある。表示が同じ段落を取り込み元のものにしただけで、文字は変わらない
   - `X` の前に `q` で閉じれば選択を取り消し、「取り込む変更が選ばれていません。取り込み先は変えていません。」が出る
   - 「変更が選択されていません。Enter・Space でハンクを選び、X で反映してください。」が出たら、ハンクを選んで `X` を押す
   - 「このまとまりの変更行をすべて選んでください。」で止まったら、そのまとまりの変更行をすべて選んで `X` を押し直す
   - 取り込み先を LibreOffice などで開いたために書き込めなければ、閉じて `X` を押し直す
   - 専用画面を閉じると、端末に「N か所の変更を取り込み先へ書き込みました: …」が出ればよい

<details id="excel-diff-の補足と注意点">
  <summary>excel-diff の補足と注意点</summary>

**[excel-diff を導入・更新する](#excel-diff-を導入更新する)の手順 2**

- Git 全体の textconv・alias・属性を設定し、依存はリポジトリ外の仮想環境へ入れる

- `--check` は読み取りだけの確認

- 終わると元の作業ディレクトリへ戻る

**[excel-diff を導入・更新する](#excel-diff-を導入更新する)の手順 2: スクリプトを更新した後に導入し直す理由**

- Excel の変換スクリプトの写しは、中身などから決まる名前で Git の設定に書かれる。`scripts/excel-textconv.py` を変える更新を取り込むと、前の設定では確認が失敗する
- [excel-diff を導入・更新する](#excel-diff-を導入更新する)の手順 2 の導入・確認を通し直すと、新しい変換スクリプトの名前で設定される

**[lazygit で Excel の差分を確かめる](#lazygit-で-excel-の差分を確かめる)の手順 1**

- 表示する内容は[Excel 差分の仕様](https://github.com/ryo-aoki-pc/excel-diff/blob/main/docs/reference/readme.md#表示する内容)、属性の優先順位と制限は[注意点](https://github.com/ryo-aoki-pc/excel-diff/blob/main/docs/extra/readme.md#注意点)を参照する

- Git の `core.quotePath` が既定の `true` なら、日本語のファイル名は `"\345\243\262\344\270\212\350\241\250.xlsx": diff: excel` のように引用符と 8 進数で出る（同じファイル）

**[lazygit で大きな Excel の変換を待つ](#lazygit-で大きな-excel-の変換を待つ)の手順 1**

- この環境変数は、このコマンドにだけ適用する

**[lazygit で 2 つの Excel のセルの変更を取り込む](#lazygit-で-2-つの-excel-のセルの変更を取り込む)の手順 2**

- 端末に「書き換えるファイル: …」「取り込み元: …」が出て、専用画面が開く

**[lazygit で Word の差分を確かめる](#lazygit-で-word-の差分を確かめる)の手順 1**

- 表示する内容は[Word の表示の仕様](https://github.com/ryo-aoki-pc/excel-diff/blob/main/docs/reference/readme.md#word-の表示)、属性の優先順位は[注意点](https://github.com/ryo-aoki-pc/excel-diff/blob/main/docs/extra/readme.md#注意点)、Word の制限は[Word の注意点](https://github.com/ryo-aoki-pc/excel-diff/blob/main/docs/extra/readme.md#word-の注意点)を参照する

- Git の `core.quotePath` が既定の `true` なら、日本語のファイル名は `"\344\273\225\346\247\230\346\233\270.docx": diff: word` のように引用符と 8 進数で出る（同じファイル）

**[lazygit で 2 つの Word の変更を取り込む](#lazygit-で-2-つの-word-の変更を取り込む)の手順 2**

- 端末に「書き換えるファイル: …」「取り込み元: …」が出て、専用画面が開く

**参照**

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

---

### yazi

- 端末のファイルマネージャーの yazi と、プレビュー・検索に使うツールを Homebrew で入れ、自分用の設定を入れて `y` で起動する
- 前提: [共通の bash 設定](shell-terminal.md#共通の-bash-設定)・[Homebrew](#homebrew)・[WezTerm](shell-terminal.md#wezterm)を通し、PATH に Homebrew が入った端末（[シェルのツール](shell-terminal.md#シェルのツール)の手順 2 で開き直した端末）を開いてある
  - この項の手順 3 は、[yazi の設定を導入する](#yazi-の設定を導入する)の前提も要る
- 実行場所: WezTerm のタブ（前提の、PATH に Homebrew が入った端末。GNOME にログインした自分のユーザーの bash）。この項の手順 4 で新しいタブを開く

1. 変数を設定する。

   ```bash
   YAZI_EXTRAS="ffmpeg-full sevenzip jq poppler fd ripgrep fzf resvg imagemagick-full font-symbols-only-nerd-font"   # プレビューと検索に使う。空にすると yazi 本体だけ
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'YAZI_EXTRAS = %s\n' "${YAZI_EXTRAS}"
   ```

   - **編集が必須の変数は無い**
   - 最小構成にするなら、`YAZI_EXTRAS` を空にする
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこの項の手順 1 を貼り直す

1. brew で yazi と、プレビュー・検索に使うツールを入れる。

   ```bash
   brew install yazi ${YAZI_EXTRAS}
   ```

   - fd・ripgrep（[LazyVim の設定を導入する](neovim.md#lazyvim-の設定を導入する)の手順 4）と fzf（[シェルのツール](shell-terminal.md#シェルのツール)の手順 1）を入れてあれば、`Warning: fd … is already installed and up-to-date.` のように出る
   - 数分から 10 分ほどかかる。入れ終わるまで待つ
   - **次の手順は、確認が出たら表示された導入予定を確かめて `y` と答え、プロンプトに戻ってから貼る**（続けて進むと、導入を断ったときや失敗したときも、設定の clone へ進む。[Homebrew の補足と注意点](#homebrew-の補足と注意点)の「注意点」）

1. 自分用の設定（[ryo-aoki-pc/yazi](https://github.com/ryo-aoki-pc/yazi)）を入れる。

   - [yazi の設定を導入する](#yazi-の設定を導入する)の全項を通す
   - ファイルを開くエディタは nvim（[Neovim](neovim.md#neovim)）、`z` と `Z` のキーは fzf と zoxide（[シェルのツール](shell-terminal.md#シェルのツール)の手順 1）を使う

1. WezTerm で新しいタブを開き、y 関数を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   type -t y
   ```

   - `function` が出ればよい
   - **`. ~/.bashrc` で読み直さず、新しいタブで `y` を確かめる**（[シェルのツール](shell-terminal.md#シェルのツール)の手順 2）

1. 同じタブで、yazi が入ったか確かめ、`y` で起動する。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # yazi と ya の版を確かめる
   yazi --version
   ya --version
   brew list --versions yazi
   # yazi を起動する
   y
   ```

   - yazi の版と `Triple:` が出ればよい
   - プレビューを確かめるには、PDF・動画・画像・書庫のあるディレクトリで右ペインを見る
   - 画面が出たら `q` で終了する
   - **ほかのコマンドは、`q` で終了してから貼る**（yazi を開いたまま貼ると、yazi への入力になる）

#### yazi の設定ファイル

- 置き場所は `~/.config/yazi/` で、ファイル名は `yazi.toml`（全般）/ `keymap.toml`（キー割り当て）/ `theme.toml`（配色）

#### yazi の設定を導入する

- 自分用の yazi の設定（[ryo-aoki-pc/yazi](https://github.com/ryo-aoki-pc/yazi) の `custom` ブランチ）を `~/.config/yazi` に clone する
- 前提: [yazi](#yazi)の手順 1・2 で yazi と依存ツールを入れてある。ファイルを開くエディタに nvim（[Neovim](neovim.md#neovim)）、`z` と `Z` のキーに fzf と zoxide（[シェルのツール](shell-terminal.md#シェルのツール)の手順 1）を使う
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ。既存の `~/.config/yazi` の確認と退避を省かない

1. yazi を終了し、自分用の設定を clone する。

   ```bash
   git clone -b custom https://github.com/ryo-aoki-pc/yazi.git ~/.config/yazi
   ```

   - 既存ディレクトリがあれば clone は中断する。内容を確認して退避してから貼り直す
   - `ya env` の Config で読み込む場所を確かめる

#### yazi で複数ファイルをまとめて開く

- yazi で選んだ複数のファイルを、`l` / `<Enter>` でまとめて開けるようにする
- 前提: [yazi の設定を導入する](#yazi-の設定を導入する)を通してある
- 実行場所: 自分のユーザーがエディタで開いた `~/.config/yazi/init.lua`（`sudo` は使わない）。追記の前に、今の中身の確認を省かない

1. 選択した複数ファイルをまとめて開くため、`init.lua` に追記する。

   ```lua
   require("smart-enter"):setup { open_multi = true }
   ```

   - `l` / `<Enter>` で選択した複数ファイルを開ければよい

#### yazi の設定を更新する

- 自分用の yazi の設定の clone を GitHub の `custom` に合わせる。持ち主が上流の新しい版に合わせて `custom` を載せ替えた（force push した）後も、この項で合わせる
- 前提: [yazi の設定を導入する](#yazi-の設定を導入する)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ。この項の手順 1 の手元の変更の確認を省かない
- yazi 本体は[共通の bash 設定・Homebrew・Flatpak を上げる](#共通の-bash-設定homebrewflatpak-を上げる)の手順 2・3 で上げる

> [!WARNING]
> - この項の手順 3 では、この clone でコミットしたものは新しい `custom` に載らない（前の位置は `git -C ~/.config/yazi reflog` で見られる）。
>
> - **この項の手順 4 は、ぶつからなかったファイルの分も含め、手元の変更を作業ツリーから消す**。変更は stash にだけ残る

1. 手元の変更を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   git -C ~/.config/yazi status --short --branch
   ```

   - 1 行目が `## custom...origin/custom` で始まればよい（`[ahead …, behind …]` が続いてもよい）
   - 2 行目から出る行（` M init.lua` など）は手元の変更。この項の手順 2 で残したまま合わせる
   - 1 行目が `## HEAD (no branch)` で、前にこの項の手順 2 を貼って止まったままなら、この項の手順 2 は飛ばし、手順 3 から貼る
   - そのほかに、1 行目が `## custom` で始まらなければ、中断する

1. GitHub の `custom` に合わせる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   git -C ~/.config/yazi pull --rebase --autostash
   git -C ~/.config/yazi status --short --branch
   ```

   - `Successfully rebased and updated refs/heads/custom.`・`Fast-forward`・`Already up to date.` のどれかが出て、`status` の 1 行目が `## custom...origin/custom`（`[ahead`・`[behind` が付かない）で、2 行目から `UU` の行が無ければよい
   - 手元の変更を退避して戻したときは、`Created autostash:`・`Applied autostash.` が出て、`status` の 2 行目から同じ形で残る
   - 1 行目が `## HEAD (no branch)` なら（`Could not apply` と出て止まった。`UU` の行も出る）、この項の手順 3 を貼る。手順 4 へ進むかは、手順 3 の `status` で決める
   - 1 行目が `## HEAD (no branch)` でなければ、この項の手順 3 は飛ばす
   - 1 行目が `## custom...origin/custom` で始まり、2 行目から `UU` で始まる行があれば（`resulted in conflicts` と出た）、この項の手順 4 を貼る。無ければ、この項の手順 4 は飛ばす
   - 書き換わった `custom` を取り込んだときは、`(forced update)` の行が出る

1. この項の手順 2 の `status` の 1 行目が `## HEAD (no branch)` のときだけ、手元の変更を残して rebase を取り消し、新しい `custom` に移る。

   ```bash
   # 競合中の rebase を中止する
   git -C ~/.config/yazi rebase --abort
   printf '\n\033[7m 確認 \033[0m\n'
   git -C ~/.config/yazi rebase --autostash --onto origin/custom HEAD
   git -C ~/.config/yazi status --short --branch
   ```

   - `Successfully rebased and updated refs/heads/custom.` と出て、`status` の 1 行目が `## custom...origin/custom`（`[ahead`・`[behind` が付かない）で、2 行目から `UU` の行が無ければよい
   - 手元の未コミットの変更は残る
   - 2 行目から `UU` で始まる行があれば、この項の手順 4 を貼る。無ければ、この項の手順 4 は飛ばす

1. この項の手順 2・3 の `status` が `## custom` で始まり `UU` の行を出したときだけ、作業ツリーを新しい設定に戻す。

   ```bash
   # 作業ツリーの変更を破棄する
   git -C ~/.config/yazi reset -q --hard
   printf '\n\033[7m 確認 \033[0m\n'
   # 作業ツリーの状態を確かめる
   git -C ~/.config/yazi status --short --branch
   # 退避した変更の内容を確かめる
   git --no-pager -C ~/.config/yazi stash show -p
   ```

   - `status` が `## custom...origin/custom` の 1 行だけになり、その後ろに手元の変更の差分が出ればよい
   - `init.lua` の `open_multi` の行は、[yazi で複数ファイルをまとめて開く](#yazi-で複数ファイルをまとめて開く)を通し直して足す。新しい `init.lua` に同じ行が既にあれば、足さない
   - ほかの変更は、要るものをエディタで書き直す
   - 書き直したら、`git -C ~/.config/yazi stash drop` で stash を消す

1. 設定の元にした上流の版と、入っている本体の版を比べる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # 設定のリリースタグを確かめる
   git -C ~/.config/yazi describe --tags --abbrev=0
   # yazi 本体の版を確かめる
   yazi --version
   ```

   - 設定の元にした上流のタグの版と、`Version:` の版が同じならよい
   - 本体の方が古ければ、[共通の bash 設定・Homebrew・Flatpak を上げる](#共通の-bash-設定homebrewflatpak-を上げる)の手順 2・3 で上げる

<details id="yazi-の補足と注意点">
  <summary>yazi の補足と注意点</summary>

**注意点**

- **yazi も、Homebrew の注意のとおり**: PATH の先頭が Homebrew になる（同名のコマンドは RPM 版より Homebrew 版が勝つ）、`sudo yazi` はそのままでは使えない（root で使うなら、[Homebrew を sudo でも使う](#homebrew-を-sudo-でも使う)の節を通すか、フルパスで呼ぶ）、など
  - RPM 版と両方入れると分かりにくくなるので、どちらか一方にする

- **yazi: 画像プレビューは端末に依存する**: Kitty / WezTerm / foot などのグラフィックプロトコル、または Überzug++ が要る。GNOME 端末では文字ベースの表示になる

- **yazi: `q` と `Q`**: `y` 関数経由なら `q` で終了時にそのディレクトリへ移動し、`Q` なら移動しない

- **yazi: Homebrew の更新は自分の責任で**: `brew upgrade` は指定しなければ全 formula を上げる。yazi だけ上げるなら `brew upgrade yazi`

**[yazi](#yazi)の手順 1**

- 最後の行で値を読み戻して確かめる

**[yazi](#yazi)の手順 1: 変数について**

- `YAZI_EXTRAS` に並べているのは、yazi が外部コマンドとして呼ぶツール。依存ツールは、この折りたたみの「参照」の Installation — Yazi に挙げている
- `ffmpeg-full` と `imagemagick-full` は、Homebrew の `ffmpeg` / `imagemagick` に対してコーデック・フォーマットを広く有効にしたビルド（どちらも `homebrew/core` の formula）
- 既定は、プレビュー・検索用のツールを一緒に入れる想定になっている

**[yazi](#yazi)の手順 2**

- 依存を合わせて 170 個ほどが入り、数分から 10 分ほどかかる

**[yazi](#yazi)の手順 2: 一緒に入る python3 と curl**

- 既定の `YAZI_EXTRAS` では、依存として Homebrew の `python3`（2026-10-11 は `python@3.15`）と `curl` も入る
- 共通の bash 設定が Homebrew のディレクトリを PATH の先頭に置くので、端末では、どちらも `/usr/bin` のものより先に見つかるようになる（2026-10-11 の 3 つの VM で、この後の `command -v curl` は `/home/linuxbrew/.linuxbrew/bin/curl` を返した）
- 日本語入力（IBus）を OS の `python3` で動かす設定は、[Homebrew](#homebrew)の手順 3

**[yazi](#yazi)の手順 2: ボトルと、依存ツールの役割**

検証記録（`docs/verification/almalinux-setup.md` の「yazi: 実施手順 / 手順 2: 補足: ボトルと、依存ツールの役割」）

- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない

**[yazi](#yazi)の手順 4**

- `function` が出ればよい。`~/.bashrc` への関数の追記は不要

**[yazi](#yazi)の手順 4: y 関数**

- `y` は yazi を閉じたディレクトリへ移る。空白や日本語を含むパスも扱い、同じ場所なら移動し直さない

**[yazi](#yazi)の手順 5**

- 画像プレビューは端末側の対応が要る（この折りたたみの「注意点」）

- `Version: 26.9.1 (Homebrew ...)`、`Triple: aarch64-unknown-linux-gnu` のように出る

**[yazi](#yazi)の手順 5: ya と y**

- `ya` は付属のプラグイン管理コマンド
- ブロックの最後の `y` で起動して確認する
- `y` で起動したときは、終了時にそのディレクトリへ移動する

**[yazi の設定ファイル](#yazi-の設定ファイル)のリード**

- パッケージは設定ファイルを置かない。無ければ組み込みの既定値で動く

- Windows 11 の置き場所は `%APPDATA%\yazi\config\`（Windows の yazi は `XDG_CONFIG_HOME` を見ない。別の場所にするなら `YAZI_CONFIG_HOME` に絶対パスを入れる）
  - 状態は `%APPDATA%\yazi\state`、キャッシュは `%LOCALAPPDATA%\yazi`
  - yazi が読む場所は `ya env` の `Config` の行で確かめられる（[yazi](windows-setup.md#yazi)の手順 7）
- **既定値のファイルは配布物に入っていない**。変更する項目だけを設定ファイルに書く
- 既定値は[公式ドキュメントの Configuration](https://yazi-rs.github.io/docs/configuration/overview/) か、リポジトリの `yazi-config/preset/` を見る
- **自分用の設定**は [ryo-aoki-pc/yazi](https://github.com/ryo-aoki-pc/yazi) にある（上流の既定の設定を丸ごと置き、3 ペインの比率・行表示・独自のキー割り当てなどを変えた設定）
  - 導入は[yazi](#yazi)の手順 3。`custom` を `~/.config/yazi` に clone する
  - 更新は[yazi の設定を更新する](#yazi-の設定を更新する)（[yazi の設定を更新する](windows-setup.md#yazi-の設定を更新する)）で行う
  - Windows 11 は[yazi](windows-setup.md#yazi)の手順 6。`custom` を `%APPDATA%\yazi\config` に clone する
  - キーは[独自キーバインド](https://github.com/ryo-aoki-pc/yazi/blob/custom/docs/reference/readme.md#独自キーバインド抜粋)、外部コマンドは[依存コマンド](https://github.com/ryo-aoki-pc/yazi#依存コマンド)を参照する
  - fd・ripgrep・fzf は[yazi](#yazi)の手順 2、nvim は[Neovim](neovim.md#neovim)、zoxide と fzf のキー操作は[シェルのツール](shell-terminal.md#シェルのツール)で入れる
    - Windows 11 の Git Bash の fzf のキー操作と zoxide は、[シェルのツールを入れる](shell-terminal.md#シェルのツールを入れる)で入る（zoxide は 0.9.9 に止める）
  - Windows 11 では、`O`（対話的に開く）の候補に Neovide も出る。選んで使うなら、Neovide（scoop の extras の `neovide`）を入れておく

**[yazi の設定を導入する](#yazi-の設定を導入する)の手順 1**

- `custom` ブランチを使う。導入先は `~/.config/yazi`

**[yazi で複数ファイルをまとめて開く](#yazi-で複数ファイルをまとめて開く)の手順 1**

- `l` / `<Enter>` で選択した複数ファイルを開く。追記前はホバー中の 1 ファイルだけを開く

**[yazi の設定を更新する](#yazi-の設定を更新する)の手順 2**


- `[ahead 1]` などが残ったら、この clone でコミットしたものが新しい `custom` の上に載っている

**[yazi の設定を更新する](#yazi-の設定を更新する)の手順 2: force push と分岐点**

- `--ff-only` を使わない理由、fork point と reflog、`--rebase --autostash` を明示する理由は、[lazygit の補足と注意点](#lazygit-の補足と注意点)の「lazygit の設定を更新するの手順 2: force push と分岐点」と同じ
- pull は新しい上流のタグも取得する。設定の元にした上流の版は、[yazi の設定を更新する](#yazi-の設定を更新する)の手順 5 の `describe --tags --abbrev=0` で確かめる

**[yazi の設定を更新する](#yazi-の設定を更新する)の手順 3: 分岐点が分からないときの載せ直し**

- rebase が止まる条件と、`--onto origin/custom HEAD` でこの clone だけのコミットを載せない理由は、[lazygit の補足と注意点](#lazygit-の補足と注意点)の「lazygit の設定を更新するの手順 3: 分岐点が分からないときの載せ直し」と同じ

**[yazi の設定を更新する](#yazi-の設定を更新する)の手順 4: autostash の衝突と reset の範囲**

- git 2.52.0 の文言、衝突しても終了コードが 0 になること、`UU` の行で判定する理由と、一律に `reset --hard origin/custom` を使わない理由は、[lazygit の補足と注意点](#lazygit-の補足と注意点)の「lazygit の設定を更新するの手順 4: autostash の衝突と reset の範囲」と同じ

**[yazi の設定を更新する](#yazi-の設定を更新する)の手順 5**

- `upstream/v26.9.1` の版と、その後ろの `Version: 26.9.1` が同じならよい

**参照**

- [Installation — Yazi](https://yazi-rs.github.io/docs/installation/) — 経路一覧と依存ツール（ffmpeg / 7-Zip / jq / poppler / fd / ripgrep / fzf / zoxide / ImageMagick）
- [Quick Start — Yazi](https://yazi-rs.github.io/docs/quick-start/) — `y` シェル関数（`--cwd-file`）の原典
- [Configuration — Yazi](https://yazi-rs.github.io/docs/configuration/overview/) — `yazi.toml` / `keymap.toml` / `theme.toml`
- [ryo-aoki-pc/yazi](https://github.com/ryo-aoki-pc/yazi) — 自分用の設定。入れ方・独自のキー・上流との差分の管理は README にある
- [Homebrew](#homebrew)の手順 1〜2 — Homebrew 本体の導入手順。`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件は[Homebrew の補足と注意点](#homebrew-の補足と注意点)の「注意点」、`brew` の基本操作は[Homebrew の使い方の基本](#homebrew-の使い方の基本)
- [Installation — Yazi の Windows](https://yazi-rs.github.io/docs/installation/#windows) — scoop の経路と依存、`YAZI_FILE_ONE`（Git for Windows の `file.exe`）
- [Image Preview — Yazi](https://yazi-rs.github.io/docs/image-preview/) — Windows で画像を出せる端末（WezTerm の nightly、Windows Terminal 1.22.10352.0 以降）と ConPTY の制約
- [ScoopInstaller/Main — yazi.json](https://github.com/ScoopInstaller/Main/blob/master/bucket/yazi.json) — Windows 11 の scoop の定義
- [sxyazi/yazi — yazi-fs/src/xdg.rs（v26.9.1）](https://github.com/sxyazi/yazi/blob/v26.9.1/yazi-fs/src/xdg.rs) — Windows の設定・状態・キャッシュの場所
- [sxyazi/yazi — yazi-cli/src/env/env.rs（v26.9.1）](https://github.com/sxyazi/yazi/blob/v26.9.1/yazi-cli/src/env/env.rs) — `ya env` の出力
- [sxyazi/yazi — yazi-config/preset/yazi-default.toml（v26.9.1）](https://github.com/sxyazi/yazi/blob/v26.9.1/yazi-config/preset/yazi-default.toml) — 上流の既定の `[opener]`（Windows の `edit` は `code`）
- [sxyazi/yazi — yazi-plugin/preset/plugins/mime-local.lua（v26.9.1）](https://github.com/sxyazi/yazi/blob/v26.9.1/yazi-plugin/preset/plugins/mime-local.lua)・[yazi-binding/src/process/command.rs（v26.9.1）](https://github.com/sxyazi/yazi/blob/v26.9.1/yazi-binding/src/process/command.rs) — `YAZI_FILE_ONE` の起動（シェルを挟まない）

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

---

### mdtable

- GLFM の Markdown の表を、Excel のブックにして編集し、Markdown へ戻す（[md-table-excel](https://github.com/ryo-aoki-pc/md-table-excel)）

#### mdtable を導入・更新する

- `mdtable` を `~/md-table-excel` に clone し、専用の仮想環境に入れて確かめる。更新も、この項の手順 1 で行う
- 前提: Python 3.9 以上と git が入っている（git は[Homebrew](#homebrew)の手順 1 で入る）
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）。`sudo` は、ensurepip で止まったときの `python3-pip` の導入だけで使う。更新では、`~/md-table-excel` の手元の変更の確認を省かない

1. リポジトリを clone し、導入して確かめる。

   ```bash
   # md-table-excel のソースを取得する
   git clone https://github.com/ryo-aoki-pc/md-table-excel.git ~/md-table-excel
   # コマンドを導入して設定を検査する
   (
     cd ~/md-table-excel &&
       python3 scripts/setup-mdtable.py &&
       python3 scripts/setup-mdtable.py --check
   )
   ```

   - ensurepip で止まったら `sudo dnf install python3-pip` を行う
   - `~/.local/bin` が PATH に無いときは、案内に従って加える
   - 更新時は `git -C ~/md-table-excel pull --ff-only` し、この手順の `(`〜`)` の導入・確認を再実行する

#### mdtable のブックを Excel で編集するときの注意

- セルは文字列の書式（`@`）になっている。書式をクリアしたセルや、別のブック・Web から「すべて貼り付け」したセルでは、Excel が入力を数値や日付に変えることがある（`1/2` → 日付、`3.10` → 3.1 など）。日付になったセルがあると取り込みは止まる
- 貼り付けは「値のみ」か、セルの編集中（F2・数式バー）に行う
- オートコレクト（`(c)` → `©` など）は入力を変える。コードを書くなら Excel の [ファイル] → [オプション] で切る
- 見出し行の直下に行を挿入すると、見出しの書式が写る（HTML の表では `<th>` になる）。[挿入オプション] で「下と同じ書式を適用」を選ぶ
- [セルを結合して中央揃え] は中央揃えも付く。結合だけなら [セルを結合]
- 「テーブルとして書式設定」（Ctrl+T）は使わない
- セルの一部だけの書式（文字の色・斜体など）は書き戻さない。強調は `**` などで書く
- シート名の変更・並べ替えはよい。シートを消した表は変更なしとして扱う。足したシートは読まない
- 表から離れたセルに書いた値は無視する（警告を出す）
- フォントは、書き出す PC に HackGen Console NF が入っていればそれ、無ければ BIZ UDゴシック（`\` が `¥` に見える）。環境変数 `MDTABLE_FONT` にフォント名を入れると、そのフォントにする

#### mdtable で Markdown の表を Excel と往復する

- Markdown の表を Excel のブックに書き出し、Excel で編集したブックの変更を Markdown に書き戻す
- 前提: [mdtable を導入・更新する](#mdtable-を導入更新する)を通し、`mdtable` が PATH にある。ブックの編集には、Excel のある端末を使う
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）の、編集する文書のあるディレクトリ。ブックの編集は、Excel のある端末
- `README.md` と `README.tables.xlsx` は、対象の文書名とブック名に置き換える

> [!CAUTION]
> この項の手順 1 の後で Excel を編集する前に、[mdtable のブックを Excel で編集するときの注意](#mdtable-のブックを-excel-で編集するときの注意)を必ず読む。日付化・小数の桁落ちなどで、元の文字列を失うことがある。

1. Markdown の表を Excel ブックへ書き出す。

   ```bash
   mdtable export README.md
   ```

   - 同じフォルダーに `README.tables.xlsx` ができる。保存先は `-o` で変えられる
   - 既存のブックは `--force` が無ければ上書きしない
   - **次の手順は、Excel のある端末でブックを編集し、元のフォルダーへ戻してから貼る**

1. 取り込む差分を確かめる。

   ```bash
   mdtable import README.tables.xlsx --dry-run
   ```

   - 差分だけが表示され、Markdown は変わらない
   - **次の手順は、差分の内容を確かめてから貼る**

1. ブックの変更を Markdown に書き戻す。

   ```bash
   mdtable import README.tables.xlsx
   ```

   - ブックに記録した Markdown に書き戻す
   - 書き出し後に Markdown の表を変えていたら、衝突として書き戻さない。**`--force` はブックの内容で上書きする**
   - 取り込み済みのブックは「適用済み」になる。取り込み後のブックは消してよい

<details id="mdtable-の補足と注意点">
  <summary>mdtable の補足と注意点</summary>

**[mdtable を導入・更新する](#mdtable-を導入更新する)の手順 1**

- 依存はリポジトリ外の専用仮想環境へ入る

- `--check` は何も変更せず状態を確かめる

- 起動コマンドは `~/.local/bin`。PATH に無いときは案内に従って加える

**[mdtable で Markdown の表を Excel と往復する](#mdtable-で-markdown-の表を-excel-と往復する)の手順 3**


- ブックに記録した Markdown に書き戻す。書き戻す先は `--md` で変えられる

**参照**

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

---

### md-format

- GFM と GLFM の Markdown を、描画を変えずに整形する `mdfmt` コマンド（[md-format](https://github.com/ryo-aoki-pc/md-format)）。Neovim（LazyVim）の保存のときの整形も、これを使う

#### md-format を導入・更新する

- md-format を `~/md-format` に clone し、リポジトリの外に依存を入れて、`mdfmt` コマンドを確かめる。更新も、この項の手順 2 で行う
- 前提: git が入っている（[Homebrew](#homebrew)の手順 1 で入る）
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）。`sudo` は、この項の手順 1 で Node.js が無いときだけ使う。更新では、`~/md-format` の手元の変更の確認を省かない

1. Node.js が無ければ dnf で入れ、版を確かめる。

   ```bash
   # Node.js と npm を導入する
   command -v node >/dev/null || sudo dnf install -y nodejs nodejs-npm
   printf '\n\033[7m 確認 \033[0m\n'
   node --version
   ```

   - `v22.` 以上の版が出ればよい
   - 22 より古い版が出たら、その Node.js を更新してから貼り直す

1. リポジトリを clone し、導入して確かめる。

   ```bash
   # md-format のソースを取得する
   git clone https://github.com/ryo-aoki-pc/md-format.git ~/md-format
   # コマンドを導入して設定を検査する
   (
     cd ~/md-format &&
       node scripts/setup.mjs &&
       node scripts/setup.mjs --check
   )
   ```

   - 最後に `導入済み: mdfmt` と版、起動コマンドのパスが出ればよい
   - `問題:` で始まる行が出たら、その案内に従って直してから `(`〜`)` を貼り直す（`~/.local/bin` が PATH に無いときは、PATH に加えてから端末を開き直す）
   - 更新時は `git -C ~/md-format pull --ff-only` し、この手順の `(`〜`)` の導入・確認を再実行する
   - `ほかの導入が動いています` で止まったら、表示のプロセスが終わるのを待って、`(`〜`)` を貼り直す
   - 古い整形器の依存が残っていると、`注意:` に `~/.local/share/nvim/glfm-format` が出る。LazyVim の設定を md-format を使う版に揃えた後なら、`rm -rf ~/.local/share/nvim/glfm-format` で消してよい

#### mdfmt で Markdown を整形する

- 文書を整形し、整形の要るファイルを確かめる
- 前提: [md-format を導入・更新する](#md-format-を導入更新する)を通し、`mdfmt` が PATH にある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）の、整形する文書のあるディレクトリ
- 方言の既定は GLFM。GitHub 向けの文書のリポジトリでは、この項の手順 1 で GFM にする
- `docs` と `README.md` は、整形するフォルダーとファイルに置き換える

1. GitHub 向けの文書のリポジトリなら、そのリポジトリの直下で方言を GFM にする。

   ```bash
   printf '%s\n' '{ "flavor": "gfm" }' > .md-format.json
   ```

   - GitLab 向け（GLFM）の文書なら、この手順は行わない
   - 長い行を折りたいときは `{ "flavor": "gfm", "fixes": { "line_length": true } }` と書く（幅は markdownlint の MD013 の設定）

1. 整形の要るファイルを確かめる。

   ```bash
   mdfmt --check docs README.md
   ```

   - 整形の要るファイルの名前が出る。何も出なければ、整形は要らない
   - `mdfmt:` で始まる行は誤り。そのファイルは変えていない

1. 整形して書き換える。

   ```bash
   mdfmt --write docs README.md
   ```

   - 書き換えたファイルの名前が出る

<details id="md-format-の補足と注意点">
  <summary>md-format の補足と注意点</summary>

**[md-format を導入・更新する](#md-format-を導入更新する)の手順 2**

- 依存はリポジトリ外の `~/.local/share/md-format` へ入る

- 起動コマンド `mdfmt` は `~/.local/bin`

- `--check` は何も変更せず状態を確かめる

**[mdfmt で Markdown を整形する](#mdfmt-で-markdown-を整形する)の手順 3**

- フォルダーは、その下の `*.md` を扱う（`.git`・`node_modules`・`.` で始まるフォルダーは除く）

**参照**

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

---

### ShellCheck と shfmt

- シェルスクリプトの静的検査の ShellCheck と、整形の shfmt を Homebrew で入れ、検出できるか確かめる
- 前提: [Homebrew](#homebrew)を通し、PATH に Homebrew が入った端末（[シェルのツール](shell-terminal.md#シェルのツール)の手順 2 で開き直した端末）を開いてある。`command -v brew` で何も出なければ、先に通す
- 実行場所: 前提の端末（GNOME にログインした自分のユーザーの bash）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ

> [!IMPORTANT]
> - **自分のシェルで実行する**。Homebrew の導入・管理は一般ユーザーで行う

1. ShellCheck と shfmt を導入し、検査の動作を確認する。

   ```bash
   # シェルの検査と整形の道具を導入する
   brew install shellcheck shfmt
   printf '\n\033[7m 確認 \033[0m\n'
   # 版と実行ファイルの場所を確かめる
   shellcheck --version
   shfmt --version
   command -v shellcheck shfmt
   brew list --versions shellcheck shfmt
   # ShellCheck の指摘と終了コードを確かめる
   printf '#!/bin/bash\nx=$(ls)\necho $x\n' | shellcheck -
   echo "rc=$?"
   # shfmt の整形結果と終了コードを確かめる
   printf '#!/bin/bash\nif true; then\necho a\nfi\n' | shfmt -i 2 -d -
   echo "rc=$?"
   ```

   - Homebrew の確認が出たら答える
   - ShellCheck と shfmt の版が出ればよい
   - ShellCheck は `SC2086` の指摘が出て **`rc=1`** になればよい
   - shfmt は字下げを足す差分が出て `rc=1` になる

#### ShellCheck と shfmt: 更新

- Homebrew で入れた ShellCheck と shfmt を上げる
- 前提: [Homebrew](#homebrew)と[ShellCheck と shfmt](#shellcheck-と-shfmt)を通し、PATH に Homebrew が入った端末（[シェルのツール](shell-terminal.md#シェルのツール)の手順 2 で開き直した端末）を開いてある
- 実行場所: 前提の端末（GNOME にログインした自分のユーザーの bash）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ

1. ShellCheck と shfmt を上げる。

   ```bash
   brew upgrade shellcheck shfmt
   ```

   - すべてまとめて上げるなら `brew upgrade`
   - **ほかのコマンドは、Homebrew の確認が出たら答え、更新が終わってから貼る**（終わる前に貼ると、動いているコマンドへの入力になる）

<details id="shellcheck-と-shfmt-の補足と注意点">
  <summary>ShellCheck と shfmt の補足と注意点</summary>

**注意点**

- **EPEL 版と brew 版を両方入れない**: どちらもコマンド名は `shellcheck` で、PATH の先頭にある Homebrew 版が勝つ
  - EPEL のパッケージ名だけ大文字の `ShellCheck` なので、`rpm -q shellcheck` では見つからない
- **指摘があると `rc=1`**: CI に組むときはこれが期待どおりだが、`set -e` のスクリプトの途中で呼ぶと止まる
  - `|| true` は終了コードを成功に変える。CI の成否判定が必要なら付けない
- **`sudo shellcheck` は、そのままでは使えない**: sudo の PATH に Homebrew が無い（[Homebrew の補足と注意点](#homebrew-の補足と注意点)の「注意点」）。root で走らせるなら、[Homebrew を sudo でも使う](#homebrew-を-sudo-でも使う)の節を通すか、フルパスか EPEL 版

**[ShellCheck と shfmt](#shellcheck-と-shfmt)の手順 1**

- `version: 0.11.0` と `3.14.1` が出る

- ShellCheck は `SC2086 (info): Double quote to prevent globbing and word splitting.` が 1 件出て **`rc=1`** になる

**[ShellCheck と shfmt](#shellcheck-と-shfmt)の手順 1: ボトルと依存**

- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
- ShellCheck は `gmp` と `libffi` を要求する（Haskell 製のため）。shfmt に依存は無い

**[ShellCheck と shfmt](#shellcheck-と-shfmt)の手順 1: わざと欠陥のあるコードで確かめる**

- わざと欠陥のあるコードを標準入力に流して、本当に検出できることを確かめる（ファイルは作らない）。shfmt も同じように確かめる
- どちらも「指摘があれば `rc=1`」で、`rc=0` は「指摘なし」を意味する

**選択した方針**

- **ShellCheck**

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `arm64_linux` ボトルを使える | **採用** |
| EPEL | **パッケージ名は大文字の `ShellCheck`**（コマンドは小文字 `shellcheck`）。dnf 管理で root でも使える | 不採用。**`sudo shellcheck` を使いたい / dnf 管理に揃えたいならこちら**（`sudo dnf install ShellCheck`） |
| 公式のバイナリ配布 | GitHub Releases に `linux.aarch64` の tar.xz がある。展開して PATH に置くだけだが、更新は手作業 | 不採用（Homebrew に揃える） |
| `cabal install` / Docker イメージ | Haskell の toolchain か podman が要る | 不採用 |

- **shfmt**

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `arm64_linux` ボトルを使える | **採用** |
| GitHub Releases のバイナリ | `shfmt_v3.x.x_linux_arm64` を落として `chmod +x` するだけ。更新は手作業 | 不採用（Homebrew に揃える） |
| `go install mvdan.cc/sh/v3/cmd/shfmt@latest` | Go toolchain が要る | 不採用 |

**2 つとも Homebrew に揃える。** ShellCheck だけ EPEL にすると 1 つの文書に dnf 経路と Homebrew 経路が同居し、更新も `dnf upgrade` と `brew upgrade` の 2 本立てになる。

**参照**

検証記録（`docs/verification/shellcheck.md` の「補足の実測」）


- 検証記録（`docs/verification/shellcheck.md`）

</details>

---

### VS Code

- Microsoft の dnf のリポジトリから VS Code（rpm 版）を入れ、起動を確かめる
- 前提: [ログインと sudo](#ログインと-sudo)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ

> [!IMPORTANT]
> - **すべて対象ホスト上で実行する**。デスクトップが要るのは、この項の手順 5（GUI の起動）だけ
> - **この項の手順 5 は、デスクトップにログインした端末から実行する**。TTY やディスプレイが無いシェル（ssh や自動化）からは実行しない

1. 署名鍵を落として、取り込む前に fingerprint を見る。

   ```bash
   # Microsoft の公開鍵を取得して照合する
   curl -fsSL https://packages.microsoft.com/keys/microsoft.asc -o /tmp/microsoft.asc
   gpg --show-keys --with-fingerprint /tmp/microsoft.asc
   ```

   - 次の値と一致することを目で確かめる。違っていればここで止める
     - fingerprint `BC52 8686 B50D 79E3 39D3 721C EB3E 94AD BE12 29CF`
     - uid `Microsoft (Release signing) <gpgsecurity@microsoft.com>`
   - **次の手順は、一致したのを確かめてから貼る**

1. fingerprint が一致したら署名鍵を取り込み、確かめて鍵ファイルを消す。

   ```bash
   # Microsoft の公開鍵を登録して読み戻す
   sudo rpm --import /tmp/microsoft.asc
   rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i microsoft
   # 取得した公開鍵の一時ファイルを削除する
   rm -f /tmp/microsoft.asc
   ```

   - `gpg-pubkey-be1229cf-5631588c` と `Microsoft (Release signing)` が出ればよい

1. リポジトリを追加する。

   ```bash
   # VS Code のリポジトリ設定を書き込む
   sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
   [vscode]
   name=Visual Studio Code
   baseurl=https://packages.microsoft.com/yumrepos/vscode
   enabled=1
   gpgcheck=1
   gpgkey=https://packages.microsoft.com/keys/microsoft.asc
   EOF
   printf '\n\033[7m 確認 \033[0m\n'
   cat /etc/yum.repos.d/vscode.repo
   ```

1. VS Code を導入し、版と入手元を確認する。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # 導入予定のパッケージを表示して導入する
   sudo dnf install --assumeno code
   sudo dnf install code
   # VS Code の版と導入元を確かめる
   code --version
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' code
   rpm -qi code | sed -n '/^Vendor/p;/^Build Date/p'
   # 共有ライブラリーの依存関係を確かめる
   ldd /usr/share/code/code | grep -c 'not found'
   # アプリの起動ファイルを確かめる
   rpm -ql code | grep '/applications/.*\.desktop$'
   ```

   - 先に何が入るかだけ見る（`--assumeno` は必ず中断する）
   - 容量を確かめ、よければ続く `dnf install` の `[y/N]` に答える
   - バージョン / コミットハッシュ / アーキテクチャ（`x64` または `arm64`）の 3 行が出る
   - `from_repo` が `vscode`、`Vendor` が `Microsoft Corporation` になる
   - **`ldd` の `not found` が `0`** ならよい

1. デスクトップにログインした端末から、GUI を起動する。

   ```bash
   code
   ```

   - ウィンドウが出たことを確かめる
   - アプリ一覧の「Visual Studio Code」からでも同じ
   - **次の手順は、ウィンドウを閉じてから貼る**（起動したウィンドウを確認して閉じる操作を挟む）

1. 初回起動で設定のディレクトリができたか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # VS Code の設定フォルダーを確かめる
   ls -d ~/.config/Code ~/.vscode
   # 導入した拡張機能を一覧にする
   code --list-extensions
   ```

   - `~/.config/Code` があればよい
   - 拡張を入れていなければ、`code --list-extensions` は何も返さない

#### VS Code: 拡張機能を入れる

- VS Code の拡張機能を、CLI（`code`）で一覧し、入れ、消す
- 前提: [VS Code](#vs-code)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ
- Settings Sync・Remote-SSH・Marketplace の利用条件は扱わない

1. 入っている拡張機能を一覧する。

   ```bash
   code --list-extensions --show-versions
   ```

   - 入れるときは `code --install-extension <publisher.name>` の形で ID を渡す。たとえば [ShellCheck](#shellcheck-と-shfmt) をエディタから使うなら `timonwong.shellcheck`

#### VS Code: 更新

- VS Code を dnf で上げる。VS Code は、OS の通常の更新にも含まれる
- 前提: [VS Code](#vs-code)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ

1. VS Code を更新する。

   ```bash
   sudo dnf upgrade code
   ```

   - システム全体なら `sudo dnf upgrade`
   - **rpm 版では VS Code 内蔵のアップデータは使わない**

<details id="vs-code-の補足と注意点">
  <summary>VS Code の補足と注意点</summary>

**注意点**

- **`.el8` のタグに驚かなくてよい**: Microsoft が EL 共通に 1 本だけ出している rpm で、EL10 向けの別ビルドは存在しない。`rpm -qi` の `Vendor` が `Microsoft Corporation` であることを確かめれば十分（この折りたたみの「VS Code の手順 4: .el8 タグの rpm が EL10 で解決できる理由」）
- **`~/.config/code-flags.conf` は効かない**: Microsoft の rpm のラッパーは読まない
- 容量が不足する場合は、インストール前にトランザクション表と空き容量を確かめる
- **内蔵のアップデータは使わない**: rpm 版は dnf が管理する。VS Code が更新を促してきても `sudo dnf upgrade code` で上げる
- **`code-insiders` と併存できる**: コマンド名も設定ディレクトリ（`~/.config/Code - Insiders`）も別
- **Electron なので X11 のライブラリを要求する**: `libX11` / `libXcomposite` などが rpm の requires に並ぶ
  - これは XWayland 経由でも動くようにするためで、**ライブラリが入っていることは「X11 で動いている」ことを意味しない**
- **root では起動できない**: ラッパーが `--user-data-dir` の指定を要求する。そもそも root で使うものではない
- **TTY もディスプレイも無いシェルからは GUI を起動できなかった**: デスクトップの端末からは起動する
  - 原因は特定できていない

**[VS Code](#vs-code)の手順 2**

- `gpg-pubkey-be1229cf-5631588c Microsoft (Release signing) ...` が出れば入っている

**[VS Code](#vs-code)の手順 3: ヒアドキュメント**

- ヒアドキュメントは `<<'EOF'`（クォート付き）。この中に展開したい変数は無い

**[VS Code](#vs-code)の手順 4**

- `code ... 343 M` と `Installed size: 1.0 G` のように容量が出る。よければ、続く `dnf install` の `[y/N]` に答えて入れる

- **`ldd` の `not found` が `0`** なら、必要な共有ライブラリがすべて EL10 側で解決できている

**[VS Code](#vs-code)の手順 4: 弱い依存**

- 弱い依存として `socat` が一緒に入る

**[VS Code](#vs-code)の手順 4: .el8 タグの rpm が EL10 で解決できる理由**

入る rpm は `code-1.138.0-1789458729.el8.aarch64` で、release の末尾が **`.el8` に固定されている**。

- これは「EL8 用のビルドを EL10 に流用している」のではなく、**Microsoft が EL 共通の rpm を 1 本だけ出している**ためで、EL9 / EL10 向けの別ビルドは存在しない
- `baseurl` も `yumrepos/vscode` の 1 つだけで、ディストリ非依存になっている

根拠は依存の下限。aarch64 向けに要求される glibc のうち最も新しいものが **2.28**（EL8 の版）で、EL10 の 2.39 が余裕で満たす:

- つまり **EL8 を最低ラインにして EL8 / EL9 / EL10 を 1 本でカバーする**作りで、Microsoft の公式ドキュメントも RHEL / CentOS / Fedora のすべてでこの同じリポジトリを案内している
- [WezTerm](shell-terminal.md#wezterm) の「作者が EL9 向けに出した COPR ビルドを EL10 で使う」とは事情が違う
- dnf は release 文字列を比較するだけなので、`.el8` のままでも `dnf upgrade` は正しく効く

**[VS Code](#vs-code)の手順 5**


- ウィンドウが開き、初回は Welcome 画面と `Continue without Signing In` のボタンが表示される

**[VS Code](#vs-code)の手順 6**

- `~/.vscode` は、起動を試みた時点で `argv.json` だけ作られる

- 初回起動で `~/.config/Code` ができる

**[VS Code](#vs-code)の手順 6: 設定のディレクトリ**

- `~/.config/Code` は設定と履歴

**[VS Code: 更新](#vs-code-更新)の手順 1: 内蔵のアップデータを使わない理由**

- rpm 版で VS Code 内蔵のアップデータを使わないのは、dnf が管理しているため。[Firefox](#firefox)と同じ論点

**選択した方針**

検証記録（`docs/verification/vscode.md` の「選択した方針」）

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Microsoft 公式 dnf リポジトリ** | `packages.microsoft.com/yumrepos/vscode` に **aarch64 が 276 パッケージ**（`code` / `code-insiders` / `code-exploration`）。安定版は `code 1.138.0`。dnf で更新できる | **採用** |
| 公式サイトの `.rpm` を直接 `dnf install` | 同じバイナリだが、更新のたびに手で落とすことになる | 不採用 |
| Flathub `com.visualstudio.code` | リモートと runtime の導入が必要で、サンドボックスで PATH やツールチェインの見え方が変わる | 不採用（RPM で足りる） |
| Snap | EL10 に snapd を入れることになる | 不採用 |
| VSCodium / `code-oss` | Marketplace と一部の拡張（Remote-SSH など）が使えない | 対象外（本書は Microsoft のビルドを入れる） |
| `code-insiders` | 同じリポジトリの別パッケージ。コマンド名も設定ディレクトリ（`~/.config/Code - Insiders`）も別なので安定版と併存できる | 使うなら [VS Code](#vs-code)の手順 4 以降の `code` を `code-insiders` に読み替える |

**参照**

- [Visual Studio Code on Linux](https://code.visualstudio.com/docs/setup/linux) — 公式のインストール手順（RHEL / CentOS / Fedora の節がこのリポジトリを案内している）
- [packages.microsoft.com/yumrepos/vscode](https://packages.microsoft.com/yumrepos/vscode/) — リポジトリの中身
- [VS Code — Command Line Interface](https://code.visualstudio.com/docs/editor/command-line) — `--list-extensions` / `--install-extension` / `--user-data-dir`
- [Electron — Ozone platform](https://www.electronjs.org/docs/latest/api/environment-variables) — `ELECTRON_OZONE_PLATFORM_HINT`
- `code --help` / `rpm -q --scripts code` — CLI のオプションと rpm のスクリプトレット


- 検証記録（`docs/verification/vscode.md`）

</details>

---

### npm のオフライン導入

- インターネットに出られないホストで、SSH の SOCKS トンネルを通して AppStream の Node.js と npm を入れ、Neovim の Mason に npm のパッケージ（LSP サーバー・リンター）を入れる
- 前提: オンラインのホストから[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1〜3 でトンネルを張り、オフラインのホストへ接続してある
  - この項の手順 1 の前に、[SSH の SOCKS トンネル: dnf にもトンネルを使わせる](#ssh-の-socks-トンネル-dnf-にもトンネルを使わせる)も通してある
  - 同じトンネルで、[Homebrew のオフライン導入](#homebrew-のオフライン導入)と[Neovim](neovim.md#neovim)の手順 1 を通してある
  - この項の手順 1・2 で経路を設定してから、[LazyVim の設定を導入する](neovim.md#lazyvim-の設定を導入する)の手順 8 の初回起動を含む導入を行い、この項の手順 3 へ進む。Mason の npm パッケージは未導入でよい
- 実行場所: オフラインのホストの、`sudo` できる自分のユーザーのシェル（[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 3 のシェル）。この項の手順 4 でトンネルを閉じてログインし直し（オンラインのホストでも操作する）、この項の手順 5 はログインし直したシェルに貼る

> [!WARNING]
>
> - トンネルを張っている間は、オフラインのホストのどのユーザーも `127.0.0.1:1080` を通って外に出られる（[SSH の SOCKS トンネル の補足と注意点](#ssh-の-socks-トンネル-の補足と注意点)の「注意点」）

1. [SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 3 のシェルで、AppStream の Node.js と npm を入れる。

   ```bash
   sudo dnf install -y nodejs nodejs-npm
   ```

   - `nodejs`・`nodejs-npm` と不足する依存が入り、`Complete!`（日本語では `完了しました!`）で終わる。導入済みなら `Nothing to do.`（`行うべきことはありません。`）も出る
   - `Failed to download metadata for repo` で止まったら、dnf がトンネルを通っていない
     - `Curl error (6)`（名前を引けない）なら、[SSH の SOCKS トンネル: dnf にもトンネルを使わせる](#ssh-の-socks-トンネル-dnf-にもトンネルを使わせる)の設定が無い
     - `Curl error (7)`（`127.0.0.1 port 1080` につながらない）なら、トンネルが無い（[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 2 から張り直す）

1. Node.js と npm を確かめ、npm にトンネルを使わせて、レジストリに届くか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # Node.js と npm の版と配置先を確かめる
   node --version
   npm --version
   command -v node npm
   # npm の通信経路を設定して接続を確かめる
   export https_proxy=socks5h://127.0.0.1:1080
   npm config get https-proxy
   npm config get proxy
   npm ping
   ```

   - Node.js と npm の版、`/usr/bin/node`、`/usr/bin/npm` が出ればよい
   - `/home/linuxbrew/.linuxbrew/bin/npm` が出たら、Homebrew の node が PATH で先に来ていて、Mason もそちらを使う（[npm のオフライン導入 の補足と注意点](#npm-のオフライン導入-の補足と注意点)の「注意点」）
   - `npm config get` の 2 行は、どちらも `null`
   - ほかの値が出たら、`~/.npmrc` などの設定が `https_proxy` より優先される
   - `PONG` が出れば、レジストリに届いている
   - **トンネルを張り直したら、[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 3 に続けて、この手順を貼り直す**

1. この項の手順 2 のシェルで Neovim でファイルを開き、Mason に足りないパッケージを入れさせる。

   ```bash
   nvim -R ~/.config/nvim/init.lua
   ```

   - `:Mason` で画面を開く
   - npm のパッケージ（`markdownlint-cli2`・`json-lsp` など）が `Installed` に並べばよい
   - この項の手順 5 で使う `markdownlint-cli2` が設定に無ければ、`:MasonInstall markdownlint-cli2` で入れる。ほかの npm のパッケージも、同じように名前で入れられる
   - 失敗は通知が出ないことがある。`Installed` に並ばないものは、`:MasonLog` の `Installation failed for Package(name=…)` の行で理由を見る
   - npm 以外の理由（`unzip` が無い、など）で失敗したものは[npm のオフライン導入 の補足と注意点](#npm-のオフライン導入-の補足と注意点)の「注意点」
   - 通知が出そろってから、`:qa` で閉じる
   - LSP サーバーが 1 つも入らなかったら、`:qa` で閉じて、この手順をもう一度貼る
   - **次の手順は、`:qa` で Neovim を閉じてから貼る**（必要なパッケージが入ったことを確かめてから、トンネルを閉じる）

1. [SSH の SOCKS トンネル: トンネルを閉じる](#ssh-の-socks-トンネル-トンネルを閉じる)の手順 1・3 を貼り、トンネルを閉じて、転送を付けずにログインし直す。

   - [SSH の SOCKS トンネル: トンネルを閉じる](#ssh-の-socks-トンネル-トンネルを閉じる)の手順 1（`exit`）はオフラインのホストで、同じ項の手順 3 はオンラインのホストで貼る
   - オンラインのホストのシェルで[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1 の変数が消えていたら（新しいシェルなど）、先に[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1 を貼る
   - **次の手順は、ログインし直してから貼る**（ssh と続けて貼ると、ssh を閉じた後のオンライン側の元のシェルで動く）

1. オフラインのホストで、トンネルが無くても Mason の npm のパッケージが動き、npm が外に出られないことを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # プロキシの環境変数を確かめる
   env | grep -i _proxy
   # Mason の導入済みツールと動作を確かめる
   ls ~/.local/share/nvim/mason/bin
   ~/.local/share/nvim/mason/bin/markdownlint-cli2 --help | head -n 1
   # npm レジストリへの接続を確かめる
   npm ping --fetch-retries=0 && echo '届いた（オフラインではない）' || echo '届かない（期待どおり）'
   ```

   - `env` は何も出さない
   - `ls` に、Mason で入れたコマンド（`markdownlint-cli2`・`vscode-json-language-server` など）が並ぶ
   - `markdownlint-cli2` の版が出ればよい
   - 最後の行は、`ENOTFOUND` のエラーの後に `届かない（期待どおり）`

#### npm のオフライン導入: 更新

- オフラインのホストの Node.js と npm、Mason の npm のパッケージを、SSH の SOCKS トンネルを通して上げる
- 前提: [npm のオフライン導入](#npm-のオフライン導入)を通してある。[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1〜3 でトンネルを張り、そのシェルで[npm のオフライン導入](#npm-のオフライン導入)の手順 2 を貼ってある
- 実行場所: オフラインのホストの、トンネルを張った ssh のシェル（`sudo` できる自分のユーザー）

1. Node.js と npm を上げる。

   ```bash
   sudo dnf upgrade -y nodejs nodejs-npm
   ```

   - 上げるものが無ければ `Nothing to do.`（日本語では `行うべきことはありません。`）と `Complete!`（`完了しました!`）で終わる

1. Neovim でファイルを開き、Mason のパッケージを上げる。

   ```bash
   nvim -R ~/.config/nvim/init.lua
   ```

   - `:MasonUpdate` で、Mason のパッケージの一覧を取り直す（`Successfully updated 1 registry.` の通知が出る）
   - `:Mason` の画面の `Installed` の見出しに `Press U to update 1 package (markdown-toc)` のような案内が出たら、`U` を押して上げる
   - 案内が無ければ、上げるものは無い
   - 上げ終わると `markdown-toc was successfully installed.` のような通知が出る。通知が出そろってから、`:qa` で閉じる
   - 画面の `Installing` の表示は、上げ終わっても残ることがある（`q` で閉じて `:Mason` で開き直すと、`Installed` に移っている）
   - **次の手順は、上げ終わったことを確かめ、`:qa` で Neovim を閉じてから貼る**（続けて貼ると、上げ終わったかを確かめる前にトンネルを閉じる）

1. オフラインのホストからログアウトして、トンネルを閉じる。

   ```bash
   exit
   ```

<details id="npm-のオフライン導入-の補足と注意点">
  <summary>npm のオフライン導入 の補足と注意点</summary>

**注意点**

- **npm だけは `ALL_PROXY` では足りない**: [npm のオフライン導入](#npm-のオフライン導入)の手順 2 の `export` を飛ばさない。Mason の npm パッケージが導入に失敗して再試行を繰り返す
- **`sudo` は `https_proxy` を渡さない**: `sudo printenv https_proxy` は何も出さなかった。`sudo npm install -g` のような使い方は、本書では扱わない
- **Homebrew の node が入っていると、Mason はそちらの npm を使う**: Mason は PATH の先頭の `npm` を使い、`brew shellenv` は Homebrew の `bin` を PATH の先頭に置く。[npm のオフライン導入](#npm-のオフライン導入)の手順 2 の `command -v` で確かめる
- **PyPI のパッケージは入らない**: Mason は PyPI のパッケージを、仮想環境の pip で入れる。その pip は SOCKS のプロキシを使えない
  - GitHub のリリースから入るもの（ruff など）は、この問題が無い
- **npm 以外の理由でも失敗する**: `unzip` が無い場合もパッケージを導入できない。足りないコマンドを確認する
  - 足りないコマンドは、`:checkhealth mason` の `WARNING unzip: not available` のような行で見られる
  - トンネルのシェルで `sudo dnf install -y unzip` を実行してから開き直す
- **Mason のパッケージの一覧は、24 時間ごとに取り直そうとする**: トンネルの無いときに開くと、取り直しに失敗する
  - `:Mason` の画面に `Registry installation failed with the following error:` と出る
  - 入れたパッケージはそのまま使える
  - 一覧を取り直すのは、次にトンネルのあるシェルで開いたとき（[npm のオフライン導入: 更新](#npm-のオフライン導入-更新)）
- **トンネルが無いときに開くと、設定にあって入っていないパッケージの導入が毎回失敗する**: 画面での編集には影響しない
- **ssh が切れると、トンネルも消える**: 途中の導入は失敗する。[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 2 から張り直し、[npm のオフライン導入](#npm-のオフライン導入)の手順 2・3 を貼り直す

**[npm のオフライン導入](#npm-のオフライン導入)の手順 1・2: LazyVim の初回取得より前に経路を設定する理由**

[Neovim](neovim.md#neovim)の手順 2 は、[LazyVim の設定を導入する](neovim.md#lazyvim-の設定を導入する)を参照する。[LazyVim の設定を導入する](neovim.md#lazyvim-の設定を導入する)の手順 8 の初回起動から依存の取得が始まるため、オフラインでは先に同じ SOCKS シェルで Node.js/npm を用意し、`https_proxy` とレジストリの疎通を確認する。[Neovim](neovim.md#neovim)の手順 1 の本体導入と、LazyVim の初回起動を分けて案内する。

2026-10-12の既存VM継続の記録（`docs/verification/npm-offline.md` の「付録: 既存2VMでオフライン経路を継続した記録（2026-10-12、OFFLINE-FULL）」）では、この順番と通信を確認した。キャッシュなしの初回Mason取得や、過去の応答停止原因の証明には含めない。

**[npm のオフライン導入](#npm-のオフライン導入)の手順 2**

- `v22.23.2`、`10.9.8`、`/usr/bin/node`、`/usr/bin/npm` が出る

- `npm notice PONG 148ms` のように `PONG` が出れば、npm はトンネルを通ってレジストリに届いている

**[npm のオフライン導入](#npm-のオフライン導入)の手順 2: npm は ALL_PROXY を読まない**

検証記録（`docs/verification/npm-offline.md` の「実施手順 / 手順 2: 補足: npm は ALL_PROXY を読まない」）

**npm が読むプロキシの環境変数は、`https_proxy`・`http_proxy`・`proxy`・`no_proxy` だけ**（大文字でもよい）。npm 10.9 に同梱の `@npmcli/agent` の `lib/proxy.js`:

```javascript
const PROXY_ENV_KEYS = new Set(['https_proxy', 'http_proxy', 'proxy', 'no_proxy'])
...
    proxy = url.protocol === 'https:'
      ? PROXY_ENV.https_proxy
      : PROXY_ENV.https_proxy || PROXY_ENV.http_proxy || PROXY_ENV.proxy
```

- npm のレジストリは https なので、使うのは `https_proxy` だけ。[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 3 の `ALL_PROXY` は読まない
- `socks5h://` は、同梱の `socks-proxy-agent` が受け付ける（`socks`・`socks4`・`socks4a`・`socks5`・`socks5h`）。`h` を落とすと、名前をオフラインのホストで引いて失敗する（[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 3 の補足）

- **設定の値は、環境変数より優先される。**

**`https_proxy` は、curl と git も読む。** 値は `ALL_PROXY` と同じなので、このシェルの brew も同じプロキシを使う。

**`~/.bashrc` や `~/.npmrc` には書かない。** トンネルがあるのは [SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 2 の ssh の間だけなので、このシェルにだけ入れる（この折りたたみの「選択した方針」）。

- `export` はこのシェルの中だけで有効

**[npm のオフライン導入](#npm-のオフライン導入)の手順 3**

- `:Mason` で画面を開くと、入れている間は `Installing` に `$ npm install markdown-toc@1.2.0` のような行が出る

- 入れ終わるたびに、`markdownlint-cli2 was successfully installed.` のような通知が出る

**[npm のオフライン導入](#npm-のオフライン導入)の手順 3: Mason が npm を動かす仕組みと、ファイルを開く理由**

検証記録（`docs/verification/npm-offline.md` の「実施手順 / 手順 3: 補足: Mason が npm を動かす仕組みと、ファイルを開く理由」）

**Mason（2.3.1）は、npm のパッケージを `~/.local/share/nvim/mason/packages/<名前>` に入れる。** そのディレクトリで `npm init --yes --scope=mason` と `npm install <名前>@<版>` を実行し、`~/.local/share/nvim/mason/bin/` からリンクを張る。

- npm は PATH から探し、環境変数は Neovim のものを引き継ぐ。[npm のオフライン導入](#npm-のオフライン導入)の手順 2 のシェルから開くのは、`https_proxy` を npm に渡すため
- 入れたコマンドは `#!/usr/bin/env node` で始まるので、動かすたびに[npm のオフライン導入](#npm-のオフライン導入)の手順 1 の Node.js を使う
- Mason のパッケージの一覧（mason-registry）は、GitHub のリリースから curl で取る。curl は `ALL_PROXY` も `https_proxy` も読む

**ファイルを開くのは、LSP サーバーも入れさせるため。** LazyVim は、Mason に入れさせるものを 2 か所に持つ。

- ツール（mason.nvim の `ensure_installed`。stylua・markdownlint-cli2 など）: Mason が読み込まれたときに入る
- LSP サーバー（json-lsp・marksman など）: ファイルを開いて nvim-lspconfig が読み込まれたときに入る。Mason もこのときに読み込まれる

**LazyVim は、入れる LSP サーバーを Mason のパッケージの一覧から選ぶ。** 開いた時点で一覧がまだ無い（初めて取るところ）と、その回は LSP サーバーを入れない。

**入れている途中で `:qa` すると、確認は出ず、その導入は止まる。** 次に開いたときに、Mason がやり直す。

**[npm のオフライン導入](#npm-のオフライン導入)の手順 5**

- `markdownlint-cli2 v0.23.3 (markdownlint v0.41.1)` のような版の行が出る

**[npm のオフライン導入](#npm-のオフライン導入)の手順 5: プロキシの変数**

- `env` が何も出さないのは、プロキシの変数が[npm のオフライン導入](#npm-のオフライン導入)の手順 2 のシェルと一緒に消えたため

**[npm のオフライン導入: 更新](#npm-のオフライン導入-更新)のリード**

- Node.js と npm は `sudo dnf upgrade` でも上がる（トンネルか、dnf が届くリポジトリが要る）

**選択した方針**

検証記録（`docs/verification/npm-offline.md` の「選択した方針」）

| 経路 | 要るもの | 採否 |
|---|---|---|
| **AppStream の `nodejs`（22 系）と、シェルの `https_proxy`** | [SSH の SOCKS トンネル](#ssh-の-socks-トンネル)のトンネルと dnf のプロキシ | **採用。** 言語処理系は AppStream から入れる方針（[導入元一覧](tool-catalog.md)）で、`dnf upgrade` で上がる。npm にだけ変数を 1 つ足せば、Mason を書き換えずに npm がトンネルを通る |
| AppStream の `nodejs24`（24.19.0） | 同上 | 不採用。コマンドが `node-24`・`npm-24` で、Mason が探す `npm` が無い |
| Homebrew の `node` | homebrew-offline.md のトンネル | 不採用。Homebrew の `bin` が PATH で先に来るので、RPM の node と npm を隠す。版を選ぶなら mise（[導入元一覧](tool-catalog.md)） |
| `~/.npmrc` に `https-proxy=socks5h://127.0.0.1:1080` を書く | — | 不採用。トンネルが無いときも npm が 1080 番に向かい続ける。dnf のプロキシの行（[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の[SSH の SOCKS トンネル: dnf にもトンネルを使わせる](#ssh-の-socks-トンネル-dnf-にもトンネルを使わせる)）と違い、書かなくても済む |
| `ALL_PROXY` だけ | — | 動かない。npm は `ALL_PROXY` を読まない（[npm のオフライン導入](#npm-のオフライン導入)の手順 2 の補足） |
| npm のキャッシュ・Mason のディレクトリを運ぶ、社内に npm のミラー（Verdaccio など）を建てる | 同じアーキのホスト、運ぶ手段、ミラーのサーバー | 本書では扱わない（ネットワークで届かないときの方法） |

- **Mason の導入を、`nvim --headless` のコマンドにしなかった**
  - `nvim --headless '+MasonInstall <名前>' +qa` の `:MasonInstall` は、名前を挙げたものが終わるまでしか待たない
  - LazyVim が読み込み時に始めたほかの導入は、`+qa` で止まりうる
  - 読者の設定が入れるものを 1 つずつ挙げる必要もあるので、画面で終わりを見て閉じる形にした
- **`https_proxy` を `~/.bashrc` に書かない**: [SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の `ALL_PROXY` と同じ理由（トンネルは[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 2 の ssh の間だけ）

**参照**

- [npm Docs — config の `https-proxy`・`proxy`](https://docs.npmjs.com/cli/v10/using-npm/config#https-proxy) — npm のプロキシの設定と環境変数
- [npm/agent の lib/proxy.js](https://github.com/npm/agent/blob/main/lib/proxy.js) — npm が読むプロキシの環境変数と、SOCKS の扱い
- [mason.nvim](https://github.com/mason-org/mason.nvim) — `lua/mason-core/installer/managers/npm.lua`（npm のパッケージの入れ方）、`lua/mason-core/fetch.lua`（curl と wget）
- [LazyVim の LSP の設定](https://www.lazyvim.org/plugins/lsp) — mason.nvim と mason-lspconfig.nvim の `ensure_installed`
- [SSH の SOCKS トンネル](#ssh-の-socks-トンネル) — 前提のトンネルと dnf のプロキシ。[npm のオフライン導入](#npm-のオフライン導入)の手順 4 で[SSH の SOCKS トンネル: トンネルを閉じる](#ssh-の-socks-トンネル-トンネルを閉じる)の手順 1・3 を使う
- [Homebrew のオフライン導入](#homebrew-のオフライン導入) — 前提の Homebrew（Neovim をトンネル越しに入れる）
- [Neovim](neovim.md#neovim) — 前提の Neovim と、自分用の設定


- 検証記録（`docs/verification/npm-offline.md`）

</details>

---

## アプリ

- Firefox と画像の道具、端末で使う道具（btop・gdu）

### Firefox

- Mozilla の dnf のリポジトリから最新版（Rapid Release）の Firefox を入れ、RPM Fusion の FFmpeg で AAC・H.264 を再生できるようにする
- 前提: [ログインと sudo](#ログインと-sudo)を通してある。この項の手順 7〜9 には、[EPEL と RPM Fusion](#epel-と-rpm-fusion)も要る
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）。この項の手順 6・10 は、デスクトップのセッションの Firefox

1. 変数を設定する。

   ```bash
   FF_PKG=firefox                  # 本書は最新版（Rapid Release）の firefox だけを扱う。変更しない。<FF_PKG>
   FF_L10N=firefox-l10n-ja         # 日本語 UI の言語パック。要らなければ空にする。<FF_L10N>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in FF_PKG FF_L10N; do printf '%-9s = %s\n' "$v" "${!v}"; done
   ```

   - **編集が必須の変数は無い**
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
   printf '\n\033[7m 確認 \033[0m\n'
   sudo rpm --import https://packages.mozilla.org/rpm/firefox/signing-key.gpg
   rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i mozilla
   ```

   - `rpm --import` は期限切れの副鍵についての warning を出すが、問題ない
   - `gpg-pubkey-d98f0353-55a94004` と `Mozilla Software Releases` が出ればよい

1. Mozilla のリポジトリを追加し、入手できる版を見る。

   ```bash
   # Mozilla のリポジトリ設定を書き込む
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
   ```

   - 一覧の下のほうに、`mozilla` リポジトリ提供の版が出る
   - `aarch64` と `x86_64` の両方の行が並ぶ

1. Firefox を導入し、Mozilla 公式のビルドか確認する。

   ```bash
   # Firefox と日本語の言語パックを導入する
   sudo dnf install "${FF_PKG:?「Firefox」の手順 1 の FF_PKG が空のまま。値を入れて貼り直す}" ${FF_L10N}
   printf '\n\033[7m 確認 \033[0m\n'
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' "${FF_PKG}" ${FF_L10N}
   firefox --version
   rpm -qi "${FF_PKG}" | sed -n '/^Vendor/p;/^Build Date/p'
   ```

   - AppStream の Firefox（ESR）が入っていれば、一覧の `アップグレード:` の下に `firefox` が出る
   - この文書を Firefox で見ているときは、入れ替わった後に Firefox を開き直す（この項の手順 6 で、新しい版で起動する）
   - トランザクション表を見て、`[y/N]` に答える
   - `from_repo` が `mozilla`、`Vendor` が `Mozilla` なら、Mozilla 公式のビルドが入っている

1. デスクトップのセッションで Firefox を起動し、`about:support` で公式のビルドかを確かめる。

   - 最初の起動では、窓いっぱいに「Firefox へようこそ」が出る（続行すると、Firefox の利用規約とプライバシー通知に同意したことになる、と書かれている）。「続行」を押すまで、`about:support` は開けない
   - 次のように出ればよい（日本語 UI の表記）
     - 「更新チャンネル」が `release`
     - 「プログラムの実行ファイル」が `/usr/lib/firefox/firefox-bin`（AppStream 版の `/usr/lib64` ではない）
   - 日本語パックを入れた場合は、`about:preferences` の言語で日本語を選べる

1. 入手できる版を見てから、RPM Fusion（[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 2〜4）の FFmpeg のライブラリを入れる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   dnf -q list --showduplicates ffmpeg-libs
   sudo dnf install ffmpeg-libs
   ```

   - `ffmpeg-libs` の候補が `rpmfusion-free-updates` から出ればよい
   - EPEL の `noopenh264` も依存で入るが、H.264 の再生には影響しない（[Firefox の補足と注意点](#firefox-の補足と注意点)）
   - `conflicts with libswresample-free` と出て止まったら、この項の手順 8 で入れ直す。入ったときは手順 8 は飛ばす
   - **次の手順は、トランザクション表の `[y/N]` に答えてから貼る**（この項の手順 8 は、指定の衝突で止まったときだけ貼る）

1. この項の手順 7 が `libavcodec-free` との衝突で止まったときだけ、それを外して入れ直す。

   ```bash
   sudo dnf install --allowerasing ffmpeg-libs
   ```

   - トランザクション表の `Removing dependent packages:` に、`libavcodec-free`・`libavutil-free`・`libswresample-free` の 3 つが出る
   - この 3 つのほかにも `Removing` に出たら、`N` で止める
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると、ほかのパッケージの削除を断ったときや導入に失敗したときも、後ろの確認の行が動く）

1. FFmpeg のライブラリが入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # ffmpeg-libs とリポジトリの導入元を確かめる
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' ffmpeg-libs rpmfusion-free-release epel-release
   # 動画用の共有ライブラリーを確かめる
   ls /usr/lib64/libavcodec.so.*
   ```

   - `ffmpeg-libs` が `rpmfusion-free-updates` から入り、`rpmfusion-free-release`・`epel-release` の行が出ればよい
   - `/usr/lib64/libavcodec.so.61` がある

1. Firefox をすべて閉じてから起動し直し、AAC・H.264 の再生を確かめる。

   - **開いていたら全部閉じてから起動し直す**
   - `about:support` の「コーデックサポート情報」で、`H264` と `AAC` の「ソフトウェアデコーディング」が「対応」になる
   - 再生できなかった動画が再生できる

<details id="firefox-の補足と注意点">
  <summary>Firefox の補足と注意点</summary>

**注意点**

- **Firefox: チャンネルが変わる**: ESR（年 1 回のメジャー更新）から Rapid Release（4 週間ごと）に移る
  - 企業ポリシーで ESR を使っている場合は、この手順を使わない

- **Firefox: セキュリティ更新の出所が変わる**: AppStream 版は AlmaLinux が、mozilla 版は Mozilla が直接出す
  - `dnf upgrade` の対象になるのは同じだが、AlmaLinux のエラータ（`dnf updateinfo`）には載らない

- **Firefox: ダウングレードするとプロファイルを読めないことがある**: 156 で開いたプロファイルを 140 で開くと、「新しいバージョンの Firefox で作成されたプロファイル」と警告が出る
  - 戻す前提があるなら、先に `~/.mozilla/firefox`（新しく作られた場合は `~/.config/mozilla/firefox`）を退避しておく

- **Firefox: 言語パックは本体と同時に上げる**: バージョンが食い違うと UI が英語に戻る。`dnf upgrade` 全体を流していれば自動で揃う

- Firefox: パッケージの導入・削除が終わったことを確かめる

- **Firefox: RPM Fusion は Fedora の外のリポジトリ**: free は「Fedora がライセンス以外の理由で配れないオープンソースのソフト」を配る（RPM Fusion の Configuration の説明）
  - 鍵の照合と、`rpmfusion-free-release` の署名の確かめ方は [EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 2〜4 にある

- **Firefox: FFmpeg を入れたら Firefox を起動し直す**: 起動中の Firefox は読み直さない（[Firefox](#firefox)の手順 10）

- **Firefox: EPEL の `libavcodec-free` とは同居できない**: 入っていると[Firefox](#firefox)の手順 7 が止まる。残したままだと H.264 が再生できない（[Firefox](#firefox)の手順 8）

- **Firefox: aarch64 では Widevine を必要とするコンテンツの再生を前提にしない**

**[Firefox](#firefox)の手順 1**

- **編集が必須の変数は無い**。最新版（Rapid Release）を入れるなら既定のままでよい

**[Firefox](#firefox)の手順 1: 扱う範囲**

- ESR / Beta の導入・確認は本書では扱わない
- [Firefox](#firefox)の手順 1 のブロックは、最後の行で値を読み戻す

**[Firefox](#firefox)の手順 3**

- `gpg-pubkey-d98f0353-55a94004 Mozilla Software Releases ...` の 1 行が出る

**[Firefox](#firefox)の手順 3: 期限切れの副鍵の warning**

- `rpm --import` が出す期限切れの副鍵についての warning は、署名に使う副鍵が別にあるので問題ない

**[Firefox](#firefox)の手順 4: priority は保険**

検証記録（`docs/verification/almalinux-setup.md` の「Firefox: 実施手順 / 手順 4: 補足: priority は保険」）

Mozilla の案内する repo ファイルには `priority` が無い。`priority=10`（数字が小さいほど優先）は、将来のリポジトリ間の優先順位に備えて足している。

将来 AppStream 側の ESR が Mozilla 側の版を追い越す状況（Mozilla 側でリリースが巻き戻る、ESR が別番号体系になる、など）に備えた保険として残している。

`repo_gpgcheck=0` は Mozilla の案内どおりで、**パッケージの署名は検証する（`gpgcheck=1`）がリポジトリメタデータには署名が無い**、という意味。

このリポジトリは `baseurl` に `$basearch` を含まない**全アーキテクチャ共通**の作りなので、`dnf list` には `firefox.x86_64` の行も出る。インストールされるのは実行中のアーキテクチャのものだけ。

**[Firefox](#firefox)の手順 5**

- AppStream の Firefox（ESR）が既に入っているホストでは、この 1 コマンドが、`firefox` のアップグレードとして解決される（一覧の `アップグレード:` の下に `firefox` が出る）

**[Firefox](#firefox)の手順 7**

- 依存として、RPM Fusion の `x264-libs`・`x265-libs` などと、EPEL のライブラリが入る

- 版は `ffmpeg-libs.aarch64  7.1.5-1.el10  rpmfusion-free-updates` のように出る

**[Firefox](#firefox)の手順 9**

- `ffmpeg-libs 7.1.5-1.el10 rpmfusion-free-updates` の行と、`rpmfusion-free-release`・`epel-release` の行が出る

**[Firefox](#firefox)の手順 10: 起動し直す理由**

- 起動中の Firefox は FFmpeg を読み直さない

**選択した方針**

検証記録（`docs/verification/almalinux-setup.md` の「Firefox: 選択した方針」）

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Mozilla 公式 RPM リポジトリ** | `packages.mozilla.org/rpm/firefox` に `firefox` 156.0.1 / `firefox-esr` 153.3.0esr / `firefox-beta` 157.0b4 と各言語パックがあり、**aarch64 と x86_64 の両方**が揃っている。dnf 管理で更新できる | **採用** |
| AppStream の `firefox` | 140.15.0（ESR 140 系）。AlmaLinux がセキュリティ更新を出すが、最新版の機能は入らない | 不採用（最新版ではない） |
| Flathub の `org.mozilla.firefox` | Mozilla 公式ビルド。flathub と runtime の導入が必要で、RPM と二重管理になる | 不採用（RPM で足りる） |
| 公式 tarball を `/opt` に展開 | `linux-aarch64` のビルドが公式にある（Firefox 136 以降）。更新は Firefox 内蔵のアップデータ任せで、`.desktop` を自作する必要がある | 不採用（dnf で管理できない） |
| ソースビルド | 実用的でない | 不採用 |

**AAC と H.264 を OS の FFmpeg で補う理由**:

| 経路 | AAC | H.264 | 採否 |
|---|---|---|---|
| 何も足さない | 再生できない | OpenH264 が落ちるまでは再生できない。落ちた後は再生できる | —（元の状態） |
| **RPM Fusion（free）の `ffmpeg-libs` 7.1.5** | 再生できる | 再生できる（FFmpeg で復号） | **採用** |
| EPEL の `libavcodec-free` 7.1.2 | 再生できる | **再生できない**。H.264 を OpenH264 に任せる作りで、EL10 には中身の無い `noopenh264` しか無い。about:support には「対応」と出るのに `Couldn't open avcodec` で止まり、落ちてきた OpenH264 にも切り替わらない | 不採用 |
| RPM Fusion の `libavcodec-freeworld` | — | — | 不採用（EPEL の `ffmpeg-free` を使い続けるときに足すもの。RPM Fusion の Howto/Multimedia の案内による） |

- RPM Fusion の EL 10 向けには、`ffmpeg-libs` 7.1.5 が aarch64 と x86_64 の両方にある
- RPM Fusion は EPEL を前提にしている（`rpmfusion-free-release` が `epel-release` を要求する）

| 経路 | 状況 | 採否 |
|---|---|---|
| **winget の `Mozilla.Firefox.ja` を PC 全体に** | 157.0。Mozilla の CDN の日本語版の NSIS インストーラ（x64・x86・arm64）を、winget が sha256 を確かめて画面を出さずに入れる。`Scope` は `machine` だけ。Maintenance Service が入り、以後は Firefox が自分で更新する | **採用** |
| winget の `Mozilla.Firefox` に `--locale ja` | 137.0.1 までは言語ごとのインストーラ（`InstallerLocale`）が 51 あったが、137.0.2 から英語（en-US）だけになり、言語ごとに `Mozilla.Firefox.<言語>` に分かれた。言語の無いインストーラは、`--locale` を付けると候補から外れるので、入らないはず | 不採用 |
| `Mozilla.Firefox`（英語版）に日本語の言語パック | 言語パックがあると、閉じている間の更新（Background Update）が動かない（Mozilla の文書）。本体と版を揃える必要もある（AlmaLinux 10 のこの折りたたみの「注意点」と同じ） | 不採用 |
| winget の `Mozilla.Firefox.MSIX`・Microsoft Store 版 | MSIX（言語は multi）で、パッケージのアプリ（`Mozilla.MozillaFirefox`）として入る | 不採用（Mozilla の通常のインストーラと、Firefox 自身の更新にそろえた） |
| scoop の `extras/firefox` | 157.0。英語版のインストーラを 7z で展開するだけのポータブル版で、プロファイルは scoop の `persist` に作る | 不採用（日本語版でなく、PC 全体にも入らない） |
| Mozilla のサイトからインストーラを落として実行 | 同じものが入るが、ダウンロードと実行が画面の操作になる | 不採用（winget で同じインストーラが入る） |

- **PC 全体（`machine`）に入れた**: winget の定義が `machine` しか持たない。AlmaLinux 10 の dnf と同じく、PC の全ユーザーで 1 つの Firefox を使い、更新は Maintenance Service で管理者の確認なしに行える
  - Mozilla のインストーラは、管理者の権限が無いまま入れると `%LOCALAPPDATA%\Mozilla Firefox` に入れ、Maintenance Service は入れない（Firefox のソースの `installer.nsi`・`postupdate_helper.nsh`）。winget の定義では、この形は選べない
- **日本語版（`.ja`）にした**: 言語パックが要らないので、AlmaLinux 10 の「言語パックは本体と同時に上げる」（この折りたたみの「注意点」）に当たる注意が無く、閉じている間の更新も動く
- **既定のブラウザーは、Windows の設定の画面で変える**: 今の Windows 11 では、`http`・`https` の既定をコマンドで書き換えられない（[Firefox](windows-setup.md#firefox)の手順 5 の補足）

**参照**

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

---

### 画像の道具

- Dockerfile とコンテナイメージの検査（hadolint・dive・Trivy）に使う
- 前提: [Homebrew](#homebrew)の手順 1〜2 と[Podman](containers.md#podman)の手順 7（API ソケット）までを通してある
  - `command -v brew podman` が 2 行を返さない、または `systemctl --user is-active podman.socket` が `active` を返さなければ、先に前提を通す
- 実行場所: 自分のユーザーでログインしたシェル（端末の bash か SSH）

> [!IMPORTANT]
> - **`sudo -i` した root のシェルでは行わない**（Homebrew の導入・更新は root では行わず、イメージも自分のユーザーの podman に作るため）

1. hadolint と dive を導入し、結果を確認する。

   ```bash
   # hadolint と dive を導入する
   brew install hadolint dive
   printf '\n\033[7m 確認 \033[0m\n'
   hadolint --version
   dive --version
   command -v hadolint dive
   ```

   - Homebrew の確認が出たら答える
   - hadolint と dive の版が出ればよい
   - どちらも `/home/linuxbrew/.linuxbrew/bin/` の下にある

1. 公式のリポジトリから Trivy を導入し、結果を確認する。

   ```bash
   # Trivy のリポジトリ設定を書き込む
   sudo tee /etc/yum.repos.d/trivy.repo >/dev/null <<'EOF'
   [trivy]
   name=Trivy repository
   baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/$basearch/
   gpgcheck=1
   enabled=1
   gpgkey=https://aquasecurity.github.io/trivy-repo/rpm/public.key
   EOF
   printf '\n\033[7m 確認 \033[0m\n'
   # リポジトリ設定と提供されている版を確かめる
   cat /etc/yum.repos.d/trivy.repo
   dnf -q list --showduplicates trivy
   # Trivy を導入して版と配置先を確かめる
   sudo dnf install trivy
   trivy --version
   command -v trivy
   rpm -q trivy
   ```

   - ファイルに `gpgcheck=1` があることを確かめる
   - `trivy` リポジトリの候補が出ればよい。EPEL の候補も並ぶことがある
   - fingerprint が `825A D903 6F7C 850E 6A6F ED49 35B8 ACA4 4FD9 CA9F`（`trivy-repo <oss@aquasec.com>`）であることを確かめてから `y` と答える。違っていれば `N` で中断する
   - トランザクション表の `[y/N]` に答える
   - `trivy --version` の `Version:` が、この手順で導入した RPM の版と一致し、`/usr/bin/trivy` とその RPM の名前が出ればよい

1. わざと欠陥のある Containerfile を hadolint に渡し、指摘が出ることを確かめる。

   ```bash
   printf 'FROM registry.access.redhat.com/ubi10/ubi-minimal\nRUN microdnf install -y httpd\n' | hadolint -; echo "rc=$?"
   ```

   - `DL3006`・`DL3040`・`DL3041` の 3 つの `warning` と、`rc=1` が出ればよい

1. 確認用の Containerfile とページを置き、hadolint が何も指摘しないことを確かめる。

   ```bash
   # 確認用の HTML ファイルを作成する
   mkdir -p ~/image-check
   echo 'hello from image-check' > ~/image-check/index.html
   printf '\n\033[7m 確認 \033[0m\n'
   cat > ~/image-check/Containerfile <<'EOF'
   FROM registry.access.redhat.com/ubi10/httpd-24:10.1
   COPY index.html /var/www/html/index.html
   EOF
   hadolint ~/image-check/Containerfile; echo "rc=$?"
   ```

   - 何も出ずに `rc=0` ならよい

1. イメージを作る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   podman build -t localhost/image-check:1 ~/image-check
   podman images localhost/image-check
   ```

   - `Successfully tagged localhost/image-check:1` が出る
   - `podman images` に `localhost/image-check  1` の行が出ればよい

1. dive の判定のモード（`--ci`）で、イメージの無駄を数える。

   ```bash
   dive --source podman --ci localhost/image-check:1; echo "rc=$?"
   ```

   - `Image Source: podman://localhost/image-check:1` が出れば、podman のイメージを直接読めている
   - **既定の基準では `Result:FAIL` と `rc=1` になる**

1. Trivy で、イメージの脆弱性を調べる。

   ```bash
   trivy image --image-src podman --severity HIGH,CRITICAL localhost/image-check:1
   ```

   - `Detected OS` の後に `Report Summary` の表が出ればよい

1. dive の画面で、層の中身を見る。

   ```bash
   dive --source podman localhost/image-check:1
   ```

   - 左に `Layers` と `Image Details`、右に `Current Layer Contents` が出る
   - いちばん下の行に、キーの案内（`Quit`・`Tab Switch view`・`^F Filter` など）が出る
   - `q` で終了する
   - **次のコマンドは、`q` で終了してから貼る**（dive を開いたまま貼ると、dive への入力になる）

#### 画像の道具: 使い方の基本

| コマンド | 用途 |
|---|---|
| `hadolint <Containerfile>` | Containerfile（Dockerfile）の書き方を検査する |
| `hadolint --ignore <規則> <Containerfile>` | 特定の規則を外して検査する |
| `dive --source podman <イメージ>` | 層ごとの中身と無駄を画面で見る |
| `dive --source podman --ci <イメージ>` | 無駄の量を基準で判定する（`PASS` / `FAIL` と終了コード） |
| `trivy image --image-src podman <イメージ>` | 手元の podman のイメージの脆弱性を調べる |
| `trivy image <レジストリのイメージ>` | 手元に取らずに、レジストリのイメージを調べる |
| `trivy config <ディレクトリ>` | Containerfile などの設定の問題を調べる |


#### 画像の道具: 更新

- Homebrew で入れた hadolint・dive と、dnf で入れた Trivy を上げる
- 前提: [画像の道具](#画像の道具)を通してある
- 実行場所: 自分のユーザーでログインしたシェル（端末の bash か SSH）

1. hadolint と dive を更新する。

   ```bash
   brew upgrade hadolint dive
   ```

   - 新しい版が無ければ `already installed` と出て、何もしない
   - すべてまとめて上げるなら `brew upgrade`

1. Trivy を更新する。

   ```bash
   sudo dnf upgrade trivy
   ```

   - 更新があると `[y/N]` で聞かれる。無ければ `Nothing to do.` で終わる

<details id="画像の道具-の補足と注意点">
  <summary>画像の道具 の補足と注意点</summary>

**注意点**

- **dive の `--ci` の既定の基準は厳しい**: ベースイメージの層の無駄も数えるので、よく使われるイメージを元にしただけで `FAIL` になる。CI で使うなら、基準を自分で決めて `.dive-ci` に書く
- **Trivy の結果は日によって変わる**: データベースは新しい脆弱性が見つかるたびに更新される。同じイメージでも、後日の結果は変わりうる
- **Trivy の `--image-src podman` は API ソケットが要る**: [Podman](containers.md#podman)の手順 7 のソケットが止まっていると、[画像の道具](#画像の道具)の手順 7 の Trivy がソケットへの接続に失敗する
- **hadolint と Trivy の設定の検査は、見るところが違う**: 確認用の Containerfile は hadolint では指摘が無く、`trivy config` では `USER` と `HEALTHCHECK` が無いことを指摘された（[画像の道具: 使い方の基本](#画像の道具-使い方の基本)）
- **Homebrew の 2 つは、そのままでは `sudo` の PATH に無い**（[Homebrew の補足と注意点](#homebrew-の補足と注意点)の「注意点」）: root で使うなら、[Homebrew を sudo でも使う](#homebrew-を-sudo-でも使う)の節を通すか、`/home/linuxbrew/.linuxbrew/bin/hadolint` のようにフルパスで呼ぶ

**[画像の道具](#画像の道具)のリード**

- **[画像の道具](#画像の道具)の手順 2 には対話入力がある**（トランザクション表の `[y/N]` と Trivy の鍵の確認）。表示された内容を確かめて答える

- **[画像の道具](#画像の道具)の手順 8 で dive の画面（TUI）が開く**。`q` で終了する

**[画像の道具](#画像の道具)の手順 1**

- `Haskell Dockerfile Linter 2.15.1` と `dive 0.13.1` が出る

**[画像の道具](#画像の道具)の手順 1: ボトルと依存**

検証記録（`docs/verification/image-tools.md` の「実施手順 / 手順 1: 補足: ボトルと依存」）

- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
- hadolint は `gmp` など 4 つの依存を連れてくる（Haskell 製のため）。dive に依存は無い

**[画像の道具](#画像の道具)の手順 2**

- 初回は署名鍵の取り込みを 1 回聞かれる

- 公式の候補は `trivy.x86_64  0.75.0-1  trivy` のように出る。EPEL の候補も並ぶことがある

**[画像の道具](#画像の道具)の手順 2: リポジトリのファイル**

- 中身は Trivy の公式の導入手順（RHEL/CentOS）と同じ
- `<<'EOF'` と引用符を付けているので、`$basearch` はそのままファイルに書かれ、dnf が `x86_64` / `aarch64` に置き換える

**[画像の道具](#画像の道具)の手順 2: root の PATH**

- Trivy は RPM なので、Homebrew の 2 つと違い、何も足さずに root の PATH にも入っている

**[画像の道具](#画像の道具)の手順 3: 標準入力**

- `hadolint -` の末尾の `-` は、標準入力の Containerfile を読む指定

**[画像の道具](#画像の道具)の手順 4: 確認用のイメージ**

- `ubi10/httpd-24`（Apache）に、ページを 1 つ足すだけのイメージ

**[画像の道具](#画像の道具)の手順 5**

- `podman images` に `localhost/image-check  1` の行が出る（283 MB）

**[画像の道具](#画像の道具)の手順 5: buildah**

- `podman build` は podman に入っている。buildah を別に入れる必要は無い

**[画像の道具](#画像の道具)の手順 6**

- `efficiency: 85.4470 %` と `wastedBytes: 58951134 bytes (59 MB)` が出る

**[画像の道具](#画像の道具)の手順 6: FAIL の理由と、判定の基準**

検証記録（`docs/verification/image-tools.md` の「実施手順 / 手順 8: 補足: FAIL の理由と、判定の基準」）

- 無駄の元はベースイメージの層で、[画像の道具](#画像の道具)の手順 4 の `COPY` の層ではない
- `ubi10/httpd-24` は、複数の層でパッケージを入れるため、層ごとに rpm のデータベースが書き直される
- 自分が足した層が小さいと、「自分が足した量に対する無駄」の割合が大きく出る

- 基準は `--lowestEfficiency` などのオプションか、リポジトリに置く `.dive-ci` で変えられる（`dive --help`）
- `--source podman` の dive は podman のコマンド（`podman image save`）でイメージを取り出すので、API ソケットは要らない

**[画像の道具](#画像の道具)の手順 7**

- 初回は脆弱性のデータベースを落とす（容量は取得時点で変わる）

- 脆弱性の結果は、データベースの日付とイメージの中身で変わる

- `Detected OS  family="redhat" version="10.1"` の後に、`Report Summary` の表が出る

**[画像の道具](#画像の道具)の手順 8**

- `Image Details` の `Image efficiency score: 85 %` と `Potential wasted space: 59 MB` は、[画像の道具](#画像の道具)の手順 6 と同じ値

**[画像の道具](#画像の道具)の手順 8: 画面の項目**

- `Layers` は層の一覧、`Current Layer Contents` はその層のファイルの木

**[画像の道具: 使い方の基本](#画像の道具-使い方の基本)のリード**

- `trivy image registry.access.redhat.com/ubi10/ubi-minimal:latest --severity CRITICAL` は、手元に取らずに `redhat 10.2` と判定し、`0` を返した
- 確認用の Containerfile に `trivy config ~/image-check` を使うと、hadolint が何も言わなかったのに対して、2 つが出た
  - `DS-0002 (HIGH)`: `USER` が無い（ベースイメージが root 以外で動くことは見ていない）
  - `DS-0026 (LOW)`: `HEALTHCHECK` が無い

**[画像の道具: 更新](#画像の道具-更新)の手順 1**

- 新しい版が無ければ `Warning: hadolint 2.15.1 already installed` のように出て、何もしない

**[画像の道具: 更新](#画像の道具-更新)の手順 2: 脆弱性のデータベース**

- 脆弱性のデータベースは別もので、`trivy image` が古いと判断したときに取り直す

**選択した方針**

| ツール | 経路 | 理由 |
|---|---|---|
| hadolint | **Homebrew（2.15.1）** | AppStream にも EPEL にも無い。公式のコンテナイメージで動かす方法もあるが、検査のたびにコンテナを起動することになる |
| dive | **Homebrew（0.13.1）** | RPM のリポジトリが無い（上流は GitHub に rpm を置いているだけで、`dnf upgrade` に乗らない） |
| Trivy | **公式の dnf リポジトリ（0.74.0）** | Homebrew と同じ版なので、[選び方](tool-catalog.md#選び方)の規則 1 で RPM にした。EPEL は 0.64.1 と古い |
| syft / grype（SBOM と脆弱性） | 対象外 | Trivy と役割が重なる |

- 3 つの経路が混ざるので、更新も `brew upgrade` と `sudo dnf upgrade` の 2 つになる（[画像の道具: 更新](#画像の道具-更新)）
- Trivy だけ RPM なので、`sudo trivy` がそのまま動く。hadolint と dive は Homebrew なので、root で使うなら [Homebrew を sudo でも使う](#homebrew-を-sudo-でも使う)の節を通すか、フルパスで呼ぶ

**参照**

- [hadolint — README](https://github.com/hadolint/hadolint) — 規則の一覧、`--ignore`、設定ファイル（`~/.config/hadolint.yaml`）
- [dive — README](https://github.com/wagoodman/dive) — `--source`、`--ci` と `.dive-ci`、キー操作
- [Trivy — Installation](https://trivy.dev/docs/latest/getting-started/installation/) — RHEL/CentOS の公式 dnf リポジトリの登録
- [Trivy — Container Image](https://trivy.dev/docs/latest/guide/target/container_image/) — `--image-src`（podman は API ソケットを使う）
- [Homebrew](#homebrew)の手順 1〜2（Homebrew） / [Podman](containers.md#podman) — 前提の手順書


- 検証記録（`docs/verification/image-tools.md`）

</details>

---

### btop

- CPU・メモリ・ディスク・ネットワーク・プロセスを端末の画面で見る btop を、EPEL から入れる
- 前提: [EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 1 で EPEL を有効にしてある（`dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に通す）
- 実行場所: btop を入れるホストの、自分のユーザーの端末（bash）。**すべて、その対象ホスト上で実行する**
- EPEL 版と Homebrew 版は片方だけにする

1. btop を導入して起動し、設定ファイルの作成を確認する。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # 提供されている btop の版を確かめて導入する
   dnf -q list --showduplicates btop
   sudo dnf install btop
   # btop の版と配置先と導入元を確かめる
   btop --version
   command -v btop
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' btop
   # btop を起動して設定ファイルを確かめる
   btop
   ls -l ~/.config/btop
   ```

   - EPEL の署名鍵の確認が出たら、fingerprint `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）なら `y`、違えば `N` で中断する
   - トランザクション表の `[y/N]` に答える
   - 画面が出たら `q` で終了する
   - `btop.conf` と `themes/` があればよい

#### btop: 設定ファイル

- btop の設定ファイルとテーマの置き場所を確かめ、起動せずに既定の設定を見る
- 前提: [btop](#btop)を通してある
- 実行場所: btop を入れたホストの、自分のユーザーの端末（bash）

1. 起動せずに、既定の設定だけを見る。

   ```bash
   btop --default-config | head -20
   ```

#### btop: 更新

- btop を dnf で上げる。btop は通常の更新に含まれる
- 前提: [btop](#btop)を通してある
- 実行場所: btop を入れたホストの、自分のユーザーの端末（bash）

1. btop を更新する。

   ```bash
   sudo dnf upgrade btop
   ```

   - システム全体なら `sudo dnf upgrade`

<details id="btop-の補足と注意点">
  <summary>btop の補足と注意点</summary>

**注意点**

- **EPEL 版は `GPU_SUPPORT=false` でビルドされている**: `btop --version` の 3 行目にそう出る。GPU の使用率パネルは出ない
  - Raspberry Pi では元々使えないので実害は無いが、GPU 監視が目的なら別経路を検討する
- **EPEL が遅れると版が止まる**: 今は upstream と同じ 1.4.7 だが、EPEL の更新が止まれば古いままになる。そのときは Homebrew 版に移せる
  - **ただし `/usr/bin/btop` と Homebrew 版を両方入れると、PATH の先頭にある Homebrew 版が勝ち、`dnf upgrade` で上がるのは使われないほうになる。片方だけにする**
- **表示は端末の UTF-8 とカラーに依存する**: 記号が崩れるときは `--force-utf`、色がおかしいときは `-l`（256 色）や `-t`（TTY モード）を試す
- **root で起動しなくても動く**: ただし他ユーザーのプロセスの詳細（コマンドライン全体など）は見えないことがある
  - 全部見たいなら `sudo btop`（RPM なので、何も足さずに root の PATH にも入っている。ここが Homebrew 版との違い）
- **設定は初回起動まで作られない**: この折りたたみの「btop: 設定ファイルのリード」と「参照」で確かめる
- **`htop` とは別物**: 同時に入れても衝突しない

**[btop](#btop)のリード**

- [btop](#btop)の手順 1 には対話入力がある（トランザクション表の `[y/N]` と鍵の確認）。表示された内容を確かめて答える
- [btop](#btop)の手順 1 で TUI が開く。`q` で終了すると、設定ファイルの確認が動く

**[btop](#btop)の手順 1**

- 版は `btop.aarch64  1.4.7-1.el10_2  epel` のように 1 つだけ出る
- EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる
- `btop version: 1.4.7` と `/usr/bin/btop` が出てから、btop の画面が開く

**[btop](#btop)の手順 1: 依存**

- 依存として `hicolor-icon-theme`（デスクトップエントリのアイコン用）が、まだ無ければ一緒に入る

**[btop: 設定ファイル](#btop-設定ファイル)のリード**

- `~/.config/btop/btop.conf` は**初回起動時に既定値で作られる**（約 9.8 KB、項目ごとにコメント付き）
- アプリ内では `Esc` または `m` でメニューが開き、`Options` からほとんどの項目を GUI で変えられる（保存も btop がやる）
- テーマは 2 か所から読む。`btop.conf` の `color_theme` にファイル名を書くと切り替わる（`"Default"` と `"TTY"` は組み込み）
  - `/usr/share/btop/themes/`: RPM が入れる既定のテーマ（`dracula` / `nord` / `gruvbox-*` / `adwaita-dark` など）
  - `~/.config/btop/themes/`: 自分で足すテーマ

**[btop: 設定ファイル](#btop-設定ファイル)の手順 1: よく使う起動オプション**

`btop --help` の全文より抜粋:

| オプション | 意味 |
|---|---|
| `-p, --preset <id>` | プリセット（0-9）を指定して起動 |
| `-t, --tty` / `--no-tty` | TTY モードの強制・強制解除（16 色と ASCII 寄りの記号になる） |
| `-l, --low-color` | true color を使わず 256 色にする |
| `--force-utf` | ロケール判定を無視して UTF-8 として扱う |
| `-u, --update <ms>` | 更新間隔 |
| `-f, --filter <filter>` | プロセスの絞り込みを指定して起動 |
| `-c, --config <file>` | 設定ファイルを指定 |
| `--default-config` | 既定の設定を標準出力に出す |

**[btop: 更新](#btop-更新)の手順 1**

- EPEL が新しい版を出すまでは上がらない

**参照**

- 検証記録（`docs/verification/btop.md`）
- [aristocratos/btop — README](https://github.com/aristocratos/btop) — 機能、キーバインド、設定項目、テーマの書式
- [EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 1 — 前提の `epel-release` の入れ方と、CRB の案内
- `btop --help` / `btop --default-config` — 起動オプションと既定の設定
- `man btop` — RPM に同梱

</details>

---

### gdu

- ディスクの使用量を端末の画面で調べる gdu を、Homebrew で入れる
- 前提: [共通の bash 設定](shell-terminal.md#共通の-bash-設定)と[Homebrew](#homebrew)の手順 1〜2 を通してある（`command -v brew` で何も出なければ、先に通す）
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。PATH に Homebrew が入った端末）
- ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない

> [!IMPORTANT]
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わず、共通設定も自分のユーザーに導入するため）

1. brew で gdu を入れる。

   ```bash
   brew install gdu
   ```

   - **入るコマンドは `gdu` ではなく `gdu-go`**
   - `brew install` の最後に ``To avoid a conflict with `coreutils`, `gdu` has been installed as `gdu-go`.`` という caveat が出る

1. `gdu-go` が入ったことと、TUI を起動せずに走査できることを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # gdu-go の版とコマンド名を確かめる
   gdu-go --version
   brew list --versions gdu
   command -v gdu-go
   command -v gdu || echo 'gdu という名前のコマンドは無い'
   # ディスク使用量を集計して確かめる
   gdu-go -n /usr/share | tail -5
   ```

   - gdu-go の版が出ればよい
   - `command -v gdu` の行は `gdu という名前のコマンドは無い` になる。[gdu の名前で呼ぶ](#gdu-gdu-の名前で呼ぶ)をやるまでは、これが正しい状態
   - 最後の `gdu-go -n` では、サイズの大きい順に並んだ一覧が出る

#### gdu: gdu の名前で呼ぶ

- 共通の bash 設定のエイリアスで、`gdu-go` を `gdu` の名前で呼ぶ
- 前提: [gdu](#gdu)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。PATH に Homebrew が入った端末）

1. 共通設定を読み直し、gdu のエイリアスを確かめる。

   ```bash
   # 共通の bash 設定を読み込む
   . ~/.bashrc
   printf '\n\033[7m 確認 \033[0m\n'
   alias gdu
   ```

   - `alias gdu='gdu-go'` が出ればよい

1. スクリプトや他のツールからも `gdu` で呼びたいときだけ、シンボリックリンクにする。

   ```bash
   mkdir -p ~/.local/bin && ln -sfn /home/linuxbrew/.linuxbrew/bin/gdu-go ~/.local/bin/gdu
   ```

   - `sudo gdu` には効かない。`sudo` では `gdu-go` と打つ（[Homebrew を sudo でも使う](#homebrew-を-sudo-でも使う)が要る）

#### gdu: 更新

- brew で gdu を上げる
- 前提: [gdu](#gdu)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。PATH に Homebrew が入った端末）

1. brew で gdu を更新する。

   ```bash
   brew upgrade gdu
   ```

   - すべてまとめて上げるなら `brew upgrade`

<details id="gdu-の補足と注意点">
  <summary>gdu の補足と注意点</summary>

**注意点**

- **コマンド名が `gdu-go`**: これが最大の引っかかりどころ。`gdu` と打って `command not found` になったら、まず `command -v gdu-go` を見る
- **エイリアスの確認に `type -t` は使えない**: bash は非対話シェルでエイリアスを展開しないため、`type -t gdu` はエイリアスを見つけられない（`alias gdu` なら確認できる）
  - 関数を定義する zoxide（[シェルのツール](shell-terminal.md#シェルのツール)）や、[yazi](#yazi) の `y()` は、この制約を受けない
- **EPEL 版と同時に入れると版が 2 つ並ぶ**: 名前が違う（`/usr/bin/gdu` と `gdu-go`）ので上書きされず、**共存してしまう**
  - `gdu` と打つと EPEL の 5.32.0、`gdu-go` と打つと Homebrew の 5.37.0 という状態になる
  - どちらか片方にする
- **エイリアスは対話シェルだけ**: スクリプトや `sudo` からは `gdu-go`。スクリプトからも揃えたいならシンボリックリンク（`sudo` には効かない）
- **走査は I/O が重い**: Raspberry Pi の microSD で `/` 全体を走らせると時間がかかる。`-x`（ファイルシステムを跨がない）や対象ディレクトリの限定を併用する
- **TUI からファイルを消せる**: `d` で削除できるので、root 権限で起動するときは特に注意する（`sudo gdu-go` は、[Homebrew を sudo でも使う](#homebrew-を-sudo-でも使う)の節を通さないと、フルパスが要る。[Homebrew の補足と注意点](#homebrew-の補足と注意点)の「注意点」）

**[gdu](#gdu)の手順 1: ボトルと依存**

- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
- 依存は無い（Go の静的バイナリ 1 つ、約 20 MB）
- `brew install` の最後に出る caveat の出力例は検証記録

**[gdu](#gdu)の手順 2**

- `Version: v5.38.0` のように版が出る

**[gdu](#gdu)の手順 2: TUI で使う**

- TUI で使うときは引数にディレクトリを渡すだけ（`gdu-go ~` など。`q` で終了）

**[gdu: gdu の名前で呼ぶ](#gdu-gdu-の名前で呼ぶ)の手順 1: 共通設定**

- gdu のエイリアスは共通設定にあるので、`~/.bashrc` への追記は不要

**[gdu: gdu の名前で呼ぶ](#gdu-gdu-の名前で呼ぶ)の手順 2: シンボリックリンク**

- `~/.local/bin` は AlmaLinux の既定の `~/.bashrc` で PATH に入っている
- リンク先を Cellar ではなく `/home/linuxbrew/.linuxbrew/bin` にしてあるので、`brew upgrade` で版が上がってもリンクは張り直さなくてよい
- ただし **PATH の順序では Homebrew のほうが先**なので、EPEL 版の `/usr/bin/gdu` を同時に入れている場合はどちらが呼ばれるか変わる（この折りたたみの「注意点」）
- `sudo gdu` に効かないのは、`~/.local/bin` が sudo の PATH に無いため

**参照**

- [dundee/gdu — README](https://github.com/dundee/gdu) — 使い方、キーバインド、各ディストリビューションでの入手方法
- [gdu — Configuration](https://github.com/dundee/gdu/blob/master/docs/configuration.md) — `~/.gdu.yaml` の項目
- `gdu-go --help` — 全フラグ（非対話モード、除外、データベース出力など）
- [Homebrew の gdu formula](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/g/gdu.rb) — `gdu-go` にリネームしている箇所
- [Homebrew](#homebrew)の手順 1〜2 — Homebrew 本体の導入手順。`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件は[Homebrew の補足と注意点](#homebrew-の補足と注意点)の「注意点」、`brew` の基本操作は[Homebrew の使い方の基本](#homebrew-の使い方の基本)


- 検証記録（`docs/verification/gdu.md`）

</details>

---

## ネットワークとリモート操作

- SSH・SOCKS トンネル。GNOME のリモートの画面（デスクトップ共有・ヘッドレスセッション・リモートログイン）は[GNOME のリモート操作のセットアップ](gnome-remote.md)で入れる

### SSH を公開鍵だけにする

- 常時動かしておく PC で、パスワードでの SSH のログインを断り、公開鍵だけにする
- 前提: [ログインと sudo](#ログインと-sudo)と、[システムの設定](#システムの設定)の手順 3・4（SSH の待ち受けとファイアウォール）を通してある
- 実行場所: 常時動かしておく PC の、SSH でログインを受けるユーザーの端末（bash）。この項の手順 2・4 は、つなぐ側の PC で行う
- 鍵は、つなぐ側の PC で作る（`ssh-keygen -t ed25519`）。公開鍵の 1 行は、つなぐ側の `~/.ssh/id_ed25519.pub`（Windows は `%USERPROFILE%\.ssh\id_ed25519.pub`）

> [!WARNING]
> **この項の手順 3 の後は、パスワードでは SSH でログインできない**。この項の手順 2 で、鍵でログインできることを確かめてから貼る。SSH でつないで作業しているときは、そのセッションを閉じずに、別のセッションでこの項の手順 4 を確かめる。

1. 公開鍵を `~/.ssh/authorized_keys` に足す（`SSH_PUBKEY` は必ず値を入れる）。

   ```bash
   SSH_PUBKEY=''   # つなぐ側の PC の公開鍵（ssh-ed25519 AAAA… の 1 行）。<SSH_PUBKEY>
   ```

   ```bash
   # 登録する公開鍵の形式を確かめる
   if [ -z "${SSH_PUBKEY}" ]; then echo '中断: SSH_PUBKEY が空のまま。公開鍵の 1 行を入れて貼り直す' >&2
   elif ! printf '%s\n' "${SSH_PUBKEY}" | ssh-keygen -lf - >/dev/null; then echo '中断: SSH_PUBKEY が公開鍵の形ではない' >&2
   else
     # 公開鍵を登録するファイルを用意する
     install -d -m 700 ~/.ssh
     touch ~/.ssh/authorized_keys
     chmod 600 ~/.ssh/authorized_keys
     # 公開鍵を追加して SELinux の設定を整える
     if grep -qxF "${SSH_PUBKEY}" ~/.ssh/authorized_keys; then echo 'この鍵はもうある'; else printf '%s\n' "${SSH_PUBKEY}" >> ~/.ssh/authorized_keys; fi
     restorecon -R ~/.ssh
     printf '\n\033[7m 確認 \033[0m\n'
     ssh-keygen -lf ~/.ssh/authorized_keys
   fi
   ```

   - 最後に、足した鍵の fingerprint（`256 SHA256:… (ED25519)`）が出ればよい

1. つなぐ側の PC から、鍵でログインできることを確かめる。

   - `ssh -o PasswordAuthentication=no <USER>@<IP>` でログインできればよい（パスフレーズを付けた鍵なら、パスフレーズを聞かれる）
   - `Permission denied (publickey,…)` で断られたら、この項の手順 1 の鍵と、つなぐ側の鍵が合っていない。この項の手順 3 へは進まない
   - **次の手順は、鍵でログインできてから貼る**

1. パスワードでの SSH のログインを切る。

   ```bash
   # 公開鍵認証だけを許可する設定を書き込む
   printf 'PasswordAuthentication no\nKbdInteractiveAuthentication no\n' | sudo install -m 0600 /dev/stdin /etc/ssh/sshd_config.d/40-pubkey-only.conf
   printf '\n\033[7m 確認 \033[0m\n'
   # SSH の設定を検査して読み直す
   sudo sshd -t && sudo systemctl reload sshd
   # 認証方式の設定を読み戻す
   sudo sshd -T | grep -Ei '^(passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication) '
   ```

   - `passwordauthentication no`・`kbdinteractiveauthentication no`・`pubkeyauthentication yes` が出ればよい
   - `sshd -t` が設定の誤りを見つけたら、reload しない（誤りの行が出る）。今つないでいるセッションは切れない

1. つなぐ側の PC から、パスワードでは断られることを確かめる。

   - `ssh -o PubkeyAuthentication=no <USER>@<IP>` が、パスワードを聞かずに `Permission denied (publickey,gssapi-keyex,gssapi-with-mic).` で断られればよい
   - 鍵（`ssh <USER>@<IP>`）では、そのまま入れる

<details id="ssh-を公開鍵だけにする-の補足と注意点">
  <summary>SSH を公開鍵だけにする の補足と注意点</summary>

**[SSH を公開鍵だけにする](#ssh-を公開鍵だけにする)の手順 1: restorecon**

- `restorecon` は、`~/.ssh` の SELinux のラベルを、sshd が読めるものに合わせる

**選択した方針**

- **SSH を公開鍵だけにする**: ドロップインのファイル名を `40-pubkey-only.conf` にする。sshd は最初に読んだ値を使い、Workstation の `50-redhat.conf` より前に読ませるため

**参照**

- `man sshd_config`（最初に読んだ値が使われる）

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

---

### SSH の SOCKS トンネル

- インターネットに出られないホストから、ssh の SOCKS の転送で、インターネットに出られるホストを通して外へ出る
- 前提: オンラインのホストからオフラインのホストへ ssh でログインできる（LAN・VPN・VirtualBox のホストオンリーのネットワークなど）。オンラインのホストの OpenSSH は 7.6 以上
- 実行場所: この項の手順 1・2 は、インターネットに出られるホスト（以下、オンラインのホスト）のシェル（bash）。手順 3 は、手順 2 でログインしたインターネットに出られないホスト（以下、オフラインのホスト）のシェル

- オンラインのホストが Windows なら、この項の手順 1 は飛ばし、手順 2 の箇条書きのとおり 1 行を打つ

> [!WARNING]
> **トンネルを張っている間は、オフラインのホストのどのユーザーも `127.0.0.1:1080` を通ってインターネットに出られる**（出口はオンラインのホスト）。使い終わったら[トンネルを閉じる](#ssh-の-socks-トンネル-トンネルを閉じる)。
>

1. オンラインのホストで、変数を設定する（`OFFLINE_HOST` は必ず値を入れる）。

   ```bash
   OFFLINE_HOST=192.0.2.20              # ← 自分の値に書き換える。オフラインのホストの IP アドレスかホスト名。<OFFLINE_HOST>
   ```

   ```bash
   OFFLINE_USER=${USER}                 # オフラインのホストでログインするユーザー。<OFFLINE_USER>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in OFFLINE_HOST OFFLINE_USER; do
     printf '%-12s = %s\n' "$v" "${!v}"
   done
   ```

   - 編集が必須なのは `OFFLINE_HOST` だけ
   - オフラインのホストのユーザー名がオンラインのホストと違うときは、`OFFLINE_USER` も書き換える
   - `OFFLINE_HOST` を書き換えたかをここで確かめる
   - **新しいシェルを開いたら**、この項の手順 1 の 2 つのブロックを貼り直す

1. オンラインのホストから、SOCKS の転送を付けて ssh でログインする。

   ```bash
   ssh -o ExitOnForwardFailure=yes -o ControlPath=none -R 1080 "${OFFLINE_USER:?手順 1 の OFFLINE_USER が空のまま}@${OFFLINE_HOST:?手順 1 の OFFLINE_HOST が空のまま}"
   ```

   - ログインすると、オフラインのホストの `127.0.0.1:1080` が SOCKS プロキシになる。そこへの接続は、オンラインのホストから外へ出る
   - 転送は、この ssh のセッションが続く間だけ有効。このウィンドウは開いたままにする
   - オンラインのホストが Windows なら、PowerShell か cmd に `ssh -o ExitOnForwardFailure=yes -o ControlPath=none -R 1080 <OFFLINE_USER>@<OFFLINE_HOST>` を打つ
   - `Error: remote port forwarding failed for listen port 1080` で終わったら、オフラインのホストで 1080 番がふさがっているか、sshd が転送を禁じている（[SSH の SOCKS トンネル の補足と注意点](#ssh-の-socks-トンネル-の補足と注意点)）
   - 初めてつなぐホストでは、ホスト鍵の確認に `yes` と答える
   - **次の手順は、オフラインのホストにログインしてから貼る**（続けて貼ると、ssh を閉じた後のオンライン側の元のシェルで動く）

1. オフラインのホストで、プロキシを環境変数に入れ、インターネットに届くか確かめる。

   ```bash
   # SOCKS トンネルを使う通信経路を設定する
   export ALL_PROXY=socks5h://127.0.0.1:1080
   printf '\n\033[7m 確認 \033[0m\n'
   # トンネルの待ち受けを確かめる
   ss -Hltn 'sport = :1080'
   # トンネル経由の外部接続を確かめる
   curl -sS -o /dev/null --connect-timeout 10 -w '%{http_code}\n' https://github.com
   ```

   - `ss` の行は `127.0.0.1:1080`（IPv6 があれば `[::1]:1080` も）だけ
   - `0.0.0.0:1080` や `*:1080` が出たら、LAN 全体にプロキシが開いている。`exit` で抜けて、ここで止める（[SSH の SOCKS トンネル の補足と注意点](#ssh-の-socks-トンネル-の補足と注意点)）
   - 最後の行が `200` なら届いている
   - `000` と `Failed to connect to 127.0.0.1 port 1080` が出たら、この項の手順 2 の転送が無い
   - **ssh を張り直したら、この項の手順 2 からやり直す**
   - `sudo` を付けたコマンド・podman・npm は `ALL_PROXY` を読まない（[SSH の SOCKS トンネル の補足と注意点](#ssh-の-socks-トンネル-の補足と注意点)）。dnf には[dnf にもトンネルを使わせる](#ssh-の-socks-トンネル-dnf-にもトンネルを使わせる)で設定する

#### SSH の SOCKS トンネル: dnf にもトンネルを使わせる

- オフラインのホストで、dnf で外のリポジトリから入れるときだけ行う（[Homebrew のオフライン導入](#homebrew-のオフライン導入) では、Homebrew の依存が足りないとき）
- 前提: オフラインのホストで[ログインと sudo](#ログインと-sudo)を通してある。[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1〜3 で、トンネルを張ってある
- 実行場所: オフラインのホストの、[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 3 を貼ったシェル（bash）
- 社内のミラーなど、dnf がトンネル無しで届くリポジトリを使うホストでは行わない（その通信もトンネルに向かってしまう）

1. dnf にプロキシを設定する。

   ```bash
   # dnf のプロキシ設定を追加する
   if grep -q '^proxy' /etc/dnf/dnf.conf; then echo '中断: /etc/dnf/dnf.conf に proxy の行が既にある（この手順は行わない）' >&2; else
     sudo sed -i '/^\[main\]$/a proxy=socks5h://127.0.0.1:1080' /etc/dnf/dnf.conf
     printf '\n\033[7m 確認 \033[0m\n'
     # 追加した設定を読み戻す
     grep -n '^proxy' /etc/dnf/dnf.conf
     # プロキシ経由でメタデータを取得する
     sudo dnf makecache
   fi
   ```

   - `2:proxy=socks5h://127.0.0.1:1080` と `Metadata cache created.`（日本語では `メタデータキャッシュを作成しました。`）が出ればよい

#### SSH の SOCKS トンネル: トンネルを閉じる

- SOCKS のトンネルを閉じ、オフラインのホストが外に出られなくなったことを確かめる
- 前提: [SSH の SOCKS トンネル](#ssh-の-socks-トンネル)でトンネルを張り、トンネルを使う手順書の作業を終えてある
- 実行場所: この項の手順 1 は、トンネルを張ったオフラインのホストのシェル（[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 2 でログインしたシェル）。手順 2・3 は、手順 1 で戻ったオンラインのホストのシェル（bash）、手順 4 は、手順 3 でログインしたオフラインのホストのシェル
- オンラインのホストが Windows なら、この項の手順 2 は飛ばし、手順 3 の箇条書きのとおり 1 行を打つ
- 張り直すときは、[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1〜3 から（同じ項の手順 1 の変数が残っているオンラインのホストのシェルなら、同じ項の手順 2 から）
- この項の手順 2〜4 は、閉じたことを確かめるためのもの。確かめないなら、この項の手順 1 だけでよい

1. オフラインのホストからログアウトして、トンネルを閉じる。

   ```bash
   exit
   ```

   - **次の手順は、オンラインのホストのプロンプトに戻ってから貼る**

1. オンラインのホストで、変数を設定する（`OFFLINE_HOST` は必ず値を入れる）。

   ```bash
   OFFLINE_HOST=192.0.2.20              # ← 自分の値に書き換える。オフラインのホストの IP アドレスかホスト名。<OFFLINE_HOST>
   ```

   ```bash
   OFFLINE_USER=${USER}                 # オフラインのホストでログインするユーザー。<OFFLINE_USER>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in OFFLINE_HOST OFFLINE_USER; do
     printf '%-12s = %s\n' "$v" "${!v}"
   done
   ```

   - 編集が必須なのは `OFFLINE_HOST` だけ。[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1 と同じ値を入れる
   - `OFFLINE_USER` も、[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1 で書き換えたなら、同じ値に書き換える
   - **新しいシェルを開いたら**、この項の手順 2 の 2 つのブロックを貼り直す

1. オンラインのホストから、転送を付けずにログインし直す。

   ```bash
   ssh "${OFFLINE_USER:?この項の手順 2 の OFFLINE_USER が空のまま}@${OFFLINE_HOST:?この項の手順 2 の OFFLINE_HOST が空のまま}"
   ```

   - オンラインのホストが Windows なら、この Bash のブロックの代わりに、PowerShell か cmd に `ssh <OFFLINE_USER>@<OFFLINE_HOST>` を打つ（[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 2 と同じユーザー・ホストを指定する）
   - **次の手順は、ログインしてから貼る**（続けて貼ると、ssh を閉じた後のオンライン側の元のシェルで動く）

1. オフラインのホストで、トンネルが無く、外に出られないことを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # トンネルの待ち受けを確かめる
   ss -Hltn 'sport = :1080'
   # 外部への接続を確かめる
   curl -sS -o /dev/null --connect-timeout 10 https://github.com && echo '届いた（オフラインではない）' || echo '届かない（期待どおり）'
   ```

   - `ss` は何も出さない
   - 最後の行は `届かない（期待どおり）`

<details id="ssh-の-socks-トンネル-の補足と注意点">
  <summary>SSH の SOCKS トンネル の補足と注意点</summary>

**注意点**

- 待ち受けが loopback だけでも、ユーザーを区別しない
- **外への通信の出口はオンラインのホスト**: オンラインのホストのネットワークの規則（社内のプロキシ、ファイアウォール）に従う。オンラインのホストの ssh が知るのは宛先の名前とポートで、HTTPS の中身は暗号化されたまま通る
- **`socks5h` の `h` を落とさない**: 落とすと名前を引けない
- **`https_proxy` や git の `http.proxy` が入っていると、そちらが勝つ**: [SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 3 の補足
- **`sudo` は `ALL_PROXY` を渡さない**: dnf は[SSH の SOCKS トンネル: dnf にもトンネルを使わせる](#ssh-の-socks-トンネル-dnf-にもトンネルを使わせる)の設定で、podman はコマンドの前の `https_proxy` で通す
- **npm は `ALL_PROXY` を読まない**: `https_proxy` を足す（[npm のオフライン導入](#npm-のオフライン導入)の手順 2）
- **dnf の節の行は残る**: トンネルが無い間は、dnf が `127.0.0.1 port 1080` につながらずに失敗する
- **ssh が切れると、トンネルも消える**: 取得の途中なら失敗するはず。そのときは[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 2 から張り直して、同じコマンドを貼り直す

**[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)のリード**

- これを前提にする項:
  - [Homebrew のオフライン導入](#homebrew-のオフライン導入)
  - [npm のオフライン導入](#npm-のオフライン導入)（Neovim の Mason が npm で入れるパッケージ。npm には `https_proxy` を足す）

- **2 台のホストで行う**。[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1・2 はオンラインのホストで、[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 3 は、[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 2 でログインしたオフラインのホストのシェルで貼る

- **[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 2 は ssh のログイン**。ログインしてから[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 3 を貼る

**[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1**

- 最後に値を読み戻して確かめる

**[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1: 変数について**

- オフラインのホストには変数が無い。ポート（1080）は変える必要が無いので、変数にせずコマンドに直接書いた（ポートを変えるときは[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 2 のコマンドも対象になる）
- `OFFLINE_USER` は、トンネルを使う手順書が決める。[Homebrew のオフライン導入](#homebrew-のオフライン導入) なら、Homebrew を使うユーザー（root ではログインしない）
- `OFFLINE_HOST` を書き換えたかを[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1 で確かめるのは、既定値のままでもエラーにならないため
- 変数はオンラインのホストのシェルの中だけで使う

**[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 3**

- `export` はこのシェルの中だけで有効。**ssh を張り直したら、[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 2 からやり直す**

**[SSH の SOCKS トンネル: dnf にもトンネルを使わせる](#ssh-の-socks-トンネル-dnf-にもトンネルを使わせる)の手順 1: 設定ファイルで渡す理由**

- `sudo` は `ALL_PROXY` を引き継がないので、dnf には `/etc/dnf/dnf.conf` で渡す
- この行がある間は、トンネルが無いと dnf がどのリポジトリにも届かなくなる

**[SSH の SOCKS トンネル: トンネルを閉じる](#ssh-の-socks-トンネル-トンネルを閉じる)の手順 1: 待ち受け**

- ssh のセッションが終わると、`127.0.0.1:1080` の待ち受けも消える

**[SSH の SOCKS トンネル: トンネルを閉じる](#ssh-の-socks-トンネル-トンネルを閉じる)の手順 2**

- 最後に値を読み戻して確かめる

**[SSH の SOCKS トンネル: トンネルを閉じる](#ssh-の-socks-トンネル-トンネルを閉じる)の手順 4: 出力の意味**

- `ss` が何も出さないのは、トンネルが無いこと

**選択した方針**

検証記録（`docs/verification/ssh-socks-tunnel.md` の「選択した方針」）

| 経路 | 要るもの | 採否 |
|---|---|---|
| **オンラインのホストから `ssh -R 1080`（逆向きの動的転送）** | オンラインのホストからオフラインのホストへ ssh でログインできること。どちらのホストにも追加のソフトは要らない | **採用。** オフラインのホストで curl・git・dnf・podman が外に届く。オフラインのホストが自分で取るので、2 台のアーキが違ってもよい |
| オフラインのホストから `ssh -D 1080` | オフラインのホストからオンラインのホストへ ssh でログインできること（オンラインのホストで sshd を動かす） | 不採用。ssh の向きが逆のときの代わりになる形だ |
| オンラインのホストに HTTP プロキシ（squid など）を建てる | オンラインのホストにデーモン、待ち受けのポート、アクセス制御 | 不採用。ssh の転送で足りる |

- **`ALL_PROXY` を `~/.bashrc` に書かない**: トンネルがあるのは[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 2 の ssh のセッションの間だけなので、[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 3 でそのシェルにだけ入れる
- **dnf には、`sudo` に環境変数を渡す（`sudo --preserve-env=ALL_PROXY`）のではなく、設定ファイルで渡す**: ほかの手順書の `sudo dnf install` を、書き換えずに貼れるようにするため

**参照**

- [OpenSSH 7.6 のリリースノート](https://www.openssh.org/txt/release-7.6) — `ssh -R` の逆向きの動的転送（SOCKS）が入った版。クライアントだけで実装されている（オフラインのホストの sshd の版は問わない）
- [ssh(1)](https://man.openbsd.org/ssh) — `-R`、`-o ExitOnForwardFailure`、`-o ControlPath`
- [sshd_config(5)](https://man.openbsd.org/sshd_config) — `AllowTcpForwarding`、`GatewayPorts`、`PermitListen`、`DisableForwarding`
- [curl(1) の ENVIRONMENT](https://curl.se/docs/manpage.html#ENVIRONMENT) — `ALL_PROXY` と `socks5h://`
- [git-config(1) の http.proxy](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httpproxy) — git がプロキシを読む順番
- `man dnf.conf` — `proxy`


- 検証記録（`docs/verification/ssh-socks-tunnel.md`）

</details>

---

## 再起動の後の確認

- 再起動して、通した項の設定が効いているかを確かめる

### 再起動と確認

- 再起動して、GNOME の表示と入力・日本語入力・システムの設定などが効いているかを確かめる
- 前提: [ログインと sudo](#ログインと-sudo)を通してある。確かめるのは、次の項のうち通したもの
  - [システムの設定](#システムの設定)・[日本語入力](#日本語入力)・[GNOME の表示と入力](#gnome-の表示と入力)
  - [WezTerm と HackGen Console NF をデスクトップで使う](shell-terminal.md#wezterm-と-hackgen-console-nf-をデスクトップで使う)・[Neovim](neovim.md#neovim)
  - [Homebrew](#homebrew)の手順 3
- 実行場所: この PC の画面（GNOME）。コマンドは、GNOME にログインした自分のユーザーの端末（bash）に貼る。この項の手順 8 は、WezTerm のタブで行う

1. 再起動する。

   ```bash
   sudo systemctl reboot
   ```

   - 保存していない文書のあるアプリが開いていると、`Operation inhibited by …` で断られることがある。そのアプリを閉じてから貼り直す
   - **次の手順は、起動してログインしてから行う**

1. ログインした画面で、上部バー・ウィンドウ・Dash が変わったことを確かめる。

   - 上部バーの時計に曜日と秒が出る。電池のある PC では、電池の % も出る（[GNOME の表示と入力](#gnome-の表示と入力)を通したとき）
   - 上部バーの右に、入力ソースの表示が出る（[日本語入力](#日本語入力)を通したとき）
   - 画面がダークになり、Super キーで開く Dash が[GNOME の表示と入力](#gnome-の表示と入力)の手順 14 の並びになっていればよい（その項を通したとき）
   - Dash の端末が WezTerm になっていればよい（[WezTerm と HackGen Console NF をデスクトップで使う](shell-terminal.md#wezterm-と-hackgen-console-nf-をデスクトップで使う)を通したとき）
   - Files などのウィンドウのタイトルバーの右に、最小化・最大化・閉じるの 3 つのボタンが出る（[GNOME の表示と入力](#gnome-の表示と入力)を通したとき。自分用の設定の WezTerm は、タブバーの右端に自分でボタンを描く）
   - 「標準フォルダーの名前を現在の言語に合わせて更新しますか?」の窓は出ない（[GNOME の表示と入力](#gnome-の表示と入力)を通したとき）。出たら、「次回から表示しない」をオンにして「古い名前のままにする」を押す

1. 端末を開き、再起動の後の状態を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # journal の起動履歴を確かめる
   journalctl --list-boots --no-pager | tail -n 2
   # クラッシュ用メモリーの予約を確かめる
   cat /sys/kernel/kexec_crash_size
   # ホスト名とダウンロード先を確かめる
   hostnamectl --static
   xdg-user-dir DOWNLOAD
   # Anthy の登録と起動に使う PATH を確かめる
   ibus list-engine | grep -w anthy
   IBUS_PID="$(pgrep -u "$(id -u)" -x ibus-daemon | head -n 1)"
   if [ -n "$IBUS_PID" ]; then
     IBUS_PATH="$(tr '\0' '\n' < "/proc/$IBUS_PID/environ" | grep '^PATH=')"
     printf '%s\n' "$IBUS_PATH"
     env "$IBUS_PATH" /usr/libexec/ibus-engine-anthy --xml | grep -m 1 -o '<name>[^<]*</name>'
   else
     echo 'ibus-daemon が動いていない（GNOME にログインしてから貼り直す）'
   fi
   # トレイアイコンの拡張と拡大率の設定を確かめる
   gnome-extensions info appindicatorsupport@rgcjonas.gmail.com | grep -E '^ *(状態|State)'
   /usr/bin/gsettings get org.gnome.mutter experimental-features
   ```

   - `journalctl --list-boots` に 2 行出る（前の起動のログが残っている。[システムの設定](#システムの設定)の手順 5 を通したとき）
   - `0` が出る（[システムの設定](#システムの設定)の手順 7 で kdump を止めたとき）
   - [システムの設定](#システムの設定)の手順 2 の名前が出る（名前を変えたとき）
   - `/home/<USER>/Downloads` が出る（[GNOME の表示と入力](#gnome-の表示と入力)を通したとき）
   - `anthy - Anthy` が出る（[日本語入力](#日本語入力)を通したとき）
   - `PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin` と `<name>anthy</name>` が出る（[日本語入力](#日本語入力)と、[Homebrew](#homebrew)の手順 3 を通したとき）
   - PATH に `/home/linuxbrew/` が入っていたり、`ModuleNotFoundError: No module named 'gi'` が出たりしたら、[Homebrew](#homebrew)の手順 3 を貼って、この項の手順 1 の再起動からやり直す
   - `ibus-daemon が動いていない` と出たら、GNOME にログインしてから、この手順を貼り直す
   - トレイアイコンの拡張が `ACTIVE` になっている（[GNOME の表示と入力](#gnome-の表示と入力)を通したとき）
   - `['scale-monitor-framebuffer', 'xwayland-native-scaling']` が出る（[GNOME の表示と入力](#gnome-の表示と入力)を通したとき）

1. 拡大率を変えるときだけ、設定の「ディスプレイ」の「スケーリング」で選ぶ。

   - アクティビティの画面で「設定」を開き、「ディスプレイ」→「スケーリング」で 125% などを選ぶ（125%・150% などが出るのは、[GNOME の表示と入力](#gnome-の表示と入力)を通したとき）
   - 上に出る「適用」を押し、「この表示設定を保存しますか?」の窓で「変更を保存」を押す（押さないと、しばらくして元に戻る）
   - 選べる拡大率は、画面の解像度で決まる（解像度の低い画面では 100% しか出ないことがある）

1. キーボードで、Caps Lock・Alt+Tab・Ctrl+Alt+T を確かめる。

   - テキストエディターに何か打ち、Caps Lock を押したまま A を押すと、全部が選ばれる（Ctrl+A）。Caps Lock だけを押しても大文字にならない（[GNOME の表示と入力](#gnome-の表示と入力)を通したとき）
   - ウィンドウを 2 つ以上開いて Alt+Tab を押すと、ウィンドウごとに切り替わる（同じアプリの窓も別に並ぶ）。Super+Tab はアプリごと（[GNOME の表示と入力](#gnome-の表示と入力)を通したとき）
   - Ctrl+Alt+T で WezTerm の新しい窓が開く（[GNOME の表示と入力](#gnome-の表示と入力)と[WezTerm と HackGen Console NF をデスクトップで使う](shell-terminal.md#wezterm-と-hackgen-console-nf-をデスクトップで使う)を通したとき）

1. [日本語入力](#日本語入力)を通したときだけ、入力ソースを切り替えて、日本語を打ってみる。

   - Super+Space で「英語 (US)」と Anthy に切り替わる。[Neovim](neovim.md#neovim)の手順 2 を飛ばしたなら、[日本語入力](#日本語入力)の手順 3 の配列と Anthy
   - Anthy に切り替えてからテキストエディターなどで `nihongo` と打ち、Space を押すと「日本語」に変わり、Enter で確定する
   - Anthy は、ひらがなで始まる
   - 英字と日本語は Super+Space で切り替える。[Neovim](neovim.md#neovim)の手順 2 を通したときは、Neovim 内では `<C-j>` で切り替え、JIS キーボードでも US 配列で打つため、一部の記号は刻印と異なる

1. [GNOME の表示と入力](#gnome-の表示と入力)を通したときだけ、Files で、フォルダーの名前と、隠しファイルとフォルダーの並びを確かめる。

   - Files（アクティビティの画面で「ファイル」）でホームを開くと、`Desktop`・`Documents`・`Downloads` などの英語の名前のフォルダーが並び、日本語の名前のフォルダーは無い
   - `.bashrc`・`.config` などの隠しファイルも出て、フォルダーがファイルより先に並ぶ
   - 左のサイドバーにも `Documents`・`Downloads` などが並び、押すとそのフォルダーが開く

1. [Neovim](neovim.md#neovim)を通したときだけ、Neovim で、日本語の検索・整形と IME 連携を確かめる。

   - [LazyVim の日本語検索・整形・IME 連携を確かめる](neovim.md#lazyvim-の日本語検索整形ime-連携を確かめる)の全項を WezTerm のタブで行う
   - `/tmp/lazyvim-check.md` が無ければ、[LazyVim の設定を導入する](neovim.md#lazyvim-の設定を導入する)の手順 9 の `printf …` の行を貼ってから開く
   - `o` で足した行は保存せず、`:qa!` で閉じる

<details id="再起動と確認-の補足と注意点">
  <summary>再起動と確認 の補足と注意点</summary>

**[再起動と確認](#再起動と確認)の手順 1: 再起動で効くもの**

- [システムの設定](#システムの設定)の手順 7 の kdump のメモリー（外したとき）、[日本語入力](#日本語入力)の手順 2 で入れた ibus-anthy（入れたとき）、[GNOME の表示と入力](#gnome-の表示と入力)の手順 10 の拡大率、[GNOME の表示と入力](#gnome-の表示と入力)の手順 12 のトレイアイコン、[Flatpak と Flathub](#flatpak-と-flathub)の手順 4 の Flatseal のメニュー

**参照**

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

---

## 更新

- OS（BaseOS・AppStream・EPEL・RPM Fusion から入れたもの。`epel-release`・`rpmfusion-free-release` とトレイアイコンの拡張も）は[OS とファームウェアの更新](#os-とファームウェアの更新)の手順 1・2・3 を、ファームウェアは同じ項の手順 1・2 を貼り直す
- [dnf-automatic で自動で更新する](#dnf-automatic-で自動で更新する)を通したなら、OS の更新は毎日自動で入る（[OS とファームウェアの更新](#os-とファームウェアの更新)の手順 2 の `dnf needs-restarting -r` で要否を確かめ、要るときだけ同じ項の手順 3 で再起動する）
- EPEL の鍵をまだ取り込んでいなければ、`epel-release` が上がるときに確認を求められる（fingerprint は[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 1）
- Flatpak のアプリは `dnf upgrade` では上がらない（[共通の bash 設定・Homebrew・Flatpak を上げる](#共通の-bash-設定homebrewflatpak-を上げる)の手順 4）
- Firefox・WezTerm・GitHub CLI（それぞれのベンダーの dnf のリポジトリから入れたもの）と git・Node.js も、OS の更新で上がる
  - 1 つだけ上げるなら、名前を指定する（Firefox は言語パックと一緒に `sudo dnf upgrade firefox firefox-l10n-ja`）
  - Firefox の FFmpeg（RPM Fusion の `ffmpeg-libs`）も一緒に上がる。WezTerm の COPR は、`main` ブランチに追従して毎日〜数日おきにビルドされる
- VirtualBox・VirtualBox の bootc ゲスト・kvm-container は、仮想マシンのセットアップの[VirtualBox: 更新](virtual-machines.md#virtualbox-更新)・[VirtualBox の bootc ゲスト: 更新](virtual-machines.md#virtualbox-の-bootc-ゲスト-更新)・[kvm-container を更新する](virtual-machines.md#kvm-container-を更新する)で上げる
- Samba（`samba`・`cifs-utils` など）のパッケージと、GNOME のリモート操作で使う部品は、OS の更新で上がる
- コンテナ（Podman・podman-compose・podman-tui・lazydocker・Distrobox）は、[コンテナのセットアップ](containers.md)の各用途の「更新」で上げる
- HackGen Console NF・git-delta・Neovim・lazygit・yazi（Homebrew で入れたもの）は、[共通の bash 設定・Homebrew・Flatpak を上げる](#共通の-bash-設定homebrewflatpak-を上げる)の手順 3 で上がる
  - **Neovim の設定やプラグインは更新に追従しない**。メジャー更新の後は `:checkhealth` で壊れていないか見る
- 共通の bash 設定・シェルのツール・HackGen Console NF・WezTerm と自分用の WezTerm の設定の上げ方は、[シェルと端末のセットアップ](shell-terminal.md)の冒頭にまとめてある
- excel-diff は、[excel-diff を導入・更新する](#excel-diff-を導入更新する)の更新の箇条書きで上げる
- 自分用の設定のうち、lazygit・yazi は[lazygit の設定を更新する](#lazygit-の設定を更新する)・[yazi の設定を更新する](#yazi-の設定を更新する)で合わせる。Neovim のプラグインと外部コマンドは[LazyVimStarter の更新手順](neovim.md#lazyvim-の本体外部コマンドプラグインを更新する)
  - yazi の [README の「上流の新しい版に追従する」](https://github.com/ryo-aoki-pc/yazi#上流の新しい版に追従する)は、持ち主が 1 台で行う作業。ほかの PC の clone は[yazi の設定を更新する](#yazi-の設定を更新する)で合わせる

### 共通の bash 設定・Homebrew・Flatpak を上げる

- 共通の bash 設定と、Homebrew・Flatpak で入れたものを上げる
- 前提: [共通の bash 設定](shell-terminal.md#共通の-bash-設定)・[Homebrew](#homebrew)・[Flatpak と Flathub](#flatpak-と-flathub)のうち、上げるものを通してある
- 実行場所: 開き直した、自分のユーザーの端末（bash）。開き直し方は[シェルのツール](shell-terminal.md#シェルのツール)の手順 2 と同じ
- 入れたものの手順だけを行う。共通の bash 設定はこの項の手順 1、Homebrew は手順 2・3、Flatpak は手順 4

1. 共通の bash 設定を入れたときだけ、上げる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   git -C ~/.config/bash pull --ff-only
   ```

   - `Already up to date.`（上がったときは、変わったファイルの一覧）が出る
   - 上がったときは、端末を開き直すと効く
   - `install.sh` は初回の導入用なので流さない
   - SSH で clone したホストと、root にも入れたホストは、その項の手順で上げる

1. Homebrew を入れたときだけ、Homebrew 自身と formula の索引を更新し、上げられるものを見る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   brew update
   brew outdated
   ```

   - `brew update` が `Already up-to-date.` を返し、`brew outdated` が無出力なら、上げるものは無いので、この項の手順 3 は飛ばす
   - インターネットに出られないホストでは、[Homebrew のオフライン導入の更新](#homebrew-のオフライン導入-更新)で行う

1. Homebrew で上げるものがあるときだけ、入れたものを上げる。

   ```bash
   brew upgrade
   ```

   - 特定のものだけなら `brew upgrade <formula>`
   - `[y/n]` と聞かれたら、`y` を押す（Enter は要らない）

1. Flatpak と Flathub を通したときだけ、Flatpak で入れたアプリを上げる。

   ```bash
   sudo flatpak update
   ```

   - 更新が無ければ `Nothing to do.` で終わる
   - 更新があれば `[Y/n]` と聞かれる。`y`

<details id="共通の-bash-設定homebrewflatpak-を上げる-の補足と注意点">
  <summary>共通の bash 設定・Homebrew・Flatpak を上げる の補足と注意点</summary>

**[共通の bash 設定・Homebrew・Flatpak を上げる](#共通の-bash-設定homebrewflatpak-を上げる)の手順 1**

- [共通の bash 設定を更新する](shell-terminal.md#共通の-bash-設定を更新する)と同じ pull だけを行う。`install.sh` は初回の導入用なので流さない（流し直すと、移す行があるときは、控えの `~/.bashrc.before-bash` が既にあるので止まる）

**[共通の bash 設定・Homebrew・Flatpak を上げる](#共通の-bash-設定homebrewflatpak-を上げる)の手順 2: 自動更新**

- `brew install` / `brew upgrade` は既定で自動更新が走るので、普段は `brew update` を明示しなくてよい（抑えるには `HOMEBREW_NO_AUTO_UPDATE=1`）

**[共通の bash 設定・Homebrew・Flatpak を上げる](#共通の-bash-設定homebrewflatpak-を上げる)の手順 2: 先に確認する**

- `brew outdated` で先に確認できる

**[共通の bash 設定・Homebrew・Flatpak を上げる](#共通の-bash-設定homebrewflatpak-を上げる)の手順 3: 確認と、上げた後の tmux・fzf・zoxide**

- `[y/n]` を聞く条件は[Homebrew の補足と注意点](#homebrew-の補足と注意点)の「注意点」
- 動いている tmux のサーバーは、前の版のまま動き続ける。新しい版を使うのは、セッションを全部閉じて `tmux ls` が `no server running on …` になってから
- fzf は、開いているシェルには前の版の `fzf --bash` が読まれたまま。新しい端末から新しい版になる。zoxide のデータベース（`~/.local/share/zoxide/db.zo`）は更新で消えない

**参照**

- 検証記録（`docs/verification/almalinux-setup.md`）

</details>

---
