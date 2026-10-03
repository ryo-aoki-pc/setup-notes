# AlmaLinux 10 の CLI / GUI ツール導入元一覧

AlmaLinux 10 で使える便利な CLI・GUI ツールを、**どこから入れるか**（導入元）で比べた一覧。この文書は手順書ではない。

- ツールごとに推奨する導入元・その時点の版・導入コマンド・ほかの経路・aarch64（Raspberry Pi 5）での提供の有無を 1 行にまとめてある
- 個別の手順書があるツールは[文書化済みのツール](#文書化済みのツール)から手順書へ進む

> [!WARNING]
> **状態**: **調査は 2026-09-24（UTC 20:51〜21:20）**。検証の方法と環境は[補足](#補足)にまとめた。
>
> - x86_64 は AlmaLinux 10.2 のコンテナで、**表の導入コマンドを実行して入ることを確かめた**。確かめた深さは行ごとの「確認」列に書いてある
> - **aarch64 の列は、リポジトリのメタデータと API から調べただけ**で、どの行も実機にもコンテナにも入れていない
> - GUI アプリはどれも画面を出していない
> - 実機（Raspberry Pi 5 と x86_64 PC）には何も入れていない
> - **[CLI: コンテナ](#cli-コンテナ)と GUI の[コンテナ](#コンテナ)の節は 2026-09-27（UTC 16:26〜17:40）に調べた**。このとき表にあった podman-tui と lazydocker は、2026-09-28 に手順書にした（[文書化済みのツール](#文書化済みのツール)）
> - 2026-09-28 に、[ベンダーの dnf リポジトリ](#ベンダーの-dnf-リポジトリ)と[更新](#更新)のブロックを `{ … }` で囲んだ（[README の記法](../README.md#記法)）。中のコマンドは変えていない
> - [CLI: 定番の置き換え](#cli-定番の置き換え)の表にあった tmux は、2026-10-01 に手順書にした（[文書化済みのツール](#文書化済みのツール)）
> - 同じ表にあった fzf は、2026-10-02 に手順書にした（bash への組み込みまで。[文書化済みのツール](#文書化済みのツール)）
> - 2026-10-03 に、zoxide の dnf（COPR）の経路を zoxide.md から外し、[文書化済みのツール](#文書化済みのツール)の「zoxide（dnf）」の行を消した

「確認」列の意味:

| 値 | 意味 |
|---|---|
| 起動 | x86_64 コンテナで導入し、`--version` などを実行して版が出た |
| 導入 | x86_64 コンテナで導入まで確認した。Flatpak のアプリは、サンドボックスの起動（`flatpak run --command=true`）も確認した。画面が要るため、アプリそのものは動かしていない |
| メタデータ | 提供の有無と版を調べただけで、入れていない |

表の版は調査日のもの。**導入コマンドを貼る前提**は、導入元ごとに次のとおり。

- Homebrew（`brew install`）: [Homebrew](homebrew.md) を通してあること
- EPEL（`sudo dnf install`。AppStream / BaseOS は前提なし）: [EPEL](epel.md) を通してあること
- Flathub（`sudo flatpak install`）: [Flatpak / Flathub](flatpak.md) を通してあること
- ベンダーの dnf リポジトリ: [ベンダーの dnf リポジトリ](#ベンダーの-dnf-リポジトリ)の節で、そのリポジトリを登録してあること
- コンテナの節の行は、どの導入元でも [Podman](podman.md) の実施手順を通してあること（Pods・Podman Desktop などは、その API ソケットを使う）

---

## 導入経路と EL10 での注意

| 経路 | 有効にする方法 | 版の傾向 | aarch64 | EL10 での注意 | 詳細 |
|---|---|---|---|---|---|
| BaseOS / AppStream | 既定で有効 | 古めで固定。例: tmux 3.3a、jq 1.7.1、Firefox は ESR 140 | 調べた範囲では x86_64 と同じ版 | — | — |
| CRB | **既定で有効**。素のコンテナイメージで確認した（`almalinux-repos-10.2` の `almalinux-crb.repo` が `enabled=1`） | — | — | EPEL を入れたときに出る「CRB を有効に」の案内は、AlmaLinux 10 では済んでいる | [epel.md](epel.md) |
| EPEL 10 | [epel.md](epel.md)。`sudo dnf install -y epel-release`（`extras` にある） | Homebrew より古いことが多い（fzf 0.58.0 など）。同じ版のものもある | 調べた範囲（AppStream なども含む）はすべて x86_64 と同じ版 | Chromium・KeePassXC などの GUI もある。**Homebrew と同じ名前の実行ファイルは二重に入れない**（`fd-find` は `/usr/bin/fd`） | [epel.md](epel.md) |
| RPM Fusion（EL10） | 本書では有効にしていない。free は [rpmfusion.md](rpmfusion.md) で、鍵を照合してから `rpmfusion-free-release` を入れる（EPEL が前提） | — | free はある | EL10 向けは中身が少ない。調べた範囲では free に `ffmpeg` 7.1.5 と `gstreamer1-plugins-bad-freeworld`、nonfree に `steam`（i686）。mpv は無い。`rpmfusion-free-release` は `epel-release` を要求する | [rpmfusion.md](rpmfusion.md)、[firefox.md](firefox.md)（`ffmpeg-libs`） |
| ベンダーの dnf リポジトリ | `.repo` を置く | 上流の最新 | ベンダー次第（Chrome・mise・Trivy は両方、Edge と VirtualBox は x86_64 のみ） | **EL10 の rpm は、自己署名が SHA-1 の古い鍵を取り込まない** | [ベンダーの dnf リポジトリ](#ベンダーの-dnf-リポジトリ)、[注意点](#注意点)、[firefox.md](firefox.md)、[gh.md](gh.md)、[vscode.md](vscode.md)、[virtualbox.md](virtualbox.md)、[image-tools.md](image-tools.md)（Trivy） |
| COPR | `dnf copr enable` | 上流に近い | プロジェクト次第 | EL10 向けの chroot が無い、または repomd が 403 になる例がある | [lazygit.md](lazygit.md)、[wezterm-nightly.md](wezterm-nightly.md)、[zoxide.md](zoxide.md)（外した dnf の経路の記録） |
| Homebrew | 公式インストーラ | 上流の最新 | 調べた CLI はすべてボトルがある（`arm64_linux`。distrobox だけはアーキ共通の `all`） | root では動かない。**依存がシステムのコマンドを隠すことがある**（podman-compose で実測） | [homebrew.md](homebrew.md)、[注意点](#注意点) |
| Flathub | [flatpak.md](flatpak.md) | 上流の最新 | アプリ次第。Microsoft Edge は x86_64 のみ（[aarch64 で使えないもの](#aarch64-で使えないもの)） | 公開元が「検証済み」かどうかを見る。runtime の分だけ容量を食う | [flatpak.md](flatpak.md) |
| AppImage | ダウンロードして実行 | 上流の最新 | 配布次第 | FUSE2（`fuse-libs`）と glibc 2.39 の制約がある | [wezterm-nightly.md](wezterm-nightly.md) |

## 選び方

**CLI** は、既存の手順書と同じ規則で選んだ（[homebrew.md](homebrew.md) と [btop.md](btop.md) の「選択した方針」）。

1. RPM（AppStream / BaseOS / EPEL / ベンダーのリポジトリ）が **Homebrew と同じ版か新しい**なら RPM にする。root でも使え、`dnf upgrade` に乗る
1. RPM が古いか無ければ Homebrew にする
1. **例外として、podman 本体と、システムの podman と組んで使うもの（podman-compose / podman-tui / distrobox / toolbox / buildah / skopeo）は RPM にする**
   - Homebrew 版の podman-compose は podman 6.1.2 を依存として入れ、PATH の先頭でシステムの podman 5.8.2 を隠した（[注意点](#注意点)）
   - Homebrew の podman と skopeo は、設定を `/etc/containers` ではなく `/home/linuxbrew/.linuxbrew/etc/containers` から読む（formula の定義）
   - Homebrew の podman-tui は 2.x で、上流の互換表では podman 6 向け（[podman-tui.md](podman-tui.md) の選択した方針）

**GUI** は、次の順で選んだ。[Firefox](firefox.md) と [VS Code](vscode.md) を RPM にした判断と同じ。

1. ベンダーの公式 dnf リポジトリ（x86_64 と aarch64 の両方にあるもの）
1. AppStream / EPEL（Flathub との版の差がパッチ版までのもの）
1. Flathub で、公開元が「検証済み」のもの
1. それ以外（Flathub の未検証の公開元、または大きく遅れた EPEL）は、行ごとに理由を書く

---

## 文書化済みのツール

個別の手順書があるもの。版はそれぞれの手順書を見る（この一覧には書かない）。

| ツール | 経路 | 手順書 |
|---|---|---|
| Homebrew 本体 | 公式インストーラ | [homebrew.md](homebrew.md) |
| Flatpak / Flathub | AppStream + Flathub | [flatpak.md](flatpak.md) |
| yazi / lazygit / Neovim / zoxide / bat / eza / git-delta / gdu / starship / ShellCheck・shfmt / tmux / fzf | Homebrew | [yazi](yazi.md) / [lazygit](lazygit.md) / [Neovim](neovim.md) / [zoxide](zoxide.md) / [bat](bat.md) / [eza](eza.md) / [git-delta](git-delta.md) / [gdu](gdu.md) / [starship](starship.md) / [ShellCheck・shfmt](shellcheck.md) / [tmux](tmux.md) / [fzf](fzf.md) |
| Syncthing | Homebrew + systemd ユーザーサービス | [syncthing.md](syncthing.md) |
| Dropbox（公式クライアント） | Dropbox 公式の tarball + systemd ユーザーサービス（x86_64 のみ。公式 RPM は EL10 に入らない） | [dropbox.md](dropbox.md) |
| rclone（Dropbox の同期） | Homebrew + systemd ユーザータイマー（aarch64 の Dropbox 用） | [dropbox-rclone.md](dropbox-rclone.md) |
| btop | EPEL | [btop.md](btop.md) |
| Firefox | Mozilla 公式 dnf リポジトリ | [firefox.md](firefox.md) |
| Claude Code / GitHub CLI | 公式 dnf リポジトリ | [claude-code.md](claude-code.md) / [gh.md](gh.md) |
| VS Code | Microsoft 公式 dnf リポジトリ | [vscode.md](vscode.md) |
| VirtualBox | Oracle 公式 dnf リポジトリ（EPEL が前提。x86_64 のみ） | [virtualbox.md](virtualbox.md) |
| WezTerm Nightly | COPR（EL9 向けビルドの流用） | [wezterm-nightly.md](wezterm-nightly.md) |
| HackGen Console NF（フォント） | Homebrew の cask（`~/.local/share/fonts` に入る） | [hackgen.md](hackgen.md) |
| IBus + Anthy（日本語入力） | AppStream（Workstation には最初から入っている） | [japanese-input.md](japanese-input.md) |
| Podman | AppStream（自分のユーザーで動かす rootless） | [podman.md](podman.md) |
| distrobox / podman-compose / podman-tui | EPEL（Podman が前提） | [distrobox](distrobox.md) / [podman-compose](podman-compose.md) / [podman-tui](podman-tui.md) |
| hadolint / dive / Trivy | Homebrew と Trivy の公式 dnf リポジトリ（Podman が前提） | [image-tools.md](image-tools.md) |
| lazydocker | Homebrew（Podman と、その Docker 向けの節の `DOCKER_HOST` が前提） | [lazydocker.md](lazydocker.md) |

---

## CLI: 定番の置き換え

| ツール | 用途 | 推奨 | 導入コマンド | ほかの経路 | aarch64 | 確認 |
|---|---|---|---|---|---|---|
| ripgrep | 高速な grep（`rg`） | Homebrew 15.2.0 | `brew install ripgrep` | EPEL 14.1.1 | 有 | 起動 |
| fd | 使いやすい find | Homebrew 10.5.0 | `brew install fd` | EPEL `fd-find` 10.4.2（実行ファイルは同じ `/usr/bin/fd`） | 有 | 起動 |
| jq | JSON の加工 | Homebrew 1.8.2 | `brew install jq` | BaseOS 1.7.1 | 有 | 起動 |
| yq | YAML / JSON / XML の加工（mikefarah 版） | Homebrew 4.53.6 | `brew install yq` | EPEL 4.53.3（同じ mikefarah 版） | 有 | 起動 |
| zellij | 端末の多重化（キー操作が画面に出る） | Homebrew 0.45.1 | `brew install zellij` | RPM 無し | 有 | 起動 |
| htop | プロセスビューア | Homebrew 3.5.3 | `brew install htop` | EPEL 3.3.0 | 有 | 起動 |
| fastfetch | システム情報の表示（neofetch の後継） | EPEL 2.68.1 | `sudo dnf install -y fastfetch` | Homebrew 2.68.1（同版） | 有 | 起動 |
| tealdeer | コマンドの使用例を引く（`tldr`） | Homebrew 1.9.0 | `brew install tealdeer` | EPEL の `tldr` 3.3.0 は Python 製の別クライアント | 有 | 起動 |
| dust | `du` の見やすい版 | Homebrew 1.2.6 | `brew install dust` | RPM 無し | 有 | 起動 |
| duf | `df` の見やすい版 | EPEL 0.9.1 | `sudo dnf install -y duf` | Homebrew 0.9.1（同版） | 有 | 起動 |
| ncdu | ディスク使用量の TUI（[gdu](gdu.md) と同類） | Homebrew 2.9.2 | `brew install ncdu` | EPEL 1.22（C で書かれた 1.x 系。2.x は Zig で書き直された別系統） | 有 | 起動 |
| atuin | シェル履歴の検索 | Homebrew 18.23.0 | `brew install atuin` | RPM 無し | 有 | 起動 |
| difftastic | 構文を理解する diff（`difft`） | Homebrew 0.71.0 | `brew install difftastic` | EPEL 0.67.0 | 有 | 起動 |
| glow | Markdown を端末で読む | Homebrew 3.0.0 | `brew install glow` | EPEL 2.1.1 | 有 | 起動 |
| mosh | 回線が切れても続く SSH | EPEL 1.4.0 | `sudo dnf install -y mosh` | Homebrew 1.4.0（同版） | 有 | 起動 |

- 「起動」は `--version` が出たことだけを示す
- 試していないこと: `~/.bashrc` に追記して使うもの（atuin など。[zoxide](zoxide.md) と同じ形）のシェルへの組み込み、mosh のサーバー側の導入と UDP の許可

## CLI: 開発・運用

| ツール | 用途 | 推奨 | 導入コマンド | ほかの経路 | aarch64 | 確認 |
|---|---|---|---|---|---|---|
| direnv | ディレクトリごとの環境変数 | Homebrew 2.37.1 | `brew install direnv` | RPM 無し | 有 | 起動 |
| mise | 言語処理系の版の切り替え | 公式 dnf リポジトリ 2026.9.13 | [ベンダーの dnf リポジトリ](#ベンダーの-dnf-リポジトリ) | Homebrew 2026.9.12 | 有 | 起動 |
| uv | Python のパッケージと仮想環境 | Homebrew 0.12.18 | `brew install uv` | EPEL 0.10.2 | 有 | 起動 |
| chezmoi | dotfiles の管理 | Homebrew 2.72.2 | `brew install chezmoi` | EPEL 2.72.0 | 有 | 起動 |
| just | コマンドランナー（make の代わり） | Homebrew 1.58.0 | `brew install just` | EPEL 1.46.0 | 有 | 起動 |
| hyperfine | コマンドのベンチマーク | Homebrew 1.20.0 | `brew install hyperfine` | RPM 無し | 有 | 起動 |
| restic | バックアップ | EPEL 0.19.1 | `sudo dnf install -y restic` | Homebrew 0.19.1（同版） | 有 | 起動 |

- コンテナ系のツールは[CLI: コンテナ](#cli-コンテナ)の節にある。手順書のある podman-compose・distrobox・dive・podman-tui・lazydocker は[文書化済みのツール](#文書化済みのツール)にある

言語処理系は AppStream / BaseOS に Node.js 22.23.2・Python 3.12.14・Go 1.26.7・Rust 1.92.0 がある（どれも両アーキで同じ版。メタデータ）。別の版が要るときに mise を使う。

## CLI: コンテナ

- どの行も [Podman](podman.md) の実施手順を通してあることが前提
- 手順書のあるもの（Podman・distrobox・podman-compose・hadolint・dive・Trivy・podman-tui・lazydocker）は[文書化済みのツール](#文書化済みのツール)にある
- この節は 2026-09-27 に調べた（[付録](#付録-コンテナ関連の追加調査2026-09-27)）

| ツール | 用途 | 推奨 | 導入コマンド | ほかの経路 | aarch64 | 確認 |
|---|---|---|---|---|---|---|
| toolbox | 別のディストリの端末をコンテナで使う（distrobox と同類。RHEL の公式） | AppStream 0.3 | `sudo dnf install -y toolbox` | Homebrew に無い | 有 | 起動 |
| podman-docker | `docker` コマンドを podman に読み替える | AppStream 5.8.2 | `sudo dnf install -y podman-docker` | — | 有 | 起動 |
| buildah | Containerfile を使わずにイメージを作る | AppStream 1.43.1 | `sudo dnf install -y buildah` | Homebrew に無い | 有 | 起動 |
| skopeo | レジストリのイメージを取得せずに調べる・コピーする | AppStream 1.22.2 | `sudo dnf install -y skopeo` | Homebrew 1.24.1（設定を `/home/linuxbrew/.linuxbrew/etc/containers` から読む） | 有 | 起動 |
| podlet | podman のコマンドや compose ファイルから Quadlet の定義を作る | Homebrew 0.3.2 | `brew install podlet` | RPM 無し | 有 | 起動 |
| cosign | イメージの署名と検証 | Homebrew 3.1.3 | `brew install cosign` | RPM 無し | 有 | 起動 |

- 「起動」は `--version`（cosign は `cosign version`）が版を出したことを示す
- toolbox は、弱い依存として skopeo も入れた（ほかに `flatpak-session-helper`・`p11-kit-server`）。そのため skopeo の行の導入コマンドは `already installed` で終わった
- podman-docker の `docker --version` は、`Emulate Docker CLI using podman. Create /etc/containers/nodocker to quiet msg.` と `podman version 5.8.2` を出した
  - 入れると、lazydocker の `E`（シェル）・`a`（アタッチ）と compose の判定が、既定の設定のまま動いた（[lazydocker.md](lazydocker.md) の選択した方針）
- buildah の RPM の版は `1.43.1-6.el10_2` だが、`buildah --version` は `buildah version 1.43.2` を出した
- podlet は、`podlet podman run --name demo -p 127.0.0.1:8090:8080 <イメージ>` で Quadlet の `[Container]` 節を出した
  - `-d` を付けると、`equal sign is needed when assigning values to '--detach=<DETACH>'` で失敗した
- skopeo は、`skopeo inspect docker://quay.io/podman/hello` でダイジェストを、`skopeo list-tags` でタグの一覧を、イメージを取得せずに出した

---

## GUI

- Flathub の行の「推奨」には、アプリ ID と、使う runtime（GNOME 50 / FDO 25.08 など）を書いてある
- 同じ runtime のアプリは、2 本目から runtime を落とさない（[注意点](#注意点)に容量）

### ブラウザ

| ツール | 用途 | 推奨 | 導入コマンド | ほかの経路 | aarch64 | 確認 |
|---|---|---|---|---|---|---|
| Google Chrome | ブラウザ | 公式 dnf リポジトリ 154.0.8037.57 | [ベンダーの dnf リポジトリ](#ベンダーの-dnf-リポジトリ) | Flathub `com.google.Chrome`（公開元は未検証） | 有（公式 rpm） | 起動 |
| Chromium | ブラウザ | EPEL 153.0.8010.52 | `sudo dnf install -y chromium` | Flathub `org.chromium.Chromium` 154.0.8037.57（未検証） | 有 | 起動 |

Chromium は GUI の規則の 4 番目にあたる。

- 調査日の時点で、EPEL は 1 メジャー遅れていた
- Flathub 版は新しいが公開元が未検証なので、EPEL にした

### パスワード管理

| ツール | 用途 | 推奨 | 導入コマンド | ほかの経路 | aarch64 | 確認 |
|---|---|---|---|---|---|---|
| KeePassXC | パスワード管理（ローカルのファイル） | EPEL 2.7.11 | `sudo dnf install -y keepassxc` | Flathub `org.keepassxc.KeePassXC` 2.7.12（検証済み） | 有 | 起動 |

### 開発

| ツール | 用途 | 推奨 | 導入コマンド | ほかの経路 | aarch64 | 確認 |
|---|---|---|---|---|---|---|
| Meld | 差分・マージ | EPEL 3.22.2 | `sudo dnf install -y meld` | Flathub `org.gnome.meld` 3.24.0（未検証） | 有 | 導入 |

Meld は GUI の規則の 4 番目にあたる。

- EPEL は 3.22 系で Flathub の 3.24 より古いが、Flathub 版は公開元が未検証
- EPEL 版は `/usr/bin/meld` に入るので、ほかのツールから名前で呼べる

### コンテナ

| ツール | 用途 | 推奨 | 導入コマンド | ほかの経路 | aarch64 | 確認 |
|---|---|---|---|---|---|---|
| Podman Desktop | podman の GUI | Flathub `io.podman_desktop.PodmanDesktop` 1.29.3（検証済み、FDO 26.08） | `sudo flatpak install -y flathub io.podman_desktop.PodmanDesktop` | RPM 無し | 有 | 導入 |
| Pods | podman の GUI（GNOME のアプリ） | Flathub `com.github.marhkb.Pods` 3.1.1（検証済み、GNOME 50） | `sudo flatpak install -y flathub com.github.marhkb.Pods` | RPM 無し | 有 | 導入 |
| BoxBuddy | distrobox の GUI | Flathub `io.github.dvlv.boxbuddyrs` 2.6.1（検証済み、GNOME 50） | `sudo flatpak install -y flathub io.github.dvlv.boxbuddyrs` | RPM 無し | 有 | 導入 |
| Cockpit の podman の画面 | ブラウザからコンテナを操作する | AppStream `cockpit-podman` 121（BaseOS の `cockpit` 356.2 と組む） | `sudo dnf install -y cockpit cockpit-podman` | — | 有 | 導入 |

- Podman Desktop の行は 2026-09-24 の調査。ほかの 3 行は 2026-09-27 に調べた
- Pods と Podman Desktop は podman の API ソケット（[podman.md 手順 7](podman.md#実施手順)）につなぐ。Pods の権限には `xdg-run/podman:ro` がある
- BoxBuddy はホストの distrobox（[distrobox.md](distrobox.md)）を使う。権限は `filesystems=home` と、Flatpak の外のコマンドを呼ぶための `org.freedesktop.Flatpak=talk`
- Pods と BoxBuddy の 2 本で、`/var/lib/flatpak` は 2.5 GB になった（GNOME 50 の runtime）
- Cockpit は `sudo systemctl enable --now cockpit.socket` の後、`https://127.0.0.1:9090/` が応答し、`/usr/share/cockpit/podman` があることまで確かめた。ブラウザでのログインと画面は見ていない
  - `cockpit-podman` だけを入れると、依存は `cockpit-bridge` だけで、Web の画面（`cockpit-ws`）は入らなかった。素のコンテナでは、`cockpit` も入れて 102 パッケージになった
- distrobox の GUI には DistroShelf（Flathub `com.ranfdev.DistroShelf` 1.5.2、検証済み、GNOME 50）もある（メタデータのみ）

### GNOME・システム

| ツール | 用途 | 推奨 | 導入コマンド | ほかの経路 | aarch64 | 確認 |
|---|---|---|---|---|---|---|
| GNOME Tweaks | GNOME の細かい設定 | EPEL 46.1 | `sudo dnf install -y gnome-tweaks` | Flathub に無い | 有 | 起動 |
| Extension Manager | GNOME 拡張の検索と導入 | Flathub `com.mattjakeman.ExtensionManager` 0.6.5（検証済み、GNOME 50） | `sudo flatpak install -y flathub com.mattjakeman.ExtensionManager` | AppStream の `gnome-extensions-app` 46.2（入れてある拡張の管理だけ） | 有 | 導入 |
| Flatseal | Flatpak アプリの権限を変える | Flathub `com.github.tchx84.Flatseal` 2.4.1（検証済み、GNOME 50） | [flatpak.md 手順 6](flatpak.md#実施手順) | — | 有 | 導入 |
| Mission Center | リソースモニタ（GUI） | Flathub `io.missioncenter.MissionCenter` 1.2.0（検証済み、GNOME 50） | `sudo flatpak install -y flathub io.missioncenter.MissionCenter` | RPM 無し | 有 | 導入 |
| Remmina | リモートデスクトップのクライアント | EPEL 1.4.39 | `sudo dnf install -y remmina` | Flathub `org.remmina.Remmina` 1.4.43（検証済み） | 有 | 導入 |
| LocalSend | LAN 内の端末とファイルを送り合う | Flathub `org.localsend.localsend_app` 1.18.2（検証済み、FDO 25.08） | `sudo flatpak install -y flathub org.localsend.localsend_app` | RPM 無し | 有 | 導入 |

---

## ベンダーの dnf リポジトリ

上の表で「ベンダーの dnf リポジトリ」を推奨にした 2 つ。

- **リポジトリの登録から導入まで、x86_64 コンテナでこのとおり実行した**
- `dnf config-manager` は `dnf-plugins-core` に入っている（EPEL を入れると一緒に入る）

**Google Chrome**（Google は `.repo` ファイルを配っていないので、自分で置く）:

```bash
{
  sudo tee /etc/yum.repos.d/google-chrome.repo >/dev/null <<'EOF'
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
  sudo dnf install -y google-chrome-stable
  google-chrome-stable --version
}
```

- `google-chrome-stable` の導入時の処理（rpm の scriptlet）は、同じ `/etc/yum.repos.d/google-chrome.repo` を書き直す
- 導入後のファイルは、`baseurl` の `$basearch` がアーキの名前（x86_64 では `.../stable/x86_64`）に置き換わっただけで、ほかは上と同じだった
- `/etc/cron.daily/google-chrome` も置かれる

**mise**:

```bash
{
  sudo dnf config-manager --add-repo https://mise.jdx.dev/rpm/mise.repo
  sudo dnf install -y mise
  mise --version
}
```

鍵を確かめる場合、登録・導入のときに取り込まれる鍵の fingerprint は次の値だった（調査日）。

| リポジトリ | 鍵 | fingerprint |
|---|---|---|
| Google | Google Inc. (Linux Packages Signing Authority) | `EB4C 1BFD 4F04 2F6D DDCC EC91 7721 F63B D38B 4796`（rpm は副鍵 `c264648f` で署名） |
| mise | mise releases | `2485 3EC9 F655 CE80 B48E 6C3A 8B81 C9D1 7413 A06D` |

---

## aarch64 で使えないもの

Raspberry Pi 5（aarch64）で使えないもの。どれも x86_64 には提供がある（メタデータ）。

| ツール | x86_64 の提供元 | aarch64 |
|---|---|---|
| Microsoft Edge | 公式 dnf リポジトリ 154.0.4258.37 / Flathub `com.microsoft.Edge` 153.0.4234.48（未検証） | どちらにも無い |
| VirtualBox | Oracle 公式 dnf リポジトリ 7.2.20（[virtualbox.md](virtualbox.md)） | 無い（リポジトリの `el/10/aarch64/` が 404 で、Linux 向けの配布は x86_64 だけ） |
| Dropbox（公式クライアント） | Dropbox 公式の tarball（[dropbox.md](dropbox.md)）/ Flathub `com.dropbox.Client`（未検証） | 無い（`download?plat=lnx.aarch64` が 404 で、公式ヘルプも ARM は非対応）。rclone で同期する（[dropbox-rclone.md](dropbox-rclone.md)） |

---

## 更新

経路ごとにまとめて上げる。それぞれ別の仕組みなので、1 つを実行してもほかは上がらない。

```bash
{
  brew upgrade
  sudo dnf upgrade
  sudo flatpak update
}
```

`sudo dnf upgrade` は AppStream / EPEL / ベンダーのリポジトリの分をまとめて上げる。

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 で使う CLI・GUI ツールを、導入元ごとに比べて 1 か所から選べるようにする。**個別の手順書を作るほどではないツールは、この一覧の 1 行で済ませる**

| 項目 | 値 |
|---|---|
| 調査日時 | 2026-09-24、UTC 20:51〜21:20（版の取得は 20:51〜20:57） |
| 検証コンテナ | `quay.io/almalinuxorg/almalinux:10`（`sha256:83220192…c4c8`、AlmaLinux 10.2 (Lavender Lion) / x86_64、dnf 4.20.0） |
| コンテナの動かし方 | Ubuntu 24.04 / x86_64 のクラウドホスト上の Docker 29.3.1。`--network host`、Flatpak だけ `--privileged`。非 root ユーザーに NOPASSWD の sudo |
| Homebrew | 7.0.6（[homebrew.md](homebrew.md) の手順 1〜3 をそのまま通して導入） |
| EPEL | `epel-release-10-6.el10`（`extras`）。CRB はイメージの既定で有効 |
| flatpak | `flatpak-1.16.0-9.el10_2.1`（AppStream） |
| aarch64 の調べ方 | RPM: `dnf --forcearch=aarch64 repoquery`。Homebrew: formulae.brew.sh の JSON のボトル（`arm64_linux`）。Flathub: `flatpak remote-ls --arch=aarch64` と `flatpak remote-info --arch=aarch64` |
| コンテナの節の調査日時 | 2026-09-27、UTC 16:26〜17:40 |
| コンテナの節の検証コンテナ | `quay.io/almalinuxorg/10-init:10.2`（`sha256:a91c1066…fd73`）を `--privileged` で立て、systemd を PID 1 にした。中で rootless の podman を動かすため（[podman.md](podman.md) の付録と同じ作り） |
| コンテナの節の aarch64 の調べ方 | RPM: AppStream・BaseOS・EPEL 10.2・Trivy のリポジトリの `primary.xml` を直接読んだ。Homebrew と Flathub は上と同じ |

- これまでの手順書の「コンテナのみ」の検証は、実機（Raspberry Pi 5）の上の podman で `docker.io/library/almalinux:10` を使っていた
- **この一覧は x86_64 のクラウドホスト上の Docker で、`quay.io` の同じ AlmaLinux 10 公式イメージを使っている**（Docker Hub がレート制限を返したため）

### 注意点

- **Homebrew の依存がシステムのコマンドを隠す**: `brew install podman-compose` は podman 6.1.2 に加えて `util-linux`・`python@3.14`・`gnupg`・`sqlite` など 41 個を依存として入れる（すべてボトル）
  - その結果、PATH の先頭で `podman`・`mount`・`gpg`・`python3` が Homebrew のものに置き換わった（`command -v` で確認）
  - `brew uninstall podman-compose` と `brew autoremove` で元に戻る
  - **依存の多い formula を入れた後は、`command -v` で主要なコマンドの場所を確かめる**
- **同じ名前の実行ファイルを RPM と Homebrew で二重に入れない**: EPEL の `fd-find` も Homebrew の `fd` も実行ファイルは `fd` で、両方入れると PATH の先頭にある Homebrew 版が勝つ（[bat.md](bat.md) と同じ問題）
- **Flathub の「検証済み」はアプリの公開元の確認**で、中身の審査ではない
  - 未検証のもの（Chrome・Chromium・Edge など）は、上流ではない第三者が包んでいる場合がある
- **Flathub は aarch64 の appstream を配っていない**（`flatpak update --appstream --arch=aarch64` が `No such ref 'appstream2/aarch64'` で失敗する）
  - そのため aarch64 の版は表に書けない
  - 代わりに、aarch64 に提供があるものはすべて、`flatpak remote-info` のコミットの件名が x86_64 と一致することを確かめた（同じ版のビルドと推定できる）
- **Flatpak の容量**: 最初の 1 本（Flatseal）で `/var/lib/flatpak` が 2.5 GB になった
  - GNOME 50 の runtime・その翻訳・GL ドライバ・コーデックの拡張が一緒に入るため
  - 一覧の Flathub のアプリを全部入れると、runtime は GNOME 50・FDO 25.08・FDO 26.08 の 3 系統になる
  - 調査時は、ほかのアプリも合わせた 13 本で 8.1 GB になった（[付録](#付録-コンテナでの検証記録2026-09-24)）
- **EL10 の rpm は、自己署名のハッシュが SHA-1 の古い鍵を取り込まない**（ベンダーのリポジトリの鍵で実測）
  - `rpm --import` は `Policy rejects <鍵 ID>: No binding signature at time …` を出してその鍵を取り込まず、終了コード 2 で終わる
  - 取り込めない鍵があっても、rpm の署名に使われている鍵が取り込めていれば、導入はできる
  - `rpm --import` を省いて `dnf install` に鍵の取り込みを任せると、dnf は取り込めない鍵で止まり、`GPG check FAILED` で失敗する
  - 自己署名のハッシュは `gpg --list-packets` の `digest algo` で分かる（2 が SHA-1、10 が SHA-512）
- **版は日々変わる**: 表の版は調査日のもの。現在の版は `brew info <formula>` / `dnf info <package>` / `flatpak remote-info flathub <ID>` で見る
- **x86_64_v2 版は見ていない**: AlmaLinux 10 には古い CPU 向けの `x86_64_v2` 版のリポジトリもあるが、本書は通常の x86_64 版だけを調べた

### 参照

- [Homebrew Formulae](https://formulae.brew.sh/) — formula の版とボトルの一覧（JSON API は `https://formulae.brew.sh/api/formula/<名前>.json`）
- [EPEL — Fedora Docs](https://docs.fedoraproject.org/en-US/epel/) — EPEL の方針と有効化の手順
- [Flathub](https://flathub.org/) — アプリの検索、公開元の検証（Verified）の表示
- [RPM Fusion — Configuration](https://rpmfusion.org/Configuration) — EL 向けの有効化の手順（本書では使っていない。有効にする手順書は [rpmfusion.md](rpmfusion.md)）
- [Google Chrome の Linux 向けリポジトリ](https://www.google.com/linuxrepositories/) / [mise — Installing](https://mise.jdx.dev/installing-mise.html) — ベンダーのリポジトリの登録手順

---

### 付録: コンテナでの検証記録（2026-09-24）

使い捨てのコンテナを 4 つ使い分けた。どれも同じイメージで、プロキシの CA を信頼ストアに足し、`tester` ユーザーに NOPASSWD の sudo を与えている。

| コンテナ | 用途 |
|---|---|
| `meta` | 版の調査だけ（EPEL と flatpak を入れて照会） |
| `cli` | Homebrew と CLI（Homebrew / EPEL / mise のリポジトリ） |
| `gui` | GUI の RPM（ベンダー / EPEL） |
| `fp` | [flatpak.md](flatpak.md) の検証と、この一覧の Flathub のアプリ（`--privileged`） |
| `fps` | 再現の確認だけ（Flathub 登録直後の `flatpak search`） |

**版の調査で使ったコマンド**（`meta` で実行。`$(cat /tmp/rpmnames.txt)` はパッケージ名の一覧、`"..."` は 1 行目と同じ書式、`<...>` は実際には値を入れた）:

```
dnf -q repoquery --latest-limit=1 --arch=x86_64,noarch --qf "%{name}\t%{version}-%{release}\t%{arch}\t%{repoid}\n" $(cat /tmp/rpmnames.txt)
dnf -q --forcearch=aarch64 --setopt=cachedir=/var/cache/dnf-aarch64 repoquery --latest-limit=1 --arch=aarch64,noarch --qf "..." $(cat /tmp/rpmnames.txt)
dnf -q --forcearch=<ARCH> --repofrompath=<ID>,<URL> --repo=<ID> repoquery --latest-limit=1 --qf "..." <PACKAGE>
flatpak remote-ls flathub --app --arch=<ARCH> --columns=application,version,branch,runtime,download-size
flatpak remote-info --arch=<ARCH> flathub <ID>
curl -s https://formulae.brew.sh/api/formula/<FORMULA>.json
curl -s https://flathub.org/api/v2/verification/<ID>/status
```

**導入の結果:**

| グループ | 結果 |
|---|---|
| Homebrew（`cli`） | 表の Homebrew の行と、比較のための `podman-tui` / `podman-compose`、合わせて 24 個を 1 つずつ `brew install` し、すべて終了コード 0。すべてボトルで、ソースビルドは 0。1 個あたり 2〜12 秒。全部入れた時点で `/home/linuxbrew/.linuxbrew` は 1.5 GB（`podman-compose` とその依存を消した後は 959 MB） |
| EPEL の CLI（`cli`） | `fastfetch` / `duf` / `mosh` / `restic` / `distrobox` / `podman-compose` / `podman-tui` がすべて終了コード 0。追加で入ったパッケージ数は fastfetch 3、duf 1、mosh 3、restic 4、distrobox 31（podman を含む）、podman-compose 5。CRB を有効にする操作はしていない（イメージの既定で有効） |
| mise（`cli`） | `dnf config-manager --add-repo` の後の `dnf install -y mise` で鍵 `0x7413A06D` が取り込まれ、`mise --version` → `2026.9.13 linux-x64 (2026-09-24)` |
| ベンダーの GUI（`gui`） | `google-chrome-stable --version` → `Google Chrome 154.0.8037.57` |
| EPEL の GUI（`gui`） | `chromium-browser --version` → `Chromium 153.0.8010.52`、`keepassxc-cli --version` → `2.7.11`、`gnome-tweaks --version` → `46.1`。`meld --version` は画面が無いため GTK の初期化で落ちた（`AttributeError: 'NoneType' object has no attribute 'props'`）。`remmina --version` は案内文だけで版を出さなかった。この 2 つは `rpm -q` で版を確認した |
| 更新（`cli` / `fp`） | [更新](#更新)の 3 行を実行した。`brew upgrade` は無出力で終了コード 0（導入直後なので上げるものが無い）、`sudo dnf upgrade` はイメージの作成後に出た更新を当てて `Complete!`、`sudo flatpak update` は `Nothing to do.` |
| Flathub（`fp`） | 13 本（一覧に載っていないアプリを含む）を `sudo flatpak install -y --noninteractive flathub <ID>` で入れ、すべて終了コード 0、`flatpak run --command=true` もすべて成功。`--noninteractive` は進捗表示を抑えるためだけに足した。`/var/lib/flatpak` は GNOME 50 の 6 本で 3.4 GB、FDO 25.08 の 4 本を足して 5.7 GB、FDO 26.08 の 3 本を足して 8.1 GB |

#### 未確認事項

- aarch64 での導入と起動（本書の aarch64 列はすべてメタデータ）
- GUI アプリの画面の表示と操作（コンテナに画面が無い）
- Raspberry Pi 5 で Flathub のアプリ（Electron 系・ブラウザ・GPU を使うもの）が実際に動くか
- 実機（x86_64 PC）での導入。デスクトップの環境では依存の数が変わる（[vscode.md](vscode.md) の実測では、コンテナより大幅に少なかった）
- RPM Fusion（EL10）の有効化
- atuin・direnv など、`~/.bashrc` に追記して使うツールのシェルへの組み込み
- lazydocker・dive を podman の API ソケットで使うこと
- mosh の接続（サーバー側の導入と UDP の許可）
- Flathub の Chrome / Chromium / Edge など未検証の公開元のアプリの中身

---

### 付録: コンテナ関連の追加調査（2026-09-27）

[CLI: コンテナ](#cli-コンテナ)と GUI の[コンテナ](#コンテナ)の節のために、同じクラウドホストの Docker で使い捨てのコンテナを 2 つ使った。

- どちらも `quay.io/almalinuxorg/10-init:10.2` で systemd を PID 1 にした
- 非 root ユーザー（NOPASSWD の sudo）に SSH でログインして、表の導入コマンドをそのまま実行した

| コンテナ | 用途 |
|---|---|
| `cat1` | CLI の行と Cockpit。先に [podman.md](podman.md) の手順 1〜3・5〜7 と Docker 向けの節、EPEL の有効化（今の [epel.md](epel.md) の手順 1〜3。当時は btop.md の手順 1〜3）、[homebrew.md](homebrew.md) の手順 1〜4 を通した |
| `fp1` | GUI の Flathub の行。[flatpak.md](flatpak.md) の手順 1〜5 を通してから入れた |

**手順書の外で行った準備**（検証環境の都合）:

- プロキシの CA を信頼ストアに足し、dnf にプロキシを設定し、AlmaLinux のミラー一覧と EPEL の metalink を https にした
- cgroup v2 に pids のコントローラが無い環境なので、`/etc/containers/containers.conf.d/` で podman の既定の PID 数の制限を外した
- `fp1` では、`sudo` がプロキシの環境変数を消して `flatpak remote-add` が証明書の検証で失敗したので、sudoers の `env_keep` にプロキシの変数を足した

**結果:**

| 行 | 結果 |
|---|---|
| podman-tui | `sudo dnf install -y podman-tui` で 1 パッケージ（9.5 MB）。`podman-tui version` → `podman-tui v1.10.0`。端末を与えて起動すると、`localhost`（`unix://run/user/<UID>/podman/podman.sock`）が `connected` になり、`STATUS_OK`・API の版 `5.8.2`・`crun version 1.27` を出した。`Ctrl+C` で終了した |
| lazydocker | `lazydocker--0.25.2.x86_64_linux.bottle.tar.gz`。`lazydocker --version` → `Version: 0.25.2`・`BuildSource: Homebrew`。`DOCKER_HOST` を podman のソケットにした状態で起動し、`Containers`・`Images`・`Volumes`・`Networks` の枠に、動かしていた `ubi10/httpd-24` のコンテナ（`127.0.0.1:8090`）と、その Apache のログを出した。`q` で終了した |
| toolbox | 4 パッケージ（`toolbox`・`flatpak-session-helper`・弱い依存の `p11-kit-server` と `skopeo`、12 MB）。`toolbox --version` → `toolbox version 0.3` |
| podman-docker | 1 パッケージ（106 kB）。`command -v docker` → `/usr/bin/docker` |
| buildah | 1 パッケージ（10 MB）。`buildah --version` → `buildah version 1.43.2 (image-spec 1.1.1, runtime-spec 1.2.1)`（RPM は `1.43.1-6.el10_2`） |
| skopeo | toolbox の弱い依存で入っていて、`Package skopeo-2:1.22.2-5.el10_2.x86_64 is already installed.`。`skopeo --version` → `skopeo version 1.22.2` |
| podlet | `podlet--0.3.2.x86_64_linux.bottle.tar.gz`。`podlet --version` → `podlet 0.3.2` |
| cosign | `cosign--3.1.3.x86_64_linux.bottle.tar.gz`。`cosign version` → `GitVersion: v3.1.3` |
| Cockpit | `sudo dnf install -y cockpit-podman` だけでは 2 パッケージ（`cockpit-podman`・`cockpit-bridge`）。続けて `sudo dnf install -y cockpit cockpit-podman` で 102 パッケージ（44 MB）。`cockpit.socket` を有効にすると `https://127.0.0.1:9090/` が応答し（`<title>Loading...`）、`/cockpit/@localhost/podman/index.html` が 200 を返した |
| Pods / BoxBuddy | `sudo flatpak install -y flathub <ID>` で入れ、`flatpak run --command=true` がどちらも成功した。`flatpak info` は Pods 3.1.1（20.2 MB）、BoxBuddy 2.6.1（1.4 MB）で、runtime はどちらも `org.gnome.Platform/x86_64/50`。`/var/lib/flatpak` は 2.5 GB |
| aarch64 | AppStream（toolbox・podman-docker・buildah・skopeo・cockpit-podman）、BaseOS（cockpit 356.2）、EPEL 10.2（podman-tui 1.10.0）、Trivy のリポジトリ（0.74.0）のどれも aarch64 にある。Homebrew の lazydocker・podlet・cosign・hadolint・dive は `arm64_linux` のボトルがある。Flathub の Pods・BoxBuddy・Podman Desktop は、`flatpak remote-info --arch=aarch64` のコミットの件名が x86_64 と一致した |
| 移した行 | podman-compose（EPEL 1.5.0 / Homebrew 1.6.0）・podman-tui（1.10.0 / 2.0.0）・distrobox（1.8.2.3 / 1.8.2.5）・lazydocker 0.25.2・dive 0.13.1 は、2026-09-24 と同じ版だった |

最初の調査の[未確認事項](#未確認事項)にあった「lazydocker・dive を podman の API ソケットで使うこと」は、この調査で片付いた。

- lazydocker は、`DOCKER_HOST` で podman の API ソケットにつないで動いた（上の表）
- dive は API ソケットを使わず、`--source podman` で podman のコマンドからイメージを読んだ（[image-tools.md](image-tools.md)）

#### 未確認事項（2026-09-27 の調査）

- aarch64 での導入と起動（この調査の aarch64 もメタデータのみ）
- Pods・BoxBuddy・Podman Desktop・Cockpit の画面と操作
- toolbox でボックスを作ること（AlmaLinux のホストで `toolbox create` がどのイメージを選ぶか）
- cosign での署名と検証
- podman-tui・lazydocker での操作（コンテナの停止・削除など）
