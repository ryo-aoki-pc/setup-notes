# ~/wg/site.env を読み、このホスト視点の変数（MY_* / PEER_*）を作る
#
# 使い方（docs/wireguard.md 手動手順 0）:
#   cp <このリポジトリ>/scripts/wireguard/wg-env.sh ~/wg/wg-env.sh
#   . ~/wg/wg-env.sh          # 実行ではなく source する。新しいシェルを開くたびに読み直す
# 環境固有の値は入っていない（すべて site.env から読む）。両拠点で同じファイルを使う。
set -a
. ~/wg/site.env

# このホストがどちらの拠点かを LAN 側 IP から判定する（A/B の取り違え防止）
host_has_ip() { ip -o -4 addr show | awk -v ip="$1" '$4 ~ "^"ip"/" {f=1} END {exit !f}'; }
if   host_has_ip "$WG_A_LAN_IP"; then MY_SITE=A
elif host_has_ip "$WG_B_LAN_IP"; then MY_SITE=B
else echo "WARN: WG_A_LAN_IP / WG_B_LAN_IP のどちらもこのホストに無い。MY_SITE を手で設定する" >&2
fi

if [ "$MY_SITE" = A ]; then
  PEER_SITE=B
  MY_LAN=$SITE_A_LAN;             PEER_LAN=$SITE_B_LAN
  MY_LAN_IP=$WG_A_LAN_IP;         PEER_LAN_IP=$WG_B_LAN_IP
  MY_TUN_IP=$WG_A_TUN_IP;         PEER_TUN_IP=$WG_B_TUN_IP
  MY_PUBLIC=$SITE_A_PUBLIC;       PEER_PUBLIC=$SITE_B_PUBLIC
  MY_PUBKEY=$SITE_A_PUBKEY;       PEER_PUBKEY=$SITE_B_PUBKEY
  MY_CLIENT_NET=$WG_A_CLIENT_NET; PEER_CLIENT_NET=$WG_B_CLIENT_NET
  MY_ROUTER_IP=$ROUTER_A_LAN_IP;  PEER_ROUTER_IP=$ROUTER_B_LAN_IP
else
  PEER_SITE=A
  MY_LAN=$SITE_B_LAN;             PEER_LAN=$SITE_A_LAN
  MY_LAN_IP=$WG_B_LAN_IP;         PEER_LAN_IP=$WG_A_LAN_IP
  MY_TUN_IP=$WG_B_TUN_IP;         PEER_TUN_IP=$WG_A_TUN_IP
  MY_PUBLIC=$SITE_B_PUBLIC;       PEER_PUBLIC=$SITE_A_PUBLIC
  MY_PUBKEY=$SITE_B_PUBKEY;       PEER_PUBKEY=$SITE_A_PUBKEY
  MY_CLIENT_NET=$WG_B_CLIENT_NET; PEER_CLIENT_NET=$WG_A_CLIENT_NET
  MY_ROUTER_IP=$ROUTER_B_LAN_IP;  PEER_ROUTER_IP=$ROUTER_A_LAN_IP
fi

WG_CONF=/etc/wireguard/$WG_IFACE.conf
WG_KEY=/etc/wireguard/$WG_IFACE.key
WG_PUB=/etc/wireguard/$WG_IFACE.pub
# 自拠点の公開鍵が site.env に無ければ鍵ファイルから読む（/etc/wireguard は 0700 なので sudo が要る）
[ -z "$MY_PUBKEY" ] && MY_PUBKEY=$(sudo cat "$WG_PUB" 2>/dev/null)

# 相手 peer の AllowedIPs。相手拠点のクライアント帯があれば自動で加わる
PEER_ALLOWED="$PEER_TUN_IP/32, $PEER_LAN"
[ -n "$PEER_CLIENT_NET" ] && PEER_ALLOWED="$PEER_ALLOWED, $PEER_CLIENT_NET"

# LAN 側 NIC とそのゾーン。ゾーン未割り当ての NIC では --get-zone-of-interface は
# "no zone" を stderr に出して 2 を返すので、文字列ではなく終了コードで判定する
MY_NIC=$(ip -o -4 addr show | awk -v ip="$MY_LAN_IP" '$4 ~ "^"ip"/" {print $2; exit}')
if [ -z "$LAN_ZONE" ]; then
  LAN_ZONE=$(sudo firewall-cmd --get-zone-of-interface="$MY_NIC" 2>/dev/null) ||
    LAN_ZONE=$(sudo firewall-cmd --get-default-zone)
fi

# policy 名（通信の向きで命名する。ゾーンの対応はホストごとに違う）
POL_OUT=site$MY_SITE-to-site$PEER_SITE           # 自拠点 LAN → 相手拠点 LAN
POL_IN=site$PEER_SITE-to-site$MY_SITE            # 相手拠点 LAN → 自拠点 LAN
POL_MYCL_IN=clients$MY_SITE-to-site$MY_SITE      # 自拠点のクライアント → 自拠点 LAN
POL_MYCL_OUT=site$MY_SITE-to-clients$MY_SITE     # 自拠点 LAN → 自拠点のクライアント
POL_MYCL_PEER=clients$MY_SITE-to-site$PEER_SITE  # 自拠点のクライアント → 相手拠点 LAN
POL_PEER_MYCL=site$PEER_SITE-to-clients$MY_SITE  # 相手拠点 LAN → 自拠点のクライアント
POL_PEERCL_IN=clients$PEER_SITE-to-site$MY_SITE  # 相手拠点のクライアント → 自拠点 LAN
POL_PEERCL_OUT=site$MY_SITE-to-clients$PEER_SITE # 自拠点 LAN → 相手拠点のクライアント
set +a
