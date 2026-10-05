# AlmaLinux 10 のクリーンインストールからの環境構築の検証（2026-10-06）

## 状態と対象

**状態**: **AlmaLinux 10.2 の x86_64 VM で本実行した記録。実機・aarch64・Windows の構築手順の検証ではない**。

公式 ISO から Workstation を新規インストールし、その状態のスナップショットから用途ごとの VM を作った。既に環境構築済みのホストを使い回さず、各 VM で前提の手順書から順に通した。導入・設定・CLI / GUI の確認と、サーバー間の通信を対象にした。アカウントの認証が必要な手順、ハードウェアの条件を満たさない分岐、実機のルーター設定は、到達したところと未実施の範囲を分けて記録する。

この文書は検証結果の一覧。実行するときは、リンク先の手順書を使う。手順書ごとの状態・警告・付録にも、今回の検証範囲を反映した。

検証開始時の手順書は [`0dbb522` 版](https://github.com/ryo-aoki-pc/setup-notes/tree/0dbb522)。この検証で直したブロックは再実行した。その後に上流へ入った共通 bash 設定への統一（#93）、lazydocker の実機検証・改良（#94）、starship の常時表示の任意節（#95）は保持したが、変更後の手順を今回の VM で通し直したわけではない。該当する付録の手順番号は検証した版を指す。共通 bash 設定の新規導入・移行と、追加された任意節は今回の範囲外。

## 環境と開始時点

| 項目 | 実際の検証環境 |
|---|---|
| ホスト | Windows 11、VirtualBox 7.2.20。Hyper-V の NEM バックエンド |
| ISO | [公式配布](https://repo.almalinux.org/almalinux/10/isos/x86_64/)の `AlmaLinux-10-latest-x86_64-boot.iso`。取得時点では 10.2 |
| SHA256 | `b3f865468075bcada8f208d830289302c67529789d668041d24e8d6fc697ba6a`。公式 CHECKSUM と照合 |
| ゲスト | AlmaLinux 10.2 (Lavender Lion)、kernel `6.12.0-211.61.1.el10_2.x86_64` |
| インストール | 公式 BaseOS / AppStream を使う Kickstart、`@^workstation-product-environment`、XFS / LVM、96 GiB の仮想ディスク |
| VM | UEFI、1 vCPU、KVM の準仮想化、VMSVGA。通常 6 GiB、オフライン用 4 GiB RAM |
| セキュリティ | SELinux Enforcing、firewalld 有効。Secure Boot は無効 |
| ロケール | `ja_JP.UTF-8`、US キーボード、Asia/Tokyo、UTC のハードウェア時計 |
| ネットワーク | SSH 用 NAT と、VM 間の内部ネットワーク `10.77.0.0/24`。オフライン用は NAT の既定経路を無効にした |

SSH の操作用に、試験用ユーザー、専用の鍵、sshd、sudo の設定だけをインストール時に追加した。sudo の通常の実行は NOPASSWD だが、Homebrew インストーラの認証は VM 専用のパスワードで答えた。利用者の実アカウントのトークン・SSH 鍵・Dropbox の認証情報は持ち込んでいない。対話入力や GUI の初回案内の確認を自動インストール済みとは扱わない。

開始時点で Homebrew、Podman、EPEL の追加ツール、個人用の設定は無かった。Workstation に含まれる Git、curl、procps-ng、file、bash-completion、fontconfig、gnupg2、ibus-anthy、cifs-utils、gvfs などは既に入っていた。既存のパッケージを確認して飛ばす手順は、本文の条件に従って飛ばした。linger は `no` だった。

ベース VM を停止して `clean-install` スナップショットを取り、CLI、デスクトップ、サーバー、コンテナ、オフラインの検証用 VM をリンククローンとして作った。サーバー / コンテナの 2 台は Samba、Syncthing、WireGuard の通信相手にも使った。オフライン試験は、経路設定の問題を切り分けた後、同じスナップショットからもう 1 台作って取り直した。

VM の準備では、VirtualBox の無人インストールの生成物に Kickstart の起動引数が入らず、起動メニューで止まった。ISO のメニューが `linuxefi` を使うことを確認し、検証用の GRUB 設定に `inst.ks` とシリアルコンソール・テキストモードの引数を直接追加して通した。準仮想化を `none` にした試行は `IO-APIC + timer doesn't work!` でカーネルが停止したため、KVM に戻してインストール・起動を完了した。この観測を、別のホストの CPU 数や設定でも必ず失敗するという意味には扱わない。

## 通した手順と結果

### 導入基盤・CLI

| 手順書 | 今回の範囲と結果 |
|---|---|
| [Git](git.md) | 導入・設定・一時リポジトリの操作。認証を伴う GitHub への送信は除外 |
| [Homebrew](homebrew.md) / [EPEL](epel.md) | 新規導入、PATH と導入元の確認。インストーラの Return / sudo / パッケージ導入の問い合わせにも答えた |
| [gh](gh.md) / [Claude Code](claude-code.md) / [Codex CLI](codex.md) | 導入・版・未ログインの確認まで。Codex はインストーラの再実行で 0.160.0 → 0.160.1 の更新も確認。実アカウントへのログインと認証後の操作は除外 |
| [btop](btop.md) / [tmux](tmux.md) / [bat](bat.md) / [eza](eza.md) / [gdu](gdu.md) | 導入と実行。TUI は文字を読み取り、キーの応答と終了を確認 |
| [zoxide](zoxide.md) / [fzf](fzf.md) | bash の設定を読み直し、移動・履歴・ファイル・ディレクトリ選択を実際に操作 |
| [yazi](yazi.md) / [lazygit](lazygit.md) / [Neovim](neovim.md) / [delta](git-delta.md) | 導入と対話操作。yazi の追加ツールは本文の既定を全て導入し、ディレクトリ移動・ZIP プレビューも確認。Neovim の checkhealth はエラー無し、任意 provider などの警告 8 件。delta のページャと複数の変更間の n / N の移動も成功 |
| [ShellCheck](shellcheck.md) / [HackGen Console NF](hackgen.md) / [bash の設定](bash-settings.md) / [starship](starship.md) | 導入・設定・読み戻し。ShellCheck で WG スクリプトを検査し、フォントの 4 字種、Tab・履歴・移動、再 SSH 後のプロンプトも確認 |

### デスクトップ

| 手順書 | 今回の範囲と結果 |
|---|---|
| [電源とロック](gnome-power.md) | ユーザー・GDM・OS の設定を実行して読み戻し。Workstation の自動サスペンドを止めた |
| [ヘッドレスのセッション](gnome-headless-session.md) / [GUI の操作](claude-code-gui.md) | セッションと仮想モニターを作り、画面を撮影。電卓への入力とクリックを確認。GUI 構成を戻した後の再起動でも 1920×1080 の撮影・入力・クリックが成功 |
| [日本語入力](japanese-input.md) | Anthy を有効にして実際に日本語を確定。Mutter のキーコード入力で `日本語` を確認。既存スクリプトの keysym によるローマ字入力は別の制限として記録 |
| [RPM Fusion](rpmfusion.md) / [Firefox](firefox.md) | リポジトリ・Firefox・FFmpeg の導入。H.264 / AAC の動画を表示し、復号フレームの増加を確認。音声の実出力と GPU デコードは未確認 |
| [Flatpak](flatpak.md) / [VS Code](vscode.md) | 導入と実ウィンドウの起動。VS Code の desktop ファイルの確認方法を修正。Flatseal は Activities と CLI 検索で見えるが、GNOME Software の検索では表示されなかった |
| [WezTerm nightly](wezterm-nightly.md) | COPR の EL9 RPM を EL10 に導入、依存を確認して実ウィンドウを起動 |
| [GNOME Remote Desktop](gnome-remote-desktop.md) | 別 VM の FreeRDP から 3390 の既存セッションと 3389 の GDM に接続。新規セッション・再接続・既存セッションへの引き渡し、再起動後の接続と LAN の接続元制限も確認 |

ヘッドレスの RDP 接続から、電卓に `12×34` を入力し `408` を確認した画面:

![FreeRDP クライアントから操作した GNOME の電卓](images/almalinux-vm/rdp-calculator.png)

デスクトップ VM の再起動後は、GDM → システムの GNOME Remote Desktop の順に起動し、`GetManagedObjects` の警告は無かった。3389 の GDM からヘッドレスのセッションへ引き渡し、電卓の `9×9 = 81` を確認した。切断して 3390 へ直接接続しても同じ表示が残った。これは Linux の FreeRDP クライアントでの確認で、Windows の「リモートデスクトップ接続」は今回使っていない。

### サーバー・ネットワーク

| 手順書 | 今回の範囲と結果 |
|---|---|
| [linger](linger.md) | 有効化、解除、再有効化。ユーザーサービスの前提として使用 |
| [Samba](samba.md) | 共有の作成と認証、ホームと root の任意共有、SELinux Enforcing での読み書き |
| [Samba クライアント](samba-client.md) | 別 VM から CIFS の手動マウント、読み書き、資格情報の権限、fstab / automount。再起動・未使用時の解除・再アクセスと、GNOME Files の接続・F5・切断も確認 |
| [Syncthing](syncthing.md) | 2 台への導入・ユーザーサービス・GUI の設定、日本語名ファイルの双方向同期、バックアップ 8 個の一致と設定の復元。TLS 設定の応答が切れる問題を修正 |
| [WireGuard](wireguard.md) | 2 台で鍵生成・apply、カーネルの WireGuard と firewalld を使用。各 LAN を模した namespace 間で双方向 ICMP、MTU 1420、TCP / HTTP を確認 |
| [WireGuard Road Warrior](wireguard-road-warrior.md) | 別 VM で鍵生成、ホストでクライアント追加、NetworkManager への import、切断と接続。実機の回線切り替えは除外 |

WireGuard の拠点間通信には VM の内部ネットワークを使った。家庭のルーターのポート転送、外部の回線からの接続、実際の LAN に置いた機器は今回の検証に含まれない。

サーバー VM の再起動では、ユーザーの systemd、Syncthing、設定バックアップの path / timer、WireGuard、Samba が SSH の再ログインより前に自動起動した。Syncthing の両フォルダーは `idle` / 未受信 0 件で、相手との直接 TCP 接続も戻った。

Samba とクライアント、Syncthing のロールバックも実行した。初めから入っていた cifs-utils / gvfs は残し、今回作った共有・受信規則・資格情報・fstab の行・Syncthing の現行設定とサービスを片付けた。Syncthing の保存済みバックアップは保管した。WireGuard は backup → remove / purge → restore / apply で鍵の一致と 0600 の復元、再起動後の通信も確認した。

### コンテナ・オフライン導入

| 手順書 | 今回の範囲と結果 |
|---|---|
| [Podman](podman.md) | 実施手順 1〜3・5〜7、API、Docker 向けの節、Quadlet。subuid / subgid は既存のため補う分岐は飛ばした |
| [podman-compose](podman-compose.md) | 実施手順 1〜6。公開ポートとサービス名で HTTP が返り、`:Z` のラベルとカテゴリも一致 |
| [Distrobox](distrobox.md) | 実施手順 1〜6。Ubuntu 24.04.5 の初期化と入退場。pids の読み替えは不要 |
| [hadolint / dive / Trivy](image-tools.md) | 実施手順 1〜10。意図した lint エラー、イメージのビルド、dive の判定・画面操作、Trivy の DB 取得と走査 |
| [podman-tui](podman-tui.md) / [lazydocker](lazydocker.md) | 各実施手順 1〜5。実際のコンテナを画面から停止し、CLI でも停止を確認 |
| [Dropbox](dropbox.md) | 実施手順 1〜7。署名の検証、新規導入、ユーザーサービス、リンク用 URL の表示まで。アカウント未リンク |
| [Dropbox（rclone）](dropbox-rclone.md) | 導入と OAuth 待ち受けまで。ブラウザで許可する前に中断。同期は未実施 |
| [ssh の SOCKS トンネル](ssh-socks-tunnel.md) / [Homebrew のオフライン導入](homebrew-offline.md) / [npm のオフライン導入](npm-offline.md) | 既定経路の無い VM と Windows の OpenSSH を使用。Homebrew の新規導入、jq、dnf、Node.js / npm、Mason の範囲は各付録に記録 |
| [VirtualBox](virtualbox.md) / [Secure Boot の MOK](secure-boot-mok.md) | ゲストに仮想化支援が見えず、Secure Boot も無効。本文の条件に従って止めた。入れ子の VM 起動と MOK 登録は未実施 |

コンテナ用 VM の再起動では、Quadlet の Web サーバーが最初の SSH ログインより前に起動し、HTTP 応答も戻った。Podman の API ソケットと未リンクの Dropbox サービスも active だった。一方、Compose の例と Distrobox は自動起動を設定していないため、停止したままだった。

[VirtualBox の bootc ゲスト](virtualbox-guest-bootc.md)は、AlmaLinux Atomic Desktop を作る別の構築手順で、今回の Workstation のクリーンインストール試験には含めていない。導入元一覧の手順書が無いツールも、一括してインストールしたわけではない。

## 見つかった問題と切り分け

| 問題 | 原因・対応と確認 |
|---|---|
| `wg-vpn.sh apply` が終了 141 | `pipefail` の下で、IP の一覧を読む awk が最初の一致で終了し、上流の `ip` が SIGPIPE になった。修正前は 1,000 回中 117 回失敗。awk が最後まで読み、最初の一致を END で出す形に修正。修正後 1,000 回すべて成功、`bash -n` / ShellCheck と apply・通信も成功 |
| Syncthing の TLS を有効にする CLI が `EOF` | 設定値は `true` になったが、CLI が終了 1 になり、後ろの `&&` の処理まで進まなかった。GUI の待ち受け切り替えに伴う応答中断と推定。設定の読み戻しと短い再試行を足し、設定が意図した値か確かめる形へ修正 |
| VS Code の `code*.desktop` が見つからない | 配布 RPM の名前が `com.microsoft.VSCode*.desktop` に変わっていた。固定の glob ではなく RPM のファイル一覧から確認する形へ修正して再実行 |
| GNOME RDP の firewalld 確認が終了 253 | SSH の一般ユーザーからの `firewall-cmd --list-services` が polkit の認可に失敗した。確認コマンドにも `sudo` を付けて再実行 |
| GNOME Software で Flatseal を検索できない | Activities と `flatpak search`、実ウィンドウの起動は成功した。GNOME Software 47.5 は AppStream の更新と再起動後も `NoAppFound`。原因は特定できておらず、GUI の検索まで成功とは扱わない |
| GUI の初回起動にフォーカスが移らない / 電卓が間に合わない | クリーン状態では初回の案内とアクティビティ画面があり、1 vCPU のソフトウェア描画では起動に約 18 秒かかった。案内を閉じ、実際に窓が出てから操作する必要があった |
| Distrobox の入場時に brew が見つからない | ホストのホームと `.bashrc` が共有されるが、ボックスに Homebrew の prefix は無い。エラーの後もシェルとコマンドは動いた。導入失敗とは区別して記録 |
| オフライン試験中に直接通信が復活 | `ip route del` だけでは、NetworkManager の DHCP / RA が既定経路を復元した。試験環境側の問題。新しいクリーン VM で `ipv4.never-default=yes` / `ipv6.method=disabled` を設定し、再起動後の経路と直接通信の失敗を確認して取り直した |

GUI 用のキー注入では、既存の `NotifyKeyboardKeysym` で送るローマ字が Anthy に期待どおり届かなかった。一方、同じセッションで `NotifyKeyboardKeycode` による入力では `日本語` を確定できた。日本語入力の OS 設定の結果と、操作スクリプトの制限を分けた。スクリプト本体の入力方式は変更していない。

![検証用 GNOME セッションの WezTerm で日本語を確定した画面](images/almalinux-vm/japanese-input.png)

## 記録の取り方と残る範囲

本文のコードブロックを読み、折り畳みの補足と Windows の節を除いて、SSH の対話の bash に貼った。問い合わせは終わってから次のブロックを実行した。主にブラケットペーストを使ったため、今回だけでブラケットペースト無しのすべての手順を保証するものではない。TUI は擬似端末の文字とキー応答、GUI は GNOME の ScreenCast / RemoteDesktop と PNG で確認した。

検証の補助として、専用の SSH / 端末ドライバ、内部ネットワーク、WireGuard の LAN を模す namespace、オフライン用 NetworkManager 設定を使った。手順書の代わりのコマンド、設定値を変えた箇所、認証前で止めた箇所は各付録に書いた。スタブでサービスやカーネルを置き換えて成功とはしていない。

生ログ、端末画面、PNG、インストールメディア、試験用の認証情報は `.verification/` に置き、Git の追跡対象から除外した。仮想ディスクは Windows の一時ディレクトリに置いた。認証 URL・パスワード・鍵の値は手順書に転載しない。

検証の終了時に、ベースとクローンの計 7 台をすべて停止した。SSH トンネル、FreeRDP、Xvfb と検証用の補助プロセスも終了した。ログと VM は確認用に保管し、仮想ディスクの保存先は `%LOCALAPPDATA%\Temp\setup-notes-vm-verification-20261006`。

今回の範囲外は、実機と aarch64、デュアルブート、Windows の各構築手順、実アカウントへのログイン・クラウドとの同期、家庭のルーター・テザリング・Wi-Fi / サスペンド復帰、Secure Boot の鍵登録、VM 内への VirtualBox の導入。個人用設定の別リポジトリの導入、全ツールを 1 台にまとめた併用状態、すべての任意節・更新・ロールバックも一括して検証済みとは扱わない。各手順書の付録に、通した手順と残る範囲を示した。
