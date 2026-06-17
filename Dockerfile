FROM nginx:1.25-alpine

# ၁။ လိုအပ်သော Packages များနှင့် V2ray (Xray) ကို တစ်ခါတည်း သွင်းခြင်း
RUN apk add --no-cache \
    curl \
    bash \
    tzdata \
    ca-certificates

# Xray Core ကို Download ဆွဲပြီး သင့်တော်ရာနေရာသို့ ထည့်သွင်းခြင်း
RUN mkdir -p /etc/v2ray /usr/bin && \
    curl -L -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip /tmp/xray.zip -d /tmp/xray && \
    mv /tmp/xray/xray /usr/bin/v2ray && \
    chmod +x /usr/bin/v2ray && \
    rm -rf /tmp/xray.zip /tmp/xray

# Cloudflare Tunnel (cloudflared) ကိုပါ ထည့်သွင်းခြင်း
RUN curl -L -o /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    chmod +x /usr/local/bin/cloudflared

# ၂။ Cache directories ဆောက်ခြင်း
RUN mkdir -p /var/cache/nginx/cdn \
    && mkdir -p /var/cache/nginx/static \
    && chown -R nginx:nginx /var/cache/nginx

# ၃။ Nginx Advanced configuration နှင့် V2ray configurations များ ထည့်သွင်းခြင်း
COPY nginx-advanced.conf /etc/nginx/nginx.conf

# 💡 ပြင်ဆင်ချက် - အစ်ကိုကြီးဆောက်ထားတဲ့ config.json အစစ်ကို Docker Container ထဲသို့ ကူးထည့်ခြင်း
COPY config.json /etc/v2ray/config.json 

# ၄။ Static HTML ဖိုင်များနှင့် Error Pages များ ဆောက်ခြင်း
COPY index.html /usr/share/nginx/html/index.html

RUN mkdir -p /usr/share/nginx/html/errors
RUN echo '<!DOCTYPE html><html><head><title>400 Bad Request</title></head><body><h1>400 - Bad Request</h1><p>Your request was malformed.</p></body></html>' > /usr/share/nginx/html/errors/400.html \
    && echo '<!DOCTYPE html><html><head><title>404 Not Found</title></head><body><h1>404 - Not Found</h1><p>The requested resource was not found.</p></body></html>' > /usr/share/nginx/html/errors/404.html \
    && echo '<!DOCTYPE html><html><head><title>Server Error</title></head><body><h1>Server Error</h1><p>An internal server error occurred.</p></body></html>' > /usr/share/nginx/html/errors/50x.html

RUN chown -R nginx:nginx /usr/share/nginx/html

# ၅။ Startup Script ကို ကူးထည့်ပြီး အခွင့်အရေးပေးခြင်း
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Port 80 ကို HTTP အတွက် ဖွင့်ခြင်း
EXPOSE 80

# Start မောင်းနှင်ရန် script ကို ခေါ်ခြင်း
CMD ["/bin/bash", "/entrypoint.sh"]
