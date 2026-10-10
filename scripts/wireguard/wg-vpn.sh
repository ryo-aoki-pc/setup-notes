#!/usr/bin/env bash
# WireGuard 拠点間 VPN と、そこへのリモートクライアント追加
# （docs/wireguard.md）の手順を site.env の値で実行する。
#
#   sudo ./wg-vpn.sh [options] keygen [A|B]          「鍵を作って適用する」の手順 1: wireguard-tools 導入と鍵生成
#   sudo ./wg-vpn.sh [options] apply  A|B            「鍵を作って適用する」の手順 4〜5: wg0.conf・sysctl・firewalld・サービス（旧レイアウトの専用ゾーンと policy が残っていれば消す）
#        ./wg-vpn.sh [options] router A|B            ルーターに入れる値を表示（apply の末尾と同じ。補足「ルーターの設定」）
#   sudo ./wg-vpn.sh [options] status                「状態と疎通を確かめる」の手順 1: 状態確認
#   sudo ./wg-vpn.sh [options] remove A|B            ロールバック
#   sudo ./wg-vpn.sh [options] client add A|B NAME   「クライアントを登録する」の手順 1〜2: クライアントを登録し、鍵とクライアント用 conf を生成する
#   sudo ./wg-vpn.sh [options] client remove NAME    クライアントの登録とクライアント用 conf を削除する
#   sudo ./wg-vpn.sh [options] client show NAME      クライアント用 conf を表示する
#        ./wg-vpn.sh [options] client list           登録済みクライアントを表示する（root なら最終ハンドシェイクも）
#   client add / remove の後は、その拠点で apply を実行してホストに反映する。
#
#   sudo ./wg-vpn.sh [options] backup  [A|B]         鍵・site.env・clients.list を tar.gz に退避する
#   sudo ./wg-vpn.sh [options] restore FILE          退避したものを元の場所に戻す
#   クリーンインストール後は restore してから apply すると、同じ鍵のまま復旧できる
#   （相手拠点の設定とクライアント端末の conf は変更不要）。
#
# options:
#   -e, --env FILE          設定ファイル（既定: スクリプトと同じディレクトリの site.env）
#   -n, --dry-run           変更せず、実行予定の内容だけを表示する
#   --use-existing-conf     既存の wg0.conf を使い、生成しない（site.env の WG_USE_EXISTING_CONF=1 と同じ）
#   --drop-unknown-peers    apply: 登録簿に無い [Peer] が既存の conf にあっても止めずに消す
#   --purge                 remove で wg0.conf・鍵ファイル・クライアント用 conf も削除する
#   --pubkey KEY            client add: クライアント側で生成した公開鍵を登録する（秘密鍵をホストで作らない）
#   --ip ADDR               client add: トンネル IP を指定する（既定: 帯の中で最小の空きアドレス）
#   --qr                    client show: QR コードで表示する（qrencode が必要）
#   -o, --output FILE       backup: 出力先（既定: ~/wg-backup-<ホスト名>-<日時>.tar.gz）
#   -h, --help              このヘルプ
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ENV_FILE="$SCRIPT_DIR/site.env"
DRY_RUN=0
OPT_USE_EXISTING=0
DROP_UNKNOWN=0
PURGE=0
OPT_PUBKEY=""
OPT_IP=""
OPT_QR=0
OPT_OUTPUT=""
# -e が明示されたか（restore で site.env の戻し先を決めるのに使う）
ENV_FILE_SET=0
# load_env が設定ファイルを読めたか（復旧直後はまだ無い）
ENV_LOADED=0
# make_tmpdir が作る作業用ディレクトリ
TMP_WORK=""
SYSCTL_FILE=/etc/sysctl.d/90-wireguard.conf
# --pubkey で登録したクライアントの conf に書く PrivateKey の仮の値
CLIENT_KEY_PLACEHOLDER="<CLIENT_PRIVATE_KEY>"
# 旧レイアウト（専用ゾーン WG_FW_ZONE + 方向ごとの policy）が作っていた policy 名。apply / remove が残っていれば消す
LEGACY_POLICY_RE='^(site[AB]-to-(site|clients)[AB]|clients[AB]-to-site[AB])$'

die()  { echo "ERROR: $*" >&2; exit 1; }
warn() { echo "WARN:  $*" >&2; }
info() { echo "==> $*"; }

usage() { sed -n '2,/^set -euo/{/^set -euo/d;s/^# \{0,1\}//;p}' "${BASH_SOURCE[0]}"; }

# 変更を伴うコマンドはすべてこれを通す
run() {
  if (( DRY_RUN )); then
    printf '[dry-run] '; printf '%q ' "$@"; echo
  else
    "$@"
  fi
}

need_root() { [[ $EUID -eq 0 ]] || die "root で実行してください（sudo）"; }

load_env() {
  local required=$1
  if [[ -f $ENV_FILE ]]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    ENV_LOADED=1
  elif (( required )); then
    die "設定ファイルがありません: $ENV_FILE（site.env.example をコピーして作成）"
  fi
  WG_IFACE=${WG_IFACE:-wg0}
  WG_FW_ZONE=${WG_FW_ZONE:-wireguard}   # 旧レイアウトで wg0 を入れていた専用ゾーン名（残っていれば消す対象）
  WG_KEEPALIVE=${WG_KEEPALIVE:-25}
  WG_MTU=${WG_MTU:-}
  LAN_ZONE=${LAN_ZONE:-}
  WG_A_CLIENT_NET=${WG_A_CLIENT_NET:-}
  WG_B_CLIENT_NET=${WG_B_CLIENT_NET:-}
  WG_CLIENT_DNS=${WG_CLIENT_DNS:-}
  CLIENTS_FILE=${WG_CLIENTS_FILE:-$(dirname "$ENV_FILE")/clients.list}
  CLIENT_DIR=${WG_CLIENT_DIR:-/etc/wireguard/clients}
  CONF=/etc/wireguard/$WG_IFACE.conf
  KEY=/etc/wireguard/$WG_IFACE.key
  PUB=/etc/wireguard/$WG_IFACE.pub
  if (( OPT_USE_EXISTING )) || [[ ${WG_USE_EXISTING_CONF:-0} == 1 ]]; then
    USE_EXISTING=1
  else
    USE_EXISTING=0
  fi
}

# A/B から自拠点・相手拠点の値を引く
select_site() {
  case ${1:-} in
    A) L=A; P=B ;;
    B) L=B; P=A ;;
    *) die "拠点を A または B で指定してください" ;;
  esac
  local v
  for v in SITE_A_LAN SITE_B_LAN WG_A_LAN_IP WG_B_LAN_IP WG_TUNNEL_NET WG_A_TUN_IP WG_B_TUN_IP WG_PORT; do
    [[ -n ${!v:-} ]] || die "site.env の $v が空です"
  done
  local n
  n=SITE_${P}_LAN;       PEER_LAN=${!n}
  n=WG_${L}_LAN_IP;      MY_LAN_IP=${!n}
  n=WG_${P}_LAN_IP;      PEER_LAN_IP=${!n}
  n=WG_${L}_TUN_IP;      MY_TUN=${!n}
  n=WG_${P}_TUN_IP;      PEER_TUN=${!n}
  n=SITE_${L}_PUBLIC;    MY_PUBLIC=${!n:-}
  n=SITE_${P}_PUBLIC;    PEER_PUBLIC=${!n:-}
  n=SITE_${L}_PUBKEY;    MY_PUBKEY=${!n:-}
  n=SITE_${P}_PUBKEY;    PEER_PUBKEY=${!n:-}
  n=ROUTER_${L}_LAN_IP;  MY_ROUTER=${!n:-}
  n=WG_${L}_CLIENT_NET;  MY_CLIENT_NET=${!n:-}
  n=WG_${P}_CLIENT_NET;  PEER_CLIENT_NET=${!n:-}
  PORT=$WG_PORT
}

# アドレス類の形式・包含関係・重複と、クライアント登録簿の内容を検査する
validate_addresses() {
  local out
  out=$(python3 - "$SITE_A_LAN" "$SITE_B_LAN" "$WG_TUNNEL_NET" \
      "$WG_A_LAN_IP" "$WG_B_LAN_IP" "$WG_A_TUN_IP" "$WG_B_TUN_IP" \
      "${ROUTER_A_LAN_IP:-}" "${ROUTER_B_LAN_IP:-}" "$WG_PORT" "$WG_KEEPALIVE" "$WG_MTU" \
      "$WG_A_CLIENT_NET" "$WG_B_CLIENT_NET" "$CLIENTS_FILE" <<'PY'
import ipaddress as ip, os, re, sys
(a_lan, b_lan, tun, a_ip, b_ip, a_tun, b_tun, a_rt, b_rt, port, ka, mtu,
 a_cl, b_cl, clients_file) = sys.argv[1:]
errs = []
def net(name, v):
    try:
        return ip.ip_network(v, strict=True)
    except ValueError as e:
        errs.append(f"{name}={v}: ネットワークアドレスとして不正です（{e}）")
def addr(name, v):
    try:
        return ip.ip_address(v)
    except ValueError:
        errs.append(f"{name}={v}: IP アドレスとして不正です")
na, nb, nt = net("SITE_A_LAN", a_lan), net("SITE_B_LAN", b_lan), net("WG_TUNNEL_NET", tun)
ia, ib = addr("WG_A_LAN_IP", a_ip), addr("WG_B_LAN_IP", b_ip)
ta, tb = addr("WG_A_TUN_IP", a_tun), addr("WG_B_TUN_IP", b_tun)
ra = addr("ROUTER_A_LAN_IP", a_rt) if a_rt else None
rb = addr("ROUTER_B_LAN_IP", b_rt) if b_rt else None
ca = net("WG_A_CLIENT_NET", a_cl) if a_cl else None
cb = net("WG_B_CLIENT_NET", b_cl) if b_cl else None
if not errs:
    nets = [(na, "SITE_A_LAN"), (nb, "SITE_B_LAN"), (nt, "WG_TUNNEL_NET")]
    nets += [(ca, "WG_A_CLIENT_NET")] if ca else []
    nets += [(cb, "WG_B_CLIENT_NET")] if cb else []
    for i, (x, xn) in enumerate(nets):
        for y, yn in nets[i + 1:]:
            if x.overlaps(y):
                errs.append(f"{xn}={x} と {yn}={y} が重複しています")
    for i, n, iname, nname in [(ia, na, "WG_A_LAN_IP", "SITE_A_LAN"), (ib, nb, "WG_B_LAN_IP", "SITE_B_LAN"),
                               (ta, nt, "WG_A_TUN_IP", "WG_TUNNEL_NET"), (tb, nt, "WG_B_TUN_IP", "WG_TUNNEL_NET"),
                               (ra, na, "ROUTER_A_LAN_IP", "SITE_A_LAN"), (rb, nb, "ROUTER_B_LAN_IP", "SITE_B_LAN")]:
        if i is not None and i not in n:
            errs.append(f"{iname}={i} が {nname}={n} に含まれていません")
    if ta == tb:
        errs.append("WG_A_TUN_IP と WG_B_TUN_IP が同じです")
    for i, n in [(ta, nt), (tb, nt)]:
        if n.num_addresses > 2 and i in (n.network_address, n.broadcast_address):
            errs.append(f"{i} は {n} のネットワーク/ブロードキャストアドレスです")
    for n, nname in [(ca, "WG_A_CLIENT_NET"), (cb, "WG_B_CLIENT_NET")]:
        if n is not None and n.num_addresses < 4:
            errs.append(f"{nname}={n}: クライアント用の帯は /30 より広くしてください")
    # クライアント登録簿（NAME SITE TUNNEL_IP PUBLIC_KEY）
    cnets = {"A": ca, "B": cb}
    seen_name, seen_ip, seen_key = {}, {}, {}
    lines = open(clients_file, encoding="utf-8").read().splitlines() if os.path.exists(clients_file) else []
    for lineno, raw in enumerate(lines, 1):
        where = f"{clients_file}:{lineno}"
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        f = line.split()
        if len(f) != 4:
            errs.append(f"{where}: 4 列（NAME SITE TUNNEL_IP PUBLIC_KEY）ではありません")
            continue
        name, site, cip, key = f
        if not re.fullmatch(r"[A-Za-z0-9_-]+", name):
            errs.append(f"{where}: クライアント名 {name} は英数字・-・_ だけで指定してください")
        if name in seen_name:
            errs.append(f"{where}: クライアント名 {name} が {seen_name[name]} 行目と重複しています")
        seen_name.setdefault(name, lineno)
        if site not in cnets:
            errs.append(f"{where}: SITE={site} は A か B で指定してください")
            continue
        try:
            i = ip.ip_address(cip)
        except ValueError:
            errs.append(f"{where}: {cip} は IP アドレスとして不正です")
            continue
        n = cnets[site]
        if n is None:
            errs.append(f"{where}: クライアント {name} は拠点 {site} ですが WG_{site}_CLIENT_NET が空です")
        elif i not in n:
            errs.append(f"{where}: {i} が WG_{site}_CLIENT_NET={n} に含まれていません")
        elif i in (n.network_address, n.broadcast_address):
            errs.append(f"{where}: {i} は {n} のネットワーク/ブロードキャストアドレスです")
        if i in seen_ip:
            errs.append(f"{where}: {i} が {seen_ip[i]} 行目と重複しています")
        seen_ip.setdefault(i, lineno)
        if not re.fullmatch(r"[A-Za-z0-9+/]{42}[AEIMQUYcgkosw048]=", key):
            errs.append(f"{where}: 公開鍵が WireGuard の公開鍵の形式ではありません")
        elif key in seen_key:
            errs.append(f"{where}: 公開鍵が {seen_key[key]} 行目と重複しています")
        seen_key.setdefault(key, lineno)
if not port.isdigit() or not 1 <= int(port) <= 65535:
    errs.append(f"WG_PORT={port}: 1〜65535 で指定してください")
if not ka.isdigit():
    errs.append(f"WG_KEEPALIVE={ka}: 0 以上の整数で指定してください")
if mtu and (not mtu.isdigit() or not 1280 <= int(mtu) <= 1500):
    errs.append(f"WG_MTU={mtu}: 1280〜1500 で指定してください")
for e in errs:
    print(e)
if not errs and nt is not None:
    print(f"PREFIX={nt.prefixlen}")
PY
  ) || die "アドレスの検査に失敗しました"
  if [[ $out != PREFIX=* ]]; then
    while IFS= read -r line; do echo "ERROR: $line" >&2; done <<<"$out"
    exit 1
  fi
  TUN_PREFIX=${out#PREFIX=}
}

is_pubkey() { [[ $1 =~ ^[A-Za-z0-9+/]{42}[AEIMQUYcgkosw048]=$ ]]; }

# 指定 IP を持つインターフェース名（無ければ空）
iface_of_ip() {
  # 最初の一致を控えて最後まで読む。途中で exit すると ip が SIGPIPE で終わり、
  # set -o pipefail の下で apply が終了 141 になることがある。
  ip -o -4 addr show | awk -v ip="$1" '{split($4, a, "/"); if (a[1] == ip && iface == "") iface = $2} END {if (iface != "") print iface}'
}

check_host_is_site() {
  LAN_IFACE=$(iface_of_ip "$MY_LAN_IP")
  if [[ -z $LAN_IFACE ]]; then
    if [[ -n $(iface_of_ip "$PEER_LAN_IP") ]]; then
      die "このホストは拠点 $P の WG ホスト（$PEER_LAN_IP）です。拠点の指定を確認してください"
    fi
    die "このホストに WG_${L}_LAN_IP=$MY_LAN_IP が割り当てられていません"
  fi
}

resolve_lan_zone() {
  if [[ -z $LAN_ZONE ]]; then
    [[ -n ${LAN_IFACE:-} ]] || die "LAN_ZONE を自動検出できません。site.env に LAN_ZONE を指定してください"
    LAN_ZONE=$(firewall-cmd --get-zone-of-interface="$LAN_IFACE" 2>/dev/null || true)
    if [[ -z $LAN_ZONE || $LAN_ZONE == "no zone" ]]; then
      LAN_ZONE=$(firewall-cmd --get-default-zone)
    fi
    info "LAN 側ゾーン: $LAN_ZONE（$LAN_IFACE から検出）"
  fi
  firewall-cmd --permanent --get-zones | has_word "$LAN_ZONE" \
    || die "firewalld にゾーン $LAN_ZONE がありません"
  # 旧レイアウトの掃除で LAN 側ゾーンを消してしまわないように
  [[ $WG_FW_ZONE != "$LAN_ZONE" ]] || die "WG_FW_ZONE（旧専用ゾーン名）が LAN_ZONE と同じです"
}

install_tools() {
  if ! rpm -q wireguard-tools >/dev/null 2>&1; then
    info "wireguard-tools をインストールします"
    run dnf install -y wireguard-tools
  fi
}

# --- クライアント登録簿 ------------------------------------------------------------
# clients.list（NAME SITE TUNNEL_IP PUBLIC_KEY、# 以降はコメント）を読み、
# 拠点 $1（空なら全拠点）の行を CL_NAMES / CL_SITES / CL_IPS / CL_PUBS に入れる。
# 形式の検査は validate_addresses が行うので、先にそちらを呼ぶ
read_clients() {
  local site=${1:-} name s cip key
  CL_NAMES=(); CL_SITES=(); CL_IPS=(); CL_PUBS=()
  [[ -f $CLIENTS_FILE ]] || return 0
  while read -r name s cip key _; do
    [[ -n $name && $name != \#* ]] || continue
    [[ -z $site || $s == "$site" ]] || continue
    CL_NAMES+=("$name"); CL_SITES+=("$s"); CL_IPS+=("$cip"); CL_PUBS+=("$key")
  done <"$CLIENTS_FILE"
}

# 登録済みクライアント $1 の添字を CL_INDEX に入れる（無ければ偽）
find_client() {
  local i
  for i in "${!CL_NAMES[@]}"; do
    if [[ ${CL_NAMES[i]} == "$1" ]]; then CL_INDEX=$i; return 0; fi
  done
  return 1
}

# 帯 $1 の中で使えるアドレスを返す。$2 が空なら最小の空き、指定があればそれを検査する。残りは使用中の IP
alloc_client_ip() {
  python3 - "$@" <<'PY'
import ipaddress as ip, sys
net, want, *used = sys.argv[1:]
n = ip.ip_network(net)
used = {ip.ip_address(u) for u in used}
def fail(msg):
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(1)
if want:
    try:
        a = ip.ip_address(want)
    except ValueError:
        fail(f"--ip {want}: IP アドレスとして不正です")
    if a not in n:
        fail(f"--ip {a} が WG_CLIENT_NET={n} に含まれていません")
    if a in (n.network_address, n.broadcast_address):
        fail(f"--ip {a} は {n} のネットワーク/ブロードキャストアドレスです")
    if a in used:
        fail(f"--ip {a} は既に別のクライアントに割り当てられています")
    print(a)
else:
    for h in n.hosts():
        if h not in used:
            print(h)
            break
    else:
        fail(f"{n} に空きアドレスがありません")
PY
}

# --- 既存 conf の検査 ------------------------------------------------------------
# 停止すべき不一致は ERROR、続行できるものは WARN を出す。ListenPort が書かれていれば PORT をそれに合わせる
check_existing_conf() {
  [[ -f $CONF ]] || die "既存の設定ファイルがありません: $CONF"
  local mode out rc=0
  mode=$(stat -c %a "$CONF")
  [[ $mode == 600 ]] || warn "$CONF のパーミッションが $mode です（600 を推奨）"
  out=$(python3 - "$CONF" "$MY_TUN" "$PEER_TUN" "$PEER_LAN" "$WG_PORT" "$PEER_CLIENT_NET" <<'PY'
import ipaddress as ip, re, sys
path, my_tun, peer_tun, peer_lan, port, peer_clients = sys.argv[1:]
iface, peers, cur = {}, [], None
for raw in open(path, encoding="utf-8"):
    line = raw.split("#", 1)[0].strip()
    if not line:
        continue
    m = re.fullmatch(r"\[(\w+)\]", line)
    if m:
        sec = m.group(1).lower()
        if sec == "interface":
            cur = iface
        elif sec == "peer":
            cur = {}
            peers.append(cur)
        else:
            cur = None
        continue
    if cur is None or "=" not in line:
        continue
    k, v = (s.strip() for s in line.split("=", 1))
    cur.setdefault(k.lower(), []).append(v)
def items(d, k):
    return [x.strip() for v in d.get(k, []) for x in v.split(",") if x.strip()]
def nets(p):
    out = []
    for n in items(p, "allowedips"):
        try:
            out.append(ip.ip_network(n, strict=False))
        except ValueError:
            errs.append(f"AllowedIPs={n} が不正です")
    return out
errs, warns = [], []
addrs = items(iface, "address")
def iface_ip(a):
    try:
        return ip.ip_interface(a).ip
    except ValueError:
        errs.append(f"[Interface] Address={a} が不正です")
if not any(iface_ip(a) == ip.ip_address(my_tun) for a in addrs):
    errs.append(f"[Interface] Address（{', '.join(addrs) or 'なし'}）に自拠点のトンネル IP {my_tun} がありません")
lan = ip.ip_network(peer_lan)
covering = [p for p in peers if any(lan.version == n.version and lan.subnet_of(n) for n in nets(p))]
if not covering:
    errs.append(f"相手拠点 LAN {peer_lan} を AllowedIPs に含む [Peer] がありません")
else:
    p = covering[0]
    if not any(ip.ip_address(peer_tun) in n for n in nets(p)):
        warns.append(f"相手 peer の AllowedIPs に相手のトンネル IP {peer_tun} が含まれていません")
    if not p.get("endpoint"):
        warns.append("相手 peer に Endpoint がありません（相手側からトンネルを張る構成でなければ接続できません）")
    if peer_clients:
        cn = ip.ip_network(peer_clients)
        if not any(cn.version == n.version and cn.subnet_of(n) for n in nets(p)):
            warns.append(f"相手 peer の AllowedIPs に相手拠点のクライアント帯 {peer_clients} が含まれていません（相手拠点のクライアントからこの拠点へは届きません）")
lp = iface.get("listenport", [])
if not lp:
    warns.append(f"[Interface] に ListenPort がありません（ランダムなポートになり、ポート転送できません）。firewalld には WG_PORT={port} を使います")
elif lp[-1] != port:
    warns.append(f"ListenPort={lp[-1]} が WG_PORT={port} と違います。firewalld とルーター表示には {lp[-1]} を使います")
    print(f"PORT={lp[-1]}")
if not iface.get("privatekey"):
    if any("private-key" in v for v in iface.get("postup", [])):
        warns.append("PrivateKey を PostUp で読み込んでいます。systemctl reload / wg syncconf で鍵が消えます（手順書の落とし穴 1）")
    else:
        warns.append("[Interface] に PrivateKey がありません")
for w in warns:
    print(f"WARN {w}")
for e in errs:
    print(f"ERROR {e}")
sys.exit(1 if errs else 0)
PY
  ) || rc=$?
  local line
  while IFS= read -r line; do
    case $line in
      PORT=*)  PORT=${line#PORT=} ;;
      WARN\ *) warn "${line#WARN }" ;;
      ERROR\ *) echo "ERROR: ${line#ERROR }" >&2 ;;
    esac
  done <<<"$out"
  (( rc == 0 )) || die "既存の $CONF が site.env と一致しません。何も変更していません"
  info "既存の $CONF を使います（生成しません）"
}

# --- conf 生成 ---------------------------------------------------------------------
# Endpoint の値（IPv6 リテラルは [] で囲む）
format_endpoint() {
  if [[ $1 == *:* && $1 != \[* ]]; then
    echo "[$1]:$PORT"
  else
    echo "$1:$PORT"
  fi
}

# 自拠点のクライアント（read_clients "$L" の結果）の [Peer] ブロック
render_client_peers() {
  local i
  for i in "${!CL_NAMES[@]}"; do
    echo
    echo "[Peer]"
    echo "# Client ${CL_NAMES[i]}"
    echo "PublicKey = ${CL_PUBS[i]}"
    echo "AllowedIPs = ${CL_IPS[i]}/32"
  done
}

render_conf() {  # $1 = PrivateKey の値
  local endpoint="" allowed="$PEER_TUN/32, $PEER_LAN"
  [[ -z $PEER_PUBLIC ]] || endpoint=$(format_endpoint "$PEER_PUBLIC")
  # 相手拠点のクライアントは相手拠点ホストの向こうにいるので、その帯も相手 peer に載せる
  [[ -z $PEER_CLIENT_NET ]] || allowed+=", $PEER_CLIENT_NET"
  echo "[Interface]"
  echo "Address = $MY_TUN/$TUN_PREFIX"
  echo "ListenPort = $PORT"
  echo "PrivateKey = $1"
  [[ -z $WG_MTU ]] || echo "MTU = $WG_MTU"
  echo
  echo "[Peer]"
  echo "# Site $P"
  echo "PublicKey = $PEER_PUBKEY"
  [[ -z $endpoint ]] || echo "Endpoint = $endpoint"
  echo "AllowedIPs = $allowed"
  (( WG_KEEPALIVE == 0 )) || echo "PersistentKeepalive = $WG_KEEPALIVE"
  render_client_peers
}

# クライアント用 conf。$1 = クライアント名、$2 = トンネル IP、$3 = PrivateKey の値。SITE_PUBKEY は resolve_my_pubkey で決める
render_client_conf() {
  echo "[Interface]"
  echo "# Client $1 (site $L)"
  echo "Address = $2/32"
  echo "PrivateKey = $3"
  [[ -z $WG_CLIENT_DNS ]] || echo "DNS = $WG_CLIENT_DNS"
  echo
  echo "[Peer]"
  echo "# Site $L"
  echo "PublicKey = $SITE_PUBKEY"
  echo "Endpoint = $(format_endpoint "$MY_PUBLIC")"
  echo "AllowedIPs = $SITE_A_LAN, $SITE_B_LAN, $WG_TUNNEL_NET"
  (( WG_KEEPALIVE == 0 )) || echo "PersistentKeepalive = $WG_KEEPALIVE"
}

# このホストの鍵ファイルから公開鍵を算出する（鍵が無ければ空）
derive_my_pubkey() {
  [[ -f $KEY ]] || { echo ""; return 0; }
  wg pubkey <"$KEY" || die "$KEY から公開鍵を算出できません"
}

check_keys() {
  [[ -n $PEER_PUBKEY ]] || die "site.env の SITE_${P}_PUBKEY（相手拠点の公開鍵）が空です"
  is_pubkey "$PEER_PUBKEY" || die "SITE_${P}_PUBKEY が WireGuard の公開鍵の形式ではありません"
  [[ -f $KEY ]] || die "秘密鍵 $KEY がありません。先に keygen を実行してください"
  local derived
  derived=$(derive_my_pubkey)
  if [[ -n $MY_PUBKEY && $MY_PUBKEY != "$derived" ]]; then
    die "SITE_${L}_PUBKEY がこのホストの鍵（$derived）と一致しません"
  fi
  [[ $PEER_PUBKEY != "$derived" ]] || die "SITE_${P}_PUBKEY が自拠点の公開鍵と同じです"
}

# クライアント conf に書く自拠点の公開鍵を SITE_PUBKEY に決める（site.env の値を優先し、鍵ファイルと食い違えば止まる）
resolve_my_pubkey() {
  local derived=""
  if [[ -f $KEY ]] && command -v wg >/dev/null; then
    derived=$(derive_my_pubkey)
  fi
  if [[ -n $MY_PUBKEY ]]; then
    is_pubkey "$MY_PUBKEY" || die "SITE_${L}_PUBKEY が WireGuard の公開鍵の形式ではありません"
    [[ -z $derived || $derived == "$MY_PUBKEY" ]] || die "SITE_${L}_PUBKEY がこのホストの鍵（$derived）と一致しません"
    SITE_PUBKEY=$MY_PUBKEY
  elif [[ -n $derived ]]; then
    SITE_PUBKEY=$derived
  else
    die "拠点 $L の公開鍵がわかりません。site.env に SITE_${L}_PUBKEY を書くか、先に keygen を実行してください"
  fi
}

# 作り直す conf に載らない [Peer] が既存の conf にあれば列挙する。
# apply は clients.list からクライアントの [Peer] を毎回組み立て直すので、登録簿に無い peer は
# 黙って消える（手で足した peer を残したまま移行するとこれで失う）。消す前に止める
# client remove 後も同じ保護が働く。対象鍵の確認と明示許可は docs/wireguard.md の削除手順を参照
check_unknown_peers() {
  [[ -f $CONF ]] || return 0
  local known=("$PEER_PUBKEY" "${CL_PUBS[@]}")
  [[ -z ${MY_PUBKEY:-} ]] || known+=("$MY_PUBKEY")
  [[ ! -r $PUB ]] || known+=("$(cat "$PUB")")
  local -a unknown=()
  local line key label="" lineno=0 k found
  while IFS= read -r line || [[ -n $line ]]; do
    lineno=$((lineno + 1))
    case $line in
      \[*) label="" ; continue ;;
      \#*) label=${line#\#}; label=${label## } ; continue ;;
    esac
    [[ $line =~ ^[[:space:]]*[Pp]ublic[Kk]ey[[:space:]]*=[[:space:]]*([^[:space:]#]+) ]] || continue
    key=${BASH_REMATCH[1]}
    found=0
    for k in "${known[@]}"; do
      [[ $k != "$key" ]] || { found=1; break; }
    done
    (( found )) || unknown+=("$(printf '%s:%s  %-16s %s' "$CONF" "$lineno" "${label:-（名前なし）}" "$key")")
  done <"$CONF"
  (( ${#unknown[@]} )) || return 0
  local head="既存の $CONF に、登録簿（$CLIENTS_FILE）に無い [Peer] が ${#unknown[@]} 個あります"
  if (( DROP_UNKNOWN )); then
    warn "$head。--drop-unknown-peers が指定されているので、消して続行します:"
    printf '       %s\n' "${unknown[@]}" >&2
    return 0
  fi
  echo "ERROR: $head。このまま apply すると消えます:" >&2
  printf '       %s\n' "${unknown[@]}" >&2
  echo "       残すなら、登録簿に取り込んでから apply し直してください:" >&2
  echo "         sudo $0 client add $L <名前> --pubkey <公開鍵> --ip <トンネル IP>" >&2
  echo "         （トンネル IP は $CONF のその [Peer] の AllowedIPs の値）" >&2
  echo "       消してよいなら --drop-unknown-peers を付けて実行してください。" >&2
  exit 1
}

write_conf() {
  if (( DRY_RUN )); then
    info "$CONF に書き込む内容:"
    render_conf "(hidden)" | sed 's/^/    /'
    return
  fi
  local tmp
  tmp=$(umask 077; mktemp "$CONF.XXXXXX")
  # 秘密鍵は画面に出さず、鍵ファイルから直接書き込む
  (umask 077; render_conf "$(cat "$KEY")" >"$tmp")
  if [[ -f $CONF ]] && cmp -s "$tmp" "$CONF"; then
    rm -f "$tmp"
    info "$CONF は変更なし"
    return
  fi
  if [[ -f $CONF ]]; then
    local bak
    bak="$CONF.bak-$(date +%Y%m%d-%H%M%S)"
    cp -p "$CONF" "$bak"
    info "既存の $CONF を $bak に退避しました"
  fi
  chmod 600 "$tmp"
  mv "$tmp" "$CONF"
  restorecon "$CONF" 2>/dev/null || true
  info "$CONF を書き込みました"
}

setup_sysctl() {
  local want="net.ipv4.ip_forward = 1"
  if [[ -f $SYSCTL_FILE ]] && [[ $(cat "$SYSCTL_FILE") == "$want" ]]; then
    info "$SYSCTL_FILE は変更なし"
  elif (( DRY_RUN )); then
    echo "[dry-run] $SYSCTL_FILE に '$want' を書き込む"
  else
    echo "$want" >"$SYSCTL_FILE"
    info "$SYSCTL_FILE を書き込みました"
  fi
  run sysctl -q -p "$SYSCTL_FILE"
}

# --- firewalld（すべて存在確認してから追加する） ------------------------------------------
# wg0 は LAN 側 NIC と同じゾーン（LAN_ZONE）に入れ、そのゾーンの forward（ゾーン内転送）で
# トンネル ⇔ LAN、wg0 → wg0 の折り返しをすべて通す。転送はここでは絞らない（絞るのは宛先ホスト側）。
fw() { firewall-cmd --permanent "$@" >/dev/null 2>&1; }

# grep -q は途中で読むのをやめて pipefail で誤判定しうるので、全部読ませる
has_word() { tr -s ' \n' '\n' | grep -Fx -- "$1" >/dev/null; }

# 旧レイアウト（専用ゾーン WG_FW_ZONE + 方向ごとの policy）が残っていれば消す。
# policy → ゾーンの順に消す（ゾーンを先に消すと、参照する policy が残って reload が INVALID_ZONE で失敗する）
cleanup_legacy_firewalld() {
  local p found=0
  for p in $(firewall-cmd --permanent --get-policies | tr -s ' \n' '\n' | grep -E "$LEGACY_POLICY_RE" || true); do
    found=1
    run firewall-cmd --permanent --delete-policy="$p"
    [[ ! -f /etc/firewalld/policies/$p.xml.old ]] || run rm -f "/etc/firewalld/policies/$p.xml.old"
  done
  if firewall-cmd --permanent --get-zones | has_word "$WG_FW_ZONE"; then
    found=1
    # ゾーンを消すと所属していた wg0 も外れる（--remove-interface は不要）
    run firewall-cmd --permanent --delete-zone="$WG_FW_ZONE"
    [[ ! -f /etc/firewalld/zones/$WG_FW_ZONE.xml.old ]] || run rm -f "/etc/firewalld/zones/$WG_FW_ZONE.xml.old"
  fi
  (( found )) && info "旧レイアウト（ゾーン $WG_FW_ZONE と policy）を削除しました"
  return 0
}

setup_firewalld() {
  systemctl is-active --quiet firewalld || die "firewalld が起動していません"
  resolve_lan_zone
  # 何かを変える前に、wg0 が LAN 側ゾーンでも旧専用ゾーンでもない別のゾーンにあれば止まる
  local cur
  cur=$(firewall-cmd --permanent --get-zone-of-interface="$WG_IFACE" 2>/dev/null || true)
  if [[ -n $cur && $cur != "no zone" && $cur != "$LAN_ZONE" && $cur != "$WG_FW_ZONE" ]]; then
    die "$WG_IFACE は既にゾーン $cur に割り当てられています"
  fi
  cleanup_legacy_firewalld            # 旧専用ゾーンにあった wg0 は、ここで未割り当てになる
  [[ $cur != "$WG_FW_ZONE" ]] || cur=""
  fw --zone="$LAN_ZONE" --query-port="$PORT/udp" || run firewall-cmd --permanent --zone="$LAN_ZONE" --add-port="$PORT/udp"
  [[ $cur == "$LAN_ZONE" ]] || run firewall-cmd --permanent --zone="$LAN_ZONE" --add-interface="$WG_IFACE"
  # ゾーン内転送（LAN NIC ⇔ wg0、wg0 → wg0 の折り返しを含む）。組み込みゾーンは既定で有効、--new-zone で作ったゾーンは無効
  fw --zone="$LAN_ZONE" --query-forward || run firewall-cmd --permanent --zone="$LAN_ZONE" --add-forward
  run firewall-cmd --reload
}

# --- バックアップ / 復旧 ------------------------------------------------------------
# アーカイブは wg-backup/ の下に平らに並べ、MANIFEST に
# 「FILE 種別 アーカイブ内の名前 パーミッション 元のパス」を残す。restore はそれを見て元の場所へ戻す
BACKUP_DIR_NAME=wg-backup
# MANIFEST の形式。restore は知らない値を拒否する
BACKUP_FORMAT=1

short_host() { hostname -s 2>/dev/null || uname -n; }

# sudo の呼び出しユーザーのホーム（無ければ root のもの）
user_home() {
  local h=""
  [[ -z ${SUDO_USER:-} ]] || h=$(getent passwd "$SUDO_USER" | cut -d: -f6)
  echo "${h:-$HOME}"
}

# site.env から 1 変数の値を読む（source せずに読む。# 以降と前後の空白・二重引用符を落とす）
env_value() {  # $1 = ファイル, $2 = 変数名
  [[ -f $1 ]] || return 0
  awk -v k="$2" '
    { line = $0; sub(/^[ \t]*/, "", line) }
    index(line, k "=") == 1 {
      v = substr(line, length(k) + 2)
      sub(/#.*/, "", v)
      gsub(/^[ \t]+|[ \t]+$/, "", v)
      gsub(/^"|"$/, "", v)
      val = v
    }
    END { if (val != "") print val }
  ' "$1"
}

# 作業用ディレクトリ（終了時に消す）
make_tmpdir() {
  TMP_WORK=$(umask 077; mktemp -d "${TMPDIR:-/tmp}/wg-vpn.XXXXXX") || die "作業用ディレクトリを作れません"
  trap 'rm -rf "$TMP_WORK"' EXIT
}

# SELinux のラベルを付け直す（restorecon が無い環境でも止めない）
relabel() {
  if (( DRY_RUN )); then
    printf '[dry-run] '; printf '%q ' restorecon "$1"; echo
  else
    restorecon "$1" >/dev/null 2>&1 || true
  fi
}

# root で戻したファイルの所有者を、置き先ディレクトリ → sudo の呼び出しユーザー の順で決める。
# site.env と clients.list を root 所有のままにすると、非 root で動く client list / router が読めなくなる。
# 「既にある同名ファイルの所有者」を優先しないのは、一度 root 所有で置かれたものが直らなくなるため
fix_owner() {  # $1 = パス
  local p=$1 owner
  owner=$(stat -c %U "$(dirname "$p")" 2>/dev/null || echo root)
  if [[ $owner == root && -n ${SUDO_USER:-} ]]; then
    owner=$SUDO_USER
  fi
  [[ $owner == root ]] || run chown "$owner:" "$p"
}

# アーカイブ内の 1 ファイルを戻す。既存のものは write_conf と同じく .bak-日時 に退避する
restore_file() {  # $1 = アーカイブ内のファイル, $2 = 戻し先, $3 = パーミッション, $4 = 1 なら所有者を合わせる
  local src=$1 dst=$2 mode=$3 own=$4 dir
  [[ -f $src ]] || return 0
  dir=$(dirname "$dst")
  if [[ ! -d $dir ]]; then
    run install -d -m 700 "$dir"
    (( own == 0 )) || fix_owner "$dir"
  fi
  if [[ -f $dst ]] && cmp -s "$src" "$dst"; then
    info "$dst は変更なし"
    return 0
  fi
  if [[ -f $dst ]]; then
    run cp -p "$dst" "$dst.bak-$(date +%Y%m%d-%H%M%S)"
    (( DRY_RUN )) || info "既存の $dst を退避しました"
  fi
  run install -m "$mode" "$src" "$dst"
  relabel "$dst"
  (( own == 0 )) || fix_owner "$dst"
  (( DRY_RUN )) || info "$dst を戻しました"
}

# --- commands --------------------------------------------------------------------
cmd_keygen() {
  need_root
  load_env 0
  if [[ -n ${1:-} ]]; then
    select_site "$1"
    check_host_is_site
  fi
  install_tools
  if [[ -f $KEY ]]; then
    info "$KEY は既にあるので生成しません"
  elif (( DRY_RUN )); then
    echo "[dry-run] $KEY と $PUB を生成する"
    return
  else
    (umask 077; wg genkey | tee "$KEY" | wg pubkey >"$PUB")
    info "$KEY と $PUB を生成しました"
  fi
  [[ -f $PUB ]] || (umask 077; wg pubkey <"$KEY" >"$PUB")
  echo
  echo "公開鍵: $(cat "$PUB")"
  echo "site.env の SITE_${L:-<A|B>}_PUBKEY に書き、同じ site.env を相手拠点にも置いてください。"
}

cmd_apply() {
  need_root
  load_env 1
  select_site "${1:-}"
  validate_addresses
  read_clients "$L"
  [[ -n $MY_PUBLIC || -n $PEER_PUBLIC ]] || die "SITE_A_PUBLIC と SITE_B_PUBLIC の両方が空です（どちらからもトンネルを張れません）"
  if [[ -n $MY_CLIENT_NET && -z $MY_PUBLIC ]]; then
    warn "WG_${L}_CLIENT_NET が設定されていますが SITE_${L}_PUBLIC が空です（この拠点は着信を受けられないので、クライアントは接続できません）"
  fi
  check_host_is_site
  (( USE_EXISTING )) || check_unknown_peers
  install_tools
  if (( USE_EXISTING )); then
    check_existing_conf
    if (( ${#CL_NAMES[@]} )); then
      warn "既存の conf を使うため、拠点 $L のクライアント ${#CL_NAMES[@]} 台の [Peer] は書き込みません。必要なら次を $CONF に追加してください:"
      render_client_peers | sed 's/^/    /' >&2
    fi
  else
    if (( DRY_RUN )) && ! command -v wg >/dev/null; then
      warn "wireguard-tools が未導入のため、鍵の検査は省略します"
    else
      check_keys
    fi
  fi
  (( DRY_RUN )) && info "dry-run: 以下は実行予定の内容です"

  (( USE_EXISTING )) || write_conf
  setup_sysctl
  setup_firewalld
  run systemctl enable "wg-quick@$WG_IFACE"
  # AllowedIPs・Address の変更（クライアントの追加・削除を含む）は reload では経路に反映されないので、常に restart する（落とし穴 2）
  run systemctl restart "wg-quick@$WG_IFACE"
  (( DRY_RUN )) || info "wg-quick@$WG_IFACE を起動しました"
  echo
  print_router
}

print_router() {
  echo "---- 拠点 $L のルーターに設定する値 ----"
  if [[ -n $MY_PUBLIC ]]; then
    echo "ポート転送 : WAN（$MY_PUBLIC）の $PORT/udp → $MY_LAN_IP:$PORT"
  else
    echo "ポート転送 : 不要（SITE_${L}_PUBLIC が空。この拠点からトンネルを張る）"
  fi
  echo "静的経路   : 宛先 $PEER_LAN → ゲートウェイ $MY_LAN_IP"
  [[ -z $MY_CLIENT_NET ]]   || echo "静的経路   : 宛先 $MY_CLIENT_NET → ゲートウェイ $MY_LAN_IP（拠点 $L のクライアント）"
  [[ -z $PEER_CLIENT_NET ]] || echo "静的経路   : 宛先 $PEER_CLIENT_NET → ゲートウェイ $MY_LAN_IP（拠点 $P のクライアント）"
  echo "DHCP 予約  : $MY_LAN_IP をこの WG ホストに固定"
  [[ -z $MY_ROUTER ]] || echo "（ルーターの LAN 側 IP: $MY_ROUTER）"
}

cmd_router() {
  load_env 1
  select_site "${1:-}"
  validate_addresses
  print_router
}

cmd_status() {
  need_root
  load_env 0
  local sep="--------"
  echo "$sep wg show $WG_IFACE";            wg show "$WG_IFACE" 2>&1 || true
  echo "$sep ip route show dev $WG_IFACE";  ip route show dev "$WG_IFACE" 2>&1 || true
  echo "$sep service";                      systemctl is-enabled "wg-quick@$WG_IFACE" 2>&1 || true
                                            systemctl is-active "wg-quick@$WG_IFACE" 2>&1 || true
  echo "$sep sysctl";                       sysctl net.ipv4.ip_forward
  echo "$sep firewalld";                    firewall-cmd --get-active-zones
  # apply は必ず reload するので runtime を見れば足りる（status は拠点を指定しないので LAN_ZONE は使わない）
  local z
  z=$(firewall-cmd --get-zone-of-interface="$WG_IFACE" 2>/dev/null || true)
  if [[ -n $z ]]; then
    echo "$sep zone $z ($WG_IFACE)";       firewall-cmd --info-zone="$z"      # interfaces / ports / forward
  else
    echo "$WG_IFACE はどのゾーンにも割り当てられていません"
  fi
  if [[ -f $CLIENTS_FILE ]]; then
    echo "$sep clients ($CLIENTS_FILE)"
    read_clients ""
    print_client_list
  fi
  return 0
}

cmd_remove() {
  need_root
  load_env 1
  select_site "${1:-}"
  systemctl is-active --quiet firewalld || die "firewalld が起動していません"
  LAN_IFACE=$(iface_of_ip "$MY_LAN_IP")
  resolve_lan_zone
  if [[ -f $CONF ]]; then
    local lp
    lp=$(awk -F= 'tolower($1) ~ /^[ \t]*listenport[ \t]*$/ {gsub(/[ \t]/, "", $2); print $2}' "$CONF" | tail -1)
    [[ -z $lp ]] || PORT=$lp
  fi
  if systemctl is-enabled --quiet "wg-quick@$WG_IFACE" 2>/dev/null || systemctl is-active --quiet "wg-quick@$WG_IFACE"; then
    run systemctl disable --now "wg-quick@$WG_IFACE"
  fi
  local cur
  cur=$(firewall-cmd --permanent --get-zone-of-interface="$WG_IFACE" 2>/dev/null || true)
  if [[ $cur == "$LAN_ZONE" ]]; then
    run firewall-cmd --permanent --zone="$LAN_ZONE" --remove-interface="$WG_IFACE"
  elif [[ -n $cur && $cur != "no zone" && $cur != "$WG_FW_ZONE" ]]; then
    warn "$WG_IFACE はゾーン $cur に割り当てられています（このスクリプトが入れたものではないので触りません）"
  fi
  cleanup_legacy_firewalld            # 旧レイアウトの policy・専用ゾーン（wg0 ごと）も消す
  fw --zone="$LAN_ZONE" --query-port="$PORT/udp" && run firewall-cmd --permanent --zone="$LAN_ZONE" --remove-port="$PORT/udp"
  # ゾーンの forward は戻さない（apply 前の状態が分からず、組み込みゾーンでは既定で有効なため）
  run firewall-cmd --reload
  if [[ -f $SYSCTL_FILE ]]; then
    run rm -f "$SYSCTL_FILE"
    run sysctl -q -w net.ipv4.ip_forward=0
  fi
  if (( PURGE )); then
    run rm -f "$CONF" "$KEY" "$PUB"
    # クライアント用 conf は登録簿にあるものだけ消す（登録簿 clients.list は残す）
    read_clients ""
    local i
    for i in "${!CL_NAMES[@]}"; do
      [[ ! -f $CLIENT_DIR/${CL_NAMES[i]}.conf ]] || run rm -f "$CLIENT_DIR/${CL_NAMES[i]}.conf"
    done
    [[ ! -d $CLIENT_DIR ]] || run rmdir --ignore-fail-on-non-empty "$CLIENT_DIR"
    [[ ! -f $CLIENTS_FILE ]] || info "$CLIENTS_FILE は残しています（不要なら手で削除）"
  else
    info "$CONF・鍵ファイル・クライアント用 conf は残しています（削除するには --purge）"
  fi
  echo "ルーターのポート転送と静的経路は手動で削除してください。"
}

# --- backup / restore ------------------------------------------------------------
cmd_backup() {
  need_root
  load_env 1
  [[ -f $KEY ]] || die "秘密鍵 $KEY がありません。この拠点の WG ホストで実行してください"
  # 拠点は LAN 側 IP ではなく鍵で判定する（IP は再インストールや NIC の都合で変わりうる）
  local pub="" site="" a_pub b_pub
  if command -v wg >/dev/null; then
    pub=$(derive_my_pubkey)
  else
    warn "wireguard-tools が未導入のため、MANIFEST に公開鍵を書けません"
  fi
  if [[ -n $pub ]]; then
    a_pub=$(env_value "$ENV_FILE" SITE_A_PUBKEY)
    b_pub=$(env_value "$ENV_FILE" SITE_B_PUBKEY)
    if   [[ -n $a_pub && $a_pub == "$pub" ]]; then site=A
    elif [[ -n $b_pub && $b_pub == "$pub" ]]; then site=B
    fi
  fi
  if [[ -n ${1:-} ]]; then
    select_site "$1"
    [[ -z $site || $site == "$L" ]] || die "拠点 $1 を指定しましたが、$KEY は拠点 $site の鍵です"
    site=$L
  fi
  [[ -n $site ]] || warn "拠点（A/B）を判定できません。MANIFEST の SITE は空になります"

  local envsh
  envsh="$(dirname "$ENV_FILE")/wg-env.sh"
  # 種別 アーカイブ内の名前 元のパス。無いものは飛ばす
  local -a cand=(
    "key     $WG_IFACE.key  $KEY"
    "pub     $WG_IFACE.pub  $PUB"
    "conf    $WG_IFACE.conf $CONF"
    "env     site.env       $ENV_FILE"
    "envsh   wg-env.sh      $envsh"
    "clients clients.list   $CLIENTS_FILE"
  )
  local -a items=()
  local spec kind name path mode
  for spec in "${cand[@]}"; do
    read -r kind name path <<<"$spec"
    [[ -f $path ]] || continue
    mode=$(stat -c %a "$path") || die "$path の情報を取得できません"
    items+=("$kind $name $mode $path")
  done

  local out=$OPT_OUTPUT
  [[ -n $out ]] || out="$(user_home)/wg-backup-$(short_host)-$(date +%Y%m%d-%H%M%S).tar.gz"

  if (( DRY_RUN )); then
    info "$out に入れる内容:"
    for spec in "${items[@]}"; do
      read -r kind name mode path <<<"$spec"
      printf '    %-13s (%s) <- %s\n' "$name" "$mode" "$path"
    done
    echo "    MANIFEST"
    return
  fi

  [[ ! -e $out ]] || die "$out が既にあります（-o で別の名前を指定してください）"
  make_tmpdir
  local stage="$TMP_WORK/$BACKUP_DIR_NAME"
  mkdir -p "$stage"
  for spec in "${items[@]}"; do
    read -r kind name mode path <<<"$spec"
    cp -p "$path" "$stage/$name"
  done
  {
    echo "# wg-vpn.sh backup（docs/wireguard.md「バックアップと復旧」）"
    echo "FORMAT=$BACKUP_FORMAT"
    echo "CREATED=$(date -Is)"
    echo "HOST=$(short_host)"
    echo "SITE=$site"
    echo "WG_IFACE=$WG_IFACE"
    echo "PUBKEY=$pub"
    for spec in "${items[@]}"; do
      echo "FILE $spec"
    done
  } >"$stage/MANIFEST"

  (umask 077; tar czf "$out" --owner=0 --group=0 --numeric-owner -C "$TMP_WORK" "$BACKUP_DIR_NAME") || die "アーカイブを作れません: $out"
  chmod 600 "$out"
  [[ -z ${SUDO_USER:-} ]] || chown "$SUDO_USER:" "$out" 2>/dev/null || true
  info "バックアップを作成しました: $out"
  tar tzf "$out" | sed 's/^/    /'
  if compgen -G "$CLIENT_DIR/*.conf" >/dev/null; then
    warn "$CLIENT_DIR にクライアント用 conf（秘密鍵入り）が残っています。バックアップには含めていません。端末に取り込み済みなら削除してください"
  fi
  echo
  echo "このファイルには拠点の秘密鍵が入っている。リポジトリに入れず、0600 のままオフラインの安全な場所に置く。"
  echo "復旧するには: sudo $0 restore $out"
}

cmd_restore() {
  need_root
  local file=${1:-}
  [[ -n $file ]] || die "使い方: restore FILE（backup で作ったアーカイブ）"
  [[ -f $file ]] || die "ファイルがありません: $file"
  load_env 0

  # 展開する前に中身を検査する
  local listing e
  listing=$(tar tzf "$file") || die "アーカイブを読めません: $file"
  while IFS= read -r e; do
    [[ -n $e ]] || continue
    case $e in
      /*)   die "アーカイブに絶対パスのエントリがあります: $e" ;;
      *..*) die "アーカイブに .. を含むエントリがあります: $e" ;;
      "$BACKUP_DIR_NAME"|"$BACKUP_DIR_NAME"/|"$BACKUP_DIR_NAME"/*) ;;
      *)    die "このスクリプトが作ったバックアップではありません（$e）" ;;
    esac
  done <<<"$listing"
  has_word "$BACKUP_DIR_NAME/MANIFEST" <<<"$listing" \
    || die "MANIFEST がありません。このスクリプトが作ったバックアップではありません"

  make_tmpdir
  tar xzf "$file" -C "$TMP_WORK" || die "アーカイブを展開できません: $file"
  local stage="$TMP_WORK/$BACKUP_DIR_NAME"

  local m_iface="" m_site="" m_pubkey="" m_host="" m_created="" m_format="" line
  local -a items=()
  while IFS= read -r line; do
    case $line in
      FORMAT=*)   m_format=${line#FORMAT=} ;;
      CREATED=*)  m_created=${line#CREATED=} ;;
      HOST=*)     m_host=${line#HOST=} ;;
      SITE=*)     m_site=${line#SITE=} ;;
      WG_IFACE=*) m_iface=${line#WG_IFACE=} ;;
      PUBKEY=*)   m_pubkey=${line#PUBKEY=} ;;
      "FILE "*)   items+=("${line#FILE }") ;;
    esac
  done <"$stage/MANIFEST"
  [[ -n $m_format ]] || die "MANIFEST に FORMAT がありません。このスクリプトが作ったバックアップではありません"
  [[ $m_format == "$BACKUP_FORMAT" ]] || die "バックアップの形式（FORMAT=$m_format）を扱えません。新しい版の wg-vpn.sh を使ってください"
  [[ -n $m_iface ]] || die "MANIFEST に WG_IFACE がありません"
  info "バックアップ: ${m_host:-不明} / 拠点 ${m_site:-不明} / $m_iface / ${m_created:-日時不明}"

  # 復旧直後は site.env がまだ無いので、その場合はバックアップのインターフェース名を採用する
  if (( ENV_LOADED )); then
    [[ $m_iface == "$WG_IFACE" ]] \
      || die "バックアップのインターフェース名（$m_iface）が site.env の WG_IFACE=$WG_IFACE と違います"
  else
    WG_IFACE=$m_iface
    CONF=/etc/wireguard/$WG_IFACE.conf
    KEY=/etc/wireguard/$WG_IFACE.key
    PUB=/etc/wireguard/$WG_IFACE.pub
  fi
  install_tools

  # 戻し先を決める。site.env は -e があればそちらを優先し、wg-env.sh と clients.list はその隣に置く
  local spec kind name mode path
  local key_name="" env_name="" env_target="" env_dir=""
  for spec in "${items[@]}"; do
    read -r kind name mode path <<<"$spec"
    case $kind in
      key) key_name=$name ;;
      env) env_name=$name; env_target=$path ;;
    esac
  done
  # MANIFEST のファイル名は展開先のファイル名そのもの。/ を含むと展開先の外を指せてしまう
  for spec in "${items[@]}"; do
    read -r kind name mode path <<<"$spec"
    [[ $name != */* && $name != . && $name != .. ]] \
      || die "MANIFEST のファイル名が不正です: $name"
  done
  [[ -n $key_name && -f $stage/$key_name ]] || die "アーカイブに秘密鍵がありません"
  if [[ -n $env_target ]] && (( ENV_FILE_SET )) && [[ $ENV_FILE != "$env_target" ]]; then
    info "site.env の戻し先を $env_target から $ENV_FILE に変更します（-e の指定）"
    env_target=$ENV_FILE
  fi
  [[ -z $env_target ]] || env_dir=$(dirname "$env_target")

  # 復元先へファイルを書く前に、鍵と site.env が噛み合っているかを確かめる（パッケージ導入は実施済み）
  local derived=""
  if command -v wg >/dev/null; then
    derived=$(wg pubkey <"$stage/$key_name") || die "バックアップの鍵から公開鍵を算出できません"
  else
    warn "wireguard-tools が未導入のため、鍵の照合は省略します"
  fi
  if [[ -n $derived ]]; then
    [[ -z $m_pubkey || $m_pubkey == "$derived" ]] \
      || die "鍵ファイルが MANIFEST の公開鍵と一致しません（アーカイブが壊れています）"
    local envsrc="$stage/${env_name:-site.env}" a_pub b_pub found=""
    a_pub=$(env_value "$envsrc" SITE_A_PUBKEY)
    b_pub=$(env_value "$envsrc" SITE_B_PUBKEY)
    if   [[ -n $a_pub && $a_pub == "$derived" ]]; then found=A
    elif [[ -n $b_pub && $b_pub == "$derived" ]]; then found=B
    fi
    if [[ -n $found ]]; then
      [[ -z $m_site || $m_site == "$found" ]] \
        || warn "MANIFEST の拠点（$m_site）と、公開鍵から判定した拠点（$found）が違います"
      m_site=$found
      info "鍵と site.env は一致しています（拠点 $found の公開鍵 $derived）"
    elif [[ -z $a_pub && -z $b_pub ]]; then
      warn "site.env に公開鍵が書かれていないため、鍵との照合はできません（この鍵の公開鍵: $derived）"
    else
      die "バックアップの鍵の公開鍵（$derived）が site.env の SITE_A_PUBKEY / SITE_B_PUBKEY のどちらとも一致しません"
    fi
    if [[ -n $m_site ]]; then
      local other my_ip peer_ip
      if [[ $m_site == A ]]; then other=B; else other=A; fi
      my_ip=$(env_value "$envsrc" "WG_${m_site}_LAN_IP")
      peer_ip=$(env_value "$envsrc" "WG_${other}_LAN_IP")
      # 相手拠点のホストに戻すと両拠点が同じ鍵になるので、これは止める
      if [[ -n $peer_ip && -n $(iface_of_ip "$peer_ip") ]]; then
        die "このホストは拠点 $other の WG ホスト（$peer_ip）です。拠点 $m_site の鍵を戻すと両拠点が同じ鍵になります"
      fi
      # どちらの IP も無いのは再インストール直後にありうるので、警告にとどめる
      if [[ -n $my_ip && -z $(iface_of_ip "$my_ip") ]]; then
        warn "このホストに WG_${m_site}_LAN_IP=$my_ip がありません。LAN 側 IP を変えた場合は site.env と、ルーターのポート転送の宛先も直してください"
      fi
    fi
  fi

  # パーミッションは MANIFEST の値をそのまま使わない。細工されたアーカイブで
  # 秘密鍵が 0644 で置かれるのを防ぐため、秘密を含むものは 600 に固定する
  for spec in "${items[@]}"; do
    read -r kind name mode path <<<"$spec"
    [[ $mode =~ ^[0-7]{3,4}$ ]] || die "MANIFEST のパーミッションが不正です: $kind $mode"
    case $kind in
      key)     restore_file "$stage/$name" "$KEY"  600 0 ;;
      pub)     restore_file "$stage/$name" "$PUB"  600 0 ;;
      conf)    restore_file "$stage/$name" "$CONF" 600 0 ;;
      env)     restore_file "$stage/$name" "$env_target" 600 1 ;;
      envsh)   restore_file "$stage/$name" "${env_dir:-$(dirname "$path")}/$(basename "$path")" 600 1 ;;
      clients) restore_file "$stage/$name" "${env_dir:-$(dirname "$path")}/$(basename "$path")" "$mode" 1 ;;
      *)       warn "MANIFEST の未知の種別を無視します: $kind" ;;
    esac
  done

  local envopt=""
  [[ -z $env_target || $env_target == "$SCRIPT_DIR/site.env" ]] || envopt="-e $env_target "
  echo
  echo "---- 次にすること ----"
  echo "1. 値を確認する        : ${env_target:-site.env}"
  echo "2. 設定を作り直して起動: sudo $0 ${envopt}apply ${m_site:-A|B}"
  echo "3. ルーターのポート転送と静的経路は鍵に依存しないので変更不要"
  echo "   （WG ホストの LAN 側 IP を変えた場合だけ、ポート転送の宛先を直す）"
  echo
  echo "相手拠点とクライアント端末の設定は、同じ鍵に戻したので変更は要らない。"
}

# --- client commands -------------------------------------------------------------
cmd_client_add() {
  need_root
  load_env 1
  local site=${1:-} name=${2:-}
  [[ -n $name ]] || die "使い方: client add A|B NAME"
  [[ $name =~ ^[A-Za-z0-9_-]+$ ]] || die "クライアント名は英数字・-・_ だけで指定してください: $name"
  select_site "$site"
  validate_addresses
  [[ -n $MY_CLIENT_NET ]] || die "site.env の WG_${L}_CLIENT_NET（拠点 $L のクライアント用アドレス帯）が空です"
  [[ -n $MY_PUBLIC ]] || die "SITE_${L}_PUBLIC が空です（この拠点は着信を受けられないので、クライアントは接続できません）"
  check_host_is_site
  install_tools
  read_clients ""
  if find_client "$name"; then
    die "クライアント $name は既に登録されています（拠点 ${CL_SITES[CL_INDEX]}、${CL_IPS[CL_INDEX]}）"
  fi
  local cip
  cip=$(alloc_client_ip "$MY_CLIENT_NET" "$OPT_IP" "${CL_IPS[@]}") || exit 1
  resolve_my_pubkey
  local priv pub i
  if [[ -n $OPT_PUBKEY ]]; then
    is_pubkey "$OPT_PUBKEY" || die "--pubkey が WireGuard の公開鍵の形式ではありません"
    for i in "${!CL_PUBS[@]}"; do
      [[ ${CL_PUBS[i]} != "$OPT_PUBKEY" ]] || die "その公開鍵はクライアント ${CL_NAMES[i]} に登録済みです"
    done
    [[ $OPT_PUBKEY != "$SITE_PUBKEY" ]] || die "--pubkey が拠点 $L の公開鍵と同じです"
    pub=$OPT_PUBKEY
    priv=$CLIENT_KEY_PLACEHOLDER
  elif (( DRY_RUN )); then
    pub="(generated)"
    priv="(hidden)"
  else
    priv=$(wg genkey) || die "鍵を生成できません"
    pub=$(wg pubkey <<<"$priv") || die "公開鍵を算出できません"
  fi
  local conf="$CLIENT_DIR/$name.conf" line
  line=$(printf '%-12s %-4s %-15s %s' "$name" "$L" "$cip" "$pub")
  if (( DRY_RUN )); then
    info "dry-run: $conf に書き込む内容:"
    render_client_conf "$name" "$cip" "$priv" | sed 's/^/    /'
    info "dry-run: $CLIENTS_FILE に追記する行:"
    echo "    $line"
    return
  fi
  [[ ! -e $conf ]] || die "$conf が既にあります（登録簿に無い古い conf）。内容を確認して削除してから実行してください"
  [[ -d $CLIENT_DIR ]] || (umask 077; mkdir -p "$CLIENT_DIR")
  (umask 077; render_client_conf "$name" "$cip" "$priv" >"$conf")
  restorecon "$conf" 2>/dev/null || true
  if [[ ! -f $CLIENTS_FILE ]]; then
    printf '# %-10s %-4s %-15s %s\n' NAME SITE TUNNEL_IP PUBLIC_KEY >"$CLIENTS_FILE"
  fi
  echo "$line" >>"$CLIENTS_FILE"
  info "クライアント $name を登録しました（拠点 $L、$cip）: $CLIENTS_FILE"
  info "クライアント用 conf を書き込みました: $conf"
  echo
  if [[ -n $OPT_PUBKEY ]]; then
    echo "conf の PrivateKey は $CLIENT_KEY_PLACEHOLDER のままです。クライアント側で秘密鍵に置き換えてください。"
  else
    echo "conf にはクライアントの秘密鍵が入っています。端末に取り込んだら削除してください。"
  fi
  echo "表示するには        : sudo $0 client show $name [--qr]"
  echo "ホストに反映するには: sudo $0 apply $L"
}

cmd_client_remove() {
  need_root
  load_env 1
  local name=${1:-}
  [[ -n $name ]] || die "使い方: client remove NAME"
  read_clients ""
  find_client "$name" || die "クライアント $name は登録されていません（$CLIENTS_FILE）"
  local site=${CL_SITES[CL_INDEX]} conf="$CLIENT_DIR/$name.conf"
  if (( DRY_RUN )); then
    echo "[dry-run] $CLIENTS_FILE から $name の行を削除する"
    [[ ! -f $conf ]] || echo "[dry-run] rm -f $conf"
  else
    local tmp
    tmp=$(mktemp "$CLIENTS_FILE.XXXXXX")
    awk -v n="$name" '{ line = $0; sub(/#.*/, "", line); split(line, f) } f[1] != n { print }' "$CLIENTS_FILE" >"$tmp"
    chmod --reference="$CLIENTS_FILE" "$tmp"
    mv "$tmp" "$CLIENTS_FILE"
    [[ ! -f $conf ]] || rm -f "$conf"
    info "クライアント $name を削除しました"
  fi
  echo "ホストに反映するには: sudo $0 apply $site"
}

cmd_client_show() {
  need_root
  load_env 1
  local name=${1:-}
  [[ -n $name ]] || die "使い方: client show NAME [--qr]"
  read_clients ""
  find_client "$name" || die "クライアント $name は登録されていません（$CLIENTS_FILE）"
  local conf="$CLIENT_DIR/$name.conf"
  [[ -f $conf ]] || die "$conf がありません（取り込み後に削除した場合は、client remove して add し直してください）"
  if (( OPT_QR )); then
    command -v qrencode >/dev/null || die "qrencode がありません（dnf install qrencode。EPEL が必要な場合があります）"
    qrencode -t ansiutf8 <"$conf"
  else
    cat "$conf"
  fi
}

# read_clients 済みの一覧を表示する。root で wg が動いていれば最終ハンドシェイクを付ける
print_client_list() {
  if (( ${#CL_NAMES[@]} == 0 )); then
    echo "登録済みクライアントはありません"
    return 0
  fi
  local -A hs=()
  local k t
  if [[ $EUID -eq 0 ]] && command -v wg >/dev/null; then
    while read -r k t; do hs[$k]=$t; done < <(wg show "$WG_IFACE" latest-handshakes 2>/dev/null || true)
  fi
  local now i st
  now=$(date +%s)
  printf '%-12s %-4s %-15s %-44s %s\n' NAME SITE TUNNEL_IP PUBLIC_KEY LAST_HANDSHAKE
  for i in "${!CL_NAMES[@]}"; do
    t=${hs[${CL_PUBS[i]}]:-}
    if [[ -z $t ]]; then st="-"          # wg が動いていない、この拠点の peer ではない、または root ではない
    elif (( t == 0 )); then st="なし"     # peer は登録済みだが一度も接続していない
    else st="$(( now - t )) 秒前"
    fi
    printf '%-12s %-4s %-15s %-44s %s\n' "${CL_NAMES[i]}" "${CL_SITES[i]}" "${CL_IPS[i]}" "${CL_PUBS[i]}" "$st"
  done
}

cmd_client_list() {
  load_env 1
  read_clients ""
  print_client_list
}

# --- main ------------------------------------------------------------------------
args=()
while (( $# )); do
  case $1 in
    -e|--env) [[ $# -ge 2 ]] || die "$1 には値が必要です"; ENV_FILE=$2; ENV_FILE_SET=1; shift ;;
    -n|--dry-run) DRY_RUN=1 ;;
    --use-existing-conf) OPT_USE_EXISTING=1 ;;
    --drop-unknown-peers) DROP_UNKNOWN=1 ;;
    --purge) PURGE=1 ;;
    --pubkey) [[ $# -ge 2 ]] || die "$1 には値が必要です"; OPT_PUBKEY=$2; shift ;;
    --ip) [[ $# -ge 2 ]] || die "$1 には値が必要です"; OPT_IP=$2; shift ;;
    --qr) OPT_QR=1 ;;
    -o|--output) [[ $# -ge 2 ]] || die "$1 には値が必要です"; OPT_OUTPUT=$2; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) die "不明なオプション: $1" ;;
    *) args+=("$1") ;;
  esac
  shift
done
set -- "${args[@]}"

case ${1:-} in
  keygen) shift; cmd_keygen "$@" ;;
  apply)  shift; cmd_apply "$@" ;;
  router) shift; cmd_router "$@" ;;
  status) shift; cmd_status ;;
  remove) shift; cmd_remove "$@" ;;
  backup) shift; cmd_backup "$@" ;;
  restore) shift; cmd_restore "$@" ;;
  client)
    shift
    case ${1:-} in
      add)    shift; cmd_client_add "$@" ;;
      remove) shift; cmd_client_remove "$@" ;;
      show)   shift; cmd_client_show "$@" ;;
      list)   shift; cmd_client_list ;;
      *) usage; exit 1 ;;
    esac ;;
  *) usage; exit 1 ;;
esac
