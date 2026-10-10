# ShellCheck / shfmt インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

- [検証記録](verification/shellcheck.md)・[参考資料](reference/shellcheck.md)・[ロールバックと注意点](extra/shellcheck.md)

> [!IMPORTANT]
> - **前提**: [AlmaLinux 10 の初期設定の手順 46〜48](almalinux-setup.md#実施手順) で Homebrew を入れてあること。`command -v brew` で何も出なければ、先に通す
> - **前提**: 手順 5 の JSON 集計には `jq` が要る。`command -v jq` で何も出なければ、[導入元一覧の jq](tool-catalog.md#cli-定番の置き換え) を先に入れる
> - **自分のシェルで実行する**。Homebrew の導入・管理は一般ユーザーで行う
> - **手順 2 で Homebrew の確認が出る場合がある**。答えて導入が完了してから手順 3 を貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 手順の後: 整形は[shfmt で整形を確かめる（任意）](#shfmt-で整形を確かめる任意)、警告の抑制は[検査を調整する（任意）](#検査を調整する任意)。以後は[更新](#更新)・[ロールバック](extra/shellcheck.md#ロールバック)

1. 変数を設定する（`SC_TARGET` は必ず値を入れる）。

   ```bash
   SC_TARGET=scripts/wireguard/wg-vpn.sh   # 検査するスクリプト。自分のパスに変える。<SC_TARGET>
   ```

   ```bash
   SC_SEVERITY=style        # -S に渡す最低重大度。style だと全部出る。error / warning / info / style。<SC_SEVERITY>
   SHFMT_INDENT=2           # shfmt -i のインデント幅。0 ならタブ。<SHFMT_INDENT>
   for v in SC_TARGET SC_SEVERITY SHFMT_INDENT; do printf '%-13s = %s\n' "$v" "${!v}"; done
   ```

   - **編集が必須なのは、検査対象のパス `SC_TARGET` だけ**。自分のリポジトリのスクリプトに変える
   - 残りは既定のままでよい
   - 最後に値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先に手順 1 の 2 つのブロックを貼り直す

1. ShellCheck と shfmt を入れる。

   ```bash
   brew install shellcheck shfmt
   ```

   - **次の手順は、Homebrew の確認が出たら答え、導入が成功してプロンプトに戻ってから貼る**（続けて貼ると確認の答えとして食われる）

1. 2 つが入ったか確かめ、わざと欠陥のあるコードで検出できるかを見る。

   ```bash
   shellcheck --version
   shfmt --version
   command -v shellcheck shfmt
   brew list --versions shellcheck shfmt
   printf '#!/bin/bash\nx=$(ls)\necho $x\n' | shellcheck -
   echo "rc=$?"
   printf '#!/bin/bash\nif true; then\necho a\nfi\n' | shfmt -i 2 -d -
   echo "rc=$?"
   ```

   - `version: 0.11.0` と `3.14.1` が出る
   - ShellCheck は `SC2086 (info): Double quote to prevent globbing and word splitting.` が 1 件出て **`rc=1`** になる
   - shfmt は字下げを足す差分が出て `rc=1` になる

1. スクリプトを、bash の構文チェックと ShellCheck で検査する。

   ```bash
   bash -n "${SC_TARGET:?手順 1 の SC_TARGET が空のまま。値を入れて貼り直す}"
   echo "rc=$?"
   shellcheck -x "${SC_TARGET}"
   echo "rc=$?"
   ```

   - 1 つ目の `rc=0` なら構文としては通っている
   - **警告が 0 件なら何も出ずに `rc=0` で終わる**

1. 件数だけ見たいときと、重大度で絞りたいときは、JSON で数えて `-S` で絞る。

   ```bash
   if [ -z "${SC_TARGET}" ] || [ -z "${SC_SEVERITY}" ]; then
     echo '中断: 手順 1 の SC_TARGET と SC_SEVERITY を設定してから貼り直す' >&2
   elif ! command -v jq >/dev/null 2>&1; then
     echo '中断: jq が無い。リードの導入元一覧から入れて貼り直す' >&2
   else
     shellcheck -x -f json "${SC_TARGET}" | jq 'length'
     shellcheck -x -f json "${SC_TARGET}" | jq -r '.[] | "\(.level) \(.code)"' | sort | uniq -c | sort -rn
     shellcheck -x -S "${SC_SEVERITY}" "${SC_TARGET}" | head -20
   fi
   ```

---

## shfmt で整形を確かめる（任意）

- **`-d` は差分を出すだけでファイルを変えない**

> [!WARNING]
> **`-w` は元のファイルを上書きする。** いきなり本番のスクリプトに掛けない。**この節の**手順 2 は、一時ディレクトリの複製に掛けて挙動を見る。

1. 今の書き方とどれだけ違うかを見て、整形対象になるファイルを一覧する。

   ```bash
   if [ -z "${SC_TARGET}" ] || [ -z "${SHFMT_INDENT}" ]; then
     echo '中断: 手順 1 の SC_TARGET と SHFMT_INDENT を設定してから貼り直す' >&2
   else
     shfmt -i "${SHFMT_INDENT}" -d "${SC_TARGET}" | wc -l
     shfmt -i "${SHFMT_INDENT}" -d "${SC_TARGET}" | head -30
     shfmt -f "$(dirname -- "${SC_TARGET}")" | head
     shfmt -l -i "${SHFMT_INDENT}" "$(dirname -- "${SC_TARGET}")"
   fi
   ```

1. 一時ディレクトリに複製して、`-w` の挙動を見る。

   ```bash
   SHFMT_TMP=$(mktemp -d)
   cp "${SC_TARGET}" "${SHFMT_TMP}/copy.sh"
   shfmt -i "${SHFMT_INDENT}" -w "${SHFMT_TMP}/copy.sh"
   diff <(wc -l < "${SC_TARGET}") <(wc -l < "${SHFMT_TMP}/copy.sh")
   rm -rf "${SHFMT_TMP}"
   ```

   - 行数がどれだけ増減するかが出る
   - **差分が大きいときは、そのスクリプトの書き方と shfmt の既定が合っていない**（[検証記録](verification/shellcheck.md)・[参考資料](reference/shellcheck.md)の shfmt の項を見る）

---

## 検査を調整する（任意）

1. 1 行だけ黙らせるディレクティブの例を、検査対象の中から探す。

   ```bash
   grep -n 'shellcheck disable' "${SC_TARGET}"
   ```

   - **1 行だけ黙らせる**には、その行の直前にディレクティブを置く
   - `# shellcheck disable=SC1090` のような行が出る
   - 複数まとめるならカンマ区切り（`disable=SC2086,SC2034`）

1. リポジトリ全体に効かせるときは、`.shellcheckrc` の挙動を一時ディレクトリで確かめる。

   ```bash
   SC_TMP=$(mktemp -d)
   cp "${SC_TARGET}" "${SC_TMP}/target.sh"
   printf 'disable=SC2034\nexternal-sources=true\nsource-path=SCRIPTDIR\n' > "${SC_TMP}/.shellcheckrc"
   (cd "${SC_TMP}" && shellcheck -x target.sh; echo "rc=$?")
   rm -rf "${SC_TMP}"
   ```

   - **リポジトリ全体に効かせる**なら `.shellcheckrc` を置く
   - `disable` に挙げたコードが消えて `rc` が変わる

---

## 更新

1. ShellCheck と shfmt を上げる。

   ```bash
   brew upgrade shellcheck shfmt
   ```

   - すべてまとめて上げるなら `brew upgrade`
   - **ほかのコマンドは、Homebrew の確認が出たら答え、更新が終わってから貼る**（続けて貼ると確認の答えとして食われる）
