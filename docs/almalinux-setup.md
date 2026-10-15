# AlmaLinux 10 のセットアップ

- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md)・[参考資料](reference/almalinux-setup.md)・[ロールバックと注意点](extra/almalinux-setup.md)

> [!IMPORTANT]
> - 前提: AlmaLinux 10 Workstation を入れた PC と、インターネット接続。オフラインの Homebrew は[別手順](#homebrew-のオフライン導入)を使う
> - **GNOME にログインした、インストール時の管理者ユーザー（`wheel`）の bash で行う**。`sudo -i`・`su -` のシェルでは行わない

- どの項も単独で通せる。目的の項のリードの前提を先に満たす
- 新しく入れた PC では、カテゴリを上から順に、要る項を選んで通す
- 対話・GUI・再起動は各手順の案内に従い、プロンプトに戻ってから次へ進む
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 新しい端末では、使う項の変数の手順を貼り直す
- Windows 11 は[Windows の初期設定](windows-setup.md)から指定された項だけを使う
- AI コーディングエージェント（Claude Code・Codex CLI・Grok Build）は、[AI コーディングエージェントのセットアップ](ai-agents.md)で入れる
- 仮想マシン（VirtualBox・VirtualBox の bootc ゲスト・kvm-container）は、[仮想マシンのセットアップ](virtual-machines.md)で入れる
- Forgejo のサーバーは、[Forgejo のセットアップ](forgejo.md)で動かす
- 共通の bash 設定・シェルのツール・HackGen Console NF・WezTerm は、[シェルと端末のセットアップ](shell-terminal.md#almalinux-10-で使う)で入れる
- GNOME のリモート操作（デスクトップ共有・ヘッドレスセッション・リモートログイン）・WireGuard・Neovim・Samba・Syncthing は、[GNOME のリモート操作のセットアップ](gnome-remote.md)・[WireGuard のセットアップ](wireguard.md)・[Neovim のセットアップ](neovim.md)・[Samba のセットアップ](samba.md)・[Syncthing のセットアップ](syncthing.md)で入れる
- 入れたものを上げるときは、[更新](#更新)の案内に従う

> [!WARNING]
> - [ログインと sudo](#ログインと-sudo)の手順 3 の後は、**このユーザーのプログラムがパスワード無しで root 権限を使える**。人が触れる場所の PC や信用できないプログラムを使うユーザーでは行わない
> - sudo のパスワード入力は「ログインと sudo」の手順 3 だけ。元に戻すときは[ロールバック](extra/almalinux-setup.md#ロールバック)の最後の手順

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

   - `[sudo] <USER> のパスワード:` にはログインのパスワードを入れる
   - `stdin: 正しく構文解析されました`（英語では `parsed OK`）、`/etc/sudoers`・`/etc/sudoers.d/nopasswd`、最後に `sudo はパスワードを聞かない` が出ればよい
   - `中断:` が出たら、何も書いていない。インストールのときに管理者にしたユーザーでログインし直して、この項の手順 2 から
   - **次の手順は、パスワードを入れて、プロンプトに戻ってから貼る**（続けて貼ると、パスワードとして食われる）

---

### OS とファームウェアの更新

- OS のパッケージを最新にし、ファームウェアの更新があれば入れて、要るときだけ再起動する
- 前提: [ログインと sudo](#ログインと-sudo)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）

1. OS を最新にする。

   ```bash
   sudo dnf upgrade --refresh
   ```

   - 更新するものの一覧（トランザクション表）の後に `これでよろしいですか? [y/N]:` と聞かれる。`y`
   - インストールの後の最初の更新では、続けて AlmaLinux の署名鍵の取り込みを聞かれる（`GPG 鍵 0xC2A1E572 をインポート中:`）
     - `Userid : "AlmaLinux OS 10 <packager@almalinux.org>"` と `Fingerprint: EE6D B7B9 8F5B F5ED D9DA 0DE5 DEE5 C11C C2A1 E572` を確かめてから `y`（[AlmaLinux の Security のページ](https://almalinux.org/security/)の値と同じ）。違っていれば `N` で中断する
   - `行うべきことはありません。` と出たら、更新は無い（`[y/N]` も、署名鍵の確認も出ない）
     - このときは、AlmaLinux の署名鍵は、[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 1 で取り込まれる
   - **次の手順は、`完了しました!` が出てプロンプトに戻ってから貼る**（続けて貼ると、`[y/N]` の答えとして食われる）

1. ファームウェアの情報（LVFS のメタデータ）を取り直す。

   ```bash
   sudo fwupdmgr refresh --force
   ```

   - 初めてのときは `現在リモートが有効になっていないため、メタデータが利用できません。` に続けて `このリモートを有効にしますか? [Y|n]:` と聞かれる。`Y`
   - `新しいメタデータのダウンロードに成功しました:` と、更新できる機器の数が出る（VirtualBox の VM では `更新可能なデバイスはありません`。Hyper-V と VMware の VM では `N 個のデバイスが更新可能です` と出て、この項の手順 3 で `UEFI dbx` の更新を聞かれることがある）
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

---

### システムの設定

- PC の名前・SSH の待ち受け・ログ（journal）の保存・kdump・コマンドが無いときの案内を設定する
- 前提: [ログインと sudo](#ログインと-sudo)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）

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

   - 最後に値を読み戻して確かめる
   - `HOST_NAME` を変えないなら空のままにして、この項の手順 2 を飛ばす
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

---

### EPEL と RPM Fusion

- EPEL と RPM Fusion（free）のリポジトリを、署名鍵を確かめてから入れる
- 前提: [ログインと sudo](#ログインと-sudo)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）

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
   - [OS とファームウェアの更新](#os-とファームウェアの更新)の手順 1 で更新が無かったときは、ここで AlmaLinux の署名鍵が、確認を求めずに取り込まれる（「確認」の見出しより前の dnf の出力に、`GPG 鍵 0xC2A1E572 をインポート中:` と出る）
     - その出力の `Fingerprint:` が `EE6D B7B9 8F5B F5ED D9DA 0DE5 DEE5 C11C C2A1 E572` であることを確かめる。違っていれば、ここで中断する（鍵は取り込まれた後なので、次の手順へ進まない）
   - EPEL の署名鍵は、EPEL からパッケージを初めて入れるとき（この文書では[GNOME の表示と入力](#gnome-の表示と入力)の手順 11）に、dnf が 1 回だけ確認を求める
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

---

### Flatpak と Flathub

- flatpak を確かめ、署名鍵を確かめてから Flathub を system に登録し、確認用のアプリ（Flatseal）で動きを確かめる
- 前提: [ログインと sudo](#ログインと-sudo)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）

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
   - 最初の 1 本は runtime ごと落とすので、`/var/lib/flatpak` が 1.7 GB ほどになる（runtime が GNOME 50 のとき）。要らなければ、この手順とこの項の手順 5 は飛ばしてよい
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
| `sudo flatpak override --reset <ID>` | 足した権限を元に戻す |
| `sudo flatpak uninstall <ID>` | 消す |
| `sudo flatpak uninstall --unused` | もう誰も使っていない runtime を消す |

- `flatpak` の読み取り系（`search` / `list` / `info` / `remote-ls`）は `sudo` 無しで動く
- Flathub を登録した直後に `flatpak search flatseal` が `No matches found` を返す場合は、`sudo flatpak update --appstream` で検索用のメタデータを取得してから検索し直す。`sudo flatpak update` を 1 度実行したあとも、同じように検索できるようになる

---

### Homebrew

- Homebrew を公式のインストーラで `/home/linuxbrew/.linuxbrew` に入れ、共通の bash 設定で PATH を通す
- 前提: [ログインと sudo](#ログインと-sudo)と[共通の bash 設定](shell-terminal.md#共通の-bash-設定)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）
- インターネットに出られない PC は、この項を飛ばし、[Homebrew のオフライン導入](#homebrew-のオフライン導入)を通す
- **GNOME で日本語入力を使う PC は、この項の手順 4 を飛ばさない**。Homebrew が既に入っていても、IBus の PATH 固定まで行う

1. Homebrew の依存パッケージを入れる。

   ```bash
   sudo dnf install -y procps-ng curl file git
   ```

   - Workstation では、どれも入っている（`は既にインストールされています。` と出る）

1. Homebrew の公式のインストーラを実行する。

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

   - インストーラは続行の確認で `RETURN` を求める
   - `==> Installation successful!` と `==> Next steps:` が出ればよい。`Next steps` の `~/.bashrc` への追記は行わない
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

1. IBus の GNOME 向けユーザーサービスの PATH を、Homebrew を含まない固定値にする。

   ```bash
   {
     mkdir -p ~/.config/systemd/user/org.freedesktop.IBus.session.GNOME.service.d
     printf '%s\n' '[Service]' 'Environment=PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin' > ~/.config/systemd/user/org.freedesktop.IBus.session.GNOME.service.d/10-system-path.conf
     systemctl --user daemon-reload
     printf '\n\033[7m 確認 \033[0m\n'
     systemctl --user show org.freedesktop.IBus.session.GNOME.service -p Environment
   }
   ```

   - `Environment=PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin` が出ればよい
   - GNOME で日本語入力を使う PC では、この手順を飛ばさない（理由は[参考資料](reference/almalinux-setup.md#homebrew--手順-4-補足-ibus-の-path-を固定する理由)）
   - 効くのは、[再起動と確認](#再起動と確認)の手順 1 の再起動の後

#### Homebrew の使い方の基本

この文書の各項が使うコマンドはこれだけ。

| コマンド | 用途 |
|---|---|
| `brew install <formula>` | 入れる。ビルド済みのボトルがあれば `Pouring ...` と出て、ソースビルドは走らない |
| `brew uninstall <formula>` | 消す。Homebrew 7.0.7 では、不要になった依存も既定で自動削除する（[注意点](extra/almalinux-setup.md#注意点)） |
| `brew list --versions` | 入っているものと版の一覧 |
| `brew leaves` | ほかの導入済み formula や cask から依存されていない formula の一覧。明示的に入れたものの履歴ではない |
| `brew info <formula>` | 版・依存・caveat（[gdu](#gdu) のような名前の注意書き） |
| `brew deps --tree <formula>` | 依存の木。単独で入れたときに何が付いてくるか |
| `brew outdated` | 更新できるものの一覧。何も無ければ無出力 |
| `brew autoremove` | 依存として入って、もう誰も使っていないものを消す（`--dry-run` で確認できる） |

- `brew install`・`brew upgrade` などの管理操作は、導入した一般ユーザーで行う
- [Homebrew を sudo でも使う](#homebrew-を-sudo-でも使う)を通しても、管理操作は一般ユーザーで行う
- 入れたコマンドを root のシェルでも使うなら [Homebrew を root のシェルでも使う](#homebrew-を-root-のシェルでも使う)を、`sudo <コマンド>` で使うなら [Homebrew を sudo でも使う](#homebrew-を-sudo-でも使う)を通す
- `brew install` の確認が出たら答えてから進む（[確認が出る条件](extra/almalinux-setup.md#注意点)）
- Homebrew からツールを入れる手順は、[Homebrew](#homebrew)の手順 1〜3 を前提にする。Trivy は dnf で入れる

#### Homebrew を root のシェルでも使う

- root のログインシェルでも、Homebrew で入れたコマンドを使う。PATH は、root に入れた共通の bash 設定が足す
- 前提: [Homebrew](#homebrew)と[共通の bash 設定を root に入れる](shell-terminal.md#共通の-bash-設定を-root-に入れる)（root 自身の clone と読み込み口）を通してある
- 実行場所: Homebrew を入れた自分のユーザーの端末（bash）
- 自分専用のマシンで、一般ユーザーを信用できる場合だけ行う。root のシェルから Homebrew のユーザー所有のコマンドを実行するため
- 共通設定の `brew shellenv` は Homebrew を PATH の先頭に入れる。同名の RPM コマンドより Homebrew が優先される
- `sudo <コマンド>` は別で、[Homebrew を sudo でも使う](#homebrew-を-sudo-でも使う)の `secure_path` を使う

1. root のログインシェルから Homebrew が見えることを確かめる。

   ```bash
   sudo -i bash -c 'printenv PATH; command -v brew'
   ```

   - `/home/linuxbrew/.linuxbrew/bin/brew` が出ればよい。`/root/.bashrc` に PATH の行は追記しない
   - `brew install` などは一般ユーザーで行う

1. root の共通設定も外す場合だけ、bash のロールバックを行う。

   - [root の導入手順](shell-terminal.md#共通の-bash-設定を-root-に入れる)のロールバックを参照する

#### Homebrew を sudo でも使う

- sudo の設定に 1 行のファイル（`/etc/sudoers.d/homebrew`）を置き、sudo がコマンドを探す PATH（`secure_path`）の末尾に、Homebrew の `bin` と `sbin` を足す
- 前提: [Homebrew](#homebrew)の手順 1〜3 を通してある
- 実行場所: Homebrew を入れた自分のユーザーの端末（bash）
- **`sudo <コマンド>` で Homebrew のコマンドを使わないなら、この項は不要**
- `sudo nvim /etc/hosts` や `sudo gdu-go /` のように、`sudo <コマンド>` で使えるようになる。`sudo -s`・`sudo -i` で開いた root のシェルでも使える
- `EDITOR=nvim` の `sudoedit` も、自分の設定の Homebrew の `nvim` で開くようになる（この項の前は、黙って `vi` で開く）
- sudo を通らない `su -`、コンソールや ssh での root のログインには効かない。そちらは [Homebrew を root のシェルでも使う](#homebrew-を-root-のシェルでも使う)を通す
- RPM にも同じ名前のコマンドがあると、`sudo` では RPM のほうが使われる
- `brew install` などの管理操作は、この項を通しても一般ユーザーで行う（通常のホストでは `sudo brew install` などを `Running Homebrew as root is extremely dangerous …` で断られる）
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
     - `既にある` なら、この項は通してある。最後の 2 行で確かめる
     - `既定と違う` なら、`secure_path` がほかで変えてある（`sudo grep -rn secure_path /etc/sudoers /etc/sudoers.d` で探す）。そのホストでは、この項は使わない
   - 開いたままの root のシェル（`sudo -s` など）には効かない。開き直す

1. 元に戻すときは、この項の手順 1 で置いたファイルを消す。

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

### Homebrew のオフライン導入

- インターネットに出られないホスト（以下、オフラインのホスト）に、SSH の SOCKS トンネル越しに Homebrew を入れる。トンネルの出口は、インターネットに出られるホスト（以下、オンラインのホスト）
- 前提: [SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1〜3 を、接続元をオンラインのホスト、接続先をオフラインのホストとして通してある。オフラインのホストには、[共通の bash 設定](shell-terminal.md#共通の-bash-設定)の手順 1・2 を、そのトンネルのシェルで通してある
- 実行場所: トンネルを張ってログインした、オフラインのホストの自分のユーザーのシェル（`ALL_PROXY` を入れたシェル。Homebrew の通信にもトンネルを使う）。この項の手順 5 には、オンラインのホストで行う操作がある
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/homebrew-offline.md)・[参考資料](reference/homebrew-offline.md)・[ロールバックと注意点](extra/homebrew-offline.md)
- この項の手順 3 で貼る[Homebrew](#homebrew)の手順 1〜4（同じ項の手順 4 は、GNOME で日本語入力を使う PC だけ）も、同じシェルのまま貼る
- **オフラインのホストには、`sudo` できる自分のユーザーでログインする**（[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1 の `OFFLINE_USER`）。root ではログインしない（Homebrew の導入・更新は root では行わない）
- **この項の手順 3・4 には対話入力がある**（インストーラの `RETURN`、brew の `[y/n]`）。終わってから次の手順を貼る
- Neovim の Mason に npm のパッケージを入れるなら、この項の手順 5 でトンネルを閉じる前に、このシェルで [npm のオフライン導入](#npm-のオフライン導入) を貼る（npm は `ALL_PROXY` を読まない）

> [!WARNING]
>
> - トンネルを張っている間は、オフラインのホストのどのユーザーもインターネットに出られる（出口はオンラインのホスト。[SSH の SOCKS トンネルの注意点](extra/ssh-socks-tunnel.md#注意点)）。使い終わったら、この項の手順 5 で閉じる

1. トンネルのシェルで、Homebrew の取得先に届くかと、Homebrew が使うパッケージを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   for u in https://github.com https://raw.githubusercontent.com https://formulae.brew.sh https://ghcr.io/v2/; do
     printf '%-34s %s\n' "$u" "$(curl -sS -o /dev/null --connect-timeout 10 -w '%{http_code}' "$u")"
   done
   rpm -q procps-ng curl file git
   ```

   - 4 つの URL の数字が、どれも `000` 以外なら届いている（ghcr.io は `401`）
   - `000` と `Failed to connect to 127.0.0.1 port 1080` が出たら、トンネルか `ALL_PROXY` が無い。[SOCKS トンネル](#ssh-の-socks-トンネル)の手順 2 からやり直す
   - `rpm -q` の 4 つがどれも入っていれば、**この項の手順 2 は飛ばし、この項の手順 3 でも[Homebrew](#homebrew)の手順 1 を飛ばす**
   - dnf がトンネル無しで届くリポジトリ（社内のミラーなど）を使うホストなら、この項の手順 2 は飛ばす

1. この項の手順 1 で入っていないパッケージがあったときだけ、[SSH の SOCKS トンネルの「dnf にもトンネルを使わせる」](#ssh-の-socks-トンネル-dnf-にもトンネルを使わせる)を行う。

   - **次の手順は、その項の `Metadata cache created.` が出てから貼る**

1. この項の手順 1 のシェルのまま、[Homebrew](#homebrew)の手順 1〜4 を貼る。

   - `command -v brew` が `/home/linuxbrew/.linuxbrew/bin/brew` を返すなら、[Homebrew](#homebrew)の手順 1〜3 は飛ばす
   - [Homebrew](#homebrew)の手順 1 の dnf は、この項の手順 2 の設定で通る（この項の手順 1 で 4 つとも入っていたなら飛ばす）
   - [Homebrew](#homebrew)の手順 3 は、[共通の bash 設定](shell-terminal.md#共通の-bash-設定)の手順 1・2 を入れてあるシェルで貼る
   - [Homebrew](#homebrew)の手順 4 は、GNOME で日本語入力を使う PC だけで貼る。Homebrew が入っていても、この手順は飛ばさない
   - **次の手順は、[Homebrew](#homebrew)の手順 3（GNOME で日本語入力を使う PC は同じ項の手順 4）まで終えてから貼る**（同じ項の手順 2 に `RETURN` の確認がある）

1. 確かめるために、brew で jq をトンネル越しに入れる。

   ```bash
   brew install jq
   ```

   - 入れるものの一覧の後に `==> Do you want to proceed with the installation? [y/n]` と聞かれたら、`y` を押す（Enter は要らない）
   - `==> Pouring jq--…bottle…tar.gz` と出て、ソースからのビルドにならない
   - ほかの Homebrew で入れる項も、この項の手順 5 の前に、このシェルで貼る
   - **次の手順は、確認が出たら `y` を押し、入れ終わってから貼る**（続けて貼ると、後ろの行の文字が答えとして読まれる）

1. [SSH の SOCKS トンネルの「トンネルを閉じる」](#ssh-の-socks-トンネル-トンネルを閉じる)の手順 1〜4 で、トンネルを閉じて、転送を付けずにログインし直す。

   - その項で `exit` した後の、転送を付けないログインは、オンラインのホストで行う
   - その項の最後の確かめで、`ss` が何も出さず、`届かない（期待どおり）` になることを確かめる
   - **次の手順は、ログインし直したオフラインのホストのシェルで貼る**

1. オフラインのホストで、トンネルが無くても jq が動くことを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   brew list --versions jq
   command -v jq
   echo '{"host": "offline"}' | jq -r .host
   ```

   - `jq 1.8.2` のような版、`/home/linuxbrew/.linuxbrew/bin/jq`、`offline` が出る

#### Homebrew のオフライン導入: 更新

- オフラインのホストで、SSH の SOCKS トンネル越しに Homebrew と、Homebrew で入れたものを上げる
- 前提: [Homebrew のオフライン導入](#homebrew-のオフライン導入)を通してある。[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1〜3 で、トンネルを張り直してある
- 実行場所: トンネルを張ってログインした、オフラインのホストの自分のユーザーのシェル（`ALL_PROXY` を入れたシェル）

1. [共通の bash 設定・Homebrew・Flatpak を上げる](#共通の-bash-設定homebrewflatpak-を上げる)の手順 2・3 を貼る。

   - `brew outdated` が何も出さなければ、上げるものは無いので、[共通の bash 設定・Homebrew・Flatpak を上げる](#共通の-bash-設定homebrewflatpak-を上げる)の手順 3 は飛ばす
   - `brew upgrade` が `[y/n]` と聞いたら、`y` を押す（[Homebrew のオフライン導入](#homebrew-のオフライン導入)の手順 4 と同じ確認）
   - **次の手順は、上げ終わってから行う**（続けて貼ると、後ろの行の文字が答えとして読まれる）

1. [SSH の SOCKS トンネルの「トンネルを閉じる」](#ssh-の-socks-トンネル-トンネルを閉じる)の手順 1 で、トンネルを閉じる。

---

### dnf-automatic で自動で更新する

- BaseOS の `dnf-automatic` のタイマーで、毎日、更新をダウンロードして入れる。再起動はしない（カーネルなどの更新は、[OS とファームウェアの更新](#os-とファームウェアの更新)の手順 4・5 で自分で再起動する）
- 前提: [ログインと sudo](#ログインと-sudo)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）
- GNOME Software の自動の更新（裏でダウンロードし、再起動のときに入れる）は、この項の手順 3 で止める（二重にしない）
- 戻すときは、この項の手順 5・6

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

### Secure Boot の署名鍵

- Secure Boot が有効な PC（または VM）で、自分でビルドしたカーネルモジュールを読み込めるように、署名用の鍵を作って MOK に登録する
- 前提: [ログインと sudo](#ログインと-sudo)を通してある（bootc のシステムでは、`sudo` できるユーザーでログインしてある）
- 実行場所: Secure Boot を使う PC（または VM）の、自分のユーザーの端末（bash）か SSH
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/secure-boot-mok.md)・[参考資料](reference/secure-boot-mok.md)・[ロールバックと注意点](extra/secure-boot-mok.md)
- **カーネルモジュールをビルドする項より先に通す**。この項の手順 3 で Secure Boot が無効と分かったら、この項はそこで終わり
- bootc のシステム（AlmaLinux Atomic Desktop など）でも同じ手順になる
- **この項の手順 4 で一時パスワードを 2 回聞かれ、この項の手順 5 で再起動する**。答えてから次の手順を貼る
- 通すと使えるようになるもの（この鍵で署名したモジュールが、Secure Boot のまま読み込まれる）:
  - [VirtualBox](virtual-machines.md#virtualbox) のホストのモジュール（`vboxdrv` など）
  - [VirtualBox Guest Additions（bootc のゲスト）](virtual-machines.md#virtualbox-の-bootc-ゲスト) のモジュール（`vboxguest` など）

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
   if sudo test -e /var/lib/shim-signed/mok/MOK.der; then echo '中断: 鍵が既にある。作り直さずに、手順 7 で登録を確かめる' >&2; else
     sudo mkdir -m 0700 -p /var/lib/shim-signed/mok
     sudo openssl req -nodes -new -x509 -newkey rsa:2048 -outform DER -addext "extendedKeyUsage=codeSigning" -subj "/CN=Local kernel module signing key/" -days 36500 -keyout /var/lib/shim-signed/mok/MOK.priv -out /var/lib/shim-signed/mok/MOK.der
     printf '\n\033[7m 確認 \033[0m\n'
     sudo ls -l /var/lib/shim-signed/mok
     sudo mokutil --import /var/lib/shim-signed/mok/MOK.der
   fi
   ```

   - 鍵を作る間は `.....+++` のような行が流れる
   - `MOK.priv`（秘密鍵。`-rw-------`）と `MOK.der`（公開鍵の証明書）ができる
   - **`MOK.priv` は登録した鍵で信頼するモジュールを作れる秘密鍵**。root 以外に読ませず、ほかのマシンに持ち出さない
   - **場所とファイル名は変えない**
   - **一時パスワードを 2 回聞かれる**（手順 6 の MokManager で 1 回だけ使う。本書には残さない）
   - `中断: 鍵が既にある` と出たら、前に作った鍵がある。手順 7 へ進む
   - ホストオンリーだけの VM は、この手順の代わりに[オフラインビルド](virtual-machines.md#virtualbox-の-bootc-ゲスト-ホストオンリーアダプターだけの-vm-でビルドする)の手順 2〜5 を通す
   - 鍵はホストで作り、証明書だけを VM に置いて予約する。手順 5 からは同じ
   - **次の手順は、一時パスワードに答えてから貼る**（続けて貼ると答えとして食われる）

1. 再起動する。

   ```bash
   sudo systemctl reboot
   ```

   - 起動の途中で青い **MokManager** の画面が出る（手順 6）

1. 起動の途中の MokManager で、鍵を登録する。

   - 最初の画面の `Press any key to perform MOK management` は、`Booting in 10 seconds` から数え下げて 10 秒で消える。消える前に何かキーを押す（VM なら、VM のウィンドウで押す）
   - 続けて `Enroll MOK` → `Continue` → `Yes` → 手順 4 の一時パスワード → `Reboot` と進む
   - **何もしないで進むと登録されない**。そのときは `sudo mokutil --import /var/lib/shim-signed/mok/MOK.der`（手順 4 の最後の行）を貼り直してから、手順 5 からやり直す
   - **注意**: MokManager でキーボードが効かない PC がある（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/secure-boot-mok.md#実施手順--手順-6-補足-画面の並びと登録できなかった-pc)の手順 6 の補足を参照）
   - **次の手順は、起動したらログインし、新しい端末を開いてから貼る**

1. 鍵が登録されたか確かめる。

   ```bash
   sudo mokutil --test-key /var/lib/shim-signed/mok/MOK.der
   ```

   - `/var/lib/shim-signed/mok/MOK.der is already enrolled` が出れば、登録できている
   - 登録できていなければ `is not enrolled` になる。手順 6 の箇条書きのとおりやり直す
   - `sudo` が要る。鍵のディレクトリは root だけが入れる（`drwx------`）

---

### ユーザーサービスの常駐

- 自分のユーザーの linger を有効にして、ログアウトしている間も、そのユーザーのサービスが動くようにする
- 前提: [ログインと sudo](#ログインと-sudo)を通してある
- 実行場所: 常駐させるユーザー自身のシェル（デスクトップの端末か SSH の bash）
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/linger.md)・[参考資料](reference/linger.md)・[ロールバックと注意点](extra/linger.md)
- 通すと使えるようになるもの（ログアウトしている間も動く）:
  - [Syncthing](syncthing.md#syncthing)・[Dropbox 公式](#dropbox)・[rclone](#dropbox-と-rclone)
  - [Forgejo](forgejo.md#forgejo)・[Grok のブラウザ操作](ai-agents.md#grok-build-のブラウザ操作-実施手順)
  - [Podman の Quadlet](#podman-quadlet-で自動起動する)で動かすコンテナ

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
   {
     sudo loginctl enable-linger "${USER}"
     printf '\n\033[7m 確認 \033[0m\n'
     loginctl show-user "$(id -u)" -p Linger
     ls /var/lib/systemd/linger
   }
   ```

   - `enable-linger` は何も出さない
   - `Linger=yes` と、自分のユーザー名が出ればよい

---

## GNOME のデスクトップ

- 日本語入力と、GNOME の表示・入力・電源の設定

### 日本語入力

- GNOME で日本語を打てるように、Anthy と日本語のフォントを入れ、入力ソースを「キーボードの配列 + Anthy」にする
- 前提: [ログインと sudo](#ログインと-sudo)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）
- **Homebrew を入れた（これから入れる）PC では、[Homebrew](#homebrew)の手順 4 も通す**。Homebrew が既に入っていても、IBus の PATH 固定まで行う

1. 変数を設定する。

   ```bash
   XKB_LAYOUT=$(localectl status 2>/dev/null | sed -n 's/^ *X11 Layout: \([a-z][a-z0-9_]*\).*/\1/p')   # キーボードの配列（自動）。JIS は jp、US は us。<XKB_LAYOUT>
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'XKB_LAYOUT = %s\n' "${XKB_LAYOUT}"
   ```

   - 最後に値を読み戻して確かめる
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
   if [ -z "${XKB_LAYOUT}" ]; then echo '中断: この項の手順 1 の XKB_LAYOUT が空のまま。値を入れて貼り直す' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     /usr/bin/gsettings get org.gnome.desktop.input-sources sources
     /usr/bin/gsettings set org.gnome.desktop.input-sources sources "[('xkb', '${XKB_LAYOUT}'), ('ibus', 'anthy')]"
     /usr/bin/gsettings get org.gnome.desktop.input-sources sources
     /usr/bin/gsettings get org.gnome.desktop.wm.keybindings switch-input-source
   fi
   ```

   - 最初の `get` は変える前の値（最初のログインの後は、今の配列だけの `[('xkb', 'us')]` など）。戻すときのために控えておく
   - 2 つ目の `get` が `[('xkb', 'jp'), ('ibus', 'anthy')]`（US 配列なら `'us'`）になればよい
   - **ほかの入力ソースは消える**。残すものは `set` の値に足す
   - **注意**: `/usr/bin/` を外さない（[GNOME の表示と入力](#gnome-の表示と入力)の手順 1〜14 も同じ）
   - [Neovim](neovim.md#neovim)の手順 3 では、JIS 配列でも入力ソースが「英語 (US)」と Anthy に変わる

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

   - **編集が必須の変数は無い**。既定のままなら、Dash に Firefox・ファイル・端末（Ptyxis）・テキストエディターが並ぶ
   - 最後に値を読み戻して確かめる
   - **新しい端末を開いたら**、この項の手順 1 を貼り直してから先へ進む

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
   - `user-dirs.dirs` の 8 行が `$HOME/` の下の `Desktop`・`Downloads`・`Templates`・`Public`・`Documents`・`Music`・`Pictures`・`Videos` を指し、ブックマークも英語の名前を指せばよい
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
   - 入るのは `gnome-shell-extension-appindicator` と、依存の 3 つ（`libappindicator-gtk3`・`libdbusmenu`・`libdbusmenu-gtk3`）
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

   - 一覧に `'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal/'` と、`binding '<Control><Alt>t'`・`command 'ptyxis --new-window'`・`name '端末'` が出ればよい

1. Dash のお気に入り（アクティビティの画面の下の並び）を、この項の手順 1 のアプリにする。

   ```bash
   if [ -z "${DASH_FAVORITES}" ]; then echo '中断: この項の手順 1 の DASH_FAVORITES が空のまま。値を入れて貼り直す' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     /usr/bin/gsettings get org.gnome.shell favorite-apps
     /usr/bin/gsettings set org.gnome.shell favorite-apps "${DASH_FAVORITES}"
     /usr/bin/gsettings get org.gnome.shell favorite-apps
   fi
   ```

   - 最初の `get` の並びを、元に戻すときのために控える
   - 2 つ目の `get` がこの項の手順 1 の値になればよい。すぐに効く

---

### 画面オフ・画面ロック・自動サスペンドを止める

- 常時動かしておく PC で、GNOME が画面を消したり、ロックしたり、放置で眠ったりしないようにする。ログイン画面・蓋・OS のサスペンドも止める
  - WireGuard・Samba・Syncthing・Dropbox のホストや、RDP で待ち受ける PC は、眠るとサービスが止まる
  - [GNOME のヘッドレスのセッション](gnome-remote.md#gnome-のヘッドレスセッション)はこの項の手順 1・2 が前提。サスペンドできる PC では手順 3・4 も通す
  - [Claude Code で GUI を確かめる](ai-agents.md#claude-code-の-gnome-操作-実施手順)はこの項の手順 1・2、[GNOME のデスクトップ共有](gnome-remote.md#gnome-のデスクトップ共有)は手順 1〜4 が前提
- 前提: [ログインと sudo](#ログインと-sudo)を通してある
- 実行場所: GNOME にログインするユーザー本人の端末（bash）。この項の手順 1 で変数を設定したシェルに貼る
- **人が触れる場所にある PC では行わない**（画面をロックしないので、前にいる人がそのまま使える）
- GNOME を入れていない（デスクトップの無い）機械では、この項の手順 4・5 だけを行う
- 戻すときは、この項の手順 6〜9。変える前の値ではなく**既定値**に戻る（Server with GUI で入れた PC は、既定でも電源につないでいる間は眠らない）

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
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、この項の手順 1 のブロックを貼り直してから先へ進む

1. 自分のセッションの画面オフ・減光・ロック・自動サスペンド・電源ボタンを変える。

   ```bash
   /usr/bin/gsettings set org.gnome.desktop.session idle-delay "${IDLE_DELAY:?この項の手順 1 の IDLE_DELAY が空のまま。値を入れて貼り直す}"
   /usr/bin/gsettings set org.gnome.desktop.screensaver lock-enabled "${LOCK_ENABLED:?この項の手順 1 の LOCK_ENABLED が空のまま。値を入れて貼り直す}"
   /usr/bin/gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
   /usr/bin/gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type nothing
   /usr/bin/gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type nothing
   /usr/bin/gsettings set org.gnome.settings-daemon.plugins.power power-button-action "${POWER_BUTTON:?この項の手順 1 の POWER_BUTTON が空のまま。値を入れて貼り直す}"
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get org.gnome.desktop.session idle-delay
   /usr/bin/gsettings get org.gnome.desktop.screensaver lock-enabled
   /usr/bin/gsettings list-recursively org.gnome.settings-daemon.plugins.power | grep -E 'idle-dim|sleep-inactive-(ac|battery)-type|power-button-action'
   ```

   - `uint32 0`、`false`、続いて `idle-dim false`・`power-button-action 'interactive'`・`sleep-inactive-ac-type 'nothing'`・`sleep-inactive-battery-type 'nothing'` の 4 行が出ればよい
   - 値が変わっていなければ、デスクトップの端末でこの項の手順 1 から貼り直す
   - **注意**: `/usr/bin/` を外さない

1. ログイン画面（GDM）用の設定を書き、dconf を作り直して、ログイン画面から見える値を確かめる。

   ```bash
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

## Git と開発の道具

- Git・git-delta・GitHub CLI・lazygit・yazi・mdtable・ShellCheck と shfmt・VS Code と、オフラインの npm。Neovim（LazyVim）は、[Neovim のセットアップ](neovim.md)で入れる

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
   - **この項の手順 3〜5 のキーと `pull.ff` の元の値・スコープ・ファイルを控える**。`global` に無ければ「global は未設定」と控える（[ロールバック](extra/almalinux-setup.md#git-の道具を消す)で使う）
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
   git -c core.autocrlf=true status --short
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
   git rm -r -q --cached .
   git reset -q --hard
   printf '\n\033[7m 確認 \033[0m\n'
   git ls-files --eol | grep -c 'i/lf *w/crlf'
   git status --short
   ```

   - 数は `0` になる
   - `git status --short` は、もともとあった `??` の行以外は出さない

1. この項の手順 2 で保存成功の表示が出たときだけ、今回の変更を戻す。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   git stash pop
   git ls-files --eol
   ```

   - `git status` の形で、元の変更だけが出る
   - 戻したファイルも `w/lf` になる
   - この項の手順 2 からここまでは、別の stash を作らない

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

   - **編集が必須の変数は無い**。既定のままで進められる
   - 広い画面で左右に並べたいなら、`DELTA_SIDE_BY_SIDE=true` にする
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこの項の手順 1 を貼り直す

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
   git -C ~/.config/bash show --format= | delta --paging=never | head -20
   ```

   - 版は `delta 0.19.2` / `git-delta 0.19.2` のように出る
   - ファイル名のヘッダと、行ごとに背景色の付いた差分が出る
   - 差分の行が出ないときは、`git -C ~/.config/bash log -1 --oneline` で最後のコミットを確かめる。差分を持たないコミット（マージコミットなど）なら、この差分表示の確認は飛ばす（その場合の出力は VM では確かめていない）
   - **`git diff` を単体で打ったときは、端末に直接出る場合だけ delta を通る**。`git diff | head` のようにパイプに繋ぐと git はページャを呼ばないので、素の差分が出る

#### git-delta の設定ファイル

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

### GitHub CLI

- GitHub の dnf のリポジトリから GitHub CLI（`gh`）を入れ、GitHub にログインする
- 前提: GitHub のアカウントを用意し、[ログインと sudo](#ログインと-sudo)を通してある
  - この項の手順 4 のブラウザ認証には、このホストのブラウザ（[Firefox](#firefox)）か、手元のブラウザを使う
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ

1. `dnf config-manager` を使えるようにし、リポジトリを追加する。

   ```bash
   {
     sudo dnf install -y 'dnf-command(config-manager)'
     printf '\n\033[7m 確認 \033[0m\n'
     sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
     cat /etc/yum.repos.d/gh-cli.repo
   }
   ```

   - `repo の追加: https://cli.github.com/packages/rpm/gh-cli.repo` と出て、`/etc/yum.repos.d/gh-cli.repo` ができる
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
   - 1 つ目の鍵を取り込むと、`警告: Certificate 23F3D4EA75716059:` と、次の行に `The certificate is expired: …` が出る（2026-09-05 に期限が切れている）。導入は続く
   - **次の手順は、答えてから貼る**（続けて貼ると答えとして食われる）

1. GitHub へのログインを始める。

   ```bash
   gh auth login
   ```

   - 対話で GitHub.com / HTTPS / ブラウザ認証を選ぶ
   - `Authenticate Git with your GitHub credentials?` は `Y`。外すときは[ロールバックの「Git の道具を消す」](extra/almalinux-setup.md#git-の道具を消す)の手順 6
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

   - [Neovim](neovim.md#neovim)の手順 3 で入っていれば、`Warning: lazygit … is already installed and up-to-date.` と出て何も変えない
   - **次の手順は、Homebrew の確認が出たら答え、導入が成功してプロンプトに戻ってから貼る**（続けて貼ると確認の答えとして食われる）

1. 自分用の設定（[ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit)）を入れる。

   - [lazygit の設定を導入する](#lazygit-の設定を導入する)の全項を通す
   - 差分の表示に delta（[git-delta](#git-delta)）、アイコンに Nerd Fonts（[HackGen Console NF](shell-terminal.md#hackgen-console-nf)）を使う設定
   - `e` キーで開くエディタは、`EDITOR`（[Neovim](neovim.md#neovim)の手順 4）から決まる

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

   - 初回に `Thanks for using lazygit...` の案内が出たら Enter で閉じる（この項の手順 2 の設定を入れていれば、出ない）。ファイル・変更差分・ブランチ・コミットの一覧が出ればよい
   - **注意**: git 管理下でないディレクトリで起動すると、リポジトリを作るか聞かれる
   - `q` で終了する
   - **次の手順は、`q` で終了してから貼る**（続けて貼ると lazygit への操作として食われる）

#### lazygit の設定ファイル

- パッケージは設定ファイルを置かない。無ければ組み込みの既定値で動く
- 置き場所は `~/.config/lazygit/config.yml`（`lazygit --print-config-dir` で確認できる）
- Windows 11 は `%LOCALAPPDATA%\lazygit\config.yml`（`%APPDATA%\lazygit\config.yml` があれば、そちらも読む）。`state.yml` も同じフォルダー
- Windows 11 の場所は[初期設定の「lazygit」](windows-setup.md#lazygit)の手順 6 で確かめる
- **自分用の設定**は [ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit) にある（公式の既定の全項目に、あいまい検索・Nerd Fonts のアイコン・マウス無効などの変更を載せた `config.yml`）
  - 導入は[lazygit](#lazygit)の手順 2。`config.yml` を `~/.config/lazygit/config.yml` にリンクする
  - Windows 11 は[初期設定の「lazygit」](windows-setup.md#lazygit)の手順 5。リンクにせず `%LOCALAPPDATA%\lazygit` に直接 clone する
  - 何を変えたかは [設定のリポジトリの参考資料の「主な設定内容」](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/reference/readme.md#主な設定内容)
  - アイコンに Nerd Fonts が要る（`gui.nerdFontsVersion: "3"`）。端末のフォントを HackGen Console NF（[HackGen Console NF](shell-terminal.md#hackgen-console-nf)）にする
    - Windows 11 への導入は[HackGen Console NF](shell-terminal.md#windows-11-で-hackgen-console-nf-を入れる)。WezTerm は自分用の設定で変わる
    - Windows Terminal のフォントは[シェルと端末のセットアップの「Windows Terminal のフォントと貼り付けの警告を変える」](shell-terminal.md#windows-terminal-のフォントと貼り付けの警告を変える)で変える
  - 差分に delta を使う（[AlmaLinux](#git-delta)・[Windows 11](windows-setup.md#git-delta)）。Windows の引用符は[設定例](https://github.com/ryo-aoki-pc/lazygit#windows-で使う場合)を参照する
  - `e` キーで開くエディタは、`EDITOR` などから自動で決まる（[Neovim](neovim.md#neovim)の手順 4）
    - Windows 11 で Windows PowerShell から起動するなら、[Neovim のセットアップの「Neovim を既定のエディタにする」](neovim.md#neovim-を既定のエディタにする)で、ユーザーの環境変数 `EDITOR` を `nvim` にする

#### lazygit の設定を導入する

- 自分用の lazygit の設定（[ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit)）を `~/lazygit-config` に clone し、`~/.config/lazygit/config.yml` にリンクする
- 前提: [lazygit](#lazygit)の手順 1 で lazygit を入れ、[git-delta](#git-delta)と[HackGen Console NF](shell-terminal.md#hackgen-console-nf)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ。この項の手順 1 の前の、既存の `config.yml` の確認と退避を省かない

> [!CAUTION]
> - この項の手順 1 は既存の `~/.config/lazygit/config.yml` を置き換える
> - 残す通常ファイルがある場合は止め、別名へ退避してから、この項の手順 1 を貼る

1. 設定を clone してリンクする。

   ```bash
   git clone https://github.com/ryo-aoki-pc/lazygit.git ~/lazygit-config
   mkdir -p ~/.config/lazygit
   ln -sf ~/lazygit-config/config.yml ~/.config/lazygit/config.yml
   ```

   - 設定の置き場所は `lazygit --print-config-dir` で確かめる
   - `e` キーのエディタは `EDITOR` から決まる
   - 一時的に試すなら `lazygit --use-config-file ~/lazygit-config/config.yml` を使う

#### lazygit の Excel 差分表示を導入する

- 設定のリポジトリ（`~/lazygit-config`）のスクリプトで、Git と lazygit が Excel のブックの差分をテキストで出せるようにする
- 前提: [lazygit の設定を導入する](#lazygit-の設定を導入する)を通してある（`~/lazygit-config` を使う）。Python 3.9 以上と git が要る
  - 部分ステージ（[lazygit で Excel のセル変更を部分ステージする](#lazygit-で-excel-のセル変更を部分ステージする)）には、lazygit 0.66.0 以上・delta 0.20.1 以上も要る
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）。`sudo` は、ensurepip で止まったときの `python3-pip` の導入だけで使う

1. 設定リポジトリで Excel の差分表示を導入して確かめる。

   ```bash
   (
     cd ~/lazygit-config &&
       python3 --version &&
       python3 scripts/setup-excel-diff.py &&
       python3 scripts/setup-excel-diff.py --check
   )
   ```

   - 仮想環境の作成が ensurepip で止まる場合は `sudo dnf install python3-pip` を行って再実行する
   - Git 全体の textconv・alias・属性を設定し、依存はリポジトリ外の仮想環境へ入れる
   - 同期したリポジトリでも端末ごとに一度実施し、スクリプトを更新したら再実行する
   - `--check` は読み取りだけの確認

#### lazygit で Excel の差分を確かめる

- Excel のブックのある Git リポジトリで、ブックの差分がシートとセル番地の付いたテキストで出ることを確かめる
- 前提: [lazygit の Excel 差分表示を導入する](#lazygit-の-excel-差分表示を導入する)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）の、ブックのある Git リポジトリのディレクトリ。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ

1. Excel のある Git リポジトリで差分を確かめる（`売上表.xlsx` は実際のファイル名）。

   ```bash
   git check-attr diff -- "売上表.xlsx"
   git diff -- "売上表.xlsx"
   git diff --cached -- "売上表.xlsx"
   ```

   - 最初に `売上表.xlsx: diff: excel` が出て、差分に `Sheet:` とセル番地が出ればよい
   - lazygit を開き直してファイルを選ぶと delta で表示する。`|` の内蔵表示でも Excel のテキスト差分が出る
   - `unset` や別のドライバーが出たら、そのリポジトリの `.gitattributes`・`.git/info/attributes` を確認する
   - そのリポジトリだけに設定するなら、`.git/info/attributes` に `*.[xX][lL][sS][xX] diff=excel` を足す
   - 全体をステージするには、lazygit の**ファイル一覧で `Space`** を押す
   - **通常差分の `Enter` から行・ハンクのステージや破棄を行わない**。既存 Excel にはパッチを適用できず、新規ファイルはテキストをステージしてしまう場合がある
   - `diff.excel.binary=true` でも、この操作は禁止されない。部分ステージは[専用画面](#lazygit-で-excel-のセル変更を部分ステージする)の `E` で行う
   - 対応形式と制限は[Excel 差分の仕様](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/excel-diff.md)を参照する

#### lazygit で Excel のセル変更を部分ステージする

- lazygit の専用画面で、Excel のブックのセルの変更を選んで index に入れる
- 前提: [lazygit](#lazygit)・[git-delta](#git-delta)・[lazygit の Excel 差分表示を導入する](#lazygit-の-excel-差分表示を導入する)を通してある（lazygit 0.66.0 以上・delta 0.20.1 以上）
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）で、ブックのある Git リポジトリを開いた lazygit。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ
- 対象は HEAD と index にある既存 `.xlsx` / `.xlsm` / `.xltx` / `.xltm`
- 新規ファイルは全体をコミットしてから使う

1. lazygit のファイル一覧で対象を選び、`E` を押す。

   - 端末から開くなら `git excel-stage -- "売上表.xlsx"`。実際のファイル名に置き換える
   - 専用画面が開くまで待つ。大きいブックでは「Excel を読み込んでいます」と出る

1. 専用画面で `Enter` → `Space` を押してハンクを選ぶ。

   - 左右の矢印で移動し、ステージ済み差分を確認する
   - 値・通常の数式の変更だけを選べる。置換は削除・追加の両方を選ぶ
   - 書式・画像・マクロ・行列の挿入や移動を反映する場合は、元のファイル一覧で全体をステージする
   - 対応できない変更は index を変更せず中断する。[対応条件と制限](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/extra/excel-diff.md)を確認する

1. 選択を確認して専用画面の `X` で適用し、`q` で戻る。

   - `X` の前に `q` で閉じれば選択を取り消す
   - 作業中の Excel は変えず、index 側の書式・画像・マクロを保持する
   - 開いた後に対象の index・作業ファイルが変わった場合は中断する。閉じて `E` から開き直す
   - 選んだ文字列セルのふりがなは引き継がない。未選択のセルは保持する
   - 次に Excel で開いたときに再計算する。スクリプトはマクロ・外部リンク更新・数式再計算を実行しない

#### lazygit で大きな Excel の変換を待つ

- 大きなブックの差分を、全セルの変換が終わるまで待ってから出す
- 前提: [lazygit の Excel 差分表示を導入する](#lazygit-の-excel-差分表示を導入する)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）の、ブックのある Git リポジトリのディレクトリ。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ

1. 全セルの変換を待って差分を表示する（`売上表.xlsx` は実際のファイル名）。

   ```bash
   EXCEL_TEXTCONV_TIMEOUT=0 git diff -- "売上表.xlsx"
   ```

   - 通常の変換中のブックは、完了後に選び直すか `R` で表示する
   - この環境変数は、このコマンドにだけ適用する

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
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこの項の手順 1 を貼り直す

1. brew で yazi と、プレビュー・検索に使うツールを入れる。

   ```bash
   brew install yazi ${YAZI_EXTRAS}
   ```

   - fd・ripgrep（[LazyVim の設定を導入する](neovim.md#lazyvim-の設定を導入する)の手順 5）と fzf（[シェルのツール](shell-terminal.md#シェルのツール)の手順 1）を入れてあれば、`Warning: fd … is already installed and up-to-date.` のように出る
   - 依存を合わせて 170 個ほどが入り、数分から 10 分ほどかかる
   - **次の手順は、確認が出たら表示された導入予定を確かめて `y` と答え、プロンプトに戻ってから貼る**（続けて貼ると確認の答えとして食われる。[Homebrew の注意点](extra/almalinux-setup.md#注意点)）

1. 自分用の設定（[ryo-aoki-pc/yazi](https://github.com/ryo-aoki-pc/yazi)）を入れる。

   - [yazi の設定を導入する](#yazi-の設定を導入する)の全項を通す
   - ファイルを開くエディタは nvim（[Neovim](neovim.md#neovim)）、`z` と `Z` のキーは fzf と zoxide（[シェルのツール](shell-terminal.md#シェルのツール)の手順 1）を使う

1. WezTerm で新しいタブを開き、y 関数を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   type -t y
   ```

   - `function` が出ればよい。`~/.bashrc` への関数の追記は不要
   - **`. ~/.bashrc` で読み直さず、新しいタブで `y` を確かめる**（[シェルのツール](shell-terminal.md#シェルのツール)の手順 2）

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

#### yazi の設定ファイル

- パッケージは設定ファイルを置かない。無ければ組み込みの既定値で動く
- 置き場所は `~/.config/yazi/` で、ファイル名は `yazi.toml`（全般）/ `keymap.toml`（キー割り当て）/ `theme.toml`（配色）
- Windows 11 の置き場所は `%APPDATA%\yazi\config\`（Windows の yazi は `XDG_CONFIG_HOME` を見ない。別の場所にするなら `YAZI_CONFIG_HOME` に絶対パスを入れる）
  - 状態は `%APPDATA%\yazi\state`、キャッシュは `%LOCALAPPDATA%\yazi`
  - yazi が読む場所は `ya env` の `Config` の行で確かめられる（[Windows 11 の初期設定の「yazi」](windows-setup.md#yazi)の手順 7）
- **既定値のファイルは配布物に入っていない**。変更する項目だけを設定ファイルに書く
- 既定値は[公式ドキュメントの Configuration](https://yazi-rs.github.io/docs/configuration/overview/) か、リポジトリの `yazi-config/preset/` を見る
- **自分用の設定**は [ryo-aoki-pc/yazi](https://github.com/ryo-aoki-pc/yazi) にある（上流の既定の設定を丸ごと置き、3 ペインの比率・行表示・独自のキー割り当てなどを変えた設定）
  - 導入は[yazi](#yazi)の手順 3。`custom` を `~/.config/yazi` に clone する
  - Windows 11 は[初期設定の「yazi」](windows-setup.md#yazi)の手順 6。`custom` を `%APPDATA%\yazi\config` に clone する
  - キーは[独自キーバインド](https://github.com/ryo-aoki-pc/yazi/blob/custom/docs/reference/readme.md#独自キーバインド抜粋)、外部コマンドは[依存コマンド](https://github.com/ryo-aoki-pc/yazi#依存コマンド)を参照する
  - fd・ripgrep・fzf は[yazi](#yazi)の手順 2、nvim は[Neovim](neovim.md#neovim)、zoxide と fzf のキー操作は[シェルのツール](shell-terminal.md#シェルのツール)で入れる
    - Windows 11 の Git Bash の fzf のキー操作と zoxide は、[シェルと端末のセットアップの「シェルのツールを入れる」](shell-terminal.md#シェルのツールを入れる)で入る（zoxide は 0.9.9 に止める）
  - Windows 11 では、`O`（対話的に開く）の候補に Neovide も出る。選んで使うなら、Neovide（scoop の extras の `neovide`）を入れておく

#### yazi の設定を導入する

- 自分用の yazi の設定（[ryo-aoki-pc/yazi](https://github.com/ryo-aoki-pc/yazi) の `custom` ブランチ）を `~/.config/yazi` に clone する
- 前提: [yazi](#yazi)の手順 1・2 で yazi と依存ツールを入れてある。ファイルを開くエディタに nvim（[Neovim](neovim.md#neovim)）、`z` と `Z` のキーに fzf と zoxide（[シェルのツール](shell-terminal.md#シェルのツール)の手順 1）を使う
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ。既存の `~/.config/yazi` の確認と退避を省かない

1. yazi を終了し、自分用の設定を clone する。

   ```bash
   git clone -b custom https://github.com/ryo-aoki-pc/yazi.git ~/.config/yazi
   ```

   - `custom` ブランチを使う。導入先は `~/.config/yazi`
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

   - `l` / `<Enter>` で選択した複数ファイルを開く。追記前はホバー中の 1 ファイルだけを開く

---

### mdtable

- GLFM の Markdown の表を、Excel のブックにして編集し、Markdown へ戻す（[md-table-excel](https://github.com/ryo-aoki-pc/md-table-excel)）

#### mdtable を導入・更新する

- `mdtable` を `~/md-table-excel` に clone し、専用の仮想環境に入れて確かめる。更新も、この項の手順 1 で行う
- 前提: Python 3.9 以上と git が入っている（git は[Homebrew](#homebrew)の手順 1 で入る）
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）。`sudo` は、ensurepip で止まったときの `python3-pip` の導入だけで使う。更新では、`~/md-table-excel` の手元の変更の確認を省かない

1. リポジトリを clone し、導入して確かめる。

   ```bash
   git clone https://github.com/ryo-aoki-pc/md-table-excel.git ~/md-table-excel
   (
     cd ~/md-table-excel &&
       python3 scripts/setup-mdtable.py &&
       python3 scripts/setup-mdtable.py --check
   )
   ```

   - ensurepip で止まったら `sudo dnf install python3-pip` を行う
   - 依存はリポジトリ外の専用仮想環境へ入る
   - 起動コマンドは `~/.local/bin`。PATH に無いときは案内に従って加える
   - `--check` は何も変更せず状態を確かめる
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

   - ブックに記録した Markdown に書き戻す。書き戻す先は `--md` で変えられる
   - 書き出し後に Markdown の表を変えていたら、衝突として書き戻さない。**`--force` はブックの内容で上書きする**
   - 取り込み済みのブックは「適用済み」になる。取り込み後のブックは消してよい

---

### ShellCheck と shfmt

- シェルスクリプトの静的検査の ShellCheck と、整形の shfmt を Homebrew で入れ、自分のスクリプトを検査する
- 前提: [Homebrew](#homebrew)を通し、PATH に Homebrew が入った端末（[シェルのツール](shell-terminal.md#シェルのツール)の手順 2 で開き直した端末）を開いてある。`command -v brew` で何も出なければ、先に通す
  - この項の手順 5 の JSON の集計には `jq` が要る。`command -v jq` で何も出なければ、[導入元一覧の jq](tool-catalog.md#cli-定番の置き換え) を先に入れる
- 実行場所: 前提の端末（GNOME にログインした自分のユーザーの bash）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/shellcheck.md)・[参考資料](reference/shellcheck.md)・[ロールバックと注意点](extra/shellcheck.md)

> [!IMPORTANT]
> - **自分のシェルで実行する**。Homebrew の導入・管理は一般ユーザーで行う

1. 変数を設定する（`SC_TARGET` は必ず値を入れる）。

   ```bash
   SC_TARGET=scripts/wireguard/wg-vpn.sh   # 検査するスクリプト。自分のパスに変える。<SC_TARGET>
   ```

   ```bash
   SC_SEVERITY=style        # -S に渡す最低重大度。style だと全部出る。error / warning / info / style。<SC_SEVERITY>
   SHFMT_INDENT=2           # shfmt -i のインデント幅。0 ならタブ。<SHFMT_INDENT>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in SC_TARGET SC_SEVERITY SHFMT_INDENT; do printf '%-13s = %s\n' "$v" "${!v}"; done
   ```

   - **編集が必須なのは、検査対象のパス `SC_TARGET` だけ**。自分のリポジトリのスクリプトに変える
   - 残りは既定のままでよい
   - 最後に値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこの項の手順 1 の 2 つのブロックを貼り直す

1. ShellCheck と shfmt を入れる。

   ```bash
   brew install shellcheck shfmt
   ```

   - **次の手順は、Homebrew の確認が出たら答え、導入が成功してプロンプトに戻ってから貼る**（続けて貼ると確認の答えとして食われる）

1. 2 つが入ったか確かめ、わざと欠陥のあるコードで検出できるかを見る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   shellcheck --version
   shfmt --version
   command -v shellcheck shfmt
   brew list --versions shellcheck shfmt
   printf '#!/bin/bash\nx=$(ls)\necho $x\n' | shellcheck -
   echo "rc=$?"
   printf '#!/bin/bash\nif true; then\necho a\nfi\n' | shfmt -i 2 -d -
   echo "rc=$?"
   ```

   - `version: 0.11.0` と `3.14.1` が出る
   - ShellCheck は `SC2086 (info): Double quote to prevent globbing and word splitting.` が 1 件出て **`rc=1`** になる
   - shfmt は字下げを足す差分が出て `rc=1` になる

1. スクリプトを、bash の構文チェックと ShellCheck で検査する。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   bash -n "${SC_TARGET:?手順 1 の SC_TARGET が空のまま。値を入れて貼り直す}"
   echo "rc=$?"
   shellcheck -x "${SC_TARGET}"
   echo "rc=$?"
   ```

   - 1 つ目の `rc=0` なら構文としては通っている
   - **警告が 0 件なら何も出ずに `rc=0` で終わる**

1. 件数だけ見たいときと、重大度で絞りたいときは、JSON で数えて `-S` で絞る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   if [ -z "${SC_TARGET}" ] || [ -z "${SC_SEVERITY}" ]; then
     echo '中断: 手順 1 の SC_TARGET と SC_SEVERITY を設定してから貼り直す' >&2
   elif ! command -v jq >/dev/null 2>&1; then
     echo '中断: jq が無い。リードの導入元一覧から入れて貼り直す' >&2
   else
     shellcheck -x -f json "${SC_TARGET}" | jq 'length'
     shellcheck -x -f json "${SC_TARGET}" | jq -r '.[] | "\(.level) \(.code)"' | sort | uniq -c | sort -rn
     shellcheck -x -S "${SC_SEVERITY}" "${SC_TARGET}" | head -20
   fi
   ```

#### ShellCheck と shfmt: shfmt で整形を確かめる

- shfmt で、スクリプトの今の書き方と整形した結果との違いを見て、`-w` の上書きを一時ディレクトリの複製で試す
- 前提: [ShellCheck と shfmt](#shellcheck-と-shfmt)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ
- **`-d` は差分を出すだけでファイルを変えない**

> [!WARNING]
> **`-w` は元のファイルを上書きする。** いきなり本番のスクリプトに掛けない。**この項の**手順 3 は、一時ディレクトリの複製に掛けて挙動を見る。

1. 変数を設定する（`SC_TARGET` は必ず値を入れる）。

   ```bash
   SC_TARGET=scripts/wireguard/wg-vpn.sh   # 検査するスクリプト。自分のパスに変える。<SC_TARGET>
   ```

   ```bash
   SHFMT_INDENT=2           # shfmt -i のインデント幅。0 ならタブ。<SHFMT_INDENT>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in SC_TARGET SHFMT_INDENT; do printf '%-13s = %s\n' "$v" "${!v}"; done
   ```

   - [ShellCheck と shfmt](#shellcheck-と-shfmt)の手順 1 と同じ値を入れる
   - **編集が必須なのは、検査対象のパス `SC_TARGET` だけ**
   - 最後に値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこの項の手順 1 の 2 つのブロックを貼り直す

1. 今の書き方とどれだけ違うかを見て、整形対象になるファイルを一覧する。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   if [ -z "${SC_TARGET}" ] || [ -z "${SHFMT_INDENT}" ]; then
     echo '中断: この項の手順 1 の SC_TARGET と SHFMT_INDENT を設定してから貼り直す' >&2
   else
     shfmt -i "${SHFMT_INDENT}" -d "${SC_TARGET}" | wc -l
     shfmt -i "${SHFMT_INDENT}" -d "${SC_TARGET}" | head -30
     shfmt -f "$(dirname -- "${SC_TARGET}")" | head
     shfmt -l -i "${SHFMT_INDENT}" "$(dirname -- "${SC_TARGET}")"
   fi
   ```

1. 一時ディレクトリに複製して、`-w` の挙動を見る。

   ```bash
   if [ -z "${SC_TARGET}" ] || [ -z "${SHFMT_INDENT}" ]; then
     echo '中断: この項の手順 1 の SC_TARGET と SHFMT_INDENT を設定してから貼り直す' >&2
   else
     SHFMT_TMP=$(mktemp -d)
     cp "${SC_TARGET}" "${SHFMT_TMP}/copy.sh"
     shfmt -i "${SHFMT_INDENT}" -w "${SHFMT_TMP}/copy.sh"
     printf '\n\033[7m 確認 \033[0m\n'
     diff <(wc -l < "${SC_TARGET}") <(wc -l < "${SHFMT_TMP}/copy.sh")
     rm -rf "${SHFMT_TMP}"
   fi
   ```

   - 行数がどれだけ増減するかが出る
   - **差分が大きいときは、そのスクリプトの書き方と shfmt の既定が合っていない**（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/shellcheck.md)・[参考資料](reference/shellcheck.md)の shfmt の項を見る）

#### ShellCheck と shfmt: 検査を調整する

- ShellCheck の指摘を、1 行だけ（ディレクティブ）か、リポジトリ全体（`.shellcheckrc`）で黙らせる書き方を確かめる
- 前提: [ShellCheck と shfmt](#shellcheck-と-shfmt)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ

1. 変数を設定する（`SC_TARGET` は必ず値を入れる）。

   ```bash
   SC_TARGET=scripts/wireguard/wg-vpn.sh   # 検査するスクリプト。自分のパスに変える。<SC_TARGET>
   ```

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'SC_TARGET = %s\n' "${SC_TARGET}"
   ```

   - [ShellCheck と shfmt](#shellcheck-と-shfmt)の手順 1 と同じ値を入れる
   - 最後に値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこの項の手順 1 の 2 つのブロックを貼り直す

1. 1 行だけ黙らせるディレクティブの例を、検査対象の中から探す。

   ```bash
   grep -n 'shellcheck disable' "${SC_TARGET}"
   ```

   - **1 行だけ黙らせる**には、その行の直前にディレクティブを置く
   - `# shellcheck disable=SC1090` のような行が出る
   - 複数まとめるならカンマ区切り（`disable=SC2086,SC2034`）

1. リポジトリ全体に効かせるときは、`.shellcheckrc` の挙動を一時ディレクトリで確かめる。

   ```bash
   SC_TMP=$(mktemp -d)
   cp "${SC_TARGET}" "${SC_TMP}/target.sh"
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'disable=SC2034\nexternal-sources=true\nsource-path=SCRIPTDIR\n' > "${SC_TMP}/.shellcheckrc"
   (cd "${SC_TMP}" && shellcheck -x target.sh; echo "rc=$?")
   rm -rf "${SC_TMP}"
   ```

   - **リポジトリ全体に効かせる**なら `.shellcheckrc` を置く
   - `disable` に挙げたコードの指摘が消える。元から対象の指摘が無い場合は `rc` は変わらない

#### ShellCheck と shfmt: 更新

- Homebrew で入れた ShellCheck と shfmt を上げる
- 前提: [Homebrew](#homebrew)と[ShellCheck と shfmt](#shellcheck-と-shfmt)を通し、PATH に Homebrew が入った端末（[シェルのツール](shell-terminal.md#シェルのツール)の手順 2 で開き直した端末）を開いてある
- 実行場所: 前提の端末（GNOME にログインした自分のユーザーの bash）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ

1. ShellCheck と shfmt を上げる。

   ```bash
   brew upgrade shellcheck shfmt
   ```

   - すべてまとめて上げるなら `brew upgrade`
   - **ほかのコマンドは、Homebrew の確認が出たら答え、更新が終わってから貼る**（続けて貼ると確認の答えとして食われる）

---

### VS Code

- Microsoft の dnf のリポジトリから VS Code（rpm 版）を入れ、起動を確かめる
- 前提: [ログインと sudo](#ログインと-sudo)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/vscode.md)・[参考資料](reference/vscode.md)・[ロールバックと注意点](extra/vscode.md)

> [!IMPORTANT]
> - **すべて対象ホスト上で実行する**。デスクトップが要るのは、この項の手順 6（GUI の起動）だけ
> - **この項の手順 6 は、デスクトップにログインした端末から実行する**。TTY やディスプレイが無いシェル（ssh や自動化）からは実行しない

1. 署名鍵を落として、取り込む前に fingerprint を見る。

   ```bash
   curl -fsSL https://packages.microsoft.com/keys/microsoft.asc -o /tmp/microsoft.asc
   gpg --show-keys --with-fingerprint /tmp/microsoft.asc
   ```

   - 次の値と一致することを目で確かめる。違っていればここで止める
     - fingerprint `BC52 8686 B50D 79E3 39D3 721C EB3E 94AD BE12 29CF`
     - uid `Microsoft (Release signing) <gpgsecurity@microsoft.com>`
   - **次の手順は、一致したのを確かめてから貼る**

1. fingerprint が一致したら署名鍵を取り込み、確かめて鍵ファイルを消す。

   ```bash
   {
     sudo rpm --import /tmp/microsoft.asc
     rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i microsoft
     rm -f /tmp/microsoft.asc
   }
   ```

   - `gpg-pubkey-be1229cf-5631588c Microsoft (Release signing) ...` が出れば入っている

1. リポジトリを追加する。

   ```bash
   {
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
   }
   ```

1. 何が入るかを先に見てから、VS Code を入れる。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     sudo dnf install --assumeno code
     sudo dnf install code
   }
   ```

   - 先に何が入るかだけ見る（`--assumeno` は必ず中断する）
   - `code ... 343 M` と `Installed size: 1.0 G` のように容量が出る。よければ、続く `dnf install` の `[y/N]` に答えて入れる
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. VS Code が入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   code --version
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' code
   rpm -qi code | sed -n '/^Vendor/p;/^Build Date/p'
   ldd /usr/share/code/code | grep -c 'not found'
   rpm -ql code | grep '/applications/.*\.desktop$'
   ```

   - バージョン / コミットハッシュ / アーキテクチャ（`x64` または `arm64`）の 3 行が出る
   - `from_repo` が `vscode`、`Vendor` が `Microsoft Corporation` になる
   - **`ldd` の `not found` が `0`** なら、必要な共有ライブラリがすべて EL10 側で解決できている

1. デスクトップにログインした端末から、GUI を起動する。

   ```bash
   code
   ```

   - アプリ一覧の「Visual Studio Code」からでも同じ
   - **注意**: ssh や自動化など、TTY もディスプレイも無いシェルからは起動できなかった（この項のリードのアラートと、この手順の補足）
   - ウィンドウが開き、初回は Welcome 画面と `Continue without Signing In` のボタンが表示される
   - ウィンドウが出たことを確かめる
   - **次の手順は、ウィンドウを閉じてから貼る**（続けて貼ると VS Code への操作として食われる）

1. 初回起動で設定のディレクトリができたか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   ls -d ~/.config/Code ~/.vscode
   code --list-extensions
   ```

   - 初回起動で `~/.config/Code` ができる
   - `~/.vscode` は、起動を試みた時点で `argv.json` だけ作られる
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
   - 消すときは `code --uninstall-extension <publisher.name>`

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

---

### npm のオフライン導入

- インターネットに出られないホストで、SSH の SOCKS トンネルを通して AppStream の Node.js と npm を入れ、Neovim の Mason に npm のパッケージ（LSP サーバー・リンター）を入れる
- 前提: オンラインのホストから[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1〜3 でトンネルを張り、オフラインのホストへ接続してある
  - この項の手順 1 の前に、[SSH の SOCKS トンネル: dnf にもトンネルを使わせる](#ssh-の-socks-トンネル-dnf-にもトンネルを使わせる)も通してある
  - 同じトンネルで、[Homebrew のオフライン導入](#homebrew-のオフライン導入)と[Neovim](neovim.md#neovim)の手順 1・2 を通してある
  - この項の手順 1・2 で経路を設定してから、[LazyVim の設定を導入する](neovim.md#lazyvim-の設定を導入する)の手順 10 の初回起動を含む導入を行い、この項の手順 3 へ進む。Mason の npm パッケージは未導入でよい
- 実行場所: オフラインのホストの、`sudo` できる自分のユーザーのシェル（[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 3 のシェル）。この項の手順 4 でトンネルを閉じてログインし直し（オンラインのホストでも操作する）、この項の手順 5 はログインし直したシェルに貼る
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/npm-offline.md)・[参考資料](reference/npm-offline.md)・[ロールバックと注意点](extra/npm-offline.md)

> [!WARNING]
>
> - トンネルを張っている間は、オフラインのホストのどのユーザーも `127.0.0.1:1080` を通って外に出られる（[SSH の SOCKS トンネルの注意点](extra/ssh-socks-tunnel.md#注意点)）

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
   node --version
   npm --version
   command -v node npm
   export https_proxy=socks5h://127.0.0.1:1080
   npm config get https-proxy
   npm config get proxy
   npm ping
   ```

   - `v22.23.2`、`10.9.8`、`/usr/bin/node`、`/usr/bin/npm` が出る
   - `/home/linuxbrew/.linuxbrew/bin/npm` が出たら、Homebrew の node が PATH で先に来ていて、Mason もそちらを使う（[注意点](extra/npm-offline.md#注意点)）
   - `npm config get` の 2 行は、どちらも `null`
   - ほかの値が出たら、`~/.npmrc` などの設定が `https_proxy` より優先される
   - `npm notice PONG 148ms` のように `PONG` が出れば、npm はトンネルを通ってレジストリに届いている
   - **トンネルを張り直したら、[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 3 に続けて、この手順を貼り直す**

1. この項の手順 2 のシェルで Neovim でファイルを開き、Mason に足りないパッケージを入れさせる。

   ```bash
   nvim -R ~/.config/nvim/init.lua
   ```

   - 入れ終わるたびに、`markdownlint-cli2 was successfully installed.` のような通知が出る
   - `:Mason` で画面を開くと、入れている間は `Installing` に `$ npm install markdown-toc@1.2.0` のような行が出る
   - npm のパッケージ（`markdownlint-cli2`・`json-lsp` など）が `Installed` に並べばよい
   - この項の手順 5 で使う `markdownlint-cli2` が設定に無ければ、`:MasonInstall markdownlint-cli2` で入れる。ほかの npm のパッケージも、同じように名前で入れられる
   - 失敗は通知が出ないことがある。`Installed` に並ばないものは、`:MasonLog` の `Installation failed for Package(name=…)` の行で理由を見る
   - npm 以外の理由（`unzip` が無い、など）で失敗したものは[注意点](extra/npm-offline.md#注意点)
   - 通知が出そろってから、`:qa` で閉じる
   - LSP サーバーが 1 つも入らなかったら、`:qa` で閉じて、この手順をもう一度貼る
   - **次の手順は、`:qa` で Neovim を閉じてから貼る**（続けて貼ると Neovim への入力として食われる）

1. [SSH の SOCKS トンネル: トンネルを閉じる](#ssh-の-socks-トンネル-トンネルを閉じる)の手順 1・3 を貼り、トンネルを閉じて、転送を付けずにログインし直す。

   - [SSH の SOCKS トンネル: トンネルを閉じる](#ssh-の-socks-トンネル-トンネルを閉じる)の手順 1（`exit`）はオフラインのホストで、同じ項の手順 3 はオンラインのホストで貼る
   - オンラインのホストのシェルで[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1 の変数が消えていたら（新しいシェルなど）、先に[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1 を貼る
   - **次の手順は、ログインし直してから貼る**（続けて貼るとパスワードへの答えとして食われる）

1. オフラインのホストで、トンネルが無くても Mason の npm のパッケージが動き、npm が外に出られないことを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   env | grep -i _proxy
   ls ~/.local/share/nvim/mason/bin
   ~/.local/share/nvim/mason/bin/markdownlint-cli2 --help | head -n 1
   npm ping --fetch-retries=0 && echo '届いた（オフラインではない）' || echo '届かない（期待どおり）'
   ```

   - `env` は何も出さない
   - `ls` に、Mason で入れたコマンド（`markdownlint-cli2`・`vscode-json-language-server` など）が並ぶ
   - `markdownlint-cli2 v0.23.3 (markdownlint v0.41.1)` のような版の行が出る
   - 最後の行は、`ENOTFOUND` のエラーの後に `届かない（期待どおり）`

#### npm のオフライン導入: 更新

- オフラインのホストの Node.js と npm、Mason の npm のパッケージを、SSH の SOCKS トンネルを通して上げる
- 前提: [npm のオフライン導入](#npm-のオフライン導入)を通してある。[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1〜3 でトンネルを張り、そのシェルで[npm のオフライン導入](#npm-のオフライン導入)の手順 2 を貼ってある
- 実行場所: オフラインのホストの、トンネルを張った ssh のシェル（`sudo` できる自分のユーザー）
- Node.js と npm は `sudo dnf upgrade` でも上がる（トンネルか、dnf が届くリポジトリが要る）

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
   - **次の手順は、`:qa` で Neovim を閉じてから貼る**（続けて貼ると Neovim への入力として食われる）

1. オフラインのホストからログアウトして、トンネルを閉じる。

   ```bash
   exit
   ```

---

## アプリ

- Firefox と画像の道具、端末で使う道具（btop・gdu）

### Firefox

- Mozilla の dnf のリポジトリから最新版（Rapid Release）の Firefox を入れ、RPM Fusion の FFmpeg で AAC・H.264 を再生できるようにする
- 前提: [ログインと sudo](#ログインと-sudo)を通してある。この項の手順 8〜10 には、[EPEL と RPM Fusion](#epel-と-rpm-fusion)も要る
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）。この項の手順 7・11 は、デスクトップのセッションの Firefox

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
   - `aarch64` と `x86_64` の両方の行が並ぶ

1. Firefox を入れる。

   ```bash
   sudo dnf install "${FF_PKG:?「Firefox」の手順 1 の FF_PKG が空のまま。値を入れて貼り直す}" ${FF_L10N}
   ```

   - AppStream の Firefox（ESR）が既に入っているホストでは、この 1 コマンドが、`firefox` のアップグレードとして解決される（一覧の `アップグレード:` の下に `firefox` が出る。参考資料を参照）
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

   - 最初の起動では、窓いっぱいに「Firefox へようこそ」が出る（続行すると、Firefox の利用規約とプライバシー通知に同意したことになる、と書かれている）。「続行」を押すまで、`about:support` は開けない
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

---

### 画像の道具

- Dockerfile とコンテナイメージの検査（hadolint・dive・Trivy）に使う
- 前提: [Homebrew](#homebrew)の手順 1〜3 と[Podman](#podman)の手順 7（API ソケット）までを通してある
  - `command -v brew podman` が 2 行を返さない、または `systemctl --user is-active podman.socket` が `active` を返さなければ、先に前提を通す
- 実行場所: 自分のユーザーでログインしたシェル（端末の bash か SSH）
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/image-tools.md)・[参考資料](reference/image-tools.md)・[ロールバックと注意点](extra/image-tools.md)
- **この項の手順 3 には対話入力がある**（トランザクション表の `[y/N]` と Trivy の鍵の確認）。答えてから次の手順を貼る
- **この項の手順 10 で dive の画面（TUI）が開く**。`q` で終了する

> [!IMPORTANT]
> - **`sudo -i` した root のシェルでは行わない**（Homebrew の導入・更新は root では行わず、イメージも自分のユーザーの podman に作るため）

1. brew で hadolint と dive を入れる。

   ```bash
   brew install hadolint dive
   ```

   - **次の手順は、確認が出たら答え、インストールが終わってシェルのプロンプトに戻ってから貼る**（依存の追加を確認する `[y/n]` が出る版では、続けて貼ると回答として食われる）

1. hadolint と dive が入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   hadolint --version
   dive --version
   command -v hadolint dive
   ```

   - `Haskell Dockerfile Linter 2.15.1` と `dive 0.13.1` が出る
   - どちらも `/home/linuxbrew/.linuxbrew/bin/` の下にある

1. Trivy の公式 dnf リポジトリを登録し、ファイルと版を確かめてから Trivy を入れる。

   ```bash
   {
     sudo tee /etc/yum.repos.d/trivy.repo >/dev/null <<'EOF'
   [trivy]
   name=Trivy repository
   baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/$basearch/
   gpgcheck=1
   enabled=1
   gpgkey=https://aquasecurity.github.io/trivy-repo/rpm/public.key
   EOF
     printf '\n\033[7m 確認 \033[0m\n'
     cat /etc/yum.repos.d/trivy.repo
     dnf -q list --showduplicates trivy
     sudo dnf install trivy
   }
   ```

   - ファイルに `gpgcheck=1` があることを確かめる
   - 公式の候補は `trivy.x86_64  0.75.0-1  trivy` のように出る。EPEL の候補も並ぶことがある
   - 初回は署名鍵の取り込みを 1 回聞かれる
   - fingerprint が `825A D903 6F7C 850E 6A6F ED49 35B8 ACA4 4FD9 CA9F`（`trivy-repo <oss@aquasec.com>`）であることを確かめてから `y` と答える。違っていれば `N` で中断する
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

1. Trivy が入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   trivy --version
   command -v trivy
   rpm -q trivy
   ```

   - 1 行目の `Version:` が、手順 3 で導入した RPM の版と一致し、`/usr/bin/trivy` とその RPM の名前が出ればよい

1. わざと欠陥のある Containerfile を hadolint に渡し、指摘が出ることを確かめる。

   ```bash
   printf 'FROM registry.access.redhat.com/ubi10/ubi-minimal\nRUN microdnf install -y httpd\n' | hadolint -; echo "rc=$?"
   ```

   - `DL3006`・`DL3040`・`DL3041` の 3 つの `warning` と、`rc=1` が出ればよい

1. 確認用の Containerfile とページを置き、hadolint が何も指摘しないことを確かめる。

   ```bash
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
   - `podman images` に `localhost/image-check  1` の行が出る（283 MB）

1. dive の判定のモード（`--ci`）で、イメージの無駄を数える。

   ```bash
   dive --source podman --ci localhost/image-check:1; echo "rc=$?"
   ```

   - `Image Source: podman://localhost/image-check:1` が出れば、podman のイメージを直接読めている
   - `efficiency: 85.4470 %` と `wastedBytes: 58951134 bytes (59 MB)` が出る
   - **既定の基準では `Result:FAIL` と `rc=1` になる**

1. Trivy で、イメージの脆弱性を調べる。

   ```bash
   trivy image --image-src podman --severity HIGH,CRITICAL localhost/image-check:1
   ```

   - 初回は脆弱性のデータベースを落とす（容量は取得時点で変わる）
   - `Detected OS  family="redhat" version="10.1"` の後に、`Report Summary` の表が出る
   - 脆弱性の結果は、データベースの日付とイメージの中身で変わる

1. dive の画面で、層の中身を見る。

   ```bash
   dive --source podman localhost/image-check:1
   ```

   - 左に `Layers` と `Image Details`、右に `Current Layer Contents` が出る
   - `Image Details` の `Image efficiency score: 85 %` と `Potential wasted space: 59 MB` は、手順 8 と同じ値
   - いちばん下の行に、キーの案内（`Quit`・`Tab Switch view`・`^F Filter` など）が出る
   - `q` で終了する
   - **次のコマンドは、`q` で終了してから貼る**（続けて貼ると dive への操作として食われる）

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

- `trivy image registry.access.redhat.com/ubi10/ubi-minimal:latest --severity CRITICAL` は、手元に取らずに `redhat 10.2` と判定し、`0` を返した
- 確認用の Containerfile に `trivy config ~/image-check` を使うと、hadolint が何も言わなかったのに対して、2 つが出た
  - `DS-0002 (HIGH)`: `USER` が無い（ベースイメージが root 以外で動くことは見ていない）
  - `DS-0026 (LOW)`: `HEALTHCHECK` が無い

#### 画像の道具: 更新

- Homebrew で入れた hadolint・dive と、dnf で入れた Trivy を上げる
- 前提: [画像の道具](#画像の道具)を通してある
- 実行場所: 自分のユーザーでログインしたシェル（端末の bash か SSH）

1. hadolint と dive を更新する。

   ```bash
   brew upgrade hadolint dive
   ```

   - 新しい版が無ければ `Warning: hadolint 2.15.1 already installed` のように出て、何もしない
   - すべてまとめて上げるなら `brew upgrade`

1. Trivy を更新する。

   ```bash
   sudo dnf upgrade trivy
   ```

   - 更新があると `[y/N]` で聞かれる。無ければ `Nothing to do.` で終わる

---

### btop

- CPU・メモリ・ディスク・ネットワーク・プロセスを端末の画面で見る btop を、EPEL から入れる
- 前提: [EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 1 で EPEL を有効にしてある（`dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に通す）
- 実行場所: btop を入れるホストの、自分のユーザーの端末（bash）。**すべて、その対象ホスト上で実行する**
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/btop.md)・[参考資料](reference/btop.md)・[ロールバックと注意点](extra/btop.md)
- **この項の手順 1 には対話入力がある**（トランザクション表の `[y/N]` と鍵の確認）。答えてから手順 2 を貼る
- **この項の手順 2 で TUI が開く**。`q` で終了してから手順 3 を貼る

1. 入手できる版を見てから、btop を入れる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   dnf -q list --showduplicates btop
   sudo dnf install btop
   ```

   - 版は `btop.aarch64  1.4.7-1.el10_2  epel` のように 1 つだけ出る
   - **EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる**
   - fingerprint `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）なら `y`、違えば `N` で中断する
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

1. btop が入ったか確かめ、起動する。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   btop --version
   command -v btop
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' btop
   btop
   ```

   - `btop version: 1.4.7` と `/usr/bin/btop` が出てから、btop の画面が開く
   - 画面が出たら `q` で終了する
   - **次の手順は、`q` で終了してから貼る**（続けて貼ると btop への操作として食われる）

1. 初回の起動で `~/.config/btop/btop.conf` が作られたか確かめる。

   ```bash
   ls -l ~/.config/btop
   ```

   - `btop.conf` と `themes/` があればよい

#### btop: 設定ファイル

- btop の設定ファイルとテーマの置き場所を確かめ、起動せずに既定の設定を見る
- 前提: [btop](#btop)を通してある
- 実行場所: btop を入れたホストの、自分のユーザーの端末（bash）
- `~/.config/btop/btop.conf` は**初回起動時に既定値で作られる**（約 9.8 KB、項目ごとにコメント付き）
- アプリ内では `Esc` または `m` でメニューが開き、`Options` からほとんどの項目を GUI で変えられる（保存も btop がやる）
- テーマは 2 か所から読む。`btop.conf` の `color_theme` にファイル名を書くと切り替わる（`"Default"` と `"TTY"` は組み込み）
  - `/usr/share/btop/themes/`: RPM が入れる既定のテーマ（`dracula` / `nord` / `gruvbox-*` / `adwaita-dark` など）
  - `~/.config/btop/themes/`: 自分で足すテーマ

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
   - EPEL が新しい版を出すまでは上がらない（[注意点](extra/btop.md#注意点)）

---

### gdu

- ディスクの使用量を端末の画面で調べる gdu を、Homebrew で入れる
- 前提: [共通の bash 設定](shell-terminal.md#共通の-bash-設定)と[Homebrew](#homebrew)の手順 1〜3 を通してある（`command -v brew` で何も出なければ、先に通す）
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。PATH に Homebrew が入った端末）
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/gdu.md)・[参考資料](reference/gdu.md)・[ロールバックと注意点](extra/gdu.md)
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
   gdu-go --version
   brew list --versions gdu
   command -v gdu-go
   command -v gdu || echo 'gdu という名前のコマンドは無い'
   gdu-go -n /usr/share | tail -5
   ```

   - `Version: v5.38.0` のように版が出る
   - `command -v gdu` の行は `gdu という名前のコマンドは無い` になる。[gdu の名前で呼ぶ](#gdu-gdu-の名前で呼ぶ)をやるまでは、これが正しい状態
   - 最後の `gdu-go -n` では、サイズの大きい順に並んだ一覧が出る

#### gdu: gdu の名前で呼ぶ

- 共通の bash 設定のエイリアスで、`gdu-go` を `gdu` の名前で呼ぶ
- 前提: [gdu](#gdu)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。PATH に Homebrew が入った端末）

1. 共通設定を読み直し、gdu のエイリアスを確かめる。

   ```bash
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

---

## ネットワークとリモート操作

- SSH・Wake on LAN・SOCKS トンネル。WireGuard は[WireGuard のセットアップ](wireguard.md)、GNOME のリモートの画面（デスクトップ共有・ヘッドレスセッション・リモートログイン）は[GNOME のリモート操作のセットアップ](gnome-remote.md)で入れる

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
   - `Permission denied (publickey,…)` で断られたら、この項の手順 1 の鍵と、つなぐ側の鍵が合っていない。この項の手順 3 へは進まない
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

1. 元に戻すときは、この項の手順 3 のファイルを消し、パスワードでもログインできるようにする。

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

### Wake on LAN を使う

- 電源を切った（シャットダウンした）この PC を、LAN の別の PC から起こせるようにする。有線 LAN だけ（Wi-Fi では使えない）
- 前提: [ログインと sudo](#ログインと-sudo)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）。この項の手順 4 は UEFI の設定の画面、この項の手順 7 は LAN の別の PC で行う
- **この項の手順 3 で再起動して UEFI の画面に入る**
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
   - `LAN_CON` が空なら、有線の LAN の接続が無い（この項は使えない）
   - 新しい端末を開いたら（この項の手順 3 の再起動の後も）、この項の手順 1 を貼り直す

1. 有線の接続で、マジック パケットでの起動を有効にし、MAC アドレスを表示する。

   ```bash
   if [ -z "${LAN_CON}" ]; then echo '中断: この項の手順 1 の LAN_CON が空のまま（有線の LAN の接続が無い）' >&2; else
     sudo nmcli connection modify "${LAN_CON}" 802-3-ethernet.wake-on-lan magic
     sudo nmcli device reapply "${LAN_IF}"
     printf '\n\033[7m 確認 \033[0m\n'
     nmcli -g 802-3-ethernet.wake-on-lan connection show "${LAN_CON}"
     sudo ethtool "${LAN_IF}" | grep -i 'wake-on'
     ip -brief link show "${LAN_IF}"
   fi
   ```

   - `magic` と、`Supports Wake-on:` の文字に `g` があり、`Wake-on: g` が出ればよい
   - 最後の行の `xx:xx:xx:xx:xx:xx` が MAC アドレス。この項の手順 7 で使うので控える
   - `Supports Wake-on:` に `g` が無ければ、この LAN のアダプターは Wake on LAN を使えない
   - `Wake-on: d` のままなら、アダプターのドライバが設定を受け付けていない。この項の手順 5 で、起動の後にもう一度見る

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

1. この項の手順 1 を貼り直してから、Wake on LAN が有効なままか確かめる。

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

   - AlmaLinux など Python のある PC では、`python3 -c "import socket; m = bytes.fromhex('<MAC>'.replace(':', '').replace('-', '')); s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1); s.sendto(b'\xff' * 6 + m * 16, ('255.255.255.255', 9))"` で送れる（`<MAC>` はこの項の手順 2 の値）
   - 起動しなければ、UEFI の設定（この項の手順 4）と、LAN のアダプターのランプ（電源が切れていても点いているか）を見る

1. 元に戻すときは、マジック パケットでの起動を切る。

   ```bash
   if [ -z "${LAN_CON}" ]; then echo '中断: この項の手順 1 の LAN_CON が空のまま' >&2; else
     sudo nmcli connection modify "${LAN_CON}" 802-3-ethernet.wake-on-lan default
     sudo nmcli device reapply "${LAN_IF}"
     printf '\n\033[7m 確認 \033[0m\n'
     nmcli -g 802-3-ethernet.wake-on-lan connection show "${LAN_CON}"
   fi
   ```

   - `default` が出ればよい。UEFI の設定は、この項の手順 4 の画面で戻す

---

### SSH の SOCKS トンネル

- インターネットに出られないホストから、ssh の SOCKS の転送で、インターネットに出られるホストを通して外へ出る
- 前提: オンラインのホストからオフラインのホストへ ssh でログインできる（LAN・VPN・VirtualBox のホストオンリーのネットワークなど）。オンラインのホストの OpenSSH は 7.6 以上
- 実行場所: この項の手順 1・2 は、インターネットに出られるホスト（以下、オンラインのホスト）のシェル（bash）。手順 3 は、手順 2 でログインしたインターネットに出られないホスト（以下、オフラインのホスト）のシェル
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/ssh-socks-tunnel.md)・[参考資料](reference/ssh-socks-tunnel.md)・[ロールバックと注意点](extra/ssh-socks-tunnel.md)

> [!IMPORTANT]
> - **2 台のホストで行う**。この項の手順 1・2 はオンラインのホストで、手順 3 は、手順 2 でログインしたオフラインのホストのシェルで貼る
> - **この項の手順 2 は ssh のログイン**。ログインしてから手順 3 を貼る
> - オンラインのホストが Windows なら、この項の手順 1 は飛ばし、手順 2 の箇条書きのとおり 1 行を打つ

- これを前提にする項:
  - [Homebrew（インターネットに出られないホスト）](#homebrew-のオフライン導入)
  - [npm（インターネットに出られないホスト）](#npm-のオフライン導入)（Neovim の Mason が npm で入れるパッケージ。npm には `https_proxy` を足す）

> [!WARNING]
> **トンネルを張っている間は、オフラインのホストのどのユーザーも `127.0.0.1:1080` を通ってインターネットに出られる**（出口はオンラインのホスト）。使い終わったら[トンネルを閉じる](#ssh-の-socks-トンネル-トンネルを閉じる)。
>

1. オンラインのホストで、変数を設定する（`OFFLINE_HOST` は必ず値を入れる）。

   ```bash
   OFFLINE_HOST=192.168.1.20            # ← 自分の値に書き換える。オフラインのホストの IP アドレスかホスト名。<OFFLINE_HOST>
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
   - 最後に値を読み戻して確かめる
   - `OFFLINE_HOST` を書き換えたかをここで確かめる
   - **新しいシェルを開いたら**、この項の手順 1 の 2 つのブロックを貼り直す

1. オンラインのホストから、SOCKS の転送を付けて ssh でログインする。

   ```bash
   ssh -o ExitOnForwardFailure=yes -o ControlPath=none -R 1080 "${OFFLINE_USER:?手順 1 の OFFLINE_USER が空のまま}@${OFFLINE_HOST:?手順 1 の OFFLINE_HOST が空のまま}"
   ```

   - ログインすると、オフラインのホストの `127.0.0.1:1080` が SOCKS プロキシになる。そこへの接続は、オンラインのホストから外へ出る
   - 転送は、この ssh のセッションが続く間だけ有効。このウィンドウは開いたままにする
   - オンラインのホストが Windows なら、PowerShell か cmd に `ssh -o ExitOnForwardFailure=yes -o ControlPath=none -R 1080 <OFFLINE_USER>@<OFFLINE_HOST>` を打つ
   - `Error: remote port forwarding failed for listen port 1080` で終わったら、オフラインのホストで 1080 番がふさがっているか、sshd が転送を禁じている（参考資料を参照）
   - 初めてつなぐホストでは、ホスト鍵の確認に `yes` と答える
   - **次の手順は、オフラインのホストにログインしてから貼る**（続けて貼るとホスト鍵の確認やパスワードへの答えとして食われる）

1. オフラインのホストで、プロキシを環境変数に入れ、インターネットに届くか確かめる。

   ```bash
   export ALL_PROXY=socks5h://127.0.0.1:1080
   printf '\n\033[7m 確認 \033[0m\n'
   ss -Hltn 'sport = :1080'
   curl -sS -o /dev/null --connect-timeout 10 -w '%{http_code}\n' https://github.com
   ```

   - `ss` の行は `127.0.0.1:1080`（IPv6 があれば `[::1]:1080` も）だけ
   - `0.0.0.0:1080` や `*:1080` が出たら、LAN 全体にプロキシが開いている。`exit` で抜けて、ここで止める（参考資料を参照）
   - 最後の行が `200` なら届いている
   - `000` と `Failed to connect to 127.0.0.1 port 1080` が出たら、この項の手順 2 の転送が無い
   - `export` はこのシェルの中だけで有効。**ssh を張り直したら、この項の手順 2 からやり直す**
   - `sudo` を付けたコマンド・podman・npm は `ALL_PROXY` を読まない（参考資料を参照）。dnf には[dnf にもトンネルを使わせる](#ssh-の-socks-トンネル-dnf-にもトンネルを使わせる)で設定する

#### SSH の SOCKS トンネル: dnf にもトンネルを使わせる

- オフラインのホストで、dnf で外のリポジトリから入れるときだけ行う（[Homebrew のオフライン導入](#homebrew-のオフライン導入) では、Homebrew の依存が足りないとき）
- 前提: オフラインのホストで[ログインと sudo](#ログインと-sudo)を通してある。[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 1〜3 で、トンネルを張ってある
- 実行場所: オフラインのホストの、[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 3 を貼ったシェル（bash）
- 社内のミラーなど、dnf がトンネル無しで届くリポジトリを使うホストでは行わない（その通信もトンネルに向かってしまう）
- 足した行は、[ロールバック](extra/ssh-socks-tunnel.md#ロールバック)で消すまで残る

1. dnf にプロキシを設定する。

   ```bash
   if grep -q '^proxy' /etc/dnf/dnf.conf; then echo '中断: /etc/dnf/dnf.conf に proxy の行が既にある（この手順は行わない）' >&2; else
     sudo sed -i '/^\[main\]$/a proxy=socks5h://127.0.0.1:1080' /etc/dnf/dnf.conf
     printf '\n\033[7m 確認 \033[0m\n'
     grep -n '^proxy' /etc/dnf/dnf.conf
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
   OFFLINE_HOST=192.168.1.20            # ← 自分の値に書き換える。オフラインのホストの IP アドレスかホスト名。<OFFLINE_HOST>
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
   - 最後に値を読み戻して確かめる
   - **新しいシェルを開いたら**、この項の手順 2 の 2 つのブロックを貼り直す

1. オンラインのホストから、転送を付けずにログインし直す。

   ```bash
   ssh "${OFFLINE_USER:?この項の手順 2 の OFFLINE_USER が空のまま}@${OFFLINE_HOST:?この項の手順 2 の OFFLINE_HOST が空のまま}"
   ```

   - オンラインのホストが Windows なら、この Bash のブロックの代わりに、PowerShell か cmd に `ssh <OFFLINE_USER>@<OFFLINE_HOST>` を打つ（[SSH の SOCKS トンネル](#ssh-の-socks-トンネル)の手順 2 と同じユーザー・ホストを指定する）
   - **次の手順は、ログインしてから貼る**（続けて貼るとパスワードへの答えとして食われる）

1. オフラインのホストで、トンネルが無く、外に出られないことを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   ss -Hltn 'sport = :1080'
   curl -sS -o /dev/null --connect-timeout 10 https://github.com && echo '届いた（オフラインではない）' || echo '届かない（期待どおり）'
   ```

   - `ss` は何も出さない
   - 最後の行は `届かない（期待どおり）`

---

## コンテナ

- Podman とその周りの道具（podman-compose・podman-tui・lazydocker）と Distrobox。仮想マシン（VirtualBox・VirtualBox の bootc ゲスト・kvm-container）は、[仮想マシンのセットアップ](virtual-machines.md)で入れる

### Podman

- AppStream の podman を入れ、自分のユーザー（rootless）でコンテナを動かせるようにする
- 前提: [ログインと sudo](#ログインと-sudo)を通してある
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/podman.md)・[参考資料](reference/podman.md)・[ロールバックと注意点](extra/podman.md)
- 導入後は、必要な[コンテナ用ツール](tool-catalog.md#cli-コンテナ)を追加する

> [!IMPORTANT]
> - **自分のユーザーでログインした bash（デスクトップの端末か SSH）で行う**
> - `sudo -i` の root のシェルや、`sudo -iu <ユーザー>` で切り替えたシェルでは行わない

1. podman が入っているか確かめる。

   ```bash
   rpm -q podman || echo 'podman は未導入'
   ```

   - `podman-5.8.2-...` のように版が出れば、手順 2 は飛ばす
   - `podman は未導入` と出たら、手順 2 で入れる

1. podman が未導入のときだけ、AppStream から入れる。

   ```bash
   sudo dnf install -y podman
   ```

1. 自分のユーザーに、rootless 用の UID・GID の範囲（subuid / subgid）があるか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   for f in /etc/subuid /etc/subgid; do
     grep -H "^${USER}:" "$f" || printf '%s: 自分の割り当てが無い\n' "$f"
   done
   ```

   - `/etc/subuid:<USER>:524288:65536` と `/etc/subgid:<USER>:524288:65536` のような 2 行が出れば、手順 4 は飛ばす
   - 片方でも `自分の割り当てが無い` と出たら、手順 4 で不足している側だけ割り当てる

1. 片方でも割り当てが無いときだけ、不足する側に範囲を割り当て、podman に読み直させる。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: 自分のユーザーのシェルで貼る' >&2
   elif SUBID_START=$(awk -F: '{ e = $2 + $3; if (e > m) m = e } END { print (m > 524288 ? m : 524288) }' /etc/subuid /etc/subgid); then
     SUBID_ARGS=()
     if ! grep -q "^${USER}:" /etc/subuid; then
       SUBID_ARGS+=(--add-subuids "${SUBID_START}-$((SUBID_START + 65535))")
     fi
     if ! grep -q "^${USER}:" /etc/subgid; then
       SUBID_ARGS+=(--add-subgids "${SUBID_START}-$((SUBID_START + 65535))")
     fi
     if [ "${#SUBID_ARGS[@]}" -eq 0 ]; then echo '両方とも割り当て済み'
     else
       printf '\n\033[7m 確認 \033[0m\n'
       sudo usermod "${SUBID_ARGS[@]}" "${USER}" &&
       podman system migrate &&
       grep -H "^${USER}:" /etc/subuid /etc/subgid
     fi
   else echo '中断: /etc/subuid または /etc/subgid を読めない' >&2
   fi
   ```

   - 手順 3 で出るはずだった 2 行が出ればよい

1. 自分のユーザーで動く設定になっているか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   podman version --format '{{.Client.Version}}'
   command -v podman
   podman info --format '{{.Host.Security.Rootless}} {{.Store.GraphDriverName}} {{.Host.OCIRuntime.Name}} {{.Host.NetworkBackend}} {{.Host.RootlessNetworkCmd}} {{.Host.CgroupsVersion}}'
   podman info --format '{{.Store.GraphRoot}}'
   ```

   - `5.8.2` と `/usr/bin/podman` が出る
   - 3 行目が `true overlay crun netavark pasta v2` なら、自分のユーザー（rootless）で動く
   - イメージとコンテナは、4 行目の場所（`/home/<USER>/.local/share/containers/storage`）に入る

1. イメージを完全な名前で指定して、コンテナを 1 つ動かす。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   podman run --rm quay.io/podman/hello
   podman images
   ```

   - `!... Hello Podman World ...!` から始まる絵と案内が出る
   - `podman images` に `quay.io/podman/hello` の行が出る
   - **イメージはレジストリの名前から書く**（`quay.io/...`、`registry.access.redhat.com/...`）。短い名前だと、どこから取るかを聞かれることがある（参考資料を参照）

1. API ソケットを有効にして、応答を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user enable --now podman.socket
   systemctl --user is-active podman.socket
   curl -s --unix-socket "${XDG_RUNTIME_DIR}/podman/podman.sock" http://d/_ping; echo
   podman --remote version --format '{{.Server.Version}}'
   ```

   - `active`・`OK`・`5.8.2` が出ればよい
   - 初めて有効にしたときは、その前に `Created symlink '/home/<USER>/.config/systemd/user/sockets.target.wants/podman.socket' → '/usr/lib/systemd/user/podman.socket'.` の行が 1 つ出る
   - `Failed to connect to user scope bus` と出たら、`sudo -iu` などで切り替えたシェルで実行している。自分のユーザーでログインし直す

#### Podman: Docker 向けのツールから使う

- Docker の API に `DOCKER_HOST` でつなぐツール（[lazydocker](#lazydocker) など）のための設定
- 前提: [Podman](#podman)と[共通の bash 設定](shell-terminal.md#共通の-bash-設定)を通してある
  - `DOCKER_HOST` は共通の bash 設定が入れる。ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）
- [画像の道具](#画像の道具) の dive と Trivy、[podman-tui](#podman-tui) は podman を直接読むので、この項は要らない

1. 共通設定を読み直し、ソケットが Docker の API に答えるか確かめる。

   ```bash
   . ~/.bashrc
   printf '\n\033[7m 確認 \033[0m\n'
   printf '%s\n' "${DOCKER_HOST-}"
   curl -s --unix-socket "${DOCKER_HOST#unix://}" http://d/version | grep -o '"Name":"Podman Engine"'
   ```

   - `unix:///run/user/…/podman/podman.sock` と `"Name":"Podman Engine"` が出ればよい
   - 既に別の値がある場合は上書きせず、その用途を確認する
   - `~/.bashrc` には追記しない

#### Podman: Quadlet で自動起動する

- `podman run -d` で動かしたコンテナは、PC を再起動すると戻らない。linger が無いと、ログアウトしただけで止まる（[注意点](extra/podman.md#注意点)）
- Quadlet は、`~/.config/containers/systemd` に置いた定義から、ユーザーの systemd のサービスを作る仕組み。podman に含まれている
- 確認用に、`registry.access.redhat.com/ubi10/httpd-24`（Apache）を `127.0.0.1:8080` で動かす
- 前提: [Podman](#podman)と[ユーザーサービスの常駐](#ユーザーサービスの常駐)（linger）を通してある
  - `loginctl show-user "$(id -u)" -p Linger` が `Linger=yes` でなければ、先に通す
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）
- この項の手順 3 で再起動する

1. 確認用の Web サーバーの定義とページを置く。

   ```bash
   mkdir -p ~/hello-web ~/.config/containers/systemd
   echo 'hello from quadlet' > ~/hello-web/index.html
   cat > ~/.config/containers/systemd/hello-web.container <<'EOF'
   [Unit]
   Description=Quadlet の確認用の Web サーバー

   [Container]
   Image=registry.access.redhat.com/ubi10/httpd-24:latest
   ContainerName=hello-web
   PublishPort=127.0.0.1:8080:8080
   Volume=%h/hello-web:/var/www/html:Z
   AutoUpdate=registry

   [Service]
   TimeoutStartSec=300

   [Install]
   WantedBy=default.target
   EOF
   ```

1. systemd に定義を読み直させ、サービスを起動して応答を確かめる。

   ```bash
   systemctl --user daemon-reload
   systemctl --user start hello-web.service
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user is-active hello-web.service
   systemctl --user is-enabled hello-web.service
   curl -s --retry 10 --retry-delay 1 --retry-all-errors http://127.0.0.1:8080/
   ```

   - `active`・`generated`・`hello from quadlet` が出ればよい
   - 初回の `start` は、数十秒かかることがある
   - **`systemctl --user enable` は使わない**

1. 再起動しても起動するかを確かめるときだけ、再起動する。

   ```bash
   sudo systemctl reboot
   ```

   - 再起動しないなら、この項の手順 4 も飛ばす
   - **次の手順は、再起動した後にログインし直してから貼る**

1. 再起動の後、ログインより前にサービスが起動していたことを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user show hello-web.service -p ActiveEnterTimestamp
   loginctl show-session "${XDG_SESSION_ID}" -p Timestamp
   curl -s http://127.0.0.1:8080/
   ```

   - 1 行目の時刻（サービスが起動した時刻）が、2 行目の時刻（ログインした時刻）より前ならよい
   - `hello from quadlet` が出る

#### Podman: 使い方の基本

| コマンド | 用途 |
|---|---|
| `podman ps -a` | コンテナの一覧（止まっているものも） |
| `podman images` | イメージの一覧 |
| `podman run -d --name <名前> -p 127.0.0.1:<ポート>:<ポート> <イメージ>` | 裏で動かす。自分のユーザーでは 1024 未満のポートを使えない（[注意点](extra/podman.md#注意点)） |
| `podman logs <名前>` | ログを見る（`-f` で追い続ける） |
| `podman exec -it <名前> bash` | 動いているコンテナの中でシェルを開く |
| `podman stop <名前>` / `podman rm <名前>` | 止める / 消す |
| `podman rmi <イメージ>` | イメージを消す |
| `podman pull <イメージ>` | 取得だけする |
| `podman manifest inspect <イメージ>` | 取得せずに、対応しているアーキ（`arm64` など）を見る |
| `podman system df` | イメージ・コンテナ・ボリュームの容量 |
| `podman image prune -a` | どのコンテナも使っていないイメージを消す（`-a` 無しは、名前の無いイメージだけ） |
| `podman unshare ls -ln <パス>` | コンテナから見える UID で、ファイルの持ち主を見る |

- どれも `sudo` を付けない
- `sudo podman` は root 用の別の保管場所（`/var/lib/containers`）を使うので、自分のコンテナもイメージも見えない

#### Podman: 更新

- podman と、Quadlet で動かすコンテナのイメージを上げる
- 前提: [Podman](#podman)を通してある
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）

1. podman を更新する。

   ```bash
   sudo dnf upgrade podman
   ```

   - システム全体なら `sudo dnf upgrade`
   - 更新があると `[y/N]` で聞かれる。無ければ `Nothing to do.` で終わる
   - **次の手順は、答えて完了してから貼る**（続けて貼ると答えとして食われる）

1. [Quadlet で自動起動する](#podman-quadlet-で自動起動する)を通したときだけ、新しいイメージがあるか見てから当てる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   podman auto-update --dry-run
   podman auto-update
   ```

   - `UPDATED` の列が `false` なら、新しいイメージは無い
   - `true` なら、新しいイメージを取ってサービスを起動し直す

---

### podman-compose

- EPEL の podman-compose を入れ、compose ファイルで 2 つのコンテナを動かして確かめる
- 前提: [Podman](#podman)と[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 1 を通してある
  - `podman info --format '{{.Host.Security.Rootless}}'` が `true` を返さない、または `dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に前提を通す
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/podman-compose.md)・[参考資料](reference/podman-compose.md)・[ロールバックと注意点](extra/podman-compose.md)
- **手順 1 には対話入力がある**（トランザクション表の `[y/N]` と、EPEL の鍵の確認）。答えてから手順 2 を貼る
- **手順 6 の `podman-compose exec` は、動いている間に貼った行をコンテナへの入力として取り込む**。プロンプトが戻ってから次を貼る
- PC を再起動しても動かしておきたいものは、compose ではなく [Podman の Quadlet](#podman-quadlet-で自動起動する) で動かす（[注意点](extra/podman-compose.md#注意点)）

> [!IMPORTANT]
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（コンテナを自分のユーザーの rootless の podman で動かすため）

1. 入手できる版を見てから、podman-compose を入れる。

   ```bash
   dnf -q list --showduplicates podman-compose
   sudo dnf install podman-compose
   ```

   - 版は `podman-compose.noarch  1.5.0-1.el10_1  epel` のように 1 つだけ出る
   - 一緒に入るのは未導入の Python のライブラリで、最大 4 つ（`python3-click`・`python3-dotenv`・`python3-dotenv+cli`・`python3-pyyaml`）
   - **EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる**
   - fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）であることを確かめてから `y` と答える
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

1. podman-compose が入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   podman-compose version
   command -v podman-compose
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' podman-compose
   podman compose version
   ```

   - `podman-compose version 1.5.0` と `podman version 5.8.2` の 2 行が出る
   - `/usr/bin/podman-compose`、`podman-compose 1.5.0-1.el10_1 epel` が出る
   - 最後の `podman compose` は、`Executing external compose provider "/usr/bin/podman-compose"` と出してから、同じ 2 行を出す

1. 確認用の compose ファイルとページを置く。

   ```bash
   mkdir -p ~/compose-sample/html
   echo 'hello from compose' > ~/compose-sample/html/index.html
   cat > ~/compose-sample/compose.yaml <<'EOF'
   services:
     web:
       image: registry.access.redhat.com/ubi10/httpd-24:latest
       ports:
         - "127.0.0.1:8081:8080"
       volumes:
         - ./html:/var/www/html:Z
     check:
       image: registry.access.redhat.com/ubi10/httpd-24:latest
       command: sleep infinity
       init: true
   EOF
   cat ~/compose-sample/compose.yaml
   ```

1. compose ファイルのあるディレクトリで、コンテナを起動する。

   ```bash
   cd ~/compose-sample
   printf '\n\033[7m 確認 \033[0m\n'
   podman-compose up -d
   ```

   - 最後に `compose-sample_web_1` と `compose-sample_check_1` が出る

1. 起動したコンテナと、公開したポートを確かめる。

   ```bash
   cd ~/compose-sample
   printf '\n\033[7m 確認 \033[0m\n'
   podman-compose ps
   podman pod ps
   curl -s --retry 10 --retry-delay 1 --retry-all-errors http://127.0.0.1:8081/
   ```

   - `podman-compose ps` に 2 つのコンテナが `Up` で出て、`web` の `PORTS` に `127.0.0.1:8081->8080/tcp` が出る
   - `podman pod ps` に `pod_compose-sample` が `Running` で出る
   - `hello from compose` が出ればよい

1. `check` のコンテナから、サービス名 `web` でつながるか確かめる。

   ```bash
   cd ~/compose-sample
   printf '\n\033[7m 確認 \033[0m\n'
   podman-compose exec check curl -s http://web:8080/
   ```

   - `hello from compose` が出ればよい
   - **ほかの項の手順は、プロンプトが戻ってから貼る**（続けて貼るとコンテナの中のコマンドへの入力として食われる）

#### podman-compose: 使い方の基本

どれも compose ファイル（`compose.yaml`）のあるディレクトリで打つ。別の場所からなら `-f <ファイル>` を付ける。

| コマンド | 用途 |
|---|---|
| `podman-compose up -d` | 起動する（無ければ作る） |
| `podman-compose ps` | コンテナの一覧と状態 |
| `podman-compose logs <サービス>` | ログを見る |
| `podman-compose exec <サービス> <コマンド>` | 動いているコンテナの中でコマンドを動かす（動いている間に貼った行を取り込むので、終わってから次を打つ） |
| `podman-compose pull` | イメージを取り直す |
| `podman-compose down` | コンテナ・pod・ネットワークを消す。名前付きのボリュームは残る |
| `podman-compose down -v` | 名前付きのボリュームも消す（中のデータも消える） |

- 端末の画面（TUI）でサービスのログを見たり再起動したりするなら、[lazydocker の compose の節](#lazydocker-compose-のプロジェクトを見る)

#### podman-compose: 更新

- podman-compose を上げ、確認用の compose のイメージを取り直す
- 前提: [podman-compose](#podman-compose)を通してある（この項の手順 2 は `~/compose-sample` を使う）
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）

1. podman-compose を更新する。

   ```bash
   sudo dnf upgrade podman-compose
   ```

   - システム全体なら `sudo dnf upgrade`
   - 更新があると `[y/N]` で聞かれる。無ければ `Nothing to do.` で終わる
   - **次の手順は、答えて完了してから貼る**（続けて貼ると答えとして食われる）

1. イメージを取り直し、新しいイメージでコンテナを起動し直す。

   ```bash
   cd ~/compose-sample
   podman-compose pull
   printf '\n\033[7m 確認 \033[0m\n'
   podman-compose up -d
   ```

   - 新しいイメージが無いときも、`up -d` はコンテナの名前を出して終わる

---

### podman-tui

- EPEL の podman-tui を入れ、確認用のコンテナを画面（TUI）から止めて確かめる
- 前提: [Podman](#podman)の手順 7（API ソケット）までと、[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 1 を通してある
  - `systemctl --user is-active podman.socket` が `active` を返さない、または `dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に前提を通す
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/podman-tui.md)・[参考資料](reference/podman-tui.md)・[ロールバックと注意点](extra/podman-tui.md)
- **手順 1 には対話入力がある**（トランザクション表の `[y/N]` と、EPEL の鍵の確認）。答えてから手順 2 を貼る
- **手順 4 で podman-tui の画面（TUI）が開く**。`Ctrl+C` で終了してから手順 5 を貼る（`q` では終わらない）
- Docker の API でつなぐ TUI なら [lazydocker](#lazydocker)（違いは[選択した方針](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/podman-tui.md#選択した方針)）

> [!IMPORTANT]
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（podman-tui は、自分のユーザーの API ソケットにつなぐため）

1. 入手できる版を見てから、podman-tui を入れる。

   ```bash
   dnf -q list --showduplicates podman-tui
   sudo dnf install podman-tui
   ```

   - 版は `podman-tui.x86_64  1.10.0-1.el10_2  epel` のように 1 つだけ出る
   - 入るのは `podman-tui` の 1 パッケージだけ（ダウンロード 9.5 MB、展開後 32 MB）
   - **EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる**
   - fingerprint `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）なら `y`、違えば `N` で中断する
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

1. podman-tui が入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   podman-tui version
   command -v podman-tui
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' podman-tui
   ```

   - `podman-tui v1.10.0`、`/usr/bin/podman-tui`、`podman-tui 1.10.0-1.el10_2 epel` が出る

1. 画面で操作する、確認用のコンテナを動かす。

   ```bash
   podman run -d --name podman-tui-web registry.access.redhat.com/ubi10/httpd-24:latest
   printf '\n\033[7m 確認 \033[0m\n'
   podman ps --filter name=podman-tui-web --format '{{.Names}} {{.Status}}'
   ```

   - `podman-tui-web Up Less than a second` のように出る

1. podman-tui を起動し、確認用のコンテナを画面から止める。

   ```bash
   podman-tui
   ```

   - 最初に SYSTEM の画面が開き、上の `Connection:` に `✅ STATUS_OK`、`API version:` に `5.8.2` が出る
   - その下の `SYSTEM CONNECTIONS[1]` に、`localhost` が `✅ connected` で出る
   - `F4` でコンテナの画面（`CONTAINERS[N]`）に移り、↑↓ で `podman-tui-web` の行を選ぶ
   - `m` でコマンドのメニューを開き、↓ で `stop` まで下りて Enter を押す（確認は出ない）
   - 数秒で、`STATUS` が `▼ Exited (0) ...` に変わる
   - `Ctrl+C` で終了する
   - **次の手順は、`Ctrl+C` で終了してから貼る**（続けて貼ると podman-tui への操作として食われる）

1. 確認用のコンテナが止まったことを、podman でも確かめる。

   ```bash
   podman ps -a --filter name=podman-tui-web --format '{{.Names}} {{.Status}}'
   ```

   - `podman-tui-web Exited (0) ...` と出ればよい

#### podman-tui: 使い方の基本

| キー | 動作 |
|---|---|
| `F1` | ヘルプ（キーの一覧） |
| `F2`〜`F8` | SYSTEM・PODS・CONTAINERS・VOLUMES・IMAGES・NETWORKS・SECRETS の画面 |
| `l` / `h`（`→` / `←`） | 次 / 前の画面 |
| `j` / `k`（`↓` / `↑`） | 行を選ぶ |
| `m` | 選んだものへのコマンドのメニュー（コンテナなら `start`・`stop`・`logs`・`exec`・`rm` など） |
| `s` | 並べ替えのダイアログ |
| `Delete` | 選んだものを消す（確認の枠が出る） |
| `Tab` | ダイアログの中の項目を移る |
| `Esc` | メニューや確認の枠を閉じる |
| `Ctrl+C` | 終了（`q` では終わらない） |

- F キーが端末に取られて届かないときは、`l` / `h` で画面を移る
- 並べ替えのダイアログは、`Esc` で閉じないことがある。`Tab` で `Cancel` に移って Enter を押す
- 画面での操作は API を通るので、結果はそのまま `podman ps` などにも出る

#### podman-tui: 更新

- podman-tui を上げる
- 前提: [podman-tui](#podman-tui)を通してある
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）

1. podman-tui を更新する。

   ```bash
   sudo dnf upgrade podman-tui
   ```

   - システム全体なら `sudo dnf upgrade`
   - 更新があると `[y/N]` で聞かれる。無ければ `Nothing to do.` で終わる
   - EPEL の podman-tui が 2.x に上がったときは、上流の互換表で podman の版と合うかを確かめる（[注意点](extra/podman-tui.md#注意点)）

---

### lazydocker

- Homebrew の lazydocker を入れ、podman の API ソケットにつないで、確認用のコンテナを画面（TUI）から止める
- 前提: [共通の bash 設定](shell-terminal.md#共通の-bash-設定)、[Homebrew](#homebrew)の手順 1〜3、[Podman](#podman)の手順 7（API ソケット）まで、[Podman: Docker 向けのツールから使う](#podman-docker-向けのツールから使う)を通してある
  - ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない
  - `command -v brew podman` が 2 行を返さない、または `echo "${DOCKER_HOST}"` が `unix:///run/user/<UID>/podman/podman.sock` を返さなければ、先に前提を通す
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/lazydocker.md)・[参考資料](reference/lazydocker.md)・[ロールバックと注意点](extra/lazydocker.md)
- **手順 4 で lazydocker の画面（TUI）が開く**。`q` で終了してから手順 5 を貼る
- pod やシークレットも画面で扱うなら [podman-tui](#podman-tui)（違いは[選択した方針](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/lazydocker.md#選択した方針)）

> [!IMPORTANT]
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わず、lazydocker も自分のユーザーの API ソケットにつなぐため）

1. brew で lazydocker を入れる。

   ```bash
   brew install lazydocker
   ```

   - **次の手順は、確認が出たら答え、インストールが終わってシェルのプロンプトに戻ってから貼る**（依存の追加を確認する `[y/n]` が出る版では、続けて貼ると回答として食われる）

1. lazydocker が入ったことと、つなぐ先を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   lazydocker --version
   command -v lazydocker
   echo "${DOCKER_HOST}"
   curl -s --unix-socket "${DOCKER_HOST#unix://}" http://d/_ping; echo
   ```

   - 1 行目で `Version: 0.25.2` と `BuildSource: Homebrew` が出る
   - `/home/linuxbrew/.linuxbrew/bin/lazydocker` が出る
   - `unix:///run/user/<UID>/podman/podman.sock` と `OK` が出れば、lazydocker は podman の API ソケットにつなぐ
   - 3 行目が空なら、`DOCKER_HOST` が無い。[Podman: Docker 向けのツールから使う](#podman-docker-向けのツールから使う)を通す（参考資料を参照）

1. 画面で操作する、確認用のコンテナを動かす。

   ```bash
   podman run -d --name lazydocker-web --label name=lazydocker-web registry.access.redhat.com/ubi10/httpd-24:latest
   printf '\n\033[7m 確認 \033[0m\n'
   podman ps --filter name=lazydocker-web --format '{{.Names}} {{.Status}}'
   ```

   - `lazydocker-web Up Less than a second` のように出る

1. lazydocker を起動し、確認用のコンテナを画面から止める。

   ```bash
   lazydocker
   ```

   - 左に `[3]─Containers`・`[4]─Images`・`[5]─Volumes`・`[6]─Networks`、右に `Logs - Stats - Env - Config - Top` の枠が出る
   - ↑↓ で `running` の `lazydocker-web` の行を選ぶと、右の枠に Apache のログ（`... configured -- resuming normal operations` など）が出る
   - `s` を押し、`Are you sure you want to stop this container?` に `y` と答える
   - 行が `exited (0)` に変わる
   - `q` で終了する
   - **次の手順は、`q` で終了してから貼る**（続けて貼ると lazydocker への操作として食われる）

1. 確認用のコンテナが止まったことと、設定ファイルができたことを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   podman ps -a --filter name=lazydocker-web --format '{{.Names}} {{.Status}}'
   ls -l ~/.config/lazydocker
   ```

   - `lazydocker-web Exited (0) ...` と出ればよい
   - `config.yml`（0 バイト）がある

#### lazydocker: podman exec でシェルを開く

- lazydocker の `E`（シェルを開く）と `a`（アタッチ）は、`docker` コマンドを直接呼ぶ。podman だけの PC では、`+ docker exec -it ...` と出るだけで何も起きない（[注意点](extra/lazydocker.md#注意点)）
- この項で、`c`（自分で足したコマンドのメニュー）に、`podman exec` でシェルを開くコマンドを足す
- 前提: [lazydocker](#lazydocker)を通してある（確認用のコンテナ `lazydocker-web` と、設定ファイル `~/.config/lazydocker/config.yml` を使う）
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）

1. [手順 4](#lazydocker) で止めた確認用のコンテナを、起動し直す。

   ```bash
   podman start lazydocker-web
   ```

   - `lazydocker-web` と出る

1. `podman exec` でシェルを開くコマンドを、設定ファイルに足す。

   ```bash
   cat >> ~/.config/lazydocker/config.yml <<'EOF'
   customCommands:
     containers:
       - name: podman exec sh
         attach: true
         command: 'podman exec -it {{ .Container.ID }} sh'
   EOF
   printf '\n\033[7m 確認 \033[0m\n'
   cat ~/.config/lazydocker/config.yml
   ```

   - 読み戻した中身に、足した 5 行が出る
   - **注意**: 既に `customCommands:` があるなら、`cat >>` で足さずに手で中身をまとめる。同じキーが 2 つあると、後ろのものだけが使われ、前の定義は黙って無視される（参考資料を参照）

1. lazydocker を起動し、足したコマンドでコンテナのシェルを開く。

   ```bash
   lazydocker
   ```

   - `running` の `lazydocker-web` の行を選び、`c` を押す
   - `Custom Command:` の枠の `podman exec sh` で Enter を押すと、`sh-5.2$` のプロンプトになる
   - `id` を打つと `uid=1001(default) gid=0(root) groups=0(root)` と出る
   - `exit` で抜け、`Press enter to return to lazydocker ...` で Enter を押すと画面に戻る
   - `q` で終了する
   - **ほかの項の手順は、`q` で終了してから貼る**（続けて貼ると lazydocker への操作として食われる）

#### lazydocker: compose のプロジェクトを見る

- lazydocker は、起動したディレクトリで `docker compose config --quiet` が通ったときだけ、`[1]─Project` と `[2]─Services` の枠を出す
- podman だけの PC では通らないので、この項で compose のコマンドを `podman-compose` に替える
- 前提: [lazydocker](#lazydocker)を通し、[podman-compose](#podman-compose)を手順 4 まで通して、`~/compose-sample` のコンテナが動いている
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）

1. compose のコマンドを `podman-compose` にする設定を、設定ファイルに足す。

   ```bash
   cat >> ~/.config/lazydocker/config.yml <<'EOF'
   commandTemplates:
     dockerCompose: podman-compose
   EOF
   printf '\n\033[7m 確認 \033[0m\n'
   cat ~/.config/lazydocker/config.yml
   ```

   - 読み戻した中身に、足した 2 行が出る
   - **注意**: 既に `commandTemplates:` があるなら、`cat >>` で足さずに手で中身をまとめる

1. compose ファイルのあるディレクトリで lazydocker を起動し、`web` のサービスを再起動する。

   ```bash
   cd ~/compose-sample
   lazydocker
   ```

   - 左の上に `[1]─Project`（`compose-sample`）と `[2]─Services`（`check`・`web`）の枠が出る
   - 確認用のコンテナなど compose の外のものは、`[3]─Standalone Containers` に移る
   - `web` の行を選ぶと、右の枠に Apache のログが出る
   - `r` を押すと、確認なしに `web` が再起動する
   - `q` で終了する
   - **次の手順は、`q` で終了してから貼る**（続けて貼ると lazydocker への操作として食われる）

1. `web` だけが再起動したことを確かめる。

   ```bash
   cd ~/compose-sample
   printf '\n\033[7m 確認 \033[0m\n'
   podman-compose ps --format '{{.Names}} {{.Status}}'
   ```

   - `compose-sample_web_1 Up 15 seconds` のように、`web` の動いている時間が `check` より短ければよい

#### lazydocker: root でも使う

- この項で、システムの podman の API ソケット（`/run/podman/podman.sock`）を有効にし、root のコンテナを lazydocker で見る
- **root のコンテナを lazydocker で見ないなら、この項は不要**
- root のコンテナは `/var/lib/containers` にあり、[手順 4](#lazydocker)の一般ユーザーの画面には出ない
- 前提: [lazydocker](#lazydocker)と[共通の bash 設定を root に入れる](shell-terminal.md#共通の-bash-設定を-root-に入れる)を通してある
  - この設定が Homebrew の PATH と root 用の `DOCKER_HOST` を読む。sudo の `secure_path` だけではこの項の前提を満たさない
  - `sudo -i bash -c 'command -v lazydocker'` が `/home/linuxbrew/.linuxbrew/bin/lazydocker` を返せばよい
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）。root の権限は、コマンドに付けた `sudo` で使う
- [注意点](extra/podman.md#注意点)と[root を使う条件](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/podman.md#選択した方針)を先に確認する
- root の共通設定が、システムのソケットを指す `DOCKER_HOST` を入れる。`/root/.bashrc` には追記しない
- 起動は `sudo -i lazydocker`。`su -`・`sudo -i`・`sudo -s` で開いた root のシェルでは `lazydocker`
- `-i` の無い `sudo lazydocker` は root の `~/.bashrc` を読まないので、root のコンテナにつながらない（[root で使うときの補足](reference/lazydocker.md#root-で使うときの補足)）
- この項の手順 4 で lazydocker の画面（TUI）が開く
- 補足: [root で使うときの補足](reference/lazydocker.md#root-で使うときの補足)

> [!WARNING]
> - root の lazydocker は、一般ユーザーが書き換えられるプログラムを root 権限で動かす。[root 用 Homebrew](#homebrew-を-root-のシェルでも使う)と同じ導入条件で行う
> - システムの API ソケットにつなげるのは root だけ。権限を緩めない（つなげると、root と同じことができる）

1. システムの podman の API ソケットを有効にして、root で応答を確かめる。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     sudo systemctl enable --now podman.socket
     systemctl is-active podman.socket
     sudo curl -s --unix-socket /run/podman/podman.sock http://d/_ping; echo
     sudo podman --remote version --format '{{.Server.Version}}'
   }
   ```

   - `active`・`OK`・`5.8.2` が出ればよい
   - `Created symlink …` が出なければ、前から有効だった。元に戻すときは、この項の手順 8 を飛ばす

1. root の共通設定が接続先を設定したことを確かめる。

   ```bash
   sudo -i bash -c 'printenv DOCKER_HOST; command -v lazydocker'
   ```

   - `unix:///run/podman/podman.sock` と `/home/linuxbrew/.linuxbrew/bin/lazydocker` が出ればよい
   - root 自身の [共通設定](shell-terminal.md#共通の-bash-設定を-root-に入れる)を先に導入する。`/root/.bashrc` への `DOCKER_HOST` の追記は不要
   - 接続先が違う場合はここで止め、既存の用途を確認する

1. 確認用のコンテナを root で動かす。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     sudo podman run -d --name lazydocker-root-web --label name=lazydocker-root-web registry.access.redhat.com/ubi10/httpd-24:latest
     sudo podman ps --filter name=lazydocker-root-web --format '{{.Names}} {{.Status}}'
   }
   ```

   - コンテナの ID の後に、`lazydocker-root-web Up Less than a second` のように出る

1. root で lazydocker を起動し、確認用のコンテナを止める。

   ```bash
   sudo -i lazydocker
   ```

   - `[3]─Containers` に `running  lazydocker-root-web` の行が出る。[手順 3](#lazydocker) の `lazydocker-web` は出ない
   - ↑↓ で `lazydocker-root-web` の行を選び、`s` を押し、`Are you sure you want to stop this container?` に `y` と答える
   - 行が `exited (0)` に変わる
   - `q` で終了する
   - **次の手順は、`q` で終了してから貼る**（続けて貼ると lazydocker への操作として食われる）

1. 確認用のコンテナが止まったことと、root の設定ファイルができたことを確かめる。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     sudo podman ps -a --filter name=lazydocker-root-web --format '{{.Names}} {{.Status}}'
     sudo ls -l /root/.config/lazydocker
   }
   ```

   - `lazydocker-root-web Exited (0) ...` と出ればよい
   - `config.yml`（0 バイト）は root の設定ファイル

1. 元に戻すときは、root の確認用コンテナと lazydocker の設定を消す。

   ```bash
   {
     sudo podman rm -f lazydocker-root-web
     sudo rm -rf /root/.config/lazydocker
   }
   ```

   - root の設定ファイルに手で足したものも消える
   - 共通設定と `~/.bashrc` は変更しない。ソケットはこの項の手順 8 で止める

1. 元に戻すときは、root でほかに使っていないときだけ、root のイメージを消す。

   ```bash
   sudo podman rmi registry.access.redhat.com/ubi10/httpd-24:latest
   ```

   - `Untagged:` と `Deleted:` が出る
   - 同じイメージの root のコンテナが残っていると、消せずにエラーになる

1. 元に戻すときは、この項の手順 1 で有効にしたときだけ、システムの API ソケットを止める。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     sudo systemctl disable --now podman.socket
     systemctl is-active podman.socket
   }
   ```

   - `Removed …` と `inactive` が出ればよい
   - Cockpit の podman の画面など、ほかのものも、このソケットを使うことがある

#### lazydocker: 使い方の基本

| キー | 動作 |
|---|---|
| `↑` / `↓` | 行を選ぶ |
| `←` / `→`、`1`〜`6` | 枠を移る（`3` が Containers、`4` が Images など） |
| `[` / `]` | 右の枠のタブ（Logs・Stats・Env・Config・Top）を移る |
| `s` | 止める（確認が出る） |
| `r` | 再起動する（確認は出ない） |
| `m` | ログを画面いっぱいに追う（`Ctrl+C` で戻る） |
| `e` | 止まったコンテナを隠す / また出す |
| `d` | 消す（`remove`・`remove with volumes`・`cancel` から選ぶ） |
| `c` | 自分で足したコマンドのメニュー（[podman exec の節](#lazydocker-podman-exec-でシェルを開く)） |
| `x` | 選んでいる枠のキーの一覧 |
| `q` | 終了 |

- `E`（シェル）と `a`（アタッチ）は `docker` コマンドを呼ぶので、podman だけの PC では何も起きない。シェルは `c` から開く
- 画面は英語で出る（lazydocker に日本語の翻訳は無い）

#### lazydocker: 更新

- Homebrew の lazydocker を上げる
- 前提: [lazydocker](#lazydocker)を通してある
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）。Homebrew の更新は root のシェルでは行わない

1. lazydocker を更新する。

   ```bash
   brew upgrade lazydocker
   ```

   - 新しい版が無ければ `Warning: lazydocker 0.25.2 already installed` のように出て、何もしない
   - すべてまとめて上げるなら `brew upgrade`

---

### Distrobox

- EPEL の distrobox を入れ、podman のコンテナでほかのディストリ（既定は Ubuntu 24.04）のボックスを作って入る
- 前提: [Podman](#podman)と[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 1 を通してある
  - `podman info --format '{{.Host.Security.Rootless}}'` が `true` を返さない、または `dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に前提を通す
- 実行場所: ホストの、自分のユーザーでログインした bash（GNOME の端末か SSH）
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/distrobox.md)・[参考資料](reference/distrobox.md)・[ロールバックと注意点](extra/distrobox.md)
- この項の手順 1 で変数を設定したシェルに貼る
- **手順 2 には対話入力がある**（トランザクション表の `[y/N]` と、EPEL の鍵の確認）。答えてから手順 3 を貼る
- **手順 5 と 6 はボックスの中のコマンドになる**。手順 5 は終わってから、手順 6 は `exit` で戻ってから、次を貼る

> [!IMPORTANT]
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（ボックスは自分のユーザーの rootless の podman で動かすため）

1. 変数を設定する。

   ```bash
   DBX_NAME=ubuntu                                  # ボックスの名前。<DBX_NAME>
   DBX_IMAGE=quay.io/toolbx/ubuntu-toolbox:24.04    # 元にするイメージ。<DBX_IMAGE>
   printf '\n\033[7m 確認 \033[0m\n'
   printf '%-9s = %s\n' DBX_NAME "${DBX_NAME}" DBX_IMAGE "${DBX_IMAGE}"
   ```

   - **編集が必須の変数は無い**。既定のままなら、Ubuntu 24.04 のボックスができる
   - 別のディストリにするときだけ `DBX_IMAGE` を変える（候補はこの手順の補足）
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. 入手できる版を見てから、distrobox を入れる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   dnf -q list --showduplicates distrobox
   sudo dnf install distrobox
   ```

   - 版は `distrobox.noarch  1.8.2.3-1.el10_2  epel` のように 1 つだけ出る
   - `hicolor-icon-theme` が未導入なら一緒に入る。導入済みなら追加されない
   - **EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる**
   - fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）であることを確かめてから `y` と答える
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

1. distrobox が入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   distrobox version
   command -v distrobox
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' distrobox
   distrobox list
   ```

   - `distrobox: 1.8.2.3`、`/usr/bin/distrobox`、`distrobox 1.8.2.3-1.el10_2 epel` が出る
   - `distrobox list` は見出しの行だけを出す（ボックスはまだ無い）

1. ボックスを作る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   distrobox create --yes --name "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" --image "${DBX_IMAGE:?手順 1 の DBX_IMAGE が空のまま。値を入れて貼り直す}"
   distrobox list
   ```

   - イメージを取得してから、`Distrobox 'ubuntu' successfully created.` が出る
   - `distrobox list` に、`ubuntu`・`Created`・`quay.io/toolbx/ubuntu-toolbox:24.04` の行が出る
   - `--yes` は、イメージの取得を確かめる問い合わせ（`Do you want to pull the image now? [Y/n]`）を飛ばす

1. 初回の初期化を兼ねて、ボックスの中でコマンドを 1 つ動かす。

   ```bash
   distrobox enter "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- sh -c 'grep PRETTY_NAME /etc/os-release; id -un; pwd'
   ```

   - 初回はボックスの初期化が走る。`[ OK ]` の行が並んだ後に `Container Setup Complete!` が出る
   - その後に `PRETTY_NAME="Ubuntu 24.04.5 LTS"`・自分のユーザー名・`/home/<USER>` が出る
   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

1. ボックスのシェルに入る。

   ```bash
   distrobox enter "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}"
   ```

   - プロンプトが `📦[<USER>@ubuntu ~]$` に変わる。ここから先はボックスの中のシェル
   - SSH など画面の無いログインから入ると、`host-spawn: command not found` が出ることがある。出なくても、ボックスのプロンプトに入れればよい
   - `exit` でホストに戻る
   - **ほかの項の手順は、`exit` でホストに戻ってから貼る**

#### Distrobox: ボックスのコマンドをホストから呼ぶ

- 例として、AppStream と EPEL に無い `ffmpeg` を Ubuntu のボックスに入れ、ホストのシェルから `ffmpeg` で呼べるようにする
- ボックスに入れたものはボックスの中にだけある。ホストには、ボックスを呼び出す小さなスクリプトが `~/.local/bin` に置かれる
- 前提: [Distrobox](#distrobox)を通して、ボックスを作ってある
- 実行場所: ホストの、自分のユーザーでログインした bash（GNOME の端末か SSH）。ボックスの中のシェルには貼らない
- **この項の手順 2〜4 は `distrobox enter` で終わる**。プロンプトが戻ってから次を貼る

1. 変数を設定する（既定のままでよい）。

   ```bash
   DBX_NAME=ubuntu                                  # ボックスの名前。<DBX_NAME>
   printf '\n\033[7m 確認 \033[0m\n'
   printf '%-9s = %s\n' DBX_NAME "${DBX_NAME}"
   ```

   - [Distrobox](#distrobox)の手順 1 で `DBX_NAME` を変えたときは、同じ値を入れる
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. ボックスのパッケージの一覧を新しくする。

   ```bash
   distrobox enter "${DBX_NAME:?この項の手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- sudo apt-get update
   ```

   - `Reading package lists...` または `パッケージリストを読み込んでいます... 完了` で終わる
   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

1. ボックスに ffmpeg を入れる。

   ```bash
   distrobox enter "${DBX_NAME:?この項の手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- sudo apt-get install -y ffmpeg
   ```

   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

1. ffmpeg をホストから呼べるように書き出す。

   ```bash
   distrobox enter "${DBX_NAME:?この項の手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- distrobox-export --bin /usr/bin/ffmpeg --export-path ~/.local/bin
   ```

   - `/usr/bin/ffmpeg from ubuntu exported successfully in /home/<USER>/.local/bin.` と `OK!` が出る
   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

1. ホストのシェルから ffmpeg を呼ぶ。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   command -v ffmpeg
   ~/.local/bin/ffmpeg -version | head -1
   ```

   - 最後の行が `ffmpeg version 6.1.1-3ubuntu5 ...` なら、書き出したコマンドを呼べている
   - `command -v ffmpeg` が `/home/<USER>/.local/bin/ffmpeg` 以外なら、通常の `ffmpeg` は既存の別の版を呼ぶ。ボックスの版を使うときは `~/.local/bin/ffmpeg` で呼ぶ

#### Distrobox: 更新

- distrobox と、ボックスの中のパッケージを上げる
- 前提: [Distrobox](#distrobox)を通して、ボックスを作ってある
- 実行場所: ホストの、自分のユーザーでログインした bash（GNOME の端末か SSH）。ボックスの中のシェルには貼らない

1. 変数を設定する（既定のままでよい）。

   ```bash
   DBX_NAME=ubuntu                                  # ボックスの名前。<DBX_NAME>
   printf '\n\033[7m 確認 \033[0m\n'
   printf '%-9s = %s\n' DBX_NAME "${DBX_NAME}"
   ```

   - [Distrobox](#distrobox)の手順 1 で `DBX_NAME` を変えたときは、同じ値を入れる
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. distrobox を更新する。

   ```bash
   sudo dnf upgrade distrobox
   ```

   - システム全体なら `sudo dnf upgrade`
   - 更新があると `[y/N]` で聞かれる。無ければ `Nothing to do.` で終わる
   - **次の手順は、答えて完了してから貼る**（続けて貼ると答えとして食われる）

1. ボックスの中のパッケージを更新する。

   ```bash
   distrobox upgrade "${DBX_NAME:?この項の手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}"
   ```

   - **ボックスの中身は `dnf upgrade` では上がらない**。ボックスごとにこの手順を行う
   - **ほかの項の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

---

## ファイルの共有と同期

- Dropbox（公式のクライアントと rclone）。Samba のクライアントとサーバーは[Samba のセットアップ](samba.md)、Syncthing は[Syncthing のセットアップ](syncthing.md)で入れる

### Dropbox

- Dropbox の公式クライアント（ヘッドレスのデーモン）をホームに入れ、ユーザーサービスとして常駐させ、この PC を Dropbox のアカウントにリンクする
- 前提: [ユーザーサービスの常駐](#ユーザーサービスの常駐)（linger。ログアウト中も Dropbox を動かすため）を通してある
  - `loginctl show-user "$(id -u)" -p Linger` が `Linger=yes` を返さなければ、先に[ユーザーサービスの常駐](#ユーザーサービスの常駐)を通す
  - **ログアウト中も同期するなら、PC を眠らせない**（[画面オフ・画面ロック・自動サスペンドを止める](#画面オフ画面ロック自動サスペンドを止める)を通す。Workstation で入れた PC は、ログイン画面のまま 15 分で眠る）
- 実行場所: x86_64 の PC の、自分のユーザーの bash（デスクトップの端末か SSH）。**手順 8 はブラウザでリンクする**。この PC でなくても、ブラウザがあればどこでもよい
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/dropbox.md)・[参考資料](reference/dropbox.md)・[ロールバックと注意点](extra/dropbox.md)
- **手順 2 で止まる**（fingerprint の目視）

> [!IMPORTANT]
> - **x86_64 の PC で実行する**。Dropbox は Linux の ARM 版を出していないので、Raspberry Pi 5（aarch64）では [Dropbox と rclone](#dropbox-と-rclone) を使う
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（デーモンは自分のホームに入り、同期するファイルの持ち主として動く）

1. この PC で公式クライアントが動くかを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   uname -m
   stat -f -c %T "${HOME}"
   df -h "${HOME}"
   ```

   - `uname -m` が `x86_64` ならよい
   - **`aarch64` ならここで止め、[Dropbox と rclone](#dropbox-と-rclone) へ進む**
   - `stat` が `xfs`・`ext2/ext3`（ext4 もこう出る）・`btrfs` のどれかなら、Dropbox が対応するファイルシステム
   - `df` の `Avail` が、Dropbox で使っている容量より大きいこと

1. Dropbox の署名鍵を落として、fingerprint を見る。

   ```bash
   curl -fsSL https://linux.dropbox.com/fedora/rpm-public-key.asc -o /tmp/dropbox-key.asc
   printf '\n\033[7m 確認 \033[0m\n'
   gpg --show-keys --with-fingerprint /tmp/dropbox-key.asc
   ```

   - `gpg: command not found` と出たら、`sudo dnf install -y gnupg2` で入れてから貼り直す
   - 次の値と一致することを目で確かめる
     - fingerprint `1C61 A265 6FB5 7B7E 4DE0  F4C1 FC91 8B33 5044 912E`
     - uid `Dropbox Automatic Signing Key <linux@dropbox.com>`
   - 違っていればここで止める
   - **次の手順は、fingerprint と uid が一致するのを確かめてから貼る**

1. tarball と署名を落とし、署名が正しいときだけホームに展開する。

   ```bash
   DBX_URL=$(curl -fsS -o /dev/null -w '%{redirect_url}' 'https://www.dropbox.com/download?plat=lnx.x86_64')
   printf '\n\033[7m 確認 \033[0m\n'
   echo "${DBX_URL}"
   curl -fL -o /tmp/dropbox-lnx.tar.gz "${DBX_URL:?URL を取れなかった。この手順を貼り直す}"
   curl -fsSL -o /tmp/dropbox-lnx.tar.gz.asc "${DBX_URL}.asc"
   gpg --dearmor < /tmp/dropbox-key.asc > /tmp/dropbox-key.gpg
   gpgv --keyring /tmp/dropbox-key.gpg /tmp/dropbox-lnx.tar.gz.asc /tmp/dropbox-lnx.tar.gz && tar -xzf /tmp/dropbox-lnx.tar.gz -C ~
   ```

   - `echo` が出す URL の末尾に版が入っている（例 `dropbox-lnx.x86_64-270.4.3312.tar.gz`、約 87 MiB）
   - `gpgv: Good signature from "Dropbox Automatic Signing Key <linux@dropbox.com>"`（日本語では同じ署名者からの `正しい署名`）が出れば、`~/.dropbox-dist` に展開されている
   - `BAD signature` のときは展開されない（`tar` は `&&` の後ろにある）ので、ここで止める

1. 展開した版を確かめ、落としたファイルを消す。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   ls ~/.dropbox-dist
   du -sh ~/.dropbox-dist
   rm -f /tmp/dropbox-lnx.tar.gz /tmp/dropbox-lnx.tar.gz.asc /tmp/dropbox-key.asc /tmp/dropbox-key.gpg
   ```

   - `VERSION`・`dropbox-lnx.x86_64-<版>`・`dropboxd` の 3 つが出る
   - `du` は約 150 MB（270.4.3312 で `153M`）

1. 操作に使う `dropbox` コマンドを `~/.local/bin` に置く。

   ```bash
   mkdir -p ~/.local/bin
   curl -fsSL -o ~/.local/bin/dropbox https://linux.dropbox.com/packages/dropbox.py
   chmod +x ~/.local/bin/dropbox
   printf '\n\033[7m 確認 \033[0m\n'
   command -v dropbox
   dropbox version
   ```

   - `command -v` が `/home/<USER>/.local/bin/dropbox` を出す
   - `Dropbox daemon version: 272.4.3798` と `Dropbox command-line interface version: 2026.09.28` のように、本体と CLI の版が出る

1. ユーザーサービスを置いて、Dropbox を起動する。

   ```bash
   mkdir -p ~/.config/systemd/user
   cat > ~/.config/systemd/user/dropbox.service <<'EOF'
   [Unit]
   Description=Dropbox (headless)

   [Service]
   Type=simple
   ExecStart=%h/.dropbox-dist/dropboxd
   Restart=always
   RestartSec=10
   UnsetEnvironment=DISPLAY WAYLAND_DISPLAY

   [Install]
   WantedBy=default.target
   EOF
   systemctl --user daemon-reload
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user enable --now dropbox.service
   systemctl --user is-enabled dropbox.service   # enabled
   systemctl --user is-active dropbox.service    # active
   ```

   - `Created symlink '.../default.target.wants/dropbox.service' → ...` が出る
   - `enabled`・`active` が出ればよい

1. リンク用の URL を出す。

   ```bash
   sleep 30
   printf '\n\033[7m 確認 \033[0m\n'
   dropbox status
   ```

   - `To link this computer to a Dropbox account, visit the following url:` の次の行に、URL（`https://www.dropbox.com/cli_link_nonce?nonce=...`）が出る
   - `Connecting...` や `Starting...` だけで URL が出なければ、少し待って `dropbox status` だけを貼り直す
   - **URL は他人に見せない**（開いた人の Dropbox アカウントにこの PC がつながる）

1. ブラウザで手順 7 の URL を開き、この PC を Dropbox に接続する。

   - Dropbox にログインして、この PC の接続を承認する（この PC のブラウザでなくてもよい）
   - **次の手順は、ブラウザで接続し終えてから貼る**

1. 同期が始まったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   dropbox status
   ls ~/Dropbox
   journalctl --user -u dropbox.service -n 20 --no-pager
   ```

   - `dropbox status` からリンク用の URL の案内が消え、同期の状態が出れば、リンクできている
   - `~/Dropbox` ができ、アカウントのファイルが落ちてくる（リンクする前は `No such file or directory`）

#### Dropbox: 使い方の基本

| コマンド | 用途 |
|---|---|
| `dropbox status` | 状態を見る。リンクしていないときは、リンク用の URL を出す |
| `dropbox filestatus ~/Dropbox/<パス>` | ファイルごとの同期の状態 |
| `dropbox exclude add ~/Dropbox/<フォルダ>` | そのフォルダをこの PC に同期しない（選択型同期） |
| `dropbox exclude list` | 同期しないフォルダの一覧（`exclude remove` で同期に戻す） |
| `dropbox sharelink ~/Dropbox/<パス>` | 共有リンクを作る |
| `dropbox lansync n` | LAN 同期を止める（`y` で戻す） |
| `dropbox help` | コマンドの一覧（`dropbox help <コマンド>` で使い方） |
| `systemctl --user stop dropbox.service` | デーモンを止める（`start` で動かす）。`dropbox stop` は 10 秒後に戻される |
| `journalctl --user -u dropbox.service -f` | デーモンの出力を追う |

  - `exclude add` / `exclude remove` は何も出さずに終わった
  - `exclude list` は `Dropbox isn't responding!`、`filestatus` は `File doesn't exist`、`sharelink` は `Couldn't get shared link: ... does not exist` を返した
- `exclude` に渡すパスは、Dropbox フォルダの中でなければならない（`dropbox help exclude` の `Any specified path must be within Dropbox.`）
- 公式ヘルプは、これらのコマンドを Dropbox フォルダの一番上（`~/Dropbox`）で実行するよう案内している

#### Dropbox: 更新

- Dropbox のデーモンと CLI の版を確かめ、CLI（dropbox.py）を取り直す
- 前提: [Dropbox](#dropbox)を通してある
- 実行場所: Dropbox を入れた PC の、自分のユーザーの bash（デスクトップの端末か SSH）
- デーモンは、`~/.dropbox-dist` の中身を自分で入れ替えて更新する作り（tarball の README と `dropbox.py` の説明）
- `dropbox.py` は自分では更新しない

1. デーモンと CLI の版を確かめる。

   ```bash
   dropbox version
   ```

   - 手で入れ直すときは、`systemctl --user stop dropbox.service` で止めてから[Dropbox](#dropbox)の手順 2〜4 をやり直し、`systemctl --user start dropbox.service` で動かす
   - 入れ直すと、古い版のディレクトリ（`~/.dropbox-dist/dropbox-lnx.x86_64-<古い版>`）が残る。新しい版で動いているのを `dropbox version` で確かめてから、`rm -rf` で消してよい

1. CLI（dropbox.py）を取り直す。

   ```bash
   curl -fsSL -o ~/.local/bin/dropbox https://linux.dropbox.com/packages/dropbox.py
   dropbox version
   ```

---

### Dropbox と rclone

- Homebrew で rclone を入れ、Dropbox と `~/Dropbox` を `rclone bisync` で 15 分ごとに同期する（公式クライアントの無い aarch64 向け）
- 前提: [Homebrew](#homebrew)の手順 1〜3 と、[ユーザーサービスの常駐](#ユーザーサービスの常駐)（linger）を通してある
  - `command -v brew` で何も出なければ、先に[Homebrew](#homebrew)を通す
  - `loginctl show-user "$(id -u)" -p Linger` が `Linger=yes` でなければ、先に[ユーザーサービスの常駐](#ユーザーサービスの常駐)を通す
  - **ログアウト中も同期するなら、Raspberry Pi 5 を眠らせない**（[画面オフ・画面ロック・自動サスペンドを止める](#画面オフ画面ロック自動サスペンドを止める)を通す）
- 実行場所: Raspberry Pi 5（aarch64）などの、自分のユーザーの bash（デスクトップの端末か SSH）。**手順 3 はブラウザで認証する**
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/dropbox-rclone.md)・[参考資料](reference/dropbox-rclone.md)・[ロールバックと注意点](extra/dropbox-rclone.md)
- **手順 3・6・7・8 で止まる**（ブラウザでの許可・エディタ・`--dry-run` の結果の確認・最初の同期の完了）
- 手順 1 の導入で `[y/n]` が出たら、答えてプロンプトが戻ってから手順 2 を貼る
- x86_64 の PC では、公式クライアントの [Dropbox](#dropbox) を勧める（この手順も同じように動く）

> [!IMPORTANT]
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わず、同期するファイルの持ち主として動かすため）
> - 手順 2 は、Raspberry Pi 5 のデスクトップの端末で貼るか、手元の PC から `ssh -L localhost:53682:localhost:53682 <USER>@<HOSTNAME>` で入り直してから貼る

1. brew で rclone を入れる。

   ```bash
   brew install rclone
   ```

   - 最後の Caveats の「`mount` subcommand on macOS」は macOS の話で、ここでは関係ない
   - 依存の一覧と `[y/n]` が出たら、入るものを見て `y` と答える
   - **次の手順は、導入が終わってプロンプトが戻ってから貼る**（問い合わせ中に続けて貼ると、後ろの文字が答えとして読まれる）

1. rclone が入ったことを確かめ、Dropbox を登録する。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   rclone version
   command -v rclone
   rclone config create dropbox dropbox >/dev/null
   ```

   - `rclone v1.75.2` のような版と `os/arch:` などの行、`/home/linuxbrew/.linuxbrew/bin/rclone` が出ればよい
   - `http://127.0.0.1:53682/auth?state=...` が表示され、`Waiting for code...` で許可を待つ（手順 3 で許可する）
   - SSH で入っているときは、`ssh -L` でトンネルを張った端末で貼る

1. ブラウザで手順 2 の URL を開き、rclone のアクセスを許可する。

   - Dropbox にログインしてから許可する
   - SSH で入っているときは、手元の PC のブラウザで開く
   - **次の手順は、ブラウザで許可してプロンプトが戻ってから貼る**

1. Dropbox に届くかと、使っている容量を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   rclone listremotes --long
   rclone about dropbox:
   rclone lsd dropbox:
   df -h ~
   ```

   - `listremotes` が `dropbox: dropbox` を出す
   - `lsd` が Dropbox の一番上のフォルダを並べる
   - **`Used:` が `Avail` より大きいとき、または一部のフォルダだけ同期するときは、手順 6 で絞る**
   - 全部同期するなら、手順 6 は飛ばす

1. フィルタのファイルと、同期先の `~/Dropbox` を用意する。

   ```bash
   mkdir -p ~/.config/rclone ~/Dropbox
   cat > ~/.config/rclone/dropbox-filters.txt <<'EOF'
   # rclone bisync のフィルタ（書き方は https://rclone.org/filtering/ ）
   # このファイルを変えたら、次の同期は --resync で行う（Dropbox と rclone の「同期するフォルダを変える」）

   # Dropbox が同期しないファイル（rclone の bisync の文書の例から）
   - .dropbox.attr
   - ~*.tmp
   - ~$*
   - .~*
   - desktop.ini
   - .dropbox

   # rclone が強制終了や電源断で残す書きかけのファイル
   - *.partial

   # 一部のフォルダだけ同期するときは、同期するフォルダを「+ /名前/**」で並べ、最後に「- **」を置く（上から順に判定される）
   # + /Documents/**
   # + /Photos/**
   # - **
   EOF
   printf '\n\033[7m 確認 \033[0m\n'
   grep -v -e '^#' -e '^$' ~/.config/rclone/dropbox-filters.txt
   ```

   - 最後の `grep` が、有効な 7 行（`- .dropbox.attr` から `- *.partial` まで）を出す

1. 同期するフォルダを絞るときだけ、フィルタのファイルを編集する。

   ```bash
   vi ~/.config/rclone/dropbox-filters.txt
   ```

   - 最後の 3 行の `# ` を外し、同期するフォルダを `+ /名前/**` の形で並べる（`/Documents` と `/Photos` は例なので書き換える）
   - `- **` は最後の行に残す
   - **次の手順は、保存して `vi` を閉じてから貼る**

1. 最初の同期で何が起きるかを見る（`--dry-run`）。

   ```bash
   rclone bisync dropbox: ~/Dropbox --filters-file ~/.config/rclone/dropbox-filters.txt --resync --max-lock 2m --dry-run --verbose
   ```

   - `Resync is copying files to - Path2` の後の `Skipped copy as --dry-run is set` の行が、Dropbox から手元に落ちてくるファイル
   - `Resync is copying files to - Path1` の後に `Skipped copy` の行があれば、それは手元にだけあるファイルで、Dropbox に上がる（`~/Dropbox` が空なら `There was nothing to transfer`）
   - 最後に `Bisync successful` が出る（`--dry-run` でも出る）
   - **次の手順は、コピーされるファイルを確かめてから貼る**

1. 最初の同期を行う（Dropbox の中身を落とす）。

   ```bash
   rclone bisync dropbox: ~/Dropbox --filters-file ~/.config/rclone/dropbox-filters.txt --resync --max-lock 2m --verbose
   ```

   - `Copied (new)` の行がファイルごとに出て、最後に `Bisync successful` が出れば終わり
   - アカウントが大きいと時間がかかる。SSH が切れると止まるので、Raspberry Pi 5 のデスクトップの端末で行う方が無難
   - 途中で止まったときは、2 分待ってからこの手順を貼り直す
   - **次の手順は、`Bisync successful` が出てプロンプトが戻ってから貼る**

1. 15 分ごとに同期する service と timer を置いて、timer を有効にする。

   ```bash
   mkdir -p ~/.config/systemd/user
   cat > ~/.config/systemd/user/dropbox-rclone.service <<'EOF'
   [Unit]
   Description=rclone bisync (Dropbox <-> ~/Dropbox)

   [Service]
   Type=oneshot
   ExecStart=/home/linuxbrew/.linuxbrew/bin/rclone bisync dropbox: %h/Dropbox --filters-file %h/.config/rclone/dropbox-filters.txt --resilient --recover --max-lock 2m --conflict-resolve newer --verbose
   EOF
   cat > ~/.config/systemd/user/dropbox-rclone.timer <<'EOF'
   [Unit]
   Description=rclone bisync (Dropbox <-> ~/Dropbox) every 15 minutes

   [Timer]
   OnBootSec=5min
   OnUnitInactiveSec=15min

   [Install]
   WantedBy=timers.target
   EOF
   systemctl --user daemon-reload
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user enable --now dropbox-rclone.timer
   systemctl --user is-enabled dropbox-rclone.timer    # enabled
   ```

   - `enabled` が出ればよい
   - `Created symlink '.../timers.target.wants/dropbox-rclone.timer' → ...` が出る

1. 1 回動かして、結果と次の実行時刻を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user start dropbox-rclone.service
   systemctl --user show -p Result dropbox-rclone.service      # Result=success
   journalctl --user -u dropbox-rclone.service -n 20 --no-pager
   systemctl --user list-timers dropbox-rclone.timer --no-pager
   ```

   - `Result=success` と、journal の `Bisync successful` が出ればよい
   - `list-timers` の `NEXT` が、次に同期する時刻
   - 失敗すると、最初の行で `Job for dropbox-rclone.service failed ...` と出る。journal の `ERROR` の行を見る（[使い方の基本](#dropbox-と-rclone-使い方の基本)）

#### Dropbox と rclone: 使い方の基本

| コマンド | 用途 |
|---|---|
| `systemctl --user start dropbox-rclone.service` | 今すぐ同期する（終わるまで戻らない） |
| `systemctl --user list-timers dropbox-rclone.timer --no-pager` | 次に同期する時刻と、前回の時刻 |
| `journalctl --user -u dropbox-rclone.service -n 50 --no-pager` | 同期のログ（`Bisync successful` か `ERROR` を見る） |
| `systemctl --user stop dropbox-rclone.timer` | 定期的な同期を止める（`start` で戻す） |
| `rclone about dropbox:` | Dropbox の使用量と空き |
| `rclone lsd dropbox:` | Dropbox 側のフォルダを見る（`rclone ls dropbox:<フォルダ>` でファイル） |
| `find ~/Dropbox -name '*.conflict*'` | 競合で残った方のファイルを探す |

- **削除は伝わる**。手元で消すと次の回で Dropbox からも消え、逆も同じ
- **一度に半分を超えて消えていると、同期は止まる**（`Safety abort: too many deletes`）
  - 誤って消したのなら、手元に戻すと次の回から元どおりに動く
  - 本当に消すのなら、rclone の案内のとおり `--force` を付けて手で 1 回動かす
- 両方で変えたファイルは新しい方が残り、古い方は `<名前>.conflict1` として両側に残る
- 同期を途中で止めるなら `systemctl --user stop dropbox-rclone.service`。後始末をして止まる（`kill -9` はしない）

#### Dropbox と rclone: 同期するフォルダを変える

- rclone の同期で使うフィルタのファイルを変え、`--resync` で同期し直す
- 前提: [Dropbox と rclone](#dropbox-と-rclone)を通してある
- 実行場所: rclone で同期しているホストの、自分のユーザーの bash（デスクトップの端末か SSH）
- フィルタを変えたら、次の同期は `--resync` で行う。しないと `Bisync critical error: filters file has changed (must run --resync)` で止まる
- 外したフォルダの手元の複製は、消えずに残る（同期されなくなるだけ）。要らなければ手で消す

1. タイマーとサービスを止めて、フィルタのファイルを編集する。

   ```bash
   systemctl --user stop dropbox-rclone.timer dropbox-rclone.service
   vi ~/.config/rclone/dropbox-filters.txt
   ```

   - 同期の途中なら、`systemctl --user stop` は後始末が終わるまで待つ
   - 書き方は[Dropbox と rclone](#dropbox-と-rclone)の手順 6 と同じ
   - **次の手順は、保存して `vi` を閉じてから貼る**

1. 変えた後の同期で何が起きるかを見る（`--dry-run`）。

   ```bash
   rclone bisync dropbox: ~/Dropbox --filters-file ~/.config/rclone/dropbox-filters.txt --resync --max-lock 2m --dry-run --verbose
   ```

   - 見方は[Dropbox と rclone](#dropbox-と-rclone)の手順 7 と同じ
   - **次の手順は、コピーされるファイルを確かめてから貼る**

1. `--resync` で同期し直し、タイマーを戻す。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   rclone bisync dropbox: ~/Dropbox --filters-file ~/.config/rclone/dropbox-filters.txt --resync --max-lock 2m --verbose
   systemctl --user start dropbox-rclone.timer
   systemctl --user list-timers dropbox-rclone.timer --no-pager
   ```

   - `Bisync successful` の後に、`list-timers` が次の時刻を出せばよい

#### Dropbox と rclone: 更新

- Homebrew で入れた rclone を上げる
- 前提: [Dropbox と rclone](#dropbox-と-rclone)を通してある
- 実行場所: rclone で同期しているホストの、自分のユーザーの bash（デスクトップの端末か SSH）

1. rclone を上げる。

   ```bash
   brew upgrade rclone
   ```

   - 新しい版が無ければ `Warning: rclone 1.75.2 already installed` のように出る
   - 依存の一覧と `[y/n]` が出たら、更新するものを見て `y` と答える
   - **次の手順は、更新が終わってプロンプトが戻ってから貼る**（問い合わせ中に続けて貼ると、後ろの文字が答えとして読まれる）

1. 更新後の版を確かめる。

   ```bash
   rclone version | head -1
   ```

   - `rclone v` に続いて版が出ればよい

---

## 再起動の後の確認

- 再起動して、通した項の設定が効いているかを確かめる

### 再起動と確認

- 再起動して、GNOME の表示と入力・日本語入力・システムの設定などが効いているかを確かめる
- 前提: [ログインと sudo](#ログインと-sudo)を通してある。確かめるのは、次の項のうち通したもの
  - [システムの設定](#システムの設定)・[日本語入力](#日本語入力)・[GNOME の表示と入力](#gnome-の表示と入力)
  - [WezTerm と HackGen Console NF をデスクトップで使う](shell-terminal.md#wezterm-と-hackgen-console-nf-をデスクトップで使う)・[Neovim](neovim.md#neovim)
  - [Homebrew](#homebrew)の手順 4
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
   journalctl --list-boots --no-pager | tail -n 2
   cat /sys/kernel/kexec_crash_size
   hostnamectl --static
   xdg-user-dir DOWNLOAD
   ibus list-engine | grep -w anthy
   IBUS_PID="$(pgrep -u "$(id -u)" -x ibus-daemon | head -n 1)"
   if [ -n "$IBUS_PID" ]; then
     IBUS_PATH="$(tr '\0' '\n' < "/proc/$IBUS_PID/environ" | grep '^PATH=')"
     printf '%s\n' "$IBUS_PATH"
     env "$IBUS_PATH" /usr/libexec/ibus-engine-anthy --xml | grep -m 1 -o '<name>[^<]*</name>'
   else
     echo 'ibus-daemon が動いていない（GNOME にログインしてから貼り直す）'
   fi
   gnome-extensions info appindicatorsupport@rgcjonas.gmail.com | grep -E '^ *(状態|State)'
   /usr/bin/gsettings get org.gnome.mutter experimental-features
   ```

   - `journalctl --list-boots` に 2 行出る（前の起動のログが残っている。[システムの設定](#システムの設定)の手順 5 を通したとき）
   - `0` が出る（[システムの設定](#システムの設定)の手順 7 で kdump を止めたとき）
   - [システムの設定](#システムの設定)の手順 2 の名前が出る（名前を変えたとき）
   - `/home/<USER>/Downloads` が出る（[GNOME の表示と入力](#gnome-の表示と入力)を通したとき）
   - `anthy - Anthy` が出る（[日本語入力](#日本語入力)を通したとき）
   - `PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin` と `<name>anthy</name>` が出る（[日本語入力](#日本語入力)と、[Homebrew](#homebrew)の手順 4 を通したとき）
   - PATH に `/home/linuxbrew/` が入っていたり、`ModuleNotFoundError: No module named 'gi'` が出たりしたら、[Homebrew](#homebrew)の手順 4 を貼って、この項の手順 1 の再起動からやり直す
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

   - Super+Space で「英語 (US)」と Anthy に切り替わる。[Neovim](neovim.md#neovim)の手順 3 を飛ばしたなら、[日本語入力](#日本語入力)の手順 3 の配列と Anthy
   - Anthy に切り替えてからテキストエディターなどで `nihongo` と打ち、Space を押すと「日本語」に変わり、Enter で確定する
   - Anthy は、ひらがなで始まる
   - 英字と日本語は Super+Space で切り替える。[Neovim](neovim.md#neovim)の手順 3 を通したときは、Neovim 内では `<C-j>` で切り替え、JIS キーボードでも US 配列で打つため、一部の記号は刻印と異なる

1. [GNOME の表示と入力](#gnome-の表示と入力)を通したときだけ、Files で、フォルダーの名前と、隠しファイルとフォルダーの並びを確かめる。

   - Files（アクティビティの画面で「ファイル」）でホームを開くと、`Desktop`・`Documents`・`Downloads` などの英語の名前のフォルダーが並び、日本語の名前のフォルダーは無い
   - `.bashrc`・`.config` などの隠しファイルも出て、フォルダーがファイルより先に並ぶ
   - 左のサイドバーにも `Documents`・`Downloads` などが並び、押すとそのフォルダーが開く

1. [Neovim](neovim.md#neovim)を通したときだけ、Neovim で、日本語の検索・整形と IME 連携を確かめる。

   - [LazyVim の日本語検索・整形・IME 連携を確かめる](neovim.md#lazyvim-の日本語検索整形ime-連携を確かめる)の全項を WezTerm のタブで行う
   - `/tmp/lazyvim-check.md` が無ければ、[LazyVim の設定を導入する](neovim.md#lazyvim-の設定を導入する)の手順 11 の `printf …` の行を貼ってから開く
   - `o` で足した行は保存せず、`:qa!` で閉じる

---

## 更新

- OS（BaseOS・AppStream・EPEL・RPM Fusion から入れたもの。`epel-release`・`rpmfusion-free-release` とトレイアイコンの拡張も）は[OS とファームウェアの更新](#os-とファームウェアの更新)の手順 1・4・5 を、ファームウェアは同じ項の手順 2・3 を貼り直す
- [dnf-automatic で自動で更新する](#dnf-automatic-で自動で更新する)を通したなら、OS の更新は毎日自動で入る（再起動は[OS とファームウェアの更新](#os-とファームウェアの更新)の手順 4・5 で自分で行う）
- EPEL の鍵をまだ取り込んでいなければ、`epel-release` が上がるときに確認を求められる（fingerprint は[EPEL と RPM Fusion](#epel-と-rpm-fusion)の手順 1）
- Flatpak のアプリは `dnf upgrade` では上がらない（[共通の bash 設定・Homebrew・Flatpak を上げる](#共通の-bash-設定homebrewflatpak-を上げる)の手順 4）
- Firefox・WezTerm・GitHub CLI（それぞれのベンダーの dnf のリポジトリから入れたもの）と git・Node.js も、OS の更新で上がる
  - 1 つだけ上げるなら、名前を指定する（Firefox は言語パックと一緒に `sudo dnf upgrade firefox firefox-l10n-ja`）
  - Firefox の FFmpeg（RPM Fusion の `ffmpeg-libs`）も一緒に上がる。WezTerm の COPR は、`main` ブランチに追従して毎日〜数日おきにビルドされる
- Claude Code・Codex CLI・Grok Build とプラグインは、[AI コーディングエージェントのセットアップの「更新」](ai-agents.md#更新)で上げる（dnf で入れた Claude Code は、OS の更新でも上がる）
- VirtualBox・VirtualBox の bootc ゲスト・kvm-container は、仮想マシンのセットアップの[VirtualBox: 更新](virtual-machines.md#virtualbox-更新)・[VirtualBox の bootc ゲスト: 更新](virtual-machines.md#virtualbox-の-bootc-ゲスト-更新)・[kvm-container を更新する](virtual-machines.md#kvm-container-を更新する)、Forgejo は[Forgejo のセットアップの「Forgejo: 更新」](forgejo.md#forgejo-更新)で上げる
- Syncthing は、[Syncthing のセットアップの「Syncthing: 更新」](syncthing.md#syncthing-更新)で上げる。WireGuard（`wireguard-tools`）・Samba（`samba`・`cifs-utils` など）のパッケージと、GNOME のリモート操作で使う部品は、OS の更新で上がる
- HackGen Console NF・git-delta・Neovim・lazygit・yazi（Homebrew で入れたもの）は、[共通の bash 設定・Homebrew・Flatpak を上げる](#共通の-bash-設定homebrewflatpak-を上げる)の手順 3 で上がる
  - **Neovim の設定やプラグインは更新に追従しない**。メジャー更新の後は `:checkhealth` で壊れていないか見る
- 共通の bash 設定・シェルのツール・HackGen Console NF・WezTerm と自分用の WezTerm の設定の上げ方は、[シェルと端末のセットアップ](shell-terminal.md)の冒頭にまとめてある
- 自分用の設定は各リポジトリで上げる。Neovim のプラグインと外部コマンドは[LazyVimStarter の更新手順](neovim.md#lazyvim-の本体外部コマンドプラグインを更新する)
  - yazi の自分用の設定は上流の版に合わせてある。yazi の版が上がったら、その [README の「上流の新しい版に追従する」](https://github.com/ryo-aoki-pc/yazi#上流の新しい版に追従する)で設定も追う

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
   - [シェルと端末のセットアップの「共通の bash 設定を更新する」](shell-terminal.md#共通の-bash-設定を更新する)と同じ pull だけを行う。`install.sh` は初回の導入用なので流さない（流し直すと、移す行があるときは、控えの `~/.bashrc.before-bash` が既にあるので止まる）
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

---
