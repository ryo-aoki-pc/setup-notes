# Grok Build をブラウザから操作する手順（Codeg / AlmaLinux 10 は systemd のユーザーサービス / Windows 11 はタスク スケジューラ / LAN・VPN 内で使う）の参考資料

[手順書](../grok-build-remote.md)・[ロールバックと注意点](../extra/grok-build-remote.md)・[検証記録](../verification/grok-build-remote.md)

## 補足

### 実施手順 / Codeg のサーバーを入れて localhost で起動する / 手順 1: 補足: 変数

- `SERVER_IP` は、Codeg が待ち受ける IP と、firewalld の規則の宛先の両方に使う
- `ALLOW_FROM` は送信元 IPv4 の CIDR。WG ホスト自身で動かすときは、VPN のクライアントの通信が `wg0` から入り、送信元はクライアントの VPN のアドレスになる
- ポートは Codeg の既定の 3080 のまま使う。変数にしていない
- `FW_ZONE` は自動で入る

### 実施手順 / Codeg のサーバーを入れて localhost で起動する / 手順 3: 補足: SHA-256 の照合

- `.sha256` は、配布物と同じリリースに置かれたファイル。取得の途中で壊れたものは見つけられるが、リリースそのものが書き換えられた場合は見つけられない
- GitHub のリリースの画面と API は、配布物ごとの digest（`sha256:…`）を出す。検証では、その値とも一致することを確かめた
- リリースには `.sig`（署名）もある。検証のしかたは公式の文書に無く、本書では使っていない
- 公式のインストーラー（`install.ps1`）は、SHA-256 を照合しない（スクリプトを読んで確かめた）。`install.sh` は読んでいない
- `tar -tzf … | grep -c` は、展開先を外れるパス（`/` で始まるもの、`..` を含むもの）の数を出す

### 実施手順 / Codeg のサーバーを入れて localhost で起動する / 手順 4: 補足: 置き場所

- 公式のインストーラーは、実行ファイルを `/usr/local/bin`、画面のファイルを `/usr/local/share/codeg/web` に置く。本書は `sudo` を使わず、ホームの `~/.local/opt/codeg-server` にまとめる
- `codeg-mcp` は、`codeg-server` と同じディレクトリに置く（Codeg は既定で隣を探す。`CODEG_MCP_BIN` で変えられる）
- `codeg-computer-helper` は、サーバーのデスクトップを操作させる機能（`CODEG_COMPUTER_USE`）の部品。その機能を使わないので置かない

### 実施手順 / Codeg のサーバーを入れて localhost で起動する / 手順 6: 補足: ユニットの各行

- `EnvironmentFile` は必須にしてある（`-` を付けない）。トークンのファイルが無ければ起動に失敗し、Codeg がトークンを自分で作ることは無い
- `Environment=PATH=` は、`~/.grok/bin` を足すため。systemd のユーザーの環境の PATH は `/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin` で、`grok` が見つからない
- `CODEG_BRIDGE_PORTS=off` は、プロジェクトの開発サーバーを中継するための追加のポート（既定は 3081〜3090）を開けない設定
- `CODEG_BROWSER_TUNNEL=off` は、Codeg のデスクトップアプリをつないだときに、そのアプリの内蔵ブラウザがサーバー経由で届く範囲を無くす設定（既定は `all`）
- `--supervise` は、画面から Codeg を入れ替えたときに、起動に失敗した版を前の版へ戻す仕組み（公式の文書）。本書の更新は画面を使わないが、公式の起動のしかたに合わせた
- `StandardError=null` は、起動のたびに標準エラーへ出るトークンを journal に残さないため。Codeg のログは、別に `~/.local/share/codeg/logs/` に出る
- `Restart=on-failure` と `RestartSec=5` は、起動の時点で `SERVER_IP` がまだ付いていないときに、待ってやり直すため

### 実施手順 / Codeg のサーバーを入れて localhost で起動する / 手順 7: 補足: トークンを引数に書かない

- `curl -K -` は、設定を標準入力から読む。`printf` は bash の組み込みなので、トークンがどのプロセスの引数にもならない
- `grep -cFf <(…)` は、探す文字列をファイル（プロセス置換）から読む

### 実施手順 / ブラウザで開いて Grok を動かす / 手順 4: 補足: 権限モードと config.toml の値

- Codeg の「権限モード」を保存すると、`~/.grok/config.toml` の `[ui]` の `permission_mode` が書き換わる。ほかの行は変わらなかった
- 「毎回確認」は `"default"`、「常に許可」は `"bypassPermissions"` と書かれた。Grok Build の文書では、`"always-approve"` と `"bypassPermissions"` は同じモード
- Codeg は、「常に許可」のとき `--permission-mode bypassPermissions` を付けて Grok Build を起動し、「毎回確認」のときは付けなかった
- Grok Build の文書では、既定（ask）で確認なしに動くのは、読み取り専用のツールと、決まった読み取り専用のコマンドだけ。`mkdir` はその一覧に無いが、検証では確認なしで実行された

### 実施手順 / ブラウザで開いて Grok を動かす / 手順 5: 補足: 最初の会話のモデル

- Codeg を起動して最初の会話は、モデルの欄が Grok 4.6 で、Grok Build のセッションの記録（`events.jsonl`）の `modelId` も `grok-4.6` だった。同じ時点の `grok models` の既定は `grok-4.7`
- Codeg の Issue に、Grok の ACP の接続で、後から届くモデルの一覧が反映されない不具合の報告がある（#876。2026-10-02 に閉じられている）。同じ原因かは確かめていない

### 実施手順 / VPN に公開する / 手順 1・2: 補足: 規則と待ち受け

- 規則は、[Forgejo](../forgejo.md) と同じ形（送信元・宛先・ポートを絞った rich rule）。zone の既定の拒否はそのままで、指定した送信元だけを通す
- 待ち受けを `SERVER_IP` だけにするのは、ほかの NIC のアドレスで待ち受けないため。規則と二重に絞る
- サーバー自身から `SERVER_IP` へつなぐ通信は、firewalld の規則にかからない

### Windows 11 で使う / Windows 11 で Codeg のサーバーを入れて起動する / 手順 6・7: 補足: スクリプトとタスク

- 環境変数を利用者の環境（レジストリ）に入れると、すべてのプロセスにトークンが渡る。起動用のスクリプトの中だけで設定する
- スクリプトは ASCII で書く。Windows PowerShell 5.1 は、BOM の無いスクリプトを既定のコードページで読む
- タスクは、管理者ではない窓から、ログオン時のトリガー付きで登録できた。`-RunLevel Limited` で、Codeg はデスクトップのセッションの、管理者ではない権限で動く
- `-WindowStyle Hidden` で、窓を隠して起動する。標準エラーに出るトークンは、ファイルにも journal にも残らない

### Windows 11 で使う / Windows 11 で VPN に公開する / 手順 1: 補足: 規則

- `-Program` で `codeg-server.exe` 宛てに限る。同じ PC のほかのプログラムが 3080 番で待ち受けても、この規則では通らない
- `-Profile Private` は、LAN の接続がプライベートであることを前提にする
- VPN のクライアントの通信は、WG ホストが LAN へ転送する。PC から見た送信元は、クライアントの VPN のアドレスだった

## 方法のまとめ

Grok Build を、離れた場所からデスクトップアプリかブラウザで操作する方法を比べた（2026-10-11 時点）。「この手順書」の列が「採った」のものを、手順書で手順にした。

| 目的 | 方法 | この手順書 | 要るもの・制約 |
|---|---|---|---|
| 画面から Grok Build を動かす | Codeg のサーバー（`codeg-server`）を同じホストに置き、ブラウザで開く | 採った | Apache-2.0。Grok は内蔵の対応エージェント。Linux の x64・arm64 と Windows の x64 の配布物がある。外部のサーバーを通らない。通信は HTTP |
| 画面から Grok Build を動かす | Paseo のデーモンを同じホストに置く | 採らない（Codeg が動かなかったときの代わりとして調べた） | Apache-2.0。Grok は ACP のカタログの扱い。Windows で端末のコマンドの引用が壊れる不具合の報告（#5947）がある。実機では試していない |
| 画面から Grok Build を動かす | Grok UI | 採らない | MIT。Grok Build 専用だが、Windows と aarch64 の対応が文書に無い。個人の小規模なプロジェクト |
| 画面から Grok Build を動かす | Happier | 採らない | MIT。Web の画面に HTTPS が必須。プッシュ通知が第三者（Expo）を通る。Grok ではセッションの一覧が使えない |
| 画面から Grok Build を動かす | Zed の外部エージェント（SSH のリモート） | 採らない | PC のデスクトップアプリだけ。スマートフォンから使えない |
| 画面から Grok Build を動かす | Grok Build の `grok agent serve` に直接つなぐ | 採らない | つなぎ方の仕様が公式の文書に無い。公式の例は always-approve 付き |
| 端末をそのまま使う | SSH のアプリと tmux | 採らない（[共同作業の手順書](../coding-agents.md#スマートフォンから指示する)にある） | 画面で扱いたい、という目的に合わない。AlmaLinux 10 だけ |
| 端末をそのまま使う | ttyd などの Web の端末 | 採らない | 端末がそのままブラウザに出る。スマートフォンで Ctrl・Esc・矢印が打ちにくい |
| 端末をそのまま使う | zellij の Web クライアント | 採らない | Windows 版に未解決の不具合がある（[Claude Code の Remote Control（Windows）の検証記録](../verification/windows-claude-remote-control.md)） |
| Codeg の置き方 | 配布物を取得して SHA-256 を照合し、ホームに置く | 採った | 版を決めて入れる。`sudo` を使わない |
| Codeg の置き方 | 公式のインストーラー（`curl … \| bash`・`irm … \| iex`） | 採らない | SHA-256 を照合しない。`/usr/local` に置く（Linux） |
| Codeg の置き方 | 公式の Docker イメージ | 採らない | コンテナの中で動くので、ホストの Grok Build のログイン・Git・道具をそのまま使えない |
| Codeg の置き方（Windows 11） | Codeg のデスクトップアプリの「Web サービス」 | 採らない | すべての NIC で待ち受ける。待ち受ける IP を選べない |
| 常駐（AlmaLinux 10） | systemd のユーザーサービスと linger | 採った | Codeg はユニットを同梱しない |
| 常駐（Windows 11） | タスク スケジューラ（サインイン中、管理者ではない権限） | 採った | SSH のセッションから始めると管理者の権限で動くので、タスクにした |
| つなぐ側 | ブラウザ | 採った | スマートフォンと PC で同じ画面 |
| つなぐ側 | Codeg のデスクトップアプリ（リモートのワークスペース） | 採らない（確かめていない） | Windows の署名が無い。サーバーの `CODEG_BROWSER_TUNNEL` を見直す必要がある |
| つなぐ側 | Codeg の Android のアプリ | 採らない（確かめていない） | Apache-2.0。APK を GitHub から入れる。testing の段階 |
| 経路 | WireGuard の内側だけに開ける | 採った | 構築済みの VPN を使う。送信元をクライアントの帯に絞る |
| 経路 | リバースプロキシで TLS を足す | 採らない | 証明書の配布が要る。VPN の区間は暗号化されている |
| 経路 | インターネットへ公開する | 採らない | トークン 1 つが、ホストでコマンドを実行できる鍵になる |

## 選択した方針

- Grok Build には、Claude Code の Remote Control に当たる公式の遠隔操作の画面が無い。Grok Build は ACP（Agent Client Protocol）のエージェントとして動かせる（`grok agent stdio`）ので、ACP で Grok Build を動かす OSS の画面を、Grok Build と同じホストに置く
- 画面は、端末をそのまま映すものではなく、会話・承認・変更されたファイルを扱うチャット形式のものにする（利用者の指定）
- Codeg は、Grok Build 自身のセッションの置き場（`~/.grok/sessions`）を使う。端末の `grok` で始めた会話を取り込めて、Codeg で作った会話は `grok sessions list` に出る
- 既存の Grok Build（`~/.grok/bin/grok`）とログインをそのまま使う。Codeg からは Grok Build を入れ替えない
- まず localhost で起動して確かめ、それから待ち受ける IP と送信元を絞って公開する（[Forgejo](../forgejo.md) と同じ順）
- トークンは、エージェントに作らせず・読ませず、利用者が作る。確認は、値を表示しないコマンドで行う
- 承認を自動で通す設定は、離れた場所から使うなら勧めない。ただし、確認が出ることを安全の境界にはしない（`mkdir` は確認なしで実行された）
- 両 OS を 1 本の手順書にまとめ、Windows 11 は後ろの節に置く（[Syncthing](../syncthing.md) と同じ形）

## 参照

- [spacering-net/codeg](https://github.com/spacering-net/codeg)（Codeg。Apache-2.0）
- [Codeg: Supported Agents](https://docs.codeg.app/guide/supported-agents)・[Working with Agents](https://docs.codeg.app/guide/agents)
- [Codeg: Deployment](https://docs.codeg.app/getting-started/deployment)・[Configuration](https://docs.codeg.app/getting-started/configuration)・[Installation](https://docs.codeg.app/getting-started/installation)・[Privacy & Security](https://docs.codeg.app/reference/privacy)
- [Codeg の Issue #436](https://github.com/spacering-net/codeg/issues/436)（Grok の拒否の規則と sandbox が、Codeg の下で効かなかった報告）・[#876](https://github.com/spacering-net/codeg/issues/876)（Grok のモデルの一覧）
- [xai-org/grok-build](https://github.com/xai-org/grok-build)（Grok Build。Apache-2.0）
- Grok Build の同梱の文書（`~/.grok/docs/user-guide/`）: `15-agent-mode.md`（ACP）・`22-permissions-and-safety.md`（権限モード）
- [Agent Client Protocol](https://agentclientprotocol.com)
- [getpaseo/paseo](https://github.com/getpaseo/paseo)・[joeynyc/Grok-UI](https://github.com/joeynyc/Grok-UI)・[Happier の Grok 対応](https://docs.happier.dev/agents/grok)・[Zed の外部エージェント](https://zed.dev/docs/ai/external-agents)（比べた候補）
