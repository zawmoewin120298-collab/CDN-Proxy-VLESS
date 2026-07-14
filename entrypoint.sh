#!/bin/bash

# Default သတ်မှတ်ချက်များ (Environment variables မထည့်ထားရင် သုံးမယ့်အရာများ)
PORT=${PORT:-8080}
UUID=${UUID:-"e3b1c678-8ba9-4f2e-bf73-4560df76848d"}
PATH_WS=${PATH_WS:-"/vless-ws"}
DOMAIN=${RAILWAY_STATIC_URL:-"your-railway-domain.up.railway.app"}

# Domain name အား သန့်စင်ခြင်း (https:// ကို ဖယ်ထုတ်ရန်)
DOMAIN=$(echo "$DOMAIN" | sed -e 's|^[^/]*//||' -e 's|/.*$||')

# ၁။ Sing-Box Config အား Variables များဖြင့် အစားထိုးခြင်း
sed -i "s/UUID_PLACEHOLDER/$UUID/g" /etc/sing-box/config.json
sed -i "s|PATH_PLACEHOLDER|$PATH_WS|g" /etc/sing-box/config.json

# ၂။ Nginx Server block အား Dynamic ဖန်တီးခြင်း
mkdir -p /run/nginx
cat <<EOF > /etc/nginx/http.d/default.conf
server {
    listen ${PORT};
    listen [::]:${PORT};
    server_name _;

    # ပုံမှန် Browser နဲ့ ဝင်ရင် HTML Dashboard ပြပေးမည်
    location / {
        root /var/www/html;
        index index.html;
    }

    # VPN Client ချိတ်လာလျှင် Sing-Box ဆီသို့ လမ်းကြောင်းလွှဲပေးမည်
    location ${PATH_WS} {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# ၃။ မျက်နှာပြင် Web Dashboard တွင် ပြသပေးမည့် VLESS Config Link အား တည်ဆောက်ခြင်း
VLESS_LINK="vless://${UUID}@${DOMAIN}:443?encryption=none&security=tls&type=ws&host=${DOMAIN}&path=${PATH_WS}#Railway-SingBox"

sed -i "s|VLESS_LINK_PLACEHOLDER|$VLESS_LINK|g" /var/www/html/index.html
sed -i "s|UUID_PLACEHOLDER|$UUID|g" /var/www/html/index.html
sed -i "s|PATH_PLACEHOLDER|$PATH_WS|g" /var/www/html/index.html

# ၄။ Cloudflare Tunnel token ရှိလျှင် background တွင် မောင်းနှင်မည်
if [ -n "$TUNNEL_TOKEN" ]; then
    echo "Starting cloudflared tunnel..."
    cloudflared tunnel --no-autoupdate run --token "$TUNNEL_TOKEN" &
fi

# ၅။ Nginx နှင့် Sing-Box အား စတင်ပတ်မောင်းနှင်ခြင်း
echo "Starting Nginx on port ${PORT}..."
nginx

echo "Starting Sing-Box on internal port 10000..."
exec sing-box run -c /etc/sing-box/config.json
