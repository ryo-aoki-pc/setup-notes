# Forgejo のロールバック

[手順書](../forgejo.md#forgejo)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/forgejo.md)・[参考資料](../reference/forgejo.md)

- 手順書の実施手順は項（###）ごとに 1 から数える。「<項>の手順 N」は手順書のその項の手順、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- Forgejo の起動・自動更新のタイマーと、この文書が追加した firewalld の 2 規則を解除する。データとバックアップは既定で残す
- サーバーを動かすユーザーのシェルで行う。「イメージを取得して localhost で起動する」の手順 1 の `SERVER_IP`・`LAN_SUBNET`・ポート・`FW_ZONE` は、追加したときと同じ値を貼り直す
- 送信元の制限なしで追加した場合は、撤去でも `LAN_SUBNET=0.0.0.0/0` を指定する
- Podman・linger・共通の Caddy と認証局はほかのサービスも使うので、この節では削除・無効化しない

1. 必要なデータをバックアップする。

   - 保持するデータがあれば[バックアップ](../forgejo.md#forgejo-バックアップ)を通す
   - 保存したアーカイブの場所を控える

1. 自動更新と Forgejo を停止し、定義を退避して自動起動を解除する。

   ```bash
   if [ ! -f ~/.config/containers/systemd/forgejo.container ]; then
     echo '中断: この手順の Quadlet が見つからない' >&2
   elif ! grep -qx '# setup-notes: forgejo' ~/.config/containers/systemd/forgejo.container; then
     echo '中断: この手順が作った Quadlet ではない' >&2
   elif [ -e ~/.config/caddy/sites/forgejo.caddy ] && ! grep -qx '# setup-notes: forgejo' ~/.config/caddy/sites/forgejo.caddy; then
     echo '中断: この手順が作った Caddy のサイトではない' >&2
   elif [ "$(systemctl --user show -p ActiveState --value forgejo-auto-update.service)" = activating ]; then
     echo '中断: 自動更新の実行中。終わってから貼り直す' >&2
   else
     install -d -m 700 ~/.local/state/forgejo-backups &&
     FORGEJO_REMOVED=$(mktemp -d "$HOME/.local/state/forgejo-backups/removed-XXXXXXXX") &&
     { [ ! -e ~/.config/systemd/user/forgejo-auto-update.timer ] || systemctl --user disable --now forgejo-auto-update.timer; } &&
     { [ ! -e ~/.config/systemd/user/forgejo-auto-update.timer ] || mv ~/.config/systemd/user/forgejo-auto-update.timer "${FORGEJO_REMOVED}/"; } &&
     { [ ! -e ~/.config/systemd/user/forgejo-auto-update.service ] || mv ~/.config/systemd/user/forgejo-auto-update.service "${FORGEJO_REMOVED}/"; } &&
     { [ ! -e ~/.local/bin/forgejo-auto-update ] || mv ~/.local/bin/forgejo-auto-update "${FORGEJO_REMOVED}/"; } &&
     systemctl --user stop forgejo.service &&
     mv ~/.config/containers/systemd/forgejo.container "${FORGEJO_REMOVED}/forgejo.container" &&
     { [ ! -e ~/.config/caddy/sites/forgejo.caddy ] || mv ~/.config/caddy/sites/forgejo.caddy "${FORGEJO_REMOVED}/forgejo.caddy"; } &&
     systemctl --user daemon-reload &&
     printf '退避した定義: %s/forgejo.container\n' "${FORGEJO_REMOVED}"
   fi
   ```

   - 自動更新のタイマー・サービス・プログラムがあれば、無効にして同じ退避先へ移す。自動更新の無い構成では、その部分は何もしない
   - 定義は `~/.config/containers/systemd` から外れ、サービスが次回のログイン・起動で戻らなくなる
   - サイトを退避したら [Caddy: 設定を検査して起動し直す](../almalinux-setup.md#caddy-設定を検査して起動し直す)を通す。共通の Caddy と認証局は消さない
   - 永続データと SSH のホスト鍵は残る

1. この文書が追加した 2 規則だけを runtime と permanent から外す。

   ```bash
   if [ -z "${SERVER_IP}" ] || [ -z "${LAN_SUBNET}" ] || [ -z "${FORGEJO_HTTP_PORT}" ] || [ -z "${FORGEJO_SSH_PORT}" ] || [ -z "${FW_ZONE}" ]; then
     echo '中断: 追加したときの「イメージを取得して localhost で起動する」の手順 1 の変数を設定する' >&2
   else
     for port in "${FORGEJO_HTTP_PORT}" "${FORGEJO_SSH_PORT}"; do
       rule="rule family=\"ipv4\" priority=\"100\" source address=\"${LAN_SUBNET}\" destination address=\"${SERVER_IP}\" port port=\"${port}\" protocol=\"tcp\" accept"
       if sudo firewall-cmd --zone="${FW_ZONE}" --query-rich-rule="${rule}" >/dev/null; then
         sudo firewall-cmd --zone="${FW_ZONE}" --remove-rich-rule="${rule}"
       fi
       if sudo firewall-cmd --permanent --zone="${FW_ZONE}" --query-rich-rule="${rule}" >/dev/null; then
         sudo firewall-cmd --permanent --zone="${FW_ZONE}" --remove-rich-rule="${rule}"
       fi
     done
     printf '\n\033[7m 確認 \033[0m\n'
     sudo firewall-cmd --zone="${FW_ZONE}" --list-rich-rules
     sudo firewall-cmd --permanent --zone="${FW_ZONE}" --list-rich-rules
   fi
   ```

   - 指定した送信元・宛先・ポート・priority の規則が無くなればよい。`0.0.0.0/0` の許可も同じ組で外す
   - 他のサービスや、同じポートでも別の規則は外さない

1. 自動起動と待ち受けが解除されたことを確かめる。

   ```bash
   if [ -z "${FORGEJO_HTTP_PORT}" ] || [ -z "${FORGEJO_SSH_PORT}" ]; then
     echo '中断: 「イメージを取得して localhost で起動する」の手順 1 のポートを設定する' >&2
   else
     printf '\n\033[7m 確認 \033[0m\n'
     systemctl --user status forgejo.service --no-pager
     systemctl --user list-timers --all forgejo-auto-update.timer --no-pager
     podman ps --filter name='^forgejo$'
     ss -ltn "( sport = :${FORGEJO_HTTP_PORT} or sport = :${FORGEJO_SSH_PORT} )"
   fi
   ```

   - `forgejo.service` が見つからず、`list-timers` が `0 timers listed.` を出し、動いている `forgejo`、localhost の Web・Caddy の LAN の Web・Git 用 SSH の待ち受けが無ければよい
   - イメージとデータを残すだけなら、ここで終わる
   - ほかに常駐するユーザーサービスが無く、linger も切るときだけ [linger のロールバック](linger.md#ロールバック)を行う

---

## Web の HTTPS 化を戻す

- [Forgejo: Web を HTTPS に切り替える](../forgejo.md#forgejo-web-を-https-に切り替える)の前に残した `forgejo.container.http-backup` を戻す
- 前提: HTTPS 化の前後で Forgejo のイメージ版が変わっておらず、HTTP 公開へ戻してよいことを確かめてある
- 実行場所: Forgejo と共通の Caddy を動かす一般ユーザー自身の bash
- この節の手順 2〜4 の間は Web と Git が切れる。共通の Caddy の再起動はほかのサイトにも数秒影響する
- HTTP に戻すと Web の内容は暗号化されない。Caddy 本体と認証局は残す

1. HTTP の控えと現在のイメージ版が同じことを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/python3 - <<'PYCODE'
   from pathlib import Path
   import re

   path = Path.home() / '.config/containers/systemd/forgejo.container'
   backup = path.with_name('forgejo.container.http-backup')
   if not backup.is_file():
       raise SystemExit('中断: HTTP の控え（forgejo.container.http-backup）が無い')
   current, saved = path.read_text(), backup.read_text()
   for text in (current, saved):
       if not text.startswith('# setup-notes: forgejo\n'):
           raise SystemExit('中断: この手順の定義ではない')
   images = [re.findall(r'^Image=(.+)$', text, re.M) for text in (current, saved)]
   if len(images[0]) != 1 or images[0] != images[1]:
       raise SystemExit('中断: イメージ版が変わった。古いイメージだけへ戻さない')
   if len(re.findall(r'^PublishPort=(?!127\.0\.0\.1:)\d+\.\d+\.\d+\.\d+:\d+:3000$', saved, re.M)) != 1:
       raise SystemExit('中断: 控えが旧 HTTP の公開定義ではない')
   print('HTTP の控えと同じイメージ版: OK')
   PYCODE
   ```

   - `OK` が出ればよい。版が変わっていたら、この節では戻さず現在の Quadlet の Web 2 行だけを変更する方法を管理者と確認する

1. Forgejo を止め、Caddy の Forgejo サイトだけを外す。

   ```bash
   if [ "$(systemctl --user show -p ActiveState --value forgejo-auto-update.service)" = activating ]; then
     echo '中断: 自動更新の実行中。終わってから貼り直す' >&2
   elif [ ! -f ~/.config/containers/systemd/forgejo.container.http-backup ] ||
        ! grep -qx '# setup-notes: forgejo' ~/.config/caddy/sites/forgejo.caddy; then
     echo '中断: HTTP の控えまたは Caddy のサイトを確認する' >&2
   else
     systemctl --user stop forgejo.service &&
     mv ~/.config/caddy/sites/forgejo.caddy ~/.config/caddy/forgejo.caddy.https-backup
   fi
   ```

   - エラー無く終わったら [Caddy: 設定を検査して起動し直す](../almalinux-setup.md#caddy-設定を検査して起動し直す)を通す
   - 検査や起動に失敗したら、`mv ~/.config/caddy/forgejo.caddy.https-backup ~/.config/caddy/sites/forgejo.caddy` でサイトを戻し、同じ項を通し直してから `systemctl --user start forgejo.service` で HTTPS に戻す
   - **次の手順は、Caddy の起動し直しが通り、`ss -ltn` に `<SERVER_IP>:<Web ポート>` の待ち受けが無いことを確かめてから貼る**

1. HTTP 公開の Quadlet を控えから戻し、Forgejo を起動する。

   ```bash
   if systemctl --user is-active --quiet forgejo.service || [ -e ~/.config/caddy/sites/forgejo.caddy ]; then
     echo '中断: Forgejo または HTTPS サイトが残っている' >&2
   elif [ -e ~/.config/containers/systemd/forgejo.container.https-backup ]; then
     echo '中断: forgejo.container.https-backup が既にある。上書きしない' >&2
   else
     cp -p ~/.config/containers/systemd/forgejo.container ~/.config/containers/systemd/forgejo.container.https-backup &&
     install -m 600 ~/.config/containers/systemd/forgejo.container.http-backup ~/.config/containers/systemd/forgejo.container &&
     systemctl --user daemon-reload &&
     systemctl --user start forgejo.service
   fi
   ```

   - エラー無く終わればよい。認証局と端末のルート証明書はそのまま残す
   - 起動に失敗したら、`install -m 600 ~/.config/containers/systemd/forgejo.container.https-backup ~/.config/containers/systemd/forgejo.container` と `systemctl --user daemon-reload` で HTTPS の定義に戻し、この節の手順 2 の箇条書きの戻し方でサイトを戻して Forgejo を起動する

1. 旧 HTTP の公開と Git 用 SSH を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user is-active forgejo.service caddy.service
   podman port forgejo
   ```

   - `active` が 2 行、Web と Git 用 SSH が元の `SERVER_IP` に公開されていればよい
   - 許可した別の PC で `http://<SERVER_IP>:<Web ポート>/` にログインし、`git fetch` を確かめる
   - HTTPS に付け替えた remote を HTTP に戻す場合は、clone の `git remote set-url` で変更する

---

## 保持したデータも削除する（任意）

> [!CAUTION]
> **この節の手順 2** は、DB・リポジトリ・アカウント・添付・SSH のホスト鍵を取り戻せなくする。バックアップと復元前の退避は残る。

- 先に[ロールバック](#ロールバック)を最後まで行う。バックアップから戻す必要が無いと確かめたときだけ行う

1. 削除する専用ディレクトリを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   ls -ld ~/.local/share/forgejo
   du -sh ~/.local/share/forgejo
   ```

   - **次の手順は、このデータを消してよいと確かめてから貼る**

1. 停止した Forgejo の専用データだけを削除する（取り戻せない）。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   if [ -e ~/.config/containers/systemd/forgejo.container ] || podman container exists forgejo ||
        systemctl --user is-active --quiet forgejo.service || [ -e ~/.config/systemd/user/forgejo-auto-update.timer ]; then
     echo '中断: 先にロールバックで停止と自動起動の解除を行う' >&2
   elif [ -L ~/.local/share/forgejo ] || [ ! -d ~/.local/share/forgejo ]; then
     echo '中断: データの場所が専用ディレクトリではない' >&2
   else
     rm -r -f -- ~/.local/share/forgejo
   fi
   ```

   - 何も表示されずに終わればよい。git のオブジェクトは書き込み禁止なので、`-f` で 1 つずつの確認を出さずに消す
   - `~/.local/share/forgejo` だけを消す。`podman system reset` や Podman 全体の削除は行わない
   - `~/.local/state/forgejo-backups` のアーカイブ・退避（自動更新の `forgejo-auto-*`・`failed-update-*` を含む）にも秘密は残る。不要になったものは、その保管先の運用に合わせて個別に消す
   - 自動更新の保留とロックの `~/.local/state/forgejo-auto-update` は秘密を含まない。要らなければ手で消す
