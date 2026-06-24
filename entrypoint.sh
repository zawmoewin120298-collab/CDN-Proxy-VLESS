#!/bin/bash

# ၁။ Node.js Web Server ကို နောက်ကွယ် (Background) ကနေ အရင်မောင်းနှင်ပါ
if [ -d "/app" ]; then
    echo "Starting Node.js Web Server on Port 3000..."
    cd /app && npm start &
else
    echo "⚠️ WARNING: /app directory not found, skipping Node.js startup."
fi

# ၂။ Sing-Box Engine ကို JSON Config ဖြင့် Background တွင် စတင်မောင်းနှင်ပါ
echo "Starting Sing-Box Engine on Port 8080..."
sing-box run -c /etc/sing-box/config.json &

# ၃။ Cloudflare Tunnel ကို Token ဖြင့် ချိတ်ဆက်ပါ (Foreground - ပင်မအဖြစ် ရှေ့ကမောင်းမည်)
if [ ! -z "$TUNNEL_TOKEN" ]; then
    echo "Connecting to Cloudflare Tunnel Network..."
    exec /usr/local/bin/cloudflared tunnel --no-autoupdate run --protocol http2 --no-tls-verify --token "$TUNNEL_TOKEN"
else
    echo "⚠️ ERROR: TUNNEL_TOKEN is missing!"
    exit 1
fi
