#!/usr/bin/env bash
# WireGuard 拠点間 VPN（docs/wireguard-site-to-site.md）の手順を site.env の値で実行する。
#
#   sudo ./wg-s2s.sh [options] keygen [A|B]   手順 1〜2: wireguard-tools 導入と鍵生成
#   sudo ./wg-s2s.sh [options] apply  A|B     手順 3〜6: wg0.conf・sysctl・firewalld・サービス
#        ./wg-s2s.sh [options] router A|B     手順 7: ルーターに入れる値を表示
#   sudo ./wg-s2s.sh [options] status         状態確認
#   sudo ./wg-s2s.sh [options] remove A|B     ロールバック
#
# options:
#   -e, --env FILE          設定ファイル（既定: スクリプトと同じディレクトリの site.env）
#   -n, --dry-run           変更せず、実行予定の内容だけを表示する
#   --use-existing-conf     既存の wg0.conf を使い、生成しない（site.env の WG_USE_EXISTING_CONF=1 と同じ）
#   --purge                 remove で wg0.conf と鍵ファイルも削除する
#   -h, --help              このヘルプ
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ENV_FILE="$SCRIPT_DIR/site.env"
DRY_RUN=0
OPT_USE_EXISTING=0
PURGE=0
SYSCTL_FILE=/etc/sysctl.d/90-wireguard.conf

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
  elif (( required )); then
    die "設定ファイルがありません: $ENV_FILE（site.env.example をコピーして作成）"
  fi
  WG_IFACE=${WG_IFACE:-wg0}
  WG_FW_ZONE=${WG_FW_ZONE:-wireguard}
  WG_KEEPALIVE=${WG_KEEPALIVE:-25}
  WG_MTU=${WG_MTU:-}
  LAN_ZONE=${LAN_ZONE:-}
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
  n=SITE_${L}_LAN;      MY_LAN=${!n}
  n=SITE_${P}_LAN;      PEER_LAN=${!n}
  n=WG_${L}_LAN_IP;     MY_LAN_IP=${!n}
  n=WG_${P}_LAN_IP;     PEER_LAN_IP=${!n}
  n=WG_${L}_TUN_IP;     MY_TUN=${!n}
  n=WG_${P}_TUN_IP;     PEER_TUN=${!n}
  n=SITE_${L}_PUBLIC;   MY_PUBLIC=${!n:-}
  n=SITE_${P}_PUBLIC;   PEER_PUBLIC=${!n:-}
  n=SITE_${L}_PUBKEY;   MY_PUBKEY=${!n:-}
  n=SITE_${P}_PUBKEY;   PEER_PUBKEY=${!n:-}
  n=ROUTER_${L}_LAN_IP; MY_ROUTER=${!n:-}
  POLICY_OUT="site${L}-to-site${P}"
  POLICY_IN="site${P}-to-site${L}"
  PORT=$WG_PORT
}

# アドレス類の形式・包含関係・重複を検査する
validate_addresses() {
  local out
  out=$(python3 - "$SITE_A_LAN" "$SITE_B_LAN" "$WG_TUNNEL_NET" \
      "$WG_A_LAN_IP" "$WG_B_LAN_IP" "$WG_A_TUN_IP" "$WG_B_TUN_IP" \
      "${ROUTER_A_LAN_IP:-}" "${ROUTER_B_LAN_IP:-}" "$WG_PORT" "$WG_KEEPALIVE" "$WG_MTU" <<'PY'
import ipaddress as ip, sys
a_lan, b_lan, tun, a_ip, b_ip, a_tun, b_tun, a_rt, b_rt, port, ka, mtu = sys.argv[1:]
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
if not errs:
    for (x, xn), (y, yn) in [((na, "SITE_A_LAN"), (nb, "SITE_B_LAN")),
                             ((na, "SITE_A_LAN"), (nt, "WG_TUNNEL_NET")),
                             ((nb, "SITE_B_LAN"), (nt, "WG_TUNNEL_NET"))]:
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
  ip -o -4 addr show | awk -v ip="$1" '{split($4, a, "/"); if (a[1] == ip) { print $2; exit }}'
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
}

install_tools() {
  if ! rpm -q wireguard-tools >/dev/null 2>&1; then
    info "wireguard-tools をインストールします"
    run dnf install -y wireguard-tools
  fi
}

# --- 既存 conf の検査 ------------------------------------------------------------
# 停止すべき不一致は ERROR、続行できるものは WARN を出す。ListenPort が書かれていれば PORT をそれに合わせる
check_existing_conf() {
  [[ -f $CONF ]] || die "既存の設定ファイルがありません: $CONF"
  local mode out rc=0
  mode=$(stat -c %a "$CONF")
  [[ $mode == 600 ]] || warn "$CONF のパーミッションが $mode です（600 を推奨）"
  out=$(python3 - "$CONF" "$MY_TUN" "$PEER_TUN" "$PEER_LAN" "$WG_PORT" <<'PY'
import ipaddress as ip, re, sys
path, my_tun, peer_tun, peer_lan, port = sys.argv[1:]
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
render_conf() {  # $1 = PrivateKey の値
  local endpoint=""
  if [[ -n $PEER_PUBLIC ]]; then
    if [[ $PEER_PUBLIC == *:* && $PEER_PUBLIC != \[* ]]; then
      endpoint="[$PEER_PUBLIC]:$PORT"
    else
      endpoint="$PEER_PUBLIC:$PORT"
    fi
  fi
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
  echo "AllowedIPs = $PEER_TUN/32, $PEER_LAN"
  (( WG_KEEPALIVE == 0 )) || echo "PersistentKeepalive = $WG_KEEPALIVE"
}

check_keys() {
  [[ -n $PEER_PUBKEY ]] || die "site.env の SITE_${P}_PUBKEY（相手拠点の公開鍵）が空です"
  is_pubkey "$PEER_PUBKEY" || die "SITE_${P}_PUBKEY が WireGuard の公開鍵の形式ではありません"
  [[ -f $KEY ]] || die "秘密鍵 $KEY がありません。先に keygen を実行してください"
  local derived
  derived=$(wg pubkey <"$KEY") || die "$KEY から公開鍵を算出できません"
  if [[ -n $MY_PUBKEY && $MY_PUBKEY != "$derived" ]]; then
    die "SITE_${L}_PUBKEY がこのホストの鍵（$derived）と一致しません"
  fi
  [[ $PEER_PUBKEY != "$derived" ]] || die "SITE_${P}_PUBKEY が自拠点の公開鍵と同じです"
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
fw() { firewall-cmd --permanent "$@" >/dev/null 2>&1; }

# grep -q は途中で読むのをやめて pipefail で誤判定しうるので、全部読ませる
has_word() { tr -s ' \n' '\n' | grep -Fx -- "$1" >/dev/null; }

ensure_policy() {  # name ingress egress src dst
  local name=$1 in=$2 out=$3 src=$4 dst=$5
  local rule="rule family=ipv4 source address=$src destination address=$dst accept"
  if ! firewall-cmd --permanent --get-policies | has_word "$name"; then
    run firewall-cmd --permanent --new-policy="$name"
  fi
  fw --policy="$name" --query-ingress-zone="$in" || run firewall-cmd --permanent --policy="$name" --add-ingress-zone="$in"
  fw --policy="$name" --query-egress-zone="$out" || run firewall-cmd --permanent --policy="$name" --add-egress-zone="$out"
  fw --policy="$name" --query-rich-rule="$rule" || run firewall-cmd --permanent --policy="$name" --add-rich-rule="$rule"
}

setup_firewalld() {
  systemctl is-active --quiet firewalld || die "firewalld が起動していません"
  resolve_lan_zone
  fw --zone="$LAN_ZONE" --query-port="$PORT/udp" || run firewall-cmd --permanent --zone="$LAN_ZONE" --add-port="$PORT/udp"
  if ! firewall-cmd --permanent --get-zones | has_word "$WG_FW_ZONE"; then
    run firewall-cmd --permanent --new-zone="$WG_FW_ZONE"
  fi
  local cur
  cur=$(firewall-cmd --permanent --get-zone-of-interface="$WG_IFACE" 2>/dev/null || true)
  if [[ -n $cur && $cur != "no zone" && $cur != "$WG_FW_ZONE" ]]; then
    die "$WG_IFACE は既にゾーン $cur に割り当てられています"
  fi
  [[ $cur == "$WG_FW_ZONE" ]] || run firewall-cmd --permanent --zone="$WG_FW_ZONE" --add-interface="$WG_IFACE"
  ensure_policy "$POLICY_OUT" "$LAN_ZONE" "$WG_FW_ZONE" "$MY_LAN" "$PEER_LAN"
  ensure_policy "$POLICY_IN" "$WG_FW_ZONE" "$LAN_ZONE" "$PEER_LAN" "$MY_LAN"
  run firewall-cmd --reload
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
  [[ -n $MY_PUBLIC || -n $PEER_PUBLIC ]] || die "SITE_A_PUBLIC と SITE_B_PUBLIC の両方が空です（どちらからもトンネルを張れません）"
  check_host_is_site
  install_tools
  if (( USE_EXISTING )); then
    check_existing_conf
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
  # AllowedIPs・Address の変更は reload では経路に反映されないので、常に restart する（落とし穴 2）
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
  local p
  # 未 reload の変更も見えるよう permanent 側を表示する
  for p in siteA-to-siteB siteB-to-siteA; do
    if firewall-cmd --permanent --get-policies | has_word "$p"; then
      echo "$sep policy $p (permanent)"
      firewall-cmd --permanent --info-policy="$p"
    fi
  done
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
  local p name
  for p in "$POLICY_OUT" "$POLICY_IN"; do
    firewall-cmd --permanent --get-policies | has_word "$p" && run firewall-cmd --permanent --delete-policy="$p"
  done
  if firewall-cmd --permanent --get-zones | has_word "$WG_FW_ZONE"; then
    run firewall-cmd --permanent --delete-zone="$WG_FW_ZONE"
  fi
  fw --zone="$LAN_ZONE" --query-port="$PORT/udp" && run firewall-cmd --permanent --zone="$LAN_ZONE" --remove-port="$PORT/udp"
  run firewall-cmd --reload
  # 削除時に firewalld が残す *.xml.old を片付ける（このスクリプトが作ったものだけ）
  for name in "policies/$POLICY_OUT" "policies/$POLICY_IN" "zones/$WG_FW_ZONE"; do
    [[ ! -f /etc/firewalld/$name.xml.old ]] || run rm -f "/etc/firewalld/$name.xml.old"
  done
  if [[ -f $SYSCTL_FILE ]]; then
    run rm -f "$SYSCTL_FILE"
    run sysctl -q -w net.ipv4.ip_forward=0
  fi
  if (( PURGE )); then
    run rm -f "$CONF" "$KEY" "$PUB"
  else
    info "$CONF と鍵ファイルは残しています（削除するには --purge）"
  fi
  echo "ルーターのポート転送と静的経路は手動で削除してください。"
}

# --- main ------------------------------------------------------------------------
args=()
while (( $# )); do
  case $1 in
    -e|--env) [[ $# -ge 2 ]] || die "$1 には値が必要です"; ENV_FILE=$2; shift ;;
    -n|--dry-run) DRY_RUN=1 ;;
    --use-existing-conf) OPT_USE_EXISTING=1 ;;
    --purge) PURGE=1 ;;
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
  *) usage; exit 1 ;;
esac
