#!/bin/sh
# Entrypoint for the Render xray node.
# - xray listens on 127.0.0.1:10000 (VLESS over WebSocket)
# - caddy listens on $PORT (Render's public port): serves 200 on / so
#   Render's health check passes, and reverse-proxies the WS path to xray.
# - TLS is terminated by Cloudflare in front (domain proxied, orange cloud),
#   so neither xray nor caddy does TLS here.
set -e

PORT="${PORT:-8080}"
WS_PATH="${WS_PATH:-/ray}"
UUID="${UUID:-}"

if [ -z "$UUID" ]; then
  echo "ERROR: UUID env var is not set. Set it in the Render dashboard." >&2
  exit 1
fi

mkdir -p /etc/xray /etc/caddy

cat > /etc/xray/config.json <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": 10000,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [{ "id": "$UUID" }],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "$WS_PATH" }
      }
    }
  ],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF

cat > /etc/caddy/Caddyfile <<EOF
:$PORT {
  handle $WS_PATH* {
    reverse_proxy 127.0.0.1:10000
  }
  handle {
    respond "ok" 200
  }
}
EOF

/usr/local/bin/xray -config /etc/xray/config.json &
exec /usr/bin/caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
