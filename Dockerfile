# အဆင့်မြင့် Sing-Box ပုံရိပ်ကို အခြေခံပြီး စတင်ခြင်း
FROM ghcr.io/sagernet/sing-box:latest

# ၁။ လိုအပ်သော Linux Tools များ၊ Node.js၊ npm နှင့် cloudflared ကို တစ်ခါတည်း သွင်းခြင်း
RUN apk add --no-cache curl bash jq ca-certificates nodejs npm && \
    curl -L -o /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    chmod +x /usr/local/bin/cloudflared

# ၂။ Folder တည်ဆောက်ခြင်း
RUN mkdir -p /etc/sing-box /app

# ၃။ Node.js ပရောဂျက်အတွက် အလုပ်လုပ်မည့် နေရာသတ်မှတ်ခြင်း
WORKDIR /app

# ၄။ Node.js ဖိုင်များအား ဆာဗာထဲ ကူးယူတပ်ဆင်ခြင်း
COPY package*.json ./
RUN npm install
COPY index.js ./

# ၅။ Sing-Box ပင်မ Config နှင့် Entrypoint စတင်မည့် Script ကို ကူးထည့်ခြင်း
COPY config.json /etc/sing-box/config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# x-ui binary ကို ကူးထည့်ပါ (ဆရာ့ binary ရှိတဲ့နေရာအတိုင်း)
COPY x-ui /app/x-ui
RUN chmod +x /app/x-ui

# ၆။ WispByte အတွက် ပင်မ Port လမ်းကြောင်း ဖွင့်ပေးခြင်း
EXPOSE 3000
EXPOSE 8080

# ၇။ Script အား အလိုအလျောက် စတင်မောင်းနှင်ရန် သတ်မှတ်ခြင်း
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
