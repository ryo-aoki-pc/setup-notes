# 検証記録の一覧

[目的別の手順書一覧](../README.md)・[導入順](../getting-started.md)・[リポジトリの入口](../../README.md)

実施日・環境・結果・失敗・未実施の範囲を確かめるための索引。各文書の「状態」と、その実施に対応する記録を読む。

## 検証の総括

- [AlmaLinux 10 のクリーンインストールからの環境構築](almalinux-vm.md)
- [Windows 11 の初期設定と追加検証](windows-setup.md)
- [README から分離した過去の検証範囲](readme.md)

## 初期設定と共通の前提

| 検証記録 | 操作する手順書 |
|---|---|
| [AlmaLinux 10 の初期設定](almalinux-setup.md) | [手順書](../almalinux-setup.md) |
| [Windows 11 の初期設定](windows-setup.md) | [手順書](../windows-setup.md) |
| [Windows 11 のデュアルブート向けの導入](windows-dual-boot.md) | [手順書](../windows-dual-boot.md) |
| [ログアウト中のユーザーサービス（linger）](linger.md) | [手順書](../linger.md) |
| [Secure Boot の MOK 登録](secure-boot-mok.md) | [手順書](../secure-boot-mok.md) |

## リモート接続と VPN

| 検証記録 | 操作する手順書 |
|---|---|
| [WireGuard VPN のサーバー](wireguard.md) | [手順書](../wireguard.md) |
| [WireGuard の外出先のクライアント](wireguard-road-warrior.md) | [手順書](../wireguard-road-warrior.md) |
| [GNOME のリモートログイン](gnome-remote-desktop.md) | [手順書](../gnome-remote-desktop.md) |
| [GNOME のヘッドレスのセッション](gnome-headless-session.md) | [手順書](../gnome-headless-session.md) |
| [GNOME のデスクトップ共有](gnome-desktop-sharing.md) | [手順書](../gnome-desktop-sharing.md) |
| [Windows の OpenSSH サーバー](windows-openssh-server.md) | [手順書](../windows-openssh-server.md) |
| [Windows の SSH クライアント](windows-ssh-client.md) | [手順書](../windows-ssh-client.md) |
| [Windows の RDP をロックせずに切断](windows-rdp-disconnect.md) | [手順書](../windows-rdp-disconnect.md) |
| [ssh の SOCKS トンネル](ssh-socks-tunnel.md) | [手順書](../ssh-socks-tunnel.md) |

## ファイル共有と同期

| 検証記録 | 操作する手順書 |
|---|---|
| [Samba のサーバー](samba.md) | [手順書](../samba.md) |
| [Samba のクライアント](samba-client.md) | [手順書](../samba-client.md) |
| [Syncthing](syncthing.md) | [手順書](../syncthing.md) |
| [Dropbox の公式クライアント](dropbox.md) | [手順書](../dropbox.md) |
| [Dropbox の rclone 同期](dropbox-rclone.md) | [手順書](../dropbox-rclone.md) |

## 端末とファイル操作

| 検証記録 | 操作する手順書 |
|---|---|
| [WezTerm Nightly](wezterm-nightly.md) | [手順書](../wezterm-nightly.md) |
| [HackGen Console NF](hackgen.md) | [手順書](../hackgen.md) |
| [yazi](yazi.md) | [手順書](../yazi.md) |
| [gdu](gdu.md) | [手順書](../gdu.md) |
| [btop](btop.md) | [手順書](../btop.md) |

## エディタと Git

| 検証記録 | 操作する手順書 |
|---|---|
| [Neovim](neovim.md) | [手順書](../neovim.md) |
| [VS Code](vscode.md) | [手順書](../vscode.md) |
| [Git](git.md) | [手順書](../git.md) |
| [git-delta](git-delta.md) | [手順書](../git-delta.md) |
| [GitHub CLI](gh.md) | [手順書](../gh.md) |
| [lazygit](lazygit.md) | [手順書](../lazygit.md) |

## AI と開発ツール

| 検証記録 | 操作する手順書 |
|---|---|
| [Claude Code](claude-code.md) | [手順書](../claude-code.md) |
| [Codex CLI](codex.md) | [手順書](../codex.md) |
| [Claude Code から GNOME の GUI を操作](claude-code-gui.md) | [手順書](../claude-code-gui.md) |
| [Windows の Claude Code Remote Control](windows-claude-remote-control.md) | [手順書](../windows-claude-remote-control.md) |
| [ShellCheck / shfmt](shellcheck.md) | [手順書](../shellcheck.md) |

## コンテナと仮想化

| 検証記録 | 操作する手順書 |
|---|---|
| [Podman](podman.md) | [手順書](../podman.md) |
| [distrobox](distrobox.md) | [手順書](../distrobox.md) |
| [podman-compose](podman-compose.md) | [手順書](../podman-compose.md) |
| [podman-tui](podman-tui.md) | [手順書](../podman-tui.md) |
| [lazydocker](lazydocker.md) | [手順書](../lazydocker.md) |
| [hadolint / dive / Trivy](image-tools.md) | [手順書](../image-tools.md) |
| [VirtualBox](virtualbox.md) | [手順書](../virtualbox.md) |
| [bootc ゲストの VirtualBox Guest Additions](virtualbox-guest-bootc.md) | [手順書](../virtualbox-guest-bootc.md) |

## ブラウザと通信制約

| 検証記録 | 操作する手順書 |
|---|---|
| [Firefox](firefox.md) | [手順書](../firefox.md) |
| [インターネットに出られないホストの Homebrew](homebrew-offline.md) | [手順書](../homebrew-offline.md) |
| [インターネットに出られないホストの npm](npm-offline.md) | [手順書](../npm-offline.md) |

## 導入元の調査

- [CLI / GUI ツール導入元一覧の調査・検証記録](tool-catalog.md)（[一覧](../tool-catalog.md)）
