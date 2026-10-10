# Syncthing インストール手順（AlmaLinux 10 は Homebrew + systemd ユーザーサービス / Windows 11 は公式の zip + タスク スケジューラ）のロールバックと注意点

[手順書](../syncthing.md)・[検証記録](../verification/syncthing.md)・[参考資料](../reference/syncthing.md)

- 「手順 N」は[手順書](../syncthing.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- AlmaLinux 10 の手順。Windows 11 は [Windows 11 のロールバック](#windows-11-のロールバック)
- 上から順に実行する
- 接続元を絞る節を使った場合は `syncthing-gui` ではなく rich rule が入っているので、先に[接続元を絞る（任意）](../syncthing.md#接続元を絞る任意)の手順 2 を貼る
- 自動バックアップを設定した場合は、Syncthing が動いているうちに、先に[設定を自動でバックアップする（任意）](../syncthing.md#設定を自動でバックアップする任意)の手順 7 を貼る
- 同期していたファイル自体は、この節のどの手順でも消えない
- linger も切るときは、この節の後に [linger.md のロールバック](linger.md#ロールバック)を行う（ほかに linger を使うものが無いかは、そこで確かめる）

> [!CAUTION]
> **この節の**手順 3 で設定・鍵・DB を**消すとデバイス ID が失われ、相手デバイスからは別のデバイスとして見える**。入れ直す可能性があるなら残すか、自動バックアップのアーカイブ（`~/syncthing-backup`）を取っておく（[バックアップから戻す](../syncthing.md#バックアップから戻す)で同じデバイス ID に戻せる）。

1. サービスを止めて、Syncthing を消す。

   ```bash
   brew services stop syncthing
   brew uninstall syncthing
   ```

   - Syncthing を動かしていたユーザー自身のシェルで貼る（Homebrew の削除・サービス管理も、そのユーザーで行う）
   - `brew services stop` は停止に加えて**自動起動の登録も外す**（`brew services --help` の「unregister it from launching at login」）
   - 設定・鍵・DB（`~/.local/state/syncthing`）とログ（`/home/linuxbrew/.linuxbrew/var/log/syncthing.log`）は残る

1. ファイアウォールの設定を外す。

   ```bash
   sudo firewall-cmd --permanent --remove-service=syncthing --remove-service=syncthing-gui && sudo firewall-cmd --reload
   ```

1. 完全に消すときだけ、設定・鍵・DB とログを消す（取り戻せない）。

   ```bash
   rm -rf ~/.local/state/syncthing /home/linuxbrew/.linuxbrew/var/log/syncthing.log
   ```

   - 自動バックアップのアーカイブ（`~/syncthing-backup`）は消えない

---

## Windows 11 のロールバック

- 上から順に、管理者の Windows PowerShell（5.1）に貼る（変数は使わない）。この節の手順 4 は Windows 11 の初期設定のロールバックで行う
- 同期していたファイル自体は、この節のどの手順でも消えない（同期したフォルダーの `.stfolder` も残る）

> [!CAUTION]
> **この節の手順 5 で、鍵・設定・DB（`%LOCALAPPDATA%\Syncthing`）を消すと、デバイス ID が失われる**。入れ直すと、相手からは別のデバイスとして見える。入れ直すかもしれないなら、手順 5 は行わない（手順 1〜4 だけなら、入れ直したときに同じデバイス ID に戻る）。

1. Syncthing を止め、タスクを消す。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   if (Get-Process -Name syncthing -ErrorAction SilentlyContinue) {
     & $exe cli operations shutdown
     for ($i = 0; $i -lt 30 -and (Get-Process -Name syncthing -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
   }
   Unregister-ScheduledTask -TaskName 'Syncthing' -Confirm:$false -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Process -Name syncthing -ErrorAction SilentlyContinue | Format-Table Id
   Get-ScheduledTask -TaskName 'Syncthing' -ErrorAction SilentlyContinue
   ```

   - 最後の 2 つが何も出さなければよい

1. 受信の規則を消す（警告の窓が作った規則も）。

   ```powershell
   Remove-NetFirewallRule -Group 'Syncthing (setup-notes)' -ErrorAction SilentlyContinue
   Get-NetFirewallApplicationFilter | Where-Object Program -like '*\Programs\Syncthing\syncthing.exe' | Get-NetFirewallRule | Remove-NetFirewallRule
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-NetFirewallApplicationFilter | Where-Object Program -like '*\Programs\Syncthing\syncthing.exe'
   ```

   - 最後のコマンドが何も出さなければよい（数秒かかる）

1. 実行ファイルを消す。

   ```powershell
   Remove-Item -LiteralPath "$env:LOCALAPPDATA\Programs\Syncthing" -Recurse -Force
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Test-Path "$env:LOCALAPPDATA\Programs\Syncthing"
   ```

   - `False` が出ればよい（`syncthing.exe.old` も消える）

1. LAN の接続をパブリックに戻すときだけ、[Windows 11 の初期設定のロールバック](windows-setup.md#ロールバック)の手順 33 を行う。

   - [Windows の OpenSSH サーバー](../windows-openssh-server.md)やリモート デスクトップをこの LAN で使っているなら、戻さない（パブリックにすると SSH も届かなくなる）

1. 完全に消すときだけ、鍵・設定・DB・ログを消す（取り戻せない）。

   ```powershell
   Remove-Item -LiteralPath "$env:LOCALAPPDATA\Syncthing" -Recurse -Force
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Test-Path "$env:LOCALAPPDATA\Syncthing"
   ```

   - `False` が出ればよい

---

## 注意点

- **自分では更新しない**: Homebrew の formula は `--no-upgrade` でビルドしている（バージョン文字列の `noupgrade`）
  - 公式 tarball 版のような自己アップグレードは働かないので、`brew upgrade` で追う
  - **`brew upgrade` だけでは動いているプロセスが古いまま**なので、`brew services restart` まで行う
- **linger を切ると止まる**: `loginctl disable-linger` すると、ログアウトした時点で同期が止まる。止まっていること自体は GUI を開くまで気付きにくい
- **公開範囲は public ゾーンの全 NIC**: この環境では `wg0` も public にあるので、**VPN 越しの拠点からも 22000 と 8384 に届く**
  - 同期には好都合だが、GUI まで届くことは意識しておく。絞るなら[接続元を絞る（任意）](../syncthing.md#接続元を絞る任意)
- **GUI の認証は必須**: LAN に開く構成なので、認証を設定しないまま待ち受けを広げると誰でも全設定を触れる。本書は手順 3〜4（認証）→ 手順 6（公開）→ 手順 7（firewalld）の順にしてある
- **証明書は自己署名**: ブラウザの警告は消えない。警告を無視する運用に慣れると本物の異常を見逃すので、常用するなら例外として明示的に登録する
- **GUI に入れる人は、Syncthing を動かすユーザーのファイルを読み書きできる**: Syncthing はそのユーザーとして動き、GUI からフォルダを足せる。GUI のパスワードは、OS のパスワードと同じ重みで扱う
- **API キーはパスワードと同じ重み**: `config.xml`（Windows 11 では `%LOCALAPPDATA%\Syncthing\config.xml`）にあり、これ 1 つで GUI の全操作ができる。ログや issue に貼らない
- **設定と DB は `~/.local/state/syncthing`**: 1.27.0 以降の既定
  - 戻すのに要るのは `cert.pem` / `key.pem`（失うとデバイス ID が変わる）と `config.xml`。DB（`index-v2`）は作り直せる
  - 自動で取っておくなら[設定を自動でバックアップする（任意）](../syncthing.md#設定を自動でバックアップする任意)、戻すなら[バックアップから戻す](../syncthing.md#バックアップから戻す)
- **2.x は DB 形式が 1.x と違う**: 2.0 で LevelDB から SQLite に変わり、1.x から上げると初回起動時に移行が走る（大きな構成では時間がかかる）
  - 上げる前に設定ディレクトリごと退避し、移行後の DB をそのまま 1.x に戻さない
  - 他のホストの 1.x から移すなら、上げる前に設定ディレクトリごと退避しておく
- **QUIC の受信バッファについて警告が出る**: 起動時に `failed to sufficiently increase receive buffer size (was: 208 kiB, wanted: 7168 kiB, got: 416 kiB)` と出る
  - 動作はする。消すなら `net.core.rmem_max` を上げる（本書では触っていない）
- **ホームを丸ごと同期しない**: `~/.local/state/syncthing`（Windows 11 では `AppData\Local\Syncthing`）自身やキャッシュまで対象になる。このホストは [Samba](../samba.md) でホームを公開しているので、同じ領域を二重に扱うことにもなる
- **Windows 11 の注意点**
  - **パブリックのネットワークでは、直接はつながりにくい**: 規則はプライベートだけで有効。持ち出した先の Wi-Fi や、パブリックになっている VPN（WireGuard のトンネルの接続など）では、相手とはリレー（Syncthing のリレーのサーバー）経由になることが多い。外向きの接続だけでも同期はできる
  - **サインアウトとスリープの間は止まる**: タスクはサインインしている間だけ動く。スリープの間も同期しない。止まっている間の変更は、次に動いたときに同期される
  - **短い間に何度も起動し直さない**: 子のプロセスが 60 秒の間に 4 回起動すると、親はあきらめて終わる（[Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 9 の補足）
  - **タスクの状態では、動いているかは分からない**: タスクを終了しても本体は止まらず、自動の更新の後はタスクの外で動く。止めるのは [Windows 11 で止める・もう一度始める](../syncthing.md#windows-11-で止めるもう一度始める)の手順 1、確かめるのはプロセス
  - **Windows で使えない名前のファイル**: 相手（AlmaLinux 10 など）にある、`:` や `?` などを含む名前や、大文字と小文字だけが違う名前のファイルは、Windows では同期できない。Syncthing の GUI で同期できなかったファイルを確認する
  - **24H2 より前の Windows**: `syncthing.exe` に入っている「コンソールの窓を作らない」設定が効かず、タスクから起動したときにコンソールの窓が一瞬出て、`--no-console` で隠れるはず
  - **設定とログの場所**: `%LOCALAPPDATA%\Syncthing`（設定・鍵・DB・`syncthing.log`）。戻すのに要るのは `cert.pem` / `key.pem`（失うとデバイス ID が変わる）と `config.xml`
