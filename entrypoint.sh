#!/bin/bash

# ၁။ Xray (V2ray) Core ကို Background တွင် စတင်မောင်းနှင်ပါ
echo "Starting Xray Core Engine..."
/usr/bin/v2ray run -config /etc/v2ray/config.json &

# ၂။ Cloudflare Tunnel အား Token ဖြင့် ချိတ်ဆက်ခြင်း
if [ ! -z "$TUNNEL_TOKEN" ]; then
    echo "Connecting to Cloudflare Tunnel Network..."
    /usr/local/bin/cloudflared tunnel --no-autoupdate run --protocol http2 --no-tls-verify --token "$TUNNEL_TOKEN" &
else
    echo "⚠️ Warning: TUNNEL_TOKEN Variable is empty!"
fi

# ၃။ Nginx အား ရှေ့ဆုံးမှ မောင်းနှင်ပြီး Container အား အမြဲရှင်သန်စေခြင်း
echo "Starting Nginx Web Server on Port 7860..."
exec nginx -g "daemon off;"
