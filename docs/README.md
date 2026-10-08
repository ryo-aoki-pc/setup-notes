# 目的別の手順書一覧

[導入順](getting-started.md)・[手順書とツールの比較](catalog.md)・[導入元一覧](tool-catalog.md)・[リポジトリの入口](../README.md)

初めて構築するときは [導入順](getting-started.md)から始める。目的が決まっていれば、下の分類から手順書を選ぶ。
各行から、操作を行う手順書、採用理由を読む参考資料、実施範囲を確かめる検証記録を開ける。

- [初期設定と共通の前提](#初期設定と共通の前提)
- [リモート接続と VPN](#リモート接続と-vpn)
- [ファイル共有と同期](#ファイル共有と同期)
- [端末とファイル操作](#端末とファイル操作)
- [エディタと Git](#エディタと-git)
- [AI と開発ツール](#ai-と開発ツール)
- [コンテナと仮想化](#コンテナと仮想化)
- [ブラウザと通信制約](#ブラウザと通信制約)

## 初期設定と共通の前提

| 手順書 | 参考資料 | 検証記録 |
|---|---|---|
| [AlmaLinux 10 の初期設定](almalinux-setup.md) | [背景・方針](reference/almalinux-setup.md) | [状態・結果](verification/almalinux-setup.md) |
| [Windows 11 の初期設定](windows-setup.md) | [背景・方針](reference/windows-setup.md) | [状態・結果](verification/windows-setup.md) |
| [Windows 11 のデュアルブート向けの導入](windows-dual-boot.md) | [背景・方針](reference/windows-dual-boot.md) | [状態・結果](verification/windows-dual-boot.md) |
| [ログアウト中のユーザーサービス（linger）](linger.md) | [背景・方針](reference/linger.md) | [状態・結果](verification/linger.md) |
| [Secure Boot の MOK 登録](secure-boot-mok.md) | [背景・方針](reference/secure-boot-mok.md) | [状態・結果](verification/secure-boot-mok.md) |

## リモート接続と VPN

| 手順書 | 参考資料 | 検証記録 |
|---|---|---|
| [WireGuard VPN のサーバー](wireguard.md) | [背景・方針](reference/wireguard.md) | [状態・結果](verification/wireguard.md) |
| [WireGuard の外出先のクライアント](wireguard-road-warrior.md) | [背景・方針](reference/wireguard-road-warrior.md) | [状態・結果](verification/wireguard-road-warrior.md) |
| [GNOME のリモートログイン](gnome-remote-desktop.md) | [背景・方針](reference/gnome-remote-desktop.md) | [状態・結果](verification/gnome-remote-desktop.md) |
| [GNOME のヘッドレスのセッション](gnome-headless-session.md) | [背景・方針](reference/gnome-headless-session.md) | [状態・結果](verification/gnome-headless-session.md) |
| [GNOME のデスクトップ共有](gnome-desktop-sharing.md) | [背景・方針](reference/gnome-desktop-sharing.md) | [状態・結果](verification/gnome-desktop-sharing.md) |
| [Windows の OpenSSH サーバー](windows-openssh-server.md) | [背景・方針](reference/windows-openssh-server.md) | [状態・結果](verification/windows-openssh-server.md) |
| [Windows の SSH クライアント](windows-ssh-client.md) | [背景・方針](reference/windows-ssh-client.md) | [状態・結果](verification/windows-ssh-client.md) |
| [Windows の RDP をロックせずに切断](windows-rdp-disconnect.md) | [背景・方針](reference/windows-rdp-disconnect.md) | [状態・結果](verification/windows-rdp-disconnect.md) |
| [ssh の SOCKS トンネル](ssh-socks-tunnel.md) | [背景・方針](reference/ssh-socks-tunnel.md) | [状態・結果](verification/ssh-socks-tunnel.md) |

## ファイル共有と同期

| 手順書 | 参考資料 | 検証記録 |
|---|---|---|
| [Samba のサーバー](samba.md) | [背景・方針](reference/samba.md) | [状態・結果](verification/samba.md) |
| [Samba のクライアント](samba-client.md) | [背景・方針](reference/samba-client.md) | [状態・結果](verification/samba-client.md) |
| [Syncthing](syncthing.md) | [背景・方針](reference/syncthing.md) | [状態・結果](verification/syncthing.md) |
| [Dropbox の公式クライアント](dropbox.md) | [背景・方針](reference/dropbox.md) | [状態・結果](verification/dropbox.md) |
| [Dropbox の rclone 同期](dropbox-rclone.md) | [背景・方針](reference/dropbox-rclone.md) | [状態・結果](verification/dropbox-rclone.md) |

## 端末とファイル操作

| 手順書 | 参考資料 | 検証記録 |
|---|---|---|
| [WezTerm Nightly](wezterm-nightly.md) | [背景・方針](reference/wezterm-nightly.md) | [状態・結果](verification/wezterm-nightly.md) |
| [HackGen Console NF](hackgen.md) | [背景・方針](reference/hackgen.md) | [状態・結果](verification/hackgen.md) |
| [yazi](yazi.md) | [背景・方針](reference/yazi.md) | [状態・結果](verification/yazi.md) |
| [gdu](gdu.md) | [背景・方針](reference/gdu.md) | [状態・結果](verification/gdu.md) |
| [btop](btop.md) | [背景・方針](reference/btop.md) | [状態・結果](verification/btop.md) |

starship・zoxide・fzf・eza・bat・tmux は [AlmaLinux 10 の初期設定](almalinux-setup.md)に、Windows の Git Bash のツールは [Windows 11 の初期設定の任意節](windows-setup.md#シェルのツールを入れる任意)にある。

## エディタと Git

| 手順書 | 参考資料 | 検証記録 |
|---|---|---|
| [Neovim](neovim.md) | [背景・方針](reference/neovim.md) | [状態・結果](verification/neovim.md) |
| [VS Code](vscode.md) | [背景・方針](reference/vscode.md) | [状態・結果](verification/vscode.md) |
| [Git](git.md) | [背景・方針](reference/git.md) | [状態・結果](verification/git.md) |
| [git-delta](git-delta.md) | [背景・方針](reference/git-delta.md) | [状態・結果](verification/git-delta.md) |
| [GitHub CLI](gh.md) | [背景・方針](reference/gh.md) | [状態・結果](verification/gh.md) |
| [lazygit](lazygit.md) | [背景・方針](reference/lazygit.md) | [状態・結果](verification/lazygit.md) |

## AI と開発ツール

| 手順書 | 参考資料 | 検証記録 |
|---|---|---|
| [Claude Code](claude-code.md) | [背景・方針](reference/claude-code.md) | [状態・結果](verification/claude-code.md) |
| [Codex CLI](codex.md) | [背景・方針](reference/codex.md) | [状態・結果](verification/codex.md) |
| [Claude Code から GNOME の GUI を操作](claude-code-gui.md) | [背景・方針](reference/claude-code-gui.md) | [状態・結果](verification/claude-code-gui.md) |
| [Windows の Claude Code Remote Control](windows-claude-remote-control.md) | [背景・方針](reference/windows-claude-remote-control.md) | [状態・結果](verification/windows-claude-remote-control.md) |
| [ShellCheck / shfmt](shellcheck.md) | [背景・方針](reference/shellcheck.md) | [状態・結果](verification/shellcheck.md) |

## コンテナと仮想化

| 手順書 | 参考資料 | 検証記録 |
|---|---|---|
| [Podman](podman.md) | [背景・方針](reference/podman.md) | [状態・結果](verification/podman.md) |
| [distrobox](distrobox.md) | [背景・方針](reference/distrobox.md) | [状態・結果](verification/distrobox.md) |
| [podman-compose](podman-compose.md) | [背景・方針](reference/podman-compose.md) | [状態・結果](verification/podman-compose.md) |
| [podman-tui](podman-tui.md) | [背景・方針](reference/podman-tui.md) | [状態・結果](verification/podman-tui.md) |
| [lazydocker](lazydocker.md) | [背景・方針](reference/lazydocker.md) | [状態・結果](verification/lazydocker.md) |
| [hadolint / dive / Trivy](image-tools.md) | [背景・方針](reference/image-tools.md) | [状態・結果](verification/image-tools.md) |
| [VirtualBox](virtualbox.md) | [背景・方針](reference/virtualbox.md) | [状態・結果](verification/virtualbox.md) |
| [bootc ゲストの VirtualBox Guest Additions](virtualbox-guest-bootc.md) | [背景・方針](reference/virtualbox-guest-bootc.md) | [状態・結果](verification/virtualbox-guest-bootc.md) |

## ブラウザと通信制約

| 手順書 | 参考資料 | 検証記録 |
|---|---|---|
| [Firefox](firefox.md) | [背景・方針](reference/firefox.md) | [状態・結果](verification/firefox.md) |
| [インターネットに出られないホストの Homebrew](homebrew-offline.md) | [背景・方針](reference/homebrew-offline.md) | [状態・結果](verification/homebrew-offline.md) |
| [インターネットに出られないホストの npm](npm-offline.md) | [背景・方針](reference/npm-offline.md) | [状態・結果](verification/npm-offline.md) |

## 一覧・背景・検証を読む

| 読む目的 | 文書 |
|---|---|
| 用途が近いツールを比較する | [手順書とツールの比較](catalog.md) |
| 導入元・版・aarch64 の提供を比べる | [CLI / GUI ツール導入元一覧](tool-catalog.md)、[参考資料](reference/tool-catalog.md)、[検証記録](verification/tool-catalog.md) |
| 採用理由や背景を読む | [参考資料の一覧](reference/README.md) |
| 検証済みの範囲を調べる | [検証記録の一覧](verification/README.md)、[AlmaLinux の VM 検証総括](verification/almalinux-vm.md) |
| 手順書の読み方・書き方を確認する | [記法](writing-guide.md)、[編集規則](../CLAUDE.md#手順書の構造) |
