# AlmaLinux 10 の CLI / GUI ツール導入元一覧

- [検証記録](verification/tool-catalog.md)・[参考資料](reference/tool-catalog.md)

AlmaLinux 10 で使える便利な CLI・GUI ツールを、**どこから入れるか**（導入元）で比べた一覧。この文書は手順書ではない。

- ツールごとに推奨する導入元・その時点の版・導入コマンド・ほかの経路・aarch64（Raspberry Pi 5）での提供の有無を 1 行にまとめてある
- 個別の手順書があるツールは[文書化済みのツール](#文書化済みのツール)から手順書へ進む

「確認」列の意味:

| 値 | 意味 |
|---|---|
| 起動 | x86_64 コンテナで導入し、`--version` などを実行して版が出た |
| 導入 | x86_64 コンテナで導入まで確認した。Flatpak のアプリは、サンドボックスの起動（`flatpak run --command=true`）も確認した。画面が要るため、アプリそのものは動かしていない |
| メタデータ | 提供の有無と版を調べただけで、入れていない |

表の版は調査日のもの。**導入コマンドを貼る前提**は、導入元ごとに次のとおり。

- Homebrew（`brew install`）: [AlmaLinux 10 の初期設定の「Homebrew」の手順 1〜3](almalinux-setup.md#homebrew)（Homebrew）を通してあること
- EPEL（`sudo dnf install`。AppStream / BaseOS は前提なし）: [AlmaLinux 10 の初期設定の「EPEL と RPM Fusion」の手順 1](almalinux-setup.md#epel-と-rpm-fusion)（EPEL）を通してあること
- Flathub（`sudo flatpak install`）: [AlmaLinux 10 の初期設定の「Flatpak と Flathub」の手順 1〜3](almalinux-setup.md#flatpak-と-flathub)（Flatpak / Flathub）を通してあること
- ベンダーの dnf リポジトリ: [ベンダーの dnf リポジトリ](#ベンダーの-dnf-リポジトリ)の節で、そのリポジトリを登録してあること
- コンテナの節の行は、どの導入元でも [Podman](podman.md) の実施手順を通してあること（Pods・Podman Desktop などは、その API ソケットを使う）

---

## 導入経路と EL10 での注意

| 経路 | 有効にする方法 | 版の傾向 | aarch64 | EL10 での注意 | 詳細 |
|---|---|---|---|---|---|
| BaseOS / AppStream | 既定で有効 | 古めで固定。例: tmux 3.3a、jq 1.7.1、Firefox は ESR 140 | 調べた範囲では x86_64 と同じ版 | — | — |
| CRB | **既定で有効**。素のコンテナイメージで確認した（`almalinux-repos-10.2` の `almalinux-crb.repo` が `enabled=1`） | — | — | EPEL を入れたときに出る「CRB を有効に」の案内は、AlmaLinux 10 では済んでいる | [AlmaLinux 10 の初期設定](almalinux-setup.md) |
| EPEL 10 | [AlmaLinux 10 の初期設定の「EPEL と RPM Fusion」の手順 1](almalinux-setup.md#epel-と-rpm-fusion)。`sudo dnf install -y epel-release`（`extras` にある） | Homebrew より古いことが多い（fzf 0.58.0 など）。同じ版のものもある | 調べた範囲（AppStream なども含む）はすべて x86_64 と同じ版 | Chromium・KeePassXC などの GUI もある。**Homebrew と同じ名前の実行ファイルは二重に入れない**（`fd-find` は `/usr/bin/fd`） | [AlmaLinux 10 の初期設定](almalinux-setup.md) |
| RPM Fusion（EL10） | 本書では有効にしていない。free は [AlmaLinux 10 の初期設定の「EPEL と RPM Fusion」の手順 2〜5](almalinux-setup.md#epel-と-rpm-fusion) で、鍵を照合してから `rpmfusion-free-release` を入れる（EPEL が前提） | — | free はある | EL10 向けは中身が少ない。調べた範囲では free に `ffmpeg` 7.1.5 と `gstreamer1-plugins-bad-freeworld`、nonfree に `steam`（i686）。mpv は無い。`rpmfusion-free-release` は `epel-release` を要求する | [AlmaLinux 10 の初期設定](almalinux-setup.md)、[firefox.md](firefox.md)（`ffmpeg-libs`） |
| ベンダーの dnf リポジトリ | `.repo` を置く | 上流の最新 | ベンダー次第（Chrome・mise・Trivy は両方、Edge と VirtualBox は x86_64 のみ） | **EL10 の rpm は、自己署名が SHA-1 の古い鍵を取り込まない** | [ベンダーの dnf リポジトリ](#ベンダーの-dnf-リポジトリ)、[注意点](#注意点)、[firefox.md](firefox.md)、[gh.md](gh.md)、[vscode.md](vscode.md)、[virtualbox.md](virtualbox.md)、[image-tools.md](image-tools.md)（Trivy） |
| COPR | `dnf copr enable` | 上流に近い | プロジェクト次第 | EL10 向けの chroot が無い、または repomd が 403 になる例がある | [lazygit.md](lazygit.md)、[wezterm-nightly.md](wezterm-nightly.md)、[AlmaLinux 10 の初期設定の検証記録](verification/almalinux-setup.md#zoxide-付録-dnf-の経路のコンテナでの検証記録2026-09-29)（zoxide の外した dnf の経路の記録） |
| Homebrew | 公式インストーラ | 上流の最新 | 調べた CLI はすべてボトルがある（`arm64_linux`。distrobox だけはアーキ共通の `all`） | 導入・更新などの管理操作は一般ユーザーで行う。**依存がシステムのコマンドを隠すことがある**（podman-compose で実測） | [AlmaLinux 10 の初期設定](almalinux-setup.md)、[注意点](#注意点) |
| Flathub | [AlmaLinux 10 の初期設定の「Flatpak と Flathub」の手順 1〜3](almalinux-setup.md#flatpak-と-flathub) | 上流の最新 | アプリ次第。Microsoft Edge は x86_64 のみ（[aarch64 で使えないもの](#aarch64-で使えないもの)） | 公開元が「検証済み」かどうかを見る。runtime の分だけ容量を食う | [AlmaLinux 10 の初期設定](almalinux-setup.md) |
| AppImage | ダウンロードして実行 | 上流の最新 | 配布次第 | FUSE2（`fuse-libs`）と glibc 2.39 の制約がある | [wezterm-nightly.md](wezterm-nightly.md) |

## 選び方

**CLI** は、既存の手順書と同じ規則で選んだ（[Homebrew](reference/almalinux-setup.md#homebrew-選択した方針)と [btop](verification/btop.md#選択した方針) の「選択した方針」）。

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
| Homebrew 本体 | 公式インストーラ | [AlmaLinux 10 の初期設定](almalinux-setup.md)（「Homebrew」の手順 1〜3） |
| Flatpak / Flathub | AppStream + Flathub | [AlmaLinux 10 の初期設定](almalinux-setup.md)（「Flatpak と Flathub」の手順 1〜3） |
| starship / zoxide / fzf / eza / bat / tmux | Homebrew（初期化は共通の bash 設定） | [AlmaLinux 10 の初期設定](almalinux-setup.md)（「シェルのツール」の手順 1） |
| yazi / lazygit / Neovim / git-delta / gdu / ShellCheck・shfmt | Homebrew | [yazi](yazi.md) / [lazygit](lazygit.md) / [Neovim](neovim.md) / [git-delta](git-delta.md) / [gdu](gdu.md) / [ShellCheck・shfmt](shellcheck.md) |
| Syncthing | Homebrew + systemd ユーザーサービス | [syncthing.md](syncthing.md) |
| Dropbox（公式クライアント） | Dropbox 公式の tarball + systemd ユーザーサービス（x86_64 のみ。公式 RPM は EL10 に入らない） | [dropbox.md](dropbox.md) |
| rclone（Dropbox の同期） | Homebrew + systemd ユーザータイマー（aarch64 の Dropbox 用） | [dropbox-rclone.md](dropbox-rclone.md) |
| btop | EPEL | [btop.md](btop.md) |
| Firefox | Mozilla 公式 dnf リポジトリ | [firefox.md](firefox.md) |
| Claude Code / GitHub CLI | 公式 dnf リポジトリ | [claude-code.md](claude-code.md) / [gh.md](gh.md) |
| Codex CLI | OpenAI 公式 standalone インストーラー（Node.js 不要。起動したときに新しい版を知らせ、Enter で上がる。Windows 11 の手順もある） | [codex.md](codex.md) |
| Grok Build | xAI 公式のインストーラー（Node.js 不要。起動したときに自分で上がる。`~/.bashrc` に PATH のブロックを足す。Windows 11 の手順もある） | [grok-build.md](grok-build.md) |
| Codex・Grok Build の Claude Code 用プラグイン | Claude Code のプラグインのマーケットプレイス（OpenAI と xAI の GitHub の公式のリポジトリ）。プラグインが使う Node.js は AppStream | [coding-agents.md](coding-agents.md) |
| VS Code | Microsoft 公式 dnf リポジトリ | [vscode.md](vscode.md) |
| VirtualBox | Oracle 公式 dnf リポジトリ（EPEL が前提。x86_64 のみ） | [virtualbox.md](virtualbox.md) |
| WezTerm Nightly | COPR（EL9 向けビルドの流用） | [wezterm-nightly.md](wezterm-nightly.md) |
| HackGen Console NF（フォント） | Homebrew の cask（`~/.local/share/fonts` に入る） | [hackgen.md](hackgen.md) |
| IBus + Anthy（日本語入力） | AppStream（Workstation には最初から入っている） | [AlmaLinux 10 の初期設定](almalinux-setup.md)（「日本語入力」の手順 1・2） |
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

| ツール | 用途 | 推奨 | 導入コマンド | ほかの経路 | aarch64 | 確認 |
|---|---|---|---|---|---|---|
| toolbox | 別のディストリの端末をコンテナで使う（distrobox と同類。RHEL の公式） | AppStream 0.3 | `sudo dnf install -y toolbox` | Homebrew に無い | 有 | 起動 |
| podman-docker | `docker` コマンドを podman に読み替える | AppStream 5.8.2 | `sudo dnf install -y podman-docker` | — | 有 | 起動 |
| buildah | Containerfile を使わずにイメージを作る | AppStream 1.43.1 | `sudo dnf install -y buildah` | Homebrew に無い | 有 | 起動 |
| skopeo | レジストリのイメージを取得せずに調べる・コピーする | AppStream 1.22.2 | `sudo dnf install -y skopeo` | Homebrew 1.24.1（設定を `/home/linuxbrew/.linuxbrew/etc/containers` から読む） | 有 | 起動 |
| podlet | podman のコマンドや compose ファイルから Quadlet の定義を作る | Homebrew 0.3.2 | `brew install podlet` | RPM 無し | 有 | 起動 |
| cosign | イメージの署名と検証 | Homebrew 3.1.3 | `brew install cosign` | RPM 無し | 有 | 起動 |

- 「起動」は `--version`（cosign は `cosign version`）が版を出したことを示す
- podman-docker の `docker --version` は、`Emulate Docker CLI using podman. Create /etc/containers/nodocker to quiet msg.` と `podman version 5.8.2` を出した
  - 入れると、lazydocker の `E`（シェル）・`a`（アタッチ）と compose の判定が、既定の設定のまま動いた（[lazydocker.md](lazydocker.md) の選択した方針）
- buildah の RPM の版は `1.43.1-6.el10_2` だが、`buildah --version` は `buildah version 1.43.2` を出した
- podlet は、`podlet podman run --name demo -p 127.0.0.1:8090:8080 <イメージ>` で Quadlet の `[Container]` 節を出した
  - `-d` だけでは指定せず、`--detach=true` と書く
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

- Pods と Podman Desktop は podman の API ソケット（[podman.md 手順 7](podman.md#実施手順)）につなぐ。Pods の権限には `xdg-run/podman:ro` がある
- BoxBuddy はホストの distrobox（[distrobox.md](distrobox.md)）を使う。権限は `filesystems=home` と、Flatpak の外のコマンドを呼ぶための `org.freedesktop.Flatpak=talk`
  - `cockpit-podman` だけを入れると、依存は `cockpit-bridge` だけで、Web の画面（`cockpit-ws`）は入らなかった。素のコンテナでは、`cockpit` も入れて 102 パッケージになった

### GNOME・システム

| ツール | 用途 | 推奨 | 導入コマンド | ほかの経路 | aarch64 | 確認 |
|---|---|---|---|---|---|---|
| GNOME Tweaks | GNOME の細かい設定 | EPEL 46.1 | `sudo dnf install -y gnome-tweaks` | Flathub に無い | 有 | 起動 |
| Extension Manager | GNOME 拡張の検索と導入 | Flathub `com.mattjakeman.ExtensionManager` 0.6.5（検証済み、GNOME 50） | `sudo flatpak install -y flathub com.mattjakeman.ExtensionManager` | AppStream の `gnome-extensions-app` 46.2（入れてある拡張の管理だけ） | 有 | 導入 |
| Flatseal | Flatpak アプリの権限を変える | Flathub `com.github.tchx84.Flatseal` 2.4.1（検証済み、GNOME 50） | [AlmaLinux 10 の初期設定の「Flatpak と Flathub」の手順 4](almalinux-setup.md#flatpak-と-flathub) | — | 有 | 導入 |
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

経路ごとにまとめて上げる。それぞれ別の仕組みなので、1 つを実行してもほかは上がらない。確認が出たら内容を見て答え、更新が成功してプロンプトに戻ってから、次のブロックを貼る。

```bash
brew upgrade
```

```bash
sudo dnf upgrade
```

```bash
sudo flatpak update
```

`sudo dnf upgrade` は AppStream / EPEL / ベンダーのリポジトリの分をまとめて上げる。

---

## 注意点

- **Homebrew の依存がシステムのコマンドを隠す**: `brew install podman-compose` は podman 6.1.2 に加えて `util-linux`・`python@3.14`・`gnupg`・`sqlite` など 41 個を依存として入れる（すべてボトル）
  - その結果、PATH の先頭で `podman`・`mount`・`gpg`・`python3` が Homebrew のものに置き換わった（`command -v` で確認）
  - `brew uninstall podman-compose` と `brew autoremove` で元に戻る
  - **依存の多い formula を入れた後は、`command -v` で主要なコマンドの場所を確かめる**
- **同じ名前の実行ファイルを RPM と Homebrew で二重に入れない**: EPEL の `fd-find` も Homebrew の `fd` も実行ファイルは `fd` で、両方入れると PATH の先頭にある Homebrew 版が勝つ（bat と同じ問題。[AlmaLinux 10 の初期設定の注意点](extra/almalinux-setup.md#注意点)）
- **Flathub の「検証済み」はアプリの公開元の確認**で、中身の審査ではない
  - 未検証のもの（Chrome・Chromium・Edge など）は、上流ではない第三者が包んでいる場合がある
- **Flathub は aarch64 の appstream を配っていない**（`flatpak update --appstream --arch=aarch64` が `No such ref 'appstream2/aarch64'` で失敗する）
  - そのため aarch64 の版は表に書けない
- **Flatpak の容量**: 最初の 1 本（Flatseal）で `/var/lib/flatpak` が 2.5 GB になった
  - GNOME 50 の runtime・その翻訳・GL ドライバ・コーデックの拡張が一緒に入るため
  - 一覧の Flathub のアプリを全部入れると、runtime は GNOME 50・FDO 25.08・FDO 26.08 の 3 系統になる
- **EL10 の rpm は、自己署名のハッシュが SHA-1 の古い鍵を取り込まない**
  - `rpm --import` は `Policy rejects <鍵 ID>: No binding signature at time …` を出してその鍵を取り込まず、終了コード 2 で終わる
  - 取り込めない鍵があっても、rpm の署名に使われている鍵が取り込めていれば、導入はできる
  - `rpm --import` を省いて `dnf install` に鍵の取り込みを任せると、dnf は取り込めない鍵で止まり、`GPG check FAILED` で失敗する
  - 自己署名のハッシュは `gpg --list-packets` の `digest algo` で分かる（2 が SHA-1、10 が SHA-512）
- **版は日々変わる**: 表の版は調査日のもの。現在の版は `brew info <formula>` / `dnf info <package>` / `flatpak remote-info flathub <ID>` で見る
- **x86_64_v2 版は見ていない**: AlmaLinux 10 には古い CPU 向けの `x86_64_v2` 版のリポジトリもあるが、本書は通常の x86_64 版だけを調べた
