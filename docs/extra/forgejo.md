# Forgejo 構築手順（AlmaLinux 10 / rootless Podman + Quadlet / LAN・VPN 内で使う）のロールバック

[手順書](../forgejo.md)・[検証記録](../verification/forgejo.md)・[参考資料](../reference/forgejo.md)

- 「手順 N」は[手順書](../forgejo.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- Forgejo の起動・自動更新のタイマーと、この文書が追加した firewalld の 2 規則を解除する。データとバックアップは既定で残す
- サーバーを動かすユーザーのシェルで行う。手順 1 の `SERVER_IP`・`LAN_SUBNET`・ポート・`FW_ZONE` は、追加したときと同じ値を貼り直す
- Podman と linger はほかのサービスも使うので、この節では削除・無効化しない

1. 必要なデータをバックアップする。

   - 保持するデータがあれば[バックアップ](../forgejo.md#バックアップ)を通す
   - 保存したアーカイブの場所を控える

1. 自動更新と Forgejo を停止し、定義を退避して自動起動を解除する。

   ```bash
   if [ ! -f ~/.config/containers/systemd/forgejo.container ]; then
     echo '中断: この手順の Quadlet が見つからない' >&2
   elif ! grep -qx '# setup-notes: forgejo' ~/.config/containers/systemd/forgejo.container; then
     echo '中断: この手順が作った Quadlet ではない' >&2
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
     systemctl --user daemon-reload &&
     printf '退避した定義: %s/forgejo.container\n' "${FORGEJO_REMOVED}"
   fi
   ```

   - 自動更新のタイマー・サービス・プログラムがあれば、無効にして同じ退避先へ移す。自動更新の無い構成では、その部分は何もしない
   - 定義は `~/.config/containers/systemd` から外れ、サービスが次回のログイン・起動で戻らなくなる
   - 永続データと SSH のホスト鍵は残る

1. この文書が追加した 2 規則だけを runtime と permanent から外す。

   ```bash
   if [ -z "${SERVER_IP}" ] || [ -z "${LAN_SUBNET}" ] || [ -z "${FORGEJO_HTTP_PORT}" ] || [ -z "${FORGEJO_SSH_PORT}" ] || [ -z "${FW_ZONE}" ]; then
     echo '中断: 追加したときの手順 1 の変数を設定する' >&2
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

   - 指定した送信元・宛先・ポート・priority の規則が無くなればよい。他のサービスや、同じポートでも別の規則は外さない

1. 自動起動と待ち受けが解除されたことを確かめる。

   ```bash
   if [ -z "${FORGEJO_HTTP_PORT}" ] || [ -z "${FORGEJO_SSH_PORT}" ]; then
     echo '中断: 手順 1 のポートを設定する' >&2
   else
     printf '\n\033[7m 確認 \033[0m\n'
     systemctl --user status forgejo.service --no-pager
     systemctl --user list-timers --all forgejo-auto-update.timer --no-pager
     podman ps --filter name='^forgejo$'
     ss -ltn "( sport = :${FORGEJO_HTTP_PORT} or sport = :${FORGEJO_SSH_PORT} )"
   fi
   ```

   - `forgejo.service` が見つからず、`list-timers` が `0 timers listed.` を出し、動いている `forgejo` と 2 ポートの待ち受けが無ければよい
   - イメージとデータを残すだけなら、ここで終わる
   - ほかに常駐するユーザーサービスが無く、linger も切るときだけ [linger のロールバック](linger.md#ロールバック)を行う

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
