# AlmaLinux 10 の初期設定の手順（インストール直後の更新・sudo・SSH・導入元・日本語入力・GNOME・シェルのツール）のロールバックと注意点

[手順書](../almalinux-setup.md)・[検証記録](../verification/almalinux-setup.md)・[参考資料](../reference/almalinux-setup.md)

- 「手順 N」は[手順書](../almalinux-setup.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

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
- 任意節で変えたものは、その節の最後の「元に戻すときは」の手順で戻す。[Homebrew を sudo でも使う（任意）](../almalinux-setup.md#homebrew-を-sudo-でも使う任意)を通したなら、先にその節の手順 2 を行う
- 別の手順書で入れたものは、それぞれの手順書のロールバックで先に戻す（Homebrew を消す前に HackGen Console NF などの Homebrew のもの、RPM Fusion を消す前に [firefox.md のロールバック](firefox.md#ロールバック)の手順 1 の FFmpeg）
- **EPEL・RPM Fusion を消しても、そこから入れたパッケージ（btop・distrobox・podman-compose・podman-tui・VirtualBox の `liblzf`・Firefox の FFmpeg など）は残り、更新されなくなる**。要らないものは、先に各手順書のロールバックで消す
- 手順 1〜23 は、手順 50 と同じ、開き直した端末に貼る

> [!CAUTION]
> **この節の手順 25 は、Homebrew で入れたものを全部消す**（この文書の外で入れた yazi・Neovim・HackGen Console NF なども）。**この節の手順 38 は、ディスクに残した journal（前の起動のログ）を消す**。**この節の手順 22 の後に閉じたシェルは、`~/.bash_history` を既定の 1,000 行に切り詰める**（残す履歴は、この節の手順 17 で控える）。どれも取り戻せない。

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
   - 手順 41 で控えた並びに戻すなら、`reset` の代わりに `/usr/bin/gsettings set org.gnome.shell favorite-apps "<控えた値>"` を貼る（`<控えた値>` を置き換える）

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
   printf '\n\033[7m 確認 \033[0m\n'
   wc -l ~/.bash_history.bak
   ```

   - 行数が出る。要らなくなったら `~/.bash_history.bak` は手で消す

1. starship・zoxide・eza・bat・tmux を消す。

   ```bash
   brew uninstall starship zoxide eza bat tmux
   ```

   - Homebrew ごと消すなら、この手順と手順 19 は飛ばしてよい（手順 25 で全部消える）
   - 残すツールは、名前を外してから貼る
   - 依存は、ほかの formula（[git-delta](../git-delta.md) など）が必要とする間は残る。Homebrew 7 では、不要になった依存は自動で削除される（`Autoremoving … unneeded formulae:`）
   - 同じシェルでは、`command -v tmux` などがまだ前のパスを返す（bash が覚えている）。`hash -r` の後か新しいシェルでは、何も返さない
   - starship を消した後のこの端末では、プロンプトを出すたびに `-bash: /home/linuxbrew/.linuxbrew/bin/starship: そのようなファイルやディレクトリはありません` と出て、プロンプトの文字が消える。コマンドは動くので、この節の手順 23 で端末を開き直すまで、そのまま貼ってよい

1. fzf を使うツールがほかに無いときだけ、fzf を消す。

   ```bash
   brew uninstall fzf
   ```

   - fzf の実行ファイルは、zoxide の `zi` と [yazi](../yazi.md) の絞り込みにも使う。それらを使うなら消さない
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
   printf '\n\033[7m 確認 \033[0m\n'
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
   - インターネットに出られないホストでは、[ssh-socks-tunnel.md 手順 1〜3](../ssh-socks-tunnel.md#実施手順) でトンネルを張ったシェルで、この節の手順 24 から貼る
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

1. 手順 10 で PC の名前を変えたときだけ、元の名前に戻す（`OLD_HOST_NAME` は必ず値を入れる）。

   ```bash
   OLD_HOST_NAME=''   # 手順 10 で控えた「変える前:」の名前。<HOSTNAME>
   ```

   ```bash
   if [ -z "${OLD_HOST_NAME}" ]; then echo '中断: OLD_HOST_NAME が空のまま。手順 10 で控えた名前を入れて貼り直す' >&2; else
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

   - この節の手順 37 を行ったなら、0 でない数（`268435456` など）が出る
   - `journalctl --list-boots` は、見出しの行（`IDX BOOT ID …`）と、`0` で始まる今の起動の 1 行だけ
   - この節の手順 39 の名前と、この節の手順 15 を行ったなら日本語の名前（`/home/<USER>/ダウンロード`）が出る
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

- **パスワードを聞かない sudo**: [手順 3](../almalinux-setup.md#実施手順) の後は、このユーザーで動くものがパスワード無しで root の権限を使える（リードの `[!WARNING]`）。外すのは[ロールバック](#ロールバック)の手順 42
- **アプリが再起動を止めることがある**: `sudo systemctl reboot` が `Operation inhibited by …` で断られたら、保存していない文書のあるアプリを閉じてから貼り直す
- **PC の名前を変えた後**: 開いている端末のプロンプトは前の名前のまま。ほかの PC の `~/.ssh/known_hosts` は名前でつないでいれば、新しい名前で鍵を聞かれる
- **SSH はパスワードでもログインできる**: Workstation の既定。公開鍵だけにするなら[SSH を公開鍵だけにする（任意）](../almalinux-setup.md#ssh-を公開鍵だけにする任意)
- **journal は rsyslog と二重に残る**: `/var/log/messages`（rsyslog）にも同じ内容が残る。journal の大きさは、既定でファイルシステムの 10%（4 GiB まで）
- **kdump を止めると、カーネルが落ちたときの記録（vmcore）は残らない**: 原因を調べるときは、[ロールバック](#ロールバック)の手順 37 で戻す
- **コマンドが見つからないときに、パッケージを案内しない**: 手順 16 の後は、`dnf provides '*/bin/<コマンド>'` で探す
- **EPEL・RPM Fusion は AlmaLinux の配布物ではない**: EPEL は Fedora のプロジェクトが作るリポジトリ。AppStream / BaseOS にあるパッケージは、そちらを使う
  - RPM Fusion の free は「Fedora がライセンス以外の理由で配れないオープンソースのソフト」を配る（RPM Fusion の Configuration の説明）。鍵は手順 18 で照合し、`rpmfusion-free-release` の署名も手順 20 で確かめる
  - EL10 向けの RPM Fusion は中身が少ない。調べた範囲では、free に `ffmpeg` 7.1.5 と `gstreamer1-plugins-bad-freeworld`、nonfree に `steam`（i686）がある（[導入元一覧](../tool-catalog.md#導入経路と-el10-での注意)）
  - RPM Fusion の `ffmpeg-libs` は、EPEL の `libavcodec-free` と衝突する（[firefox.md 手順 9](../firefox.md#実施手順)）
- **Homebrew と同じ名前の実行ファイルを、EPEL から二重に入れない**: 例えば EPEL の `fd-find` は `/usr/bin/fd` を置く。両方入れると、PATH の先頭の Homebrew 版が使われ、`dnf upgrade` で上がるのは使われないほうになる（[btop.md の注意点](btop.md#注意点)）
- **ほかの手順書のロールバックでは、EPEL・RPM Fusion を消さない**: 使う手順書が複数ある。消すときはこの文書の[ロールバック](#ロールバック)で行う
- **Flatpak は容量が大きい**: アプリ本体に加え、runtime・翻訳・GL ドライバ・コーデックの拡張の容量も確保する。`sudo flatpak uninstall --unused` で、使われなくなった runtime を消せる
- **Flatpak のアプリは `dnf upgrade` では上がらない**: [更新](../almalinux-setup.md#更新)の `sudo flatpak update` を別に実行する
- **Flatpak の権限はアプリごとに違う**: 入れる前に表示される権限の一覧を確かめる。入れた後は `flatpak info --show-permissions <ID>` で見られ、Flatseal か `sudo flatpak override` で変えられる
- **Flathub のアプリの公開元を確認する**: 検証済み（公開元がアプリの作者本人だと確認されたもの）と未検証（第三者が包んでいる場合がある）の 2 種類がある。[導入元一覧](../tool-catalog.md#gui)の表に書き分けてある
  - Microsoft Edge などは Flathub でも x86_64 だけ（[導入元一覧](../tool-catalog.md#aarch64-で使えないもの)）
  - [Firefox](../firefox.md) のように RPM で入れたものを Flathub からも入れると、メニューに同じ名前が 2 つ並ぶと見込まれる
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
- **eza のアイコンには Nerd Font が要る**: `--icons=always` はグリフを出すだけなので、フォントが無い端末では豆腐になる（[HackGen Console NF](../hackgen.md)）
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
