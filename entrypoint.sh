#!/bin/bash

# Sing-Box Engine ကို JSON Config ဖြင့် နောက်ကွယ် (Background) တွင် စတင်မောင်းနှင်ပါသည်
if [ -f "/etc/sing-box/config.json" ]; then
    echo "🚀 Starting Sing-Box Engine on Port 8080 (Background Mode)..."
    sing-box run -c /etc/sing-box/config.json &
else
    echo "⚠️ ERROR: /etc/sing-box/config.json not found!"
    exit 1
fi

# Cloudflare Tunnel Token ရှိမရှိ စစ်ဆေးပြီး မောင်းနှင်ခြင်း
if [ -z "$TUNNEL_TOKEN" ]; then
    echo "⚠️ WARNING: TUNNEL_TOKEN variable ကို ရှာမတွေ့ပါ။ Sing-Box ပဲ သီးသန့် Run နေပါမည်။"
    # Token မရှိရင် Container ပိတ်မသွားအောင် Sing-Box process ကို စောင့်ခိုင်းထားခြင်း
    wait -n
else
    echo "☁️ Starting Cloudflare Tunnel..."
    # Cloudflare Tunnel ကို တိုက်ရိုက် Foreground ကနေ Run ပါမယ်
    exec cloudflared tunnel --no-autoupdate run --token "$TUNNEL_TOKEN"
fi
