#!/bin/bash

# ၁။ Xray (V2ray) Core ကို နောက်ခံ (Background) မှာ အရင်ဆုံး စတင်မောင်းနှင်ပါ
echo "Starting Xray (V2ray) Core Engine..."
/usr/bin/v2ray run -config /etc/v2ray/config.json &

# ၂။ Cloudflare Tunnel ကို ထည့်သွင်းထားသော Token ဖြင့် ချိတ်ဆက်ခြင်း
if [ ! -z "$TUNNEL_TOKEN" ]; then
    echo "Connecting to Cloudflare Network via Tunnel Token..."
    # HTTP/2 (TCP) စနစ်သီးသန့်ဖြင့် ကွန်ရက်ပိတ်ဆို့မှုများ ကျော်လွှားရန် Force Run ခြင်း
    /usr/local/bin/cloudflared tunnel --no-autoupdate run --protocol http2 --no-tls-verify --token "$TUNNEL_TOKEN" &
else
    echo "⚠️ Warning: TUNNEL_TOKEN Variable is empty! Tunnel cannot start."
fi

# ၃။ Nginx ကို ရှေ့ဆုံး (Foreground) ကနေ စတင်မောင်းနှင်ပြီး Container ကြီးကို အမြဲတမ်း အသက်ရှင်စေခြင်း
# (Nginx ပွင့်လာမှသာ ပရောဂျက်တစ်ခုလုံး လမ်းကြောင်း ပွင့်သွားမှာ ဖြစ်ပါတယ်)
echo "Starting Nginx Web/Proxy Server..."
nginx -g "daemon off;"
