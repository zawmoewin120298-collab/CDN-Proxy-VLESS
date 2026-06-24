# အဆင့်မြင့် Sing-Box ပုံရိပ်ကို အခြေခံပြီး စတင်ခြင်း
FROM ghcr.io/sagernet/sing-box:latest

# လိုအပ်သော Linux Tools များနှင့် cloudflared ကို သွင်းခြင်း (Node.js မပါ)
RUN apk add --no-cache curl bash jq ca-certificates && \
    curl -L -o /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    chmod +x /usr/local/bin/cloudflared

# Sing-Box Config နေရာနှင့် Entrypoint ထားရန် Folder များ
RUN mkdir -p /etc/sing-box

# Sing-Box ပင်မ Config နှင့် Entrypoint Script ကို ကူးထည့်ခြင်း
COPY config.json /etc/sing-box/config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Sing-Box အတွက် Port လမ်းကြောင်း ဖွင့်ပေးခြင်း (ဆရာ config.json ထဲက listen_port အတိုင်း)
EXPOSE 8080

# Script အား အလိုအလျောက် စတင်မောင်းနှင်ရန် သတ်မှတ်ခြင်း
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
