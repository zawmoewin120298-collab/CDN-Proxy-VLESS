# အဆင့်မြင့် Sing-Box ပုံရိပ်ကို အခြေခံပြီး စတင်ခြင်း
FROM ghcr.io/sagernet/sing-box:latest

# လိုအပ်သော Linux Tools များ သွင်းခြင်း
RUN apk add --no-cache curl bash jq ca-certificates

# Sing-Box Config နေရာ Folder ဆောက်ခြင်း
RUN mkdir -p /etc/sing-box

# Config နှင့် Entrypoint Script ကို ကူးထည့်ခြင်း
COPY config.json /etc/sing-box/config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Railway အတွက် Port 8080 လမ်းကြောင်း ဖွင့်ပေးခြင်း
EXPOSE 8080

# Script အား စတင်မောင်းနှင်ရန် သတ်မှတ်ခြင်း
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
