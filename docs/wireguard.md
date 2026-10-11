# WireGuard VPN 構築手順（site-to-site + road warrior / wg-quick + firewalld）

実施手順は OS ごとのセットアップに集約した。旧見出しから該当箇所へ進む。

[検証記録](verification/wireguard.md)・[参考資料](reference/wireguard.md)・[ロールバックと注意点](extra/wireguard.md)

## 実施手順

- [AlmaLinux 10 の「WireGuard: 実施手順」](almalinux-setup.md#wireguard-実施手順)

### site.env を作る

- [AlmaLinux 10 の「WireGuard: site.env を作る」](almalinux-setup.md#wireguard-siteenv-を作る)

### 鍵を作って適用する

- [AlmaLinux 10 の「WireGuard: 鍵を作って適用する」](almalinux-setup.md#wireguard-鍵を作って適用する)

### クライアントを登録する

- [AlmaLinux 10 の「WireGuard: クライアントを登録する」](almalinux-setup.md#wireguard-クライアントを登録する)

### 状態と疎通を確かめる

- [AlmaLinux 10 の「WireGuard: 状態と疎通を確かめる」](almalinux-setup.md#wireguard-状態と疎通を確かめる)

## AlmaLinux 10 の PC からつなぐ

- [AlmaLinux 10 の「WireGuard: AlmaLinux 10 の PC からつなぐ」](almalinux-setup.md#wireguard-almalinux-10-の-pc-からつなぐ)

### 鍵を作る

- [AlmaLinux 10 の「WireGuard: 鍵を作る」](almalinux-setup.md#wireguard-鍵を作る)

### WG ホストに登録する

- [AlmaLinux 10 の「WireGuard: WG ホストに登録する」](almalinux-setup.md#wireguard-wg-ホストに登録する)

### conf を取り込む

- [AlmaLinux 10 の「WireGuard: conf を取り込む」](almalinux-setup.md#wireguard-conf-を取り込む)

### トンネルを確かめる

- [AlmaLinux 10 の「WireGuard: トンネルを確かめる」](almalinux-setup.md#wireguard-トンネルを確かめる)

## Windows 11 で使う

- [Windows 11 の「WireGuard: Windows 11 で使う」](windows-setup.md#wireguard-windows-11-で使う)

### Windows 11 で WireGuard と鍵を用意する

- [Windows 11 の「WireGuard: Windows 11 で WireGuard と鍵を用意する」](windows-setup.md#wireguard-windows-11-で-wireguard-と鍵を用意する)

### Windows 11 で WG ホストに登録して取り込む

- [Windows 11 の「WireGuard: Windows 11 で WG ホストに登録して取り込む」](windows-setup.md#wireguard-windows-11-で-wg-ホストに登録して取り込む)

### Windows 11 でトンネルを確かめる

- [Windows 11 の「WireGuard: Windows 11 でトンネルを確かめる」](windows-setup.md#wireguard-windows-11-でトンネルを確かめる)

## Windows 11 の更新

- [Windows 11 の「WireGuard: Windows 11 の更新」](windows-setup.md#wireguard-windows-11-の更新)

## 回線に合わせて MTU を下げる（任意）

- [AlmaLinux 10 の「WireGuard: 回線に合わせて MTU を下げる（任意）」](almalinux-setup.md#wireguard-回線に合わせて-mtu-を下げる任意)

## クライアントを削除する

- [AlmaLinux 10 の「WireGuard: クライアントを削除する」](almalinux-setup.md#wireguard-クライアントを削除する)

## バックアップと復旧（OS の再インストール）

- [AlmaLinux 10 の「WireGuard: バックアップと復旧（OS の再インストール）」](almalinux-setup.md#wireguard-バックアップと復旧os-の再インストール)

## 落とし穴: `apply` は作業中の ssh 経路そのものを切る

- [AlmaLinux 10 の「WireGuard: 落とし穴: `apply` は作業中の ssh 経路そのものを切る」](almalinux-setup.md#wireguard-落とし穴-apply-は作業中の-ssh-経路そのものを切る)

## site.env に書く値

- [AlmaLinux 10 の「WireGuard: site.env に書く値」](almalinux-setup.md#wireguard-siteenv-に書く値)
