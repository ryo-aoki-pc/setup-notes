# WezTerm Nightly インストール手順（AlmaLinux 10 は公式 COPR の EL9 ビルドを流用 / Windows 11 は nightly のインストーラ）の参考資料

[手順書](../wezterm-nightly.md)・[ロールバックと注意点](../extra/wezterm-nightly.md)

## 補足

### 実施手順 / 手順 1: 補足: chroot を明示する理由

`dnf copr enable` は chroot を省略すると `/etc/os-release` から推定する。EL 系は `epel-<major>-<arch>` になる（`/usr/lib/python3.12/site-packages/dnf-plugins/copr.py` の `_guess_chroot`）。このプロジェクトに `epel-10-x86_64` は無いので失敗する:

エラーメッセージの言うとおり第 2 引数に chroot を渡せば通る。「repo ファイルの手直しが要るかも」とあるが、生成された repo ファイルは `baseurl` が `rhel-9-$basearch` を指すだけで、そのまま使えた:

```
[copr:copr.fedorainfracloud.org:wezfurlong:wezterm-nightly]
name=Copr repo for wezterm-nightly owned by wezfurlong
baseurl=https://download.copr.fedorainfracloud.org/results/wezfurlong/wezterm-nightly/rhel-9-$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://download.copr.fedorainfracloud.org/results/wezfurlong/wezterm-nightly/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
```

公式ドキュメントの openSUSE 向け手順が同じ `dnf copr enable wezfurlong/wezterm-nightly <repository>` の形なので、想定内の使い方ではある。

### 実施手順 / 手順 3: 補足: wezterm はメタパッケージ / 取り込まれる鍵

[この節の検証記録](../verification/wezterm-nightly.md#実施手順--手順-3-補足-wezterm-はメタパッケージ--取り込まれる鍵)

- `wezterm` 本体（6.4 KB、`rpm -ql wezterm` は空）は、`wezterm-common`（CLI の `wezterm`、シェル統合、補完）/ `wezterm-gui`（`wezterm-gui`、desktop ファイル、アイコン）/ `wezterm-mux-server` を Requires で束ねているだけ
- `dnf repoquery --requires wezterm` に `gcc` / `*-devel` / `make` が並んで見えるのは、同名の **SRPM の BuildRequires** が一緒に表示されているため。x86_64 パッケージには入っていない

GPG 鍵はインストール時に COPR の `pubkey.gpg` から取り込まれる:

```
Importing GPG key 0xCEA2757D:
 Userid     : "wezfurlong_wezterm-nightly (None) <wezfurlong#wezterm-nightly@copr.fedorahosted.org>"
 Fingerprint: FD90 9B62 88A8 4250 AD58 020F A698 91C5 CEA2 757D
 From       : https://download.copr.fedorainfracloud.org/results/wezfurlong/wezterm-nightly/pubkey.gpg
```

### 実施手順 / 手順 4: 補足: wezterm ls-fonts と wezterm-gui --version

- **`wezterm ls-fonts`** は GUI 無しでフォント解決を確認できる
  - 既定のフォントは組み込みの `JetBrains Mono` で、フォールバックに `Noto Color Emoji`（fontconfig 経由）と組み込みの `Symbols Nerd Font Mono` が並ぶ
  - `| head` で切ると `rc=101`（Rust の panic 終了コード）になるが、パイプが閉じたためで異常ではない。単体で実行すると `rc=0`
- **`wezterm-gui --version` は `wezterm-gui someone forgot to call assign_version_info` と出る**（rc=0）
  - COPR ビルドでは GUI バイナリにバージョン情報が埋め込まれていない。バージョンは `wezterm --version` で見る

### 実施手順 / 手順 5: 補足: Wayland セッションでの起動試験

- **Wayland セッションでの起動試験**: この検証は Claude Code のシェル（TTY もディスプレイも無い）から行ったので、`env -i` で環境を空にしてから、ログイン中の GNOME セッションの `WAYLAND_DISPLAY=wayland-0` と `XDG_RUNTIME_DIR` を渡した
  - 値は `/proc/$(pgrep -u "$USER" -x gnome-shell)/environ` から取れる
  - `wezterm start -- sh -c 'exit 0'` はウィンドウを開いて `sh` を走らせ、終了と同時にウィンドウを閉じる。結果 `rc=0`
  - `timeout 30` は、描画に失敗してウィンドウが残った場合の保険

### Windows 11 のロールバック / 手順 1: 補足: アンインストーラの動き

- アンインストーラは `C:\Program Files\WezTerm\unins000.exe`（Inno Setup）。場所は登録の `UninstallString` から読む
- 引数の `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART` は、Inno Setup のアンインストーラの標準の引数（確認の窓も完了の窓も出さない）
- アンインストーラは自分の写しを `%TEMP%` に作り、写しの方が消す。終了コードが返った時点では片付けがまだ続いていることがある（Inno Setup の文書）ので、登録とフォルダーが消えるまで 60 秒まで待つ
- 消えるもの: インストーラが置いたファイルとフォルダー、スタートメニューの「WezTerm」、右クリックの「Open WezTerm here」、PC 全体の `PATH` の `C:\Program Files\WezTerm`、アンインストールの登録
- 残るもの: 設定ファイルと、WezTerm が作る作業用のフォルダー（ソースでは `%USERPROFILE%\.local\share\wezterm`・`%APPDATA%\wezterm`・`%LOCALAPPDATA%\wezterm`。作られていれば）

### 選択した方針

`wezterm-gui` が要求するのは次のもの（`dnf repoquery --requires wezterm-gui`）:

- `libc.so.6(GLIBC_2.34)`
- `libssl.so.3(OPENSSL_3.0.0)` / `libcrypto.so.3`
- `libwayland-client.so.0` / `libwayland-egl.so.1`
- `libxkbcommon.so.0(V_0.6.0)` / `libxkbcommon-x11.so.0`
- `libxcb.so.1` / `libxcb-image.so.0` / `libxcb-util.so.1`
- `libX11.so.6` / `libX11-xcb.so.1`
- `libfontconfig.so.1`、`mesa-libEGL`、`dbus`

EL10 は glibc 2.39 / OpenSSL 3.5（`libssl.so.3` の soname と `OPENSSL_3.0.0` シンボルバージョンを両方提供）なので、EL9 向けバイナリがそのまま動く。

#### Homebrew の tap を採らない理由

#### Windows 11 で入れる経路

- **Windows 11 では、インストーラを直接取って、`.sha256` と比べてから黙って動かす方式を採用した**
  - [Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md)が前提にしている `C:\Program Files\WezTerm` に、公式の形のまま入る
  - `.sha256` は同じリリースに置かれたものなので、分かるのは壊れていないことまで。署名が無いので、ほかに本物かを確かめる手立ては無い（winget の定義の sha256 も、同じファイルから bot が取ったもの）
  - winget の `wez.wezterm.nightly` は、入れられる日なら 1 行で済み `VCRUNTIME140.dll` の依存も入るが、入るかどうかが日によるので採らなかった。依存の再頒布可能パッケージだけは winget で入れる（[Windows 11 で使う](../wezterm-nightly.md#windows-11-で使う)の手順 3）
- **Windows 11 の手順もこの文書に置いた**: 同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、OS ごとにファイルを分けない。手順が OS で違うので、[syncthing.md](../syncthing.md) と同じく後ろの節に分けた

### 参照

---
