# 日本語入力（IBus + Anthy）の設定手順（AlmaLinux 10 / GNOME）

## 実施手順

- [検証記録](verification/japanese-input.md)・[参考資料](reference/japanese-input.md)

> [!IMPORTANT]
> - **GNOME にログインしたデスクトップの端末で、自分のユーザーのまま実行する**。`sudo -i` / `su -` したシェルでは行わない（手順 4 の `gsettings` は、実行したユーザーの設定しか変えないため）
> - **手順 3 には対話入力がある**（`[y/N]`）
> - **手順 3 を実行したときは、手順 5 でログアウトしてログインし直す**

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 手順の後: 戻すときは[ロールバック](#ロールバック)

1. 変数を設定する。

   ```bash
   XKB_LAYOUT=$(localectl status 2>/dev/null | sed -n 's/^ *X11 Layout: \([a-z][a-z0-9_]*\).*/\1/p')   # キーボードの配列（自動）。JIS は jp、US は us。<XKB_LAYOUT>
   for v in USER XKB_LAYOUT; do
     printf '%-10s = %s\n' "$v" "${!v}"
   done
   ```

   - **編集が必須の変数は無い**。OS に設定されたキーボードの配列が自動で入る
   - 最後に値を読み戻して確かめる
   - `XKB_LAYOUT` が空か、手元のキーボードと違うなら、`XKB_LAYOUT=jp`（JIS 配列）か `XKB_LAYOUT=us`（US 配列）を貼ってから先へ進む
   - `USER` が `root` になっているなら、ここで止めて、自分のユーザーのシェルで貼り直す
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**（ログインし直したあとも）、手順 1 のブロックを貼り直してから先へ進む

1. ibus-anthy と日本語のフォントが入っているか確かめる。

   ```bash
   rpm -q ibus ibus-anthy default-fonts-cjk-sans || echo '未導入のものがある'
   ```

   - 3 つとも版が出れば、手順 3 は飛ばす（Workstation で入れた PC には最初から入っている）
   - `package ... is not installed` と `未導入のものがある` が出たら、手順 3 で入れる

1. どれかが未導入のときだけ、ibus-anthy と日本語のフォントを AppStream から入れる。

   ```bash
   sudo dnf install ibus-anthy default-fonts-cjk-sans
   ```

   - 入るものを確かめて `y` で進める
   - すでに入っているものは `Package ... is already installed.` と出て、入れ直さない
   - **次の手順は、`[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. 入力ソースを「キーボードの配列 + Anthy」にする。

   ```bash
   /usr/bin/gsettings get org.gnome.desktop.input-sources sources
   /usr/bin/gsettings set org.gnome.desktop.input-sources sources "[('xkb', '${XKB_LAYOUT:?手順 1 の XKB_LAYOUT が空のまま。値を入れて貼り直す}'), ('ibus', 'anthy')]"
   /usr/bin/gsettings get org.gnome.desktop.input-sources sources
   /usr/bin/gsettings get org.gnome.desktop.wm.keybindings switch-input-source
   ```

   - 最初の `get` は変える前の値（何も設定していなければ `@a(ss) []`）
   - 戻すときのために、変える前の値を控えておく
   - 2 つ目の `get` が `[('xkb', 'jp'), ('ibus', 'anthy')]`（US 配列なら `'us'`）になればよい
   - **ほかの入力ソースは消える**。残したいものがあれば、`set` の値に並べて足す
   - 最後の `get` の `['<Super>space', 'XF86Keyboard']` が、入力ソースを切り替えるキー（Super+Space）
   - 手順 3 を飛ばしたなら、手順 5 は飛ばす
   - `/usr/bin/` は外さない（Homebrew の `gsettings` は GNOME の dconf に書かない。[gnome-power.md の検証記録](verification/gnome-power.md)・[参考資料](reference/gnome-power.md)）

1. 手順 3 で ibus-anthy を入れたときだけ、ログアウトしてログインし直す。

   - ログインし直すまで、動いている IBus は Anthy を使えない
   - **次の手順は、ログインし直してデスクトップの端末を開いてから貼る**

1. IBus が Anthy を読み込んだか確かめる。

   ```bash
   ibus list-engine | grep -w anthy
   ```

   - `anthy - Anthy` と出ればよい
   - 何も出なければ、手順 5 でログインし直したかを確かめる

1. 画面で、入力ソースを切り替えて日本語を打ってみる。

   - Super+Space で、上部バーの入力ソースの表示が切り替わる
   - Anthy に切り替えてからテキストエディタなどで `nihongo` と打ち、Space を押すと「日本語」に変わり、Enter で確定する
   - Anthy は、ひらがなで始まる
   - Anthy の中では、半角/全角キー（US 配列なら Ctrl+Space か Ctrl+J）で英字（直接入力）とひらがなを切り替える

---

## ロールバック

- 上から順に貼る。手順 1 の変数は要らない

1. 入力ソースを既定値に戻す。

   ```bash
   /usr/bin/gsettings reset org.gnome.desktop.input-sources sources
   /usr/bin/gsettings get org.gnome.desktop.input-sources sources
   ```

   - `@a(ss) []`（既定値）になればよい
   - 手順 4 で控えた値に戻すなら、`/usr/bin/gsettings set org.gnome.desktop.input-sources sources "<控えた値>"` を貼る（`<控えた値>` を置き換える）

1. 手順 3 で ibus-anthy を入れたときだけ、ibus-anthy を消す。

   ```bash
   sudo dnf remove ibus-anthy
   ```

   - `anthy-unicode`・`ibus-anthy-python`・`kasumi-common`・`kasumi-unicode` も一緒に消える
   - `ibus` 本体は残る
   - 手順 3 で入ったフォントは残る（ほかのアプリも使うので、消さなくてよい）
   - 確認の `[y/N]` に `y` で答える

---

## 注意点

- **ほかの入力ソースは消える**: 手順 4 の `set` は一覧をまるごと置き換える
- **Anthy はひらがなで始まる**: RHEL のパッチで既定の入力モードがひらがなになっている。英字を打つなら、Super+Space で配列に戻すか、半角/全角キーで直接入力にする
- **変換の精度**: Anthy は Mozc に比べて変換が弱いと言われる（本書では比べていない）。よく使う語は辞書に登録する
  - 辞書のツール `kasumi-unicode`（`/usr/bin`）が一緒に入る。本書では開いていない
- **Anthy の設定**: 入力モードやキーの割り当ての設定画面は `/usr/libexec/ibus-setup-anthy`。本書では開いていない
  - desktop ファイルの名前は「IBus Anthy の設定」だが、`NoDisplay=true` なのでアプリの一覧には出ない
