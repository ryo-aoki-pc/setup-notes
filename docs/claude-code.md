# Claude Code インストール手順（AlmaLinux 10 / 公式 dnf リポジトリ）

## 実施手順

> [!IMPORTANT]
> - **すべて対象ホスト上で実行する**。手順 5 の認証だけブラウザを使う
> - **手順 3 には対話入力がある**（署名鍵の取り込みの確認）。そのブロックだけ続けて貼らない

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 以後は[更新](#更新)・[ロールバック](#ロールバック)

1. **変数を設定する**

   - **編集が必須の変数は無い**。既定の `stable`（1 週間ほど遅れて、大きな不具合のある版を飛ばすチャンネル）でよければ、そのまま貼る
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

   ```bash
   CC_CHANNEL=stable               # 追従するチャンネル。stable（約 1 週間遅れ）か latest（即時）。<CC_CHANNEL>
   ```

   **値を読み戻して確かめる。**

   ```bash
   printf 'CC_CHANNEL = %s\n' "${CC_CHANNEL}"
   ```

   - `stable` か `latest` 以外が入っていたら、ここで止めて直す

   <details>
   <summary>補足: 変数について</summary>

   - `CC_CHANNEL` は `baseurl` の末尾に埋まるだけなので、後から変えるときは repo ファイルを書き直して `sudo dnf upgrade claude-code`（または `distro-sync`）する
   - ネイティブインストーラ版にある `autoUpdatesChannel` / `minimumVersion` の設定は dnf 版では効かない（更新を行うのが dnf のため）

   </details>

1. **リポジトリを追加する**

   ```bash
   sudo tee /etc/yum.repos.d/claude-code.repo >/dev/null <<EOF
   [claude-code]
   name=Claude Code
   baseurl=https://downloads.claude.ai/claude-code/rpm/${CC_CHANNEL:?手順 1 の CC_CHANNEL が空のまま。値を入れて貼り直す}
   enabled=1
   gpgcheck=1
   gpgkey=https://downloads.claude.ai/keys/claude-code.asc
   EOF
   cat /etc/yum.repos.d/claude-code.repo
   ```

   - `baseurl` の末尾が `stable` か `latest` になっていることを確認する

   <details>
   <summary>補足: チャンネルは baseurl で決まる</summary>

   この手順のヒアドキュメントだけ `<<EOF`（クォート無し）にしてある。`${CC_CHANNEL}` を展開して `baseurl` に埋めるため。

   公式ドキュメントの dnf 向けの例と同じ形。実機に置いてあるファイルは次のとおり:

   ```
   [claude-code]
   name=Claude Code
   baseurl=https://downloads.claude.ai/claude-code/rpm/stable
   enabled=1
   gpgcheck=1
   gpgkey=https://downloads.claude.ai/keys/claude-code.asc
   ```

   `repo_gpgcheck` は書かない（既定の 0）。パッケージ自体の署名は `gpgcheck=1` で検証される。

   </details>

1. **インストールする**

   ```bash
   sudo dnf install claude-code
   ```

   初回は署名鍵の取り込みを聞かれる。

   - 表示される fingerprint が `31DD DE24 DDFA B679 F42D 7BD2 BAA9 29FF 1A7E CACE` であることを**目で確かめてから** `y` と答える
   - 違っていれば `N` で中断する

   **次のブロックは、答えてから貼る**（続けて貼ると答えとして食われる）。

   <details>
   <summary>補足: 鍵の取り込み</summary>

   `dnf install` の途中で鍵の取り込みを聞かれる。実測（コンテナ、`-y` 付きで流したときの表示）:

   ```
   claude-code-2.1.267-1.aarch64.rpm                18 MB/s |  93 MB     00:05
   Importing GPG key 0x1A7ECACE:
    Fingerprint: 31DD DE24 DDFA B679 F42D 7BD2 BAA9 29FF 1A7E CACE
    From       : https://downloads.claude.ai/keys/claude-code.asc
   Key imported successfully
   ```

   この fingerprint は公式ドキュメントに載っているものと一致する。同じ鍵が apt / apk のリポジトリとリリースの `manifest.json` の署名にも使われている。

   依存は `glibc >= 2.17` だけ（`rpm -q --requires claude-code`）なので、デスクトップ系のパッケージは一切付いてこない。

   </details>

1. **検証する**

   ```bash
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' claude-code
   claude --version
   rpm -ql claude-code
   ```

   - `2.1.267 (Claude Code)` のようにバージョンが出れば入っている
   - 入るファイルは実行ファイル 1 つとライセンスだけ（[完了時点の状態](#完了時点の状態)）
   - Node.js は要らない

1. **認証する**

   作業したいディレクトリに `cd` してから、引数無しで `claude` を起動する。画面の案内に従ってブラウザでログインする。

   - Pro / Max / Team / Enterprise か Console のアカウントが要る（無料の claude.ai プランでは使えない）
   - `ANTHROPIC_API_KEY` を設定している場合は、ブラウザではなくその鍵を使ってよいか 1 度だけ聞かれる
   - **認証情報（トークン・API キー）はこの文書に載せない**

   <details>
   <summary>補足: 認証</summary>

   `claude` を引数無しで起動すると、ブラウザでのログインに進む。SSH 越しなど、そのホストでブラウザを開けない場合は、表示される URL を手元のブラウザで開いてコードを貼る形になる。**この手順はコンテナでは実行していない**（実機では認証済みで常用している）。

   認証後の状態は `claude doctor` で確認できる（インストールの健全性、設定ファイルの検証エラー、更新の結果を表示する読み取り専用の診断）。本書では未実行。

   </details>

---

## 更新

**dnf で入れた Claude Code は自動更新しない。** 通常の `dnf upgrade` に含まれるほか、単体で上げるなら:

```bash
sudo dnf upgrade claude-code
```

- 起動中に新しい版が出ると Claude Code が更新を知らせてくるが、dnf 版は自分で更新できない（root 権限が要るため）
- リポジトリ側にその版が届くまで、少し遅れることもある

---

## ロールバック

```bash
sudo dnf remove claude-code
sudo rm -f /etc/yum.repos.d/claude-code.repo
sudo rpm -e gpg-pubkey-1a7ecace-69caef70          # 鍵も消す場合
```

- 設定・履歴（`~/.claude/`、`~/.claude.json`、プロジェクト側の `.claude/`、`.mcp.json`）は残る

> [!CAUTION]
> 設定・履歴のファイルを消すと、設定・許可済みツール・MCP サーバー定義・セッション履歴がすべて消える。消す前に中身を確認する。

- 本書ではロールバックは**本実行していない**

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 に [Claude Code](https://code.claude.com/docs/) の CLI を **dnf 管理で**入れ、`dnf upgrade` で追従できるようにする
- **進め方**: Anthropic が公式に配っている RPM リポジトリを 1 つ足して `dnf install` する。**読者が書き換えるのは冒頭の変数ブロック（チャンネル）だけ**。npm も Node.js も使わない
- **状態**: **実機で本実行済み（2026-09-20）**
  - 下表のホストに `stable` チャンネルの repo ファイルを置いて `dnf install claude-code` し、`claude-code-2.1.267-1.aarch64` が入っている
  - 認証も済んでいて常用中（**この文書自体、そのホストの Claude Code で書いている**）
  - 本書の手順 2〜4 は 2026-09-22 に同じ OS のコンテナで通し直し、鍵の fingerprint 表示・同じ版の導入・`claude --version` まで確認した
  - **コンテナでは認証（手順 5）とロールバックは実行していない**
  - **`latest` チャンネルは未検証**

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-09-20 | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| カーネル | 6.12.96 | ホストと同じ |
| dnf | 4.20.0 | 4.20.0 |
| チャンネル | `stable` | `stable` |
| 入った Claude Code | `claude-code-2.1.267-1.aarch64`（93 MB / 展開後 207 MB） | 同じ（`2.1.267-1`） |
| Node.js | 未導入（`node` / `npm` 無し。dnf 版は不要） | 未導入 |
| 認証 | 済み（常用中） | 未実施 |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${CC_CHANNEL}` | 追従するチャンネル。`baseurl` の末尾になる | `stable` / `latest` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`2.1.267`）は実行日によって変わる。`<作業したいディレクトリ>` のような `<...>` を含むコマンドは bash のコードブロックに置いていない。
>
> **API キー・OAuth トークン・認証時のコードは書かない。** 鍵の fingerprint は公開情報なので本文に書いてある。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| Claude Code | 未導入（`claude` 無し、`~/.claude` も無し） |
| Node.js / npm | 未導入。`nodejs` は appstream に 22.23.2 があるが入れていない |
| 有効な追加リポジトリ | epel、crb、raspberrypi、gh-cli（claude-code はまだ無し） |
| `~/.local/bin` | PATH には入っているがディレクトリは未作成 |

### 選択した方針

Linux に Claude Code を入れる経路は 3 つある（2026-09-22 時点の[公式ドキュメント](https://code.claude.com/docs/en/setup)）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **公式 dnf リポジトリ** | `downloads.claude.ai/claude-code/rpm/{stable,latest}`。aarch64 の RPM があり、署名鍵で検証される。更新は `dnf upgrade`（**自動更新はしない**） | **採用**（他のツールと同じ dnf 管理に揃う） |
| ネイティブインストーラ（`curl -fsSL https://claude.ai/install.sh \| bash`） | `~/.local/bin/claude` に入り、**バックグラウンドで自動更新する**。root 不要。ただし更新経路が dnf の外になり、`~/.local/share/claude/versions/` に版が積まれる | 不採用（自動更新が要るなら有力） |
| npm（`npm install -g @anthropic-ai/claude-code`） | Node.js 22 以上が要る。このホストに Node.js は無く、そのために入れることになる。中身は同じネイティブバイナリ | 不採用 |

- どれを選んでも入るのは同じネイティブバイナリで、Node.js は実行時に使わない
- `ripgrep` は同梱されている（Alpine など musl 系以外では別途入れなくてよい）

**`stable` と `latest` の違い**:

- `stable` は 1 週間ほど遅れて、大きな不具合のある版を飛ばす
- `latest` は出た版をすぐ配る
- リポジトリが別 URL になっているだけで、切り替えは `baseurl` の書き換え（手順 2 をやり直す）

### 完了時点の状態

```
$ dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' claude-code
claude-code 2.1.267-1 claude-code
$ claude --version
2.1.267 (Claude Code)
$ rpm -ql claude-code
/usr/bin/claude
/usr/share/doc/claude-code/copyright
$ rpm -q --requires claude-code
glibc >= 2.17
$ rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i anthropic
gpg-pubkey-1a7ecace-69caef70 Anthropic Claude Code Release Signing <security@anthropic.com> public key
```

- 認証すると `~/.claude/`（設定・セッション履歴）と `~/.claude.json` ができる
- プロジェクト側の設定は `.claude/` と `.mcp.json`

### 注意点

- **自動更新しない**: ネイティブインストーラ版と違い、dnf 版は自分では更新しない
  - `CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE=1` は Homebrew / WinGet 向けで、apt / dnf / apk は root 権限が要るため対象外
- **更新の通知が先に来ることがある**: リポジトリに新しい版が届く前に「更新がある」と言われることがある。その場合は時間をおいて `sudo dnf upgrade claude-code`
- **`claude` が 2 つ入ると混乱する**: ネイティブインストーラや npm で入れたものが `~/.local/bin/claude` にあると、PATH の順序でそちらが勝つ。`command -v claude` と `claude doctor` で確認する
- **アカウントが要る**: 無料の claude.ai プランでは使えない
- **設定ファイルは残る**: `dnf remove` しても `~/.claude` は消えない

### 参照

- [Advanced setup — Claude Code Docs](https://code.claude.com/docs/en/setup) — dnf / apt / apk リポジトリの設定、チャンネル、アンインストール、署名の検証
- [Troubleshoot installation and login — Claude Code Docs](https://code.claude.com/docs/en/troubleshoot-install) — インストールが失敗したときの切り分け
- `man dnf.conf`（`gpgcheck`、`baseurl`）

---

### 付録: コンテナでの検証記録（2026-09-22）

`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで手順 2〜4 を通した。実機で加えた変更は `dnf install podman` だけ。 最後にもう 1 つ新しいコンテナを立て、**この文書のコードブロックをそのまま抜き出したスクリプト**（`sudo` を外し、`dnf install` / `dnf upgrade` に `-y` を付けただけ）を流して、上から順に貼れば通ることを確かめている。

| 手順 | 結果 |
|---|---|
| 2. repo | `tee` で作成。`dnf` がメタデータ（9.8 kB）を取得できた |
| 3. install | `dnf install --assumeno claude-code` → `Installing: claude-code aarch64 2.1.267-1 claude-code 93 M / Installed size: 207 M`、依存パッケージ無し。本実行では鍵の fingerprint `31DD DE24 ... 1A7E CACE` が表示され `Key imported successfully` |
| 4. 検証 | `claude --version` → `2.1.267 (Claude Code)`。`rpm -ql` は `/usr/bin/claude` と copyright の 2 ファイル |

実機（2026-09-20 に `stable` チャンネルで導入）と同じ `2.1.267-1` が入った。

#### 未確認事項

- 手順 5 の認証（コンテナでは未実施。実機では 2026-09-20 に実行して以後常用）
- `latest` チャンネルの動作と、`stable` との切り替え（`baseurl` を書き換えたときの `dnf upgrade` / `distro-sync` の挙動）
- `claude doctor` の出力
- ロールバック（`dnf remove` と鍵の削除）の本実行
- ネイティブインストーラ版・npm 版との併存時の優先順位（`~/.local/bin/claude` が PATH の先にある場合）
