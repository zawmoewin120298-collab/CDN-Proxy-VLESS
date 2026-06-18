#!/bin/bash

# ၁။ Sing-Box Core Engine ကို နောက်ခံ (Background) တွင် စတင်မောင်းနှင်ပါ
echo "Starting Sing-Box Engine on Port 8080..."
/usr/local/bin/sing-box run -c /etc/sing-box/config.yaml &

# ၂။ Cloudflare Tunnel ကို Token ဖြင့် တိုက်ရိုက်ချိတ်ဆက်ပါ
if [ ! -z "$TUNNEL_TOKEN" ]; then
    echo "Connecting to Cloudflare Tunnel Network..."
    exec /usr/local/bin/cloudflared tunnel --no-autoupdate run --protocol http2 --no-tls-verify --token "$TUNNEL_TOKEN"
else
    echo "⚠️ ERROR: TUNNEL_TOKEN is missing! Process stopped."
    exit 1
fi
