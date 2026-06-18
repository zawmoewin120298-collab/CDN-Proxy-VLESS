#!/bin/bash

# ၁။ Sing-Box Engine ကို JSON Config ဖြင့် Background တွင် စတင်မောင်းနှင်ပါ
echo "Starting Sing-Box Engine on Port 8080..."
sing-box run -c /etc/sing-box/config.json &

# ၂။ Cloudflare Tunnel ကို Token ဖြင့် ချိတ်ဆက်ပါ
if [ ! -z "$TUNNEL_TOKEN" ]; then
    echo "Connecting to Cloudflare Tunnel Network..."
    exec /usr/local/bin/cloudflared tunnel --no-autoupdate run --protocol http2 --no-tls-verify --token "$TUNNEL_TOKEN"
else
    echo "⚠️ ERROR: TUNNEL_TOKEN is missing!"
    exit 1
fi
