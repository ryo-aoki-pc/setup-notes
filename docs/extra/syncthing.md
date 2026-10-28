# Syncthing の注意点

[手順書](../syncthing.md#syncthing)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/syncthing.md)・[参考資料](../reference/syncthing.md)

- 「手順 N」は[手順書](../syncthing.md#syncthing)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## 注意点

- **自分では更新しない**: Homebrew の formula は `--no-upgrade` でビルドしている（バージョン文字列の `noupgrade`）
  - 公式 tarball 版のような自己アップグレードは働かないので、`brew upgrade` で追う
  - **`brew upgrade` だけでは動いているプロセスが古いまま**なので、`brew services restart` まで行う
- **linger を切ると止まる**: `loginctl disable-linger` すると、ログアウトした時点で同期が止まる。止まっていること自体は GUI を開くまで気付きにくい
- **公開範囲は public ゾーンの全 NIC**: この環境では `wg0` も public にあるので、**VPN 越しの拠点からも 22000 と 8384 に届く**
  - 同期には好都合だが、GUI まで届くことは意識しておく。絞るなら[接続元を絞る](../syncthing.md#syncthing-接続元を絞る)
- **GUI の認証は必須**: LAN に開く構成なので、認証を設定しないまま待ち受けを広げると誰でも全設定を触れる。本書は手順 3〜4（認証）→ 手順 6（公開）→ 手順 7（firewalld）の順にしてある
- **証明書は自己署名**: ブラウザの警告は消えない。警告を無視する運用に慣れると本物の異常を見逃すので、常用するなら例外として明示的に登録する
- **GUI に入れる人は、Syncthing を動かすユーザーのファイルを読み書きできる**: Syncthing はそのユーザーとして動き、GUI からフォルダを足せる。GUI のパスワードは、OS のパスワードと同じ重みで扱う
- **API キーはパスワードと同じ重み**: `config.xml`（Windows 11 では `%LOCALAPPDATA%\Syncthing\config.xml`）にあり、これ 1 つで GUI の全操作ができる。ログや issue に貼らない
- **設定と DB は `~/.local/state/syncthing`**: 1.27.0 以降の既定
  - 戻すのに要るのは `cert.pem` / `key.pem`（失うとデバイス ID が変わる）と `config.xml`。DB（`index-v2`）は作り直せる
  - 自動で取っておくなら[設定を自動でバックアップする](../syncthing.md#syncthing-設定を自動でバックアップする)、戻すなら[バックアップから戻す](../syncthing.md#syncthing-バックアップから戻す)
- **2.x は DB 形式が 1.x と違う**: 2.0 で LevelDB から SQLite に変わり、1.x から上げると初回起動時に移行が走る（大きな構成では時間がかかる）
  - 上げる前に設定ディレクトリごと退避し、移行後の DB をそのまま 1.x に戻さない
  - 他のホストの 1.x から移すなら、上げる前に設定ディレクトリごと退避しておく
- **QUIC の受信バッファについて警告が出る**: 起動時に `failed to sufficiently increase receive buffer size (was: 208 kiB, wanted: 7168 kiB, got: 416 kiB)` と出る
  - 動作はする。消すなら `net.core.rmem_max` を上げる（本書では触っていない）
- **ホームを丸ごと同期しない**: `~/.local/state/syncthing`（Windows 11 では `AppData\Local\Syncthing`）自身やキャッシュまで対象になる。このホストは [Samba](../samba.md#samba-サーバー) でホームを公開しているので、同じ領域を二重に扱うことにもなる
- **Windows 11 の注意点**
  - **パブリックのネットワークでは、直接はつながりにくい**: 規則はプライベートだけで有効。持ち出した先の Wi-Fi や、パブリックになっている VPN（WireGuard のトンネルの接続など）では、相手とはリレー（Syncthing のリレーのサーバー）経由になることが多い。外向きの接続だけでも同期はできる
  - **サインアウトとスリープの間は止まる**: タスクはサインインしている間だけ動く。スリープの間も同期しない。止まっている間の変更は、次に動いたときに同期される
  - **短い間に何度も起動し直さない**: 子のプロセスが 60 秒の間に 4 回起動すると、親はあきらめて終わる（[Windows 11 で使う](../syncthing.md#windows-11-で-syncthing-を使う)の手順 9 の補足）
  - **タスクの状態では、動いているかは分からない**: タスクを終了しても本体は止まらず、自動の更新の後はタスクの外で動く。止めるのは [Windows 11 で止める・もう一度始める](../syncthing.md#syncthing-windows-11-で止めるもう一度始める)の手順 2、確かめるのはプロセス
  - **Windows で使えない名前のファイル**: 相手（AlmaLinux 10 など）にある、`:` や `?` などを含む名前や、大文字と小文字だけが違う名前のファイルは、Windows では同期できない。Syncthing の GUI で同期できなかったファイルを確認する
  - **24H2 より前の Windows**: `syncthing.exe` に入っている「コンソールの窓を作らない」設定が効かず、タスクから起動したときにコンソールの窓が一瞬出て、`--no-console` で隠れるはず
  - **設定とログの場所**: `%LOCALAPPDATA%\Syncthing`（設定・鍵・DB・`syncthing.log`）。戻すのに要るのは `cert.pem` / `key.pem`（失うとデバイス ID が変わる）と `config.xml`
