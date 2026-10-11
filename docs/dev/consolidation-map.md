# 手順の集約対応

Windows・AlmaLinux の実施手順の正本は2冊のセットアップ。旧文書には見出しと移動先の案内を残す。検証・参考資料・ロールバックの記録は元の場所に保持する。

- setup-notes の移動元: `ae1981a48fee0e26540d82224d4c195492bae782`
- 過去の検証の手順番号は当時のもの。次の対応表で現在の節を確認する
- 既存の設定内の識別印・バックアップ名・ツールの実装は変更しない
- 集約時の静的検査・回帰検査は [検証記録](../verification/consolidation.md) に記録する

## 移動元の基準

| リポジトリ | ブランチ | コミット |
| --- | --- | --- |
| setup-notes | main | `ae1981a48fee0e26540d82224d4c195492bae782` |
| bash | main | `67abb84ed5601b242870841ff1da381388f5427a` |
| wezterm | main | `ad61b5e494ecad1bf8b8e71f3ba547bbbe23b611` |
| LazyVimStarter | custom | `8e4a0741d055561121ee3710ca48371e1b72e3df` |
| lazygit | custom | `02c6326a7b81552a4603c67dea1f10a412d6b332` |
| yazi | custom | `1cfe3492fc577e71d53678e772ad0c914625ca54` |
| kvm-container | main | `d71c65c9f64fc2a4b550933f689b85c1ceaa5f9c` |
| md-table-excel | main | `6f049421dc41132604f13546caca6362d85daad4` |

## 旧見出しと現在の節

| リポジトリ | 移動元・旧見出し | 移動先 |
| --- | --- | --- |
| setup-notes | [docs/btop.md: 実施手順](../btop.md#実施手順) | [AlmaLinux 10: btop: 実施手順](../almalinux-setup.md#btop-実施手順) |
| setup-notes | [docs/btop.md: 設定ファイル](../btop.md#設定ファイル) | [AlmaLinux 10: btop: 設定ファイル](../almalinux-setup.md#btop-設定ファイル) |
| setup-notes | [docs/btop.md: 更新](../btop.md#更新) | [AlmaLinux 10: btop: 更新](../almalinux-setup.md#btop-更新) |
| setup-notes | [docs/btop.md: btop インストール手順（AlmaLinux 10 / EPEL）](../btop.md#btop-インストール手順almalinux-10--epel) | [AlmaLinux 10: btop: 実施手順](../almalinux-setup.md#btop-実施手順) |
| setup-notes | [docs/claude-code-gui.md: 実施手順](../claude-code-gui.md#実施手順) | [AlmaLinux 10: Claude Code の GNOME 操作: 実施手順](../almalinux-setup.md#claude-code-の-gnome-操作-実施手順) |
| setup-notes | [docs/claude-code-gui.md: 使い方の基本](../claude-code-gui.md#使い方の基本) | [AlmaLinux 10: Claude Code の GNOME 操作: 使い方の基本](../almalinux-setup.md#claude-code-の-gnome-操作-使い方の基本) |
| setup-notes | [docs/claude-code-gui.md: 仮想モニターの大きさを変える（任意）](../claude-code-gui.md#仮想モニターの大きさを変える任意) | [AlmaLinux 10: Claude Code の GNOME 操作: 仮想モニターの大きさを変える（任意）](../almalinux-setup.md#claude-code-の-gnome-操作-仮想モニターの大きさを変える任意) |
| setup-notes | [docs/claude-code-gui.md: Claude Code から GNOME の GUI を撮って操作する手順（ヘッドレスのセッション）](../claude-code-gui.md#claude-code-から-gnome-の-gui-を撮って操作する手順ヘッドレスのセッション) | [AlmaLinux 10: Claude Code の GNOME 操作: 実施手順](../almalinux-setup.md#claude-code-の-gnome-操作-実施手順) |
| setup-notes | [docs/coding-agents.md: 実施手順](../coding-agents.md#実施手順) | [AlmaLinux 10: コーディングエージェントの共同作業: 実施手順](../almalinux-setup.md#コーディングエージェントの共同作業-実施手順) |
| setup-notes | [docs/coding-agents.md: 使い方の基本](../coding-agents.md#使い方の基本) | [AlmaLinux 10: コーディングエージェントの共同作業: 使い方の基本](../almalinux-setup.md#コーディングエージェントの共同作業-使い方の基本) |
| setup-notes | [docs/coding-agents.md: 分担して作業する](../coding-agents.md#分担して作業する) | [AlmaLinux 10: コーディングエージェントの共同作業: 分担して作業する](../almalinux-setup.md#コーディングエージェントの共同作業-分担して作業する) |
| setup-notes | [docs/coding-agents.md: 相互にレビューする](../coding-agents.md#相互にレビューする) | [AlmaLinux 10: コーディングエージェントの共同作業: 相互にレビューする](../almalinux-setup.md#コーディングエージェントの共同作業-相互にレビューする) |
| setup-notes | [docs/coding-agents.md: main に取り込む](../coding-agents.md#main-に取り込む) | [AlmaLinux 10: コーディングエージェントの共同作業: main に取り込む](../almalinux-setup.md#コーディングエージェントの共同作業-main-に取り込む) |
| setup-notes | [docs/coding-agents.md: スマートフォンから指示する](../coding-agents.md#スマートフォンから指示する) | [AlmaLinux 10: コーディングエージェントの共同作業: スマートフォンから指示する](../almalinux-setup.md#コーディングエージェントの共同作業-スマートフォンから指示する) |
| setup-notes | [docs/coding-agents.md: 更新](../coding-agents.md#更新) | [AlmaLinux 10: コーディングエージェントの共同作業: 更新](../almalinux-setup.md#コーディングエージェントの共同作業-更新) |
| setup-notes | [docs/coding-agents.md: Windows 11 で使う](../coding-agents.md#windows-11-で使う) | [Windows 11: コーディングエージェントの共同作業: Windows 11 で使う](../windows-setup.md#コーディングエージェントの共同作業-windows-11-で使う) |
| setup-notes | [docs/coding-agents.md: Windows 11 の更新](../coding-agents.md#windows-11-の更新) | [Windows 11: コーディングエージェントの共同作業: Windows 11 の更新](../windows-setup.md#コーディングエージェントの共同作業-windows-11-の更新) |
| setup-notes | [docs/coding-agents.md: Claude Code・Codex・Grok Build を 1 つのプロジェクトで共同作業させる（AlmaLinux 10・Windows 11）](../coding-agents.md#claude-codecodexgrok-build-を-1-つのプロジェクトで共同作業させるalmalinux-10windows-11) | [AlmaLinux 10: コーディングエージェントの共同作業: 実施手順](../almalinux-setup.md#コーディングエージェントの共同作業-実施手順) |
| setup-notes | [docs/distrobox.md: 実施手順](../distrobox.md#実施手順) | [AlmaLinux 10: Distrobox: 実施手順](../almalinux-setup.md#distrobox-実施手順) |
| setup-notes | [docs/distrobox.md: ボックスのコマンドをホストから呼ぶ（任意）](../distrobox.md#ボックスのコマンドをホストから呼ぶ任意) | [AlmaLinux 10: Distrobox: ボックスのコマンドをホストから呼ぶ（任意）](../almalinux-setup.md#distrobox-ボックスのコマンドをホストから呼ぶ任意) |
| setup-notes | [docs/distrobox.md: 更新](../distrobox.md#更新) | [AlmaLinux 10: Distrobox: 更新](../almalinux-setup.md#distrobox-更新) |
| setup-notes | [docs/distrobox.md: distrobox インストール手順（AlmaLinux 10 / EPEL）](../distrobox.md#distrobox-インストール手順almalinux-10--epel) | [AlmaLinux 10: Distrobox: 実施手順](../almalinux-setup.md#distrobox-実施手順) |
| setup-notes | [docs/dropbox-rclone.md: 実施手順](../dropbox-rclone.md#実施手順) | [AlmaLinux 10: Dropbox と rclone: 実施手順](../almalinux-setup.md#dropbox-と-rclone-実施手順) |
| setup-notes | [docs/dropbox-rclone.md: 使い方の基本](../dropbox-rclone.md#使い方の基本) | [AlmaLinux 10: Dropbox と rclone: 使い方の基本](../almalinux-setup.md#dropbox-と-rclone-使い方の基本) |
| setup-notes | [docs/dropbox-rclone.md: 同期するフォルダを変える（任意）](../dropbox-rclone.md#同期するフォルダを変える任意) | [AlmaLinux 10: Dropbox と rclone: 同期するフォルダを変える（任意）](../almalinux-setup.md#dropbox-と-rclone-同期するフォルダを変える任意) |
| setup-notes | [docs/dropbox-rclone.md: 更新](../dropbox-rclone.md#更新) | [AlmaLinux 10: Dropbox と rclone: 更新](../almalinux-setup.md#dropbox-と-rclone-更新) |
| setup-notes | [docs/dropbox-rclone.md: Dropbox を rclone で同期する手順（AlmaLinux 10 / Raspberry Pi 5 / Homebrew + systemd ユーザータイマー）](../dropbox-rclone.md#dropbox-を-rclone-で同期する手順almalinux-10--raspberry-pi-5--homebrew--systemd-ユーザータイマー) | [AlmaLinux 10: Dropbox と rclone: 実施手順](../almalinux-setup.md#dropbox-と-rclone-実施手順) |
| setup-notes | [docs/dropbox.md: 実施手順](../dropbox.md#実施手順) | [AlmaLinux 10: Dropbox: 実施手順](../almalinux-setup.md#dropbox-実施手順) |
| setup-notes | [docs/dropbox.md: 使い方の基本](../dropbox.md#使い方の基本) | [AlmaLinux 10: Dropbox: 使い方の基本](../almalinux-setup.md#dropbox-使い方の基本) |
| setup-notes | [docs/dropbox.md: 更新](../dropbox.md#更新) | [AlmaLinux 10: Dropbox: 更新](../almalinux-setup.md#dropbox-更新) |
| setup-notes | [docs/dropbox.md: Dropbox 公式クライアント導入手順（AlmaLinux 10 / x86_64 / headless + systemd ユーザーサービス）](../dropbox.md#dropbox-公式クライアント導入手順almalinux-10--x86_64--headless--systemd-ユーザーサービス) | [AlmaLinux 10: Dropbox: 実施手順](../almalinux-setup.md#dropbox-実施手順) |
| setup-notes | [docs/forgejo.md: 実施手順](../forgejo.md#実施手順) | [AlmaLinux 10: Forgejo: 実施手順](../almalinux-setup.md#forgejo-実施手順) |
| setup-notes | [docs/forgejo.md: イメージを取得して localhost で起動する](../forgejo.md#イメージを取得して-localhost-で起動する) | [AlmaLinux 10: Forgejo: イメージを取得して localhost で起動する](../almalinux-setup.md#forgejo-イメージを取得して-localhost-で起動する) |
| setup-notes | [docs/forgejo.md: 初期設定と管理者の作成](../forgejo.md#初期設定と管理者の作成) | [AlmaLinux 10: Forgejo: 初期設定と管理者の作成](../almalinux-setup.md#forgejo-初期設定と管理者の作成) |
| setup-notes | [docs/forgejo.md: LAN に公開する](../forgejo.md#lan-に公開する) | [AlmaLinux 10: Forgejo: LAN に公開する](../almalinux-setup.md#forgejo-lan-に公開する) |
| setup-notes | [docs/forgejo.md: Git の接続を確かめる](../forgejo.md#git-の接続を確かめる) | [AlmaLinux 10: Forgejo: Git の接続を確かめる](../almalinux-setup.md#forgejo-git-の接続を確かめる) |
| setup-notes | [docs/forgejo.md: 再起動しても残ることを確かめる](../forgejo.md#再起動しても残ることを確かめる) | [AlmaLinux 10: Forgejo: 再起動しても残ることを確かめる](../almalinux-setup.md#forgejo-再起動しても残ることを確かめる) |
| setup-notes | [docs/forgejo.md: 自動更新を有効にする](../forgejo.md#自動更新を有効にする) | [AlmaLinux 10: Forgejo: 自動更新を有効にする](../almalinux-setup.md#forgejo-自動更新を有効にする) |
| setup-notes | [docs/forgejo.md: 使い方の基本](../forgejo.md#使い方の基本) | [AlmaLinux 10: Forgejo: 使い方の基本](../almalinux-setup.md#forgejo-使い方の基本) |
| setup-notes | [docs/forgejo.md: 設定ファイル](../forgejo.md#設定ファイル) | [AlmaLinux 10: Forgejo: 設定ファイル](../almalinux-setup.md#forgejo-設定ファイル) |
| setup-notes | [docs/forgejo.md: バックアップ](../forgejo.md#バックアップ) | [AlmaLinux 10: Forgejo: バックアップ](../almalinux-setup.md#forgejo-バックアップ) |
| setup-notes | [docs/forgejo.md: バックアップから復元する](../forgejo.md#バックアップから復元する) | [AlmaLinux 10: Forgejo: バックアップから復元する](../almalinux-setup.md#forgejo-バックアップから復元する) |
| setup-notes | [docs/forgejo.md: 更新](../forgejo.md#更新) | [AlmaLinux 10: Forgejo: 更新](../almalinux-setup.md#forgejo-更新) |
| setup-notes | [docs/forgejo.md: Forgejo 構築手順（AlmaLinux 10 / rootless Podman + Quadlet / LAN・VPN 内で使う）](../forgejo.md#forgejo-構築手順almalinux-10--rootless-podman--quadlet--lanvpn-内で使う) | [AlmaLinux 10: Forgejo: 実施手順](../almalinux-setup.md#forgejo-実施手順) |
| setup-notes | [docs/gdu.md: 実施手順](../gdu.md#実施手順) | [AlmaLinux 10: gdu: 実施手順](../almalinux-setup.md#gdu-実施手順) |
| setup-notes | [docs/gdu.md: gdu の名前で呼ぶ（任意）](../gdu.md#gdu-の名前で呼ぶ任意) | [AlmaLinux 10: gdu: gdu の名前で呼ぶ（任意）](../almalinux-setup.md#gdu-gdu-の名前で呼ぶ任意) |
| setup-notes | [docs/gdu.md: 更新](../gdu.md#更新) | [AlmaLinux 10: gdu: 更新](../almalinux-setup.md#gdu-更新) |
| setup-notes | [docs/gdu.md: gdu インストール手順（AlmaLinux 10 / Homebrew）](../gdu.md#gdu-インストール手順almalinux-10--homebrew) | [AlmaLinux 10: gdu: 実施手順](../almalinux-setup.md#gdu-実施手順) |
| setup-notes | [docs/gnome-desktop-sharing.md: 実施手順](../gnome-desktop-sharing.md#実施手順) | [AlmaLinux 10: GNOME のデスクトップ共有: 実施手順](../almalinux-setup.md#gnome-のデスクトップ共有-実施手順) |
| setup-notes | [docs/gnome-desktop-sharing.md: 前提を確かめる](../gnome-desktop-sharing.md#前提を確かめる) | [AlmaLinux 10: GNOME のデスクトップ共有: 前提を確かめる](../almalinux-setup.md#gnome-のデスクトップ共有-前提を確かめる) |
| setup-notes | [docs/gnome-desktop-sharing.md: RDP を設定する](../gnome-desktop-sharing.md#rdp-を設定する) | [AlmaLinux 10: GNOME のデスクトップ共有: RDP を設定する](../almalinux-setup.md#gnome-のデスクトップ共有-rdp-を設定する) |
| setup-notes | [docs/gnome-desktop-sharing.md: 自動ログインにして再起動する](../gnome-desktop-sharing.md#自動ログインにして再起動する) | [AlmaLinux 10: GNOME のデスクトップ共有: 自動ログインにして再起動する](../almalinux-setup.md#gnome-のデスクトップ共有-自動ログインにして再起動する) |
| setup-notes | [docs/gnome-desktop-sharing.md: 再起動の後に確かめてつなぐ](../gnome-desktop-sharing.md#再起動の後に確かめてつなぐ) | [AlmaLinux 10: GNOME のデスクトップ共有: 再起動の後に確かめてつなぐ](../almalinux-setup.md#gnome-のデスクトップ共有-再起動の後に確かめてつなぐ) |
| setup-notes | [docs/gnome-desktop-sharing.md: 見るだけにする（任意）](../gnome-desktop-sharing.md#見るだけにする任意) | [AlmaLinux 10: GNOME のデスクトップ共有: 見るだけにする（任意）](../almalinux-setup.md#gnome-のデスクトップ共有-見るだけにする任意) |
| setup-notes | [docs/gnome-desktop-sharing.md: 接続元を LAN に絞る（任意）](../gnome-desktop-sharing.md#接続元を-lan-に絞る任意) | [AlmaLinux 10: GNOME のデスクトップ共有: 接続元を LAN に絞る（任意）](../almalinux-setup.md#gnome-のデスクトップ共有-接続元を-lan-に絞る任意) |
| setup-notes | [docs/gnome-desktop-sharing.md: つながらなくなったとき](../gnome-desktop-sharing.md#つながらなくなったとき) | [AlmaLinux 10: GNOME のデスクトップ共有: つながらなくなったとき](../almalinux-setup.md#gnome-のデスクトップ共有-つながらなくなったとき) |
| setup-notes | [docs/gnome-desktop-sharing.md: GNOME のデスクトップ共有の手順（PC の画面のデスクトップに、遠隔から RDP でつなぐ。PC の画面を触らずに CLI だけで設定する）](../gnome-desktop-sharing.md#gnome-のデスクトップ共有の手順pc-の画面のデスクトップに遠隔から-rdp-でつなぐpc-の画面を触らずに-cli-だけで設定する) | [AlmaLinux 10: GNOME のデスクトップ共有: 実施手順](../almalinux-setup.md#gnome-のデスクトップ共有-実施手順) |
| setup-notes | [docs/gnome-headless-session.md: 実施手順](../gnome-headless-session.md#実施手順) | [AlmaLinux 10: GNOME のヘッドレスセッション: 実施手順](../almalinux-setup.md#gnome-のヘッドレスセッション-実施手順) |
| setup-notes | [docs/gnome-headless-session.md: 接続元を LAN に絞る（任意）](../gnome-headless-session.md#接続元を-lan-に絞る任意) | [AlmaLinux 10: GNOME のヘッドレスセッション: 接続元を LAN に絞る（任意）](../almalinux-setup.md#gnome-のヘッドレスセッション-接続元を-lan-に絞る任意) |
| setup-notes | [docs/gnome-headless-session.md: リモートログインだけにする（併用をやめる）](../gnome-headless-session.md#リモートログインだけにする併用をやめる) | [AlmaLinux 10: GNOME のヘッドレスセッション: リモートログインだけにする（併用をやめる）](../almalinux-setup.md#gnome-のヘッドレスセッション-リモートログインだけにする併用をやめる) |
| setup-notes | [docs/gnome-headless-session.md: GNOME のヘッドレスのセッションの手順（モニターの無い PC のデスクトップに RDP でつなぐ）](../gnome-headless-session.md#gnome-のヘッドレスのセッションの手順モニターの無い-pc-のデスクトップに-rdp-でつなぐ) | [AlmaLinux 10: GNOME のヘッドレスセッション: 実施手順](../almalinux-setup.md#gnome-のヘッドレスセッション-実施手順) |
| setup-notes | [docs/gnome-remote-desktop.md: 実施手順](../gnome-remote-desktop.md#実施手順) | [AlmaLinux 10: GNOME のリモートログイン: 実施手順](../almalinux-setup.md#gnome-のリモートログイン-実施手順) |
| setup-notes | [docs/gnome-remote-desktop.md: 接続元を LAN に絞る（任意）](../gnome-remote-desktop.md#接続元を-lan-に絞る任意) | [AlmaLinux 10: GNOME のリモートログイン: 接続元を LAN に絞る（任意）](../almalinux-setup.md#gnome-のリモートログイン-接続元を-lan-に絞る任意) |
| setup-notes | [docs/gnome-remote-desktop.md: 設定済みのサーバーで GDM の後に起動させる](../gnome-remote-desktop.md#設定済みのサーバーで-gdm-の後に起動させる) | [AlmaLinux 10: GNOME のリモートログイン: 設定済みのサーバーで GDM の後に起動させる](../almalinux-setup.md#gnome-のリモートログイン-設定済みのサーバーで-gdm-の後に起動させる) |
| setup-notes | [docs/gnome-remote-desktop.md: GNOME Remote Desktop 有効化手順（リモートログイン方式）](../gnome-remote-desktop.md#gnome-remote-desktop-有効化手順リモートログイン方式) | [AlmaLinux 10: GNOME のリモートログイン: 実施手順](../almalinux-setup.md#gnome-のリモートログイン-実施手順) |
| setup-notes | [docs/grok-build-remote.md: 実施手順](../grok-build-remote.md#実施手順) | [AlmaLinux 10: Grok Build のブラウザ操作: 実施手順](../almalinux-setup.md#grok-build-のブラウザ操作-実施手順) |
| setup-notes | [docs/grok-build-remote.md: Codeg のサーバーを入れて localhost で起動する](../grok-build-remote.md#codeg-のサーバーを入れて-localhost-で起動する) | [AlmaLinux 10: Grok Build のブラウザ操作: Codeg のサーバーを入れて localhost で起動する](../almalinux-setup.md#grok-build-のブラウザ操作-codeg-のサーバーを入れて-localhost-で起動する) |
| setup-notes | [docs/grok-build-remote.md: ブラウザで開いて Grok を動かす](../grok-build-remote.md#ブラウザで開いて-grok-を動かす) | [AlmaLinux 10: Grok Build のブラウザ操作: ブラウザで開いて Grok を動かす](../almalinux-setup.md#grok-build-のブラウザ操作-ブラウザで開いて-grok-を動かす) |
| setup-notes | [docs/grok-build-remote.md: HTTPS で LAN・VPN に公開する](../grok-build-remote.md#https-で-lanvpn-に公開する) | [AlmaLinux 10: Grok Build のブラウザ操作: HTTPS で LAN・VPN に公開する](../almalinux-setup.md#grok-build-のブラウザ操作-https-で-lanvpn-に公開する) |
| setup-notes | [docs/grok-build-remote.md: 端末にルート証明書を入れる](../grok-build-remote.md#端末にルート証明書を入れる) | [AlmaLinux 10: Grok Build のブラウザ操作: 端末にルート証明書を入れる](../almalinux-setup.md#grok-build-のブラウザ操作-端末にルート証明書を入れる) |
| setup-notes | [docs/grok-build-remote.md: 使い方の基本](../grok-build-remote.md#使い方の基本) | [AlmaLinux 10: Grok Build のブラウザ操作: 使い方の基本](../almalinux-setup.md#grok-build-のブラウザ操作-使い方の基本) |
| setup-notes | [docs/grok-build-remote.md: 端末の grok のセッションを取り込む](../grok-build-remote.md#端末の-grok-のセッションを取り込む) | [AlmaLinux 10: Grok Build のブラウザ操作: 端末の grok のセッションを取り込む](../almalinux-setup.md#grok-build-のブラウザ操作-端末の-grok-のセッションを取り込む) |
| setup-notes | [docs/grok-build-remote.md: 設定ファイル](../grok-build-remote.md#設定ファイル) | [AlmaLinux 10: Grok Build のブラウザ操作: 設定ファイル](../almalinux-setup.md#grok-build-のブラウザ操作-設定ファイル) |
| setup-notes | [docs/grok-build-remote.md: 更新](../grok-build-remote.md#更新) | [AlmaLinux 10: Grok Build のブラウザ操作: 更新](../almalinux-setup.md#grok-build-のブラウザ操作-更新) |
| setup-notes | [docs/grok-build-remote.md: Windows 11 で使う](../grok-build-remote.md#windows-11-で使う) | [Windows 11: Grok Build のブラウザ操作: Windows 11 で使う](../windows-setup.md#grok-build-のブラウザ操作-windows-11-で使う) |
| setup-notes | [docs/grok-build-remote.md: Windows 11 で Codeg のサーバーを入れて起動する](../grok-build-remote.md#windows-11-で-codeg-のサーバーを入れて起動する) | [Windows 11: Grok Build のブラウザ操作: Windows 11 で Codeg のサーバーを入れて起動する](../windows-setup.md#grok-build-のブラウザ操作-windows-11-で-codeg-のサーバーを入れて起動する) |
| setup-notes | [docs/grok-build-remote.md: Windows 11 で HTTPS で LAN・VPN に公開する](../grok-build-remote.md#windows-11-で-https-で-lanvpn-に公開する) | [Windows 11: Grok Build のブラウザ操作: Windows 11 で HTTPS で LAN・VPN に公開する](../windows-setup.md#grok-build-のブラウザ操作-windows-11-で-https-で-lanvpn-に公開する) |
| setup-notes | [docs/grok-build-remote.md: Windows 11 の既存のタスクを非表示起動に切り替える](../grok-build-remote.md#windows-11-の既存のタスクを非表示起動に切り替える) | [Windows 11: Grok Build のブラウザ操作: Windows 11 の既存のタスクを非表示起動に切り替える](../windows-setup.md#grok-build-のブラウザ操作-windows-11-の既存のタスクを非表示起動に切り替える) |
| setup-notes | [docs/grok-build-remote.md: Windows 11 で止める・もう一度始める](../grok-build-remote.md#windows-11-で止めるもう一度始める) | [Windows 11: Grok Build のブラウザ操作: Windows 11 で止める・もう一度始める](../windows-setup.md#grok-build-のブラウザ操作-windows-11-で止めるもう一度始める) |
| setup-notes | [docs/grok-build-remote.md: Windows 11 の更新](../grok-build-remote.md#windows-11-の更新) | [Windows 11: Grok Build のブラウザ操作: Windows 11 の更新](../windows-setup.md#grok-build-のブラウザ操作-windows-11-の更新) |
| setup-notes | [docs/grok-build-remote.md: Grok Build をブラウザから操作する手順（Codeg と Caddy / AlmaLinux 10 は systemd のユーザーサービス / Windows 11 はタスク スケジューラ / LAN・VPN 内で HTTPS で使う）](../grok-build-remote.md#grok-build-をブラウザから操作する手順codeg-と-caddy--almalinux-10-は-systemd-のユーザーサービス--windows-11-はタスク-スケジューラ--lanvpn-内で-https-で使う) | [AlmaLinux 10: Grok Build のブラウザ操作: 実施手順](../almalinux-setup.md#grok-build-のブラウザ操作-実施手順) |
| setup-notes | [docs/homebrew-offline.md: 実施手順](../homebrew-offline.md#実施手順) | [AlmaLinux 10: Homebrew のオフライン導入: 実施手順](../almalinux-setup.md#homebrew-のオフライン導入-実施手順) |
| setup-notes | [docs/homebrew-offline.md: 更新](../homebrew-offline.md#更新) | [AlmaLinux 10: Homebrew のオフライン導入: 更新](../almalinux-setup.md#homebrew-のオフライン導入-更新) |
| setup-notes | [docs/homebrew-offline.md: Homebrew をインターネットに出られないホストで使う手順（AlmaLinux 10 / ssh -R の SOCKS プロキシ）](../homebrew-offline.md#homebrew-をインターネットに出られないホストで使う手順almalinux-10--ssh--r-の-socks-プロキシ) | [AlmaLinux 10: Homebrew のオフライン導入: 実施手順](../almalinux-setup.md#homebrew-のオフライン導入-実施手順) |
| setup-notes | [docs/hyper-v.md: 実施手順](../hyper-v.md#実施手順) | [Windows 11: Hyper-V: 実施手順](../windows-setup.md#hyper-v-実施手順) |
| setup-notes | [docs/hyper-v.md: この PC で使えるかを確かめる](../hyper-v.md#この-pc-で使えるかを確かめる) | [Windows 11: Hyper-V: この PC で使えるかを確かめる](../windows-setup.md#hyper-v-この-pc-で使えるかを確かめる) |
| setup-notes | [docs/hyper-v.md: Hyper-V を有効にして再起動する](../hyper-v.md#hyper-v-を有効にして再起動する) | [Windows 11: Hyper-V: Hyper-V を有効にして再起動する](../windows-setup.md#hyper-v-hyper-v-を有効にして再起動する) |
| setup-notes | [docs/hyper-v.md: 再起動の後に確かめる](../hyper-v.md#再起動の後に確かめる) | [Windows 11: Hyper-V: 再起動の後に確かめる](../windows-setup.md#hyper-v-再起動の後に確かめる) |
| setup-notes | [docs/hyper-v.md: VM を作る](../hyper-v.md#vm-を作る) | [Windows 11: Hyper-V: VM を作る](../windows-setup.md#hyper-v-vm-を作る) |
| setup-notes | [docs/hyper-v.md: VM を起動して OS を入れる](../hyper-v.md#vm-を起動して-os-を入れる) | [Windows 11: Hyper-V: VM を起動して OS を入れる](../windows-setup.md#hyper-v-vm-を起動して-os-を入れる) |
| setup-notes | [docs/hyper-v.md: 動作を確かめる](../hyper-v.md#動作を確かめる) | [Windows 11: Hyper-V: 動作を確かめる](../windows-setup.md#hyper-v-動作を確かめる) |
| setup-notes | [docs/hyper-v.md: 使い方の基本](../hyper-v.md#使い方の基本) | [Windows 11: Hyper-V: 使い方の基本](../windows-setup.md#hyper-v-使い方の基本) |
| setup-notes | [docs/hyper-v.md: チェックポイントとクローン](../hyper-v.md#チェックポイントとクローン) | [Windows 11: Hyper-V: チェックポイントとクローン](../windows-setup.md#hyper-v-チェックポイントとクローン) |
| setup-notes | [docs/hyper-v.md: VM どうしだけがつながるスイッチを作る（任意）](../hyper-v.md#vm-どうしだけがつながるスイッチを作る任意) | [Windows 11: Hyper-V: VM どうしだけがつながるスイッチを作る（任意）](../windows-setup.md#hyper-v-vm-どうしだけがつながるスイッチを作る任意) |
| setup-notes | [docs/hyper-v.md: VM を消す](../hyper-v.md#vm-を消す) | [Windows 11: Hyper-V: VM を消す](../windows-setup.md#hyper-v-vm-を消す) |
| setup-notes | [docs/hyper-v.md: Hyper-V の有効化と VM の作成（Windows 11 Pro）](../hyper-v.md#hyper-v-の有効化と-vm-の作成windows-11-pro) | [Windows 11: Hyper-V: 実施手順](../windows-setup.md#hyper-v-実施手順) |
| setup-notes | [docs/image-tools.md: 実施手順](../image-tools.md#実施手順) | [AlmaLinux 10: 画像の道具: 実施手順](../almalinux-setup.md#画像の道具-実施手順) |
| setup-notes | [docs/image-tools.md: 使い方の基本](../image-tools.md#使い方の基本) | [AlmaLinux 10: 画像の道具: 使い方の基本](../almalinux-setup.md#画像の道具-使い方の基本) |
| setup-notes | [docs/image-tools.md: 更新](../image-tools.md#更新) | [AlmaLinux 10: 画像の道具: 更新](../almalinux-setup.md#画像の道具-更新) |
| setup-notes | [docs/image-tools.md: hadolint / dive / Trivy インストール手順（AlmaLinux 10 / Homebrew + Trivy 公式 dnf リポジトリ）](../image-tools.md#hadolint--dive--trivy-インストール手順almalinux-10--homebrew--trivy-公式-dnf-リポジトリ) | [AlmaLinux 10: 画像の道具: 実施手順](../almalinux-setup.md#画像の道具-実施手順) |
| setup-notes | [docs/lazydocker.md: 実施手順](../lazydocker.md#実施手順) | [AlmaLinux 10: lazydocker: 実施手順](../almalinux-setup.md#lazydocker-実施手順) |
| setup-notes | [docs/lazydocker.md: podman exec でシェルを開く（任意）](../lazydocker.md#podman-exec-でシェルを開く任意) | [AlmaLinux 10: lazydocker: podman exec でシェルを開く（任意）](../almalinux-setup.md#lazydocker-podman-exec-でシェルを開く任意) |
| setup-notes | [docs/lazydocker.md: compose のプロジェクトを見る（任意）](../lazydocker.md#compose-のプロジェクトを見る任意) | [AlmaLinux 10: lazydocker: compose のプロジェクトを見る（任意）](../almalinux-setup.md#lazydocker-compose-のプロジェクトを見る任意) |
| setup-notes | [docs/lazydocker.md: root でも使う（任意）](../lazydocker.md#root-でも使う任意) | [AlmaLinux 10: lazydocker: root でも使う（任意）](../almalinux-setup.md#lazydocker-root-でも使う任意) |
| setup-notes | [docs/lazydocker.md: 使い方の基本](../lazydocker.md#使い方の基本) | [AlmaLinux 10: lazydocker: 使い方の基本](../almalinux-setup.md#lazydocker-使い方の基本) |
| setup-notes | [docs/lazydocker.md: 更新](../lazydocker.md#更新) | [AlmaLinux 10: lazydocker: 更新](../almalinux-setup.md#lazydocker-更新) |
| setup-notes | [docs/lazydocker.md: lazydocker インストール手順（AlmaLinux 10 / Homebrew）](../lazydocker.md#lazydocker-インストール手順almalinux-10--homebrew) | [AlmaLinux 10: lazydocker: 実施手順](../almalinux-setup.md#lazydocker-実施手順) |
| setup-notes | [docs/linger.md: 実施手順](../linger.md#実施手順) | [AlmaLinux 10: ユーザーサービスの常駐: 実施手順](../almalinux-setup.md#ユーザーサービスの常駐-実施手順) |
| setup-notes | [docs/linger.md: linger 有効化手順（AlmaLinux 10 / ログアウト中も自分のユーザーの systemd を動かす）](../linger.md#linger-有効化手順almalinux-10--ログアウト中も自分のユーザーの-systemd-を動かす) | [AlmaLinux 10: ユーザーサービスの常駐: 実施手順](../almalinux-setup.md#ユーザーサービスの常駐-実施手順) |
| setup-notes | [docs/npm-offline.md: 実施手順](../npm-offline.md#実施手順) | [AlmaLinux 10: npm のオフライン導入: 実施手順](../almalinux-setup.md#npm-のオフライン導入-実施手順) |
| setup-notes | [docs/npm-offline.md: 更新](../npm-offline.md#更新) | [AlmaLinux 10: npm のオフライン導入: 更新](../almalinux-setup.md#npm-のオフライン導入-更新) |
| setup-notes | [docs/npm-offline.md: npm をインターネットに出られないホストで使う手順（AlmaLinux 10 / AppStream の Node.js / Neovim の Mason）](../npm-offline.md#npm-をインターネットに出られないホストで使う手順almalinux-10--appstream-の-nodejs--neovim-の-mason) | [AlmaLinux 10: npm のオフライン導入: 実施手順](../almalinux-setup.md#npm-のオフライン導入-実施手順) |
| setup-notes | [docs/podman-compose.md: 実施手順](../podman-compose.md#実施手順) | [AlmaLinux 10: podman-compose: 実施手順](../almalinux-setup.md#podman-compose-実施手順) |
| setup-notes | [docs/podman-compose.md: 使い方の基本](../podman-compose.md#使い方の基本) | [AlmaLinux 10: podman-compose: 使い方の基本](../almalinux-setup.md#podman-compose-使い方の基本) |
| setup-notes | [docs/podman-compose.md: 更新](../podman-compose.md#更新) | [AlmaLinux 10: podman-compose: 更新](../almalinux-setup.md#podman-compose-更新) |
| setup-notes | [docs/podman-compose.md: podman-compose インストール手順（AlmaLinux 10 / EPEL）](../podman-compose.md#podman-compose-インストール手順almalinux-10--epel) | [AlmaLinux 10: podman-compose: 実施手順](../almalinux-setup.md#podman-compose-実施手順) |
| setup-notes | [docs/podman-tui.md: 実施手順](../podman-tui.md#実施手順) | [AlmaLinux 10: podman-tui: 実施手順](../almalinux-setup.md#podman-tui-実施手順) |
| setup-notes | [docs/podman-tui.md: 使い方の基本](../podman-tui.md#使い方の基本) | [AlmaLinux 10: podman-tui: 使い方の基本](../almalinux-setup.md#podman-tui-使い方の基本) |
| setup-notes | [docs/podman-tui.md: 更新](../podman-tui.md#更新) | [AlmaLinux 10: podman-tui: 更新](../almalinux-setup.md#podman-tui-更新) |
| setup-notes | [docs/podman-tui.md: podman-tui インストール手順（AlmaLinux 10 / EPEL）](../podman-tui.md#podman-tui-インストール手順almalinux-10--epel) | [AlmaLinux 10: podman-tui: 実施手順](../almalinux-setup.md#podman-tui-実施手順) |
| setup-notes | [docs/podman.md: 実施手順](../podman.md#実施手順) | [AlmaLinux 10: Podman: 実施手順](../almalinux-setup.md#podman-実施手順) |
| setup-notes | [docs/podman.md: Docker 向けのツールから使う（任意）](../podman.md#docker-向けのツールから使う任意) | [AlmaLinux 10: Podman: Docker 向けのツールから使う（任意）](../almalinux-setup.md#podman-docker-向けのツールから使う任意) |
| setup-notes | [docs/podman.md: Quadlet で自動起動する（任意）](../podman.md#quadlet-で自動起動する任意) | [AlmaLinux 10: Podman: Quadlet で自動起動する（任意）](../almalinux-setup.md#podman-quadlet-で自動起動する任意) |
| setup-notes | [docs/podman.md: 使い方の基本](../podman.md#使い方の基本) | [AlmaLinux 10: Podman: 使い方の基本](../almalinux-setup.md#podman-使い方の基本) |
| setup-notes | [docs/podman.md: 更新](../podman.md#更新) | [AlmaLinux 10: Podman: 更新](../almalinux-setup.md#podman-更新) |
| setup-notes | [docs/podman.md: Podman インストール手順（AlmaLinux 10 / AppStream・rootless）](../podman.md#podman-インストール手順almalinux-10--appstreamrootless) | [AlmaLinux 10: Podman: 実施手順](../almalinux-setup.md#podman-実施手順) |
| setup-notes | [docs/samba-client.md: 実施手順](../samba-client.md#実施手順) | [AlmaLinux 10: Samba クライアント: 実施手順](../almalinux-setup.md#samba-クライアント-実施手順) |
| setup-notes | [docs/samba-client.md: GNOME Files で開く（任意）](../samba-client.md#gnome-files-で開く任意) | [AlmaLinux 10: Samba クライアント: GNOME Files で開く（任意）](../almalinux-setup.md#samba-クライアント-gnome-files-で開く任意) |
| setup-notes | [docs/samba-client.md: Windows 11 で使う](../samba-client.md#windows-11-で使う) | [Windows 11: Samba クライアント: Windows 11 で使う](../windows-setup.md#samba-クライアント-windows-11-で使う) |
| setup-notes | [docs/samba-client.md: Windows 11 の更新](../samba-client.md#windows-11-の更新) | [Windows 11: Samba クライアント: Windows 11 の更新](../windows-setup.md#samba-クライアント-windows-11-の更新) |
| setup-notes | [docs/samba-client.md: Samba の共有を AlmaLinux 10 と Windows 11 から使う手順（cifs-utils + fstab の自動マウント / GNOME Files / Windows のネットワーク ドライブ）](../samba-client.md#samba-の共有を-almalinux-10-と-windows-11-から使う手順cifs-utils--fstab-の自動マウント--gnome-files--windows-のネットワーク-ドライブ) | [AlmaLinux 10: Samba クライアント: 実施手順](../almalinux-setup.md#samba-クライアント-実施手順) |
| setup-notes | [docs/samba.md: 実施手順](../samba.md#実施手順) | [AlmaLinux 10: Samba サーバー: 実施手順](../almalinux-setup.md#samba-サーバー-実施手順) |
| setup-notes | [docs/samba.md: root のホームも公開する（任意）](../samba.md#root-のホームも公開する任意) | [AlmaLinux 10: Samba サーバー: root のホームも公開する（任意）](../almalinux-setup.md#samba-サーバー-root-のホームも公開する任意) |
| setup-notes | [docs/samba.md: /home も公開する（任意）](../samba.md#home-も公開する任意) | [AlmaLinux 10: Samba サーバー: /home も公開する（任意）](../almalinux-setup.md#samba-サーバー-home-も公開する任意) |
| setup-notes | [docs/samba.md: サーバーの上で動作を確かめる](../samba.md#サーバーの上で動作を確かめる) | [AlmaLinux 10: Samba サーバー: サーバーの上で動作を確かめる](../almalinux-setup.md#samba-サーバー-サーバーの上で動作を確かめる) |
| setup-notes | [docs/samba.md: 接続元を絞る（任意）](../samba.md#接続元を絞る任意) | [AlmaLinux 10: Samba サーバー: 接続元を絞る（任意）](../almalinux-setup.md#samba-サーバー-接続元を絞る任意) |
| setup-notes | [docs/samba.md: 設定済みのサーバーでディレクトリのリースを切る](../samba.md#設定済みのサーバーでディレクトリのリースを切る) | [AlmaLinux 10: Samba サーバー: 設定済みのサーバーでディレクトリのリースを切る](../almalinux-setup.md#samba-サーバー-設定済みのサーバーでディレクトリのリースを切る) |
| setup-notes | [docs/samba.md: Samba でホームディレクトリを公開する手順（`[homes]` 共有 / smbd + firewalld）](../samba.md#samba-でホームディレクトリを公開する手順homes-共有--smbd--firewalld) | [AlmaLinux 10: Samba サーバー: 実施手順](../almalinux-setup.md#samba-サーバー-実施手順) |
| setup-notes | [docs/secure-boot-mok.md: 実施手順](../secure-boot-mok.md#実施手順) | [AlmaLinux 10: Secure Boot の署名鍵: 実施手順](../almalinux-setup.md#secure-boot-の署名鍵-実施手順) |
| setup-notes | [docs/secure-boot-mok.md: Secure Boot の MOK 登録手順（AlmaLinux 10 / 自分でビルドするカーネルモジュールの署名鍵）](../secure-boot-mok.md#secure-boot-の-mok-登録手順almalinux-10--自分でビルドするカーネルモジュールの署名鍵) | [AlmaLinux 10: Secure Boot の署名鍵: 実施手順](../almalinux-setup.md#secure-boot-の署名鍵-実施手順) |
| setup-notes | [docs/shellcheck.md: 実施手順](../shellcheck.md#実施手順) | [AlmaLinux 10: ShellCheck と shfmt: 実施手順](../almalinux-setup.md#shellcheck-と-shfmt-実施手順) |
| setup-notes | [docs/shellcheck.md: shfmt で整形を確かめる（任意）](../shellcheck.md#shfmt-で整形を確かめる任意) | [AlmaLinux 10: ShellCheck と shfmt: shfmt で整形を確かめる（任意）](../almalinux-setup.md#shellcheck-と-shfmt-shfmt-で整形を確かめる任意) |
| setup-notes | [docs/shellcheck.md: 検査を調整する（任意）](../shellcheck.md#検査を調整する任意) | [AlmaLinux 10: ShellCheck と shfmt: 検査を調整する（任意）](../almalinux-setup.md#shellcheck-と-shfmt-検査を調整する任意) |
| setup-notes | [docs/shellcheck.md: 更新](../shellcheck.md#更新) | [AlmaLinux 10: ShellCheck と shfmt: 更新](../almalinux-setup.md#shellcheck-と-shfmt-更新) |
| setup-notes | [docs/shellcheck.md: ShellCheck / shfmt インストール手順（AlmaLinux 10 / Homebrew）](../shellcheck.md#shellcheck--shfmt-インストール手順almalinux-10--homebrew) | [AlmaLinux 10: ShellCheck と shfmt: 実施手順](../almalinux-setup.md#shellcheck-と-shfmt-実施手順) |
| setup-notes | [docs/ssh-socks-tunnel.md: 実施手順](../ssh-socks-tunnel.md#実施手順) | [AlmaLinux 10: SSH の SOCKS トンネル: 実施手順](../almalinux-setup.md#ssh-の-socks-トンネル-実施手順) |
| setup-notes | [docs/ssh-socks-tunnel.md: dnf にもトンネルを使わせる（任意）](../ssh-socks-tunnel.md#dnf-にもトンネルを使わせる任意) | [AlmaLinux 10: SSH の SOCKS トンネル: dnf にもトンネルを使わせる（任意）](../almalinux-setup.md#ssh-の-socks-トンネル-dnf-にもトンネルを使わせる任意) |
| setup-notes | [docs/ssh-socks-tunnel.md: トンネルを閉じる](../ssh-socks-tunnel.md#トンネルを閉じる) | [AlmaLinux 10: SSH の SOCKS トンネル: トンネルを閉じる](../almalinux-setup.md#ssh-の-socks-トンネル-トンネルを閉じる) |
| setup-notes | [docs/ssh-socks-tunnel.md: ssh の SOCKS トンネル手順（AlmaLinux 10 / インターネットに出られないホストから ssh -R で外に出る）](../ssh-socks-tunnel.md#ssh-の-socks-トンネル手順almalinux-10--インターネットに出られないホストから-ssh--r-で外に出る) | [AlmaLinux 10: SSH の SOCKS トンネル: 実施手順](../almalinux-setup.md#ssh-の-socks-トンネル-実施手順) |
| setup-notes | [docs/syncthing.md: 実施手順](../syncthing.md#実施手順) | [AlmaLinux 10: Syncthing: 実施手順](../almalinux-setup.md#syncthing-実施手順) |
| setup-notes | [docs/syncthing.md: 同期フォルダとデバイスを追加する（任意）](../syncthing.md#同期フォルダとデバイスを追加する任意) | [AlmaLinux 10: Syncthing: 同期フォルダとデバイスを追加する（任意）](../almalinux-setup.md#syncthing-同期フォルダとデバイスを追加する任意) |
| setup-notes | [docs/syncthing.md: 接続元を絞る（任意）](../syncthing.md#接続元を絞る任意) | [AlmaLinux 10: Syncthing: 接続元を絞る（任意）](../almalinux-setup.md#syncthing-接続元を絞る任意) |
| setup-notes | [docs/syncthing.md: 設定を自動でバックアップする（任意）](../syncthing.md#設定を自動でバックアップする任意) | [AlmaLinux 10: Syncthing: 設定を自動でバックアップする（任意）](../almalinux-setup.md#syncthing-設定を自動でバックアップする任意) |
| setup-notes | [docs/syncthing.md: バックアップから戻す](../syncthing.md#バックアップから戻す) | [AlmaLinux 10: Syncthing: バックアップから戻す](../almalinux-setup.md#syncthing-バックアップから戻す) |
| setup-notes | [docs/syncthing.md: 更新](../syncthing.md#更新) | [AlmaLinux 10: Syncthing: 更新](../almalinux-setup.md#syncthing-更新) |
| setup-notes | [docs/syncthing.md: Windows 11 で使う](../syncthing.md#windows-11-で使う) | [Windows 11: Syncthing: Windows 11 で使う](../windows-setup.md#syncthing-windows-11-で使う) |
| setup-notes | [docs/syncthing.md: Windows 11 で止める・もう一度始める](../syncthing.md#windows-11-で止めるもう一度始める) | [Windows 11: Syncthing: Windows 11 で止める・もう一度始める](../windows-setup.md#syncthing-windows-11-で止めるもう一度始める) |
| setup-notes | [docs/syncthing.md: Windows 11 の更新](../syncthing.md#windows-11-の更新) | [Windows 11: Syncthing: Windows 11 の更新](../windows-setup.md#syncthing-windows-11-の更新) |
| setup-notes | [docs/syncthing.md: Syncthing インストール手順（AlmaLinux 10 は Homebrew + systemd ユーザーサービス / Windows 11 は公式の zip + タスク スケジューラ）](../syncthing.md#syncthing-インストール手順almalinux-10-は-homebrew--systemd-ユーザーサービス--windows-11-は公式の-zip--タスク-スケジューラ) | [AlmaLinux 10: Syncthing: 実施手順](../almalinux-setup.md#syncthing-実施手順) |
| setup-notes | [docs/virtualbox-guest-bootc.md: 実施手順](../virtualbox-guest-bootc.md#実施手順) | [AlmaLinux 10: VirtualBox の bootc ゲスト: 実施手順](../almalinux-setup.md#virtualbox-の-bootc-ゲスト-実施手順) |
| setup-notes | [docs/virtualbox-guest-bootc.md: ホストオンリーアダプターだけの VM でビルドする（任意）](../virtualbox-guest-bootc.md#ホストオンリーアダプターだけの-vm-でビルドする任意) | [AlmaLinux 10: VirtualBox の bootc ゲスト: ホストオンリーアダプターだけの VM でビルドする（任意）](../almalinux-setup.md#virtualbox-の-bootc-ゲスト-ホストオンリーアダプターだけの-vm-でビルドする任意) |
| setup-notes | [docs/virtualbox-guest-bootc.md: 共有フォルダーを使う（任意）](../virtualbox-guest-bootc.md#共有フォルダーを使う任意) | [AlmaLinux 10: VirtualBox の bootc ゲスト: 共有フォルダーを使う（任意）](../almalinux-setup.md#virtualbox-の-bootc-ゲスト-共有フォルダーを使う任意) |
| setup-notes | [docs/virtualbox-guest-bootc.md: 更新](../virtualbox-guest-bootc.md#更新) | [AlmaLinux 10: VirtualBox の bootc ゲスト: 更新](../almalinux-setup.md#virtualbox-の-bootc-ゲスト-更新) |
| setup-notes | [docs/virtualbox-guest-bootc.md: 既存のコンテナ署名設定に追加する](../virtualbox-guest-bootc.md#既存のコンテナ署名設定に追加する) | [AlmaLinux 10: VirtualBox の bootc ゲスト: 既存のコンテナ署名設定に追加する](../almalinux-setup.md#virtualbox-の-bootc-ゲスト-既存のコンテナ署名設定に追加する) |
| setup-notes | [docs/virtualbox-guest-bootc.md: VirtualBox Guest Additions 導入手順（AlmaLinux 10 bootc / Atomic Desktop のゲスト）](../virtualbox-guest-bootc.md#virtualbox-guest-additions-導入手順almalinux-10-bootc--atomic-desktop-のゲスト) | [AlmaLinux 10: VirtualBox の bootc ゲスト: 実施手順](../almalinux-setup.md#virtualbox-の-bootc-ゲスト-実施手順) |
| setup-notes | [docs/virtualbox.md: 実施手順](../virtualbox.md#実施手順) | [AlmaLinux 10: VirtualBox: 実施手順](../almalinux-setup.md#virtualbox-実施手順) |
| setup-notes | [docs/virtualbox.md: リポジトリを置く](../virtualbox.md#リポジトリを置く) | [AlmaLinux 10: VirtualBox: リポジトリを置く](../almalinux-setup.md#virtualbox-リポジトリを置く) |
| setup-notes | [docs/virtualbox.md: VirtualBox を入れる](../virtualbox.md#virtualbox-を入れる) | [AlmaLinux 10: VirtualBox: VirtualBox を入れる](../almalinux-setup.md#virtualbox-virtualbox-を入れる) |
| setup-notes | [docs/virtualbox.md: KVM と USB の設定](../virtualbox.md#kvm-と-usb-の設定) | [AlmaLinux 10: VirtualBox: KVM と USB の設定](../almalinux-setup.md#virtualbox-kvm-と-usb-の設定) |
| setup-notes | [docs/virtualbox.md: 動作を確かめる](../virtualbox.md#動作を確かめる) | [AlmaLinux 10: VirtualBox: 動作を確かめる](../almalinux-setup.md#virtualbox-動作を確かめる) |
| setup-notes | [docs/virtualbox.md: カーネルを更新したとき](../virtualbox.md#カーネルを更新したとき) | [AlmaLinux 10: VirtualBox: カーネルを更新したとき](../almalinux-setup.md#virtualbox-カーネルを更新したとき) |
| setup-notes | [docs/virtualbox.md: 更新](../virtualbox.md#更新) | [AlmaLinux 10: VirtualBox: 更新](../almalinux-setup.md#virtualbox-更新) |
| setup-notes | [docs/virtualbox.md: Windows 11 で使う](../virtualbox.md#windows-11-で使う) | [Windows 11: VirtualBox: Windows 11 で使う](../windows-setup.md#virtualbox-windows-11-で使う) |
| setup-notes | [docs/virtualbox.md: Windows 11 の VirtualBox を Android からリモート デスクトップで使う（任意）](../virtualbox.md#windows-11-の-virtualbox-を-android-からリモート-デスクトップで使う任意) | [Windows 11: VirtualBox: Windows 11 の VirtualBox を Android からリモート デスクトップで使う（任意）](../windows-setup.md#virtualbox-windows-11-の-virtualbox-を-android-からリモート-デスクトップで使う任意) |
| setup-notes | [docs/virtualbox.md: Windows 11 の更新](../virtualbox.md#windows-11-の更新) | [Windows 11: VirtualBox: Windows 11 の更新](../windows-setup.md#virtualbox-windows-11-の更新) |
| setup-notes | [docs/virtualbox.md: VirtualBox インストール手順（AlmaLinux 10 は Oracle 公式 dnf リポジトリ / Windows 11 は winget）](../virtualbox.md#virtualbox-インストール手順almalinux-10-は-oracle-公式-dnf-リポジトリ--windows-11-は-winget) | [AlmaLinux 10: VirtualBox: 実施手順](../almalinux-setup.md#virtualbox-実施手順) |
| setup-notes | [docs/vmware.md: 実施手順](../vmware.md#実施手順) | [Windows 11: VMware Workstation Pro: 実施手順](../windows-setup.md#vmware-workstation-pro-実施手順) |
| setup-notes | [docs/vmware.md: インストーラーを取得して確かめる](../vmware.md#インストーラーを取得して確かめる) | [Windows 11: VMware Workstation Pro: インストーラーを取得して確かめる](../windows-setup.md#vmware-workstation-pro-インストーラーを取得して確かめる) |
| setup-notes | [docs/vmware.md: インストールする](../vmware.md#インストールする) | [Windows 11: VMware Workstation Pro: インストールする](../windows-setup.md#vmware-workstation-pro-インストールする) |
| setup-notes | [docs/vmware.md: 入ったかを確かめる](../vmware.md#入ったかを確かめる) | [Windows 11: VMware Workstation Pro: 入ったかを確かめる](../windows-setup.md#vmware-workstation-pro-入ったかを確かめる) |
| setup-notes | [docs/vmware.md: VM を作る](../vmware.md#vm-を作る) | [Windows 11: VMware Workstation Pro: VM を作る](../windows-setup.md#vmware-workstation-pro-vm-を作る) |
| setup-notes | [docs/vmware.md: VM を起動して OS を入れる](../vmware.md#vm-を起動して-os-を入れる) | [Windows 11: VMware Workstation Pro: VM を起動して OS を入れる](../windows-setup.md#vmware-workstation-pro-vm-を起動して-os-を入れる) |
| setup-notes | [docs/vmware.md: 動作を確かめる](../vmware.md#動作を確かめる) | [Windows 11: VMware Workstation Pro: 動作を確かめる](../windows-setup.md#vmware-workstation-pro-動作を確かめる) |
| setup-notes | [docs/vmware.md: 使い方の基本](../vmware.md#使い方の基本) | [Windows 11: VMware Workstation Pro: 使い方の基本](../windows-setup.md#vmware-workstation-pro-使い方の基本) |
| setup-notes | [docs/vmware.md: スナップショットとクローン](../vmware.md#スナップショットとクローン) | [Windows 11: VMware Workstation Pro: スナップショットとクローン](../windows-setup.md#vmware-workstation-pro-スナップショットとクローン) |
| setup-notes | [docs/vmware.md: VM を消す](../vmware.md#vm-を消す) | [Windows 11: VMware Workstation Pro: VM を消す](../windows-setup.md#vmware-workstation-pro-vm-を消す) |
| setup-notes | [docs/vmware.md: VMware Workstation Pro のインストールと VM の作成（Windows 11）](../vmware.md#vmware-workstation-pro-のインストールと-vm-の作成windows-11) | [Windows 11: VMware Workstation Pro: 実施手順](../windows-setup.md#vmware-workstation-pro-実施手順) |
| setup-notes | [docs/vscode.md: 実施手順](../vscode.md#実施手順) | [AlmaLinux 10: VS Code: 実施手順](../almalinux-setup.md#vs-code-実施手順) |
| setup-notes | [docs/vscode.md: 拡張機能を入れる（任意）](../vscode.md#拡張機能を入れる任意) | [AlmaLinux 10: VS Code: 拡張機能を入れる（任意）](../almalinux-setup.md#vs-code-拡張機能を入れる任意) |
| setup-notes | [docs/vscode.md: 更新](../vscode.md#更新) | [AlmaLinux 10: VS Code: 更新](../almalinux-setup.md#vs-code-更新) |
| setup-notes | [docs/vscode.md: Visual Studio Code インストール手順（AlmaLinux 10 / Microsoft 公式 dnf リポジトリ）](../vscode.md#visual-studio-code-インストール手順almalinux-10--microsoft-公式-dnf-リポジトリ) | [AlmaLinux 10: VS Code: 実施手順](../almalinux-setup.md#vs-code-実施手順) |
| setup-notes | [docs/windows-claude-remote-control.md: 実施手順](../windows-claude-remote-control.md#実施手順) | [Windows 11: Claude Code の Remote Control: 実施手順](../windows-setup.md#claude-code-の-remote-control-実施手順) |
| setup-notes | [docs/windows-claude-remote-control.md: 止める・もう一度始める](../windows-claude-remote-control.md#止めるもう一度始める) | [Windows 11: Claude Code の Remote Control: 止める・もう一度始める](../windows-setup.md#claude-code-の-remote-control-止めるもう一度始める) |
| setup-notes | [docs/windows-claude-remote-control.md: Windows 11 で Claude Code の Remote Control を SSH の切断後も動かす手順（タスク スケジューラ + WezTerm）](../windows-claude-remote-control.md#windows-11-で-claude-code-の-remote-control-を-ssh-の切断後も動かす手順タスク-スケジューラ--wezterm) | [Windows 11: Claude Code の Remote Control: 実施手順](../windows-setup.md#claude-code-の-remote-control-実施手順) |
| setup-notes | [docs/windows-dual-boot.md: 実施手順](../windows-dual-boot.md#実施手順) | [Windows 11: Windows と AlmaLinux のデュアルブート: 実施手順](../windows-setup.md#windows-と-almalinux-のデュアルブート-実施手順) |
| setup-notes | [docs/windows-dual-boot.md: 次回だけ AlmaLinux で起動する（任意）](../windows-dual-boot.md#次回だけ-almalinux-で起動する任意) | [Windows 11: Windows と AlmaLinux のデュアルブート: 次回だけ AlmaLinux で起動する（任意）](../windows-setup.md#windows-と-almalinux-のデュアルブート-次回だけ-almalinux-で起動する任意) |
| setup-notes | [docs/windows-dual-boot.md: 次回起動の指定を取り消す（任意）](../windows-dual-boot.md#次回起動の指定を取り消す任意) | [Windows 11: Windows と AlmaLinux のデュアルブート: 次回起動の指定を取り消す（任意）](../windows-setup.md#windows-と-almalinux-のデュアルブート-次回起動の指定を取り消す任意) |
| setup-notes | [docs/windows-dual-boot.md: Windows 11 を AlmaLinux 10 とのデュアルブート向けに入れる手順（ESP を 2 GiB にし、AlmaLinux 用の空きを残す）](../windows-dual-boot.md#windows-11-を-almalinux-10-とのデュアルブート向けに入れる手順esp-を-2-gib-にしalmalinux-用の空きを残す) | [Windows 11: Windows と AlmaLinux のデュアルブート: 実施手順](../windows-setup.md#windows-と-almalinux-のデュアルブート-実施手順) |
| setup-notes | [docs/windows-hotkey-conflict.md: 実施手順](../windows-hotkey-conflict.md#実施手順) | [Windows 11: Windows のホットキー競合: 実施手順](../windows-setup.md#windows-のホットキー競合-実施手順) |
| setup-notes | [docs/windows-hotkey-conflict.md: 初回準備](../windows-hotkey-conflict.md#初回準備) | [Windows 11: Windows のホットキー競合: 初回準備](../windows-setup.md#windows-のホットキー競合-初回準備) |
| setup-notes | [docs/windows-hotkey-conflict.md: 権限要求を減らすために Program Files へ配置する（任意）](../windows-hotkey-conflict.md#権限要求を減らすために-program-files-へ配置する任意) | [Windows 11: Windows のホットキー競合: 権限要求を減らすために Program Files へ配置する（任意）](../windows-setup.md#windows-のホットキー競合-権限要求を減らすために-program-files-へ配置する任意) |
| setup-notes | [docs/windows-hotkey-conflict.md: 使用アプリが分からない場合の切り分け](../windows-hotkey-conflict.md#使用アプリが分からない場合の切り分け) | [Windows 11: Windows のホットキー競合: 使用アプリが分からない場合の切り分け](../windows-setup.md#windows-のホットキー競合-使用アプリが分からない場合の切り分け) |
| setup-notes | [docs/windows-hotkey-conflict.md: ホットキーの登録可否を確認する（任意）](../windows-hotkey-conflict.md#ホットキーの登録可否を確認する任意) | [Windows 11: Windows のホットキー競合: ホットキーの登録可否を確認する（任意）](../windows-setup.md#windows-のホットキー競合-ホットキーの登録可否を確認する任意) |
| setup-notes | [docs/windows-hotkey-conflict.md: Windows 11 でホットキーを使用しているアプリを調べる手順](../windows-hotkey-conflict.md#windows-11-でホットキーを使用しているアプリを調べる手順) | [Windows 11: Windows のホットキー競合: 実施手順](../windows-setup.md#windows-のホットキー競合-実施手順) |
| setup-notes | [docs/windows-rdp-disconnect.md: 実施手順](../windows-rdp-disconnect.md#実施手順) | [Windows 11: RDP をロックせずに切断: 実施手順](../windows-setup.md#rdp-をロックせずに切断-実施手順) |
| setup-notes | [docs/windows-rdp-disconnect.md: ショートカットで切断する（任意）](../windows-rdp-disconnect.md#ショートカットで切断する任意) | [Windows 11: RDP をロックせずに切断: ショートカットで切断する（任意）](../windows-setup.md#rdp-をロックせずに切断-ショートカットで切断する任意) |
| setup-notes | [docs/windows-rdp-disconnect.md: Windows 11 のリモートデスクトップを、画面をロックせずに切断する手順（tscon）](../windows-rdp-disconnect.md#windows-11-のリモートデスクトップを画面をロックせずに切断する手順tscon) | [Windows 11: RDP をロックせずに切断: 実施手順](../windows-setup.md#rdp-をロックせずに切断-実施手順) |
| setup-notes | [docs/windows-ssh-client.md: 実施手順](../windows-ssh-client.md#実施手順) | [Windows 11: Windows の OpenSSH クライアント: 実施手順](../windows-setup.md#windows-の-openssh-クライアント-実施手順) |
| setup-notes | [docs/windows-ssh-client.md: 更新](../windows-ssh-client.md#更新) | [Windows 11: Windows の OpenSSH クライアント: 更新](../windows-setup.md#windows-の-openssh-クライアント-更新) |
| setup-notes | [docs/windows-ssh-client.md: Windows 11 で OpenSSH クライアントを使う手順（ed25519 の鍵と ssh の config で AlmaLinux 10 のホストに入る）](../windows-ssh-client.md#windows-11-で-openssh-クライアントを使う手順ed25519-の鍵と-ssh-の-config-で-almalinux-10-のホストに入る) | [Windows 11: Windows の OpenSSH クライアント: 実施手順](../windows-setup.md#windows-の-openssh-クライアント-実施手順) |
| setup-notes | [docs/wireguard.md: 実施手順](../wireguard.md#実施手順) | [AlmaLinux 10: WireGuard: 実施手順](../almalinux-setup.md#wireguard-実施手順) |
| setup-notes | [docs/wireguard.md: site.env を作る](../wireguard.md#siteenv-を作る) | [AlmaLinux 10: WireGuard: site.env を作る](../almalinux-setup.md#wireguard-siteenv-を作る) |
| setup-notes | [docs/wireguard.md: 鍵を作って適用する](../wireguard.md#鍵を作って適用する) | [AlmaLinux 10: WireGuard: 鍵を作って適用する](../almalinux-setup.md#wireguard-鍵を作って適用する) |
| setup-notes | [docs/wireguard.md: クライアントを登録する](../wireguard.md#クライアントを登録する) | [AlmaLinux 10: WireGuard: クライアントを登録する](../almalinux-setup.md#wireguard-クライアントを登録する) |
| setup-notes | [docs/wireguard.md: 状態と疎通を確かめる](../wireguard.md#状態と疎通を確かめる) | [AlmaLinux 10: WireGuard: 状態と疎通を確かめる](../almalinux-setup.md#wireguard-状態と疎通を確かめる) |
| setup-notes | [docs/wireguard.md: AlmaLinux 10 の PC からつなぐ](../wireguard.md#almalinux-10-の-pc-からつなぐ) | [AlmaLinux 10: WireGuard: AlmaLinux 10 の PC からつなぐ](../almalinux-setup.md#wireguard-almalinux-10-の-pc-からつなぐ) |
| setup-notes | [docs/wireguard.md: 鍵を作る](../wireguard.md#鍵を作る) | [AlmaLinux 10: WireGuard: 鍵を作る](../almalinux-setup.md#wireguard-鍵を作る) |
| setup-notes | [docs/wireguard.md: WG ホストに登録する](../wireguard.md#wg-ホストに登録する) | [AlmaLinux 10: WireGuard: WG ホストに登録する](../almalinux-setup.md#wireguard-wg-ホストに登録する) |
| setup-notes | [docs/wireguard.md: conf を取り込む](../wireguard.md#conf-を取り込む) | [AlmaLinux 10: WireGuard: conf を取り込む](../almalinux-setup.md#wireguard-conf-を取り込む) |
| setup-notes | [docs/wireguard.md: トンネルを確かめる](../wireguard.md#トンネルを確かめる) | [AlmaLinux 10: WireGuard: トンネルを確かめる](../almalinux-setup.md#wireguard-トンネルを確かめる) |
| setup-notes | [docs/wireguard.md: Windows 11 で使う](../wireguard.md#windows-11-で使う) | [Windows 11: WireGuard: Windows 11 で使う](../windows-setup.md#wireguard-windows-11-で使う) |
| setup-notes | [docs/wireguard.md: Windows 11 で WireGuard と鍵を用意する](../wireguard.md#windows-11-で-wireguard-と鍵を用意する) | [Windows 11: WireGuard: Windows 11 で WireGuard と鍵を用意する](../windows-setup.md#wireguard-windows-11-で-wireguard-と鍵を用意する) |
| setup-notes | [docs/wireguard.md: Windows 11 で WG ホストに登録して取り込む](../wireguard.md#windows-11-で-wg-ホストに登録して取り込む) | [Windows 11: WireGuard: Windows 11 で WG ホストに登録して取り込む](../windows-setup.md#wireguard-windows-11-で-wg-ホストに登録して取り込む) |
| setup-notes | [docs/wireguard.md: Windows 11 でトンネルを確かめる](../wireguard.md#windows-11-でトンネルを確かめる) | [Windows 11: WireGuard: Windows 11 でトンネルを確かめる](../windows-setup.md#wireguard-windows-11-でトンネルを確かめる) |
| setup-notes | [docs/wireguard.md: Windows 11 の更新](../wireguard.md#windows-11-の更新) | [Windows 11: WireGuard: Windows 11 の更新](../windows-setup.md#wireguard-windows-11-の更新) |
| setup-notes | [docs/wireguard.md: 回線に合わせて MTU を下げる（任意）](../wireguard.md#回線に合わせて-mtu-を下げる任意) | [AlmaLinux 10: WireGuard: 回線に合わせて MTU を下げる（任意）](../almalinux-setup.md#wireguard-回線に合わせて-mtu-を下げる任意) |
| setup-notes | [docs/wireguard.md: クライアントを削除する](../wireguard.md#クライアントを削除する) | [AlmaLinux 10: WireGuard: クライアントを削除する](../almalinux-setup.md#wireguard-クライアントを削除する) |
| setup-notes | [docs/wireguard.md: バックアップと復旧（OS の再インストール）](../wireguard.md#バックアップと復旧os-の再インストール) | [AlmaLinux 10: WireGuard: バックアップと復旧（OS の再インストール）](../almalinux-setup.md#wireguard-バックアップと復旧os-の再インストール) |
| setup-notes | [docs/wireguard.md: 落とし穴: `apply` は作業中の ssh 経路そのものを切る](../wireguard.md#落とし穴-apply-は作業中の-ssh-経路そのものを切る) | [AlmaLinux 10: WireGuard: 落とし穴: `apply` は作業中の ssh 経路そのものを切る](../almalinux-setup.md#wireguard-落とし穴-apply-は作業中の-ssh-経路そのものを切る) |
| setup-notes | [docs/wireguard.md: site.env に書く値](../wireguard.md#siteenv-に書く値) | [AlmaLinux 10: WireGuard: site.env に書く値](../almalinux-setup.md#wireguard-siteenv-に書く値) |
| setup-notes | [docs/wireguard.md: WireGuard VPN 構築手順（site-to-site + road warrior / wg-quick + firewalld）](../wireguard.md#wireguard-vpn-構築手順site-to-site--road-warrior--wg-quick--firewalld) | [AlmaLinux 10: WireGuard: 実施手順](../almalinux-setup.md#wireguard-実施手順) |
| bash | [docs/install.md: 実施手順](https://github.com/ryo-aoki-pc/bash/blob/main/docs/install.md#実施手順) | [AlmaLinux 10: 共通の-bash-設定を手動で移行する任意](../almalinux-setup.md#共通の-bash-設定を手動で移行する任意) |
| bash | [docs/install.md: root-のシェルでも読む任意](https://github.com/ryo-aoki-pc/bash/blob/main/docs/install.md#root-のシェルでも読む任意) | [AlmaLinux 10: 共通の-bash-設定を-root-に入れる任意](../almalinux-setup.md#共通の-bash-設定を-root-に入れる任意) |
| bash | [docs/install.md: 更新](https://github.com/ryo-aoki-pc/bash/blob/main/docs/install.md#更新) | [AlmaLinux 10: 共通の-bash-設定を更新する](../almalinux-setup.md#共通の-bash-設定を更新する) |
| bash | [docs/install.md: 更新](https://github.com/ryo-aoki-pc/bash/blob/main/docs/install.md#更新) | [Windows 11: 共通の-bash-設定を更新する](../windows-setup.md#共通の-bash-設定を更新する) |
| bash | [docs/quick-start.md: 実施手順](https://github.com/ryo-aoki-pc/bash/blob/main/docs/quick-start.md#実施手順) | [AlmaLinux 10: 共通の-bash-設定](../almalinux-setup.md#共通の-bash-設定) |
| bash | [docs/quick-start.md: 更新](https://github.com/ryo-aoki-pc/bash/blob/main/docs/quick-start.md#更新) | [AlmaLinux 10: 共通の-bash-設定を更新する](../almalinux-setup.md#共通の-bash-設定を更新する) |
| bash | [docs/quick-start.md: 実施手順](https://github.com/ryo-aoki-pc/bash/blob/main/docs/quick-start.md#実施手順) | [Windows 11: git-bash-と-wezterm-の設定](../windows-setup.md#git-bash-と-wezterm-の設定) |
| bash | [docs/quick-start.md: 更新](https://github.com/ryo-aoki-pc/bash/blob/main/docs/quick-start.md#更新) | [Windows 11: 共通の-bash-設定を更新する](../windows-setup.md#共通の-bash-設定を更新する) |
| wezterm | [docs/install.md: 実施手順](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md#実施手順) | [AlmaLinux 10: wezterm-の設定を導入する](../almalinux-setup.md#wezterm-の設定を導入する) |
| wezterm | [docs/install.md: 実施手順](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md#実施手順) | [Windows 11: wezterm-の設定を導入する](../windows-setup.md#wezterm-の設定を導入する) |
| wezterm | [docs/install.md: wsl-でもシェル統合を使う任意](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md#wsl-でもシェル統合を使う任意) | [Windows 11: wezterm-のシェル統合を-wsl-で使う任意](../windows-setup.md#wezterm-のシェル統合を-wsl-で使う任意) |
| wezterm | [docs/install.md: ssh-先でもシェル統合を使う任意](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md#ssh-先でもシェル統合を使う任意) | [AlmaLinux 10: wezterm-のシェル統合を-ssh-先で使う任意](../almalinux-setup.md#wezterm-のシェル統合を-ssh-先で使う任意) |
| wezterm | [docs/install.md: 更新](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md#更新) | [AlmaLinux 10: wezterm-の設定を更新する](../almalinux-setup.md#wezterm-の設定を更新する) |
| wezterm | [docs/install.md: 更新](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md#更新) | [Windows 11: wezterm-の設定を更新する](../windows-setup.md#wezterm-の設定を更新する) |
| LazyVimStarter | [docs/setup.md: almalinux-10-に導入する-1-度だけ](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#almalinux-10-に導入する-1-度だけ) | [AlmaLinux 10: lazyvim-の設定を導入する](../almalinux-setup.md#lazyvim-の設定を導入する) |
| LazyVimStarter | [docs/setup.md: windows-11-に導入する-1-度だけ](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#windows-11-に導入する-1-度だけ) | [Windows 11: lazyvim-の設定を導入する](../windows-setup.md#lazyvim-の設定を導入する) |
| LazyVimStarter | [docs/setup.md: ほかのマシンの変更を取り込む-繰り返し](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#ほかのマシンの変更を取り込む-繰り返し) | [AlmaLinux 10: lazyvim-の設定とプラグインの版を揃える](../almalinux-setup.md#lazyvim-の設定とプラグインの版を揃える) |
| LazyVimStarter | [docs/setup.md: ほかのマシンの変更を取り込む-繰り返し](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#ほかのマシンの変更を取り込む-繰り返し) | [Windows 11: lazyvim-の設定とプラグインの版を揃える](../windows-setup.md#lazyvim-の設定とプラグインの版を揃える) |
| LazyVimStarter | [docs/setup.md: gitlab-markdown-の安全な整形を導入する-初回と依存の変更後](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#gitlab-markdown-の安全な整形を導入する-初回と依存の変更後) | [AlmaLinux 10: lazyvim-の安全な-markdown-整形を導入する](../almalinux-setup.md#lazyvim-の安全な-markdown-整形を導入する) |
| LazyVimStarter | [docs/setup.md: gitlab-markdown-の安全な整形を導入する-初回と依存の変更後](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#gitlab-markdown-の安全な整形を導入する-初回と依存の変更後) | [Windows 11: lazyvim-の安全な-markdown-整形を導入する](../windows-setup.md#lazyvim-の安全な-markdown-整形を導入する) |
| LazyVimStarter | [docs/setup.md: カーソル色を-tmux-で効かせる-任意](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#カーソル色を-tmux-で効かせる-任意) | [AlmaLinux 10: lazyvim-のカーソル色を-tmux-で使う任意](../almalinux-setup.md#lazyvim-のカーソル色を-tmux-で使う任意) |
| LazyVimStarter | [docs/setup.md: gnome-の上部バーを-ime-連携に合わせる-任意](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#gnome-の上部バーを-ime-連携に合わせる-任意) | [AlmaLinux 10: lazyvim-の-ime-連携に-gnome-の上部バーを合わせる任意](../almalinux-setup.md#lazyvim-の-ime-連携に-gnome-の上部バーを合わせる任意) |
| LazyVimStarter | [docs/setup.md: ssh-越しのヤンクを手元のクリップボードに送る-任意](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#ssh-越しのヤンクを手元のクリップボードに送る-任意) | [AlmaLinux 10: lazyvim-のヤンクを-ssh-越しに手元へ送る任意](../almalinux-setup.md#lazyvim-のヤンクを-ssh-越しに手元へ送る任意) |
| LazyVimStarter | [docs/setup.md: gitlab-プレビューのトークンを設定する-任意](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#gitlab-プレビューのトークンを設定する-任意) | [AlmaLinux 10: lazyvim-の-gitlab-プレビューを設定する任意](../almalinux-setup.md#lazyvim-の-gitlab-プレビューを設定する任意) |
| LazyVimStarter | [docs/setup.md: gitlab-プレビューのトークンを設定する-任意](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#gitlab-プレビューのトークンを設定する-任意) | [Windows 11: lazyvim-の-gitlab-プレビューを設定する任意](../windows-setup.md#lazyvim-の-gitlab-プレビューを設定する任意) |
| LazyVimStarter | [docs/setup.md: 更新](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#更新) | [AlmaLinux 10: lazyvim-の本体外部コマンドプラグインを更新する](../almalinux-setup.md#lazyvim-の本体外部コマンドプラグインを更新する) |
| LazyVimStarter | [docs/setup.md: 更新](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#更新) | [Windows 11: lazyvim-の本体外部コマンドプラグインを更新する](../windows-setup.md#lazyvim-の本体外部コマンドプラグインを更新する) |
| kvm-container | [docs/setup.md: 導入する-1-度だけ](https://github.com/ryo-aoki-pc/kvm-container/blob/main/docs/setup.md#導入する-1-度だけ) | [AlmaLinux 10: kvm-container-を導入する任意](../almalinux-setup.md#kvm-container-を導入する任意) |
| kvm-container | [docs/setup.md: vm-を作る-vm-ごとに-1-度](https://github.com/ryo-aoki-pc/kvm-container/blob/main/docs/setup.md#vm-を作る-vm-ごとに-1-度) | [AlmaLinux 10: kvm-container-で-vm-を作る](../almalinux-setup.md#kvm-container-で-vm-を作る) |
| kvm-container | [docs/setup.md: vm-を使う-繰り返し](https://github.com/ryo-aoki-pc/kvm-container/blob/main/docs/setup.md#vm-を使う-繰り返し) | [AlmaLinux 10: kvm-container-の-vm-を使う](../almalinux-setup.md#kvm-container-の-vm-を使う) |
| kvm-container | [docs/setup.md: 再ログインしたとき-繰り返し](https://github.com/ryo-aoki-pc/kvm-container/blob/main/docs/setup.md#再ログインしたとき-繰り返し) | [AlmaLinux 10: kvm-container-の-gui-を再ログイン後に使う](../almalinux-setup.md#kvm-container-の-gui-を再ログイン後に使う) |
| kvm-container | [docs/setup.md: vm-をホストのブリッジにつなぐ-任意](https://github.com/ryo-aoki-pc/kvm-container/blob/main/docs/setup.md#vm-をホストのブリッジにつなぐ-任意) | [AlmaLinux 10: kvm-container-の-vm-をホストのブリッジにつなぐ任意](../almalinux-setup.md#kvm-container-の-vm-をホストのブリッジにつなぐ任意) |
| kvm-container | [docs/setup.md: vm-を削除する](https://github.com/ryo-aoki-pc/kvm-container/blob/main/docs/setup.md#vm-を削除する) | [AlmaLinux 10: kvm-container-の-vm-を削除する](../almalinux-setup.md#kvm-container-の-vm-を削除する) |
| kvm-container | [docs/setup.md: 更新](https://github.com/ryo-aoki-pc/kvm-container/blob/main/docs/setup.md#更新) | [AlmaLinux 10: kvm-container-を更新する](../almalinux-setup.md#kvm-container-を更新する) |
| lazygit | [README.md: 導入方法](https://github.com/ryo-aoki-pc/lazygit/blob/custom/README.md#導入方法) | [AlmaLinux 10: lazygit-の設定を導入する](../almalinux-setup.md#lazygit-の設定を導入する) |
| lazygit | [README.md: 導入方法](https://github.com/ryo-aoki-pc/lazygit/blob/custom/README.md#導入方法) | [Windows 11: lazygit-の設定を導入する](../windows-setup.md#lazygit-の設定を導入する) |
| lazygit | [docs/excel-diff.md: 導入](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/excel-diff.md#導入) | [AlmaLinux 10: lazygit-の-excel-差分表示を導入する任意](../almalinux-setup.md#lazygit-の-excel-差分表示を導入する任意) |
| lazygit | [docs/excel-diff.md: 確認と操作](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/excel-diff.md#確認と操作) | [AlmaLinux 10: lazygit-で-excel-の差分を確かめる](../almalinux-setup.md#lazygit-で-excel-の差分を確かめる) |
| lazygit | [docs/excel-diff.md: excel-の部分ステージ](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/excel-diff.md#excel-の部分ステージ) | [AlmaLinux 10: lazygit-で-excel-のセル変更を部分ステージする](../almalinux-setup.md#lazygit-で-excel-のセル変更を部分ステージする) |
| lazygit | [docs/excel-diff.md: 大きいブックの表示](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/excel-diff.md#大きいブックの表示) | [AlmaLinux 10: lazygit-で大きな-excel-の変換を待つ任意](../almalinux-setup.md#lazygit-で大きな-excel-の変換を待つ任意) |
| lazygit | [docs/excel-diff.md: 導入](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/excel-diff.md#導入) | [Windows 11: lazygit-の-excel-差分表示を導入する任意](../windows-setup.md#lazygit-の-excel-差分表示を導入する任意) |
| lazygit | [docs/excel-diff.md: 確認と操作](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/excel-diff.md#確認と操作) | [Windows 11: lazygit-で-excel-の差分を確かめる](../windows-setup.md#lazygit-で-excel-の差分を確かめる) |
| lazygit | [docs/excel-diff.md: excel-の部分ステージ](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/excel-diff.md#excel-の部分ステージ) | [Windows 11: lazygit-で-excel-のセル変更を部分ステージする](../windows-setup.md#lazygit-で-excel-のセル変更を部分ステージする) |
| lazygit | [docs/excel-diff.md: 大きいブックの表示](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/excel-diff.md#大きいブックの表示) | [Windows 11: lazygit-で大きな-excel-の変換を待つ任意](../windows-setup.md#lazygit-で大きな-excel-の変換を待つ任意) |
| yazi | [README.md: インストール](https://github.com/ryo-aoki-pc/yazi/blob/custom/README.md#インストール) | [AlmaLinux 10: yazi-の設定を導入する](../almalinux-setup.md#yazi-の設定を導入する) |
| yazi | [README.md: 補足-複数ファイルをまとめて開く](https://github.com/ryo-aoki-pc/yazi/blob/custom/README.md#補足-複数ファイルをまとめて開く) | [AlmaLinux 10: yazi-で複数ファイルをまとめて開く任意](../almalinux-setup.md#yazi-で複数ファイルをまとめて開く任意) |
| yazi | [README.md: インストール](https://github.com/ryo-aoki-pc/yazi/blob/custom/README.md#インストール) | [Windows 11: yazi-の設定を導入する](../windows-setup.md#yazi-の設定を導入する) |
| yazi | [README.md: 補足-複数ファイルをまとめて開く](https://github.com/ryo-aoki-pc/yazi/blob/custom/README.md#補足-複数ファイルをまとめて開く) | [Windows 11: yazi-で複数ファイルをまとめて開く任意](../windows-setup.md#yazi-で複数ファイルをまとめて開く任意) |
| md-table-excel | [README.md: 導入](https://github.com/ryo-aoki-pc/md-table-excel/blob/main/README.md#導入) | [AlmaLinux 10: mdtable-を導入更新する任意](../almalinux-setup.md#mdtable-を導入更新する任意) |
| md-table-excel | [README.md: 使い方](https://github.com/ryo-aoki-pc/md-table-excel/blob/main/README.md#使い方) | [AlmaLinux 10: mdtable-で-markdown-の表を-excel-と往復する](../almalinux-setup.md#mdtable-で-markdown-の表を-excel-と往復する) |
| md-table-excel | [README.md: 導入](https://github.com/ryo-aoki-pc/md-table-excel/blob/main/README.md#導入) | [Windows 11: mdtable-を導入更新する任意](../windows-setup.md#mdtable-を導入更新する任意) |
| md-table-excel | [README.md: 使い方](https://github.com/ryo-aoki-pc/md-table-excel/blob/main/README.md#使い方) | [Windows 11: mdtable-で-markdown-の表を-excel-と往復する](../windows-setup.md#mdtable-で-markdown-の表を-excel-と往復する) |
| md-table-excel | [README.md: excel-で編集するときの注意](https://github.com/ryo-aoki-pc/md-table-excel/blob/main/README.md#excel-で編集するときの注意) | [AlmaLinux 10: mdtable-のブックを-excel-で編集するときの注意](../almalinux-setup.md#mdtable-のブックを-excel-で編集するときの注意) |
| md-table-excel | [README.md: excel-で編集するときの注意](https://github.com/ryo-aoki-pc/md-table-excel/blob/main/README.md#excel-で編集するときの注意) | [Windows 11: mdtable-のブックを-excel-で編集するときの注意](../windows-setup.md#mdtable-のブックを-excel-で編集するときの注意) |
