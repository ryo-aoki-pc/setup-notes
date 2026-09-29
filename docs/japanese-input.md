# 日本語入力（IBus + Anthy）の設定手順（AlmaLinux 10 / GNOME）

## 実施手順

> [!IMPORTANT]
> - **GNOME にログインしたデスクトップの端末で、自分のユーザーのまま実行する**。`sudo -i` / `su -` したシェルでは行わない（手順 4 の `gsettings` は、実行したユーザーの設定しか変えないため）
> - **手順 3 には対話入力がある**（`sudo` のパスワードと `[y/N]`）
> - **手順 3 を実行したときは、手順 5 でログアウトしてログインし直す**

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 戻すときは[ロールバック](#ロールバック)

> [!WARNING]
> **x86_64 のコンテナでのみ検証した手順書**で、実機では本実行していない。入力ソースの切り替え・上部バーの表示・アプリでの入力は、画面で確かめていない。かな漢字変換は、IBus の API にキーを送って確かめた（[対象と検証環境](#対象と検証環境)）。

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

   <details>
   <summary>補足: 配列の取り出し方</summary>

   `localectl status` の `X11 Layout:` の行から、英字で始まる最初の配列の名前だけを取る。コンテナ（systemd を PID 1 にしたもの）での実測:

   | `localectl status` の表示 | `XKB_LAYOUT` |
   |---|---|
   | `X11 Layout: (unset)` | 空 |
   | `X11 Layout: jp` | `jp` |
   | `X11 Layout: us,jp` | `us`（最初の 1 つ） |
   | `X11 Layout: jp` と `X11 Variant: OADG109A` | `jp`（変種は取らない） |

   - `localectl` が動かないとき（systemd の無い環境）は、エラーを捨てて空になる
   - 変種も指定するときは、手順 4 の `'jp'` を `'jp+OADG109A'` のように `+` でつないだ名前にする（GNOME の配列の一覧で、この形の名前があることをコンテナで確かめた）

   </details>

1. ibus-anthy と日本語のフォントが入っているか確かめる。

   ```bash
   rpm -q ibus ibus-anthy default-fonts-cjk-sans || echo '未導入のものがある'
   ```

   - 3 つとも版が出れば、手順 3 は飛ばす（Workstation で入れた PC には最初から入っている）
   - `package ... is not installed` と `未導入のものがある` が出たら、手順 3 で入れる

   <details>
   <summary>補足: インストールの種類による違い</summary>

   AlmaLinux 10 のパッケージのグループ（`dnf group info` とリポジトリのメタデータで確かめた）:

   - **Workstation** は `workstation-product` グループで `ibus-anthy` を入れる
   - **Server with GUI** は `ibus-anthy` を入れない。`ibus` 本体は GNOME の依存で入る（コンテナで、`gdm` と `gnome-control-center` を入れただけで `ibus-1.5.32-1.el10` が入った）
   - 日本語のフォント `default-fonts-cjk-sans`（中身は `google-noto-sans-cjk-vf-fonts`）は、どちらも「Fonts」グループの既定のパッケージとして入る
   - GNOME をパッケージを選んで入れた場合は、フォントが無いことがある（コンテナがこの状態だった）

   </details>

1. どれかが未導入のときだけ、ibus-anthy と日本語のフォントを AppStream から入れる。

   ```bash
   sudo dnf install ibus-anthy default-fonts-cjk-sans
   ```

   - 入るものを確かめて `y` で進める
   - すでに入っているものは `Package ... is already installed.` と出て、入れ直さない
   - **次の手順は、`sudo` のパスワードと `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 入るパッケージ</summary>

   コンテナ（ibus-anthy もフォントも無い状態）での実測。8 パッケージ、ダウンロード 35 MB、導入後 96 MB:

   ```
   Installing:
    default-fonts-cjk-sans           noarch 4.1-3.el10             appstream  13 k
    ibus-anthy                       x86_64 1.5.17-1.el10          appstream 876 k
   Installing dependencies:
    anthy-unicode                    x86_64 1.0.0.20240502-12.el10 appstream 5.7 M
    google-noto-sans-cjk-vf-fonts    noarch 1:2.004-9.el10         appstream  14 M
    ibus-anthy-python                noarch 1.5.17-1.el10          appstream 179 k
    kasumi-common                    noarch 2.5-47.el10            appstream  14 k
    kasumi-unicode                   x86_64 2.5-47.el10            appstream  71 k
   Installing weak dependencies:
    google-noto-sans-mono-cjk-vf-fonts
                                     noarch 1:2.004-9.el10         appstream  14 M
   ```

   - フォントが入っている PC では、ibus-anthy と依存を合わせた 5 パッケージ（ダウンロード 6.8 MB、導入後 35 MB）だけになる（フォントを先に入れたコンテナで確認）
   - 導入後の `fc-list :lang=ja family` は `Noto Sans CJK JP` と `Noto Sans Mono CJK JP` だった
   - `langpacks-ja` は入れない。中身は日本語のフォントの詰め合わせで、入力のエンジンは入らない（リポジトリのメタデータで確認）

   </details>

1. 入力ソースを「キーボードの配列 + Anthy」にする。

   ```bash
   gsettings get org.gnome.desktop.input-sources sources
   gsettings set org.gnome.desktop.input-sources sources "[('xkb', '${XKB_LAYOUT:?手順 1 の XKB_LAYOUT が空のまま。値を入れて貼り直す}'), ('ibus', 'anthy')]"
   gsettings get org.gnome.desktop.input-sources sources
   gsettings get org.gnome.desktop.wm.keybindings switch-input-source
   ```

   - 最初の `get` は変える前の値（何も設定していなければ `@a(ss) []`）
   - 戻すときのために、変える前の値を控えておく
   - 2 つ目の `get` が `[('xkb', 'jp'), ('ibus', 'anthy')]`（US 配列なら `'us'`）になればよい
   - **ほかの入力ソースは消える**。残したいものがあれば、`set` の値に並べて足す
   - 最後の `get` の `['<Super>space', 'XF86Keyboard']` が、入力ソースを切り替えるキー（Super+Space）
   - 手順 3 を飛ばしたなら、手順 5 は飛ばす

   <details>
   <summary>補足: 並べ方</summary>

   キーボードの配列を先に、Anthy を後に置く。RHEL を日本語で入れたときも、GNOME は配列と Anthy の 2 つを入力ソースにする（ibus-anthy の RHEL のパッチの説明文から）。

   - 設定アプリの「キーボード」→「入力ソース」と同じキー
   - Anthy のエンジンは配列を `default`（入力ソースで選ばれている配列に従う）で登録している（`/usr/share/ibus-anthy/engine/default.xml`）。JIS 配列でも US 配列でも同じ `anthy` でよい
   - 配列の短い表示名は `jp` が `ja`、Anthy は `あ`（エンジンの定義の `symbol`）。上部バーにはこれが出るはず（画面では確かめていない）

   </details>

1. 手順 3 で ibus-anthy を入れたときだけ、ログアウトしてログインし直す。

   - ログインし直すまで、動いている IBus は Anthy を使えない
   - **次の手順は、ログインし直してデスクトップの端末を開いてから貼る**

   <details>
   <summary>補足: ログインし直す理由</summary>

   動いている ibus-daemon は、起動した後に入れたエンジンを知らない。

   - コンテナで、`dnf install` の直後の `ibus list-engine` には `anthy` が出ず、ibus-daemon を起動し直すと出た
   - `ibus restart` でも起動し直せるはず。GNOME では、systemd のユーザーのユニット `org.freedesktop.IBus.session.GNOME.service` を再起動する作り（ibus 1.5.32 のソース）で、コンテナではこの経路を確かめられないので、本書はログインし直す形にした
   - systemd のユーザーのインスタンスが無いコンテナでは、`ibus restart` は `error: XDG_RUNTIME_DIR is invalid or not set in the environment.` と出したうえで daemon を起動し直し、`anthy` が出るようになった

   </details>

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

   <details>
   <summary>補足: コンテナでの確かめ方</summary>

   画面が無いので、IBus の Python の API（`gi.repository.IBus`）で入力コンテキストを作り、GNOME Shell が入力ソースを切り替えるときと同じく全体のエンジンを `anthy` にして、キーを送った。

   | 送ったキー | 結果 |
   |---|---|
   | `a` | 前編集の文字列が `あ`（ひらがなで始まる） |
   | `n` `i` `h` `o` `n` `g` `o` | `にほんご` |
   | Space | `日本語` |
   | Return | `日本語` が確定した |
   | 半角/全角 → `a` | Anthy が受け取らず、そのままアプリに渡る（直接入力） |
   | もう一度 半角/全角 → `a` | `あ`（ひらがなに戻る） |

   - ひらがなで始まるのは、RHEL の ibus-anthy のパッチで、入力モードの既定（`org.freedesktop.ibus.engine.anthy.common` の `input-mode`）が `0`（ひらがな）になっているため
   - 直接入力とひらがなを切り替えるキーは、Anthy の設定（`org.freedesktop.ibus.engine.anthy.shortcut` の `on_off`）で `['Zenkaku_Hankaku', 'Ctrl+space', 'Ctrl+J']`

   </details>

---

## ロールバック

- 上から順に貼る。手順 1 の変数は要らない
- ロールバックも、コンテナでのみ本実行した

1. 入力ソースを既定値に戻す。

   ```bash
   gsettings reset org.gnome.desktop.input-sources sources
   gsettings get org.gnome.desktop.input-sources sources
   ```

   - `@a(ss) []`（既定値）になればよい
   - 手順 4 で控えた値に戻すなら、`gsettings set org.gnome.desktop.input-sources sources "<控えた値>"` を貼る（`<控えた値>` を置き換える）

1. 手順 3 で ibus-anthy を入れたときだけ、ibus-anthy を消す。

   ```bash
   sudo dnf remove ibus-anthy
   ```

   - `anthy-unicode`・`ibus-anthy-python`・`kasumi-common`・`kasumi-unicode` も一緒に消える
   - `ibus` 本体は残る
   - 手順 3 で入ったフォントは残る（ほかのアプリも使うので、消さなくてよい）
   - 確認の `[y/N]` に `y` で答える

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 の GNOME で、日本語を入力できるようにする。入力のエンジンは、RHEL 10 の文書が日本語用に挙げている Anthy（IBus）を使う
- **進め方**: AppStream の `ibus-anthy` を入れ、`gsettings` で入力ソースを「キーボードの配列 + Anthy」にして、Super+Space で切り替える。**読者が書き換える必要のある変数は無い**
- **状態**: **x86_64 のコンテナでのみ検証済み（2026-09-27）。実機では本実行していない**
  - GNOME の一式を入れたコンテナで、`dbus-run-session` のセッションバスの中に ibus-daemon を GNOME と同じ引数（`--panel disable`）で起動し、**この文書のコードブロックをそのまま貼って**手順 1〜4・6 と[ロールバック](#ロールバック)を通した
  - 手順 1 の `localectl` は、systemd を PID 1 にした別のコンテナで確かめた（手順 1 の補足）
  - [flatpak.md](flatpak.md) と同じ、x86_64 のクラウドホスト上の Docker で行った
  - 確認したこと:
    - `dnf install` で入るもの
    - ibus-daemon を起動し直すと `ibus list-engine` に `anthy` が出る
    - 入力ソースが `[('xkb', 'jp'), ('ibus', 'anthy')]` になり、既定値に戻せる
    - IBus の API で `nihongo` と Space と Return を送ると「日本語」が確定し、半角/全角キーで直接入力とひらがなが切り替わる（手順 7 の補足）
  - **確認していないこと**: Super+Space での切り替え、上部バーの表示、候補の一覧の表示、アプリ（GTK・XWayland のアプリ・WezTerm・VS Code など）での入力。コンテナには画面も GNOME Shell も無いため
  - aarch64（Raspberry Pi 5）では通していない。パッケージは同じ版が aarch64 にもある（リポジトリのメタデータで確認）

| 項目 | 実機 | コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-27 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5）・x86_64 PC | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/almalinux:10.2`、Docker 29.3.1） |
| GNOME | 未確認 | `gdm-47.0-24.el10_2`、`gnome-shell-49.4-9.el10_2.alma.1`、`gsettings-desktop-schemas-47.1-4.el10`（`gdm` と `gnome-control-center` を入れて依存で揃えた） |
| IBus / Anthy | 未確認 | `ibus-1.5.32-1.el10`（GNOME の依存で入っていた）、`ibus-anthy-1.5.17-1.el10`、`anthy-unicode-1.0.0.20240502-12.el10` |
| セッションバス | — | `dbus-run-session`（GNOME のセッションの代わり） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${XKB_LAYOUT}` | キーボードの配列（`localectl status` から自動で入る） | `jp`（JIS 配列）/ `us`（US 配列） |
>
> 出力例の値は `<USER>` のプレースホルダで書いてある。ロールバックの `<控えた値>` は、手順 4 で控えた値に置き換える。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

コンテナで、手順 1 の前に確かめた状態:

| 項目 | 状態 |
|---|---|
| `ibus` | `ibus-1.5.32-1.el10`（GNOME の依存で入っていた） |
| `ibus-anthy` | 未導入 |
| 日本語のフォント | 無い（`default-fonts-cjk-sans` は未導入で、`fc-list :lang=ja` は何も出さない） |
| 入力ソース | `@a(ss) []`（既定値） |
| 切り替えのキー | `['<Super>space', 'XF86Keyboard']` |

### 選択した方針

| 経路 | 状況（2026-09-27 時点） | 採否 |
|---|---|---|
| **IBus + Anthy**（AppStream の `ibus-anthy`） | RHEL 10 の文書が日本語用に挙げているエンジン。GNOME は IBus を組み込んでいて、入力ソースに足すだけで使える。x86_64・aarch64 の両方にある | **採用** |
| IBus + Mozc | Mozc の RPM が EL10 に無い（EPEL 10 にも、COPR の EL10 向けにも無い） | — |
| Fcitx5 + Mozc（Flathub の `org.fcitx.Fcitx5` と `org.fcitx.Fcitx5.Addon.Mozc`） | 変換は Mozc のほうが賢いが、GNOME（Wayland）には IBus の代わりに組み込む作業が要る。Mozc のアドオンは公開元が未検証 | 不採用 |
| Anthy だけを入力ソースにして、半角/全角キーでオンとオフを切り替える | Windows に近い使い方。ログイン直後からひらがなで始まる | 不採用（GNOME の標準の、配列と Anthy を Super+Space で切り替える形にした） |

### 完了時点の状態

コンテナでの出力（手順 6 の直後）:

```
$ gsettings get org.gnome.desktop.input-sources sources
[('xkb', 'jp'), ('ibus', 'anthy')]
$ ibus list-engine | grep -w anthy
  anthy - Anthy
$ rpm -q ibus ibus-anthy default-fonts-cjk-sans
ibus-1.5.32-1.el10.x86_64
ibus-anthy-1.5.17-1.el10.x86_64
default-fonts-cjk-sans-4.1-3.el10.noarch
```

### 注意点

- **ほかの入力ソースは消える**: 手順 4 の `set` は一覧をまるごと置き換える
- **Anthy はひらがなで始まる**: RHEL のパッチで既定の入力モードがひらがなになっている。英字を打つなら、Super+Space で配列に戻すか、半角/全角キーで直接入力にする
- **変換の精度**: Anthy は Mozc に比べて変換が弱いと言われる（本書では比べていない）。よく使う語は辞書に登録する
  - 辞書のツール `kasumi-unicode`（`/usr/bin`）が一緒に入る。本書では開いていない
- **Anthy の設定**: 入力モードやキーの割り当ての設定画面は `/usr/libexec/ibus-setup-anthy`。本書では開いていない
  - desktop ファイルの名前は「IBus Anthy の設定」だが、`NoDisplay=true` なのでアプリの一覧には出ない
- **アプリによる違い**: GTK のアプリ・XWayland で動くアプリ・VS Code・WezTerm での入力は確かめていない

### 参照

- [Enabling Chinese, Japanese, or Korean text input — Using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/using_the_gnome_desktop_environment/customizing-the-desktop-environment) — 8.2 節。日本語は `ibus-anthy`、切り替えは Super+Space
- [ibus/ibus-anthy](https://github.com/ibus/ibus-anthy) — Anthy のエンジン
- [CentOS Stream 10 の ibus-anthy](https://gitlab.com/redhat/centos-stream/rpms/ibus-anthy) — RHEL のビルドの設定（配列 `default`、切り替えのキー）と、ひらがなで始めるパッチ

---

### 付録: コンテナでの検証記録（2026-09-27）

x86_64 のクラウドホスト上の Docker で、使い捨てのコンテナを使った。実機で加えた変更は無い。

- `quay.io/almalinuxorg/almalinux:10.2` に `sudo`・`gdm`・`gnome-control-center` を `dnf install` で入れ、GNOME の一式を依存で揃えた（488 パッケージ）
- 非 root ユーザーを作り、NOPASSWD の sudo を与えた

実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、次の点だけ置き換えている。

- GNOME のセッションの代わりに、`dbus-run-session -- bash` の中で実行し、ibus-daemon を GNOME のユニットと同じ `ibus-daemon --panel disable` で起動した
- コンテナに `/etc/machine-id` が無く、IBus がつながらなかったので、`systemd-machine-id-setup` で作った
- 手順 1 の `localectl` はこのコンテナでは動かず `XKB_LAYOUT` が空になったので、手順 1 の案内のとおり `XKB_LAYOUT=jp` を貼った
- `dnf install` と `dnf remove` に `-y` を付けた
- 手順 5 のログインし直しの代わりに、ibus-daemon を止めて起動し直した

| 手順 | 結果 |
|---|---|
| 1. 変数 | `USER = <USER>`、`XKB_LAYOUT` は空。`XKB_LAYOUT=jp` を貼った |
| 2. 確認 | `ibus-1.5.32-1.el10` と、`ibus-anthy` / `default-fonts-cjk-sans` の `is not installed`、`未導入のものがある` |
| 3. 導入 | 8 パッケージ（手順 3 の補足）。直後の `ibus list-engine` に `anthy` は出なかった |
| 4. 入力ソース | `@a(ss) []` → `[('xkb', 'jp'), ('ibus', 'anthy')]`、切り替えのキーは `['<Super>space', 'XF86Keyboard']` |
| 6. 確認 | ibus-daemon を起動し直した後、`anthy - Anthy`。IBus の API での入力は手順 7 の補足のとおり |
| ロールバック 1 | `@a(ss) []` |
| ロールバック 2 | `ibus-anthy` と依存の 4 パッケージが消えた。`ibus` とフォントは残った |
| 比較. フォントが入っている PC | `default-fonts-cjk-sans` を先に入れた別のコンテナで手順 2・3: 手順 2 は `ibus-anthy` だけが `is not installed`。手順 3 は `Package default-fonts-cjk-sans-4.1-3.el10.noarch is already installed.` と出て、5 パッケージが入った |

#### 未確認事項

- 実機（Raspberry Pi 5 / x86_64 PC）での実行と、aarch64 での実行
- Super+Space での切り替えと、上部バーの表示
- 候補の一覧の表示と、変換の操作（候補の選び直し、文節の区切り直し）
- アプリでの入力（GNOME のテキストエディタ・端末、Firefox、VS Code、WezTerm）
- `ibus restart` で、ログインし直さずに Anthy が使えるようになるか
- `ibus-setup-anthy` と `kasumi-unicode` の画面
