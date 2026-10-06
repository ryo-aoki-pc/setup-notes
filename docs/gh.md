# GitHub CLI（gh）インストール手順（AlmaLinux 10 / 公式 dnf リポジトリ）

## 実施手順

- [検証記録](verification/gh.md)・[参考資料](reference/gh.md)

> [!IMPORTANT]
> - **すべて対象ホスト上で実行する**。手順 4 の認証だけブラウザで行う
> - **手順 2 と手順 3 には対話入力がある**（手順 2 は署名鍵の取り込みの確認が 2 回、手順 3 は `gh auth login` の対話）。手順 3 は、手順 4 のブラウザでの認証を終えてから次の手順を貼る

- 上から順にコードブロックを貼る
- 手順の後: 以後は[更新](#更新)・[ロールバック](#ロールバック)

1. `dnf config-manager` を使えるようにし、リポジトリを追加する。

   ```bash
   {
     sudo dnf install -y 'dnf-command(config-manager)'
     sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
     cat /etc/yum.repos.d/gh-cli.repo
   }
   ```

   - AlmaLinux 10 の dnf は 4 系（dnf5 ではない）なので、この後の手順も dnf4 の構文を使う（参考資料を参照）
   - `Adding repo from: ...` と出て、`/etc/yum.repos.d/gh-cli.repo` ができる
   - `gpgcheck=1` になっていることを確認する

1. gh をインストールする。

   ```bash
   sudo dnf install gh
   ```

   - 初回は署名鍵の取り込みを **2 回**聞かれる（鍵が 2 本ある）
   - fingerprint が次の 2 つであることを目で確かめてから `y` と答える
     - `7F38 BBB5 9D06 4DBC B3D8 4D72 5612 B364 6231 3325`
     - `2C61 0620 1985 B60E 6C7A C873 23F3 D4EA 7571 6059`
   - どちらも Userid は `GitHub CLI <opensource+cli@github.com>`。違っていれば `N` で中断する
   - **次の手順は、答えてから貼る**（続けて貼ると答えとして食われる）

1. GitHub へのログインを始める。

   ```bash
   gh auth login
   ```

   - 対話で GitHub.com / HTTPS / ブラウザ認証を選ぶ
   - ワンタイムコードが表示されたら、手順 4 のブラウザで使う
   - **トークン（`gh auth token` の出力）や、認証中に表示されるワンタイムコードはこの文書に載せない**

1. ブラウザで、GitHub の認証を済ませる。

   - 手順 3 のワンタイムコードを、ブラウザの `https://github.com/login/device` に入れ、画面の案内に従う
   - SSH 越しの端末でこのホストのブラウザを開けないときは、手元のブラウザで開く
   - **次の手順は、`gh auth login` が終わってから貼る**（続けて貼ると対話の答えとして食われる）

1. 認証できたか確かめる。

   ```bash
   gh auth status
   gh --version
   ```

   - 認証前の `gh auth status` は `You are not logged into any GitHub hosts.` を返す

---

## 更新

- 通常の `dnf upgrade` に含まれる

1. gh だけを上げるときは、パッケージを指定して更新する。

   ```bash
   sudo dnf upgrade gh
   ```

---

## ロールバック

- パッケージを消すだけでは、設定と保存された認証情報は残る。認証も外すなら、gh を消す前にこの節の手順 1 を行う
- GitHub 側でトークンも無効にする場合だけ、この節の手順 2 を行う

> [!WARNING]
> **この節の手順 2 は、ほかの端末を含め、GitHub CLI が生成した認証トークンをすべて失効させる。** このホストから認証情報を消すだけなら、手順 1 だけでよい。

1. このホストの認証情報も外すときだけ、ローカルからログアウトする。

   ```bash
   gh auth logout
   ```

   - 対話でホストとアカウントを選び、確認に答える
   - OS の資格情報ストアまたは gh の設定から、このアカウントの保存された認証情報を外す。GitHub 側のトークンは失効しない
   - `~/.config/gh` に残る設定も不要なら、ログアウト後に手で消す。ディレクトリを消すだけでは、資格情報ストアのトークンは消せない
   - **次の手順は、`gh auth logout` が終わってから行う**（続けて貼ると対話の答えとして食われる）

1. 全端末の GitHub CLI のトークンも失効させるときだけ、ブラウザで GitHub の認可を取り消す。

   - `https://github.com/settings/applications` を開き、「Authorized OAuth Apps」の「GitHub CLI」→「Revoke Access」→「I understand, revoke access」で取り消す
   - 本書のブラウザ認証で作ったトークンが対象。ほかの端末も、次に使うときに認証し直す
   - 本書の手順とは別に作った PAT を使っている場合は、その PAT の設定から取り消す

1. gh を消す。

   ```bash
   sudo dnf remove gh
   ```

   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. repo ファイルを消す。

   ```bash
   sudo rm -f /etc/yum.repos.d/gh-cli.repo
   ```

1. 鍵も消すときだけ、署名鍵を消す。

   ```bash
   sudo rpm -e gpg-pubkey-62313325-69d4e1f8 gpg-pubkey-75716059-63172e8a   # 鍵も消す場合
   ```

---

## 注意点

- **EPEL と公式リポジトリが両方有効だと、更新のたびに両者を比較する**: バージョンが高い公式側が選ばれるので、実害は無い
  - EPEL 側だけを使いたいなら、`exclude=gh` を `gh-cli` 側に書くか、リポジトリを無効にする
- **トークンの置き場所**: OS の資格情報ストアを優先し、使えない場合は `~/.config/gh/hosts.yml` に平文で保存する。保存先は `gh auth status` で確認し、平文ファイルをバックアップや共有に混ぜない
  - `gh auth logout` はローカルの認証情報を外す。GitHub 側のトークンの失効は別の操作（[ロールバック](#ロールバック)の手順 2）
- **`gh` は git を呼ぶ**: `gh repo clone` などは git に依存する。最小構成のホストでは git 一式が付いてくる
- **全アーキ共通リポジトリ**: `dnf list gh` に `i386` / `armv6hl` の行が出るのは正常
