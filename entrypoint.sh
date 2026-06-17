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

# ၃။ Container တစ်ခုလုံးကို အောက်ခြေကနေ လုံးဝအကျမခံဘဲ အမြဲတမ်း အသက်ရှင်နေအောင် ထိန်းထားပါ
echo "All Core components are running successfully. Keeping server alive..."
tail -f /dev/null
