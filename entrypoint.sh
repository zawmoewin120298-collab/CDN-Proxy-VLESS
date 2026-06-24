#!/bin/bash

# ၁။ Sing-Box Engine ကို JSON Config ဖြင့် Background တွင် စတင်ပါ
if [ -f "/etc/sing-box/config.json" ]; then
    echo "✅ Starting Sing-Box Engine on Port 8080..."
    sing-box run -c /etc/sing-box/config.json &
else
    echo "⚠️ ERROR: /etc/sing-box/config.json not found!"
    exit 1
fi

# ၂။ Cloudflare Tunnel ကို Token ဖြင့် နောက်ခံ (Background) မှာ ချိတ်ဆက်ပါ
if [ ! -z "$TUNNEL_TOKEN" ]; then
    echo "✅ Connecting to Cloudflare Tunnel Network in background..."
    # Protocol နေရာကို အလိုအလျောက် ရွေးခိုင်းပြီး ပြဿနာကင်းအောင် ပြင်ထားပါသည်
    /usr/local/bin/cloudflared tunnel --no-autoupdate run --token "$TUNNEL_TOKEN" &
else
    echo "⚠️ WARNING: TUNNEL_TOKEN is missing. Skipping Cloudflare Tunnel."
fi

# ၃။ Container ကို ဆက်လက်အလုပ်လုပ်စေရန် အဓိက Process ကို စောင့်ထားပါ
echo "✅ All services started. Keeping container alive..."
wait
