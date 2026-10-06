# GNOME の画面オフ・画面ロック・自動サスペンドの設定手順（AlmaLinux 10）の参考資料

[手順書](../gnome-power.md)

## 補足

### 実施手順 / 手順 1: 補足: 変数について

- 画面を消したいなら、`IDLE_DELAY` に秒数を入れる（`300` で 5 分）。消えたときにロックもするなら `LOCK_ENABLED=true`
- 放置したときにサスペンドするかどうかは変数にしていない。手順 2・3 で `nothing`（何もしない）を直接書く
  - 手順 4 でサスペンドとハイバネートを OS ごと止めるので、ほかに選べる値が無いため
- `POWER_BUTTON` も同じ理由で、`suspend` / `hibernate` は選ばない
  - `interactive` は、設定アプリの「電源ボタンの挙動」の「電源オフ」にあたる
  - 押すと何をするかを聞く画面が出て、何も選ばなければ 60 秒で電源が切れる（RHEL 10 の文書の 13.1.2 節）

### 参照

- [Changing system power settings — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/changing-system-power-settings) — 電源ボタン（dconf と logind）と蓋（logind）の設定
- [gnome-settings-daemon 47.2 の電源のスキーマ](https://gitlab.gnome.org/GNOME/gnome-settings-daemon/-/blob/47.2/data/org.gnome.settings-daemon.plugins.power.gschema.xml.in) — `sleep-inactive-*`・`idle-dim`・`power-button-action` の既定値と説明
- [GDM 47.0 のログイン画面の既定の設定](https://gitlab.gnome.org/GNOME/gdm/-/blob/47.0/data/dconf/defaults/00-upstream-settings) — 電源のキーが無いこと
- `man dconf`（`dconf update` とプロファイル）/ `man 5 logind.conf`（`HandleLidSwitch`）/ `man systemctl`（`mask`）

---
