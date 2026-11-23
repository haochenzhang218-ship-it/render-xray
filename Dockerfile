# Xray VLESS + WebSocket node for Render (free tier)
# Base is Alpine (has a shell); xray and caddy binaries are copied from
# their official images so no version pinning is needed here.
FROM alpine:latest

RUN apk add --no-cache ca-certificates curl

COPY --from=ghcr.io/xtls/xray-core:latest /usr/local/bin/xray /usr/local/bin/xray
COPY --from=caddy:latest /usr/bin/caddy /usr/bin/caddy

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Render sets $PORT automatically. UUID must be set as an env var in the
# Render dashboard (generate one with `uuidgen` or any UUID v4 generator).
# WS_PATH is optional and defaults to /ray.
ENTRYPOINT ["/entrypoint.sh"]
